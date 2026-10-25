<?php

namespace App\Http\Controllers;

use App\Models\MatchOffer;
use App\Support\ApiError;
use App\Support\PvpMatchmakingService;
use Illuminate\Http\Request;
use RuntimeException;

class PvpController extends Controller
{
    public function __construct(private PvpMatchmakingService $pvp) {}

    public function status(Request $request)
    {
        return response()->json($this->pvp->status($request->user()));
    }

    public function enqueue(Request $request)
    {
        $data = $request->validate([
            'card_codes' => ['nullable', 'array', 'size:3'],
            'card_codes.*' => ['string'],
        ]);

        try {
            $status = $this->pvp->enqueue($request->user(), $data['card_codes'] ?? null);
        } catch (RuntimeException $e) {
            return $this->mapError($e);
        }

        return response()->json($status, 201);
    }

    public function leave(Request $request)
    {
        return response()->json($this->pvp->leaveQueue($request->user()));
    }

    public function accept(Request $request, MatchOffer $offer)
    {
        try {
            $status = $this->pvp->accept($request->user(), $offer);
        } catch (RuntimeException $e) {
            return $this->mapError($e);
        }

        return response()->json($status);
    }

    public function decline(Request $request, MatchOffer $offer)
    {
        try {
            $status = $this->pvp->decline($request->user(), $offer);
        } catch (RuntimeException $e) {
            return $this->mapError($e);
        }

        return response()->json($status);
    }

    private function mapError(RuntimeException $e)
    {
        return match ($e->getMessage()) {
            'FORBIDDEN' => ApiError::make('FORBIDDEN', 'Not your offer.', 403),
            'TEAM_INVALID' => ApiError::make('TEAM_INVALID', 'Need a valid 3-card squad.', 422),
            'CARD_NOT_FOUND' => ApiError::make('CARD_NOT_FOUND', 'Card missing.', 404),
            'CARD_NOT_OWNED' => ApiError::make('CARD_NOT_OWNED', 'You do not own that card.', 422),
            'OFFER_NOT_PENDING' => ApiError::make('OFFER_NOT_PENDING', 'Offer is no longer pending.', 409),
            'OFFER_EXPIRED' => ApiError::make('OFFER_EXPIRED', 'Accept window expired.', 409),
            'MODE_UNAVAILABLE' => ApiError::make('MODE_UNAVAILABLE', 'PvP mode unavailable.', 422),
            default => ApiError::make('PVP_FAILED', 'PvP request failed.', 500, retryable: true),
        };
    }
}
