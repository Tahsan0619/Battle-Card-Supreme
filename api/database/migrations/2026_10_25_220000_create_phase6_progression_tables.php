<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('is_admin')->default(false)->after('password');
        });

        Schema::create('balance_versions', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('version')->unique();
            $table->string('notes')->nullable();
            $table->boolean('is_current')->default(false);
            $table->timestamps();
        });

        Schema::create('player_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedInteger('level')->default(1);
            $table->unsignedBigInteger('xp')->default(0);
            $table->unsignedBigInteger('aether')->default(0);
            $table->unsignedBigInteger('void_shards')->default(0);
            $table->unsignedSmallInteger('energy')->default(30);
            $table->unsignedSmallInteger('energy_max')->default(30);
            $table->timestamp('energy_updated_at')->nullable();
            $table->unsignedInteger('balance_version_seen')->default(1);
            $table->timestamps();
        });

        Schema::create('economy_ledger', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('currency_code', 32);
            $table->bigInteger('delta');
            $table->unsignedBigInteger('balance_after');
            $table->string('reason_code', 64);
            $table->string('reference_type', 64)->nullable();
            $table->string('reference_id', 64)->nullable();
            $table->string('request_id', 80)->nullable();
            $table->timestamps();

            $table->index(['user_id', 'currency_code']);
            $table->index(['reference_type', 'reference_id']);
        });

        Schema::create('idempotency_keys', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('scope', 64);
            $table->string('key', 80);
            $table->json('response_json')->nullable();
            $table->unsignedSmallInteger('status_code')->default(200);
            $table->timestamps();

            $table->unique(['user_id', 'scope', 'key']);
        });

        Schema::create('match_reward_claims', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('match_id')->constrained('matches')->cascadeOnDelete();
            $table->string('reward_code', 64)->default('victory_pack');
            $table->unsignedInteger('xp_granted')->default(0);
            $table->unsignedInteger('aether_granted')->default(0);
            $table->string('client_claim_id', 80);
            $table->timestamps();

            $table->unique(['match_id', 'reward_code']);
            $table->unique(['user_id', 'client_claim_id']);
        });

        Schema::create('art_assets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('card_definition_id')->constrained()->cascadeOnDelete();
            $table->string('status', 32)->default('placeholder');
            $table->string('tool')->nullable();
            $table->date('generated_on')->nullable();
            $table->string('license_notes')->nullable();
            $table->string('asset_path')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->index(['card_definition_id', 'status']);
        });

        Schema::create('admin_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('action', 64);
            $table->string('target_type', 64)->nullable();
            $table->string('target_id', 64)->nullable();
            $table->json('meta_json')->nullable();
            $table->timestamps();
        });

        Schema::table('matches', function (Blueprint $table) {
            $table->unsignedInteger('balance_version')->default(1)->after('mode_rules_snapshot');
        });

        Schema::table('card_definitions', function (Blueprint $table) {
            $table->string('art_status', 32)->default('placeholder')->after('art_seed');
        });
    }

    public function down(): void
    {
        Schema::table('card_definitions', function (Blueprint $table) {
            $table->dropColumn('art_status');
        });
        Schema::table('matches', function (Blueprint $table) {
            $table->dropColumn('balance_version');
        });
        Schema::dropIfExists('admin_audit_logs');
        Schema::dropIfExists('art_assets');
        Schema::dropIfExists('match_reward_claims');
        Schema::dropIfExists('idempotency_keys');
        Schema::dropIfExists('economy_ledger');
        Schema::dropIfExists('player_profiles');
        Schema::dropIfExists('balance_versions');
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('is_admin');
        });
    }
};
