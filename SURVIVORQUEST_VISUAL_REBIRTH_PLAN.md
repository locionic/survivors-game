# SurvivorQuest: Martial Visual Juice & Arena Polish Plan

> **Goal**: Bring the in-game combat and UI aesthetics of *SurvivorQuest: Huyền Thoại Võ Lâm* up to the high standard of its title screen art, turning repetitive grey arena combat into a gorgeous, dynamic Wuxia action spectacle.

---

## 1. Visual Deficiencies Identified in Combat

1. **Drab, Empty Arena Grid**:
   - The battleground is currently a dark, repeating stone checkerboard with sparse grey pillars.
   - It feels like a test dungeon rather than an epic martial arts realm (e.g. Ba Lăng Huyện, Hoa Sơn, or Trúc Lâm).
2. **Upgrade Cards (Level Up Screen) Look Like Wireframes**:
   - The 3 upgrade choices are currently empty blue rectangular boxes with plain text lines.
   - Missing: Skill art icons, rarity framing (Common/Rare/Epic/Mythic color glowing borders), martial aura effects.
3. **Cluttered Debug-Style Top HUD**:
   - The top bar displays dense raw text strings and abbreviations (`[DAG]`, `[SHD]`, `ATK +10% SPD 253 MAG 140 DEF 2`).
   - Needs clean visual slots for 6 equipped weapons and 6 relics.
4. **Combat Slash Juice & Enemy Feedback**:
   - Sword swings, daggers, and fireballs need distinct, vibrant trails (golden ki aura, fiery bursts, ink-splatter impact).
   - Enemy deaths need impactful martial dissipation (dissolving into ink mist / jade sparks).

---

## 2. Concrete Visual Upgrades

### Phase 1: Ornate Level-Up Skill Cards
*Target: `scripts/upgrade_manager.gd`, `scripts/ui_theme.gd`*

1. **Card Visual Structure**:
   - **Rarity Glow & Border**:
     - *Bình Thường (Common)*: Iron & silver border.
     - *Hiếm (Rare)*: Azure blue glowing border with corner filigree.
     - *Tuyệt Kỹ (Epic)*: Imperial purple border with pulsing aura.
     - *Thần Công (Legendary / Evolution)*: Golden dragon lacquer frame with ember particles.
   - **Martial Skill Icon Badges**:
     - 🗡️ **Thousand Daggers**: Triple flying blades with silver trail.
     - 🔥 **Liệt Hỏa Chưởng**: Flaming palm strike with crimson embers.
     - ⚡ **Lôi Đình Kiếm**: Arc of lightning crackling over a jade sword.
     - 🌀 **Hấp Tinh Đại Pháp**: Swirling dark purple qi vortex.
     - 🛡️ **Kim Cang Hộ Thể**: Golden bell / radiant barrier.
2. **Hover & Selection Juice** — **DONE**:
   - Smooth card lift on hover (`position.y -= 12px`, scale 1.05) with gold chime audio.
   - Confetti/qi burst explosion when confirming an upgrade card.
   - Implemented: `_card_lift()` (+12px, 1.05 scale), `_pulse_aura()` for epic cards, `_ember_motes()` for legendary, `_qi_burst()` on selection, `ui_hover` sound at -12dB.

### Phase 2: Atmospheric Wuxia Arena Overhaul — **DONE**
*Target: `scenes/main.tscn` (arena theming), `scripts/hud.gd` (boss banner), `scripts/gem.gd` & `scripts/coin.gd` (magnet arcs), `scripts/sound_manager.gd` (gong)*

1. **Themed Floor & Props** — **DONE**:
   - **Ba Lăng Huyện**: Ancient paving stones interwoven with patches of green moss, bamboo reeds, weathered stone guardian lions, and floating golden autumn leaves (`CPUParticles2D`).
   - Textures generated and imported: `bamboo_reed.png`, `moss_patch.png`, `guardian_lion.png`, `red_lantern.png`.
   - Procedural helpers in `scripts/main.gd`: `_make_bamboo_reeds`, `_make_moss_patches`, `_make_guardian_lions`, `_make_lantern_posts`, `_make_autumn_leaves`.
2. **Boss Entrance Alert** — **DONE**:
   - Dramatic crimson banner with gold filigree border and shadow: `⚠️ MA GIÁO XUẤT HIỆN: %s ⚠️` with heavy gong sound effect (`buddha_gong`).
   - Boss warning signals wired in `hud.gd:_on_wave_event_announced()`.
3. **XP Gem & Gold Magnet Arcs** — **DONE**:
   - Glowing jade fragments and golden sycees with `MagnetTrail` (`CPUParticles2D` with `local_coords = false`) producing visible magnetic trailing arcs during pull toward the player.

### Phase 3: Clean, Elegant Oriental HUD — **DONE**
*Target: `scripts/hud.gd`, `scenes/main.tscn`*

1. **Visual Weapon & Relic Slots** — **DONE**:
   - 6 circular lacquer weapon slots (`Dagger`, `Shield`, `Thunder`, `Fireball`, `Axe`, `Slash`) with tier/evolution borders and level pips.
   - 6 square lacquer relic slots (`RelicsBar`) tracking collected relics (`vampire_fang`, `storm_amulet`, `phoenix_feather`, `golden_horseshoe`, `berserker_brand`, `chrono_hourglass`).
2. **Streamlined Health & EXP Gauges** — **DONE**:
   - HP bar styled as a red Dragon Qi gauge with ornate gold dragon lacquer accent frame.
   - EXP bar running with radiant jade green celestial glow.

---

> **Note**: For the ongoing **Zombie Outbreak Mode** roadmap and features, see [GAME_DEV_PLAN.md](GAME_DEV_PLAN.md).

---

## 3. Verification & Safety

- Must maintain the 63/63 clean test gate (`./scripts/ci.sh`).
- Zero FPS drops on WebGL canvas in browser.

---

## 4. Sequencing Constraint

**Phase 2 is one atomic task.** Arena props, boss banner, and magnet arcs all touch the main arena scene and related scripts together; splitting them puts multiple agents in the same code paths across branches — only one merge survives. Update `main.tscn`, `scripts/hud.gd`, `scripts/gem.gd`, `scripts/coin.gd`, and `scripts/sound_manager.gd` in a single cohesive change.
