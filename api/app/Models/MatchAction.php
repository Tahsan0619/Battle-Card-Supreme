<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MatchAction extends Model
{
    protected $fillable = [
        'match_id',
        'user_id',
        'client_action_id',
        'state_version_before',
        'state_version_after',
        'action_json',
        'events_json',
    ];

    protected function casts(): array
    {
        return [
            'action_json' => 'array',
            'events_json' => 'array',
        ];
    }

    public function match(): BelongsTo
    {
        return $this->belongsTo(GameMatch::class, 'match_id');
    }
}
