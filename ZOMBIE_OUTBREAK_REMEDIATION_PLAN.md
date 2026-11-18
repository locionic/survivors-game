# Remediation & Stabilization Plan: Project Z-Survivor (PR #1)

## Executive Summary
This document outlines the actionable remediation plan for **Pull Request #1: "Enforce Zombie Outbreak mode as default"** (branch: `fix/zombie-outbreak-default` into `master`). 

While PR #1 successfully implements core zombie assets, SWAT operatives, quarantine ambiance, and biohazard wave spawns, it currently introduces several engine syntax errors, property incompatibilities, and test regressions resulting in 28 of 65 automated test suites failing or hanging.

---

## 1. Root Cause Analysis

### A. Fatal GDScript Parse Corruption in `scenes/main.tscn` (Blocker)
* **Problem**: In commit `29f4313` and propagated into PR #1, `scenes/main.tscn` contains unescaped double quotes inside the string resource `script/source = "..."` (e.g. `var bg = get_node_or_null("Background")` instead of `\"`), followed by duplicated trailing blocks (`"" Background\")`).
* **Symptom**: Godot engine fails to parse the scene at boot with `ERROR: Failed loading scene: res://scenes/main.tscn`, causing an immediate crash / blank grey screen.

### B. Invalid Property Assignment on `CPUParticles2D` (`pre_process_time`)
* **Problem**: In `scripts/coin.gd:38`, `scripts/gem.gd:40`, and `scenes/main.tscn`, particle emitters assign `trail.pre_process_time = 0.0`.
* **Symptom**: In Godot 4.3, `CPUParticles2D` uses property `preprocess`. This throws runtime script errors and aborts `_ready()` on coins/gems, hanging game loops.

### C. Missing Suite Teardown in `tests/test_zombie_world.gd`
* **Problem**: `test_zombie_world.gd` verifies all zombie features and passes, but omits `get_tree().quit(_exit_code())`.
* **Symptom**: Headless CI hangs until hitting the 120-second timeout threshold.

### D. Destructive Defaults in `load_save_data()`
* **Problem**: In `scripts/game_manager.gd`, PR #1 unconditionally overrides `selected_stage = "zombie_city"` inside `load_save_data()`, even when resetting saves for tests.
* **Symptom**: Breaks older test suites (e.g., `test_expansion_35.gd`, `test_wave_arena_milestone_2.gd`) that test the baseline martial arts stage mechanics and HP curves.

### E. Canonical Localization Drift in `scripts/loc.gd`
* **Problem**: Replacing canonical weapon names and strings directly in `Loc.STRINGS` breaks regression tests (e.g., `test_global_edition.gd`) asserting against previous canonical IDs.

---

## 2. Step-by-Step Remediation Plan

### Phase 1: Engine Stability & Boot Recovery
1. **Fix `scenes/main.tscn`**:
   - Restore valid `.tscn` quoting syntax or extract arena setup logic into a dedicated script `scripts/main.gd`.
   - Remove corrupted trailing duplicate blocks.
   - Verify `godot --headless --path . scenes/main.tscn --quit` exits with code 0.
2. **Correct CPUParticles2D Properties**:
   - Replace `pre_process_time` with `preprocess` in `scripts/coin.gd`, `scripts/gem.gd`, and `scenes/main.tscn`.

### Phase 2: Headless CI Harness Fixes
1. **Fix `tests/test_zombie_world.gd`**:
   - Append `get_tree().quit(_exit_code())` at the completion of `_ready()`.
   - Verify `test_zombie_world.tscn` finishes in <2 seconds.

### Phase 3: Mode Isolation & Save Data Preservation
1. **Refactor `GameManager.load_save_data()`**:
   - Preserve `selected_stage` if explicitly configured or running in test harness mode.
   - Default new players/first-time runs to `"zombie_city"` and `"swat"` without overriding explicit runtime stage selections.
2. **Context-Aware Weapon & HUD Display**:
   - Allow `loc.gd` or `GameManager.get_weapon_display_name()` to resolve zombie names when in Zombie Outbreak mode, while preserving legacy string accessors for test suites.

### Phase 4: Full CI Validation
1. Execute `./scripts/ci.sh` across all 65 test suites.
2. Target: **65 / 65 passing suites green** with zero hangs.

### Phase 5: Pull Request & Remote Sync
1. Apply fixes to `fix/zombie-outbreak-default` (or merge forward into master).
2. Push commits to `origin`.
3. Update GitHub PR #1 with verification report.

---

*Authored: 2026-11-18*
