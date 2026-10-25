<?php

namespace App\Support;

use App\Models\PlayerProfile;
use Carbon\Carbon;

final class ProgressService
{
    public function ensureProfile(int $userId): PlayerProfile
    {
        return PlayerProfile::firstOrCreate(
            ['user_id' => $userId],
            [
                'level' => 1,
                'xp' => 0,
                'aether' => 500,
                'void_shards' => 0,
                'energy' => 30,
                'energy_max' => 30,
                'energy_updated_at' => Carbon::now(),
                'balance_version_seen' => 1,
            ]
        );
    }

    /**
     * Server-clock energy regen: 1 energy per 5 minutes, capped at energy_max.
     */
    public function refreshEnergy(PlayerProfile $profile): PlayerProfile
    {
        $now = Carbon::now();
        $updated = $profile->energy_updated_at ?? $now;
        $elapsedMinutes = $updated->diffInMinutes($now);
        if ($elapsedMinutes <= 0) {
            return $profile;
        }

        $gain = intdiv((int) $elapsedMinutes, 5);
        if ($gain <= 0) {
            return $profile;
        }

        $energy = min(
            (int) $profile->energy_max,
            (int) $profile->energy + $gain
        );
        $profile->energy = $energy;
        $profile->energy_updated_at = $now;
        $profile->save();

        return $profile->fresh();
    }

    public function grantXp(PlayerProfile $profile, int $xp): PlayerProfile
    {
        if ($xp <= 0) {
            return $profile;
        }

        $level = (int) $profile->level;
        $currentXp = (int) $profile->xp + $xp;
        if ($currentXp > PlayerProfile::XP_MAX) {
            $currentXp = PlayerProfile::XP_MAX;
        }

        while ($level < PlayerProfile::LEVEL_MAX) {
            $need = PlayerProfile::xpToNextLevel($level);
            if ($currentXp < $need) {
                break;
            }
            $currentXp -= $need;
            $level += 1;
        }

        if ($level >= PlayerProfile::LEVEL_MAX) {
            $currentXp = 0;
            $level = PlayerProfile::LEVEL_MAX;
        }

        $profile->level = $level;
        $profile->xp = $currentXp;
        $profile->save();

        return $profile->fresh();
    }
}
