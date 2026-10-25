<?php

namespace App\Http\Controllers;

use App\Models\CardDefinition;
use App\Support\ApiError;
use Illuminate\Http\Request;

class CardController extends Controller
{
    public function index(Request $request)
    {
        $query = CardDefinition::query()->where('is_published', true);

        if ($rarity = $request->query('rarity')) {
            $query->where('rarity', $rarity);
        }
        if ($role = $request->query('role')) {
            $query->where('role', $role);
        }
        if ($search = $request->query('q')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', '%'.$search.'%')
                    ->orWhere('code', 'like', '%'.$search.'%');
            });
        }

        $cards = $query->orderBy('id')->get()->map->toApiArray()->values();

        return response()->json([
            'catalogue_version' => 1,
            'count' => $cards->count(),
            'cards' => $cards,
        ]);
    }

    public function show(string $id)
    {
        $card = CardDefinition::query()
            ->where('is_published', true)
            ->where(function ($q) use ($id) {
                $q->where('code', $id);
                if (ctype_digit($id)) {
                    $q->orWhere('id', (int) $id);
                }
            })
            ->first();

        if (! $card) {
            return ApiError::make('CARD_NOT_FOUND', 'Card not found.', 404);
        }

        return response()->json(['card' => $card->toApiArray()]);
    }
}
