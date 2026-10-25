<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CardDefinition extends Model
{
    protected $fillable = [
        'code',
        'name',
        'pitch',
        'lore',
        'rarity',
        'role',
        'faction',
        'hp',
        'atk',
        'def',
        'spd',
        'en',
        'passive_name',
        'passive_description',
        'ability_id',
        'ability_name',
        'ability_description',
        'ability_en_cost',
        'ability_cooldown',
        'ability_multiplier',
        'ability_heal_percent',
        'ability_shield_percent',
        'ability_is_aoe',
        'synergy_tags',
        'art_seed',
        'art_status',
        'balance_version',
        'card_version',
        'is_published',
    ];

    protected function casts(): array
    {
        return [
            'synergy_tags' => 'array',
            'ability_is_aoe' => 'boolean',
            'is_published' => 'boolean',
        ];
    }

    public function playerCards(): HasMany
    {
        return $this->hasMany(PlayerCard::class);
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->code,
            'db_id' => $this->id,
            'name' => $this->name,
            'pitch' => $this->pitch,
            'lore' => $this->lore,
            'rarity' => $this->rarity,
            'role' => $this->role,
            'faction' => $this->faction,
            'stats' => [
                'hp' => $this->hp,
                'atk' => $this->atk,
                'def' => $this->def,
                'spd' => $this->spd,
                'en' => $this->en,
            ],
            'passive' => [
                'name' => $this->passive_name,
                'description' => $this->passive_description,
            ],
            'active' => [
                'id' => $this->ability_id,
                'name' => $this->ability_name,
                'description' => $this->ability_description,
                'en_cost' => $this->ability_en_cost,
                'cooldown_turns' => $this->ability_cooldown,
                'multiplier_percent' => $this->ability_multiplier,
                'heal_percent' => $this->ability_heal_percent,
                'shield_percent' => $this->ability_shield_percent,
                'is_aoe' => $this->ability_is_aoe,
            ],
            'synergy_tags' => $this->synergy_tags ?? [],
            'art_seed' => $this->art_seed,
            'art_status' => $this->art_status ?? 'placeholder',
            'balance_version' => $this->balance_version,
            'card_version' => $this->card_version,
        ];
    }
}
