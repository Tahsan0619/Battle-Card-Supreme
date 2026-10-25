<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DailyClaim extends Model
{
    protected $fillable = [
        'user_id',
        'claim_date',
        'aether_granted',
        'void_shards_granted',
        'client_claim_id',
    ];

    protected function casts(): array
    {
        return [
            'claim_date' => 'date',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
