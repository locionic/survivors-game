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

### Phase 2: Atmospheric Wuxia Arena Overhaul
*Target: `scenes/main.tscn` (arena theming), `scripts/hud.gd` (boss banner), `scripts/gem.gd` & `scripts/coin.gd` (magnet arcs), `scripts/sound_manager.gd` (gong)*

1. **Themed Floor & Props** — **PARTIALLY DONE** in `main.tscn`:
   - **Ba Lăng Huyện**: Ancient paving stones interwoven with patches of green moss, bamboo reeds, weathered stone guardian lions, and floating golden autumn leaves (`CPUParticles2D`).
   - **Borders & Walls**: Carved wooden fences and traditional red lantern posts that glow in the darkness.
   - Procedural helpers exist: `_make_bamboo_reed`, `_make_moss_patch`, `_make_guardian_lion`, `_make_lantern_post` in `main.tscn` script.
2. **Boss Entrance Alert** — **NOT DONE**:
   - Dramatic crimson banner: `⚠️ MA GIÁO XUẤT HIỆN: HẮC Y TỔNG QUẢN ⚠️` with heavy gong sound effect.
   - `buddha_gong` sound exists in `sound_manager.gd:195-197`, localization key `"hud.boss_warning": "MA GIÁO XUẤT HIỆN: %s"` in `loc.gd`.
   - `WarningBanner` node exists in HUD (`main.tscn:475-493`) but shows generic "⚠️ WARNING!".
   - Boss warning signals already emitted: `enemy_spawner.gd` & `wave_director.gd` emit `wave_event_announced`.
3. **XP Gem & Gold Magnet Arcs** — **NOT DONE**:
   - Glowing jade fragments and golden sycees (kim nguyên bảo) that pull toward the player with smooth magnetic trailing arcs.
   - `gem.gd:49-57` and `coin.gd:33-38` have magnet pull logic with squash effect but no visual arc trails.

### Phase 3: Clean, Elegant Oriental HUD
*Target: `scripts/hud.gd`*

1. **Visual Weapon & Relic Slots** — **NOT DONE**:
   - Replace bracketed text tags with 6 circular lacquer weapon slots and 6 square relic slots.
   - Small level pips under each icon (e.g. 5 tiny golden stars for Level 5 maxed skill).
   - Text `equipment_slots` iteration exists at `hud.gd:1007` but no visual slots rendered.
2. **Streamlined Health & EXP Gauges** — **NOT DONE**:
   - HP bar styled as a red Dragon Qi gauge with an ornate gold dragon-head frame.
   - EXP bar running across the top with radiant jade green glow.

---

## 3. Verification & Safety

- Must maintain the 63/63 clean test gate (`./scripts/ci.sh`).
- Zero FPS drops on WebGL canvas in browser.

---

## 4. Sequencing Constraint

**Phase 2 is one atomic task.** Arena props, boss banner, and magnet arcs all touch the main arena scene and related scripts together; splitting them puts multiple agents in the same code paths across branches — only one merge survives. Update `main.tscn`, `scripts/hud.gd`, `scripts/gem.gd`, `scripts/coin.gd`, and `scripts/sound_manager.gd` in a single cohesive change.
