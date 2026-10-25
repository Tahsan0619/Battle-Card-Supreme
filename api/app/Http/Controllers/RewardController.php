<?php

namespace App\Http\Controllers;

use App\Models\GameMatch;
use App\Support\ApiError;
use App\Support\RewardService;
use Illuminate\Http\Request;
use RuntimeException;

class RewardController extends Controller
{
    public function __construct(private RewardService $rewards) {}

    public function claimMatch(Request $request, GameMatch $gameMatch)
    {
        $data = $request->validate([
            'client_claim_id' => ['required', 'string', 'max:80'],
        ]);

        try {
            $result = $this->rewards->claimMatchVictory(
                $request->user(),
                $gameMatch,
                $data['client_claim_id'],
            );
        } catch (RuntimeException $e) {
            return match ($e->getMessage()) {
                'FORBIDDEN' => ApiError::make('FORBIDDEN', 'Not your match.', 403),
                'REWARD_NOT_ELIGIBLE' => ApiError::make(
                    'REWARD_NOT_ELIGIBLE',
                    'Only victories can claim this reward.',
                    422
                ),
                default => ApiError::make('REWARD_FAILED', 'Reward claim failed.', 500, retryable: true),
            };
        } catch (\InvalidArgumentException $e) {
            if ($e->getMessage() === 'INSUFFICIENT_CURRENCY') {
                return ApiError::make('INSUFFICIENT_CURRENCY', 'Not enough currency.', 422);
            }

            throw $e;
        }

        return response()->json([
            ...$result['payload'],
            'idempotent_replay' => $result['replay'],
        ], $result['status']);
    }
}
