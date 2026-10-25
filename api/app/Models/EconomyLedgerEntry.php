<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EconomyLedgerEntry extends Model
{
    protected $table = 'economy_ledger';

    protected $fillable = [
        'user_id',
        'currency_code',
        'delta',
        'balance_after',
        'reason_code',
        'reference_type',
        'reference_id',
        'request_id',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
