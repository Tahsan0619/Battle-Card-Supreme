<?php

namespace App\Http\Controllers;

use App\Support\ModeCatalog;

class ModeController extends Controller
{
    public function __construct(private ModeCatalog $catalog) {}

    public function index()
    {
        return response()->json([
            'modes' => $this->catalog->listPublic(),
        ]);
    }
}
