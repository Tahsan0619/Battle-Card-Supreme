<?php

namespace App\Http\Controllers;

use App\Models\CardDefinition;
use App\Models\PlayerCard;
use App\Models\Team;
use App\Models\TeamSlot;
use App\Support\ApiError;
use App\Support\SecurityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TeamController extends Controller
{
    public const MAX_SLOTS = 3;

    public function index(Request $request)
    {
        $teams = $request->user()
            ->teams()
            ->with(['slots.cardDefinition'])
            ->orderByDesc('is_active')
            ->orderBy('id')
            ->get()
            ->map(fn (Team $team) => $this->teamPayload($team));

        return response()->json(['teams' => $teams]);
    }

    /**
     * Sync the caller's active Main Squad from owned card codes.
     * Does not grant ownership; use shop/summon to acquire cards.
     */
    public function sync(Request $request)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:40'],
            'card_codes' => ['required', 'array', 'size:'.self::MAX_SLOTS],
            'card_codes.*' => ['required', 'string'],
        ]);

        $codes = $data['card_codes'];
        $error = $this->validateOwnershipAndUniques($request->user()->id, $codes);
        if ($error !== null) {
            return $error;
        }

        $team = DB::transaction(function () use ($request, $data, $codes) {
            $user = $request->user();

            $team = $user->teams()->where('is_active', true)->orderBy('id')->first();
            if (! $team) {
                $team = Team::create([
                    'user_id' => $user->id,
                    'name' => $data['name'] ?? 'Main Squad',
                    'is_active' => true,
                ]);
            } elseif (isset($data['name'])) {
                $team->update(['name' => $data['name']]);
            }

            $team->slots()->delete();
            $this->syncSlots($team, $codes);

            return $team->load(['slots.cardDefinition']);
        });

        return response()->json(['team' => $this->teamPayload($team)]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:40'],
            'card_codes' => ['required', 'array', 'size:'.self::MAX_SLOTS],
            'card_codes.*' => ['required', 'string'],
        ]);

        $error = $this->validateOwnershipAndUniques($request->user()->id, $data['card_codes']);
        if ($error !== null) {
            return $error;
        }

        $team = DB::transaction(function () use ($request, $data) {
            $team = Team::create([
                'user_id' => $request->user()->id,
                'name' => $data['name'],
                'is_active' => true,
            ]);
            $this->syncSlots($team, $data['card_codes']);

            return $team->load(['slots.cardDefinition']);
        });

        return response()->json(['team' => $this->teamPayload($team)], 201);
    }

    public function update(Request $request, Team $team)
    {
        if ($team->user_id !== $request->user()->id) {
            SecurityLog::authz('team_idor', [
                'user_id' => $request->user()->id,
                'team_id' => $team->id,
            ]);

            return ApiError::make('FORBIDDEN', 'You do not own this team.', 403);
        }

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:40'],
            'card_codes' => ['required', 'array', 'size:'.self::MAX_SLOTS],
            'card_codes.*' => ['required', 'string'],
        ]);

        $error = $this->validateOwnershipAndUniques($request->user()->id, $data['card_codes']);
        if ($error !== null) {
            return $error;
        }

        DB::transaction(function () use ($team, $data) {
            if (isset($data['name'])) {
                $team->update(['name' => $data['name']]);
            }
            $team->slots()->delete();
            $this->syncSlots($team, $data['card_codes']);
        });

        $team->load(['slots.cardDefinition']);

        return response()->json(['team' => $this->teamPayload($team)]);
    }

    private function validateOwnershipAndUniques(int $userId, array $codes)
    {
        if (count($codes) !== count(array_unique($codes))) {
            return ApiError::make('TEAM_INVALID', 'Duplicate characters are not allowed.', 422);
        }

        $cards = CardDefinition::query()
            ->whereIn('code', $codes)
            ->where('is_published', true)
            ->get()
            ->keyBy('code');

        if ($cards->count() !== count($codes)) {
            return ApiError::make('CARD_NOT_FOUND', 'One or more cards were not found.', 404);
        }

        foreach ($codes as $code) {
            $owned = PlayerCard::query()
                ->where('user_id', $userId)
                ->where('card_definition_id', $cards[$code]->id)
                ->exists();
            if (! $owned) {
                return ApiError::make('CARD_NOT_OWNED', "You do not own {$code}.", 422);
            }
        }

        return null;
    }

    private function syncSlots(Team $team, array $codes): void
    {
        foreach (array_values($codes) as $index => $code) {
            $card = CardDefinition::where('code', $code)->firstOrFail();
            TeamSlot::create([
                'team_id' => $team->id,
                'slot_index' => $index,
                'card_definition_id' => $card->id,
            ]);
        }
    }

    private function teamPayload(Team $team): array
    {
        return [
            'id' => $team->id,
            'name' => $team->name,
            'is_active' => $team->is_active,
            'slots' => $team->slots->map(function (TeamSlot $slot) {
                return [
                    'slot_index' => $slot->slot_index,
                    'card' => $slot->cardDefinition?->toApiArray(),
                ];
            })->values(),
        ];
    }
}
