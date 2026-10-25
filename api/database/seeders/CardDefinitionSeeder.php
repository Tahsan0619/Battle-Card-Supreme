<?php

namespace Database\Seeders;

use App\Models\CardDefinition;
use App\Support\StatBudget;
use Illuminate\Database\Seeder;

class CardDefinitionSeeder extends Seeder
{
    public function run(): void
    {
        $path = database_path('data/roster.json');
        $rows = json_decode(file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);

        foreach ($rows as $row) {
            $stats = StatBudget::divide($row['rarity'], $row['role']);

            CardDefinition::updateOrCreate(
                ['code' => $row['id']],
                [
                    'name' => $row['name'],
                    'pitch' => $row['pitch'],
                    'lore' => $row['lore'],
                    'rarity' => $row['rarity'],
                    'role' => $row['role'],
                    'faction' => $row['faction'],
                    'hp' => $stats['hp'],
                    'atk' => $stats['atk'],
                    'def' => $stats['def'],
                    'spd' => $stats['spd'],
                    'en' => $stats['en'],
                    'passive_name' => $row['passive_name'],
                    'passive_description' => $row['passive_description'],
                    'ability_id' => $row['ability_id'],
                    'ability_name' => $row['ability_name'],
                    'ability_description' => $row['ability_description'],
                    'ability_en_cost' => $row['en_cost'],
                    'ability_cooldown' => $row['cooldown'],
                    'ability_multiplier' => $row['mult'],
                    'ability_heal_percent' => $row['heal'],
                    'ability_shield_percent' => $row['shield'],
                    'ability_is_aoe' => $row['aoe'],
                    'synergy_tags' => $row['tags'] ?? [],
                    'art_seed' => $row['art_seed'] ?? 0,
                    'balance_version' => 1,
                    'card_version' => 1,
                    'is_published' => true,
                ]
            );
        }
    }
}
