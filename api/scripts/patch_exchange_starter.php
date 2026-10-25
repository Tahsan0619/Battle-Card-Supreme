<?php

use Illuminate\Support\Facades\DB;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

DB::table('player_profiles')->update([
    'rift_marks' => DB::raw('GREATEST(rift_marks, 120)'),
    'key_iron' => DB::raw('GREATEST(key_iron, 3)'),
]);

echo 'patched '.DB::table('player_profiles')->count().PHP_EOL;
