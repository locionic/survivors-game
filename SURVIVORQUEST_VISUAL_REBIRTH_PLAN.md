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
2. **Hover & Selection Juice**:
   - Smooth card lift on hover (`position.y -= 12px`, scale 1.05) with gold chime audio.
   - Confetti/qi burst explosion when confirming an upgrade card.

### Phase 2: Atmospheric Wuxia Arena Overhaul
*Target: `scenes/arena.tscn`, `scripts/arena.gd`, `scripts/world_map_ui.gd`*

1. **Themed Floor & Props**:
   - **Ba Lăng Huyện**: Ancient paving stones interwoven with patches of green moss, bamboo reeds, weathered stone guardian lions, and floating golden autumn leaves (`CPUParticles2D`).
   - **Borders & Walls**: Carved wooden fences and traditional red lantern posts that glow in the darkness.
2. **Vibrant Martial Combat VFX**:
   - **Hit Impact Juice**: Comic-style impact flashes when critical strikes hit.
   - **XP Gem & Gold Sparkle**: Glowing jade fragments and golden sycees (kim nguyên bảo) that pull toward the player with smooth magnetic trailing arcs.
   - **Boss Entrance Alert**: Dramatic crimson banner: `⚠️ MA GIÁO XUẤT HIỆN: HẮC Y TỔNG QUẢN ⚠️` with heavy gong sound effect.

### Phase 3: Clean, Elegant Oriental HUD
*Target: `scripts/hud.gd`*

1. **Visual Weapon & Relic Slots**:
   - Replace bracketed text tags with 6 circular lacquer weapon slots and 6 square relic slots.
   - Small level pips under each icon (e.g. 5 tiny golden stars for Level 5 maxed skill).
2. **Streamlined Health & EXP Gauges**:
   - HP bar styled as a red Dragon Qi gauge with an ornate gold dragon-head frame.
   - EXP bar running across the top with radiant jade green glow.

---

## 3. Verification & Safety

- Must maintain the 62/62 clean test gate (`./scripts/ci.sh`).
- Zero FPS drops on WebGL canvas in browser.
