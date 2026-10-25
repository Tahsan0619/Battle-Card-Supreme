<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('game_modes', function (Blueprint $table) {
            $table->id();
            $table->string('code', 64)->unique();
            $table->string('title');
            $table->string('subtitle')->nullable();
            $table->boolean('is_available')->default(false);
            $table->unsignedSmallInteger('sort_order')->default(100);
            $table->timestamps();
        });

        Schema::create('mode_rule_versions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('game_mode_id')->constrained('game_modes')->cascadeOnDelete();
            $table->unsignedInteger('version');
            $table->json('rules_json');
            $table->boolean('is_current')->default(false);
            $table->timestamps();

            $table->unique(['game_mode_id', 'version']);
            $table->index(['game_mode_id', 'is_current']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mode_rule_versions');
        Schema::dropIfExists('game_modes');
    }
};
