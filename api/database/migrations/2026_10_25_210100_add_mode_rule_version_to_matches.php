<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('matches', function (Blueprint $table) {
            $table->unsignedInteger('mode_rule_version')->default(1)->after('mode');
            $table->json('mode_rules_snapshot')->nullable()->after('mode_rule_version');
        });
    }

    public function down(): void
    {
        Schema::table('matches', function (Blueprint $table) {
            $table->dropColumn(['mode_rule_version', 'mode_rules_snapshot']);
        });
    }
};
