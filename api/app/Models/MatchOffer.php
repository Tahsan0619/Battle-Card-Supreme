<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MatchOffer extends Model
{
    protected $fillable = [
        'user_a_id',
        'user_b_id',
        'cards_a',
        'cards_b',
        'status',
        'accept_a',
        'accept_b',
        'expires_at',
        'match_id',
    ];

    protected function casts(): array
    {
        return [
            'cards_a' => 'array',
            'cards_b' => 'array',
            'accept_a' => 'boolean',
            'accept_b' => 'boolean',
            'expires_at' => 'datetime',
        ];
    }

    public function userA(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_a_id');
    }

    public function userB(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_b_id');
    }

    public function match(): BelongsTo
    {
        return $this->belongsTo(GameMatch::class, 'match_id');
    }

    public function isParticipant(int $userId): bool
    {
        return (int) $this->user_a_id === $userId || (int) $this->user_b_id === $userId;
    }
}
