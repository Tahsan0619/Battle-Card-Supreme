<?php

namespace App\Http\Middleware;

use App\Support\ApiError;
use App\Support\SecurityLog;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Symfony\Component\HttpFoundation\Response;

class RateLimitClass
{
    public function handle(Request $request, Closure $next, string $class): Response
    {
        $cfg = config("bcs.rate_limits.{$class}", ['max' => 60, 'decay_minutes' => 1]);
        $max = (int) ($cfg['max'] ?? 60);
        $decay = (int) ($cfg['decay_minutes'] ?? 1);

        $key = sprintf(
            'bcs:%s:%s:%s',
            $class,
            $request->ip() ?: 'unknown',
            optional($request->user())->id ?? 'guest'
        );

        if (RateLimiter::tooManyAttempts($key, $max)) {
            SecurityLog::authz('rate_limited', [
                'class' => $class,
                'key' => $key,
            ]);

            $retry = RateLimiter::availableIn($key);

            return ApiError::make(
                'RATE_LIMITED',
                'Too many requests. Slow down.',
                429,
                ['class' => $class, 'retry_after_seconds' => $retry],
                retryable: true,
            )->withHeaders([
                'Retry-After' => (string) $retry,
                'X-RateLimit-Limit' => (string) $max,
            ]);
        }

        RateLimiter::hit($key, $decay * 60);

        /** @var Response $response */
        $response = $next($request);
        $response->headers->set('X-RateLimit-Limit', (string) $max);
        $response->headers->set(
            'X-RateLimit-Remaining',
            (string) max(0, $max - RateLimiter::attempts($key))
        );

        return $response;
    }
}
