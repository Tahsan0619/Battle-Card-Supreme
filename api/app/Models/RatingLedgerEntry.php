<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RatingLedgerEntry extends Model
{
    protected $table = 'rating_ledger';

    protected $fillable = [
        'user_id',
        'season_code',
        'match_id',
        'rating_before',
        'rating_delta',
        'rating_after',
        'opponent_rating',
        'result',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function match(): BelongsTo
    {
        return $this->belongsTo(GameMatch::class, 'match_id');
    }
}
