<?php

use App\Http\Controllers\Admin\ArtPublishController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CardController;
use App\Http\Controllers\ChestController;
use App\Http\Controllers\CollectionController;
use App\Http\Controllers\MatchController;
use App\Http\Controllers\MetaController;
use App\Http\Controllers\ModeController;
use App\Http\Controllers\ProgressController;
use App\Http\Controllers\PvpController;
use App\Http\Controllers\RankingController;
use App\Http\Controllers\RewardController;
use App\Http\Controllers\ShopController;
use App\Http\Controllers\SummonController;
use App\Http\Controllers\TeamController;
use Illuminate\Support\Facades\Route;

Route::get('/meta', [MetaController::class, 'show'])->middleware('bcs.rate:read');
Route::get('/ready', [MetaController::class, 'ready']);

Route::middleware('bcs.rate:auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware('bcs.rate:read')->group(function () {
    Route::get('/cards', [CardController::class, 'index']);
    Route::get('/cards/{id}', [CardController::class, 'show']);
    Route::get('/modes', [ModeController::class, 'index']);
    Route::get('/leaderboard', [RankingController::class, 'leaderboard'])
        ->middleware('bcs.flag:ranking');
});

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me'])->middleware('bcs.rate:read');
    Route::get('/progress', [ProgressController::class, 'show'])->middleware('bcs.rate:read');
    Route::get('/ranking/me', [RankingController::class, 'me'])
        ->middleware(['bcs.flag:ranking', 'bcs.rate:read']);
    Route::get('/collection', [CollectionController::class, 'index'])->middleware('bcs.rate:read');
    Route::post('/collection/{code}/level-up', [ChestController::class, 'levelUp'])
        ->middleware('bcs.rate:economy');

    Route::middleware(['bcs.flag:shop', 'bcs.rate:economy'])->prefix('exchange')->group(function () {
        Route::get('/chests', [ChestController::class, 'catalogue']);
        Route::post('/keys/buy', [ChestController::class, 'buyKey']);
        Route::post('/chests/open', [ChestController::class, 'open']);
    });

    Route::middleware('bcs.rate:write')->group(function () {
        Route::get('/teams', [TeamController::class, 'index']);
        Route::post('/teams', [TeamController::class, 'store']);
        Route::post('/teams/sync', [TeamController::class, 'sync']);
        Route::put('/teams/{team}', [TeamController::class, 'update']);
    });

    Route::middleware('bcs.flag:online_clash')->group(function () {
        Route::post('/matches', [MatchController::class, 'store'])->middleware('bcs.rate:write');
        Route::get('/matches/{gameMatch}', [MatchController::class, 'show'])->middleware('bcs.rate:read');
        Route::get('/matches/{gameMatch}/history', [MatchController::class, 'history'])->middleware('bcs.rate:read');
        Route::post('/matches/{gameMatch}/actions', [MatchController::class, 'action'])
            ->middleware('bcs.rate:match_action');
        Route::post('/matches/{gameMatch}/rewards/claim', [RewardController::class, 'claimMatch'])
            ->middleware(['bcs.flag:rewards_claim', 'bcs.rate:economy']);
    });

    Route::middleware(['bcs.flag:pvp', 'bcs.rate:write'])->prefix('pvp')->group(function () {
        Route::get('/status', [PvpController::class, 'status']);
        Route::post('/queue', [PvpController::class, 'enqueue']);
        Route::delete('/queue', [PvpController::class, 'leave']);
        Route::post('/offers/{offer}/accept', [PvpController::class, 'accept']);
        Route::post('/offers/{offer}/decline', [PvpController::class, 'decline']);
    });

    Route::middleware(['bcs.flag:shop', 'bcs.rate:economy'])->prefix('shop')->group(function () {
        Route::get('/', [ShopController::class, 'catalogue']);
        Route::post('/purchase', [ShopController::class, 'purchase']);
        Route::post('/daily', [ShopController::class, 'claimDaily']);
    });

    Route::middleware(['bcs.flag:summon', 'bcs.rate:economy'])->prefix('summon')->group(function () {
        Route::get('/banners', [SummonController::class, 'banners']);
        Route::post('/pull', [SummonController::class, 'pull']);
    });

    Route::middleware(['bcs.admin', 'bcs.rate:admin'])->prefix('admin')->group(function () {
        Route::get('/cards', [ArtPublishController::class, 'index']);
        Route::post('/cards/{code}/art/publish', [ArtPublishController::class, 'publish']);
        Route::get('/audit', [ArtPublishController::class, 'audit']);
    });
});
