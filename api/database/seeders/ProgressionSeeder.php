<?php

namespace Database\Seeders;

use App\Models\ArtAsset;
use App\Models\BalanceVersion;
use App\Models\CardDefinition;
use Illuminate\Database\Seeder;

class ProgressionSeeder extends Seeder
{
    public function run(): void
    {
        BalanceVersion::query()->update(['is_current' => false]);
        BalanceVersion::updateOrCreate(
            ['version' => 1],
            [
                'notes' => 'Foundation balance freeze.',
                'is_current' => true,
            ]
        );

        foreach (CardDefinition::query()->orderBy('id')->cursor() as $card) {
            if (! isset($card->art_status) || $card->art_status === null) {
                $card->art_status = 'placeholder';
                $card->save();
            }

            ArtAsset::firstOrCreate(
                ['card_definition_id' => $card->id],
                [
                    'status' => 'placeholder',
                    'tool' => 'placeholder_pipeline',
                    'generated_on' => now()->toDateString(),
                    'license_notes' => 'Placeholder. Record tool/date/license before commercial publish.',
                    'asset_path' => 'placeholders/'.$card->code.'.png',
                ]
            );
        }
    }
}
