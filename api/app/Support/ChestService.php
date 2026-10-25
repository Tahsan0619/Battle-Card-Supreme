<?php

namespace App\Support;

use App\Models\CardDefinition;
use App\Models\ChestOpen;
use App\Models\IdempotencyKey;
use App\Models\PlayerCard;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use RuntimeException;

final class ChestService
{
    public function __construct(
        private ProgressService $progress,
        private EconomyService $economy,
        private CollectionService $collection,
    ) {}

    public function catalogue(User $user): array
    {
        $profile = $this->progress->ensureProfile($user->id);
        $keysCfg = config('chests.keys', []);
        $chests = config('chests.chests', []);

        return [
            'currency' => [
                'rift_marks' => (int) $profile->rift_marks,
                'aether' => (int) $profile->aether,
            ],
            'keys' => [
                'iron' => [
                    ...$keysCfg['iron'],
                    'owned' => (int) $profile->key_iron,
                ],
                'silver' => [
                    ...$keysCfg['silver'],
                    'owned' => (int) $profile->key_silver,
                ],
                'gold' => [
                    ...$keysCfg['gold'],
                    'owned' => (int) $profile->key_gold,
                ],
            ],
            'chests' => array_map(function (array $c) {
                $rates = $c['rates_bp'] ?? [];

                return [
                    'code' => $c['code'],
                    'title' => $c['title'],
                    'tier' => $c['tier'],
                    'description' => $c['description'],
                    'key_code' => $c['key_code'],
                    'keys_required' => $c['keys_required'],
                    'pull_count' => $c['pull_count'],
                    'probability_disclosure' => [
                        'unit' => 'basis_points_per_10000',
                        'total_bp' => array_sum($rates),
                        'rates_bp' => $rates,
                        'rates_percent' => collect($rates)->map(fn ($bp) => round($bp / 100, 2))->all(),
                    ],
                ];
            }, $chests),
            'profile' => $profile->toApiArray(),
        ];
    }

    /**
     * @return array{replay:bool,payload:array,status:int}
     */
    public function buyKey(User $user, string $keyCode, string $clientPurchaseId): array
    {
        $scope = 'key_purchase';
        $existing = IdempotencyKey::query()
            ->where('user_id', $user->id)
            ->where('scope', $scope)
            ->where('key', $clientPurchaseId)
            ->first();
        if ($existing) {
            return ['replay' => true, 'payload' => $existing->response_json ?? [], 'status' => 200];
        }

        $cfg = config("chests.keys.{$keyCode}");
        if (! $cfg) {
            throw new RuntimeException('KEY_NOT_FOUND');
        }

        return DB::transaction(function () use ($user, $cfg, $keyCode, $clientPurchaseId, $scope) {
            $profile = $this->progress->ensureProfile($user->id);
            try {
                $profile = $this->economy->apply(
                    $profile,
                    $cfg['shop_cost_currency'],
                    -1 * (int) $cfg['shop_cost_amount'],
                    'key_purchase',
                    'rift_key',
                    $keyCode,
                    $clientPurchaseId,
                );
            } catch (InvalidArgumentException $e) {
                if ($e->getMessage() === 'INSUFFICIENT_CURRENCY') {
                    throw new RuntimeException('INSUFFICIENT_CURRENCY');
                }
                throw $e;
            }

            $field = match ($keyCode) {
                'iron' => 'key_iron',
                'silver' => 'key_silver',
                'gold' => 'key_gold',
                default => throw new RuntimeException('KEY_NOT_FOUND'),
            };
            $profile->{$field} = (int) $profile->{$field} + 1;
            $profile->save();

            $payload = [
                'key_code' => $keyCode,
                'profile' => $profile->fresh()->toApiArray(),
            ];
            IdempotencyKey::create([
                'user_id' => $user->id,
                'scope' => $scope,
                'key' => $clientPurchaseId,
                'response_json' => $payload,
                'status_code' => 201,
            ]);
            SecurityLog::economy('key_purchase', [
                'user_id' => $user->id,
                'key' => $keyCode,
            ]);

            return ['replay' => false, 'payload' => $payload, 'status' => 201];
        });
    }

    /**
     * @return array{replay:bool,payload:array,status:int}
     */
    public function open(User $user, string $chestCode, string $clientOpenId): array
    {
        $scope = 'chest_open';
        $existing = IdempotencyKey::query()
            ->where('user_id', $user->id)
            ->where('scope', $scope)
            ->where('key', $clientOpenId)
            ->first();
        if ($existing) {
            return ['replay' => true, 'payload' => $existing->response_json ?? [], 'status' => 200];
        }

        $chest = collect(config('chests.chests', []))->firstWhere('code', $chestCode);
        if (! $chest) {
            throw new RuntimeException('CHEST_NOT_FOUND');
        }
        $rates = $chest['rates_bp'] ?? [];
        if (array_sum($rates) !== 10000) {
            throw new RuntimeException('CHEST_MISCONFIGURED');
        }

        return DB::transaction(function () use ($user, $chest, $clientOpenId, $scope, $rates) {
            $profile = $this->progress->ensureProfile($user->id);
            $keyCode = $chest['key_code'];
            $need = (int) $chest['keys_required'];
            $field = match ($keyCode) {
                'iron' => 'key_iron',
                'silver' => 'key_silver',
                'gold' => 'key_gold',
                default => throw new RuntimeException('KEY_NOT_FOUND'),
            };
            if ((int) $profile->{$field} < $need) {
                throw new RuntimeException('INSUFFICIENT_KEYS');
            }
            $profile->{$field} = (int) $profile->{$field} - $need;
            $profile->save();

            $seed = random_int(1, PHP_INT_MAX);
            $results = [];
            $pulls = (int) $chest['pull_count'];
            for ($i = 0; $i < $pulls; $i++) {
                $draw = $this->drawFromSeed($seed, $i);
                $rarity = $this->pickRarity($rates, $draw);
                $card = $this->pickCard($rarity, $seed + $i);
                if (! $card) {
                    continue;
                }
                $grant = $this->collection->grantOrCopy($user, $card);
                $results[] = [
                    'card' => $card->toApiArray(),
                    'rarity' => $rarity,
                    'was_new' => $grant['was_new'],
                    'level' => $grant['level'],
                    'copies' => $grant['copies'],
                ];
            }

            ChestOpen::create([
                'user_id' => $user->id,
                'chest_code' => $chest['code'],
                'client_open_id' => $clientOpenId,
                'key_code' => $keyCode,
                'keys_spent' => $need,
                'rng_seed' => $seed,
                'results_json' => $results,
            ]);

            $payload = [
                'chest_code' => $chest['code'],
                'results' => $results,
                'profile' => $profile->fresh()->toApiArray(),
            ];
            IdempotencyKey::create([
                'user_id' => $user->id,
                'scope' => $scope,
                'key' => $clientOpenId,
                'response_json' => $payload,
                'status_code' => 201,
            ]);
            SecurityLog::economy('chest_open', [
                'user_id' => $user->id,
                'chest' => $chest['code'],
                'pulls' => count($results),
            ]);

            return ['replay' => false, 'payload' => $payload, 'status' => 201];
        });
    }

    private function drawFromSeed(int $seed, int $offset = 0): int
    {
        return abs(crc32($seed.'|'.$offset)) % 10000;
    }

    private function pickRarity(array $ratesBp, int $draw): string
    {
        $cursor = 0;
        foreach ($ratesBp as $rarity => $bp) {
            $cursor += (int) $bp;
            if ($draw < $cursor) {
                return (string) $rarity;
            }
        }

        return array_key_first($ratesBp) ?: 'common';
    }

    private function pickCard(string $rarity, int $seed): ?CardDefinition
    {
        $pool = CardDefinition::query()
            ->where('is_published', true)
            ->where('rarity', $rarity)
            ->orderBy('id')
            ->get();
        if ($pool->isEmpty()) {
            $pool = CardDefinition::query()
                ->where('is_published', true)
                ->where('rarity', 'common')
                ->orderBy('id')
                ->get();
        }
        if ($pool->isEmpty()) {
            return null;
        }

        return $pool[abs($seed) % $pool->count()];
    }
}
