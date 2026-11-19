# Standing Game-Dev Plan — both repos

Written after auditing every plan file in this repo. The audit overturned the
premise of the earlier ones: most unchecked items are **already implemented**,
not backlog. Only the sections marked OPEN below are real outstanding work.

## The rule this plan exists to enforce

**Never queue a task from an unchecked checkbox.** Checkboxes in
`GAME_DESIGN_PLAN.md`, `PHASE_2_ENHANCEMENT_PLAN.md`,
`PHASE_3_IMPLEMENTATION_PLAN.md` and `VIETNAMESE_COOKING_PLAN.md` were never
maintained. Seeding the queue from them makes an unattended agent
re-implement working systems, burn its test budget, and commit churn.

Verified stale at time of writing:

| Item | Checkbox said | Reality |
|---|---|---|
| XP / leveling | not done | `SaveManager`, `LevelSystem` present and green |
| Mood / ambience | not done | spread across 41 files |
| Vietnamese cooking | not done | `minigame_manager.gd`, `test_vietnamese_cooking.gd` both green |

`SURVIVORQUEST_ENHANCEMENT_PLAN.md` — **4/4 DONE**, verified in code:
- Task 1 localization: keys are dotted (`bounty.slay_bats.title`,
  `landmark.fountain.name`), *not* the plan's underscore names. All 4 bounty +
  4 landmark VI strings present.
- Task 2 HUD: `hud.level_up` in `loc.gd`.
- Task 3 Chrono: `run_attack_speed_penalty` is a separate float from
  `CHRONO_COOLDOWN_FLOOR`. The conflict the plan describes is resolved.
- Task 4 syncfs: `is_syncing_filesystem` guard at `game_manager.gd:476`.

The residual `"Thousand Daggers"` at `upgrade_manager.gd:146` is **not** a gap.
It is a documented offline fallback, and a regression suite asserts it stays
byte-identical to `Loc.STRINGS["weapon.dagger.name"]["en"]` so the two tables
cannot drift. Do not "localize" it.

---

## Visual Rebirth Status — SurvivorQuest (Martial Arts Mode)

`SURVIVORQUEST_VISUAL_REBIRTH_PLAN.md` audited and completed:

DONE (100% Complete)
- [x] P1 four-tier rarity borders (`TIER_COLORS`, `upgrade_manager.gd`)
- [x] P1 card hover/selection juice — lift (+12px, 1.05 scale), epic pulse aura, legendary ember motes, qi burst on select, ui_hover sound
- [x] P2 arena theming: bamboo, moss, guardian lions, red lanterns, floating leaf `CPUParticles2D` (`main.tscn`, `scripts/main.gd`, assets generated & imported)
- [x] P2 boss entrance banner `⚠️ MA GIÁO XUẤT HIỆN` + gong (dramatic crimson lacquer banner, gold border, gong SFX in `hud.gd`)
- [x] P2 XP gem / coin magnet arcs (`MagnetTrail` in `gem.gd` and `coin.gd` with `local_coords = false`)
- [x] P3 HUD lacquer weapon + relic slots (6 circular lacquer weapon medallions with pips, 6 square lacquer relic slots in `hud.gd` & `main.tscn`)
- [x] P3 Streamlined Dragon Qi HP bar & glowing Jade XP bar in `hud.gd`

---

## ACTIVE ARCHITECTURE & ROADMAP: Project Z-Survivor (Zombie Outbreak Mode)

The project has transitioned to **Zombie Outbreak** as its primary default theme and game mode (`selected_stage = "zombie_city"`, default class = `"swat"`), while preserving full backwards compatibility with the Wuxia Martial Arts mode.

### Dual-Theme Architecture
1. **Primary Default (Zombie Outbreak)**:
   - **Stage**: Zombie City Quarantine Zone (dark asphalt tiles, biohazard waste, barricades).
   - **Survivors**: SWAT Operative, Field Medic, Hazard Scout, Pyro Specialist, Biker Rebel.
   - **Enemies**: Walkers, Runners (ambush ring), Bloaters, Toxic Spitters, Mutant Juggernauts.
   - **Pickups**: Bio-Vials (XP), Medical Packs (HP), Ammo Caches, Gold/Bounty credits.
   - **HUD / UI**: Tactical dossier screen, biohazard alert banners (`☣️ BIO-THREAT APPROACHING: %s ☣️`).

2. **Alternate Stage (Võ Lâm / Martial Arts)**:
   - Preserved for legacy and alternate stage selection (ancient stone tiles, bamboo reeds, guardian lions, red lanterns, qi cultivation).

### Completed Zombie Outbreak Milestones
- [x] Zombie Outbreak PR #1 remediation & stabilization:
  - Fixed GDScript parse syntax in `main.tscn` and extracted clean scene logic into `scripts/main.gd`.
  - Corrected `CPUParticles2D` property compatibility (`preprocess` for Godot 4.3).
  - Headless CI teardown fixed in `tests/test_zombie_world.gd`.
  - Save data default isolation in `GameManager.load_save_data()`.
  - 65/65 test suites green (`GATE PASSED`).
- [x] Tactical Zombie Dossier UI (`scenes/zombie_dossier_ui.tscn`, `scripts/zombie_dossier_ui.gd`).
- [x] Bio-vial XP pickups and zombie audio sfx (gunshots, groans, hits).
- [x] **Milestone 1: Tactical Weapon Reskin & Modern Arsenal Evolutions**:
  - Contextual weapon display names and tactical sprites when playing in Zombie City:
    - Dagger -> Tactical Pistol (`weapon.dagger.name`), evolved to Minigun Barrage (`evo.dagger.name`). Uses `bullet.png`.
    - Shield -> Riot Shield Orbit (`weapon.shield.name`), evolved to Bio-Barrier Array (`evo.shield.name`). Custom pixel textures `riot_shield.png` and `bio_barrier.png`.
    - Lightning -> Tesla Arc Coil (`weapon.lightning.name`), evolved to EMP Storm Grid (`evo.lightning.name`). Cyan/electric blue arcs with EMP particle bursts.
    - Fireball -> Molotov Launcher (`weapon.fireball.name`), evolved to Napalm Strike (`evo.fireball.name`). Custom pixel textures `molotov.png` and `napalm_strike.png`.
    - Axe -> Frag Grenade (`weapon.axe.name`), evolved to Cluster Warhead (`evo.axe.name`). Custom pixel textures `frag_grenade.png` and `cluster_warhead.png`.
    - Slash -> Combat Machete (`weapon.slash.name`), evolved to Chainsaw Ripper (`evo.slash.name`). Custom pixel texture `combat_machete.png` with metallic/bloody slash modulation.
  - Context-aware upgrade card titles, descriptions, and icons (`🔫`, `🛡️`, `⚡`, `💣`, `🧨`, `🔪`, `🧲`, `🏃`, `💉`, `☣️`) in `UpgradeManager`.
  - Contextual HUD lacquer badges with firearm icons in `scripts/hud.gd`.
  - Comprehensive automated test suite `tests/test_zombie_arsenal.tscn` (all assertions verified green).

- [x] **Milestone 2: Quarantine Arena Props & Destructibles (Viral Chain Reactions)**:
  - Concrete Jersey barriers (`assets/textures/jersey_barrier.png`) establishing tactical street choke points and bottlenecks.
  - Explosive Hazard Drums (`assets/textures/explosive_barrel.png`, `scenes/explosive_barrel.tscn`, `scripts/explosive_barrel.gd`):
    - 320 AoE damage to horde, screen shake, fiery particle shockwave.
    - **Cascading Chain Reaction system**: Nearby barrels prime and detonate in 0.12s domino sequences!
    - Permanent charred blast craters on asphalt (`assets/textures/charred_crater.png`) and bonus bio-vial loot.
- [x] **Milestone 3: Emergency Airdrop Event System & Adrenaline Overdrive**:
  - Timed parachute supply drops (`assets/textures/airdrop_crate.png`, `scenes/airdrop_crate.tscn`, `scripts/airdrop_crate.gd`):
    - Green signal smoke flare descent.
    - Instant screen-clearing tactical bio-purge strike (450 AoE damage).
    - 12 seconds of **Adrenaline Overdrive** (+75% attack speed, +35% move speed) and +60 gold credits.
  - Viral Kill Streak Announcer banners for `zombie_city` ("HORDE MASSACRE!", "BIO-CONTAMINATOR!", "APOCALYPSE REAPER!", "UNSTOPPABLE SLAYER!", "GOD OF SURVIVORS!").
  - Automated test suite `tests/test_zombie_viral_features.tscn` (100% green).

- [x] **Milestone 4: Bio-Contamination, Toxic Sludge & Mutant Apex Bosses**:
  - Persistent corrosive toxic bile puddles (`assets/textures/toxic_bile_puddle.png`, `scenes/toxic_bile_puddle.tscn`, `scripts/toxic_bile_puddle.gd`):
    - Left behind by ruptured Bloaters and Toxic Spitters on death.
    - Sizzling acid bubbling particle FX, tick damage (4.0/0.5s), and -20% toxic movement slow debuff on players without immunity.
    - **Interactive Neutralization Synergy**: Explosive barrels detonating near toxic sludge incinerate the bile into harmless vapor!
  - Toxic Spitter mutant ranged enemy (`assets/textures/zombie_spitter.png`, `scenes/zombie_spitter.tscn`):
    - Fires corrosive toxic globs (`assets/textures/toxic_glob.png`, `scenes/toxic_projectile.tscn`) that splash into bile puddles.
  - Mutant Juggernaut & Bio-Titan Apex Bosses (`assets/textures/mutant_juggernaut.png`, `assets/textures/bio_titan.png`, `scenes/mutant_juggernaut.tscn`, `scenes/bio_titan.tscn`):
    - Custom high-res pixel art models for the Quarantine Zone's mid-bosses and final apocalypse titan.
  - Automated test suite `tests/test_zombie_bio_contamination.tscn` (100% green, 68/68 gate passed).

### Upcoming Opportunities & Future Polish
- [ ] Viral Audiovisual Juice: Cinematic slow-mo hitstop moments on boss defeats, bass-boosted impact sounds.
- [ ] Helicopter Extraction Minigame: High-stakes 30-second evac zone event at final wave survival.

**Sequencing constraint.** P2 is one task, not five. Arena props touch
`arena.tscn` and `arena.gd` together; splitting them puts five agents in the
same branch across five branches, and only one merge survives.

**Hard constraint on all five:** 63/63 `./scripts/ci.sh` green, and the
browser build must not regress. A visual task that drops a frame budget or
breaks a suite is reverted by `fcc-task` like any other.

## OPEN — first-vibecode-game

Gate hole closed (task 2, commit `00ddff1`): `test_playthrough.gd` counted
failures but called `quit()` with no argument, i.e. `quit(0)` — it could print
`FAIL: N` and still pass the gate. It is demoted out of `run_tests.sh`'s
`PROBES` until the suite's assertions are trustworthy.

Unresolved: the CI flake hunt. Measured rate is **1 failure in 17 runs**, not
1 in 5. Not yet identified. Task 4's original premise was wrong and has been
rewritten.

---

## Environment trap that will burn the next agent

`.godot/` is **gitignored**. A fresh `git clone` of either repo cannot run its
suite — every harness fails, because nothing has been imported. Copy the cache
in from a working tree first, or use the real working tree.

Even then a clone is not a faithful environment (measured: 48 passed / 5
failed against a tree that is 52/52 green in place). **Verify in the working
tree.** Do not publish a pass/fail claim from a clone.

## Standing rule

Nothing here is merged automatically. `fcc-task` gives every task its own
branch, runs the repo's suite, and reverts on red. Merging stays a human
decision, made with the tests already run.
