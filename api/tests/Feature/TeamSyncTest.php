<?php

namespace Tests\Feature;

use App\Models\PlayerCard;
use Database\Seeders\CardDefinitionSeeder;
use Database\Seeders\GameModeSeeder;
use Database\Seeders\ProgressionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TeamSyncTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CardDefinitionSeeder::class);
        $this->seed(GameModeSeeder::class);
        $this->seed(ProgressionSeeder::class);
    }

    public function test_sync_updates_active_team(): void
    {
        $token = $this->postJson('/api/register', [
            'name' => 'Sync Commander',
            'email' => 'sync@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $codes = PlayerCard::query()
            ->where('user_id', $this->withToken($token)->getJson('/api/me')->json('user.id'))
            ->with('cardDefinition')
            ->orderBy('id')
            ->limit(3)
            ->get()
            ->map(fn ($pc) => $pc->cardDefinition->code)
            ->values()
            ->all();

        $this->withToken($token)->postJson('/api/teams/sync', [
            'card_codes' => $codes,
        ])->assertOk()
            ->assertJsonPath('team.slots.0.card.id', $codes[0])
            ->assertJsonPath('team.slots.1.card.id', $codes[1])
            ->assertJsonPath('team.slots.2.card.id', $codes[2]);

        $match = $this->withToken($token)->postJson('/api/matches', [
            'card_codes' => $codes,
        ]);
        $match->assertCreated();
    }

    public function test_sync_rejects_unowned_cards(): void
    {
        $token = $this->postJson('/api/register', [
            'name' => 'No Grant',
            'email' => 'nogrant@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $this->withToken($token)->postJson('/api/teams/sync', [
            'card_codes' => ['sr_astra_veyron', 'r_kairo_ren', 'l_sol_archon'],
        ])->assertStatus(422)
            ->assertJsonPath('error.code', 'CARD_NOT_OWNED');
    }
}
