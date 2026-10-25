<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('player_profiles', function (Blueprint $table) {
            $table->unsignedBigInteger('rift_marks')->default(0)->after('void_shards');
            $table->unsignedInteger('key_iron')->default(0)->after('rift_marks');
            $table->unsignedInteger('key_silver')->default(0)->after('key_iron');
            $table->unsignedInteger('key_gold')->default(0)->after('key_silver');
        });

        Schema::table('player_cards', function (Blueprint $table) {
            $table->unsignedInteger('copies')->default(0)->after('level');
        });

        Schema::create('chest_opens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('chest_code', 64);
            $table->string('client_open_id', 120);
            $table->string('key_code', 16);
            $table->unsignedTinyInteger('keys_spent');
            $table->unsignedBigInteger('rng_seed');
            $table->json('results_json');
            $table->timestamps();

            $table->unique(['user_id', 'client_open_id']);
            $table->index(['user_id', 'chest_code']);
        });

        Schema::table('match_reward_claims', function (Blueprint $table) {
            $table->unsignedInteger('rift_marks_granted')->default(0)->after('aether_granted');
            $table->unsignedTinyInteger('iron_keys_granted')->default(0)->after('rift_marks_granted');
        });
    }

    public function down(): void
    {
        Schema::table('match_reward_claims', function (Blueprint $table) {
            $table->dropColumn(['rift_marks_granted', 'iron_keys_granted']);
        });
        Schema::dropIfExists('chest_opens');
        Schema::table('player_cards', function (Blueprint $table) {
            $table->dropColumn('copies');
        });
        Schema::table('player_profiles', function (Blueprint $table) {
            $table->dropColumn(['rift_marks', 'key_iron', 'key_silver', 'key_gold']);
        });
    }
};
