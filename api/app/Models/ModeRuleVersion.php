<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ModeRuleVersion extends Model
{
    protected $fillable = [
        'game_mode_id',
        'version',
        'rules_json',
        'is_current',
    ];

    protected function casts(): array
    {
        return [
            'rules_json' => 'array',
            'is_current' => 'boolean',
        ];
    }

    public function gameMode(): BelongsTo
    {
        return $this->belongsTo(GameMode::class);
    }
}
