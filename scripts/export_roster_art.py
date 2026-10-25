import json
import re
from pathlib import Path

text = Path("battle_card_supreme/lib/domain/data/roster_seed.dart").read_text(
    encoding="utf-8"
)
# Only real blueprint list entries: id: 'something'
blocks = re.findall(r"_Blueprint\((.*?)\)\s*,", text, re.S)
cards = []
for b in blocks:
    m_id = re.search(r"id:\s*'([^']+)'", b)
    if not m_id:
        continue

    def g(key: str) -> str:
        m = re.search(rf"{key}:\s*'((?:\\'|[^'])*)'", b)
        if m:
            return m.group(1).replace("\\'", "'")
        m = re.search(rf"{key}:\s*([A-Za-z0-9_.]+)", b)
        return m.group(1) if m else ""

    cards.append(
        {
            "id": g("id"),
            "name": g("name"),
            "pitch": g("pitch"),
            "lore": g("lore"),
            "rarity": g("rarity").replace("Rarity.", ""),
            "role": g("role").replace("CardRole.", ""),
            "faction": g("faction").replace("Faction.", ""),
        }
    )

out = Path("docs/roster_for_art.json")
out.write_text(json.dumps(cards, indent=2), encoding="utf-8")
print(f"exported {len(cards)} cards -> {out}")
