# Technical decisions

| Decision | Choice | Why | Trade-off |
|----------|--------|-----|-----------|
| State management | Riverpod | Simple, testable, wide Flutter support | Team must learn Riverpod |
| Game engine | Pure Dart (no Flame) | Turn-based; Flame not needed yet | Add Flame later only if VFX demand it |
| Fonts | google_fonts (Space Grotesk, Plus Jakarta Sans) | Matches Design Prefer | Needs network first run or bundled fonts later |
| Offline storage | In-memory + optional shared_preferences for team | Fast MVP | Replace with API persistence later |
| Team size MVP | 3 active in battle | Faster prototype battles | Mode config will raise to 8 |
| Damage math | Integers only | Master_Prompt AF.1 | No fractional HP |
| Auth | None offline | Phase 3 | Guest merge rules later |  
