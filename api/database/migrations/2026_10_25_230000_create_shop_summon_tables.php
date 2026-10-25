<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shop_purchases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('offer_code', 64);
            $table->string('client_purchase_id', 80);
            $table->string('cost_currency', 32);
            $table->unsignedInteger('cost_amount');
            $table->json('grant_json');
            $table->timestamps();

            $table->unique(['user_id', 'client_purchase_id']);
        });

        Schema::create('summon_rolls', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('banner_code', 64);
            $table->string('client_summon_id', 80);
            $table->unsignedBigInteger('rng_seed');
            $table->unsignedInteger('rng_draw');
            $table->string('result_rarity', 32);
            $table->string('result_card_code', 64);
            $table->boolean('was_duplicate')->default(false);
            $table->unsignedInteger('shards_granted')->default(0);
            $table->string('cost_currency', 32);
            $table->unsignedInteger('cost_amount');
            $table->timestamps();

            $table->unique(['user_id', 'client_summon_id']);
        });

        Schema::create('daily_claims', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('claim_date');
            $table->unsignedInteger('aether_granted')->default(0);
            $table->unsignedInteger('void_shards_granted')->default(0);
            $table->string('client_claim_id', 80);
            $table->timestamps();

            $table->unique(['user_id', 'claim_date']);
            $table->unique(['user_id', 'client_claim_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_claims');
        Schema::dropIfExists('summon_rolls');
        Schema::dropIfExists('shop_purchases');
    }
};
