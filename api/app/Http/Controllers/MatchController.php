<?php

namespace App\Http\Controllers;

use App\Combat\CombatEngine;
use App\Models\CardDefinition;
use App\Models\GameMatch;
use App\Models\MatchAction;
use App\Models\PlayerCard;
use App\Models\Team;
use App\Models\BalanceVersion;
use App\Models\MatchRewardClaim;
use App\Support\ApiError;
use App\Support\ModeCatalog;
use App\Support\RankingService;
use App\Support\SecurityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MatchController extends Controller
{
    public function __construct(
        private CombatEngine $engine,
        private ModeCatalog $modes,
        private RankingService $ranking,
    ) {}

    public function store(Request $request)
    {
        $data = $request->validate([
            'mode' => ['nullable', 'string', 'max:64'],
            'team_id' => ['nullable', 'integer'],
            'card_codes' => ['nullable', 'array', 'size:3'],
            'card_codes.*' => ['string'],
            'enemy_card_codes' => ['nullable', 'array', 'size:3'],
            'enemy_card_codes.*' => ['string'],
            'client_match_key' => ['nullable', 'string', 'max:80'],
        ]);

        $modeCode = $data['mode'] ?? 'online_clash';
        // Online match create maps classic_clash to online_clash rules when sent by older clients.
        if ($modeCode === 'classic_clash') {
            $modeCode = 'online_clash';
        }
        $resolved = $this->modes->resolve($modeCode);
        if ($resolved === null) {
            return ApiError::make('MODE_UNAVAILABLE', "Mode {$modeCode} is not available.", 422);
        }
        $rules = $resolved['rules']->rules_json ?? [];
        $teamSize = (int) ($rules['team_size'] ?? 3);
        $maxRounds = (int) ($rules['max_rounds'] ?? 30);
        if (($rules['channel'] ?? 'both') === 'offline') {
            return ApiError::make(
                'MODE_OFFLINE_ONLY',
                'This mode runs offline on the client.',
                422
            );
        }

        $user = $request->user();
        $playerCodes = $data['card_codes'] ?? null;

        if ($playerCodes === null) {
            $teamQuery = $user->teams()->with('slots.cardDefinition');
            $team = isset($data['team_id'])
                ? $teamQuery->whereKey($data['team_id'])->first()
                : $teamQuery->where('is_active', true)->orderBy('id')->first();
            if (! $team instanceof Team || $team->slots->count() < $teamSize) {
                return ApiError::make(
                    'TEAM_INVALID',
                    "Active squad must have {$teamSize} fighters.",
                    422
                );
            }
            $playerCodes = $team->slots->sortBy('slot_index')->map(
                fn ($s) => $s->cardDefinition?->code
            )->filter()->values()->all();
        }

        if (count($playerCodes) !== $teamSize) {
            return ApiError::make(
                'TEAM_INVALID',
                "Need exactly {$teamSize} card codes.",
                422
            );
        }

        foreach ($playerCodes as $code) {
            $card = CardDefinition::where('code', $code)->where('is_published', true)->first();
            if (! $card) {
                return ApiError::make('CARD_NOT_FOUND', "Missing card {$code}.", 404);
            }
            $owned = PlayerCard::where('user_id', $user->id)
                ->where('card_definition_id', $card->id)
                ->exists();
            if (! $owned) {
                return ApiError::make('CARD_NOT_OWNED', "You do not own {$code}.", 422);
            }
        }

        $enemyCodes = $data['enemy_card_codes'] ?? CardDefinition::query()
            ->where('is_published', true)
            ->orderByDesc('id')
            ->limit($teamSize)
            ->pluck('code')
            ->all();

        $playerCards = CardDefinition::whereIn('code', $playerCodes)->get()->keyBy('code');
        $enemyCards = CardDefinition::whereIn('code', $enemyCodes)->get()->keyBy('code');

        $playerSnap = [];
        foreach ($playerCodes as $code) {
            $playerSnap[] = $playerCards[$code]->toArray();
        }
        $enemySnap = [];
        foreach ($enemyCodes as $code) {
            $enemySnap[] = $enemyCards[$code]->toArray();
        }

        $state = $this->engine->start($playerSnap, $enemySnap, $maxRounds);
        $drained = $this->engine->drainEnemyTurns($state, 7);
        $state = $drained['state'];

        $balanceVersion = BalanceVersion::query()->where('is_current', true)->value('version') ?? 1;

        $match = GameMatch::create([
            'user_id' => $user->id,
            'mode' => $resolved['mode']->code,
            'mode_rule_version' => $resolved['rules']->version,
            'mode_rules_snapshot' => $rules,
            'balance_version' => $balanceVersion,
            'outcome' => $state['outcome'],
            'state_version' => 1,
            'state_json' => $state,
            'player_snapshot' => $playerSnap,
            'enemy_snapshot' => $enemySnap,
            'max_rounds' => $maxRounds,
            'rng_seed' => 7,
        ]);

        return response()->json([
            'match' => $this->payload($match, $user->id),
        ], 201);
    }

    public function show(Request $request, GameMatch $gameMatch)
    {
        if (! $gameMatch->isParticipant($request->user()->id)) {
            SecurityLog::authz('match_idor', [
                'user_id' => $request->user()->id,
                'match_id' => $gameMatch->id,
            ]);

            return ApiError::make('FORBIDDEN', 'Not your match.', 403);
        }

        return response()->json([
            'match' => $this->payload($gameMatch, $request->user()->id),
        ]);
    }

    public function history(Request $request, GameMatch $gameMatch)
    {
        if (! $gameMatch->isParticipant($request->user()->id)) {
            SecurityLog::authz('match_idor', [
                'user_id' => $request->user()->id,
                'match_id' => $gameMatch->id,
            ]);

            return ApiError::make('FORBIDDEN', 'Not your match.', 403);
        }

        $actions = $gameMatch->actions()->orderBy('id')->get()->map(fn (MatchAction $a) => [
            'client_action_id' => $a->client_action_id,
            'state_version_before' => $a->state_version_before,
            'state_version_after' => $a->state_version_after,
            'action' => $a->action_json,
            'events' => $a->events_json,
            'created_at' => $a->created_at?->toIso8601String(),
        ]);

        return response()->json([
            'match_id' => $gameMatch->id,
            'actions' => $actions,
            'log' => $gameMatch->state_json['log'] ?? [],
        ]);
    }

    public function action(Request $request, GameMatch $gameMatch)
    {
        if (! $gameMatch->isParticipant($request->user()->id)) {
            SecurityLog::authz('match_idor', [
                'user_id' => $request->user()->id,
                'match_id' => $gameMatch->id,
                'op' => 'action',
            ]);

            return ApiError::make('FORBIDDEN', 'Not your match.', 403);
        }

        $data = $request->validate([
            'type' => ['required', 'in:basic_attack,ability,end_turn,concede'],
            'actor_id' => ['required', 'string'],
            'target_id' => ['nullable', 'string'],
            'client_action_id' => ['required', 'string', 'max:120'],
            'state_version' => ['required', 'integer', 'min:0'],
        ]);

        $seat = $gameMatch->seatFor($request->user()->id);
        if ($gameMatch->is_pvp && $data['type'] !== 'concede') {
            $prefix = $seat === 'player' ? 'P' : 'E';
            if (! str_starts_with($data['actor_id'], $prefix)) {
                return ApiError::make(
                    'MATCH_WRONG_SEAT',
                    'Actor does not belong to your seat.',
                    422
                );
            }
        }

        try {
            $result = DB::transaction(function () use ($request, $gameMatch, $data) {
                /** @var GameMatch $locked */
                $locked = GameMatch::query()->whereKey($gameMatch->id)->lockForUpdate()->firstOrFail();

                $existing = MatchAction::query()
                    ->where('match_id', $locked->id)
                    ->where('client_action_id', $data['client_action_id'])
                    ->first();
                if ($existing) {
                    return [
                        'replay' => true,
                        'match' => $locked->fresh(),
                        'error_code' => 'IDEMPOTENT_REPLAY',
                    ];
                }

                if ($locked->outcome !== 'ongoing' && $data['type'] !== 'concede') {
                    return [
                        'replay' => false,
                        'error' => ApiError::make('MATCH_ENDED', 'Match already ended.', 409),
                    ];
                }

                if ((int) $data['state_version'] !== (int) $locked->state_version) {
                    return [
                        'replay' => false,
                        'error' => ApiError::make(
                            'MATCH_STATE_CONFLICT',
                            'Stale state_version. Refresh match state.',
                            409,
                            ['expected' => $locked->state_version],
                        ),
                    ];
                }

                $before = $locked->state_version;
                $state = $locked->state_json;

                // PvP concede from guest maps to enemy victory for host.
                $actionType = $data['type'];
                if ($locked->is_pvp && $actionType === 'concede'
                    && (int) $request->user()->id === (int) $locked->opponent_user_id) {
                    $state['outcome'] = 'victory_player';
                    $ev = ['message' => 'Opponent conceded.', 'damage' => 0, 'healing' => 0];
                    $state['log'][] = $ev;
                    $locked->state_json = $state;
                    $locked->outcome = 'victory_player';
                    $locked->state_version = $before + 1;
                    $locked->save();
                    MatchAction::create([
                        'match_id' => $locked->id,
                        'user_id' => $request->user()->id,
                        'client_action_id' => $data['client_action_id'],
                        'state_version_before' => $before,
                        'state_version_after' => $locked->state_version,
                        'action_json' => $data,
                        'events_json' => [$ev],
                    ]);

                    $fresh = $locked->fresh();
                    $this->ranking->applyMatchIfNeeded($fresh);

                    return [
                        'replay' => false,
                        'match' => $fresh->fresh(),
                        'events' => [$ev],
                        'error_code' => null,
                    ];
                }

                $applied = $this->engine->apply($state, [
                    'type' => $data['type'],
                    'actor_id' => $data['actor_id'],
                    'target_id' => $data['target_id'] ?? null,
                    'client_action_id' => $data['client_action_id'],
                ]);

                if (! $applied['ok']) {
                    return [
                        'replay' => false,
                        'error' => ApiError::make(
                            $applied['error_code'] ?? 'MATCH_ILLEGAL_ACTION',
                            'Illegal match action.',
                            422,
                        ),
                    ];
                }

                $state = $applied['state'];
                $events = $applied['events'];

                // AI only for PvE online matches.
                if (! $locked->is_pvp && $state['outcome'] === 'ongoing') {
                    $drained = $this->engine->drainEnemyTurns($state, (int) $locked->rng_seed);
                    $state = $drained['state'];
                    $events = array_merge($events, $drained['events']);
                }

                $locked->state_json = $state;
                $locked->outcome = $state['outcome'];
                $locked->state_version = $before + 1;
                $locked->save();

                MatchAction::create([
                    'match_id' => $locked->id,
                    'user_id' => $request->user()->id,
                    'client_action_id' => $data['client_action_id'],
                    'state_version_before' => $before,
                    'state_version_after' => $locked->state_version,
                    'action_json' => $data,
                    'events_json' => $events,
                ]);

                $fresh = $locked->fresh();
                $this->ranking->applyMatchIfNeeded($fresh);

                return [
                    'replay' => false,
                    'match' => $fresh->fresh(),
                    'events' => $events,
                    'error_code' => $applied['error_code'],
                ];
            });
        } catch (\Throwable $e) {
            report($e);

            return ApiError::make('INTERNAL_ERROR', 'Match action failed.', 500, retryable: true);
        }

        if (isset($result['error'])) {
            return $result['error'];
        }

        return response()->json([
            'match' => $this->payload($result['match'], $request->user()->id),
            'events' => $result['events'] ?? [],
            'idempotent_replay' => $result['replay'] ?? false,
            'error_code' => $result['error_code'] ?? null,
        ]);
    }

    private function payload(GameMatch $match, ?int $viewerId = null): array
    {
        $rewardClaimed = MatchRewardClaim::query()
            ->where('match_id', $match->id)
            ->where('reward_code', 'victory_pack')
            ->exists();

        $seat = $viewerId ? $match->seatFor($viewerId) : 'player';
        $youWon = match (true) {
            $seat === 'player' && $match->outcome === 'victory_player' => true,
            $seat === 'enemy' && $match->outcome === 'victory_enemy' => true,
            default => false,
        };

        return [
            'id' => $match->id,
            'mode' => $match->mode,
            'is_pvp' => (bool) $match->is_pvp,
            'your_seat' => $seat,
            'mode_rule_version' => $match->mode_rule_version,
            'mode_rules' => $match->mode_rules_snapshot,
            'balance_version' => $match->balance_version,
            'outcome' => $match->outcome,
            'state_version' => $match->state_version,
            'state' => $this->engine->publicState($match->state_json),
            'rewards_claimable' => $youWon && ! $rewardClaimed,
            'rewards_claimed' => $rewardClaimed,
        ];
    }
}

