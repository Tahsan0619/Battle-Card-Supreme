<?php

namespace App\Http\Controllers;

use App\Support\ApiError;
use App\Support\SummonService;
use Illuminate\Http\Request;
use RuntimeException;

class SummonController extends Controller
{
    public function __construct(private SummonService $summon) {}

    public function banners()
    {
        return response()->json($this->summon->banners());
    }

    public function pull(Request $request)
    {
        $data = $request->validate([
            'banner_code' => ['required', 'string', 'max:64'],
            'client_summon_id' => ['required', 'string', 'max:80'],
        ]);

        try {
            $result = $this->summon->pull(
                $request->user(),
                $data['banner_code'],
                $data['client_summon_id'],
            );
        } catch (RuntimeException $e) {
            return match ($e->getMessage()) {
                'BANNER_NOT_FOUND' => ApiError::make('BANNER_NOT_FOUND', 'Unknown summon banner.', 404),
                'INSUFFICIENT_CURRENCY' => ApiError::make(
                    'INSUFFICIENT_CURRENCY',
                    'Not enough currency for this summon.',
                    422
                ),
                'BANNER_MISCONFIGURED' => ApiError::make(
                    'BANNER_MISCONFIGURED',
                    'Summon rates are misconfigured.',
                    500
                ),
                'SUMMON_POOL_EMPTY' => ApiError::make(
                    'SUMMON_POOL_EMPTY',
                    'No cards available in pool.',
                    500,
                    retryable: true
                ),
                default => ApiError::make('SUMMON_FAILED', 'Summon failed.', 500, retryable: true),
            };
        }

        return response()->json([
            ...$result['payload'],
            'idempotent_replay' => $result['replay'],
        ], $result['status']);
    }
}
