<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class GameMode extends Model
{
    protected $fillable = [
        'code',
        'title',
        'subtitle',
        'is_available',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'is_available' => 'boolean',
        ];
    }

    public function ruleVersions(): HasMany
    {
        return $this->hasMany(ModeRuleVersion::class);
    }

    public function currentRules(): HasOne
    {
        return $this->hasOne(ModeRuleVersion::class)->where('is_current', true);
    }
}
