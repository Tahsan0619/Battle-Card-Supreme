<?php

namespace App\Support;

use App\Combat\CombatEngine;
use App\Models\BalanceVersion;
use App\Models\CardDefinition;
use App\Models\GameMatch;
use App\Models\MatchmakingQueueEntry;
use App\Models\MatchOffer;
use App\Models\PlayerCard;
use App\Models\Team;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use RuntimeException;

final class PvpMatchmakingService
{
    public function __construct(
        private CombatEngine $engine,
        private ModeCatalog $modes,
    ) {}

    public function status(User $user): array
    {
        $this->expireStaleOffers();

        $queue = MatchmakingQueueEntry::query()
            ->where('user_id', $user->id)
            ->whereIn('status', ['queued', 'offered'])
            ->orderByDesc('id')
            ->first();

        $offer = MatchOffer::query()
            ->where(function ($q) use ($user) {
                $q->where('user_a_id', $user->id)->orWhere('user_b_id', $user->id);
            })
            ->whereIn('status', ['pending', 'ready'])
            ->orderByDesc('id')
            ->first();

        $match = GameMatch::query()
            ->where('is_pvp', true)
            ->where('outcome', 'ongoing')
            ->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)->orWhere('opponent_user_id', $user->id);
            })
            ->orderByDesc('id')
            ->first();

        return [
            'queue' => $queue ? [
                'id' => $queue->id,
                'status' => $queue->status,
                'card_codes' => $queue->card_codes,
                'offer_id' => $queue->offer_id,
            ] : null,
            'offer' => $offer ? $this->offerPayload($offer, $user->id) : null,
            'match_id' => $match?->id,
            'accept_window_seconds' => (int) config('pvp.accept_window_seconds', 30),
        ];
    }

    /**
     * @param  list<string>|null  $cardCodes
     */
    public function enqueue(User $user, ?array $cardCodes = null): array
    {
        $this->expireStaleOffers();
        $codes = $this->resolveCardCodes($user, $cardCodes);

        return DB::transaction(function () use ($user, $codes) {
            MatchmakingQueueEntry::query()
                ->where('user_id', $user->id)
                ->whereIn('status', ['queued', 'offered'])
                ->update(['status' => 'cancelled']);

            $entry = MatchmakingQueueEntry::create([
                'user_id' => $user->id,
                'card_codes' => $codes,
                'status' => 'queued',
            ]);

            $opponent = MatchmakingQueueEntry::query()
                ->where('status', 'queued')
                ->where('user_id', '!=', $user->id)
                ->orderBy('id')
                ->lockForUpdate()
                ->first();

            if (! $opponent) {
                return $this->status($user->fresh());
            }

            $offer = MatchOffer::create([
                'user_a_id' => $opponent->user_id,
                'user_b_id' => $user->id,
                'cards_a' => $opponent->card_codes,
                'cards_b' => $codes,
                'status' => 'pending',
                'accept_a' => false,
                'accept_b' => false,
                'expires_at' => Carbon::now()->addSeconds((int) config('pvp.accept_window_seconds', 30)),
            ]);

            $opponent->update(['status' => 'offered', 'offer_id' => $offer->id]);
            $entry->update(['status' => 'offered', 'offer_id' => $offer->id]);

            SecurityLog::match('pvp_offer_created', [
                'offer_id' => $offer->id,
                'user_a' => $offer->user_a_id,
                'user_b' => $offer->user_b_id,
            ]);

            return $this->status($user->fresh());
        });
    }

    public function leaveQueue(User $user): array
    {
        MatchmakingQueueEntry::query()
            ->where('user_id', $user->id)
            ->whereIn('status', ['queued', 'offered'])
            ->update(['status' => 'cancelled']);

        return $this->status($user);
    }

    public function accept(User $user, MatchOffer $offer): array
    {
        $this->expireStaleOffers();
        $offer->refresh();

        if (! $offer->isParticipant($user->id)) {
            throw new RuntimeException('FORBIDDEN');
        }
        if ($offer->status !== 'pending') {
            if ($offer->status === 'ready' && $offer->match_id) {
                return $this->status($user);
            }
            throw new RuntimeException('OFFER_NOT_PENDING');
        }
        if ($offer->expires_at->isPast()) {
            $this->markExpired($offer);
            throw new RuntimeException('OFFER_EXPIRED');
        }

        return DB::transaction(function () use ($user, $offer) {
            /** @var MatchOffer $locked */
            $locked = MatchOffer::query()->whereKey($offer->id)->lockForUpdate()->firstOrFail();
            if ($locked->status !== 'pending') {
                return $this->status($user);
            }

            if ((int) $locked->user_a_id === (int) $user->id) {
                $locked->accept_a = true;
            } else {
                $locked->accept_b = true;
            }
            $locked->save();

            if ($locked->accept_a && $locked->accept_b) {
                $match = $this->createPvpMatch($locked);
                $locked->status = 'ready';
                $locked->match_id = $match->id;
                $locked->save();

                MatchmakingQueueEntry::query()
                    ->where('offer_id', $locked->id)
                    ->update(['status' => 'cancelled']);

                SecurityLog::match('pvp_match_started', [
                    'offer_id' => $locked->id,
                    'match_id' => $match->id,
                ]);
            }

            return $this->status($user);
        });
    }

    public function decline(User $user, MatchOffer $offer): array
    {
        if (! $offer->isParticipant($user->id)) {
            throw new RuntimeException('FORBIDDEN');
        }

        DB::transaction(function () use ($offer) {
            $locked = MatchOffer::query()->whereKey($offer->id)->lockForUpdate()->firstOrFail();
            if ($locked->status === 'pending') {
                $locked->status = 'declined';
                $locked->save();
                MatchmakingQueueEntry::query()
                    ->where('offer_id', $locked->id)
                    ->update(['status' => 'cancelled']);
            }
        });

        return $this->status($user);
    }

    private function createPvpMatch(MatchOffer $offer): GameMatch
    {
        $modeCode = config('pvp.mode_code', 'pvp_clash');
        $resolved = $this->modes->resolve($modeCode, false);
        if ($resolved === null) {
            // Fall back to online_clash rules if pvp mode not seeded yet.
            $resolved = $this->modes->resolve('online_clash', false);
        }
        if ($resolved === null) {
            throw new RuntimeException('MODE_UNAVAILABLE');
        }

        $rules = $resolved['rules']->rules_json ?? [];
        $maxRounds = (int) ($rules['max_rounds'] ?? 30);

        $playerCards = CardDefinition::whereIn('code', $offer->cards_a)->get()->keyBy('code');
        $enemyCards = CardDefinition::whereIn('code', $offer->cards_b)->get()->keyBy('code');

        $playerSnap = [];
        foreach ($offer->cards_a as $code) {
            $playerSnap[] = $playerCards[$code]->toArray();
        }
        $enemySnap = [];
        foreach ($offer->cards_b as $code) {
            $enemySnap[] = $enemyCards[$code]->toArray();
        }

        $state = $this->engine->start($playerSnap, $enemySnap, $maxRounds);
        // No AI drain for PvP.

        $balanceVersion = BalanceVersion::query()->where('is_current', true)->value('version') ?? 1;

        return GameMatch::create([
            'user_id' => $offer->user_a_id,
            'opponent_user_id' => $offer->user_b_id,
            'mode' => $resolved['mode']->code ?? $modeCode,
            'is_pvp' => true,
            'host_seat' => 'player',
            'mode_rule_version' => $resolved['rules']->version ?? 1,
            'mode_rules_snapshot' => $rules,
            'balance_version' => $balanceVersion,
            'outcome' => $state['outcome'],
            'state_version' => 1,
            'state_json' => $state,
            'player_snapshot' => $playerSnap,
            'enemy_snapshot' => $enemySnap,
            'max_rounds' => $maxRounds,
            'rng_seed' => random_int(1, 999999),
        ]);
    }

    /**
     * @param  list<string>|null  $cardCodes
     * @return list<string>
     */
    private function resolveCardCodes(User $user, ?array $cardCodes): array
    {
        if ($cardCodes === null) {
            $team = $user->teams()->with('slots.cardDefinition')
                ->where('is_active', true)->orderBy('id')->first();
            if (! $team instanceof Team || $team->slots->count() < 3) {
                throw new RuntimeException('TEAM_INVALID');
            }
            $cardCodes = $team->slots->sortBy('slot_index')->map(
                fn ($s) => $s->cardDefinition?->code
            )->filter()->values()->all();
        }

        if (count($cardCodes) !== 3 || count($cardCodes) !== count(array_unique($cardCodes))) {
            throw new RuntimeException('TEAM_INVALID');
        }

        foreach ($cardCodes as $code) {
            $card = CardDefinition::where('code', $code)->where('is_published', true)->first();
            if (! $card) {
                throw new RuntimeException('CARD_NOT_FOUND');
            }
            $owned = PlayerCard::where('user_id', $user->id)
                ->where('card_definition_id', $card->id)
                ->exists();
            if (! $owned) {
                throw new RuntimeException('CARD_NOT_OWNED');
            }
        }

        return array_values($cardCodes);
    }

    private function expireStaleOffers(): void
    {
        $stale = MatchOffer::query()
            ->where('status', 'pending')
            ->where('expires_at', '<', now())
            ->get();

        foreach ($stale as $offer) {
            $this->markExpired($offer);
        }
    }

    private function markExpired(MatchOffer $offer): void
    {
        $offer->status = 'expired';
        $offer->save();
        MatchmakingQueueEntry::query()
            ->where('offer_id', $offer->id)
            ->update(['status' => 'cancelled']);
    }

    private function offerPayload(MatchOffer $offer, int $viewerId): array
    {
        return [
            'id' => $offer->id,
            'status' => $offer->status,
            'expires_at' => $offer->expires_at?->toIso8601String(),
            'you_are' => (int) $offer->user_a_id === $viewerId ? 'a' : 'b',
            'accept_a' => $offer->accept_a,
            'accept_b' => $offer->accept_b,
            'you_accepted' => (int) $offer->user_a_id === $viewerId
                ? $offer->accept_a
                : $offer->accept_b,
            'match_id' => $offer->match_id,
            'opponent_user_id' => (int) $offer->user_a_id === $viewerId
                ? $offer->user_b_id
                : $offer->user_a_id,
        ];
    }
}
