# Architecture

## Client (Flutter)

```
lib/
  theme/          Design Prefer tokens
  domain/models/  Card, Team, Match snapshots
  domain/balance/ Stat budget divider
  domain/combat/  Pure combat engine + AI
  domain/data/    Seed roster JSON-like Dart
  state/          Riverpod notifiers
  ui/screens/     Design Prefer mapped screens
  ui/widgets/     Cards, meters, buttons
```

Combat engine has zero Flutter imports.

## Backend (later)

Laravel modular monolith, MySQL, server-authoritative match actions, idempotency keys, economy ledger. Not required for offline MVP.

## Boundaries

| Concern | Offline MVP | Online later |
|---------|-------------|--------------|
| Catalogue | Local seed | API + cache |
| Ownership | All seed owned | player_cards |
| Combat | Local engine | Same rules on server |
| Rewards | Local stub | Ledger + claim |  
