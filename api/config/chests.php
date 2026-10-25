<?php

/**
 * Astral Exchange chests + keys.
 * Iron key -> Dock Crate, Brine Cache
 * Silver key -> Gale Reliquary, Eclipse Casket
 * Gold key -> Sovereign Reliquary
 */
return [
    'starter_card_count' => 3,
    'max_card_level' => 10,
    // Copies consumed to advance from level L to L+1.
    'copies_to_level' => null, // use level value itself

    'keys' => [
        'iron' => [
            'code' => 'iron',
            'title' => 'Iron Rift Key',
            'description' => 'Opens Dock Crate and Brine Cache.',
            'opens' => ['dock_crate', 'brine_cache'],
            'shop_cost_currency' => 'rift_marks',
            'shop_cost_amount' => 40,
        ],
        'silver' => [
            'code' => 'silver',
            'title' => 'Silver Rift Key',
            'description' => 'Opens Gale Reliquary and Eclipse Casket.',
            'opens' => ['gale_reliquary', 'eclipse_casket'],
            'shop_cost_currency' => 'rift_marks',
            'shop_cost_amount' => 120,
        ],
        'gold' => [
            'code' => 'gold',
            'title' => 'Gold Rift Key',
            'description' => 'Opens the Sovereign Reliquary.',
            'opens' => ['sovereign_reliquary'],
            'shop_cost_currency' => 'rift_marks',
            'shop_cost_amount' => 400,
        ],
    ],

    'chests' => [
        [
            'code' => 'dock_crate',
            'title' => 'Dock Crate',
            'tier' => 'basic',
            'description' => 'Harbor scrap chest. Mostly common relics.',
            'key_code' => 'iron',
            'keys_required' => 1,
            'pull_count' => 3,
            'rates_bp' => [
                'common' => 7000,
                'uncommon' => 2500,
                'rare' => 450,
                'superRare' => 40,
                'epic' => 10,
                'legendary' => 0,
                'mythic' => 0,
                'supreme' => 0,
            ],
        ],
        [
            'code' => 'brine_cache',
            'title' => 'Brine Cache',
            'tier' => 'common',
            'description' => 'Salt-sealed cache with steadier uncommon odds.',
            'key_code' => 'iron',
            'keys_required' => 2,
            'pull_count' => 4,
            'rates_bp' => [
                'common' => 5500,
                'uncommon' => 3200,
                'rare' => 1000,
                'superRare' => 250,
                'epic' => 50,
                'legendary' => 0,
                'mythic' => 0,
                'supreme' => 0,
            ],
        ],
        [
            'code' => 'gale_reliquary',
            'title' => 'Gale Reliquary',
            'tier' => 'uncommon',
            'description' => 'Storm-bound coffer. Rare relics appear more often.',
            'key_code' => 'silver',
            'keys_required' => 1,
            'pull_count' => 4,
            'rates_bp' => [
                'common' => 3000,
                'uncommon' => 4000,
                'rare' => 2200,
                'superRare' => 650,
                'epic' => 140,
                'legendary' => 10,
                'mythic' => 0,
                'supreme' => 0,
            ],
        ],
        [
            'code' => 'eclipse_casket',
            'title' => 'Eclipse Casket',
            'tier' => 'epic',
            'description' => 'Order vault. Heavy epic weighting.',
            'key_code' => 'silver',
            'keys_required' => 3,
            'pull_count' => 5,
            'rates_bp' => [
                'common' => 1500,
                'uncommon' => 2800,
                'rare' => 3000,
                'superRare' => 1800,
                'epic' => 750,
                'legendary' => 140,
                'mythic' => 10,
                'supreme' => 0,
            ],
        ],
        [
            'code' => 'sovereign_reliquary',
            'title' => 'Sovereign Reliquary',
            'tier' => 'legendary',
            'description' => 'Apex chest. Legendary through Supreme possible.',
            'key_code' => 'gold',
            'keys_required' => 1,
            'pull_count' => 5,
            'rates_bp' => [
                'common' => 500,
                'uncommon' => 1500,
                'rare' => 2800,
                'superRare' => 2500,
                'epic' => 1800,
                'legendary' => 700,
                'mythic' => 170,
                'supreme' => 30,
            ],
        ],
    ],

    'match_victory' => [
        'rift_marks' => 35,
        'iron_key_chance_bp' => 1500, // 15%
    ],
];
