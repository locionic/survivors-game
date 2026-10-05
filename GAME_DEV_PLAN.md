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

## OPEN — SurvivorQuest visual rebirth

`SURVIVORQUEST_VISUAL_REBIRTH_PLAN.md` is the one plan file with real work in
it. Audited by grep against the source:

DONE
- [x] P1 four-tier rarity borders (`TIER_COLORS`, `upgrade_manager.gd`)

NOT DONE
- [ ] P1 card hover/selection juice — lift, scale, gold chime, qi burst
- [ ] P2 arena theming: bamboo, moss, guardian lions, red lanterns,
      floating leaf `CPUParticles2D` (zero hits for all five)
- [ ] P2 boss entrance banner `⚠️ MA GIÁO XUẤT HIỆN` + gong (zero hits)
- [ ] P2 XP gem / coin magnet arcs
- [ ] P3 HUD lacquer weapon + relic slots (only text `equipment_slots`
      iteration exists at `hud.gd:1007`)

**Sequencing constraint.** P2 is one task, not five. Arena props touch
`arena.tscn` and `arena.gd` together; splitting them puts five agents in the
same scene file across five branches, and only one merge survives.

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