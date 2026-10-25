<?php

namespace Database\Seeders;

use App\Models\GameMode;
use App\Models\ModeRuleVersion;
use Illuminate\Database\Seeder;

class GameModeSeeder extends Seeder
{
    public function run(): void
    {
        $modes = [
            [
                'code' => 'classic_clash',
                'title' => 'Classic Card Clash',
                'subtitle' => 'Turn-based squad vs AI. Shared combat engine.',
                'is_available' => true,
                'sort_order' => 10,
                'rules' => [
                    'team_size' => 3,
                    'max_rounds' => 30,
                    'waves' => 1,
                    'heal_between_waves_percent' => 0,
                    'ownership_required' => true,
                    'ranking_eligible' => false,
                    'opponent' => 'ai',
                    'channel' => 'both',
                ],
            ],
            [
                'code' => 'online_clash',
                'title' => 'Online Card Clash',
                'subtitle' => 'Server-authoritative combat. Requires login.',
                'is_available' => true,
                'sort_order' => 20,
                'rules' => [
                    'team_size' => 3,
                    'max_rounds' => 30,
                    'waves' => 1,
                    'heal_between_waves_percent' => 0,
                    'ownership_required' => true,
                    'ranking_eligible' => false,
                    'opponent' => 'ai',
                    'channel' => 'online',
                ],
            ],
            [
                'code' => 'survival_challenge',
                'title' => 'Survival Challenge',
                'subtitle' => 'Three escalating waves. HP carries between fights.',
                'is_available' => true,
                'sort_order' => 30,
                'rules' => [
                    'team_size' => 3,
                    'max_rounds' => 20,
                    'waves' => 3,
                    'heal_between_waves_percent' => 25,
                    'ownership_required' => true,
                    'ranking_eligible' => false,
                    'opponent' => 'ai',
                    'channel' => 'offline',
                ],
            ],
            [
                'code' => 'pvp_clash',
                'title' => 'PvP Card Clash',
                'subtitle' => 'Queue, accept window, then server-authoritative duel.',
                'is_available' => true,
                'sort_order' => 35,
                'rules' => [
                    'team_size' => 3,
                    'max_rounds' => 30,
                    'waves' => 1,
                    'heal_between_waves_percent' => 0,
                    'ownership_required' => true,
                    'ranking_eligible' => true,
                    'opponent' => 'human',
                    'channel' => 'online',
                    'accept_window_seconds' => 30,
                ],
            ],
            [
                'code' => 'boss_raid',
                'title' => 'Boss Raid',
                'subtitle' => 'Phased AI boss. Coming later.',
                'is_available' => false,
                'sort_order' => 40,
                'rules' => [
                    'team_size' => 3,
                    'max_rounds' => 40,
                    'waves' => 1,
                    'heal_between_waves_percent' => 0,
                    'ownership_required' => true,
                    'ranking_eligible' => false,
                    'opponent' => 'boss',
                    'channel' => 'both',
                ],
            ],
            [
                'code' => 'draft_challenge',
                'title' => 'Draft Challenge',
                'subtitle' => 'Limited pool drafting. Locked for now.',
                'is_available' => false,
                'sort_order' => 50,
                'rules' => [
                    'team_size' => 3,
                    'max_rounds' => 25,
                    'waves' => 1,
                    'heal_between_waves_percent' => 0,
                    'ownership_required' => false,
                    'ranking_eligible' => false,
                    'opponent' => 'ai',
                    'channel' => 'both',
                ],
            ],
        ];

        foreach ($modes as $def) {
            $mode = GameMode::updateOrCreate(
                ['code' => $def['code']],
                [
                    'title' => $def['title'],
                    'subtitle' => $def['subtitle'],
                    'is_available' => $def['is_available'],
                    'sort_order' => $def['sort_order'],
                ]
            );

            ModeRuleVersion::query()
                ->where('game_mode_id', $mode->id)
                ->update(['is_current' => false]);

            ModeRuleVersion::updateOrCreate(
                [
                    'game_mode_id' => $mode->id,
                    'version' => 1,
                ],
                [
                    'rules_json' => $def['rules'],
                    'is_current' => true,
                ]
            );
        }
    }
}
