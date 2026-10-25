<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ArtAsset extends Model
{
    protected $fillable = [
        'card_definition_id',
        'status',
        'tool',
        'generated_on',
        'license_notes',
        'asset_path',
        'published_at',
    ];

    protected function casts(): array
    {
        return [
            'generated_on' => 'date',
            'published_at' => 'datetime',
        ];
    }

    public function cardDefinition(): BelongsTo
    {
        return $this->belongsTo(CardDefinition::class);
    }
}
