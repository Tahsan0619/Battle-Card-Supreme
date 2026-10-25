<?php

namespace App\Http\Controllers;

use App\Support\CollectionService;
use Illuminate\Http\Request;

class CollectionController extends Controller
{
    public function __construct(private CollectionService $collection) {}

    public function index(Request $request)
    {
        return response()->json($this->collection->catalogueFor($request->user()));
    }
}
