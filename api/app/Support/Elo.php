<?php

namespace App\Support;

/**
 * Integer-only Elo. Expected scores from a precomputed millipoint table.
 */
final class Elo
{
    /**
     * @return array{rating_a:int,rating_b:int,delta_a:int,delta_b:int}
     */
    public static function settle(int $ratingA, int $ratingB, string $outcomeForA): array
    {
        $scoreA = match ($outcomeForA) {
            'win' => 1000,
            'draw' => 500,
            'loss' => 0,
            default => 500,
        };

        $expA = self::expectedMillipoints($ratingA, $ratingB);
        $expB = 1000 - $expA;
        $k = (int) config('ranking.k_factor', 32);

        $deltaA = intdiv($k * ($scoreA - $expA), 1000);
        $deltaB = intdiv($k * ((1000 - $scoreA) - $expB), 1000);

        $min = (int) config('ranking.min_rating', 100);
        $max = (int) config('ranking.max_rating', 3000);

        $nextA = max($min, min($max, $ratingA + $deltaA));
        $nextB = max($min, min($max, $ratingB + $deltaB));

        return [
            'rating_a' => $nextA,
            'rating_b' => $nextB,
            'delta_a' => $nextA - $ratingA,
            'delta_b' => $nextB - $ratingB,
        ];
    }

    public static function expectedMillipoints(int $rating, int $opponent): int
    {
        $diff = $opponent - $rating;
        $key = (int) round($diff / 40);
        $key = max(-30, min(30, $key));
        $table = config('ranking.expected_table', []);

        return (int) ($table[$key] ?? 500);
    }
}
