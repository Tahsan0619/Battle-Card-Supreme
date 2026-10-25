<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('player_ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('season_code', 64);
            $table->unsignedInteger('rating')->default(1000);
            $table->unsignedInteger('wins')->default(0);
            $table->unsignedInteger('losses')->default(0);
            $table->unsignedInteger('draws')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'season_code']);
            $table->index(['season_code', 'rating']);
        });

        Schema::create('rating_ledger', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('season_code', 64);
            $table->foreignId('match_id')->constrained('matches')->cascadeOnDelete();
            $table->unsignedInteger('rating_before');
            $table->integer('rating_delta');
            $table->unsignedInteger('rating_after');
            $table->unsignedInteger('opponent_rating');
            $table->string('result', 16); // win|loss|draw
            $table->timestamps();

            $table->unique(['user_id', 'match_id']);
            $table->index(['season_code', 'created_at']);
        });

        Schema::table('matches', function (Blueprint $table) {
            $table->boolean('ranking_applied')->default(false)->after('is_pvp');
        });
    }

    public function down(): void
    {
        Schema::table('matches', function (Blueprint $table) {
            $table->dropColumn('ranking_applied');
        });
        Schema::dropIfExists('rating_ledger');
        Schema::dropIfExists('player_ratings');
    }
};
