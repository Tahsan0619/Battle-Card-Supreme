<?php

return [
    'starter_card_count' => 3,

    'offers' => [
        [
            'code' => 'energy_refill',
            'title' => 'Energy Refill',
            'description' => 'Restore energy to full (server clock).',
            'cost_currency' => 'aether',
            'cost_amount' => 40,
            'grant' => ['type' => 'energy_full'],
        ],
        [
            'code' => 'shard_pouch',
            'title' => 'Void Shard Pouch',
            'description' => '10 Void Shards for crafting economy.',
            'cost_currency' => 'aether',
            'cost_amount' => 80,
            'grant' => ['type' => 'currency', 'currency' => 'void_shards', 'amount' => 10],
        ],
        [
            'code' => 'aether_exchange',
            'title' => 'Shard Exchange',
            'description' => 'Trade 5 Void Shards for 50 Aether.',
            'cost_currency' => 'void_shards',
            'cost_amount' => 5,
            'grant' => ['type' => 'currency', 'currency' => 'aether', 'amount' => 50],
        ],
    ],

    'daily' => [
        'aether' => 25,
        'void_shards' => 1,
    ],

    'summon' => [
        'banners' => [
            [
                'code' => 'standard_rift',
                'title' => 'Standard Rift Summon',
                'description' => 'One random published card. Duplicates convert to Void Shards.',
                'cost_currency' => 'aether',
                'cost_amount' => 100,
                // Basis points out of 10000. Must sum to 10000.
                'rates_bp' => [
                    'common' => 5000,
                    'uncommon' => 2800,
                    'rare' => 1400,
                    'superRare' => 500,
                    'epic' => 220,
                    'legendary' => 60,
                    'mythic' => 15,
                    'supreme' => 5,
                ],
                'duplicate_shards' => [
                    'common' => 1,
                    'uncommon' => 2,
                    'rare' => 4,
                    'superRare' => 8,
                    'epic' => 12,
                    'legendary' => 30,
                    'mythic' => 60,
                    'supreme' => 120,
                ],
            ],
        ],
    ],
];
