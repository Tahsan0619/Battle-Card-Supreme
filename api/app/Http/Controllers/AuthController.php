<?php

namespace App\Http\Controllers;

use App\Models\CardDefinition;
use App\Models\PlayerCard;
use App\Models\Team;
use App\Models\TeamSlot;
use App\Models\User;
use App\Support\ApiError;
use App\Support\ProgressService;
use App\Support\RankingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function __construct(
        private ProgressService $progress,
        private RankingService $ranking,
    ) {}

    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:40'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        $user = DB::transaction(function () use ($data) {
            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => $data['password'],
            ]);

            $this->progress->ensureProfile($user->id);
            $this->ranking->ensure($user);
            $this->grantStarterCollection($user);

            return $user;
        });

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => $this->userPayload($user),
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            return ApiError::make(
                'AUTH_INVALID_CREDENTIALS',
                'Invalid email or password.',
                401,
            );
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => $this->userPayload($user),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['ok' => true]);
    }

    public function me(Request $request)
    {
        $user = $request->user();
        $profile = $this->progress->ensureProfile($user->id);
        $profile = $this->progress->refreshEnergy($profile);

        return response()->json([
            'user' => $this->userPayload($user),
            'profile' => $profile->toApiArray(),
        ]);
    }

    private function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'is_admin' => (bool) $user->is_admin,
        ];
    }

    private function grantStarterCollection(User $user): void
    {
        // Tiny starter: progression through chests/keys/rewards.
        $count = (int) config('chests.starter_card_count', 3);
        $starter = CardDefinition::query()
            ->where('is_published', true)
            ->where('rarity', 'common')
            ->orderBy('id')
            ->limit($count)
            ->get();

        foreach ($starter as $card) {
            PlayerCard::create([
                'user_id' => $user->id,
                'card_definition_id' => $card->id,
                'level' => 1,
                'copies' => 0,
            ]);
        }

        $profile = $this->progress->ensureProfile($user->id);
        $profile->rift_marks = (int) $profile->rift_marks + 120;
        $profile->key_iron = (int) $profile->key_iron + 3;
        $profile->save();

        $team = Team::create([
            'user_id' => $user->id,
            'name' => 'Main Squad',
            'is_active' => true,
        ]);

        foreach ($starter->take(3)->values() as $index => $card) {
            TeamSlot::create([
                'team_id' => $team->id,
                'slot_index' => $index,
                'card_definition_id' => $card->id,
            ]);
        }
    }
}
