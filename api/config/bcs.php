<?php

return [
    'min_app_version' => env('BCS_MIN_APP_VERSION', '1.0.0'),
    'catalogue_version' => (int) env('BCS_CATALOGUE_VERSION', 1),
    'api_version' => '1',

    'feature_flags' => [
        'shop' => (bool) env('BCS_FLAG_SHOP', true),
        'summon' => (bool) env('BCS_FLAG_SUMMON', true),
        'pvp' => (bool) env('BCS_FLAG_PVP', true),
        'ranking' => (bool) env('BCS_FLAG_RANKING', true),
        'guild' => (bool) env('BCS_FLAG_GUILD', false),
        'online_clash' => (bool) env('BCS_FLAG_ONLINE_CLASH', true),
        'survival_challenge' => (bool) env('BCS_FLAG_SURVIVAL', true),
        'rewards_claim' => (bool) env('BCS_FLAG_REWARDS', true),
    ],

    /*
     | Rate limit ceilings per class (requests per decay minutes).
     | Tests use these values; tighten in production via env.
     */
    'rate_limits' => [
        'auth' => [
            'max' => (int) env('BCS_RL_AUTH_MAX', 10),
            'decay_minutes' => (int) env('BCS_RL_AUTH_DECAY', 1),
        ],
        'read' => [
            'max' => (int) env('BCS_RL_READ_MAX', 120),
            'decay_minutes' => (int) env('BCS_RL_READ_DECAY', 1),
        ],
        'write' => [
            'max' => (int) env('BCS_RL_WRITE_MAX', 60),
            'decay_minutes' => (int) env('BCS_RL_WRITE_DECAY', 1),
        ],
        'match_action' => [
            'max' => (int) env('BCS_RL_MATCH_MAX', 90),
            'decay_minutes' => (int) env('BCS_RL_MATCH_DECAY', 1),
        ],
        'economy' => [
            'max' => (int) env('BCS_RL_ECONOMY_MAX', 20),
            'decay_minutes' => (int) env('BCS_RL_ECONOMY_DECAY', 1),
        ],
        'admin' => [
            'max' => (int) env('BCS_RL_ADMIN_MAX', 30),
            'decay_minutes' => (int) env('BCS_RL_ADMIN_DECAY', 1),
        ],
    ],
];
