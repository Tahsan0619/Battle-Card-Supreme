<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('matches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('mode', 64)->default('classic_clash');
            $table->string('outcome', 32)->default('ongoing');
            $table->unsignedInteger('state_version')->default(0);
            $table->json('state_json');
            $table->json('player_snapshot');
            $table->json('enemy_snapshot');
            $table->unsignedSmallInteger('max_rounds')->default(30);
            $table->unsignedInteger('rng_seed')->default(7);
            $table->timestamps();

            $table->index(['user_id', 'outcome']);
        });

        Schema::create('match_actions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('match_id')->constrained('matches')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('client_action_id');
            $table->unsignedInteger('state_version_before');
            $table->unsignedInteger('state_version_after');
            $table->json('action_json');
            $table->json('events_json')->nullable();
            $table->timestamps();

            $table->unique(['match_id', 'client_action_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_actions');
        Schema::dropIfExists('matches');
    }
};
