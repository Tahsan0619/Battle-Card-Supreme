<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MatchRewardClaim extends Model
{
    protected $fillable = [
        'user_id',
        'match_id',
        'reward_code',
        'xp_granted',
        'aether_granted',
        'rift_marks_granted',
        'iron_keys_granted',
        'client_claim_id',
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
