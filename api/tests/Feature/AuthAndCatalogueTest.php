<?php

namespace Tests\Feature;

use App\Models\CardDefinition;
use App\Models\User;
use Database\Seeders\CardDefinitionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthAndCatalogueTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CardDefinitionSeeder::class);
    }

    public function test_catalogue_lists_fifty_published_cards(): void
    {
        $response = $this->getJson('/api/cards');

        $response->assertOk()
            ->assertJsonPath('count', 50);
        $this->assertCount(50, CardDefinition::all());
    }

    public function test_register_login_me_and_collection(): void
    {
        $register = $this->postJson('/api/register', [
            'name' => 'Commander Rhea',
            'email' => 'rhea@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ]);

        $register->assertCreated()
            ->assertJsonStructure(['token', 'user' => ['id', 'email']]);

        $token = $register->json('token');

        $me = $this->withToken($token)->getJson('/api/me');
        $me->assertOk()->assertJsonPath('user.email', 'rhea@example.com');

        $collection = $this->withToken($token)->getJson('/api/collection');
        $collection->assertOk();
        $this->assertGreaterThanOrEqual(3, $collection->json('count'));

        $teams = $this->withToken($token)->getJson('/api/teams');
        $teams->assertOk();
        $this->assertNotEmpty($teams->json('teams'));
    }

    public function test_login_rejects_bad_password(): void
    {
        User::factory()->create([
            'email' => 'locked@example.com',
            'password' => 'Password1!',
        ]);

        $this->postJson('/api/login', [
            'email' => 'locked@example.com',
            'password' => 'wrong-password',
        ])->assertUnauthorized()
            ->assertJsonPath('error.code', 'AUTH_INVALID_CREDENTIALS');
    }

    public function test_team_update_rejects_unowned_card(): void
    {
        $register = $this->postJson('/api/register', [
            'name' => 'Commander Kai',
            'email' => 'kai@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->assertCreated();

        $token = $register->json('token');
        $userId = $register->json('user.id');
        $teamId = $this->withToken($token)->getJson('/api/teams')->json('teams.0.id');

        $target = CardDefinition::query()->orderByDesc('id')->firstOrFail();
        \App\Models\PlayerCard::query()
            ->where('user_id', $userId)
            ->where('card_definition_id', $target->id)
            ->delete();

        $owned = \App\Models\PlayerCard::query()
            ->where('user_id', $userId)
            ->with('cardDefinition')
            ->limit(2)
            ->get()
            ->map(fn ($pc) => $pc->cardDefinition->code)
            ->all();

        $this->withToken($token)->putJson("/api/teams/{$teamId}", [
            'card_codes' => [...$owned, $target->code],
        ])->assertStatus(422)
            ->assertJsonPath('error.code', 'CARD_NOT_OWNED');
    }

    public function test_card_show_by_code(): void
    {
        $this->getJson('/api/cards/sr_astra_veyron')
            ->assertOk()
            ->assertJsonPath('card.name', 'Astra Veyron');
    }
}
