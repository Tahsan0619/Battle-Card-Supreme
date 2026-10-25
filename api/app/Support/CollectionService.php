<?php

namespace App\Support;

use App\Models\CardDefinition;
use App\Models\PlayerCard;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use RuntimeException;

final class CollectionService
{
    /**
     * @return array{was_new:bool,level:int,copies:int,player_card_id:int}
     */
    public function grantOrCopy(User $user, CardDefinition $card): array
    {
        $pc = PlayerCard::query()
            ->where('user_id', $user->id)
            ->where('card_definition_id', $card->id)
            ->lockForUpdate()
            ->first();

        if (! $pc) {
            $pc = PlayerCard::create([
                'user_id' => $user->id,
                'card_definition_id' => $card->id,
                'level' => 1,
                'copies' => 0,
            ]);

            return [
                'was_new' => true,
                'level' => 1,
                'copies' => 0,
                'player_card_id' => $pc->id,
            ];
        }

        $pc->copies = (int) $pc->copies + 1;
        $pc->save();

        return [
            'was_new' => false,
            'level' => (int) $pc->level,
            'copies' => (int) $pc->copies,
            'player_card_id' => $pc->id,
        ];
    }

    public function levelUp(User $user, string $cardCode): array
    {
        $max = (int) config('chests.max_card_level', 10);
        $card = CardDefinition::query()->where('code', $cardCode)->first();
        if (! $card) {
            throw new RuntimeException('CARD_NOT_FOUND');
        }

        return DB::transaction(function () use ($user, $card, $max) {
            $pc = PlayerCard::query()
                ->where('user_id', $user->id)
                ->where('card_definition_id', $card->id)
                ->lockForUpdate()
                ->first();
            if (! $pc) {
                throw new RuntimeException('CARD_NOT_OWNED');
            }
            $level = (int) $pc->level;
            if ($level >= $max) {
                throw new RuntimeException('CARD_MAX_LEVEL');
            }
            $need = $level; // L->L+1 costs L copies
            if ((int) $pc->copies < $need) {
                throw new RuntimeException('INSUFFICIENT_COPIES');
            }
            $pc->copies = (int) $pc->copies - $need;
            $pc->level = $level + 1;
            $pc->save();

            return [
                'card' => $card->toApiArray(),
                'level' => (int) $pc->level,
                'copies' => (int) $pc->copies,
                'copies_to_next' => $pc->level >= $max ? null : (int) $pc->level,
            ];
        });
    }

    public function catalogueFor(User $user): array
    {
        $owned = PlayerCard::query()
            ->where('user_id', $user->id)
            ->with('cardDefinition')
            ->get()
            ->keyBy(fn ($pc) => $pc->cardDefinition?->code);

        $max = (int) config('chests.max_card_level', 10);
        $all = CardDefinition::query()
            ->where('is_published', true)
            ->orderBy('id')
            ->get()
            ->map(function (CardDefinition $def) use ($owned, $max) {
                /** @var PlayerCard|null $pc */
                $pc = $owned->get($def->code);
                $level = $pc ? (int) $pc->level : 0;
                $copies = $pc ? (int) $pc->copies : 0;

                return [
                    'owned' => $pc !== null,
                    'level' => $level,
                    'copies' => $copies,
                    'copies_to_next' => $pc === null || $level >= $max ? null : $level,
                    'player_card_id' => $pc?->id,
                    'card' => $def->toApiArray(),
                ];
            })
            ->values();

        return [
            'count_owned' => $owned->count(),
            'count_total' => $all->count(),
            'max_card_level' => $max,
            'collection' => $all,
        ];
    }
}
