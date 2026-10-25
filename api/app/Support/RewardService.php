<?php

namespace App\Support;

use App\Models\GameMatch;
use App\Models\IdempotencyKey;
use App\Models\MatchRewardClaim;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use RuntimeException;

final class RewardService
{
    public function __construct(
        private ProgressService $progress,
        private EconomyService $economy,
    ) {}

    /**
     * @return array{replay:bool,payload:array<string,mixed>,status:int}
     */
    public function claimMatchVictory(User $user, GameMatch $match, string $clientClaimId): array
    {
        $scope = 'match_reward_claim';
        $existingKey = IdempotencyKey::query()
            ->where('user_id', $user->id)
            ->where('scope', $scope)
            ->where('key', $clientClaimId)
            ->first();

        if ($existingKey) {
            return [
                'replay' => true,
                'payload' => $existingKey->response_json ?? [],
                'status' => 200,
            ];
        }

        if (! $match->isParticipant($user->id)) {
            throw new RuntimeException('FORBIDDEN');
        }

        $seat = $match->seatFor($user->id);
        $eligible = ($seat === 'player' && $match->outcome === 'victory_player')
            || ($seat === 'enemy' && $match->outcome === 'victory_enemy');
        if (! $eligible) {
            throw new RuntimeException('REWARD_NOT_ELIGIBLE');
        }

        $prior = MatchRewardClaim::query()
            ->where('match_id', $match->id)
            ->where('reward_code', 'victory_pack')
            ->first();

        if ($prior) {
            $payload = $this->claimPayload($prior, $this->progress->ensureProfile($user->id), true);
            IdempotencyKey::create([
                'user_id' => $user->id,
                'scope' => $scope,
                'key' => $clientClaimId,
                'response_json' => $payload,
                'status_code' => 200,
            ]);

            return ['replay' => true, 'payload' => $payload, 'status' => 200];
        }

        return DB::transaction(function () use ($user, $match, $clientClaimId, $scope) {
            $locked = GameMatch::query()->whereKey($match->id)->lockForUpdate()->firstOrFail();
            $dup = MatchRewardClaim::query()
                ->where('match_id', $locked->id)
                ->where('reward_code', 'victory_pack')
                ->lockForUpdate()
                ->first();
            if ($dup) {
                $profile = $this->progress->ensureProfile($user->id);
                $payload = $this->claimPayload($dup, $profile, true);
                IdempotencyKey::create([
                    'user_id' => $user->id,
                    'scope' => $scope,
                    'key' => $clientClaimId,
                    'response_json' => $payload,
                    'status_code' => 200,
                ]);

                return ['replay' => true, 'payload' => $payload, 'status' => 200];
            }

            $xp = 40;
            $aether = 25;
            $marks = (int) config('chests.match_victory.rift_marks', 35);
            if (($locked->mode ?? '') === 'online_clash' || ($locked->is_pvp ?? false)) {
                $xp = 50;
                $aether = 35;
                $marks = (int) ($marks * 1.4);
            }

            $profile = $this->progress->ensureProfile($user->id);
            $profile = $this->progress->refreshEnergy($profile);
            $profile = $this->progress->grantXp($profile, $xp);
            $profile = $this->economy->apply(
                $profile,
                EconomyService::CURRENCY_AETHER,
                $aether,
                'match_victory',
                'match',
                (string) $locked->id,
                $clientClaimId,
            );
            $profile = $this->economy->apply(
                $profile,
                EconomyService::CURRENCY_RIFT_MARKS,
                $marks,
                'match_victory',
                'match',
                (string) $locked->id,
                $clientClaimId.'-marks',
            );

            $ironKeys = 0;
            $chance = (int) config('chests.match_victory.iron_key_chance_bp', 1500);
            if ((abs(crc32($clientClaimId.'|key')) % 10000) < $chance) {
                $profile->key_iron = (int) $profile->key_iron + 1;
                $profile->save();
                $ironKeys = 1;
            }

            $claim = MatchRewardClaim::create([
                'user_id' => $user->id,
                'match_id' => $locked->id,
                'reward_code' => 'victory_pack',
                'xp_granted' => $xp,
                'aether_granted' => $aether,
                'rift_marks_granted' => $marks,
                'iron_keys_granted' => $ironKeys,
                'client_claim_id' => $clientClaimId,
            ]);

            $payload = $this->claimPayload($claim, $profile->fresh(), false);
            IdempotencyKey::create([
                'user_id' => $user->id,
                'scope' => $scope,
                'key' => $clientClaimId,
                'response_json' => $payload,
                'status_code' => 201,
            ]);

            SecurityLog::economy('match_victory_claimed', [
                'user_id' => $user->id,
                'match_id' => $locked->id,
                'xp' => $xp,
                'aether' => $aether,
                'rift_marks' => $marks,
                'iron_keys' => $ironKeys,
            ]);

            return ['replay' => false, 'payload' => $payload, 'status' => 201];
        });
    }

    private function claimPayload(MatchRewardClaim $claim, $profile, bool $alreadyClaimed): array
    {
        return [
            'already_claimed' => $alreadyClaimed,
            'claim' => [
                'match_id' => $claim->match_id,
                'reward_code' => $claim->reward_code,
                'xp_granted' => $claim->xp_granted,
                'aether_granted' => $claim->aether_granted,
                'rift_marks_granted' => (int) ($claim->rift_marks_granted ?? 0),
                'iron_keys_granted' => (int) ($claim->iron_keys_granted ?? 0),
                'client_claim_id' => $claim->client_claim_id,
            ],
            'profile' => $profile->toApiArray(),
        ];
    }
}
