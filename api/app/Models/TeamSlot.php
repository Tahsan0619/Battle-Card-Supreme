<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeamSlot extends Model
{
    protected $fillable = [
        'team_id',
        'slot_index',
        'card_definition_id',
    ];

    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    public function cardDefinition(): BelongsTo
    {
        return $this->belongsTo(CardDefinition::class);
    }
}
