"""Export Flutter roster blueprints to JSON for Laravel seeder."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / "battle_card_supreme" / "lib" / "domain" / "data" / "roster_seed.dart"
OUT = ROOT / "api" / "database" / "data" / "roster.json"


def parse_blueprints(text: str) -> list[dict]:
    # Split on blueprint constructors after the const list starts.
    chunks = re.split(r"\n\s*_Blueprint\(", text)
    cards: list[dict] = []
    for chunk in chunks[1:]:
        def grab(key: str, default: str | None = None) -> str | None:
            m = re.search(rf"{key}:\s*'([^']*)'", chunk)
            if m:
                return m.group(1)
            m2 = re.search(rf"{key}:\s*(Rarity\.\w+|CardRole\.\w+|Faction\.\w+|true|false|\d+)", chunk)
            if m2:
                return m2.group(1)
            return default

        rarity = grab("rarity", "") or ""
        role = grab("role", "") or ""
        faction = grab("faction", "") or ""
        card = {
            "id": grab("id"),
            "name": grab("name"),
            "pitch": grab("pitch"),
            "lore": grab("lore"),
            "rarity": rarity.replace("Rarity.", ""),
            "role": role.replace("CardRole.", ""),
            "faction": faction.replace("Faction.", ""),
            "passive_name": grab("passiveName"),
            "passive_description": grab("passiveDescription"),
            "ability_id": grab("abilityId"),
            "ability_name": grab("abilityName"),
            "ability_description": grab("abilityDescription"),
            "en_cost": int(grab("enCost", "0") or 0),
            "cooldown": int(grab("cooldown", "0") or 0),
            "mult": int(grab("mult", "100") or 100),
            "heal": int(grab("heal", "0") or 0),
            "shield": int(grab("shield", "0") or 0),
            "aoe": (grab("aoe", "false") or "false") == "true",
            "art_seed": int(grab("artSeed", "0") or 0),
            "tags": re.findall(r"'([a-z_]+)'", grab("tags", "") or "")
            if False
            else [],
        }
        tags_m = re.search(r"tags:\s*\[([^\]]*)\]", chunk)
        if tags_m:
            card["tags"] = re.findall(r"'([^']+)'", tags_m.group(1))
        if card["id"] and card["name"]:
            cards.append(card)
    return cards


def main() -> None:
    text = DART.read_text(encoding="utf-8")
    cards = parse_blueprints(text)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(cards, indent=2), encoding="utf-8")
    print(f"Wrote {len(cards)} cards to {OUT}")


if __name__ == "__main__":
    main()
