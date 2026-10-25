<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PlayerRating extends Model
{
    protected $fillable = [
        'user_id',
        'season_code',
        'rating',
        'wins',
        'losses',
        'draws',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function toApiArray(?int $rank = null): array
    {
        return [
            'user_id' => $this->user_id,
            'season_code' => $this->season_code,
            'rating' => $this->rating,
            'wins' => $this->wins,
            'losses' => $this->losses,
            'draws' => $this->draws,
            'matches' => $this->wins + $this->losses + $this->draws,
            'rank' => $rank,
            'display_name' => $this->user?->name,
        ];
    }
}
