<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('match_offers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_a_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('user_b_id')->constrained('users')->cascadeOnDelete();
            $table->json('cards_a');
            $table->json('cards_b');
            $table->string('status', 32)->default('pending');
            $table->boolean('accept_a')->default(false);
            $table->boolean('accept_b')->default(false);
            $table->timestamp('expires_at');
            $table->unsignedBigInteger('match_id')->nullable();
            $table->timestamps();

            $table->index(['status', 'expires_at']);
            $table->foreign('match_id')->references('id')->on('matches')->nullOnDelete();
        });

        Schema::create('matchmaking_queue', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->json('card_codes');
            $table->string('status', 32)->default('queued');
            $table->foreignId('offer_id')->nullable()->constrained('match_offers')->nullOnDelete();
            $table->timestamps();

            $table->index(['status', 'created_at']);
            $table->index(['user_id', 'status']);
        });

        Schema::table('matches', function (Blueprint $table) {
            $table->boolean('is_pvp')->default(false)->after('mode');
            $table->string('host_seat', 8)->default('player')->after('is_pvp');
            $table->foreignId('opponent_user_id')->nullable()->after('user_id')
                ->constrained('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('matches', function (Blueprint $table) {
            $table->dropConstrainedForeignId('opponent_user_id');
            $table->dropColumn(['is_pvp', 'host_seat']);
        });
        Schema::dropIfExists('matchmaking_queue');
        Schema::dropIfExists('match_offers');
    }
};
