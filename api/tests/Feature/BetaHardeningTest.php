<?php

namespace Tests\Feature;

use App\Models\Team;
use App\Models\User;
use Database\Seeders\CardDefinitionSeeder;
use Database\Seeders\GameModeSeeder;
use Database\Seeders\ProgressionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\RateLimiter;
use Tests\TestCase;

class BetaHardeningTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CardDefinitionSeeder::class);
        $this->seed(GameModeSeeder::class);
        $this->seed(ProgressionSeeder::class);
        RateLimiter::clear('bcs:auth:127.0.0.1:guest');
    }

    public function test_meta_exposes_versions_and_flags(): void
    {
        $res = $this->getJson('/api/meta');
        $res->assertOk()
            ->assertJsonStructure([
                'min_app_version',
                'catalogue_version',
                'balance_version',
                'feature_flags' => [
                    'shop',
                    'summon',
                    'pvp',
                    'ranking',
                    'online_clash',
                ],
            ])
            ->assertJsonPath('feature_flags.shop', true)
            ->assertJsonPath('feature_flags.summon', true)
            ->assertJsonPath('feature_flags.pvp', true)
            ->assertJsonPath('feature_flags.ranking', true)
            ->assertJsonPath('feature_flags.online_clash', true);

        $this->assertTrue($res->headers->has('X-Request-Id'));
    }

    public function test_ready_checks_database(): void
    {
        $this->getJson('/api/ready')
            ->assertOk()
            ->assertJsonPath('ready', true)
            ->assertJsonPath('checks.database', true);
    }

    public function test_match_idor_forbidden(): void
    {
        $owner = User::factory()->create(['email' => 'owner@example.com']);
        $intruder = User::factory()->create(['email' => 'intruder@example.com']);

        // Grant owner a published squad so match create succeeds.
        $this->actingAs($owner, 'sanctum');
        app(\App\Support\ProgressService::class)->ensureProfile($owner->id);
        foreach (\App\Models\CardDefinition::query()->where('is_published', true)->orderBy('id')->limit(3)->get() as $card) {
            \App\Models\PlayerCard::firstOrCreate([
                'user_id' => $owner->id,
                'card_definition_id' => $card->id,
            ], ['level' => 1]);
        }
        $codes = \App\Models\CardDefinition::query()->where('is_published', true)->orderBy('id')->limit(3)->pluck('code')->all();

        $create = $this->postJson('/api/matches', ['card_codes' => $codes]);
        $create->assertCreated();
        $matchId = $create->json('match.id');
        $this->assertNotNull($matchId);

        $this->actingAs($intruder, 'sanctum')
            ->getJson("/api/matches/{$matchId}")
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FORBIDDEN');

        $this->actingAs($intruder, 'sanctum')
            ->postJson("/api/matches/{$matchId}/rewards/claim", [
                'client_claim_id' => 'steal-1',
            ])
            ->assertForbidden();
    }

    public function test_team_idor_forbidden(): void
    {
        $owner = User::factory()->create(['email' => 'teamowner@example.com']);
        $team = Team::create([
            'user_id' => $owner->id,
            'name' => 'Secret',
            'is_active' => true,
        ]);

        $intruderToken = $this->postJson('/api/register', [
            'name' => 'Other',
            'email' => 'other@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $this->withToken($intruderToken)->putJson("/api/teams/{$team->id}", [
            'card_codes' => ['sr_astra_veyron', 'r_kairo_ren', 'l_sol_archon'],
        ])->assertForbidden()->assertJsonPath('error.code', 'FORBIDDEN');
    }

    public function test_feature_flag_disables_online_clash(): void
    {
        config(['bcs.feature_flags.online_clash' => false]);

        $token = $this->postJson('/api/register', [
            'name' => 'Flagged',
            'email' => 'flagged@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $this->withToken($token)->postJson('/api/matches', [])
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FEATURE_DISABLED');
    }

    public function test_auth_rate_limit_returns_429(): void
    {
        config(['bcs.rate_limits.auth.max' => 3, 'bcs.rate_limits.auth.decay_minutes' => 1]);
        RateLimiter::clear('bcs:auth:127.0.0.1:guest');

        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/login', [
                'email' => 'nobody@example.com',
                'password' => 'wrong',
            ]);
        }

        $this->postJson('/api/login', [
            'email' => 'nobody@example.com',
            'password' => 'wrong',
        ])->assertStatus(429)
            ->assertJsonPath('error.code', 'RATE_LIMITED');

        config(['bcs.rate_limits.auth.max' => 10]);
        RateLimiter::clear('bcs:auth:127.0.0.1:guest');
    }
}
