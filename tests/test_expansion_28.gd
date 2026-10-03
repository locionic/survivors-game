extends Node

## Automated Test Suite for Expansion 28.0:
## "Kim Thiềm" -- the Codex quest that paid out nothing, permanently.
##
## Every quest's reward_type and every arm of _apply_reward() are typed by hand, and
## the match had no default branch. The quest "Vạn Tiền Đại Phú" (rich_master) declared
##
##     "reward_type": "gold_drop_buff"
##
## while the handler spelled the same arm
##
##     "gold_drop_mult": bonus_gold_drop_mult += float(r_val)
##
## Those were the only two spellings in the file and the field bonus_gold_drop_mult is
## used consistently on both the read side (game_manager.gd, in add_gold) and the rest of
## codex_manager.gd, so the handler's spelling was always the intended one. The effect:
## accumulate 2,500 lifetime gold, claim "+30% gold drop value", receive nothing, and see
## no error -- because an unmatched match arm is a no-op, not a failure.
##
## Nothing in the save carries the damage. save_codex_data() persists only
## id/progress/unlocked/claimed, and load_codex_data() re-matches each saved row by id
## back into this file's live quests array, so reward_type is read from source on every
## launch. Fixing the data was therefore enough to reach saves that already exist.
##
## The check below walks every quest against the handler's arm names, which is a
## foreign key between two lists that used to be able to disagree silently. It covers
## the data->handler direction. The reverse -- someone renaming an arm in the handler --
## is covered at runtime instead, by the push_error on the match's default branch, which
## is the one place both directions meet.

## The arm names of _apply_reward() in codex_manager.gd. Duplicated deliberately: this
## suite is the half that cannot notice a rename, so it states the contract explicitly
## rather than inferring it.
const HANDLED_REWARD_TYPES: Array[String] = [
	"gold",
	"speed_buff",
	"attack_speed_buff",
	"gold_drop_mult",
	"start_pearl",
	"relic",
]

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

## This suite calls _apply_reward() directly, never claim_reward(). That is the whole
## reason it needs no save backup: claim_reward() is what persists (save_codex_data) and
## emits signals, and neither is under test here. Only the one in-memory float is
## snapshotted, and it is restored below.
var _gold_mult_backup: float = 0.0

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 28.0 TEST SUITE ===")
	GameManager.is_run_active = false
	_gold_mult_backup = CodexManager.bonus_gold_drop_mult

	_test_every_quest_names_a_reward_type_the_handler_knows()
	_test_the_gold_quest_actually_pays_out()
	_test_the_whole_quest_list_still_loads_as_valid_data()

	CodexManager.bonus_gold_drop_mult = _gold_mult_backup

	if _failures.is_empty():
		print("=== ALL EXPANSION 28.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the foreign key, over every quest rather than the one that broke --------

## Walking the list is the point. Checking rich_master by id would have gone green the
## moment that one string was corrected and stayed green through the next typo.
func _test_every_quest_names_a_reward_type_the_handler_knows() -> void:
	check(not CodexManager.quests.is_empty(), "Precondition: the Codex has quests")

	var unguarded: Array[String] = []
	for q in CodexManager.quests:
		var r_type := str(q.get("reward_type", ""))
		if not HANDLED_REWARD_TYPES.has(r_type):
			unguarded.append("%s(%s)" % [q.get("id", "?"), r_type])
		else:
			check(q.has("reward_val"), "Quest %s grants a type with no reward_val" % q.get("id", "?"))

	check(unguarded.is_empty(),
		"Every quest names a reward_type the match has an arm for, these do not: %s"
			% ", ".join(unguarded))

# --- 2. and the one that broke actually pays out -------------------------------

func _test_the_gold_quest_actually_pays_out() -> void:
	var quest: Dictionary = {}
	for q in CodexManager.quests:
		if str(q.get("id", "")) == "rich_master":
			quest = q
			break
	if not check(not quest.is_empty(), "Precondition: the Codex has the rich_master quest"):
		return

	# The advert says +30% and the handler accumulates, so the field has to start above
	# the point where adding 0.30 is even a gain. Pinned because add_gold() gates the
	# whole bonus on `> 1.0`: a default that dropped to 0.0 would leave this test's
	# delta assertion satisfied while the player still collected normal gold.
	CodexManager.bonus_gold_drop_mult = 1.0
	check(is_equal_approx(CodexManager.bonus_gold_drop_mult, 1.0),
		"Precondition: the gold multiplier is neutral before the reward")

	# Deep-copied so the suite cannot leave the live quest's own state behind, even
	# though _apply_reward() only reads it.
	CodexManager._apply_reward(quest.duplicate(true))

	var expected: float = 1.0 + float(quest.get("reward_val", 0.0))
	check(is_equal_approx(CodexManager.bonus_gold_drop_mult, expected),
		"Claiming Vạn Tiền Đại Phú raises the gold multiplier to %s, got %s"
			% [expected, CodexManager.bonus_gold_drop_mult])

	# The delta and the consequence are separate claims. A multiplier that moved but sat
	# at or below 1.0 would be the identical silent no-op this fix is about.
	check(CodexManager.bonus_gold_drop_mult > 1.0,
		"The claimed bonus is above the 1.0 that add_gold() tests for, got %s"
			% CodexManager.bonus_gold_drop_mult)

	# Accumulating, not assigning: two claims' worth of the bonus must not be 1.30.
	CodexManager._apply_reward(quest.duplicate(true))
	check(is_equal_approx(CodexManager.bonus_gold_drop_mult, 1.0 + 0.30 * 2.0),
		"The bonus accumulates rather than overwriting, got %s" % CodexManager.bonus_gold_drop_mult)

# --- 3. and every quest in the list is still well-formed ------------------------

## The two lists agreeing is necessary but not sufficient -- the arm has to write
## something add_gold() actually consults. This is the cheap half of the end-to-end:
## exercising add_gold() would call save_game_data() and rewrite the developer's save
## file, which is a far bigger claim to make for a two-line consumer.
func _test_the_whole_quest_list_still_loads_as_valid_data() -> void:
	var seen_ids: Dictionary = {}
	for q in CodexManager.quests:
		var q_id := str(q.get("id", ""))
		check(not seen_ids.has(q_id), "Quest id '%s' is unique" % q_id)
		seen_ids[q_id] = true
		check(str(q.get("title", "")) != "", "Quest %s has a title" % q_id)
		check(str(q.get("reward_desc", "")) != "", "Quest %s advertises its reward" % q_id)
		check(int(q.get("target", 0)) > 0, "Quest %s has a reachable target" % q_id)
