<?php

namespace App\Http\Middleware;

use App\Support\ApiError;
use App\Support\SecurityLog;
use Closure;
use Illuminate\Http\Request;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        if (! $user || ! $user->is_admin) {
            SecurityLog::authz('admin_denied', [
                'user_id' => $user?->id,
                'path' => $request->path(),
            ]);

            return ApiError::make('FORBIDDEN', 'Admin access required.', 403);
        }

        return $next($request);
    }
}
