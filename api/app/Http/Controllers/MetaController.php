<?php

namespace App\Http\Controllers;

use App\Models\BalanceVersion;
use App\Models\CardDefinition;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class MetaController extends Controller
{
    public function show()
    {
        $balance = BalanceVersion::query()->where('is_current', true)->value('version');

        return response()->json([
            'api_version' => config('bcs.api_version'),
            'min_app_version' => config('bcs.min_app_version'),
            'catalogue_version' => config('bcs.catalogue_version'),
            'balance_version' => $balance ?? 1,
            'published_card_count' => CardDefinition::query()->where('is_published', true)->count(),
            'feature_flags' => config('bcs.feature_flags'),
            'server_time' => now()->toIso8601String(),
        ]);
    }

    public function ready()
    {
        try {
            DB::select('select 1');
            $cardsReady = Schema::hasTable('card_definitions');
            $modesReady = Schema::hasTable('game_modes');
            $ok = $cardsReady && $modesReady;

            return response()->json([
                'ready' => $ok,
                'checks' => [
                    'database' => true,
                    'card_definitions' => $cardsReady,
                    'game_modes' => $modesReady,
                ],
            ], $ok ? 200 : 503);
        } catch (\Throwable $e) {
            return response()->json([
                'ready' => false,
                'checks' => [
                    'database' => false,
                    'error' => 'database_unreachable',
                ],
            ], 503);
        }
    }
}
