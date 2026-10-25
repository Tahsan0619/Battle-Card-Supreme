<?php

namespace App\Http\Controllers;

use App\Support\RankingService;
use Illuminate\Http\Request;

class RankingController extends Controller
{
    public function __construct(private RankingService $ranking) {}

    public function leaderboard(Request $request)
    {
        $limit = (int) $request->query('limit', config('ranking.leaderboard_limit', 50));

        return response()->json($this->ranking->leaderboard($limit));
    }

    public function me(Request $request)
    {
        return response()->json([
            'rating' => $this->ranking->me($request->user()),
        ]);
    }
}
