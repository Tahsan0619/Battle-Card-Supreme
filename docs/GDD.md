# Battle Card Supreme - Product Specification (GDD)

**Status:** Phase 2 offline MVP freeze  
**World:** Aetherium Rift  
**Source:** Master_Prompt.md  

## Core loop

Acquire cards, understand kits, build a team (up to 8, MVP uses 3 for faster battles), fight Classic Card Clash vs AI, view results, return to collection.

## MVP scope (offline)

- Catalogue of original sample cards (foundation set: 50, spanning all 8 rarities)
- Collection browse + card detail
- Team builder with validation
- Turn-based combat engine (pure Dart)
- Basic AI opponent
- Victory / defeat results
- Design Prefer visual language

## Postponed

Online auth, server combat, PvP matchmaking, shop, summon, guild, ranking seasons, real-money packs.

## Combat rules (MVP)

1. Each side fields 3 living units from a saved team (pad with catalogue if short).  
2. Turn order: sort living units by SPD descending, then stable id.  
3. On a unit turn: basic attack OR active ability if EN cost met and not on cooldown.  
4. Damage: `max(1, ATK * mult / 100 - DEF * 50 / 100)` using integer math only.  
5. Shields absorb before HP.  
6. Unit at HP <= 0 is defeated.  
7. Win: all enemies defeated. Loss: all allies defeated. Turn cap: 30 full rounds then draw.  
8. RNG: seeded `Random` for AI choice only in MVP (damage is deterministic).

## Rarity and stats

Budgets and role splits follow Master_Prompt section G. Compliance checked in unit tests.

## Modes

MVP: Classic Card Clash only.  
