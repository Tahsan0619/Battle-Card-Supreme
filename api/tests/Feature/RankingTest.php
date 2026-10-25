<?php

namespace Tests\Feature;

use App\Models\PlayerCard;
use App\Models\PlayerRating;
use App\Models\RatingLedgerEntry;
use App\Models\User;
use App\Support\ProgressService;
use Database\Seeders\CardDefinitionSeeder;
use Database\Seeders\GameModeSeeder;
use Database\Seeders\ProgressionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RankingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CardDefinitionSeeder::class);
        $this->seed(GameModeSeeder::class);
        $this->seed(ProgressionSeeder::class);
    }

    /**
     * @return array{0:User,1:list<string>}
     */
    private function makeCommander(string $email): array
    {
        $user = User::factory()->create([
            'email' => $email,
            'password' => 'Password1!',
        ]);
        app(ProgressService::class)->ensureProfile($user->id);

        $cards = \App\Models\CardDefinition::query()
            ->where('is_published', true)
            ->orderBy('id')
            ->limit(6)
            ->get();
        foreach ($cards as $card) {
            PlayerCard::firstOrCreate([
                'user_id' => $user->id,
                'card_definition_id' => $card->id,
            ], ['level' => 1]);
        }

        return [$user, $cards->take(3)->pluck('code')->values()->all()];
    }

    private function startPvpMatch(User $a, array $codesA, User $b, array $codesB): int
    {
        $this->actingAs($a, 'sanctum')->postJson('/api/pvp/queue', [
            'card_codes' => $codesA,
        ])->assertCreated();

        $offerId = $this->actingAs($b, 'sanctum')->postJson('/api/pvp/queue', [
            'card_codes' => $codesB,
        ])->json('offer.id');
        $this->assertNotNull($offerId);

        $this->actingAs($a, 'sanctum')->postJson("/api/pvp/offers/{$offerId}/accept")->assertOk();
        $ready = $this->actingAs($b, 'sanctum')->postJson("/api/pvp/offers/{$offerId}/accept");
        $ready->assertOk();
        $matchId = $ready->json('match_id') ?? $ready->json('offer.match_id');
        $this->assertNotNull($matchId);

        return (int) $matchId;
    }

    public function test_pvp_concede_applies_elo_once(): void
    {
        [$userA, $codesA] = $this->makeCommander('rank-a@example.com');
        [$userB, $codesB] = $this->makeCommander('rank-b@example.com');
        $matchId = $this->startPvpMatch($userA, $codesA, $userB, $codesB);

        $match = $this->actingAs($userA, 'sanctum')->getJson("/api/matches/{$matchId}")
            ->assertOk()
            ->json('match');

        $version = $match['state_version'];
        $actor = $match['state']['current_actor_id'] ?? 'P0';

        $this->actingAs($userA, 'sanctum')->postJson("/api/matches/{$matchId}/actions", [
            'type' => 'concede',
            'actor_id' => $actor,
            'client_action_id' => 'rank-concede-1',
            'state_version' => $version,
        ])->assertOk();

        $host = PlayerRating::query()->where('user_id', $userA->id)->first();
        $guest = PlayerRating::query()->where('user_id', $userB->id)->first();
        $this->assertNotNull($host);
        $this->assertNotNull($guest);
        $this->assertSame(984, $host->rating);
        $this->assertSame(1016, $guest->rating);
        $this->assertSame(1, $host->losses);
        $this->assertSame(1, $guest->wins);
        $this->assertSame(2, RatingLedgerEntry::query()->where('match_id', $matchId)->count());

        $this->actingAs($userA, 'sanctum')->getJson('/api/ranking/me')
            ->assertOk()
            ->assertJsonPath('rating.rating', 984)
            ->assertJsonPath('rating.losses', 1);

        $this->getJson('/api/leaderboard')
            ->assertOk()
            ->assertJsonPath('season_code', 'foundation')
            ->assertJsonPath('entries.0.rating', 1016);

        // Replay concede must not double-apply ranking.
        $this->actingAs($userA, 'sanctum')->postJson("/api/matches/{$matchId}/actions", [
            'type' => 'concede',
            'actor_id' => $actor,
            'client_action_id' => 'rank-concede-1',
            'state_version' => $version,
        ])->assertOk()->assertJsonPath('idempotent_replay', true);

        $this->assertSame(984, $host->fresh()->rating);
        $this->assertSame(2, RatingLedgerEntry::query()->where('match_id', $matchId)->count());
    }

    public function test_register_seeds_rating_profile(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Ranked Rookie',
            'email' => 'rookie-rank@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->assertCreated();

        $user = User::query()->where('email', 'rookie-rank@example.com')->firstOrFail();
        $row = PlayerRating::query()->where('user_id', $user->id)->first();
        $this->assertNotNull($row);
        $this->assertSame(1000, $row->rating);
    }

    public function test_flag_disables_ranking_routes(): void
    {
        config(['bcs.feature_flags.ranking' => false]);
        [$user] = $this->makeCommander('flag-rank@example.com');

        $this->getJson('/api/leaderboard')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FEATURE_DISABLED');

        $this->actingAs($user, 'sanctum')->getJson('/api/ranking/me')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FEATURE_DISABLED');
    }
}
