<?php

namespace App\Http\Controllers;

use App\Support\ApiError;
use App\Support\ChestService;
use App\Support\CollectionService;
use Illuminate\Http\Request;
use RuntimeException;

class ChestController extends Controller
{
    public function __construct(
        private ChestService $chests,
        private CollectionService $collection,
    ) {}

    public function catalogue(Request $request)
    {
        return response()->json($this->chests->catalogue($request->user()));
    }

    public function buyKey(Request $request)
    {
        $data = $request->validate([
            'key_code' => ['required', 'string', 'in:iron,silver,gold'],
            'client_purchase_id' => ['required', 'string', 'max:120'],
        ]);

        try {
            $result = $this->chests->buyKey(
                $request->user(),
                $data['key_code'],
                $data['client_purchase_id'],
            );
        } catch (RuntimeException $e) {
            return $this->mapError($e->getMessage());
        }

        return response()->json($result['payload'], $result['status']);
    }

    public function open(Request $request)
    {
        $data = $request->validate([
            'chest_code' => ['required', 'string', 'max:64'],
            'client_open_id' => ['required', 'string', 'max:120'],
        ]);

        try {
            $result = $this->chests->open(
                $request->user(),
                $data['chest_code'],
                $data['client_open_id'],
            );
        } catch (RuntimeException $e) {
            return $this->mapError($e->getMessage());
        }

        return response()->json($result['payload'], $result['status']);
    }

    public function levelUp(Request $request, string $code)
    {
        try {
            $payload = $this->collection->levelUp($request->user(), $code);
        } catch (RuntimeException $e) {
            return $this->mapError($e->getMessage());
        }

        return response()->json($payload);
    }

    private function mapError(string $code)
    {
        return match ($code) {
            'INSUFFICIENT_CURRENCY' => ApiError::make('INSUFFICIENT_CURRENCY', 'Not enough currency.', 422),
            'INSUFFICIENT_KEYS' => ApiError::make('INSUFFICIENT_KEYS', 'Not enough keys for this chest.', 422),
            'INSUFFICIENT_COPIES' => ApiError::make('INSUFFICIENT_COPIES', 'Not enough duplicate copies to level up.', 422),
            'CARD_NOT_OWNED' => ApiError::make('CARD_NOT_OWNED', 'You do not own this card.', 404),
            'CARD_NOT_FOUND' => ApiError::make('CARD_NOT_FOUND', 'Unknown card.', 404),
            'CARD_MAX_LEVEL' => ApiError::make('CARD_MAX_LEVEL', 'Card is already max level.', 422),
            'CHEST_NOT_FOUND', 'KEY_NOT_FOUND' => ApiError::make($code, 'Unknown exchange item.', 404),
            default => ApiError::make('INTERNAL_ERROR', 'Exchange action failed.', 500, retryable: true),
        };
    }
}
