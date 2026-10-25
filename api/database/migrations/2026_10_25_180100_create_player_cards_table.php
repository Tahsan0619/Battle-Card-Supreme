<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('player_cards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('card_definition_id')->constrained('card_definitions')->cascadeOnDelete();
            $table->unsignedSmallInteger('level')->default(1);
            $table->timestamps();

            $table->unique(['user_id', 'card_definition_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('player_cards');
    }
};
