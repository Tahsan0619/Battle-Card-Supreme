<?php

namespace App\Support;

use App\Models\GameMode;
use App\Models\ModeRuleVersion;

final class ModeCatalog
{
    /**
     * @return array{mode:GameMode,rules:ModeRuleVersion}|null
     */
    public function resolve(string $code, bool $requireAvailable = true): ?array
    {
        $query = GameMode::query()->where('code', $code)->with('currentRules');
        if ($requireAvailable) {
            $query->where('is_available', true);
        }
        $mode = $query->first();
        if (! $mode instanceof GameMode || ! $mode->currentRules instanceof ModeRuleVersion) {
            return null;
        }

        return ['mode' => $mode, 'rules' => $mode->currentRules];
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function listPublic(): array
    {
        return GameMode::query()
            ->with('currentRules')
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->map(function (GameMode $mode) {
                $rules = $mode->currentRules;

                return [
                    'code' => $mode->code,
                    'title' => $mode->title,
                    'subtitle' => $mode->subtitle,
                    'available' => (bool) $mode->is_available,
                    'rule_version' => $rules?->version,
                    'rules' => $rules?->rules_json,
                ];
            })
            ->all();
    }
}
