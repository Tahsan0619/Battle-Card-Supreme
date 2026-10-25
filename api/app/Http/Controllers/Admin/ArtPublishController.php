<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\ArtAsset;
use App\Models\CardDefinition;
use App\Support\ApiError;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ArtPublishController extends Controller
{
    public function index()
    {
        $cards = CardDefinition::query()
            ->orderBy('id')
            ->get()
            ->map(fn (CardDefinition $c) => [
                'code' => $c->code,
                'name' => $c->name,
                'art_seed' => $c->art_seed,
                'art_status' => $c->art_status ?? 'placeholder',
                'is_published' => $c->is_published,
                'balance_version' => $c->balance_version,
            ]);

        return response()->json(['cards' => $cards, 'count' => $cards->count()]);
    }

    public function publish(Request $request, string $code)
    {
        $data = $request->validate([
            'tool' => ['nullable', 'string', 'max:80'],
            'license_notes' => ['nullable', 'string', 'max:255'],
            'asset_path' => ['nullable', 'string', 'max:255'],
        ]);

        $card = CardDefinition::query()->where('code', $code)->first();
        if (! $card) {
            return ApiError::make('CARD_NOT_FOUND', "Missing card {$code}.", 404);
        }

        $result = DB::transaction(function () use ($request, $card, $data) {
            $asset = ArtAsset::query()
                ->where('card_definition_id', $card->id)
                ->orderByDesc('id')
                ->lockForUpdate()
                ->first();

            if (! $asset) {
                $asset = ArtAsset::create([
                    'card_definition_id' => $card->id,
                    'status' => 'placeholder',
                    'tool' => $data['tool'] ?? 'placeholder_pipeline',
                    'license_notes' => $data['license_notes'] ?? 'Generated placeholder. Curate before commercial.',
                ]);
            }

            $asset->status = 'published';
            $asset->tool = $data['tool'] ?? $asset->tool ?? 'placeholder_pipeline';
            $asset->license_notes = $data['license_notes'] ?? $asset->license_notes;
            $asset->asset_path = $data['asset_path'] ?? $asset->asset_path;
            $asset->published_at = now();
            $asset->save();

            $card->art_status = 'published';
            $card->art_seed = max(1, (int) $card->art_seed);
            $card->save();

            AdminAuditLog::create([
                'admin_user_id' => $request->user()->id,
                'action' => 'art_publish',
                'target_type' => 'card_definition',
                'target_id' => $card->code,
                'meta_json' => [
                    'art_asset_id' => $asset->id,
                    'tool' => $asset->tool,
                ],
            ]);

            return [$card->fresh(), $asset->fresh()];
        });

        [$card, $asset] = $result;

        return response()->json([
            'card' => [
                'code' => $card->code,
                'art_status' => $card->art_status,
                'art_seed' => $card->art_seed,
            ],
            'art_asset' => [
                'id' => $asset->id,
                'status' => $asset->status,
                'tool' => $asset->tool,
                'license_notes' => $asset->license_notes,
                'published_at' => optional($asset->published_at)?->toIso8601String(),
            ],
        ]);
    }

    public function audit()
    {
        $logs = AdminAuditLog::query()
            ->orderByDesc('id')
            ->limit(50)
            ->get()
            ->map(fn (AdminAuditLog $l) => [
                'id' => $l->id,
                'admin_user_id' => $l->admin_user_id,
                'action' => $l->action,
                'target_type' => $l->target_type,
                'target_id' => $l->target_id,
                'meta' => $l->meta_json,
                'created_at' => optional($l->created_at)?->toIso8601String(),
            ]);

        return response()->json(['logs' => $logs]);
    }
}
