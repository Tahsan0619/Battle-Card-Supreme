<?php

namespace Tests\Feature;

use Database\Seeders\CardDefinitionSeeder;
use Database\Seeders\GameModeSeeder;
use Database\Seeders\ProgressionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ShopSummonTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CardDefinitionSeeder::class);
        $this->seed(GameModeSeeder::class);
        $this->seed(ProgressionSeeder::class);
    }

    private function token(): string
    {
        return $this->postJson('/api/register', [
            'name' => 'Shopper',
            'email' => 'shop'.uniqid().'@example.com',
            'password' => 'Password1!',
            'password_confirmation' => 'Password1!',
        ])->json('token');
    }

    public function test_starter_is_limited_not_full_catalogue(): void
    {
        $token = $this->token();
        $count = $this->withToken($token)->getJson('/api/collection')->json('count');
        $this->assertSame(6, $count);
    }

    public function test_shop_catalogue_and_purchase_idempotent(): void
    {
        $token = $this->token();
        $cat = $this->withToken($token)->getJson('/api/shop');
        $cat->assertOk()->assertJsonStructure(['offers', 'daily', 'server_date_utc']);

        $before = $this->withToken($token)->getJson('/api/progress')->json('profile.aether');

        $buy = $this->withToken($token)->postJson('/api/shop/purchase', [
            'offer_code' => 'shard_pouch',
            'client_purchase_id' => 'buy-1',
        ]);
        $buy->assertCreated()
            ->assertJsonPath('offer_code', 'shard_pouch')
            ->assertJsonPath('idempotent_replay', false);

        $after = $this->withToken($token)->getJson('/api/progress')->json('profile');
        $this->assertSame($before - 80, $after['aether']);
        $this->assertSame(10, $after['void_shards']);

        $replay = $this->withToken($token)->postJson('/api/shop/purchase', [
            'offer_code' => 'shard_pouch',
            'client_purchase_id' => 'buy-1',
        ]);
        $replay->assertOk()->assertJsonPath('idempotent_replay', true);
        $this->assertSame(
            $after['aether'],
            $this->withToken($token)->getJson('/api/progress')->json('profile.aether')
        );
    }

    public function test_insufficient_currency_rejected(): void
    {
        $token = $this->token();
        // Drain aether via repeated shard pouches until near empty, then fail.
        $aether = $this->withToken($token)->getJson('/api/progress')->json('profile.aether');
        $i = 0;
        while ($aether >= 80 && $i < 20) {
            $this->withToken($token)->postJson('/api/shop/purchase', [
                'offer_code' => 'shard_pouch',
                'client_purchase_id' => "drain-{$i}",
            ]);
            $aether = $this->withToken($token)->getJson('/api/progress')->json('profile.aether');
            $i++;
        }

        $this->withToken($token)->postJson('/api/shop/purchase', [
            'offer_code' => 'shard_pouch',
            'client_purchase_id' => 'drain-fail',
        ])->assertStatus(422)->assertJsonPath('error.code', 'INSUFFICIENT_CURRENCY');
    }

    public function test_daily_claim_once_per_utc_day(): void
    {
        $token = $this->token();
        $first = $this->withToken($token)->postJson('/api/shop/daily', [
            'client_claim_id' => 'daily-1',
        ]);
        $first->assertCreated()->assertJsonPath('already_claimed', false);

        $second = $this->withToken($token)->postJson('/api/shop/daily', [
            'client_claim_id' => 'daily-2',
        ]);
        $second->assertOk()->assertJsonPath('already_claimed', true);
    }

    public function test_summon_discloses_odds_and_pulls_idempotent(): void
    {
        $token = $this->token();
        // Fund enough aether for a pull.
        \App\Models\PlayerProfile::query()
            ->where('user_id', $this->withToken($token)->getJson('/api/me')->json('user.id'))
            ->update(['aether' => 500]);

        $banners = $this->withToken($token)->getJson('/api/summon/banners');
        $banners->assertOk()
            ->assertJsonPath('banners.0.code', 'standard_rift')
            ->assertJsonPath('banners.0.probability_disclosure.total_bp', 10000);

        $pull = $this->withToken($token)->postJson('/api/summon/pull', [
            'banner_code' => 'standard_rift',
            'client_summon_id' => 'pull-1',
        ]);
        $pull->assertCreated()
            ->assertJsonStructure(['result' => ['card', 'rarity', 'was_duplicate'], 'rng', 'profile']);

        $replay = $this->withToken($token)->postJson('/api/summon/pull', [
            'banner_code' => 'standard_rift',
            'client_summon_id' => 'pull-1',
        ]);
        $replay->assertOk()->assertJsonPath('idempotent_replay', true);
        $this->assertSame(
            $pull->json('result.card.id'),
            $replay->json('result.card.id')
        );
    }

    public function test_flags_disable_shop(): void
    {
        config(['bcs.feature_flags.shop' => false]);
        $token = $this->token();
        $this->withToken($token)->getJson('/api/shop')
            ->assertForbidden()
            ->assertJsonPath('error.code', 'FEATURE_DISABLED');
    }
}
