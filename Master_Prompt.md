# MASTER PROJECT PROMPT: BATTLE CARD SUPREME

**Document status:** PRODUCTION SPEC (BUILD AUTHORIZED 2026-10-25)  
**Product name:** Battle Card Supreme  
**World / setting brand:** Aetherium Rift  
**Genre:** Original anime-inspired 2D collectible card battle game  
**Stack (default):** Flutter client, Laravel API, MySQL, Ubuntu VPS  
**Design system source of truth:** `Design Prefer/` (mandatory)  
**Typography:** Space Grotesk (display / tactical / numeric), Plus Jakarta Sans (body / micro)  

---

## A. DOCUMENT CONTROL AND HARD RULES

### A.1 Purpose

This file is the single source of truth for ideology, content, rarity economy, card creation, architecture, security, sessions, UI contracts, error handling, tests, and delivery gates.  
If code, comments, tickets, or chat contradict this file, **this file wins** until the user explicitly amends it.

### A.2 Build freeze (critical)

1. **Do not start building the application** until the user explicitly says to start building.  
2. Updating this prompt is allowed. Scaffolding, coding, generating the Flutter/Laravel trees, or creating cards in code is **forbidden** until that explicit start command.  
3. After the user says start, implement only against this prompt and the `Design Prefer/` references.

### A.3 Writing and punctuation rule (critical)

1. **No em dashes** (the Unicode character U+2014) anywhere in this project: this prompt, UI copy, lore, commit messages, comments, error strings, or generated docs.  
2. Prefer commas, periods, colons, parentheses, or a spaced hyphen ` - ` when a break is needed.  
3. Also avoid en dashes (U+2013) in player-facing copy. Use `to` for ranges (example: `360 to 430px`).  
4. Every edit pass must grep for `\u2014` and `\u2013` and remove them before claiming the prompt is ready.

### A.4 Accuracy mandate

1. No silent assumptions about money, drops, combat outcomes, ownership, or sessions.  
2. Every interactive control must define: enabled rules, press behavior, double-press behavior, failure states, and recovery.  
3. Every API must define success, validation failure, auth failure, conflict, rate limit, and server error shapes.  
4. Every match must define reconnect, timeout, concede, desync, and abandoned-match outcomes.  
5. Security is not a section to skim. Threats, mitigations, and tests are mandatory for online features.

### A.5 Multi-lens review gate (required before BUILD)

Before the user may be told "prompt is ready," the authoring agent must re-read this document while role-playing **all** of the following and fix gaps found:

| Lens | What they attack |
|------|------------------|
| Staff engineer | Ambiguous requirements, missing states, unclear ownership of logic |
| Security engineer | Auth, authz, injection, replay, economy fraud, admin abuse, secret leakage |
| Game designer | Rarity power creep, dead commons, unreadable combat, mode bloat |
| Flutter / mobile engineer | Lifecycle, offline, permissions, memory, touch targets, Design Prefer fidelity |
| Laravel / backend engineer | Transactions, idempotency, migrations, queues, API contracts |
| QA / test engineer | Missing negative tests, flaky paths, untested races |
| Systems / C++ expert mindset | Determinism, undefined behavior analogues, integer overflow, state machine completeness, memory/resource lifetime, concurrency races treated like UB |
| Product / ops | Deploy, rollback, backups, supportability, Bangladesh-realistic hosting |
| Adversarial player | Button spam, alt accounts, packet rewrite, shop double-claim, match leave abuse |

Only after that pass may the document claim **PRODUCTION READY**.

### A.6 Change protocol

1. Any material change updates the Document status line and a short changelog at the bottom.  
2. Balance numbers, rarity budgets, and API error codes are versioned.  
3. Do not delete security or test sections to "shorten" the prompt.

---

## B. HOW THE AGENT MUST WORK

### B.1 Roles

Act as senior game designer, software architect, Flutter developer, Laravel backend engineer, database designer, balance specialist, security engineer, QA lead, and DevOps advisor.

### B.2 Working rules

1. Analyze, decide, document, then implement. Never dump an entire unfinished app.  
2. Be practical and explicit about trade-offs.  
3. Ask only essential clarifying questions. If a default is reasonable, state it and continue.  
4. Inspect existing files before overwrite. Do not assume the repo is initialized.  
5. Prefer configuration and data over hard-coded content. New cards must not require rewriting core combat.  
6. Never invent package APIs or claim untested code ran.  
7. Never put secrets in source control.  
8. Prefer modular monolith. No Kubernetes, microservices, blockchain, NFTs, or crypto unless the user explicitly requests them later.  
9. Client never authoritatively decides damage, rewards, ownership, currency, victory, or ranking.

### B.3 Delivery order (after BUILD is authorized)

1. Product specification derived from this prompt (GDD freeze).  
2. Architecture (Flutter, Laravel, schema, API, combat boundaries, hosting, security).  
3. Technical decisions with trade-offs.  
4. Implementation roadmap with tests per milestone.  
5. Offline playable prototype first.  
6. Backend, online, modes, progression, beta: phase by phase.

---

## C. CORE IDEOLOGY

### C.1 Pitch

Battle Card Supreme is a tactical collectible card battle game where players assemble original Aetherium Rift warriors into teams, then reuse those same teams across multiple combat modes: classic clash, raids, drafts, survival, and more.

### C.2 Player fantasy

Players are **Rift Commanders**: collectors and tacticians who recruit original heroes, shape synergies, and prove mastery through readable turn-based battles, not through pay-to-win raw power.

### C.3 Non-negotiable pillars

| Pillar | Meaning |
|--------|---------|
| Original IP first | Anime-inspired style only. Never copy characters, outfits, logos, or lore from existing franchises. |
| Tactics over rarity | Higher rarity grants budget and identity depth, not automatic wins. |
| One roster, many modes | One collection, one team builder, one combat engine. Modes change rules. |
| Stats are divided | Combat numbers come from a rarity budget split by role and identity. |
| Art is generated | Portraits and frames come from a generate-then-curate pipeline. Never scraped copyright art. |
| Design Prefer binding | UI, color, type, spacing, and screen inventory follow `Design Prefer/`. |
| Easy to learn, hard to master | Clear roles; deep synergies and counters. |
| Server-authoritative online | Clients propose intents. Server validates and resolves. |
| Session-safe UX | Every button and every session edge case has a defined outcome. |
| Tested before "done" | Features ship with automated tests for happy path and failure path. |
| Modest start, real scale | Offline first. Scale hosting with real usage. |

### C.4 What this game is not

- Not a clone of any single anime or CCG.  
- Not a 3D fighter or open-world anime simulator.  
- Not a game where Mythic or Supreme cards trivialize Common or Uncommon teams by raw stats alone.  
- Not a system that trusts the client for competitive outcomes.  
- Not a prompt that allows implementation before the user says BUILD.

### C.5 Core loop

1. Acquire original character cards (rewards, progression, summoning, events).  
2. Understand role, rarity, abilities, synergies.  
3. Build validated teams (mode-configurable size; default up to 8).  
4. Battle using the shared turn-based combat engine.  
5. Progress via upgrades, unlocks, ranking, and new modes without replacing the roster model.

---

## D. WORLD AND IP

### D.1 Aetherium Rift

Original science-fantasy / anime-aesthetic setting where **Aetherium** (living rift-energy) fractures realities and births warriors, guardians, and anomalies.

Use it to name factions, regions, and card series. Support expansions as new Rift strata.

Do not paste real anime plots with renamed cities. Do not use trademarked terms or franchise-coded signature kits.

Illustrative only (not roster locks): Astra Veyron, Kairo Ren, Lyra Stormveil. Final roster must be at least **50** unique originals.

### D.2 IP rules

- Never thinly rename existing anime characters.  
- Never reproduce recognizable copyrighted designs, outfits, weapons, symbols, or backstories.  
- Do not recreate recognizable name + power + personality + appearance combos from known franchises.  
- No copyrighted logos, official art, screenshots, or ripped assets.  
- Anime influence means broad style only.  
- Create original factions, terminology, frames, logos, icons, branding.  
- AI art: record tool, date, license terms. Do not assume commercial rights.  
- Placeholders allowed early so systems are not blocked by final art.

---

## E. DESIGN PREFER BINDING (INTERFACE LEVEL)

### E.1 Mandatory sources

| Path | Role |
|------|------|
| `Design Prefer/aetherium_rift/DESIGN.md` | Design system: colors, type, spacing, elevation, components |
| `Design Prefer/Logo/` | Emblem / brand mark reference |
| Each `Design Prefer/<screen>/code.html` + `screen.png` | Screen layout, hierarchy, copy patterns, interaction density |

### E.2 Screen inventory (must be accounted for in product scope)

| Folder | Product surface | MVP priority |
|--------|-----------------|--------------|
| `home_dashboard` | Home, currencies, featured card, Enter Combat, events | MVP |
| `card_collection` | Collection grid, filters, search | MVP |
| `card_details_astra_veyron` | Card detail, stats, abilities, lore | MVP |
| `tactical_team_builder` | Team slots, validation, synergy readout | MVP |
| `battle_mode_selection` | Mode picker | MVP (subset) |
| `battle_preparation` | Pre-match confirm, team check | MVP |
| `live_tactical_duel` | Battle HUD, turns, log, speed, auto, concede | MVP |
| `battle_victory_rewards` | Victory rewards claim | MVP |
| `battle_defeat_tactical_debrief` | Defeat debrief, retry paths | MVP |
| `pvp_matchmaking_duel_found` | Match found / accept flow | Post-offline |
| `player_profile_progression` | Profile and progression | Soft MVP |
| `player_profile_with_settings_modal` | Settings modal | Soft MVP |
| `shop_astral_exchange` | Shop / exchange | Later (still specify economy safety) |
| `void_summoning_nexus` | Summoning / gacha-like acquire | Later (probability disclosure required) |
| `guild_alliance_nexus` | Guild / alliance | Later |

Implementation may stage features, but the **interaction and error contracts** for deferred screens must still be specified before those screens ship. Do not invent a conflicting visual language.

### E.3 Visual pillars (from DESIGN.md)

- Abyssal luminosity: near-black surfaces, luminous strokes, colored energy accents.  
- Runetech artifice: chamfers, hairline frames, geometric sigils.  
- Combat telemetry: thumb-zone actions, 48dp minimum primary hit targets, chromatic feedback.  
- Tiered splendor: Common matte and quiet; higher rarities gain foil, gold, violet aura intensity without destroying readability.

### E.4 Token lock (Flutter theme must map these)

**Surfaces (Material tokens in HTML mocks):**  
`#10131c` surface, `#0b0e17` lowest, `#181b25` low, `#1c1f29` container, `#272a34` high, `#32343f` highest.

**Brand accents:** primary `#d0bcff` / containers around `#a078ff`, secondary cyan `#4cd7f6`, tertiary gold `#ffb95f`, error `#ffb4ab`.

**Combat semantics (DESIGN.md narrative accents, map into theme extensions):**  
HP crimson, shield cyan, energy/AP blue, positive emerald, premium gold.

**Type:** Space Grotesk for hero/headline/tactical/numeric. Plus Jakarta Sans for body and micro labels.

**Radius / spacing:** follow DESIGN.md and the Tailwind tokens embedded in `code.html` files. Prefer tonal stacking and hairline illumination over soft muddy shadows.

**Cards:** aspect ~1:1.45; AP orb; rarity seal; rules text plate; ATK/DEF footer chips.

### E.5 UI fidelity rules

1. Prefer matching `Design Prefer` structure over generic Material defaults.  
2. Safe areas: `pt-safe` / `pb-safe` equivalents for notches and gesture bars.  
3. No horizontal scrollbar chrome; hide system scrollbars as in mocks where appropriate.  
4. `active:scale` style press feedback on primary controls.  
5. Disabled controls must look disabled and must not fire actions.  
6. Loading, empty, offline, error, partial-data, and permission-denied states are required for every data screen.  
7. Do not place unbounded particle spam that hides HP, turn, or legal targets.

---

## F. RARITY SYSTEM (EIGHT ASCENSION TIERS)

### F.1 Tiers (low to high)

| Order | Rarity | Code | Meaning |
|------:|--------|------|---------|
| 1 | Common | C | Foundation. High availability. Clear single job. |
| 2 | Uncommon | UC | Reliable specialists. Slightly richer kit. |
| 3 | Rare | R | Distinct identity. Strong role expression. |
| 4 | Super Rare | SR | Signature mechanics. Meta presence. |
| 5 | Epic | E | High impact. Tight balance. |
| 6 | Legendary | L | Franchise-defining. Still counterable. |
| 7 | Mythic | M | Near-apex. Spectacular. Hard constraints. |
| 8 | Supreme | S | Apex of Battle Card Supreme. Ultra scarce. Unique hooks. Never "win by existing." |

All eight exist in data, UI frames, filters, drops, and the 50-card plan. No empty tier in the master plan.

**Design Prefer label mapping:** some HTML mocks show seals like `SSR`. In product data and player-facing rarity names, use the eight names above. Map legacy mock shorthand as: `SSR` means **Super Rare** unless a specific mock clearly denotes Legendary or higher via gold filigree treatment. Do not invent a ninth rarity called SSR.

### F.2 What rarity may and must not do

**May increase:** total stat budget, kit depth, frame prestige, VFX, acquisition difficulty, synergy density.  

**Must not alone guarantee:** max HP and ATK and DEF and SPD together, uncounterable hard CC every turn, immunity that ignores rules, mandatory inclusion in every competitive team.

**Doctrine:** skilled Common/Uncommon play can beat poorly played Legendary/Mythic/Supreme lines.

---

## G. STAT IDEOLOGY: DIVIDE, DO NOT INFLATE

### G.1 Principle

For card stats, **divide**. Each card gets a rarity-scaled **total budget**. Split across attributes by primary role, secondary tags, and identity. Higher rarity grows the pie. It does not max every slice.

### G.2 Baseline attributes

Required: HP, ATK, DEF, SPD, EN (energy or resource economy; exact rules locked in combat GDD).  

Optional only if justified and documented: crit, resistance, penetration, shield bias, accuracy, evasion.

### G.3 Budget ladder (playtest seeds; store in versioned config)

| Rarity | Relative budget |
|--------|-----------------|
| Common | 100% |
| Uncommon | 108% |
| Rare | 118% |
| Super Rare | 128% |
| Epic | 140% |
| Legendary | 155% |
| Mythic | 170% |
| Supreme | 185% |

Also define: role weight templates, identity bias limits, per-stat soft caps, automated budget compliance tests. Final integers live in balance config with `balance_version`.

### G.4 Roles (data-driven, expandable)

1. Tank  
2. Attacker / DPS  
3. Support / Healer  
4. Assassin  
5. Mage / Controller  
6. Strategist / Tactician  
7. Skirmisher / Speedster  
8. Summoner / Specialist  

Primary role required. Secondary tags optional. Do not hard-code the whole game to exactly eight forever.

### G.5 Ability power vs stat power

Transformative kits may trade raw ATK for ability impact. Document per card in design review.

### G.6 Snapshot rule

Match start freezes card stats, ability versions, mode rules, and `balance_version`. Live patches must not mutate an in-progress match.

---

## H. ART IDEOLOGY: GENERATE, THEN CURATE

1. Brief (name, role, rarity, silhouette, faction, colors, pose, original props).  
2. Generate candidates (approved AI workflow or human art).  
3. Curate: reject franchise lookalikes; enforce silhouette uniqueness.  
4. Compose into rarity frame; thumbnail-readable face/weapon.  
5. Optimize variants: thumb, detail, battle.  
6. Store on object storage or CDN. DB holds paths, hashes, license notes.  
7. Admin publish flag. Clients fetch catalogue without shipping a new binary per card.

Never scrape copyrighted anime stills. Placeholders allowed for early milestones.

---

## I. ROSTER MANDATE: MINIMUM 50 CHARACTERS

### I.1 Hard requirement

At least **50** unique original characters across **all eight rarities**. Supreme may be few, but planned identities must exist.

### I.2 Foundation pyramid (50)

| Rarity | Count |
|--------|------:|
| Common | 12 |
| Uncommon | 10 |
| Rare | 8 |
| Super Rare | 6 |
| Epic | 5 |
| Legendary | 4 |
| Mythic | 3 |
| Supreme | 2 |
| **Total** | **50** |

### I.3 Coverage rules

- Every primary role appears at least twice in Common to Rare.  
- No single role owns all Legendary+.  
- Assassin and Controller tools exist below Epic.  
- At least one Support with heal or cleanse at Uncommon or lower.  
- 4 to 6 original factions spanning multiple rarities.

### I.4 Per-card checklist

Unique ID, original name, pitch, lore, art refs, rarity, role, tags, faction, synergy tags, divided stats, passive/active/ultimate as applicable, cooldowns or EN costs, unlock notes, upgrade hooks, `card_version`, `balance_version`.

### I.5 Entity model

1. Character: permanent world identity.  
2. Card definition: playable versioned rules + art + stats.  
3. Player card: ownership / level / progression.  
4. Team: saved lineup.  
5. Match snapshot: frozen rules and combat stats for one match.

Decide skins/variants before schema lock. Explain trade-offs in architecture deliverable.

---

## J. TEAM SYSTEM

- Default max size 8, configurable per mode.  
- Duplicate rules configurable per mode.  
- Optional role or rarity gates per mode.  
- Team power is a **display heuristic**, not a hidden win guarantee.  
- Online: ownership validation required.  
- Saved presets supported.  
- Builder shows synergy tags and soft warnings. No forced autobuild that removes skill.  
- Cannot enter match with invalid team for that mode.  
- Editing a team while a match that referenced it is active must not mutate the match snapshot.

### J.1 Team validation failure cases

| Case | UX | API |
|------|----|-----|
| Empty slots below mode minimum | Inline error, Confirm disabled | 422 |
| Duplicate where forbidden | Highlight slots | 422 |
| Unowned card | Remove or lock slot | 422 |
| Banned rarity/role for mode | Badge + disable confirm | 422 |
| Stale catalogue version | Force refresh catalogue | 409 |
| Soft synergy warning only | Warning, Confirm still allowed | 200 on save |

---

## K. COMBAT SYSTEM

### K.1 Baseline

Turn-based for first playable version. Exact rules proposed and frozen in GDD before major coding.

Must cover: speed-informed turn order, attacker/target selection, basic attack, actives, ultimates, healing, shields, buffs, debuffs, statuses, cooldowns/EN, defeat, win/loss, duration limits, documented RNG, battle logs, AI, role interactions.

### K.2 Damage seed (evaluate, do not accept blindly)

`Damage = max(minimum_damage, Attack * AbilityMultiplier - EffectiveDefense)`

Evaluate against crits, armor, shields, DR, buffs, debuffs. Avoid formulas that nullify DEF or let one stat dominate. Provide worked examples in GDD.

### K.3 Engine boundary

Combat logic is pure domain code: no Flutter widgets, no HTTP controllers inside the resolver. Same rules offline and online. Online: server resolves.

### K.4 Combat edge cases (must be defined and tested)

| Scenario | Required behavior |
|----------|-------------------|
| Target dies before action resolves | Retarget rule or action fizzle; never apply to corpse unless rules say so |
| Actor stunned on their turn | Skip with log entry; advance turn cleanly |
| Both teams empty same resolution step | Deterministic tie rule (document) |
| Infinite heal loop potential | Cap, diminishing returns, or cleanse; tests must catch |
| Permanent stun lock | Duration caps, diminishing CC, or cleanse paths |
| EN goes negative | Clamp; reject spend; never silent wrap |
| Integer overflow on big numbers | Use bounded ints; assert caps; tests at max stats |
| Double End Turn tap | Idempotent; second tap ignored |
| Concede mid-animation | Server state wins; client shows concede result |
| Auto-battle on | Only legal actions; respects mode flags |
| Speed 1x/2x/3x | Presentation only; does not change server resolution |
| Disconnect mid-turn | See Session matrix |
| Ability used twice via race | Server version/lock rejects duplicate |
| Match turn limit hit | Forced resolution per mode rules |
| Boss phase transition | Snapshot phase script; no client-authored phase skip |

### K.5 RNG

Document algorithm and seeding. Competitive online: server RNG only. Replays store seeds or event stream sufficient to audit. Client predictive FX must reconcile to server events.

---

## L. GAME MODES

One shared collection, teams, and combat engine. Modes are configuration.

| Mode | Idea | MVP |
|------|------|-----|
| Classic Card Clash | Team vs team | Yes |
| Team Tournament | Brackets | Later |
| Boss Raid | Phased AI boss | Strong post-MVP |
| Draft Challenge | Limited pool | Later |
| Survival Challenge | Successive fights | Later |
| Tactical Challenge | Objectives / limits | Later |

Per mode: team size, ownership vs draft, win conditions, turn limits, rewards, ranking eligibility, matchmaking or AI, boss scripts.

Match creation snapshots stats, abilities, and mode rule version.

---

## M. SESSION, AUTH, AND LIFECYCLE MATRIX

### M.1 Session types

| Session | Meaning |
|---------|---------|
| Anonymous local | Offline prototype / guest local save |
| Authenticated API | Bearer or Sanctum token (decide in architecture) |
| Match session | Server match id + participant seat + state version |
| Admin session | Separate guard, step-up auth recommended for destructive actions |
| Shop/summon transaction | Idempotency key scoped to user |

### M.2 Auth scenarios

| Event | Behavior |
|-------|----------|
| Valid login | Issue token; bind device id optionally; audit login |
| Bad credentials | Generic failure message; rate limit; no user enumeration |
| Expired token | 401; client refresh or re-auth; preserve navigation intent where safe |
| Revoked token | 401; clear local session; force login |
| Concurrent login policy | Document: allow multi-device or kick oldest; never undefined |
| Password reset | Time-limited token; single use; rate limited |
| Account lockout | Temporary after N failures; unlock path documented |
| Logout | Server revoke; client wipe secrets |
| App background during login | No double account create; idempotent register |
| Jailbroken/rooted device | Optional warn; never trust as security boundary |

### M.3 Match session scenarios

| Event | Behavior |
|-------|----------|
| Match found (PvP) | Accept window; timeout returns to queue or cancels |
| Accept then leave app | Match still exists; reconnect policy applies |
| One player never loads | Ready timeout; forfeit or remake per mode |
| Reconnect | Resume from server state version; client rebuilds UI from snapshot + events |
| Desync suspected | Client requests authoritative state; never "trust local HP" |
| Opponent disconnect | Timer; AI takeover or forfeit per mode config |
| Both disconnect | Abandon rules; rating impact documented |
| App killed mid-action | On resume, reconcile; do not replay unacked action blindly without idempotency key |
| Clock skew | Server timestamps win |

### M.4 App lifecycle (Flutter)

| Event | Behavior |
|-------|----------|
| cold start | Splash; restore secure session; route to home or login |
| warm resume | Refresh soft data; revalidate match if active |
| offline | Cached catalogue/collection read-only where allowed; block spend/match actions that need server |
| low memory | Release non-visible image caches; keep match state |
| permission denied (notifications etc.) | Soft degrade; never crash |

---

## N. INTERACTION CONTRACTS (BUTTONS AND CONTROLS)

**Global control rules**

1. Primary actions debounce (default 400 to 800ms) or disable until request completes.  
2. Destructive actions require confirm.  
3. Network actions show progress; success and failure toasts or inline errors.  
4. Double submit uses idempotency keys for create/spend/claim.  
5. Disabled reason must be discoverable (tooltip, caption, or dialog).

### N.1 Home (`home_dashboard`)

| Control | Success | Failure / edge |
|---------|---------|----------------|
| Enter Combat | Navigate mode select or ranked prep if eligible | Insufficient energy/stamina: modal with timer; invalid team: route to builder; banned: error |
| Inspect featured card | Open card detail | Missing card id: error state |
| Event ticker | Open event detail | Event ended: expired state |
| Currency chips | Open economy sheet (if exists) | Offline: show cached; no spend |
| Profile avatar | Open profile | Unauth: login |
| Bottom nav | Switch tabs | Active match: confirm leave or soft-block |

### N.2 Collection / detail / team builder

| Control | Success | Failure / edge |
|---------|---------|----------------|
| Filter chips | Update list | Empty result: empty state CTA |
| Search | Debounced query | XSS-safe; max length |
| Add to team | Slot fill | Full team / duplicate / ownership fail |
| Save team | Persist | Validation 422; conflict 409 |
| Reorder slots | Local then save | Save fail reverts or retries |

### N.3 Battle prep / live duel / results

| Control | Success | Failure / edge |
|---------|---------|----------------|
| Confirm lineup | Create or join match | Validation fail; already in match |
| Basic attack / ability | Send intent with idempotency key | Not your turn; illegal target; on cooldown; insufficient EN; match ended |
| End Turn | Advance phase | Double tap ignored |
| Speed toggle | Client presentation only | Hidden in competitive if fairness requires |
| Auto toggle | Auto picks legal actions | Disabled in ranked if policy says so |
| Combat log | Toggle drawer | No PII leakage |
| Concede / flag | Confirm then concede | Already ended; network fail retries with idempotency |
| Claim rewards | Grant once | Duplicate claim rejected; audit log |
| Retry / return | Navigate safely | Back stack must not reopen live ended match as active |

### N.4 Matchmaking

| Control | Success | Failure / edge |
|---------|---------|----------------|
| Accept duel | Enter prep or battle | Expired offer; opponent declined; network loss |
| Decline | Return to queue or home | Spam decline rate limit |
| Cancel queue | Leave queue | Already matched: show match found |

### N.5 Shop / summon (when enabled)

| Control | Success | Failure / edge |
|---------|---------|----------------|
| Purchase / summon | Transactional grant | Insufficient currency; idempotent replay; probability disclosure shown; legal age/region gates if required |
| Claim daily | Once per window | Timezone server-side |

### N.6 Settings / profile

| Control | Success | Failure / edge |
|---------|---------|----------------|
| Logout | Clear session | In-match: warn |
| Delete account | Confirm + cool-down | Soft delete + data policy |
| Change password | Re-auth | Session revoke others optional |

---

## O. ERROR MODEL

### O.1 Client error presentation

Every screen supports:  
`loading`, `content`, `empty`, `error_retryable`, `error_fatal`, `offline`, `forbidden`, `session_expired`.

User messages are plain language. Log technical detail separately. No em dashes in copy.

### O.2 API error envelope (canonical)

```json
{
  "error": {
    "code": "MATCH_NOT_YOUR_TURN",
    "message": "It is not your turn.",
    "details": {},
    "request_id": "uuid",
    "retryable": false
  }
}
```

### O.3 Stable error codes (extend, do not silently rename)

**Auth:** `AUTH_INVALID_CREDENTIALS`, `AUTH_TOKEN_EXPIRED`, `AUTH_TOKEN_REVOKED`, `AUTH_RATE_LIMITED`, `AUTH_ACCOUNT_LOCKED`  

**Catalogue:** `CARD_NOT_FOUND`, `CARD_UNPUBLISHED`, `CATALOGUE_VERSION_STALE`  

**Collection/teams:** `CARD_NOT_OWNED`, `TEAM_INVALID`, `TEAM_NOT_FOUND`, `TEAM_SLOT_CONFLICT`  

**Match:** `MATCH_NOT_FOUND`, `MATCH_NOT_YOUR_TURN`, `MATCH_ILLEGAL_ACTION`, `MATCH_ILLEGAL_TARGET`, `MATCH_ENDED`, `MATCH_STATE_CONFLICT`, `MATCH_TIMEOUT`, `MATCH_NOT_PARTICIPANT`  

**Economy:** `CURRENCY_INSUFFICIENT`, `REWARD_ALREADY_CLAIMED`, `PURCHASE_IDEMPOTENCY_REPLAY`, `SUMMON_RATE_LIMITED`  

**Platform:** `VALIDATION_FAILED`, `FORBIDDEN`, `NOT_FOUND`, `RATE_LIMITED`, `CONFLICT`, `INTERNAL_ERROR`

HTTP mapping: 400 validation, 401 auth, 403 forbidden, 404 not found, 409 conflict, 422 semantic rule fail, 429 rate limit, 500 internal.

---

## P. SECURITY AND COMPETITIVE INTEGRITY

### P.1 Threat model (minimum)

| Threat | Mitigation |
|--------|------------|
| Stolen password | Hashing (Argon2id or framework current default), rate limits, optional 2FA later |
| Token theft | Short-lived access, secure storage, revoke on logout, HTTPS only |
| Client damage rewrite | Server authoritative combat |
| Replay actions | Idempotency keys + state version |
| Double reward claim | Unique constraints + transactions |
| IDOR on teams/matches | Policies: actor must own or participate |
| SQL injection | Eloquent/query builder; no raw concat |
| XSS in names/lore | Sanitize/encode; length limits |
| Admin privilege abuse | Separate guard, audit log, least privilege |
| Pack probability deception | Configurable weights; disclose; legal review before real money |
| Bot spam | Rate limits, device signals, captcha later if needed |
| Matchmaking inflate | Server queue only; rating server-side |
| Art bucket public write | Signed upload URLs; authz; virus size/type checks |
| Secret leakage | Env only; no secrets in APK; rotate keys |
| Backup theft | Encrypted backups; restricted access |
| Dependency CVE | Lockfiles; periodic updates; CI audit |

### P.2 Competitive rules

Client sends intents only: `{ match_id, action_type, actor_id, target_ids, ability_id, client_action_id, state_version }`.  

Server: authz, validate, lock/transaction, resolve, persist events, return new state.  

Reject: wrong turn, bad target, unowned where required, illegal ability, insufficient resources, non-participant, replay, ended match, stale version without proper conflict handling.

### P.3 Data protection

- Passwords hashed.  
- PII minimized.  
- Logs scrub tokens and passwords.  
- Admin actions audited.  
- Right to delete / export: plan hooks even if MVP defers full automation.

### P.4 Secure coding defaults

- HTTPS everywhere in prod.  
- HSTS at edge when applicable.  
- CORS explicit.  
- Security headers on API.  
- File upload allowlist.  
- Principle of least privilege for DB users.  
- Migrations reviewed for destructive ops.

**HTTPS alone is not security.** Document threats and tests.

---

## Q. TECHNOLOGY STACK

### Q.1 Client

Flutter, Dart, responsive 2D UI, Design Prefer theme, Riverpod or Bloc after comparison, typed API models, local cache for non-sensitive data, unit and widget tests. Android first; keep iOS/desktop possible. Flame only if justified. No unnecessary 3D.

### Q.2 Backend

Laravel REST (maintained PHP/Laravel), MySQL, migrations, models, policies, validation, queues, tests. Redis only when justified. WebSockets only when realtime need is proven. Authoritative for auth, ownership, matches, combat, rankings, rewards.

### Q.3 Infrastructure

Ubuntu VPS or justified managed hosting. Nginx, HTTPS, MySQL backups, secure env, logging, deploy/rollback. Object storage/CDN for art. No Kubernetes without need. APK via store or test channel, not "VPS APK hosting" as primary distribution.

---

## R. API SURFACE (PROPOSED; REFINE BEFORE CODING)

- `POST /api/register` `POST /api/login` `POST /api/logout` `GET /api/me`  
- `GET /api/cards` `GET /api/cards/{id}` `GET /api/collection`  
- `GET/POST /api/teams` `PUT /api/teams/{id}`  
- `GET /api/game-modes`  
- `POST /api/matches` `GET /api/matches/{id}` `POST /api/matches/{id}/actions` `GET /api/matches/{id}/history`  
- `POST /api/matches/{id}/rewards/claim`  
- `GET /api/leaderboard`  

Each endpoint docs must include: auth, authz, validation, response, errors, rate limit, transaction needs, idempotency.

Never trust client for damage, rewards, ownership, currency, victory, ranking, opponent state.

---

## S. DATABASE IDEOLOGY

Candidate tables: users, player_profiles, characters, card_definitions, card_abilities, player_cards, teams, team_slots, game_modes, mode_rule_versions, matches, match_participants, match_card_snapshots, match_actions, match_events, player_progress, player_rewards, leaderboard_entries, economy_ledger, idempotency_keys, admin_audit_logs, permissions.

Rules:

- PK/FK/uniques/indexes documented.  
- Economy mutations append ledger rows; balances derived or strongly consistent under transaction.  
- Unique `(user_id, reward_id)` or equivalent prevents double claim.  
- Unique `(user_id, client_action_id)` or match-scoped idempotency prevents double actions.  
- Soft delete policy explicit per table.  
- Art not stored as MySQL blobs.  
- Do not create every table on day one; create when the milestone needs it.

---

## T. CARD CONTENT PIPELINE

1. Brief.  
2. Allocate rarity budget; divide stats.  
3. Design abilities within kit budget.  
4. Generate and curate art.  
5. Frame compose.  
6. Enter definition (admin or data files).  
7. Automated tests: budget compliance, role drift limits, ability edges.  
8. Publish with catalogue version.

Foundation set: plan all 50 in a table first; implement in waves (10, then 25, then 50). Offline prototype may ship a representative subset while the plan remains authoritative.

---

## U. HOSTING AND DEPLOYMENT (BANGLADESH-REALISTIC)

Compare local, shared hosting, VPS, managed app/DB. Call out shared hosting limits (queues, WebSockets, workers, custom config).

MVP VPS path: sizing, Ubuntu, Nginx/PHP, Laravel, MySQL lockdown, HTTPS, env, migrations, workers, schedules, backups, logs, firewall/SSH, rollback.

Estimate: closed test, small beta, growing online. Label costs as estimates; verify pricing before purchase. Stay cheap until traffic demands more.

---

## V. DEVELOPMENT PHASES (AFTER BUILD AUTHORIZED)

**Phase 1:** Requirements freeze, MVP, combat rules, data model, architecture, API contracts, risks.  
**Phase 2:** Offline prototype: sample cards from 50-plan, collection, team builder, combat, AI, results, tests. Design Prefer screens for those flows.  
**Phase 3:** Laravel/MySQL, auth, catalogue, ownership, teams, Flutter integration, tests.  
**Phase 4:** Online matches, authoritative combat, persistence, reconnect, anti-duplication, basic matchmaking/AI.  
**Phase 5:** Shared mode config; second valuable mode.  
**Phase 6:** Progression, rewards, admin CMS, balance versioning, art publish.  
**Phase 7:** Beta hardening, load/security tests, monitoring, ranking as needed, realtime only if required.

Do not implement all phases in one dump.

---

## W. TESTING STRATEGY (MANDATORY)

### W.1 Test layers

| Layer | Examples |
|-------|----------|
| Unit | Damage formula, status rules, budget split, turn order |
| Domain | Full battle scenarios with expected event logs |
| API feature | Auth, ownership, team validation, match actions |
| Concurrency | Double action, double claim, overlapping End Turn |
| Security | IDOR, authz, injection fixtures, rate limit |
| Widget | Buttons disabled correctly; error/empty/loading |
| Golden / screenshot (optional later) | Design Prefer critical screens |
| Integration | Flutter against staging API |
| Performance | Catalogue load, match action p95 |
| Balance analytics | Win rate by rarity/role after enough samples |

### W.2 Minimum combat scenario pack

1. Basic kill.  
2. Heal prevents kill.  
3. Shield absorbs then breaks.  
4. Stun skip turn.  
5. Ultimate EN gate.  
6. Speed ordering swap.  
7. Simultaneous last-hit tie rule.  
8. Turn limit draw/force.  
9. Illegal target rejection.  
10. Idempotent re-send of same `client_action_id`.

### W.3 Economy scenario pack

1. Claim reward once.  
2. Replay claim.  
3. Insufficient currency purchase.  
4. Concurrent purchases racing balance.  
5. Summon grants match weighted table (statistical test with fixed seed).

### W.4 Definition of done

A feature is not done without: happy path test, at least one negative test, error code asserted where API, and UX state for failure. Balance changes need `balance_version` bump and migration or config note.

Do not nerf from tiny samples; explain noise vs signal.

---

## X. ENGINEERING STANDARDS

- Readable code; current framework conventions.  
- Type-safe models where practical.  
- Separate UI, domain, networking, persistence.  
- Avoid giant files and pointless abstractions.  
- No duplicated business rules across client and server (share spec; server enforces).  
- Configuration over scattered constants.  
- Explicit errors; secrets out of git.  
- Setup and deploy docs.  
- Justify dependencies; check compatibility.  
- Deterministic combat resolution given same snapshot + intents + seed.  
- Treat race conditions as defects, not "unlikely."  
- Bound all numeric combat fields; reject overflow paths.  
- Explicit lifetimes for match state objects (create, run, complete, archive).

---

## Y. ACCESSIBILITY, LOCALIZATION, DEVICE REALITY

- Minimum 48dp primary touch targets.  
- Color is not the only status signal (icons + text).  
- Dynamic type: prefer no clipped critical stats.  
- Screen reader labels on icon-only buttons.  
- English first; string catalog structure ready for later locales.  
- Target ordinary Android devices: image budgets, list virtualization, avoid giant uncompressed assets.  
- Test on 360dp width class.

---

## Z. LEGAL / COMPLIANCE HOOKS

- Original IP only.  
- If real-money packs: disclose probabilities; review platform policies and local law before enabling.  
- Age gating hooks if required by store.  
- Privacy policy and terms placeholders before public beta.  
- AI art license ledger retained.

---

## AA. MULTI-LENS SELF-AUDIT CHECKLIST

Use this checklist on every major prompt revision. All boxes must be justifiable as yes before claiming PRODUCTION READY.

### AA.1 Staff engineer

- [ ] No ambiguous "TBD" on MVP-critical paths without an owner and default.  
- [ ] State machines for auth, match, and reward claim are complete.  
- [ ] Offline vs online boundaries clear.

### AA.2 Security engineer

- [ ] Server authority stated for all competitive and economy mutations.  
- [ ] IDOR, replay, double-spend mitigations present.  
- [ ] Admin and user guards separated.  
- [ ] Secrets and upload safety covered.

### AA.3 Game designer

- [ ] Eight rarities defined; Supreme not an auto-win.  
- [ ] Stats divided by budget.  
- [ ] 50-card pyramid and role coverage rules present.  
- [ ] Modes reuse one engine.

### AA.4 Flutter / UI engineer

- [ ] Design Prefer screens inventoried and bound.  
- [ ] Tokens, type, safe areas, disabled/loading/error states required.  
- [ ] Button contracts include double-press and failure.

### AA.5 Laravel / backend engineer

- [ ] Error envelope and stable codes listed.  
- [ ] Idempotency and transactions required for spend/match.  
- [ ] Snapshotting prevents live patch mutation.

### AA.6 QA

- [ ] Combat and economy scenario packs listed.  
- [ ] Definition of done includes negative tests.

### AA.7 Systems / C++ expert mindset

- [ ] Determinism requirements stated.  
- [ ] Numeric bounds / overflow considered.  
- [ ] Concurrency races treated as first-class defects.  
- [ ] Resource lifetime for matches explicit.  
- [ ] Undefined paths (unspecified disconnect, unspecified tie) eliminated.

### AA.8 Adversarial player

- [ ] Button spam handled.  
- [ ] Packet rewrite useless without server accept.  
- [ ] Leave/reconnect abuse covered by mode rules.  
- [ ] Shop/summon cannot duplicate grants via retry.

### AA.9 Ops

- [ ] Backup, rollback, logging, Bangladesh-realistic hosting path present.

### AA.10 Writing

- [ ] No em dashes (U+2014) and no en dashes (U+2013) in this file.

---

## AB. COLLABORATION PROTOCOL

**Deliverable 1:** Product specification / GDD from this prompt.  
**Deliverable 2:** Architecture.  
**Deliverable 3:** Technical decisions.  
**Deliverable 4:** Roadmap with tests.  
**Deliverable 5:** First offline prototype (only after user says BUILD).

If files exist, inspect before replacing. If structure unknown, ask or guide initialization.

---

## AC. FINAL OBJECTIVE

Ship an original, maintainable, secure, expandable Battle Card Supreme experience where:

- Players collect original Aetherium Rift characters.  
- At least 50 characters span Common through Supreme.  
- Stats are divided from rarity budgets.  
- Images are generated and curated.  
- UI follows `Design Prefer/`.  
- Teams save once and play across configurable modes.  
- Offline works before online is required.  
- Online combat and economy are server-validated, idempotent, and tested.  
- Sessions, buttons, and failures have explicit outcomes.  
- New cards and modes arrive without rewriting the application.  
- Budget stays modest and scales with real usage.

---

## AD. QUICK REFERENCE

| Topic | Rule |
|-------|------|
| Build | Frozen until user says start |
| Em dashes | Forbidden project-wide |
| Style | Anime-inspired original IP |
| World | Aetherium Rift |
| Product | Battle Card Supreme |
| UI | `Design Prefer/` binding |
| Rarities | C, UC, R, SR, E, L, M, S |
| Roster | Minimum 50 across all rarities |
| Stats | Divide budget |
| Art | Generate then curate |
| Online | Server authoritative |
| Economy | Ledger + idempotency |
| UX | Every control has success and failure |
| Quality | Negative tests required |
| Scale | Modest hosting first |

---

## AE. CHANGELOG

| Date | Change |
|------|--------|
| 2026-10-25 | Initial ideology refine (stats divide, art generate, 50 cards, eight rarities). |
| 2026-10-25 | Production max rewrite: Design Prefer binding, session/button matrices, error catalog, security threat model, test packs, multi-lens audit, build freeze, em dash ban. |
| 2026-10-25 | Second-pass hardening: integer/fixed-point combat and economy, ledger rules, name safety, version skew, admin/observability, rate limit classes, input reject cheat sheet, SSR mock mapping, readiness freeze confirmed. |
| 2026-10-25 | BUILD authorized. Offline Flutter prototype started under `battle_card_supreme/` with docs in `docs/`. |
| 2026-10-25 | Phase 3 API under `api/`: Sanctum auth, catalogue, ownership, teams, roster seed sync, feature tests. |
| 2026-10-25 | Phase 4: PHP CombatEngine, matches/actions with locks + idempotency, Flutter online login/duel. |
| 2026-10-25 | Phase 5: shared mode config + rule versions; Survival Challenge (offline multi-wave); match snapshots mode rules. |
| 2026-10-25 | Phase 6: player profiles, economy ledger, idempotent victory claims, balance_versions, art publish admin + audit. |
| 2026-10-25 | Phase 7: feature flags, rate-limit classes, request ids, /api/meta+/ready, IDOR tests, force-upgrade gate, RUNBOOK. |
| 2026-10-25 | Shop/summon enabled: offers, daily claim, disclosed-odds rift pull, duplicate shards; starter pack 6 cards. |
| 2026-10-25 | PvP: matchmaking queue, accept window, pvp_clash mode, seat-aware actions, Flutter queue + duel UI. |

---

## AF. SECOND-PASS HARDENING (MULTI-LENS GAP CLOSURE)

This section exists because the first production rewrite still left room for error. Treat every subsection as mandatory.

### AF.1 Numeric and determinism rules (systems / C++ expert mindset)

1. **No floating point in authoritative combat or economy math.** Use integers or fixed-point scaled integers (document the scale, example: millipoints). Floats are presentation-only (bar widths).  
2. **All combat attributes and currency balances have explicit min/max bounds.** Reject writes outside bounds. Tests hit max bounds.  
3. **Prefer 64-bit signed integers for tallies** (damage totals, lifetime currency earned) to avoid overflow at late-game magnitudes. Document and assert caps anyway.  
4. **Status effect resolution order is total-ordered** (example: start-of-turn DOTs, then regenerations, then stun checks, then player intents). Never "whatever the dictionary iterated."  
5. **Snapshots are immutable.** After match start, card combat stats in `match_card_snapshots` are read-only. Upgrades during a match do not apply until a future match.  
6. **Locks have lifetimes.** Acquire match lock, validate, mutate, append events, commit, release. No lockless "check then act" on rewards or match actions.  
7. **No undefined paths.** Every match terminal state is one of: `victory_a`, `victory_b`, `draw`, `forfeit_a`, `forfeit_b`, `abort_remake`, `abort_admin`. Map mode rules onto these.  
8. **Seeds are explicit.** If RNG is used, store seed + draw index or full event log sufficient for audit replay.

### AF.2 Economy integrity

1. **Currency is never a float.**  
2. Every gain/spend writes an **append-only ledger** row with: user_id, currency_code, delta, reason_code, reference_type, reference_id, created_at, request_id.  
3. Balance updates and ledger inserts share one DB transaction.  
4. **Idempotency keys** required for: purchase, summon, reward claim, match action, match create.  
5. Home dashboard energy/stamina (as in Design Prefer) regenerates on **server time**, not device clock. Client may predict; server corrects.  
6. VIP badges in mocks are cosmetic or documented entitlement flags. VIP must not silently multiply competitive damage. If VIP grants economy perks, list them in config and test them.  
7. Shop and summon screens may ship later, but their safety rules above are binding the moment those endpoints exist.

### AF.3 Identity, names, and content safety

1. Display names: length min/max, unicode normalization (NFC), reject control chars, limit homoglyph confusable pairs where practical, unique constraint policy documented (unique vs unique-case-insensitive).  
2. Lore and player text rendered as text, not HTML.  
3. Report/block hooks planned before public social features (guild chat). If guild ships without chat, do not half-add unmoderated free text.

### AF.4 Client and API version skew

1. API returns `min_app_version` / `catalogue_version`.  
2. Force-upgrade screen when client is below minimum.  
3. Soft warn when catalogue stale; refresh before match enter.  
4. Feature flags server-driven for shop, PvP, summon, guild.

### AF.5 Networking and mobile edge cases

1. Certificate pinning: optional hardening later; do not pretend APK secrecy replaces TLS.  
2. Deep links into a live match open **reconnect flow**, never a second match create.  
3. Push notifications must not auto-accept matches without user action if accept is required.  
4. Background isolate or timer must not submit match actions without fresh state_version.  
5. Guest/local progress migration to authenticated account: merge rules documented before enabling both (no duplicate infinite currency).

### AF.6 CSRF / auth transport

1. If cookie-based Sanctum SPA auth is chosen, CSRF protection is mandatory.  
2. If bearer tokens for mobile, store in secure storage; do not log Authorization headers.  
3. Decide one primary mobile auth mode in architecture deliverable and test it.

### AF.7 Admin safety

1. Admin routes on separate prefix and guard.  
2. Destructive actions (delete user, grant currency, publish card, ban) require re-auth or second factor when feasible; always audit.  
3. Impersonation, if any, is audited and time-limited.  
4. Prod admin access restricted by IP allowlist or VPN when practical.

### AF.8 Observability and incident response

1. Every API response includes `request_id`.  
2. Structured logs: authz failures, economy mutations, match resolutions.  
3. Alerts on: error rate spike, reward claim anomalies, match action conflict rate, disk/backup failures.  
4. Runbooks: rollback deploy, rotate secrets, restore DB backup, disable shop flag.

### AF.9 Rate limits (baseline classes)

| Class | Example | Baseline idea |
|-------|---------|---------------|
| Auth | login, register | Strict per IP + per account |
| Read | catalogue, profile | Higher ceiling |
| Write | teams save | Moderate |
| Match action | combat intents | Per match + per user |
| Economy | buy, summon, claim | Strict + idempotent |
| Admin | all | Per admin user, audited |

Exact numbers live in config. Tests assert 429 behavior.

### AF.10 Design Prefer vs deferred systems

Home shows ranked season, VIP, multiple currencies, events. Those are **product aspirations reflected in UI mocks**. MVP may stub or hide non-ready systems, but must not leave dead buttons that crash or silently no-op without feedback. Every visible button either works per contract or is hidden behind a feature flag.

### AF.11 Data retention and match history

1. Match events retained for dispute window (define duration in GDD, example: 30 days hot, then archive).  
2. Players can view their recent battle history.  
3. Deleting an account anonymizes or deletes PII per policy; competitive integrity logs may retain non-PII aggregates.

### AF.12 Backup while live

1. Backups must not require downtime if possible.  
2. Restore drills documented.  
3. Restoring DB does not resurrect already-claimed client entitlements without ledger consistency checks.

### AF.13 Input validation cheat sheet (reject early)

- Unknown `action_type`  
- Empty `target_ids` when target required  
- Self-target when forbidden  
- Enemy-target when heal-ally only  
- Ability not on actor kit  
- Actor not alive  
- Actor not owned by seat  
- `state_version` mismatch  
- Body over max bytes  
- Unexpected fields stripped or rejected (document choice)

### AF.14 Em dash verification

Before any "ready" claim: search this repository docs for U+2014 and U+2013 and remove them from project-authored markdown and UI strings.

---

## AG. READINESS STATEMENT

**Verification completed in-session:**

1. Em dash count (U+2014): **0**  
2. En dash count (U+2013): **0**  
3. Design Prefer screen inventory bound (section E).  
4. Session, button, error, security, test, and second-pass hardening sections present.  
5. Build freeze remains active.

**Status: PRODUCTION PROMPT READY (implementation still frozen).**

**Agent must stop here.** Do not create Flutter or Laravel project files, do not generate card assets into the app tree, and do not start coding until the user explicitly says to **BUILD** (or equivalent clear start command).

When the user says BUILD, begin with Deliverable 1 confirmation against this file, then architecture, then the offline prototype milestone, always enforcing Design Prefer, divided stats, generated art, 50-card plan, and the contracts in sections M through AF.
