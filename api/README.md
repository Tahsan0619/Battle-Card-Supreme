# Battle Card Supreme API

Laravel 12 + Sanctum modular monolith for Phase 3.

## Setup

```bash
cd api
cp .env.example .env   # if needed
php artisan key:generate
# SQLite is default in .env for local/dev
touch database/database.sqlite
php artisan migrate --seed
php artisan serve
```

## Endpoints

| Method | Path | Auth |
|--------|------|------|
| POST | `/api/register` | no |
| POST | `/api/login` | no |
| POST | `/api/logout` | yes |
| GET | `/api/me` | yes |
| GET | `/api/cards` | no |
| GET | `/api/cards/{id}` | no |
| GET | `/api/collection` | yes |
| GET | `/api/teams` | yes |
| POST | `/api/teams` | yes |
| PUT | `/api/teams/{team}` | yes |
| POST | `/api/matches` | yes |
| GET | `/api/matches/{id}` | yes |
| GET | `/api/matches/{id}/history` | yes |
| POST | `/api/matches/{id}/actions` | yes |

Combat is server-authoritative. Clients send intents with `client_action_id` + `state_version`. Enemy AI drains on the server.

Error envelope matches Master_Prompt section O.

## Tests

```bash
php artisan test
```

## Roster sync

```bash
python ../scripts/export_roster_json.py
php artisan db:seed --class=CardDefinitionSeeder
```
