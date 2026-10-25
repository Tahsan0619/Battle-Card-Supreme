<?php

namespace App\Support;

use App\Models\GameMatch;
use App\Models\PlayerRating;
use App\Models\RatingLedgerEntry;
use App\Models\User;
use Illuminate\Support\Facades\DB;

final class RankingService
{
    public function season(): string
    {
        return (string) config('ranking.season_code', 'foundation');
    }

    public function ensure(User|int $user): PlayerRating
    {
        $userId = $user instanceof User ? $user->id : $user;

        return PlayerRating::firstOrCreate(
            [
                'user_id' => $userId,
                'season_code' => $this->season(),
            ],
            [
                'rating' => (int) config('ranking.start_rating', 1000),
                'wins' => 0,
                'losses' => 0,
                'draws' => 0,
            ]
        );
    }

    public function me(User $user): array
    {
        $row = $this->ensure($user)->load('user');
        $rank = PlayerRating::query()
            ->where('season_code', $this->season())
            ->where(function ($q) use ($row) {
                $q->where('rating', '>', $row->rating)
                    ->orWhere(function ($q2) use ($row) {
                        $q2->where('rating', $row->rating)->where('id', '<', $row->id);
                    });
            })
            ->count() + 1;

        return $row->toApiArray($rank);
    }

    public function leaderboard(int $limit = 50): array
    {
        $limit = max(1, min(100, $limit));
        $rows = PlayerRating::query()
            ->with('user')
            ->where('season_code', $this->season())
            ->orderByDesc('rating')
            ->orderBy('id')
            ->limit($limit)
            ->get();

        $out = [];
        $rank = 1;
        foreach ($rows as $row) {
            $out[] = $row->toApiArray($rank);
            $rank++;
        }

        return [
            'season_code' => $this->season(),
            'entries' => $out,
        ];
    }

    /**
     * Apply Elo once when a ranked PvP match reaches a terminal outcome.
     */
    public function applyMatchIfNeeded(GameMatch $match): void
    {
        if (! (bool) config('bcs.feature_flags.ranking', true)) {
            return;
        }
        if (! $match->is_pvp || $match->ranking_applied) {
            return;
        }
        if (! $match->opponent_user_id) {
            return;
        }
        if ($match->outcome === 'ongoing') {
            return;
        }

        // Mode must be ranking-eligible when rules present.
        $rules = $match->mode_rules_snapshot ?? [];
        if (array_key_exists('ranking_eligible', $rules) && ! $rules['ranking_eligible']) {
            return;
        }

        DB::transaction(function () use ($match) {
            /** @var GameMatch $locked */
            $locked = GameMatch::query()->whereKey($match->id)->lockForUpdate()->firstOrFail();
            if ($locked->ranking_applied || $locked->outcome === 'ongoing') {
                return;
            }

            $host = $this->ensure((int) $locked->user_id);
            $guest = $this->ensure((int) $locked->opponent_user_id);
            $host = PlayerRating::query()->whereKey($host->id)->lockForUpdate()->firstOrFail();
            $guest = PlayerRating::query()->whereKey($guest->id)->lockForUpdate()->firstOrFail();

            $hostResult = match ($locked->outcome) {
                'victory_player' => 'win',
                'victory_enemy' => 'loss',
                'draw' => 'draw',
                'forfeit_player' => 'loss',
                default => 'draw',
            };

            // Guest concede already mapped to victory_player for host.
            $hostBefore = (int) $host->rating;
            $guestBefore = (int) $guest->rating;
            $settled = Elo::settle($hostBefore, $guestBefore, $hostResult);
            $guestResult = match ($hostResult) {
                'win' => 'loss',
                'loss' => 'win',
                default => 'draw',
            };

            $this->writeResult($host, $locked, $guestBefore, $settled['delta_a'], $settled['rating_a'], $hostResult);
            $this->writeResult($guest, $locked, $hostBefore, $settled['delta_b'], $settled['rating_b'], $guestResult);

            $locked->ranking_applied = true;
            $locked->save();

            SecurityLog::match('ranking_applied', [
                'match_id' => $locked->id,
                'host_delta' => $settled['delta_a'],
                'guest_delta' => $settled['delta_b'],
                'outcome' => $locked->outcome,
            ]);
        });
    }

    private function writeResult(
        PlayerRating $row,
        GameMatch $match,
        int $opponentRating,
        int $delta,
        int $after,
        string $result,
    ): void {
        $before = (int) $row->rating;
        RatingLedgerEntry::create([
            'user_id' => $row->user_id,
            'season_code' => $row->season_code,
            'match_id' => $match->id,
            'rating_before' => $before,
            'rating_delta' => $delta,
            'rating_after' => $after,
            'opponent_rating' => $opponentRating,
            'result' => $result,
        ]);

        $row->rating = $after;
        if ($result === 'win') {
            $row->wins++;
        } elseif ($result === 'loss') {
            $row->losses++;
        } else {
            $row->draws++;
        }
        $row->save();
    }
}
