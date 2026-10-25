<?php

namespace App\Http\Controllers;

use App\Models\BalanceVersion;
use App\Support\ProgressService;

class ProgressController extends Controller
{
    public function __construct(private ProgressService $progress) {}

    public function show(\Illuminate\Http\Request $request)
    {
        $profile = $this->progress->ensureProfile($request->user()->id);
        $profile = $this->progress->refreshEnergy($profile);
        $balance = BalanceVersion::query()->where('is_current', true)->first();

        return response()->json([
            'profile' => $profile->toApiArray(),
            'balance_version' => $balance?->version ?? 1,
            'balance_notes' => $balance?->notes,
        ]);
    }
}
