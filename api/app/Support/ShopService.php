<?php

namespace App\Support;

use App\Models\DailyClaim;
use App\Models\IdempotencyKey;
use App\Models\PlayerProfile;
use App\Models\ShopPurchase;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;
use RuntimeException;

final class ShopService
{
    public function __construct(
        private ProgressService $progress,
        private EconomyService $economy,
    ) {}

    public function catalogue(): array
    {
        return [
            'offers' => config('shop.offers', []),
            'daily' => config('shop.daily', []),
            'server_date_utc' => Carbon::now('UTC')->toDateString(),
        ];
    }

    /**
     * @return array{replay:bool,payload:array,status:int}
     */
    public function purchase(User $user, string $offerCode, string $clientPurchaseId): array
    {
        $scope = 'shop_purchase';
        if ($cached = $this->idempotent($user->id, $scope, $clientPurchaseId)) {
            return $cached;
        }

        $offer = collect(config('shop.offers', []))->firstWhere('code', $offerCode);
        if (! $offer) {
            throw new RuntimeException('OFFER_NOT_FOUND');
        }

        return DB::transaction(function () use ($user, $offer, $clientPurchaseId, $scope) {
            $profile = $this->progress->ensureProfile($user->id);
            $profile = $this->progress->refreshEnergy($profile);

            try {
                $profile = $this->economy->apply(
                    $profile,
                    $offer['cost_currency'],
                    -1 * (int) $offer['cost_amount'],
                    'shop_purchase',
                    'shop_offer',
                    $offer['code'],
                    $clientPurchaseId,
                );
            } catch (InvalidArgumentException $e) {
                if ($e->getMessage() === 'INSUFFICIENT_CURRENCY') {
                    throw new RuntimeException('INSUFFICIENT_CURRENCY');
                }
                throw $e;
            }

            $grantResult = $this->applyGrant($profile, $offer['grant'], $clientPurchaseId);
            $profile = $grantResult['profile'];

            ShopPurchase::create([
                'user_id' => $user->id,
                'offer_code' => $offer['code'],
                'client_purchase_id' => $clientPurchaseId,
                'cost_currency' => $offer['cost_currency'],
                'cost_amount' => $offer['cost_amount'],
                'grant_json' => $grantResult['grant'],
            ]);

            $payload = [
                'offer_code' => $offer['code'],
                'grant' => $grantResult['grant'],
                'profile' => $profile->toApiArray(),
            ];

            $this->storeIdempotent($user->id, $scope, $clientPurchaseId, $payload, 201);
            SecurityLog::economy('shop_purchase', [
                'user_id' => $user->id,
                'offer' => $offer['code'],
            ]);

            return ['replay' => false, 'payload' => $payload, 'status' => 201];
        });
    }

    /**
     * @return array{replay:bool,payload:array,status:int}
     */
    public function claimDaily(User $user, string $clientClaimId): array
    {
        $scope = 'daily_claim';
        if ($cached = $this->idempotent($user->id, $scope, $clientClaimId)) {
            return $cached;
        }

        $today = Carbon::now('UTC')->toDateString();
        $existing = DailyClaim::query()
            ->where('user_id', $user->id)
            ->whereDate('claim_date', $today)
            ->first();

        if ($existing) {
            $profile = $this->progress->ensureProfile($user->id);
            $payload = [
                'already_claimed' => true,
                'claim_date' => $today,
                'profile' => $profile->toApiArray(),
            ];
            $this->storeIdempotent($user->id, $scope, $clientClaimId, $payload, 200);

            return ['replay' => true, 'payload' => $payload, 'status' => 200];
        }

        return DB::transaction(function () use ($user, $clientClaimId, $scope, $today) {
            $locked = DailyClaim::query()
                ->where('user_id', $user->id)
                ->whereDate('claim_date', $today)
                ->lockForUpdate()
                ->first();
            if ($locked) {
                $profile = $this->progress->ensureProfile($user->id);
                $payload = [
                    'already_claimed' => true,
                    'claim_date' => $today,
                    'profile' => $profile->toApiArray(),
                ];
                $this->storeIdempotent($user->id, $scope, $clientClaimId, $payload, 200);

                return ['replay' => true, 'payload' => $payload, 'status' => 200];
            }

            $aether = (int) config('shop.daily.aether', 25);
            $shards = (int) config('shop.daily.void_shards', 1);
            $profile = $this->progress->ensureProfile($user->id);
            if ($aether > 0) {
                $profile = $this->economy->apply(
                    $profile,
                    EconomyService::CURRENCY_AETHER,
                    $aether,
                    'daily_claim',
                    'daily',
                    $today,
                    $clientClaimId,
                );
            }
            if ($shards > 0) {
                $profile = $this->economy->apply(
                    $profile,
                    EconomyService::CURRENCY_VOID_SHARDS,
                    $shards,
                    'daily_claim',
                    'daily',
                    $today,
                    $clientClaimId,
                );
            }

            DailyClaim::create([
                'user_id' => $user->id,
                'claim_date' => $today,
                'aether_granted' => $aether,
                'void_shards_granted' => $shards,
                'client_claim_id' => $clientClaimId,
            ]);

            $payload = [
                'already_claimed' => false,
                'claim_date' => $today,
                'aether_granted' => $aether,
                'void_shards_granted' => $shards,
                'profile' => $profile->toApiArray(),
            ];
            $this->storeIdempotent($user->id, $scope, $clientClaimId, $payload, 201);
            SecurityLog::economy('daily_claim', ['user_id' => $user->id, 'date' => $today]);

            return ['replay' => false, 'payload' => $payload, 'status' => 201];
        });
    }

    /**
     * @param  array<string,mixed>  $grant
     * @return array{profile:PlayerProfile,grant:array}
     */
    private function applyGrant(PlayerProfile $profile, array $grant, string $requestId): array
    {
        $type = $grant['type'] ?? '';
        if ($type === 'energy_full') {
            $profile->energy = (int) $profile->energy_max;
            $profile->energy_updated_at = now();
            $profile->save();

            return [
                'profile' => $profile->fresh(),
                'grant' => ['type' => 'energy_full', 'energy' => $profile->energy],
            ];
        }

        if ($type === 'currency') {
            $currency = $grant['currency'] ?? '';
            $amount = (int) ($grant['amount'] ?? 0);
            $profile = $this->economy->apply(
                $profile,
                $currency,
                $amount,
                'shop_grant',
                'shop_offer',
                $currency,
                $requestId,
            );

            return [
                'profile' => $profile,
                'grant' => ['type' => 'currency', 'currency' => $currency, 'amount' => $amount],
            ];
        }

        throw new RuntimeException('INVALID_GRANT');
    }

    private function idempotent(int $userId, string $scope, string $key): ?array
    {
        $row = IdempotencyKey::query()
            ->where('user_id', $userId)
            ->where('scope', $scope)
            ->where('key', $key)
            ->first();
        if (! $row) {
            return null;
        }

        return [
            'replay' => true,
            'payload' => $row->response_json ?? [],
            'status' => 200,
        ];
    }

    private function storeIdempotent(int $userId, string $scope, string $key, array $payload, int $status): void
    {
        IdempotencyKey::create([
            'user_id' => $userId,
            'scope' => $scope,
            'key' => $key,
            'response_json' => $payload,
            'status_code' => $status,
        ]);
    }
}
