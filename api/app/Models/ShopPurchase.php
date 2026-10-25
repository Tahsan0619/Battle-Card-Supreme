<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShopPurchase extends Model
{
    protected $fillable = [
        'user_id',
        'offer_code',
        'client_purchase_id',
        'cost_currency',
        'cost_amount',
        'grant_json',
    ];

    protected function casts(): array
    {
        return [
            'grant_json' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
