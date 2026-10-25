<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BalanceVersion extends Model
{
    protected $fillable = [
        'version',
        'notes',
        'is_current',
    ];

    protected function casts(): array
    {
        return [
            'is_current' => 'boolean',
        ];
    }
}
