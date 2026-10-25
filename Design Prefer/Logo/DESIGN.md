---
name: Aetherium Rift
colors:
  surface: '#10131c'
  surface-dim: '#10131c'
  surface-bright: '#363943'
  surface-container-lowest: '#0b0e17'
  surface-container-low: '#181b25'
  surface-container: '#1c1f29'
  surface-container-high: '#272a34'
  surface-container-highest: '#32343f'
  on-surface: '#e0e2ef'
  on-surface-variant: '#cbc3d7'
  inverse-surface: '#e0e2ef'
  inverse-on-surface: '#2d303a'
  outline: '#958ea0'
  outline-variant: '#494454'
  surface-tint: '#d0bcff'
  primary: '#d0bcff'
  on-primary: '#3c0091'
  primary-container: '#a078ff'
  on-primary-container: '#340080'
  inverse-primary: '#6d3bd7'
  secondary: '#4cd7f6'
  on-secondary: '#003640'
  secondary-container: '#03b5d3'
  on-secondary-container: '#00424e'
  tertiary: '#ffb95f'
  on-tertiary: '#472a00'
  tertiary-container: '#ca8100'
  on-tertiary-container: '#3e2400'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e9ddff'
  primary-fixed-dim: '#d0bcff'
  on-primary-fixed: '#23005c'
  on-primary-fixed-variant: '#5516be'
  secondary-fixed: '#acedff'
  secondary-fixed-dim: '#4cd7f6'
  on-secondary-fixed: '#001f26'
  on-secondary-fixed-variant: '#004e5c'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#10131c'
  on-background: '#e0e2ef'
  surface-variant: '#32343f'
typography:
  display-hero:
    fontFamily: Space Grotesk
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.03em
  display-hero-mobile:
    fontFamily: Space Grotesk
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: 0.0em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0.01em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.01em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 15px
    letterSpacing: 0.02em
  label-tactical:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.06em
  label-numeric:
    fontFamily: Space Grotesk
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-micro:
    fontFamily: Plus Jakarta Sans
    fontSize: 9px
    fontWeight: '600'
    lineHeight: 11px
    letterSpacing: 0.08em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-mobile: 0.5rem
  margin: 1rem
  margin-mobile: 0.75rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system establishes a high-fidelity dark-fantasy anime aesthetic crafted specifically for collectible card battle experiences on modern Android smartphones. The visual environment strikes a balance between mystical arcane power and crystalline tactical precision. It avoids juvenile tropes in favor of an ominous, prestige gaming mood: midnight void depths, ethereal energy conduits, runic accents, and gleaming card relics.

### Visual Pillars
- **Abyssal Luminosity:** UI components emerge from near-black midnight depths, utilizing luminous strokes and colored glows rather than traditional skeuomorphic bevels.
- **Runetech Artifice:** Angled chamfers, delicate hairline boundary frames, and subtle geometric sigils create an elite artifacts atmosphere inspired by modern Japanese dark fantasy role-playing games.
- **Combat Telemetry:** Tactile, ergonomic hit targets engineered strictly for one-handed and thumb-range tactical play within compact 360–430px viewports. Visual feedback is immediate, punchy, and chromatic.
- **Tiered Splendor:** Hierarchy reinforces status. Common elements remain matte and quiet; legendary and mythic frames radiate with golden embers and electric violet aura pulses.

## Colors

The palette is engineered exclusively for an immersive OLED-optimized dark mode. Backgrounds step through three disciplined tonal layers to convey depth without introducing visual mud.

### Surface Tones
- **Abyssal Base (`#080B14`):** Canvas root, root scaffold, and screen background. Deep midnight void that saves battery on AMOLED displays.
- **Card/Plate Layer (`#0D1322`):** Primary structural surface for card backings, floating sheets, drawer panels, and navigation docks.
- **Elevated Interactive Layer (`#151D33`):** Active battle slots, item badges, input containers, and elevated modals.
- **Border Conduits (`#1E293B` to `#334155`):** Structural boundaries, resting hairline borders, and frame separators.

### Energy & Combat Accents
- **Electric Violet (`#8B5CF6` / `#7C3AED`):** Primary action impulse, mana reservoirs, active skill toggles, and mystical energy signatures.
- **Luminous Cyan (`#06B6D4` / `#38BDF8`):** Tactical readouts, targeting reticles, turn timers, shield status, and secondary interactive prompts.
- **Solar Gold (`#F59E0B` / `#FBBF24`):** SSR/Legendary card frames, critical rate highlights, victory states, and premium currencies.
- **Vital Crimson (`#EF4444`):** Health bars, threat meters, incoming attack vectors, and offensive debuffs.
- **Verdant Emerald (`#10B981`):** Restorative effects, allied shields, ready states, and positive stat modifiers.
- **Arcane Blue (`#3B82F6`):** Kinetic action points, deck counters, and standard spell casting cost.

### Typography & Readout Neutral Tones
- **Star White (`#F8FAFC`):** Primary headings, power values, cost counts, and key stats.
- **Muted Slate (`#94A3B8`):** Passive lore snippets, secondary labels, disabled controls, and inactive cooldown timers.
- **Dark Slate (`#475569`):** Subdued runic etchings and background watermark iconography.

## Typography

The type system blends tactical mechanical structure with ultra-clear mobile legibility under chaotic combat conditions.

- **Display & Tactical Headings (`Space Grotesk`):** Delivers a technical, neo-cyber anime presence for damage numbers, round transitions, victory banners, and phase annunciators. It carries an assertive, angled cadence that feels futuristic and occult.
- **Card Rules & Narrative Body (`Plus Jakarta Sans`):** Ensures absolute clarity at micro sizes (11px–13px) across variable Android display densities. Its geometric, open counters prevent dense card text paragraphs and lore descriptions from fatiguing the player.
- **Tactical Numerics (`Space Grotesk` Bold):** Used inside stat badges (ATK, DEF, AP Cost) with fixed tabular spacing logic to avoid layout jitter during real-time value increments.
- **Micro Labels:** All caps with expanded letter spacing (+0.06em to +0.08em) for card sub-types, faction tags, and passive triggers.

## Layout & Spacing

Layout geometry is tuned around standard Android phone widths (360dp, 390dp, and 412dp) with dynamic safe-insets for camera cutouts, gestures, and bottom navigation handles.

### Screen Layout Model
- **Combat Grid:** Vertical split screen. The upper 48% is reserved for enemy formation zones, turn intent meters, and atmospheric card battlefield stages. The lower 52% hosts the player hand carousel, mana conduits, and quick-strike control clusters.
- **Columns & Margins:** A compact 4-column layout with `0.5rem` (8px) gutters on mobile allows dense 3-card and 5-card battlefield slots to fit side-by-side without horizontal clipping. Edge padding defaults to `0.75rem` (12px) to maximize usable card surface area.
- **Thumb Zone Anchoring:** All high-frequency action buttons (End Turn, Summon, Focus Burst) inhabit a bottom-anchored tactical arc within 72dp of the bottom navigation bar.

### Spacing Scale
- `space-xs` (4px): Inner badge padding, status pip gaps, and icon-to-number offsets.
- `space-sm` (8px): Gaps between cards in the hand dock, combat modifier tags, and stack separators.
- `space-md` (12px): Padding within card metadata wrappers and dialog header insets.
- `space-lg` (16px): Section boundaries and panel spacing.
- `space-xl` (24px): Stage demarcation between opposing battlefield halves.

## Elevation & Depth

This design system avoids soft, muddy drop shadows. Depth is established through **tonal stacking**, **hairline edge illumination**, and **localized energy bloom**.

### Layer Hierarchy
1. **The Abyss (0dp - Canvas):** Raw `#080B14` patterned with ultra-subdued 5% opacity runic geometry.
2. **Zone Plates (1dp - Surface 1):** `#0D1322` equipped with a 1px continuous border (`#1E293B`).
3. **Card Entities & Active Panels (2dp - Surface 2):** `#151D33` wrapped in a 1px semi-translucent primary-accent border (`rgba(139, 92, 246, 0.35)`).
4. **Focused / Dragging Card (8dp - Floating):** Scaled to 1.08x with an external 16px blur radius glow tinted in Electric Violet (`rgba(139, 92, 246, 0.45)`) or Solar Gold (`rgba(245, 158, 11, 0.50)`).
5. **HUD Overlays & Ultimate Modals (16dp - Apex):** Backdropped by `rgba(8, 11, 20, 0.85)` with a 12px hardware-accelerated blur (`BackdropFilter` in Flutter).

### Runic Edge Tracing
Active interactive elements do not use blurry shadows to show elevation; they use a razor-sharp 1px inner highlight (`inset 0 1px 0 rgba(255, 255, 255, 0.15)`) coupled with an energetic outer stroke.

## Shapes

The design uses **Soft (Level 1)** geometry (`0.25rem` / 4px base border radius) combined with angled chamfers to invoke precision-milled mystical armaments.

- **Base Corner Radius (`0.25rem` / 4px):** Applied to badges, HP fill segments, and skill toggles.
- **Card Frames (`rounded-lg` / 8px):** Subtle rounding that retains a sharp, collectible tarot-card feel without collapsing into casual bubble shapes.
- **Overlays & Modals (`rounded-xl` / 12px):** Top edge rounding for bottom sheets and summoning displays.
- **Chamfer Accents:** Primary combat buttons and tier seals feature 45-degree corner notches (cut corners) on top-right and bottom-left edges, executed via custom path clipping in Flutter.

## Components

### 1. Collectible Combat Cards
- **Structure:** Aspect ratio 1:1.45. Composed of an artwork viewport, top-left AP cost orb, top-right rarity seal, mid-lower rule text container (`#0D1322` at 90% opacity), and bottom combat stats footer.
- **Border Treatments:** 
  - *Standard:* 1px solid `#1E293B`.
  - *Rare/Epic:* 1.5px gradient border (`#8B5CF6` to `#06B6D4`).
  - *Legendary:* 1.5px radiant gold frame (`#F59E0B` to `#FBBF24`) with subtle corner filigree brackets.
- **Status Badges:** ATK (Crimson icon + white Space Grotesk text), DEF (Cyan shield + white Space Grotesk text) positioned in the bottom corners with `#080B14` backing chips.

### 2. Tactical Action Buttons
- **Primary Attack / Confirm:** Solid Electric Violet (`#7C3AED`) background with a 1px border (`#A78BFA`), chamfered corners, and high-contrast Star White bold text. 
- **End Turn / Tactical Pass:** Luminous Cyan outline button with `#06B6D4` typography and a pulsing 2px energy runeline across its bottom edge.
- **Touch Target:** Minimum 48dp height and 100% full-bleed thumbs-reach row options.

### 3. Vitality & Conduit Meters
- **Health Bar (HP):** Segmented container with `#151D33` track and `#EF4444` fill. Overheal or shield displays as an overlaying `#06B6D4` bar with a diagonal stripe shader.
- **Energy / Mana Pool:** Circular or diamond nodes filled with `#3B82F6` and glowing `#60A5FA` cores when charged; hollow `#1E293B` frames when depleted.

### 4. Interactive Chips & Filters
- **Card Filter Tags:** Height 28dp, background `#0D1322`, border 1px `#334155`, text `#94A3B8`. When selected: background `#8B5CF6` at 20% opacity, border `#8B5CF6`, text `#F8FAFC`.

### 5. Input Fields & Search Bars
- **Deck Search:** Pill-less, refined rectangle (`4px` radius). `#0D1322` background, 1px `#1E293B` boundary, text `#F8FAFC`, placeholder `#475569`. Focused state triggers a `#06B6D4` stroke and a micro cyan corner bracket.

### 6. Lists & Deckbuilder Drawers
- **Deck Matrix Rows:** Dense 56dp height strips with thumbnail avatar, mana cost bead, card name in `Space Grotesk`, count indicator (`x3`), and `#1E293B` bottom hairline dividers.

### 7. Checkboxes & Radio Controls
- **Runic Toggle:** Diamond-shaped 18dp box with sharp 2px chamfer. Unchecked: `#151D33` with `#334155` border. Checked: Filled with `#8B5CF6` containing a sharp Star White check sigil.