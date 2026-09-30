extends Node

## Task #20 -- the codex re-applied every claimed quest's reward on load.
##
## Both load paths called _apply_reward() for each already-claimed quest, and the
## "gold" branch calls GameManager.add_gold(). slay_500 is worth 600 meta gold,
## so the player's wallet grew by exactly 600 on every single launch, forever.
## The claimed flag was already the correct guard; the re-apply bypassed it.
##
## The fix separates the two jobs load was conflating: it restores persistent
## modifiers (from the save's "global" section / the save dict's bonus_* keys)
## but never pays a one-time reward. Restoring must be idempotent, so these
## tests assert exact numbers rather than merely "it did not crash".

## Godot's assert() only logs a SCRIPT ERROR and keeps running -- the process
## still exits 0, so a suite built on it can never fail a regression run. This
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## claim_reward() and add_gold() persist immediately, and so does
## reset_codex_data(). Both saves are backed up byte-for-byte before the suite
## and restored after, so running the tests cannot touch the developer's own
## progress -- including the codex, which the other suites also mutate.
const CODEX_PATH: String = "user://codex_data.cfg"
const CODEX_BACKUP: String = "user://codex_data.cfg.codexbak"
const SAVE_PATH: String = "user://save_data.cfg"
const SAVE_BACKUP: String = "user://save_data.cfg.codexbak"

const GOLD_QUEST: String = "slay_500"
const GOLD_REWARD: int = 600

var _relics_backup: Array = []
var _had_codex: bool = false
var _had_save: bool = false

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

# --- save isolation --------------------------------------------------------

func _backup(path: String, backup: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var src := FileAccess.open(path, FileAccess.READ)
	var dst := FileAccess.open(backup, FileAccess.WRITE)
	dst.store_buffer(src.get_buffer(src.get_length()))
	src.close()
	dst.close()
	return true

func _restore(path: String, backup: String) -> void:
	if not FileAccess.file_exists(backup):
		return
	var src := FileAccess.open(backup, FileAccess.READ)
	var dst := FileAccess.open(path, FileAccess.WRITE)
	dst.store_buffer(src.get_buffer(src.get_length()))
	src.close()
	dst.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))

## add_gold() multiplies by three optional player-state boosts (the golden
## horseshoe relic, blood moon, and the codex's own gold-drop multiplier). Pin
## them all off so a claim pays exactly reward_val rather than 600x something
## the developer happened to have equipped.
func _pin_gold_math() -> void:
	_relics_backup = GameManager.collected_relics.duplicate()
	GameManager.collected_relics.erase("golden_horseshoe")
	GameManager.is_blood_moon = false
	check(CodexManager.bonus_gold_drop_mult == 1.0,
		"Precondition: no gold-drop multiplier, got %f" % CodexManager.bonus_gold_drop_mult)

func _unpin_gold_math() -> void:
	GameManager.collected_relics = _relics_backup

# --- 1. the one-time payout is still paid, and only once ------------------

## The fix must not have cured the bug by suppressing the reward. A fresh claim
## still pays 600; a repeat claim of the same quest is refused and pays nothing.
func _test_claim_pays_exactly_once() -> void:
	CodexManager.reset_codex_data()
	_pin_gold_math()
	GameManager.total_gold = 1000

	CodexManager.report_stat("cumulative_kills", 500)
	check(bool(CodexManager.get_quest(GOLD_QUEST)["unlocked"]),
		"slay_500 unlocks at 500 cumulative kills")
	check(not bool(CodexManager.get_quest(GOLD_QUEST)["claimed"]),
		"A freshly unlocked quest starts unclaimed")

	var claimed: bool = CodexManager.claim_reward(GOLD_QUEST)
	check(claimed, "claim_reward(slay_500) succeeds on a fresh unlock")
	check(GameManager.total_gold == 1000 + GOLD_REWARD,
		"The fresh claim pays exactly %d, wallet went 1000 -> %d"
			% [GOLD_REWARD, GameManager.total_gold])
	check(bool(CodexManager.get_quest(GOLD_QUEST)["claimed"]),
		"claim_reward() flags the quest claimed")

	var again: bool = CodexManager.claim_reward(GOLD_QUEST)
	check(not again, "A second claim_reward(slay_500) on the same quest is refused")
	check(GameManager.total_gold == 1000 + GOLD_REWARD,
		"The refused claim pays nothing, wallet is %d" % GameManager.total_gold)
	print("✔ A fresh claim pays 600 once; the duplicate claim is refused for free.")

# --- 2. THE REGRESSION: loading must not pay -------------------------------

## This is the bug. The save on disk now has slay_500 claimed. Booting the game
## twice more must not move the wallet -- before the fix each load added 600.
func _test_load_does_not_pay_gold() -> void:
	var before: int = GameManager.total_gold
	check(bool(CodexManager.get_quest(GOLD_QUEST)["claimed"]),
		"Precondition: the save has slay_500 marked claimed")

	for pass_num in range(1, 3):
		CodexManager.load_codex_data()
		check(GameManager.total_gold == before,
			"Load %d of an already-claimed slay_500 leaves the wallet at %d, got %d"
				% [pass_num, before, GameManager.total_gold])
		check(CodexManager.claimed_count >= 1,
			"Load %d still counts the claim (claimed_count is %d)"
				% [pass_num, CodexManager.claimed_count])
	print("✔ Two consecutive loads of a claimed save leave the wallet untouched.")

# --- 3. the load still restores what it is supposed to ---------------------

## The re-apply was deleted, not replaced with a no-op: the permanent modifiers
## the codex owns must still come back, or the fix would have silently stripped
## every claimed buff. Restoring is a read of the save, not a fresh award.
func _test_permanent_bonuses_restored_on_load() -> void:
	CodexManager.report_stat("time", 200)       # survive_3m  -> +15 base speed
	CodexManager.report_stat("run_kills", 1500)  # slay_1500   -> +20% attack speed
	check(CodexManager.claim_reward("survive_3m"), "survive_3m claims cleanly")
	check(CodexManager.claim_reward("slay_1500"), "slay_1500 claims cleanly")
	check(CodexManager.bonus_speed == 15.0,
		"Claiming survive_3m adds its +15 speed, got %f" % CodexManager.bonus_speed)

	var gold_before: int = GameManager.total_gold
	CodexManager.load_codex_data()

	check(CodexManager.bonus_speed == 15.0,
		"Loading restores the +15 speed bonus, got %f" % CodexManager.bonus_speed)
	check(CodexManager.bonus_attack_speed == 0.20,
		"Loading restores the +20%% attack-speed bonus, got %f" % CodexManager.bonus_attack_speed)
	check(CodexManager.claimed_count == 3,
		"Loading recounts all three claims, got %d" % CodexManager.claimed_count)
	check(GameManager.total_gold == gold_before,
		"Restoring the bonuses still pays no gold, wallet moved %d -> %d"
			% [gold_before, GameManager.total_gold])
	print("✔ Speed and attack-speed bonuses are still restored on load, for free.")

# --- 4. the same regression on the web/localStorage branch -----------------

## The web branch is unreachable headlessly, but _apply_save_dict() is a plain
## method over a plain Dictionary, so the identical regression can be driven
## straight into it. Without this, the second half of the fix would be untested.
func _test_web_save_dict_does_not_pay_gold() -> void:
	var gold_before: int = GameManager.total_gold
	CodexManager._apply_save_dict({
		"quests": [
			{"id": GOLD_QUEST, "progress": 500, "unlocked": true, "claimed": true},
			{"id": "survive_3m", "progress": 200, "unlocked": true, "claimed": true},
			{"id": "kill_boss", "progress": 1, "unlocked": true, "claimed": true},
		],
		"bonus_speed": 15.0,
		"bonus_attack_speed": 0.2,
		"bonus_gold_drop_mult": 1.0,
		"bonus_starting_pearls": 0,
		"unlocked_relic_keys": ["drunken_gourd"],
	})

	check(GameManager.total_gold == gold_before,
		"The web save-dict path does not re-pay slay_500's %d gold, wallet moved %d -> %d"
			% [GOLD_REWARD, gold_before, GameManager.total_gold])
	check(CodexManager.bonus_speed == 15.0,
		"The web path still restores bonus_speed, got %f" % CodexManager.bonus_speed)
	check(CodexManager.bonus_attack_speed == 0.2,
		"The web path still restores bonus_attack_speed, got %f" % CodexManager.bonus_attack_speed)
	check(CodexManager.claimed_count == 3,
		"The web path still counts every claim, got %d" % CodexManager.claimed_count)
	check(CodexManager.unlocked_relic_keys.has("drunken_gourd"),
		"The web path still registers claimed relics")
	print("✔ The localStorage branch restores modifiers without re-paying gold.")

# --- run -------------------------------------------------------------------

func _ready() -> void:
	_had_codex = _backup(CODEX_PATH, CODEX_BACKUP)
	_had_save = _backup(SAVE_PATH, SAVE_BACKUP)
	print("=== RUNNING CODEX SAVE REGRESSION TEST SUITE ===")

	_test_claim_pays_exactly_once()
	_test_load_does_not_pay_gold()
	_test_permanent_bonuses_restored_on_load()
	_test_web_save_dict_does_not_pay_gold()

	_unpin_gold_math()
	if _had_codex:
		_restore(CODEX_PATH, CODEX_BACKUP)
	if _had_save:
		_restore(SAVE_PATH, SAVE_BACKUP)

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL CODEX SAVE REGRESSION TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)
