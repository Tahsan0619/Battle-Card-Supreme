<?php

namespace App\Support;

final class StatBudget
{
    public const COMMON_BASE = 1000;

    /** @var array<string, int> */
    public const RARITY_PERCENT = [
        'common' => 100,
        'uncommon' => 108,
        'rare' => 118,
        'superRare' => 128,
        'epic' => 140,
        'legendary' => 155,
        'mythic' => 170,
        'supreme' => 185,
    ];

    /** @var array<string, array<string, int>> */
    public const ROLE_WEIGHTS = [
        'tank' => ['hp' => 40, 'atk' => 10, 'def' => 30, 'spd' => 10, 'en' => 10],
        'attacker' => ['hp' => 20, 'atk' => 40, 'def' => 15, 'spd' => 15, 'en' => 10],
        'support' => ['hp' => 30, 'atk' => 10, 'def' => 20, 'spd' => 15, 'en' => 25],
        'assassin' => ['hp' => 15, 'atk' => 40, 'def' => 10, 'spd' => 25, 'en' => 10],
        'mage' => ['hp' => 18, 'atk' => 35, 'def' => 12, 'spd' => 15, 'en' => 20],
        'strategist' => ['hp' => 25, 'atk' => 20, 'def' => 20, 'spd' => 15, 'en' => 20],
        'skirmisher' => ['hp' => 18, 'atk' => 25, 'def' => 12, 'spd' => 35, 'en' => 10],
        'summoner' => ['hp' => 22, 'atk' => 20, 'def' => 18, 'spd' => 15, 'en' => 25],
    ];

    /**
     * @return array{hp:int,atk:int,def:int,spd:int,en:int}
     */
    public static function divide(string $rarity, string $role): array
    {
        $percent = self::RARITY_PERCENT[$rarity] ?? 100;
        $total = intdiv(self::COMMON_BASE * $percent, 100);
        $weights = self::ROLE_WEIGHTS[$role] ?? self::ROLE_WEIGHTS['attacker'];
        $weightSum = array_sum($weights);

        $alloc = static function (string $key) use ($total, $weights, $weightSum): int {
            return intdiv($total * ($weights[$key] ?? 0), $weightSum);
        };

        $hp = max(50, min($total, $alloc('hp')));
        $atk = max(10, min(intdiv($total, 2), $alloc('atk')));
        $def = max(10, min(intdiv($total, 2), $alloc('def')));
        $spd = max(5, min(intdiv($total, 3), $alloc('spd')));
        $en = max(5, min(intdiv($total, 3), $alloc('en')));

        $used = $hp + $atk + $def + $spd + $en;
        if ($used < $total) {
            $hp += $total - $used;
        } elseif ($used > $total) {
            $hp = max(50, $hp - ($used - $total));
        }

        return compact('hp', 'atk', 'def', 'spd', 'en');
    }
}
