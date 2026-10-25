# Beta runbook

## Disable risky features
Set in `.env` then reload config:

```
BCS_FLAG_SHOP=false
BCS_FLAG_SUMMON=false
BCS_FLAG_PVP=false
BCS_FLAG_ONLINE_CLASH=false
BCS_FLAG_REWARDS=false
```

`php artisan config:clear`

## Health
- Liveness: `GET /up`
- Readiness: `GET /api/ready` (DB + schema)
- Client meta: `GET /api/meta` (`min_app_version`, flags)

## Rollback deploy
1. Redeploy previous API release artifact.  
2. Do not roll forward balance_version on matches already started.  
3. Keep MySQL restore point from before the bad deploy.

## Rotate secrets
1. Rotate `APP_KEY` only with a planned session wipe.  
2. Rotate DB password; update `.env`; restart PHP.  
3. Revoke Sanctum tokens if leak suspected: truncate `personal_access_tokens`.

## Restore DB
1. Stop writers (disable online_clash flag).  
2. Restore dump.  
3. Verify `economy_ledger` and `match_reward_claims` consistency before re-enabling rewards.

## Alerts to watch
- 429 / rate_limited spikes  
- `bcs.security` authz failures (IDOR)  
- Reward claim anomalies (many already_claimed from new keys)  
- `/api/ready` failures  
