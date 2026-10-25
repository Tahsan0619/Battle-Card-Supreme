<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\CardDefinitionSeeder;
use Database\Seeders\GameModeSeeder;
use Database\Seeders\ProgressionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProgressRewardTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CardDefinitionSeeder::class);
        $this->seed(GameModeSeeder::class);
        $this->seed(ProgressionSeeder::class);
    }

    public function test_register_creates_profile_and_progress_endpoint(): void
    {
        $token = $this->postJson('/api/register', [
            'name' => 'Progress Commander',
            'email' => 'progress@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $progress = $this->withToken($token)->getJson('/api/progress');
        $progress->assertOk()
            ->assertJsonPath('profile.level', 1)
            ->assertJsonPath('profile.aether', 500)
            ->assertJsonPath('balance_version', 1);

        $me = $this->withToken($token)->getJson('/api/me');
        $me->assertOk()->assertJsonPath('profile.aether', 500);
    }

    public function test_victory_reward_claim_is_idempotent(): void
    {
        $token = $this->postJson('/api/register', [
            'name' => 'Reward Commander',
            'email' => 'reward@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $create = $this->withToken($token)->postJson('/api/matches', [
            'mode' => 'online_clash',
        ]);
        $create->assertCreated();
        $matchId = $create->json('match.id');

        // Authoritative victory for reward path (combat outcome covered elsewhere).
        \App\Models\GameMatch::whereKey($matchId)->update(['outcome' => 'victory_player']);

        $before = $this->withToken($token)->getJson('/api/progress')->json('profile.aether');

        $claim = $this->withToken($token)->postJson("/api/matches/{$matchId}/rewards/claim", [
            'client_claim_id' => 'claim-1',
        ]);
        $claim->assertCreated()
            ->assertJsonPath('claim.aether_granted', 35)
            ->assertJsonPath('idempotent_replay', false);

        $after = $this->withToken($token)->getJson('/api/progress')->json('profile.aether');
        $this->assertSame($before + 35, $after);

        $replay = $this->withToken($token)->postJson("/api/matches/{$matchId}/rewards/claim", [
            'client_claim_id' => 'claim-1',
        ]);
        $replay->assertOk()->assertJsonPath('idempotent_replay', true);

        $again = $this->withToken($token)->getJson('/api/progress')->json('profile.aether');
        $this->assertSame($after, $again);

        $secondKey = $this->withToken($token)->postJson("/api/matches/{$matchId}/rewards/claim", [
            'client_claim_id' => 'claim-2',
        ]);
        $secondKey->assertOk()->assertJsonPath('already_claimed', true);
        $this->assertSame($after, $this->withToken($token)->getJson('/api/progress')->json('profile.aether'));
    }

    public function test_non_victory_cannot_claim(): void
    {
        $token = $this->postJson('/api/register', [
            'name' => 'Forfeit Commander',
            'email' => 'forfeit@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $create = $this->withToken($token)->postJson('/api/matches', []);
        $matchId = $create->json('match.id');
        $outcome = $create->json('match.outcome');
        $version = $create->json('match.state_version');

        if ($outcome === 'ongoing') {
            $state = $create->json('match.state');
            $this->withToken($token)->postJson("/api/matches/{$matchId}/actions", [
                'type' => 'concede',
                'actor_id' => $state['current_actor_id'] ?? 'P0',
                'client_action_id' => 'concede-1',
                'state_version' => $version,
            ])->assertOk();
        } elseif ($outcome === 'victory_player') {
            $this->markTestSkipped('Match auto-resolved as victory; concede path unavailable.');
        }

        $claim = $this->withToken($token)->postJson("/api/matches/{$matchId}/rewards/claim", [
            'client_claim_id' => 'bad-claim',
        ]);
        $claim->assertStatus(422)->assertJsonPath('error.code', 'REWARD_NOT_ELIGIBLE');
    }

    public function test_admin_art_publish_and_audit(): void
    {
        $user = User::factory()->create([
            'email' => 'admin@example.com',
            'password' => 'Password1!',
            'is_admin' => true,
        ]);
        $token = $user->createToken('mobile')->plainTextToken;

        $list = $this->withToken($token)->getJson('/api/admin/cards');
        $list->assertOk();
        $this->assertGreaterThanOrEqual(50, $list->json('count'));

        $code = $list->json('cards.0.code');
        $publish = $this->withToken($token)->postJson("/api/admin/cards/{$code}/art/publish", [
            'tool' => 'curated_placeholder',
            'license_notes' => 'Internal placeholder license recorded.',
        ]);
        $publish->assertOk()
            ->assertJsonPath('card.art_status', 'published')
            ->assertJsonPath('art_asset.status', 'published');

        $audit = $this->withToken($token)->getJson('/api/admin/audit');
        $audit->assertOk();
        $this->assertSame('art_publish', $audit->json('logs.0.action'));
    }

    public function test_non_admin_blocked_from_cms(): void
    {
        $token = $this->postJson('/api/register', [
            'name' => 'Normie',
            'email' => 'normie@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $this->withToken($token)->getJson('/api/admin/cards')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');
    }
}
