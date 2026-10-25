<?php

namespace App\Support;

use App\Models\EconomyLedgerEntry;
use App\Models\PlayerProfile;
use InvalidArgumentException;

final class EconomyService
{
    public const CURRENCY_AETHER = 'aether';
    public const CURRENCY_VOID_SHARDS = 'void_shards';
    public const CURRENCY_RIFT_MARKS = 'rift_marks';

    /**
     * Mutate balance and append ledger row. Caller must wrap in a transaction.
     */
    public function apply(
        PlayerProfile $profile,
        string $currencyCode,
        int $delta,
        string $reasonCode,
        ?string $referenceType = null,
        ?string $referenceId = null,
        ?string $requestId = null,
    ): PlayerProfile {
        if ($delta === 0) {
            return $profile;
        }

        [$field, $max] = match ($currencyCode) {
            self::CURRENCY_AETHER => ['aether', PlayerProfile::AETHER_MAX],
            self::CURRENCY_VOID_SHARDS => ['void_shards', PlayerProfile::VOID_SHARDS_MAX],
            self::CURRENCY_RIFT_MARKS => ['rift_marks', PlayerProfile::RIFT_MARKS_MAX],
            default => throw new InvalidArgumentException("Unknown currency {$currencyCode}"),
        };

        $current = (int) $profile->{$field};
        $next = $current + $delta;
        if ($next < 0) {
            throw new InvalidArgumentException('INSUFFICIENT_CURRENCY');
        }
        if ($next > $max) {
            $next = $max;
            $delta = $next - $current;
        }

        $profile->{$field} = $next;
        $profile->save();

        EconomyLedgerEntry::create([
            'user_id' => $profile->user_id,
            'currency_code' => $currencyCode,
            'delta' => $delta,
            'balance_after' => $next,
            'reason_code' => $reasonCode,
            'reference_type' => $referenceType,
            'reference_id' => $referenceId,
            'request_id' => $requestId,
        ]);

        return $profile->fresh();
    }
}
