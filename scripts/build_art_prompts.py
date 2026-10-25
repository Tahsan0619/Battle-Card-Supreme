"""Build portrait prompts for GenerateImage (Aetherium Rift / BCS)."""
import json
from pathlib import Path

FACTION = {
    "aetherVanguard": "Aether Vanguard: silver-blue oath plate, harbor lantern glow, disciplined stance",
    "forgeCovenant": "Forge Covenant: ember coal light, brass and soot, furnace heat shimmer",
    "stormCourt": "Storm Court: teal lightning veins, rain mist, wind-swept cloth",
    "voidSyndicate": "Void Syndicate: deep violet shadows, quiet blades, lantern-cut silhouettes",
    "riftborn": "Riftborn: magenta rift cracks, unstable geometry, crystal shards",
    "eclipseOrder": "Eclipse Order: slate ink, chalk diagrams, austere tactical robes",
}

ROLE = {
    "tank": "heavy armor, shield or bracing pose, frontline presence",
    "attacker": "offensive weapon ready, aggressive forward lean",
    "support": "gentle healing aura, calm open hands",
    "assassin": "low profile, dagger or pin, half in shadow",
    "mage": "arcane glyphs circling hands, caster focus",
    "strategist": "tactical tools, maps or slate, calculating eyes",
    "skirmisher": "light gear, mid-motion dash pose",
    "summoner": "echo familiar or rift coil nearby, ritual hands",
}

RARITY = {
    "common": "modest gear, clean but humble",
    "uncommon": "refined kit, subtle glow accents",
    "rare": "notable hero framing, stronger rim light",
    "superRare": "prestige frame energy, richer materials",
    "epic": "dramatic hero shot, vivid faction energy",
    "legendary": "mythic presence, ornate runetech filigree",
    "mythic": "reality-bending aura, intense cosmic bloom",
    "supreme": "apex silhouette, gold-violet rift majesty",
}


def prompt_for(card: dict) -> str:
    faction = FACTION.get(card["faction"], "original fantasy faction styling")
    role = ROLE.get(card["role"], "combatant pose")
    rarity = RARITY.get(card["rarity"], "polished game art")
    return (
        f"Original anime-inspired mobile card game character portrait for Battle Card Supreme "
        f"(Aetherium Rift IP). Subject: {card['name']}. Concept: {card['pitch']} "
        f"Lore cue: {card['lore']} Role look: {role}. Faction palette: {faction}. "
        f"Rarity finish: {rarity}. Vertical 3:4 bust or upper-body portrait, dark cosmic indigo "
        f"background with soft runetech glow, dramatic lighting, highly detailed face and costume, "
        f"no text, no watermark, no logos, no real celebrity likeness, not copying any existing "
        f"franchise character."
    )


def main() -> None:
    cards = json.loads(Path("docs/roster_for_art.json").read_text(encoding="utf-8"))
    out = {c["id"]: prompt_for(c) for c in cards}
    Path("docs/art_prompts.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print(f"wrote {len(out)} prompts")


if __name__ == "__main__":
    main()
