<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('card_definitions', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('pitch');
            $table->text('lore');
            $table->string('rarity', 32);
            $table->string('role', 32);
            $table->string('faction', 64);
            $table->unsignedInteger('hp');
            $table->unsignedInteger('atk');
            $table->unsignedInteger('def');
            $table->unsignedInteger('spd');
            $table->unsignedInteger('en');
            $table->string('passive_name');
            $table->text('passive_description');
            $table->string('ability_id');
            $table->string('ability_name');
            $table->text('ability_description');
            $table->unsignedTinyInteger('ability_en_cost');
            $table->unsignedTinyInteger('ability_cooldown');
            $table->unsignedSmallInteger('ability_multiplier');
            $table->unsignedTinyInteger('ability_heal_percent')->default(0);
            $table->unsignedTinyInteger('ability_shield_percent')->default(0);
            $table->boolean('ability_is_aoe')->default(false);
            $table->json('synergy_tags')->nullable();
            $table->unsignedInteger('art_seed')->default(0);
            $table->unsignedInteger('balance_version')->default(1);
            $table->unsignedInteger('card_version')->default(1);
            $table->boolean('is_published')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('card_definitions');
    }
};
