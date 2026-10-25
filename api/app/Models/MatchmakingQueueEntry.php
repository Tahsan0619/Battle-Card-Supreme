<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MatchmakingQueueEntry extends Model
{
    protected $table = 'matchmaking_queue';

    protected $fillable = [
        'user_id',
        'card_codes',
        'status',
        'offer_id',
    ];

    protected function casts(): array
    {
        return [
            'card_codes' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function offer(): BelongsTo
    {
        return $this->belongsTo(MatchOffer::class, 'offer_id');
    }
}
