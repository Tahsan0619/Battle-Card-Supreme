"""Generate Flutter character_profiles.dart and enrich api roster.json lore."""
from __future__ import annotations

import json
import re
from pathlib import Path

# Epithet, origin, quote, story for each card id.
PROFILES: dict[str, dict[str, str]] = {
    "c_brine_ward": {
        "epithet": "Salt-Oath Sentinel of the Tide Docks",
        "origin": "Rift-Tide Harbor, Aether Vanguard outer watch",
        "quote": "If the water rises, so do we.",
        "story": (
            "Brine Ward was raised between hanging nets and cracked lanterns on the Rift-Tide docks, "
            "where salt eats steel and oaths are the only currency that survives the fog. "
            "As a child they learned to brace storm doors with their own shoulders when the pier groaned. "
            "The Vanguard did not recruit them for brilliance. They recruited them because nothing, "
            "not even a Rift surge, has ever made Brine Ward step back first. "
            "Their shield is packed with dried brine crystals that hiss when struck, "
            "turning each impact into a reminder that the harbor still stands."
        ),
    },
    "c_ember_pike": {
        "epithet": "Coal-Vent Spear of the Forge Rim",
        "origin": "Living coal vents, Forge Covenant apprenticeship yards",
        "quote": "Heat is just honesty with better manners.",
        "story": (
            "Ember Pike earned their name the hard way: tempering spearheads in vents that never cool. "
            "Apprentices who hesitate lose eyebrows. Apprentices who rush lose fingers. "
            "Pike learned the middle rhythm, heating metal until it sang, then driving that song into a foe's guard. "
            "They still smell faintly of sulfur and polished brass. "
            "On the line they do not posture. They advance, tip glowing, until the furnace decides the fight is over."
        ),
    },
    "c_reed_chorus": {
        "epithet": "Marsh Cantor of the Soft Measure",
        "origin": "Storm Court reed marshes beyond Gale Choir",
        "quote": "Breathe with me. The wound will listen.",
        "story": (
            "Reed Chorus grew up where wind and water argue all night. "
            "The marsh cantors teach healing as music: hollow reeds, shared breath, a tone held until flesh remembers how to close. "
            "Chorus was the quiet student who never missed a note, even when raids cut the reed beds. "
            "In battle they kneel beside the dying and hum a measure older than the Storm Court crowns. "
            "Allies swear the pain softens before the light arrives."
        ),
    },
    "c_night_pin": {
        "epithet": "Lantern-Cut Knife of the Quiet Hour",
        "origin": "Void Syndicate alleys under unlit districts",
        "quote": "If you see the lantern, you were already late.",
        "story": (
            "Night Pin learned assassination as a hygiene of shadows. "
            "No speeches. No trophies. Only the soft click of a pin-blade finding the gap between armor plates "
            "before the street lamps decide to wake. "
            "Syndicate handlers call them reliable. Rivals call them a rumor. "
            "Pin keeps a single extinguished lantern charm on their belt, a reminder that every fight should end "
            "before the light can name a witness."
        ),
    },
    "c_spark_novice": {
        "epithet": "First-Year Arc with Scorched Cuffs",
        "origin": "Storm Court Rift Academy, cohort of the Broken Bell",
        "quote": "I meant to hit the target. Mostly.",
        "story": (
            "Spark Novice still wears academy cuffs stained black at the edges. "
            "Professors said the Rift would teach humility. The Rift taught sparks instead. "
            "Every successful cast is half triumph, half apology to whatever sleeve caught fire. "
            "Yet when the squad needs a bolt, Novice steps up with shaking hands and a grin that refuses to quit. "
            "Veterans keep them close, because raw lightning that wants to learn is rarer than perfect form."
        ),
    },
    "c_slate_clerk": {
        "epithet": "Chalk-Mind Quill of the Eclipse Desks",
        "origin": "Eclipse Order scriptorium, Third Ledger Hall",
        "quote": "Write it once. Then make the field obey.",
        "story": (
            "Slate Clerk believes battles are messy drafts of cleaner documents. "
            "Raised among chalk dust and reprimands, they learned to turn chaos into checklists. "
            "When commanders shout, Clerk is already marking timing windows on a slate strapped to their forearm. "
            "Some call it cold. Clerk calls it mercy: fewer corpses when the plan is legible. "
            "Their strikes land where the diagram said they would."
        ),
    },
    "c_dust_skipper": {
        "epithet": "Glass-Dune Ghost with No Footprints",
        "origin": "Riftborn dunes of shattered silica flats",
        "quote": "If the sand remembers you, you stayed too long.",
        "story": (
            "Dust Skipper was born where the Rift turned desert into knives of glass. "
            "Children there learn to skip, not walk, or the dunes cut them for arrogance. "
            "Skipper made a game of it, then a profession: courier, scout, blade that arrives without a trail. "
            "Riftborn elders say Skipper's shadow sometimes arrives a breath late, as if even darkness struggles to keep up."
        ),
    },
    "c_coil_apprentice": {
        "epithet": "Polite Caller of Tiny Echo Coils",
        "origin": "Riftborn echo nurseries beneath the Fracture Choir",
        "quote": "Please. And thank you. Then sting.",
        "story": (
            "Coil Apprentice treats summons like guests, not tools. "
            "In the echo nurseries, rude callers get bitten. Polite ones get allies. "
            "Apprentice learned every courtesy phrase the coils respond to, then improvised a few more when courtesy failed. "
            "Their familiar is a thumb-sized rift spiral that chirps when danger nears. "
            "Together they look harmless until the spiral unfolds into a needle of living geometry."
        ),
    },
    "c_iron_pail": {
        "epithet": "Bucket Knight of Unreasonable Resolve",
        "origin": "Forge Covenant scrap yards and kitchen-line militia",
        "quote": "If it fits in the pail, it is under my protection.",
        "story": (
            "Iron Pail started as a joke: a militia recruit who strapped a reinforced water pail over a cracked buckler. "
            "The joke stopped landing after Pail walked out of three collapses carrying wounded in that same vessel. "
            "Forge smiths eventually plated the pail properly, but they left the silhouette intact. "
            "Pail likes it that way. Dignity is optional. Holding the line is not."
        ),
    },
    "c_yellow_fuse": {
        "epithet": "Short-Burn Temper with a Lit Cord",
        "origin": "Void Syndicate powder dens of the Amber Cut",
        "quote": "Do not wait for the spark. Be the spark.",
        "story": (
            "Yellow Fuse runs hotter than doctrine allows. "
            "Syndicate handlers tried to teach patience. Fuse taught them scorched briefing tables. "
            "A yellow cord always smolders at their wrist, cosmetic to some, countdown to others. "
            "In a duel Fuse does not circle. They close, jab, and leave the enemy wondering when the boom already happened."
        ),
    },
    "c_balm_twin": {
        "epithet": "Shared-Pulse Healer of the Twin Heartbeat",
        "origin": "Aether Vanguard field clinics after the Salt War",
        "quote": "Two beats. One cleanse. Stay with me.",
        "story": (
            "Balm Twin survived a raid that took their sibling and left a phantom second heartbeat in their chest. "
            "Medics called it trauma echo. Twin calls it a contract. "
            "Every heal they cast is offered as if two people still need to walk home. "
            "Vanguard squads request Twin by name when the wounded start whispering for family that is no longer there."
        ),
    },
    "c_cinder_scout": {
        "epithet": "Ash-Map Eyes of the Covenant Roads",
        "origin": "Forge Covenant rim patrols along smoking causeways",
        "quote": "Smoke is a map if you read the wind.",
        "story": (
            "Cinder Scout charts roads that exist only between eruptions. "
            "They memorize which vents will cough, which bridges will glow soft, which trails will vanish by dawn. "
            "Commanders trust Scout's sketches more than engraved charts. "
            "In a fight Scout is already gone from where you aimed, marking the next approach with a streak of living ember."
        ),
    },
    "uc_mist_suture": {
        "epithet": "Fog-Thread Medic of Condensed Aether",
        "origin": "Storm Court field hospitals in the Weeping Pass",
        "quote": "Hold still. The mist knows your seams.",
        "story": (
            "Mist Suture stitches with weather. "
            "They draw Aetherium vapor into threads that seal torn muscle before blood can argue. "
            "In the Weeping Pass, whole companies lived because Suture refused to accept 'too late' as a diagnosis. "
            "Their gloves are always damp. Their patients wake tasting rain and relief."
        ),
    },
    "uc_glass_runner": {
        "epithet": "Courier of the Cutting Roads",
        "origin": "Riftborn glass arteries between fracture markets",
        "quote": "Speed is the only bandage that fits this road.",
        "story": (
            "Glass Runner delivers what cannot wait and cannot shatter. "
            "Packages, warnings, sometimes people. "
            "The glass roads punish hesitation with blood, so Runner made hesitation extinct. "
            "When they join a squad, the tempo of the entire fight rises, as if the battlefield itself were a deadline."
        ),
    },
    "uc_bulwark_lynn": {
        "epithet": "Patient Wall of the Silver Oath",
        "origin": "Aether Vanguard citadel gate known as Lynn's Watch",
        "quote": "I arrive when the wall is needed. Not before. Not after.",
        "story": (
            "Bulwark Lynn never rushes, and that is why cities still have mornings. "
            "She stood a nine-day siege without raising her voice, only her shield. "
            "Recruits study her patience like scripture. Enemies study the dent patterns and learn despair. "
            "Lynn's armor is polished not for vanity, but so allies can find the wall in smoke."
        ),
    },
    "uc_hex_latch": {
        "epithet": "Lockwright of Binding Sigils",
        "origin": "Eclipse Order vault of forbidden clasps",
        "quote": "Everything opens. I decide when it closes.",
        "story": (
            "Hex Latch collects locks the way others collect scars. "
            "Each sigil on their gauntlet is a captured rule of motion: stop, seal, deny. "
            "Order inquisitors use Latch when a Rift phenomenon must be paused without destroying the evidence. "
            "In combat those same latches clamp onto enemy rhythm until the fight itself feels filed away."
        ),
    },
    "uc_veil_knife": {
        "epithet": "Half-Seen Edge Beneath the Violet Veil",
        "origin": "Void Syndicate veil dens of the Lower Neon",
        "quote": "Look at my eyes. Miss the blade.",
        "story": (
            "Veil Knife fights from behind a silk mask that never quite settles on one face. "
            "Syndicate myth says the veil drinks attention. Science says the dye refracts threat focus. "
            "Knife does not care which story you believe, only that your guard drops for half a blink. "
            "That is all a curved knife needs."
        ),
    },
    "uc_anvil_choir": {
        "epithet": "Hymn-Smith of the Ringing Brass",
        "origin": "Forge Covenant cathedral foundries",
        "quote": "Strike with me. The metal will answer in harmony.",
        "story": (
            "Anvil Choir turns industry into liturgy. "
            "Each hammer fall is a note; each quenched blade a verse. "
            "When Choir sings over a living anvil, sparks arrange themselves into protective intervals around allies. "
            "Forge captains bring Choir to demoralize sieges: nothing unsettles raiders like hearing the wall start humming back."
        ),
    },
    "uc_map_wick": {
        "epithet": "Candle Cartographer of Night Campaigns",
        "origin": "Eclipse Order war rooms lit only by map-wicks",
        "quote": "If the candle dies, the plan was already wrong.",
        "story": (
            "Map Wick plans in the dark on purpose. "
            "Candlelight forces priority: only the routes that matter get flame. "
            "Wick's campaigns are famous for arriving one lantern ahead of disaster. "
            "On the field they still carry a stub of wax, and when it gutters, the next order is already written."
        ),
    },
    "uc_echo_pupil": {
        "epithet": "Student of Floating Echo Orbs",
        "origin": "Riftborn seminary of reflected selves",
        "quote": "My echoes are not copies. They are questions.",
        "story": (
            "Echo Pupil was once told they had no talent for summoning. "
            "Then the orbs came anyway, curious little pupils of light that blinked when Pupil blinked. "
            "Teachers changed their grade. Enemies changed their footing. "
            "Pupil still studies between fights, asking the orbs what they saw while the body was busy surviving."
        ),
    },
    "uc_gale_stitch": {
        "epithet": "Wind-Seam Weaver of the Storm Looms",
        "origin": "Storm Court high lofts above the Gale Spire",
        "quote": "A torn sky can be mended. So can you.",
        "story": (
            "Gale Stitch threads wind the way tailors thread silk. "
            "In the high lofts they repair storm banners that would shred ordinary cloth in a minute. "
            "In battle those same seams pull allies together, closing gaps in formation with a tug of teal current. "
            "Stitch's fingertips are permanently lined with faint lightning scars that glow when they concentrate."
        ),
    },
    "uc_rim_raider": {
        "epithet": "Jagged Claimant of the Rift Edge",
        "origin": "Mixed-band raider camps along the Outer Fracture",
        "quote": "The rim belongs to whoever is still standing on it.",
        "story": (
            "Rim Raider grew up where factions blur and loot writes the law. "
            "They wear mismatched plates: forge brass, void wrap, a stolen Vanguard clasp worn as irony. "
            "Raider is not loyal to banners. They are loyal to the next successful extraction. "
            "Hire them carefully. Betray them never."
        ),
    },
    "r_kairo_ren": {
        "epithet": "Blade-Scholar of the Measured Cut",
        "origin": "Independent duelist circuit of the Mid-Rift arenas",
        "quote": "One clean line is worth a hundred noisy ones.",
        "story": (
            "Kairo Ren treats combat like calligraphy. "
            "Each duel is a page; each finishing stroke must justify the ink. "
            "Arena crowds chant his name because he never wastes a flourish, and never forgives a wasted one either. "
            "Commanders value Ren for the same reason: when the squad needs a decisive cut, Ren has already drawn the line in his mind."
        ),
    },
    "r_lyra_stormveil": {
        "epithet": "Veiled Tempest of the Court Canopy",
        "origin": "Storm Court canopy estates of House Stormveil",
        "quote": "Lightning wears silk until it does not.",
        "story": (
            "Lyra Stormveil was presented to society as ornament and weapon in the same breath. "
            "Her veil is woven with conductive thread that drinks thunder and releases it as precise judgment. "
            "Courtiers underestimate the smile. Veterans watch the sky instead. "
            "When Lyra lifts the veil's edge, rain bends toward her chosen target like an audience leaning in."
        ),
    },
    "r_bastion_ore": {
        "epithet": "Living Vein-Wall of the Deep Smelters",
        "origin": "Forge Covenant subterranean ore cathedrals",
        "quote": "I am not wearing the mountain. I am borrowing it.",
        "story": (
            "Bastion Ore was caught in a smelter collapse and should have died under molten stone. "
            "Instead the ore cooled around them into a second skeleton of living metal. "
            "Priests of the Covenant call it miracle metallurgy. Ore calls it a heavy job with no resignation form. "
            "When Ore plants their feet, the ground remembers what weight means."
        ),
    },
    "r_sable_flute": {
        "epithet": "Nocturne Healer with a Blackwood Reed",
        "origin": "Border chapels between Void alleys and Storm wetlands",
        "quote": "Listen. Healing is just a darker lullaby.",
        "story": (
            "Sable Flute plays for the wounded after midnight, when pride is too tired to refuse help. "
            "The flute is blackwood cut from a tree that grew in Rift shadow and somehow stayed alive. "
            "Each note carries a sedative hush and a stitch of warmth. "
            "Soldiers who mock the instrument go quiet after the first recovery they did not deserve."
        ),
    },
    "r_crimson_ledger": {
        "epithet": "Blood-Ink Auditor of Necessary Wars",
        "origin": "Eclipse Order Directorate of Costed Conflict",
        "quote": "Every life spent must balance. I keep the books.",
        "story": (
            "Crimson Ledger does not romanticize battle. They itemize it. "
            "Red ink marks accepted losses; black ink marks prevented ones. "
            "Field captains hate the coldness until Ledger's numbers save a company that ego would have spent. "
            "In a clash Ledger fights like an accountant with a knife: precise, merciless, and oddly comforting."
        ),
    },
    "r_quill_raze": {
        "epithet": "Incendiary Scribe of Burning Margins",
        "origin": "Rogue scriptoria that left the Eclipse Order",
        "quote": "If the page will not change, burn the margin.",
        "story": (
            "Quill Raze was a clerk until the Order asked them to erase a village from the record. "
            "They refused, fled, and turned the quill into a weapon that writes fire. "
            "Now Raze annotates enemies the way they once annotated law: underline, strike through, ash. "
            "Their coat pockets are full of half-charred pages that still smell like defiance."
        ),
    },
    "r_hop_mirage": {
        "epithet": "Afterimage Dancer of the Crystal Dunes",
        "origin": "Riftborn mirage troupes of the Prism Expanse",
        "quote": "Catch me twice and I will clap. Once is expected.",
        "story": (
            "Hop Mirage was a performer before they were a soldier. "
            "The troupe taught them to leave false selves in the heat shimmer so pursuers stabbed empty air. "
            "When war came, the act became survival doctrine. "
            "Mirage still bows after a perfect dodge. Habit, they claim. Joy, everyone else suspects."
        ),
    },
    "r_loom_wisp": {
        "epithet": "Spectral Weaver of Borrowed Companions",
        "origin": "Riftborn loom-houses where light is spun into kin",
        "quote": "I do not own my wisps. We collaborate.",
        "story": (
            "Loom Wisp threads luminous spirits on a loom that should not exist in three dimensions. "
            "Each wisp is a short-lived ally with a personality and a deadline. "
            "Wisp names them anyway, then thanks them when they fade. "
            "On the battlefield the loom sings, and enemies find themselves fighting a friendship they cannot cut cleanly."
        ),
    },
    "sr_astra_veyron": {
        "epithet": "Cosmic Guardian of the Shattered Void",
        "origin": "Aether Vanguard high orbit sanctum, House Veyron",
        "quote": "Stand behind my light. The void will learn manners.",
        "story": (
            "Astra Veyron carries a bloodline sworn to hold the Rift's hungriest dark at bay. "
            "As a child she watched a void swell eat a moon-district and decided fear was a luxury for people with less duty. "
            "Her armor drinks starlight and returns it as shield geometry. "
            "Squads under Astra fight taller, not because they are braver, but because the night itself seems to hesitate around her."
        ),
    },
    "sr_quill_tactician": {
        "epithet": "Ornate Cartographer of Living War",
        "origin": "Eclipse Order grand atelier of moving maps",
        "quote": "A beautiful plan that fails is still a corpse. Make it live.",
        "story": (
            "Quill Tactician drafts battles that look like illuminated manuscripts and kill like traps. "
            "Their quill leaves glowing routes in the air that squadmates can literally step into. "
            "Rivals accuse them of vanity. Survivors call it clarity worn as art. "
            "When Tactician sheathes the quill, the map fades, and only the victory remains on the page of the world."
        ),
    },
    "sr_obsidian_mire": {
        "epithet": "Black-Glass Titan of the Quiet Sink",
        "origin": "Void Syndicate sinkholes beneath the Neon Quagmire",
        "quote": "Sink with me, or learn to float on your own bones.",
        "story": (
            "Obsidian Mire rose from a sink of cooled voidglass that should have been a grave. "
            "Syndicate deep-bosses use Mire when a problem must disappear without a scream. "
            "The mire around their feet is not mud. It is slow judgment. "
            "Stand too close and your footing becomes a rumor you used to believe."
        ),
    },
    "sr_gilded_saw": {
        "epithet": "Golden Disc of the Covenant Guillotine",
        "origin": "Forge Covenant execution yards turned parade grounds",
        "quote": "Gold is just soft until you spin it fast enough.",
        "story": (
            "Gilded Saw turned a ceremonial cutting disc into a battlefield doctrine. "
            "The saw sings when it spins, a brass hymn that makes forge-workers cheer and enemies duck. "
            "Saw claims every engraved tooth is a debt collected for the Covenant. "
            "Watch the reflections on the disc: they show your last mistake before the cut arrives."
        ),
    },
    "sr_haven_bell": {
        "epithet": "Sanctuary Tone of the Last Safe Room",
        "origin": "Aether Vanguard refuge chapels of the Inner Ward",
        "quote": "Hear the bell. You are not abandoned.",
        "story": (
            "Haven Bell rings only when someone must live. "
            "The bell was cast from scrap of fallen shieldwalls and consecrated by survivors who had nothing left but breath. "
            "In combat the tone builds a brief sanctuary where panic loses jurisdiction. "
            "Bell-carriers are rare because the instrument chooses them. Haven Bell was chosen young, and never put it down."
        ),
    },
    "sr_zephyr_fang": {
        "epithet": "Wind-Tooth Assassin of the High Currents",
        "origin": "Storm Court sky-clans above the Fang Thermals",
        "quote": "You will feel the breeze. Then the absence.",
        "story": (
            "Zephyr Fang hunts on altitudes where breath is thin and mercy is thinner. "
            "Their blades are shaped like teeth of compressed gale, invisible until they bite. "
            "Sky-clan rites demand a solo hunt before adulthood. Fang returned with a storm's name carved into silence. "
            "On the ground they still move as if the air owes them favors."
        ),
    },
    "e_mirror_host": {
        "epithet": "Fractured Host of Borrowed Reflections",
        "origin": "Riftborn mirror-warrens of the Infinite Foyer",
        "quote": "Which of us is the original? Fight all of us and find out.",
        "story": (
            "Mirror Host broke in a foyer where every reflection argued for primacy. "
            "They emerged as a committee wearing one body, summoning selves that disagree productively. "
            "Some mirrors are kind. Some are knives. Host negotiates between them mid-battle. "
            "Enemies who aim for the 'real' one discover democracy has teeth."
        ),
    },
    "e_iron_psalm": {
        "epithet": "Choir-Plate Saint of the Furnace Litany",
        "origin": "Forge Covenant psalter foundries of the Deep Amen",
        "quote": "Sing the armor awake. Then let it preach.",
        "story": (
            "Iron Psalm chants metallurgy into morale. "
            "Their hymn-etched plate vibrates with furnace scripture that hardens resolve and steel alike. "
            "During the Ash Concord siege, Psalm's litany kept a breach sealed for thirty-eight verses. "
            "Ask them about miracles and they will correct you: it was practice, volume, and refusal."
        ),
    },
    "e_violet_auditor": {
        "epithet": "Judgment Eye of the Violet Inquest",
        "origin": "Eclipse Order Hall of Unpaid Consequences",
        "quote": "I am not angry. I am accurate.",
        "story": (
            "Violet Auditor audits reality for fraud: false truces, inflated threats, borrowed courage. "
            "Their gaze leaves a violet afterimage that marks lies on a person like stamped debt. "
            "Politicians fear Auditor more than assassins. Assassins fear the stamp. "
            "In battle the audit becomes sentence, and the sentence arrives as arcane precision."
        ),
    },
    "e_thorn_cantor": {
        "epithet": "Blooming Canticle of Binding Roses",
        "origin": "Storm Court thorn gardens of the Cantor Convent",
        "quote": "Beauty that cannot protect is just decoration.",
        "story": (
            "Thorn Cantor grows weapons that heal and healings that warn. "
            "Their song sprouts luminous thorns that stitch allies and snare foes in the same breath. "
            "Convent doctrine says every rose must earn its bloom through service. "
            "Cantor's garden is a battlefield, and every petal is a receipt."
        ),
    },
    "e_black_relay": {
        "epithet": "Signal Blade of the Midnight Network",
        "origin": "Void Syndicate blacksite relays under the Neon Vein",
        "quote": "I do not chase targets. I route them to endings.",
        "story": (
            "Black Relay is less a person than a node with preferences. "
            "Syndicate networks bounce kill-orders through Relay because the package always arrives. "
            "Violet electricity crawls their sleeves like living cables seeking the next socket. "
            "If you hear static in a quiet room, Relay is already deciding your next corridor."
        ),
    },
    "l_sol_archon": {
        "epithet": "Solar Crown of the Unsetting Vigil",
        "origin": "Aether Vanguard solar sanctum beyond the Daygate",
        "quote": "Night is a guest. I am the host who chooses closing time.",
        "story": (
            "Sol Archon was crowned under a sun that should have died and refused. "
            "The Archon's halo is not ornament. It is a sealed noon carried into places that have never known morning. "
            "Whole campaigns pivot around Archon's presence because darkness itself files for extension and is denied. "
            "They speak softly. The light does not."
        ),
    },
    "l_mare_absolver": {
        "epithet": "Tide Confessor of the Absolving Deep",
        "origin": "Storm Court abyssal shrines of the Mare Chorus",
        "quote": "Bring your guilt to the water. Leave lighter. Or drown cleaner.",
        "story": (
            "Mare Absolver walks shorelines where confession and drowning share a vocabulary. "
            "Their rites wash corruption from Aetherium wounds and sometimes from consciences. "
            "Fleets request Absolver before long voyages; mutinies decrease when the sea has already judged the crew. "
            "In war Absolver raises a tide that cleanses allies and erases the footing of the cruel."
        ),
    },
    "l_crown_of_cinders": {
        "epithet": "Ember Monarch of the Forever Kiln",
        "origin": "Forge Covenant throne-kiln of the Cinder Dynasty",
        "quote": "Kneel to the heat, or become fuel for someone wiser.",
        "story": (
            "Crown of Cinders rules a dynasty that treats monarchy as metallurgy: pressure, heat, purity. "
            "The living cinder crown never cools, and neither does the will beneath it. "
            "Usurpers have tried. The kiln keeps souvenirs. "
            "On the field the Crown does not merely fight. They reforge the tempo of battle until only tempered wills remain."
        ),
    },
    "l_silent_congress": {
        "epithet": "Veiled Parliament of One Body",
        "origin": "Eclipse Order sealed chamber of the Concord Mute",
        "quote": "We have already voted. You are hearing the result.",
        "story": (
            "Silent Congress is a council compressed into a single walking silence. "
            "Multiple veiled faces whisper across one shoulder, agreeing in languages that predates mercy. "
            "The Order deploys Congress when a decision must be made without debate audible to history. "
            "Enemies who demand terms receive a unanimous quiet, then a unanimous end."
        ),
    },
    "m_null_seraph": {
        "epithet": "Inverted Halo of the Unmade Choir",
        "origin": "Beyond-catalog Rift phenomena, Null Capella sightings",
        "quote": "I am the angel of things that did not happen.",
        "story": (
            "Null Seraph should not be countable, yet commanders keep counting them anyway. "
            "Wings of absence fold over the battlefield, erasing attacks that were certain a moment ago. "
            "Theologians argue whether Seraph is salvation or deletion. "
            "Soldiers only know that when the inverted halo tilts toward them, something cruel fails to finish being true."
        ),
    },
    "m_aurora_lattice": {
        "epithet": "Living Prism Grid of the Sky's Skeleton",
        "origin": "Storm-Rift confluence known as the Lattice Dawn",
        "quote": "I am not casting light. I am wearing the sky's math.",
        "story": (
            "Aurora Lattice is a person-shaped solution to an atmospheric equation. "
            "Prism filaments run through their limbs, calculating angles of mercy and ruin. "
            "When Lattice raises a hand, auroras rearrange into cages, bridges, or spears. "
            "Children point upward and cheer. Veterans check the geometry and decide whether to advance."
        ),
    },
    "m_warden_infinite": {
        "epithet": "Recursive Guardian of the Unending Door",
        "origin": "Threshold ruins where doors open into themselves",
        "quote": "You will not pass. Not this you. Not the next.",
        "story": (
            "Warden Infinite guards a door that leads only to more guarding. "
            "Armor layers nest like years, each one a previous attempt to retire that failed. "
            "Rift scholars say killing the Warden only promotes the next recursion into service. "
            "In squad play Infinite is the promise that something, somewhere, will still be standing after the math ends."
        ),
    },
    "s_aether_sovereign": {
        "epithet": "Apex Law of the Rift Throne",
        "origin": "The Aether Throne above contested reality",
        "quote": "Kneel to order, or be ordered into kneeling.",
        "story": (
            "Aether Sovereign is less a monarch and more the idea of rule wearing a body. "
            "Where Sovereign walks, conflicting laws of physics form a queue and wait their turn. "
            "Factions swear mutually exclusive oaths around this presence and somehow keep them. "
            "To fight beside Sovereign is to feel history choose a spine. To fight against is to discover your rebellion was already filed."
        ),
    },
    "s_first_fracture": {
        "epithet": "Named Wound at the Birth of the Rift",
        "origin": "The first crack, before maps, before factions",
        "quote": "I was the beginning. I can be the ending.",
        "story": (
            "First Fracture is the origin scar given courtesy, language, and appetite. "
            "Before Vanguard banners and Forge hymns, there was a split in what 'is' meant. "
            "Fracture learned names from those who feared it, then wore the finest name like a crown of broken glass. "
            "When Fracture enters a match, every other story becomes a footnote practicing for apocalypse."
        ),
    },
}


def dart_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def write_dart(path: Path) -> None:
    lines = [
        "// Generated by scripts/gen_character_profiles.py. Do not hand-edit bulk entries.",
        "class CharacterProfile {",
        "  const CharacterProfile({",
        "    required this.epithet,",
        "    required this.origin,",
        "    required this.quote,",
        "    required this.story,",
        "  });",
        "",
        "  final String epithet;",
        "  final String origin;",
        "  final String quote;",
        "  final String story;",
        "}",
        "",
        "const Map<String, CharacterProfile> kCharacterProfiles = {",
    ]
    for cid, p in PROFILES.items():
        lines.append(f"  '{cid}': CharacterProfile(")
        lines.append(f"    epithet: '{dart_escape(p['epithet'])}',")
        lines.append(f"    origin: '{dart_escape(p['origin'])}',")
        lines.append(f"    quote: '{dart_escape(p['quote'])}',")
        lines.append(f"    story: '{dart_escape(p['story'])}',")
        lines.append("  ),")
    lines.append("};")
    lines.append("")
    lines.append("CharacterProfile? profileFor(String id) => kCharacterProfiles[id];")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {path} ({len(PROFILES)} profiles)")


def patch_roster_seed(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    for cid, p in PROFILES.items():
        # Replace lore string inside the blueprint that has this id.
        pattern = (
            rf"(id:\s*'{re.escape(cid)}',[\s\S]*?pitch:\s*')([^']*)(',[\s\S]*?lore:\s*')([^']*)(')"
        )

        def repl(m: re.Match[str]) -> str:
            return f"{m.group(1)}{dart_escape(p['epithet'])}{m.group(3)}{dart_escape(p['story'][:220].rstrip() + '…') if False else dart_escape(p['story'])}{m.group(5)}"

        new_text, n = re.subn(pattern, repl, text, count=1)
        if n != 1:
            raise SystemExit(f"failed to patch lore for {cid}")
        text = new_text
    path.write_text(text, encoding="utf-8")
    print(f"patched {path}")


def patch_api_roster(path: Path) -> None:
    rows = json.loads(path.read_text(encoding="utf-8"))
    for row in rows:
        p = PROFILES.get(row["id"])
        if not p:
            continue
        row["pitch"] = p["epithet"]
        row["lore"] = p["story"]
        row["epithet"] = p["epithet"]
        row["origin"] = p["origin"]
        row["quote"] = p["quote"]
        row["story"] = p["story"]
    path.write_text(json.dumps(rows, indent=2), encoding="utf-8")
    print(f"patched {path} ({len(rows)} rows)")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    write_dart(root / "battle_card_supreme/lib/domain/data/character_profiles.dart")
    api_roster = root / "api/database/data/roster.json"
    if api_roster.exists():
        patch_api_roster(api_roster)
    assert len(PROFILES) == 50, len(PROFILES)


if __name__ == "__main__":
    main()
