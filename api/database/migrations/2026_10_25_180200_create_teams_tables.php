<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('teams', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name')->default('Main Squad');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('team_slots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('slot_index');
            $table->foreignId('card_definition_id')->constrained('card_definitions')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['team_id', 'slot_index']);
            $table->unique(['team_id', 'card_definition_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('team_slots');
        Schema::dropIfExists('teams');
    }
};
