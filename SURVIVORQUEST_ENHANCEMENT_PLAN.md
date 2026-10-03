# SurvivorQuest Enhancement & Refinement Plan

## 1. Executive Summary & Verification Context
The live Godot 4.3 Web export on **itch.io** (`https://locionic.itch.io/survivorquest`) has been verified via headless Chrome DevTools testing:
- **Engine & Performance**: Boots cleanly with WebGL 2.0 (Compatibility renderer), loads assets, compiles WASM, and enters main arena seamlessly.
- **Combat & Systems**: Arena waves, bat swarms, XP gem collection, damage numbers, and level-up card selection are fully functional.
- **Findings from Live Test & Claude Session Review**:
  1. **Localization Gaps**: While the main menu and upgrade cards are in Vietnamese, several UI elements remain hardcoded in English (e.g., Level Up header `LEVEL UP! CHOOSE AN UPGRADE`, weapon names like `[DAG] Thousand Daggers`, `6 KILLS`, and `(REROLL)`).
  2. **Bounties & Landmarks Naming**: 4 run bounties in `game_manager.gd` and 4 landmarks in `main.tscn` / `world_map_ui.gd` are hardcoded in English instead of utilizing the `Loc` localization singleton.
  3. **Expansion 58.0 Balance Conflict**: A Knight with *Chrono Hourglass* (which enforces a 1.25x speed multiplier floor) completely cancels out negative attack speed trade-offs (e.g., -15% attack speed for crit items).
  4. **Emscripten Web Save Sync**: Repeated calls to save data can cause `warning: 2 FS.syncfs operations in flight at once` in the browser console.

---

## 2. Detailed Technical Tasks

### Task 1: Bilingual Localization for Run Bounties & Landmarks
- **Files**:
  - `scripts/game_manager.gd` (`init_run_bounties()`)
  - `scripts/landmark.gd`, `scenes/main.tscn`
  - `scripts/world_map_ui.gd`
  - `scripts/loc.gd` (or localization dictionary)
- **Changes**:
  - Add localized string keys to `Loc`:
    - `bounty_slay_bats_title`: "Thợ Săn Dơi Ma" (EN: "Bat Hunter")
    - `bounty_slay_bats_desc`: "Tiêu diệt 25 Dơi Ma" (EN: "Slay 25 Bats")
    - `bounty_survive_time_title`: "Ý Chí Sắt Đá" (EN: "Iron Resolve")
    - `bounty_survive_time_desc`: "Sinh tồn 2 Phút" (EN: "Survive 2 Minutes")
    - `bounty_defeat_champion_title`: "Trảm Tướng Tinh Anh" (EN: "Champion Slayer")
    - `bounty_defeat_champion_desc`: "Hạ gục 1 Quái Tinh Anh" (EN: "Slay an Elite Champion")
    - `bounty_defeat_goblin_title`: "Săn Yêu Quái Kho Báu" (EN: "Greed Hunter")
    - `bounty_defeat_goblin_desc`: "Tiêu diệt 1 Yêu Quái Kho Báu" (EN: "Slay a Treasure Goblin")
  - Landmarks:
    - `landmark_fountain`: "Suối Sinh Mệnh" (EN: "Sanctuary of Vitality") — "Hồi phục sinh lực cho lữ khách"
    - `landmark_might`: "Đài Uy Lực" (EN: "Altar of Might") — "Cường hóa vũ khí, tăng mạnh sát thương"
    - `landmark_speed`: "Miếu Thần Tốc" (EN: "Shrine of Swiftness") — "Gia tăng tốc độ di chuyển thần tốc"
    - `landmark_vault`: "Cổ Mộ Kho Báu" (EN: "Vault of the Ancients") — "Khai mở bí tàng cổ xưa"
  - In `world_map_ui.gd` and `landmark.gd`, dynamically format names via `Loc.tr()` based on active language setting.

### Task 2: Level-Up Screen & HUD Localization Polish
- **Files**: `scripts/hud.gd`, `scripts/upgrade_screen.gd` (or level up modal)
- **Changes**:
  - Replace hardcoded `LEVEL UP! CHOOSE AN UPGRADE` with `Loc.tr("LEVEL UP! CHOOSE AN UPGRADE")` -> "THĂNG CẤP! CHỌN VÕ HỌC / BÍ KÍP".
  - Replace `KILLS` with `Loc.tr("KILLS")` -> "TIÊU DIỆT".
  - Ensure weapon display tags in the top HUD display localized weapon titles (e.g. `Phi Đao Tuyệt Kỹ` instead of `Thousand Daggers`).

### Task 3: Resolve Expansion 58.0 Balance Conflict (Chrono Hourglass vs Attack Speed Penalties)
- **Files**: `scripts/player.gd` (`_apply_cooldown_floor()`)
- **Analysis**:
  - `CHRONO_COOLDOWN_FLOOR` (1.25) was implemented to prevent hero switching or weapon rebuilds from losing the 20% cooldown reduction.
  - However, because it clamps `w.speed_multiplier = maxf(w.speed_multiplier, 1.25)`, any item or trade-off intended to impose a speed penalty (e.g., -15% speed for +crit chance) gets wiped out back to 1.25 if the player has Chrono Hourglass.
- **Solution**:
  - Separate the Chrono Hourglass relic bonus into its own multiplier factor or track `base_speed_multiplier` vs `penalty_multiplier`, ensuring penalties apply correctly without defeating the relic's intended cooldown floor.

### Task 4: Emscripten Web Save Sync Guard
- **Files**: `scripts/game_manager.gd` (`save_game()`)
- **Changes**:
  - In HTML5/Web exports, prevent overlapping asynchronous `JavaScriptBridge.eval("FS.syncfs(...)")` calls by checking an `is_syncing_filesystem` boolean flag and queuing or coalescing save requests.

---

## 3. Verification & Quality Gate
1. Run hermetic test runner:
   ```bash
   ./scripts/ci.sh
   ```
   Must pass all 61/61 test suites cleanly (`GATE PASSED`).
2. Run Godot headless verification for affected scenes.
3. Commit cleanly with descriptive messages matching the repository convention.

---

## 4. Execution Instructions for Claude Code (Pane `w2:p5`)
1. Implement Task 1 (Bounty & Landmark localization).
2. Implement Task 2 (HUD & Level Up screen localization).
3. Implement Task 3 (Expansion 58.0 Chrono Hourglass balance resolution).
4. Run `./scripts/ci.sh` to ensure all 61/61 suites pass green.
