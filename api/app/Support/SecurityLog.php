<?php

namespace App\Support;

use Illuminate\Support\Facades\Log;

final class SecurityLog
{
    public static function authz(string $event, array $context = []): void
    {
        Log::channel('stack')->warning('bcs.security', array_merge([
            'event' => $event,
            'request_id' => request()->attributes->get('request_id')
                ?? request()->header('X-Request-Id'),
        ], $context));
    }

    public static function economy(string $event, array $context = []): void
    {
        Log::channel('stack')->info('bcs.economy', array_merge([
            'event' => $event,
            'request_id' => request()->attributes->get('request_id')
                ?? request()->header('X-Request-Id'),
        ], $context));
    }

    public static function match(string $event, array $context = []): void
    {
        Log::channel('stack')->info('bcs.match', array_merge([
            'event' => $event,
            'request_id' => request()->attributes->get('request_id')
                ?? request()->header('X-Request-Id'),
        ], $context));
    }
}
