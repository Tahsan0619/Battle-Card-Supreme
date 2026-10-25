<?php

namespace App\Http\Middleware;

use App\Support\ApiError;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureFeatureFlag
{
    public function handle(Request $request, Closure $next, string $flag): Response
    {
        $enabled = (bool) config("bcs.feature_flags.{$flag}", false);
        if (! $enabled) {
            return ApiError::make(
                'FEATURE_DISABLED',
                "Feature {$flag} is disabled.",
                403,
                ['flag' => $flag],
            );
        }

        return $next($request);
    }
}
