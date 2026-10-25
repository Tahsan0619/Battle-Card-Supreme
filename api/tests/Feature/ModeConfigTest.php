<?php

namespace Tests\Feature;

use Database\Seeders\GameModeSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ModeConfigTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(GameModeSeeder::class);
    }

    public function test_modes_endpoint_lists_shared_config(): void
    {
        $res = $this->getJson('/api/modes');
        $res->assertOk()
            ->assertJsonStructure([
                'modes' => [
                    [
                        'code',
                        'title',
                        'subtitle',
                        'available',
                        'rule_version',
                        'rules',
                    ],
                ],
            ]);

        $codes = collect($res->json('modes'))->pluck('code');
        $this->assertTrue($codes->contains('classic_clash'));
        $this->assertTrue($codes->contains('survival_challenge'));

        $survival = collect($res->json('modes'))
            ->firstWhere('code', 'survival_challenge');
        $this->assertTrue($survival['available']);
        $this->assertSame(3, $survival['rules']['waves']);
        $this->assertSame(20, $survival['rules']['max_rounds']);
        $this->assertSame(25, $survival['rules']['heal_between_waves_percent']);
    }

    public function test_offline_only_mode_rejected_on_match_create(): void
    {
        $this->seed(\Database\Seeders\CardDefinitionSeeder::class);

        $token = $this->postJson('/api/register', [
            'name' => 'Mode Tester',
            'email' => 'mode@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $res = $this->withToken($token)->postJson('/api/matches', [
            'mode' => 'survival_challenge',
        ]);

        $res->assertStatus(422)
            ->assertJsonPath('error.code', 'MODE_OFFLINE_ONLY');
    }

    public function test_match_snapshots_mode_rules(): void
    {
        $this->seed(\Database\Seeders\CardDefinitionSeeder::class);

        $token = $this->postJson('/api/register', [
            'name' => 'Snap Tester',
            'email' => 'snap@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');

        $create = $this->withToken($token)->postJson('/api/matches', [
            'mode' => 'online_clash',
        ]);

        $create->assertCreated()
            ->assertJsonPath('match.mode', 'online_clash')
            ->assertJsonPath('match.mode_rule_version', 1)
            ->assertJsonPath('match.mode_rules.max_rounds', 30);
    }
}
