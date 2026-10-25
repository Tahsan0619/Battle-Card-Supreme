<?php

namespace Tests\Feature;

use App\Models\PlayerCard;
use App\Models\User;
use App\Support\ProgressService;
use Database\Seeders\CardDefinitionSeeder;
use Database\Seeders\GameModeSeeder;
use Database\Seeders\ProgressionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PvpMatchmakingTest extends TestCase
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

        $codes = $cards->take(3)->pluck('code')->values()->all();

        return [$user, $codes];
    }

    public function test_two_players_queue_accept_and_play(): void
    {
        [$userA, $codesA] = $this->makeCommander('pvp-a@example.com');
        [$userB, $codesB] = $this->makeCommander('pvp-b@example.com');

        $qa = $this->actingAs($userA, 'sanctum')->postJson('/api/pvp/queue', [
            'card_codes' => $codesA,
        ]);
        $qa->assertCreated()->assertJsonPath('queue.status', 'queued');

        $qb = $this->actingAs($userB, 'sanctum')->postJson('/api/pvp/queue', [
            'card_codes' => $codesB,
        ]);
        $qb->assertCreated();
        $this->assertNotNull($qb->json('offer.id'), 'Body: '.json_encode($qb->json()));
        $offerId = $qb->json('offer.id');

        $this->actingAs($userA, 'sanctum')->getJson('/api/pvp/status')
            ->assertOk()
            ->assertJsonPath('offer.id', $offerId);

        $this->actingAs($userA, 'sanctum')->postJson("/api/pvp/offers/{$offerId}/accept")->assertOk();
        $ready = $this->actingAs($userB, 'sanctum')->postJson("/api/pvp/offers/{$offerId}/accept");
        $ready->assertOk();
        $matchId = $ready->json('match_id') ?? $ready->json('offer.match_id');
        $this->assertNotNull($matchId);

        $this->actingAs($userA, 'sanctum')->getJson("/api/matches/{$matchId}")
            ->assertOk()
            ->assertJsonPath('match.is_pvp', true)
            ->assertJsonPath('match.your_seat', 'player');

        $this->actingAs($userB, 'sanctum')->getJson("/api/matches/{$matchId}")
            ->assertOk()
            ->assertJsonPath('match.your_seat', 'enemy');

        $stranger = User::factory()->create();
        $this->actingAs($stranger, 'sanctum')
            ->getJson("/api/matches/{$matchId}")
            ->assertForbidden();
    }

    public function test_decline_cancels_offer(): void
    {
        [$userA, $codesA] = $this->makeCommander('dec-a@example.com');
        [$userB, $codesB] = $this->makeCommander('dec-b@example.com');

        $this->actingAs($userA, 'sanctum')->postJson('/api/pvp/queue', ['card_codes' => $codesA]);
        $offerId = $this->actingAs($userB, 'sanctum')->postJson('/api/pvp/queue', [
            'card_codes' => $codesB,
        ])->json('offer.id');
        $this->assertNotNull($offerId);

        $this->actingAs($userB, 'sanctum')->postJson("/api/pvp/offers/{$offerId}/decline")
            ->assertOk()
            ->assertJsonPath('offer', null);
    }

    public function test_flag_disables_pvp(): void
    {
        config(['bcs.feature_flags.pvp' => false]);
        [$user] = $this->makeCommander('flag-pvp@example.com');
        $this->actingAs($user, 'sanctum')->postJson('/api/pvp/queue', [])
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FEATURE_DISABLED');
    }
}
