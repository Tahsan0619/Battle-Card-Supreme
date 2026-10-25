<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class GameMatch extends Model
{
    protected $table = 'matches';

    protected $fillable = [
        'user_id',
        'opponent_user_id',
        'mode',
        'is_pvp',
        'ranking_applied',
        'host_seat',
        'mode_rule_version',
        'mode_rules_snapshot',
        'balance_version',
        'outcome',
        'state_version',
        'state_json',
        'player_snapshot',
        'enemy_snapshot',
        'max_rounds',
        'rng_seed',
    ];

    protected function casts(): array
    {
        return [
            'state_json' => 'array',
            'player_snapshot' => 'array',
            'enemy_snapshot' => 'array',
            'mode_rules_snapshot' => 'array',
            'is_pvp' => 'boolean',
            'ranking_applied' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function opponent(): BelongsTo
    {
        return $this->belongsTo(User::class, 'opponent_user_id');
    }

    public function actions(): HasMany
    {
        return $this->hasMany(MatchAction::class, 'match_id');
    }

    public function isParticipant(int $userId): bool
    {
        return (int) $this->user_id === $userId
            || ((int) $this->opponent_user_id === $userId);
    }

    /** Host sits on player side (P*); opponent on enemy side (E*). */
    public function seatFor(int $userId): ?string
    {
        if ((int) $this->user_id === $userId) {
            return 'player';
        }
        if ((int) $this->opponent_user_id === $userId) {
            return 'enemy';
        }

        return null;
    }
}
