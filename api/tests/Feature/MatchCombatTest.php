<?php

namespace Tests\Feature;

use App\Models\CardDefinition;
use Database\Seeders\CardDefinitionSeeder;
use Database\Seeders\GameModeSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MatchCombatTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CardDefinitionSeeder::class);
        $this->seed(GameModeSeeder::class);
    }

    public function test_create_match_and_play_until_end_or_action(): void
    {
        $token = $this->postJson('/api/register', [
            'name' => 'Online Commander',
            'email' => 'online@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $create = $this->withToken($token)->postJson('/api/matches', []);
        $create->assertCreated()
            ->assertJsonStructure(['match' => ['id', 'state_version', 'state', 'outcome']]);

        $matchId = $create->json('match.id');
        $version = $create->json('match.state_version');
        $state = $create->json('match.state');

        if ($state['outcome'] !== 'ongoing') {
            $this->assertContains($state['outcome'], [
                'victory_player',
                'victory_enemy',
                'draw',
                'forfeit_player',
            ]);

            return;
        }

        $this->assertTrue($state['is_player_turn']);
        $actorId = $state['current_actor_id'];
        $targetId = collect($state['enemy'])->firstWhere('is_alive', true)['instance_id'] ?? null;

        $action = $this->withToken($token)->postJson("/api/matches/{$matchId}/actions", [
            'type' => 'basic_attack',
            'actor_id' => $actorId,
            'target_id' => $targetId,
            'client_action_id' => 'test-atk-1',
            'state_version' => $version,
        ]);

        $action->assertOk()
            ->assertJsonPath('idempotent_replay', false);
        $this->assertGreaterThan($version, $action->json('match.state_version'));

        // Idempotent replay
        $replay = $this->withToken($token)->postJson("/api/matches/{$matchId}/actions", [
            'type' => 'basic_attack',
            'actor_id' => $actorId,
            'target_id' => $targetId,
            'client_action_id' => 'test-atk-1',
            'state_version' => $version,
        ]);
        $replay->assertOk()->assertJsonPath('idempotent_replay', true);

        // Stale version rejected when using a new action id
        if ($action->json('match.outcome') === 'ongoing') {
            $stale = $this->withToken($token)->postJson("/api/matches/{$matchId}/actions", [
                'type' => 'end_turn',
                'actor_id' => $action->json('match.state.current_actor_id'),
                'client_action_id' => 'stale-1',
                'state_version' => $version,
            ]);
            $stale->assertStatus(409)->assertJsonPath('error.code', 'MATCH_STATE_CONFLICT');
        }

        $this->withToken($token)->getJson("/api/matches/{$matchId}/history")
            ->assertOk()
            ->assertJsonStructure(['actions', 'log']);
    }

    public function test_cannot_start_with_unowned_codes(): void
    {
        $register = $this->postJson('/api/register', [
            'name' => 'Poor Commander',
            'email' => 'poor@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->assertCreated();

        $token = $register->json('token');
        $userId = $register->json('user.id');

        $codes = CardDefinition::query()->orderByDesc('id')->limit(3)->pluck('code')->all();
        $ids = CardDefinition::query()->whereIn('code', $codes)->pluck('id');
        \App\Models\PlayerCard::query()
            ->where('user_id', $userId)
            ->whereIn('card_definition_id', $ids)
            ->delete();

        $this->withToken($token)->postJson('/api/matches', [
            'card_codes' => $codes,
        ])->assertStatus(422)->assertJsonPath('error.code', 'CARD_NOT_OWNED');
    }
}
