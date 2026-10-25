<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PlayerCard extends Model
{
    protected $fillable = [
        'user_id',
        'card_definition_id',
        'level',
        'copies',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function cardDefinition(): BelongsTo
    {
        return $this->belongsTo(CardDefinition::class);
    }
}
