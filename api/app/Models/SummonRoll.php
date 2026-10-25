<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SummonRoll extends Model
{
    protected $fillable = [
        'user_id',
        'banner_code',
        'client_summon_id',
        'rng_seed',
        'rng_draw',
        'result_rarity',
        'result_card_code',
        'was_duplicate',
        'shards_granted',
        'cost_currency',
        'cost_amount',
    ];

    protected function casts(): array
    {
        return [
            'was_duplicate' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
