<?php

namespace App\Http\Controllers;

use App\Support\ApiError;
use App\Support\ShopService;
use Illuminate\Http\Request;
use RuntimeException;

class ShopController extends Controller
{
    public function __construct(private ShopService $shop) {}

    public function catalogue()
    {
        return response()->json($this->shop->catalogue());
    }

    public function purchase(Request $request)
    {
        $data = $request->validate([
            'offer_code' => ['required', 'string', 'max:64'],
            'client_purchase_id' => ['required', 'string', 'max:80'],
        ]);

        try {
            $result = $this->shop->purchase(
                $request->user(),
                $data['offer_code'],
                $data['client_purchase_id'],
            );
        } catch (RuntimeException $e) {
            return $this->mapError($e);
        }

        return response()->json([
            ...$result['payload'],
            'idempotent_replay' => $result['replay'],
        ], $result['status']);
    }

    public function claimDaily(Request $request)
    {
        $data = $request->validate([
            'client_claim_id' => ['required', 'string', 'max:80'],
        ]);

        try {
            $result = $this->shop->claimDaily($request->user(), $data['client_claim_id']);
        } catch (RuntimeException $e) {
            return $this->mapError($e);
        }

        return response()->json([
            ...$result['payload'],
            'idempotent_replay' => $result['replay'],
        ], $result['status']);
    }

    private function mapError(RuntimeException $e)
    {
        return match ($e->getMessage()) {
            'OFFER_NOT_FOUND' => ApiError::make('OFFER_NOT_FOUND', 'Unknown shop offer.', 404),
            'INSUFFICIENT_CURRENCY' => ApiError::make(
                'INSUFFICIENT_CURRENCY',
                'Not enough currency for this purchase.',
                422
            ),
            default => ApiError::make('SHOP_FAILED', 'Shop request failed.', 500, retryable: true),
        };
    }
}
