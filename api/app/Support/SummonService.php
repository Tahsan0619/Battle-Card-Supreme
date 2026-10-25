<?php

namespace App\Support;

use App\Models\CardDefinition;
use App\Models\IdempotencyKey;
use App\Models\PlayerCard;
use App\Models\SummonRoll;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use RuntimeException;

final class SummonService
{
    public function __construct(
        private ProgressService $progress,
        private EconomyService $economy,
    ) {}

    public function banners(): array
    {
        $banners = config('shop.summon.banners', []);

        return [
            'banners' => array_map(function (array $b) {
                $rates = $b['rates_bp'] ?? [];
                $total = array_sum($rates);

                return [
                    'code' => $b['code'],
                    'title' => $b['title'],
                    'description' => $b['description'],
                    'cost_currency' => $b['cost_currency'],
                    'cost_amount' => $b['cost_amount'],
                    'probability_disclosure' => [
                        'unit' => 'basis_points_per_10000',
                        'total_bp' => $total,
                        'rates_bp' => $rates,
                        'rates_percent' => collect($rates)->map(
                            fn ($bp) => round($bp / 100, 2)
                        )->all(),
                        'duplicate_policy' => 'Duplicates grant Void Shards; card not double-granted.',
                    ],
                ];
            }, $banners),
        ];
    }

    /**
     * @return array{replay:bool,payload:array,status:int}
     */
    public function pull(User $user, string $bannerCode, string $clientSummonId): array
    {
        $scope = 'summon_pull';
        $existing = IdempotencyKey::query()
            ->where('user_id', $user->id)
            ->where('scope', $scope)
            ->where('key', $clientSummonId)
            ->first();
        if ($existing) {
            return [
                'replay' => true,
                'payload' => $existing->response_json ?? [],
                'status' => 200,
            ];
        }

        $banner = collect(config('shop.summon.banners', []))->firstWhere('code', $bannerCode);
        if (! $banner) {
            throw new RuntimeException('BANNER_NOT_FOUND');
        }

        $rates = $banner['rates_bp'] ?? [];
        if (array_sum($rates) !== 10000) {
            throw new RuntimeException('BANNER_MISCONFIGURED');
        }

        return DB::transaction(function () use ($user, $banner, $clientSummonId, $scope, $rates) {
            $profile = $this->progress->ensureProfile($user->id);

            try {
                $profile = $this->economy->apply(
                    $profile,
                    $banner['cost_currency'],
                    -1 * (int) $banner['cost_amount'],
                    'summon_pull',
                    'summon_banner',
                    $banner['code'],
                    $clientSummonId,
                );
            } catch (InvalidArgumentException $e) {
                if ($e->getMessage() === 'INSUFFICIENT_CURRENCY') {
                    throw new RuntimeException('INSUFFICIENT_CURRENCY');
                }
                throw $e;
            }

            $seed = random_int(1, PHP_INT_MAX);
            $draw = $this->drawFromSeed($seed);
            $rarity = $this->pickRarity($rates, $draw);
            $card = $this->pickCard($rarity, $seed);
            if (! $card) {
                throw new RuntimeException('SUMMON_POOL_EMPTY');
            }

            $owned = PlayerCard::query()
                ->where('user_id', $user->id)
                ->where('card_definition_id', $card->id)
                ->exists();

            $shards = 0;
            if ($owned) {
                $shards = (int) ($banner['duplicate_shards'][$rarity] ?? 1);
                if ($shards > 0) {
                    $profile = $this->economy->apply(
                        $profile,
                        EconomyService::CURRENCY_VOID_SHARDS,
                        $shards,
                        'summon_duplicate',
                        'card',
                        $card->code,
                        $clientSummonId,
                    );
                }
            } else {
                PlayerCard::create([
                    'user_id' => $user->id,
                    'card_definition_id' => $card->id,
                    'level' => 1,
                ]);
            }

            SummonRoll::create([
                'user_id' => $user->id,
                'banner_code' => $banner['code'],
                'client_summon_id' => $clientSummonId,
                'rng_seed' => $seed,
                'rng_draw' => $draw,
                'result_rarity' => $rarity,
                'result_card_code' => $card->code,
                'was_duplicate' => $owned,
                'shards_granted' => $shards,
                'cost_currency' => $banner['cost_currency'],
                'cost_amount' => $banner['cost_amount'],
            ]);

            $payload = [
                'banner_code' => $banner['code'],
                'result' => [
                    'card' => $card->toApiArray(),
                    'rarity' => $rarity,
                    'was_duplicate' => $owned,
                    'void_shards_granted' => $shards,
                ],
                'rng' => [
                    'seed' => $seed,
                    'draw' => $draw,
                ],
                'profile' => $profile->fresh()->toApiArray(),
            ];

            IdempotencyKey::create([
                'user_id' => $user->id,
                'scope' => $scope,
                'key' => $clientSummonId,
                'response_json' => $payload,
                'status_code' => 201,
            ]);

            SecurityLog::economy('summon_pull', [
                'user_id' => $user->id,
                'banner' => $banner['code'],
                'card' => $card->code,
                'duplicate' => $owned,
            ]);

            return ['replay' => false, 'payload' => $payload, 'status' => 201];
        });
    }

    private function drawFromSeed(int $seed): int
    {
        // Deterministic 0..9999 from seed for audit replay.
        return (int) ($seed % 10000);
    }

    /**
     * @param  array<string,int>  $rates
     */
    private function pickRarity(array $rates, int $draw): string
    {
        $cursor = 0;
        foreach ($rates as $rarity => $bp) {
            $cursor += (int) $bp;
            if ($draw < $cursor) {
                return (string) $rarity;
            }
        }

        return array_key_last($rates) ?: 'common';
    }

    private function pickCard(string $rarity, int $seed): ?CardDefinition
    {
        $pool = CardDefinition::query()
            ->where('is_published', true)
            ->where('rarity', $rarity)
            ->orderBy('id')
            ->get();

        if ($pool->isEmpty()) {
            // Fallback down the rarity ladder so pulls never hard-fail on empty tiers.
            $order = ['supreme', 'mythic', 'legendary', 'epic', 'superRare', 'rare', 'uncommon', 'common'];
            foreach ($order as $fallback) {
                $pool = CardDefinition::query()
                    ->where('is_published', true)
                    ->where('rarity', $fallback)
                    ->orderBy('id')
                    ->get();
                if ($pool->isNotEmpty()) {
                    break;
                }
            }
        }

        if ($pool->isEmpty()) {
            return null;
        }

        $index = (int) (($seed / 10000) % $pool->count());

        return $pool[$index];
    }
}
