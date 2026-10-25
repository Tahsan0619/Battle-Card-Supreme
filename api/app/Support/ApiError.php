<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;

final class ApiError
{
    public static function make(
        string $code,
        string $message,
        int $status = 400,
        array $details = [],
        bool $retryable = false,
    ): JsonResponse {
        return response()->json([
            'error' => [
                'code' => $code,
                'message' => $message,
                'details' => $details,
                'request_id' => request()->header('X-Request-Id') ?: (string) str()->uuid(),
                'retryable' => $retryable,
            ],
        ], $status);
    }
}
