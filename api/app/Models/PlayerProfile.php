<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PlayerProfile extends Model
{
    public const AETHER_MAX = 9_999_999_999;
    public const VOID_SHARDS_MAX = 9_999_999_999;
    public const RIFT_MARKS_MAX = 9_999_999_999;
    public const XP_MAX = 9_999_999_999;
    public const LEVEL_MAX = 100;
    public const ENERGY_MAX_CAP = 99;

    protected $fillable = [
        'user_id',
        'level',
        'xp',
        'aether',
        'void_shards',
        'rift_marks',
        'key_iron',
        'key_silver',
        'key_gold',
        'energy',
        'energy_max',
        'energy_updated_at',
        'balance_version_seen',
    ];

    protected function casts(): array
    {
        return [
            'energy_updated_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function toApiArray(): array
    {
        return [
            'level' => $this->level,
            'xp' => $this->xp,
            'xp_to_next' => self::xpToNextLevel((int) $this->level),
            'aether' => $this->aether,
            'void_shards' => $this->void_shards,
            'rift_marks' => (int) $this->rift_marks,
            'keys' => [
                'iron' => (int) $this->key_iron,
                'silver' => (int) $this->key_silver,
                'gold' => (int) $this->key_gold,
            ],
            'energy' => $this->energy,
            'energy_max' => $this->energy_max,
            'energy_updated_at' => optional($this->energy_updated_at)?->toIso8601String(),
            'balance_version_seen' => $this->balance_version_seen,
        ];
    }

    public static function xpToNextLevel(int $level): int
    {
        $level = max(1, min(self::LEVEL_MAX, $level));

        return 100 + (($level - 1) * 25);
    }
}
