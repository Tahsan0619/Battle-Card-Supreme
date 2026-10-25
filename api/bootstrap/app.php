<?php

use App\Http\Middleware\AttachRequestId;
use App\Http\Middleware\EnsureAdmin;
use App\Http\Middleware\EnsureFeatureFlag;
use App\Http\Middleware\RateLimitClass;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->appendToGroup('api', [
            AttachRequestId::class,
        ]);

        $middleware->alias([
            'bcs.rate' => RateLimitClass::class,
            'bcs.flag' => EnsureFeatureFlag::class,
            'bcs.admin' => EnsureAdmin::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
