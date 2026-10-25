<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChestOpen extends Model
{
    protected $fillable = [
        'user_id',
        'chest_code',
        'client_open_id',
        'key_code',
        'keys_spent',
        'rng_seed',
        'results_json',
    ];

    protected function casts(): array
    {
        return [
            'results_json' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
