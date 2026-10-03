extends Node

## Automated Test Suite for Expansion 36.0:
## "Điểm x11.0" -- the difficulty tier's score multiplier, promised on the
## character-select screen and never read again.
##
## The DANGER table in game_manager.gd carries six keys. Five of them do something:
##
##     speed  x1.00 .. x1.60   EnemySpawner._apply_danger()
##     hp     x1.00 .. x3.00   EnemySpawner._apply_danger()
##     elite  0 .. 2           the elite-champion spawn count
##     heal   x1.00 .. x0.60   the heal between waves
##     score  x1.0  .. x11.0   <-- read once, at character select, to be printed
##
## character_select_ui.gd:160 builds the tier's promise from three of them and shows
## the player the exact result:
##
##     Loc.tf("danger.desc", [hp * 100, speed * 100, d["score"]])
##     -> "Enemy HP 300% - Speed 160% - Score x11.0"
##
## So on Tuyệt Thế, the screen that decides whether you start the run says the run
## is worth eleven times as much, and the leaderboard has no idea. calculate_score()
## is the raw formula, and its only caller is submit_run(), which the game-over path
## (hud.gd:1040) and the victory path (hud.gd:1079) both go through -- neither of
## which multiplies. A player who picked the hardest tier for the eleven-times board
## finished with precisely the Novice's number, on the fight the whole ladder exists
## to be worth surviving.
##
## The fix goes in submit_run(), not calculate_score(). calculate_score() stays the
## raw formula so a caller that has already scaled cannot be scaled twice, and so
## test_expansion_14's assertion on 8000 for (100, 50, 200, 2) still means what it
## says. Case 3 is the ordering hazard, the same shape as Expansion 35's elite.

const RAW_RUN_TIME: float = 1800.0
const RAW_KILLS: int = 3000
const RAW_GOLD: int = 5000
const RAW_SCROLLS: Array = ["dichcankinh", "lucmach", "thaicuc"]
## Novice, whose multiplier is the identity -- so "the formula still holds at the
## bottom of the ladder" is a statement about the number, not a tautology.
const BOTTOM_TIER: int = 0
const TOP_TIER: int = 5

const SAVE_PATH: String = "user://save_data.cfg"
const BOARD_PATH: String = "user://leaderboard_data.cfg"

var _failures: Array[String] = []
var _submits: int = 0
var _save: Dictionary = {}
var _board: Dictionary = {}
var _danger_backup: int = 0

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 36.0 TEST SUITE ===")
	GameManager.is_run_active = false
	_danger_backup = GameManager.danger_level
	# Two files, both written by the calls under test. save_data.cfg because
	# _pay_daily_reward() pays meta gold out of it; leaderboard_data.cfg because
	# every submit_run() persists one. Both are restored byte for byte at teardown.
	_save = _grab(SAVE_PATH)
	_board = _grab(BOARD_PATH)

	LeaderboardManager.reset_leaderboard_data()
	# The daily trial pays gold on the first run of a day. Scoring is the subject
	# here, not the payout, and the payout is the only thing that touches the other
	# file -- so the flag is set rather than the reward neutralised. The high score
	# in case 4 is still updated, because the flag guards the payout and not the
	# comparison that updates it.
	LeaderboardManager.daily_completed = true

	_test_the_tier_multiplies_the_score()
	_test_the_bottom_tier_is_the_raw_formula()
	_test_the_multiplier_is_applied_once()
	_test_the_daily_high_score_carries_it_too()
	_test_the_promise_on_screen_is_the_number_applied()

	_finish()

# --- 1. the multiplier, as a ratio ---------------------------------------------

## Stated as a comparison between two identical runs at opposite ends of the ladder
## rather than as a number, because a run's score moves with every stat the player
## touches -- kills, gold, scrolls -- and pinning the absolute value would make this
## a balance test that breaks every time a reward is rebalanced. Only the ratio is a
## promise the game actually makes.
func _test_the_tier_multiplies_the_score() -> void:
	GameManager.danger_level = BOTTOM_TIER
	var bottom := _submit()
	GameManager.danger_level = TOP_TIER
	var top := _submit()

	if check(bottom > 0, "A tier-%d run scored something: %d" % [BOTTOM_TIER, bottom]):
		var want := float(GameManager.get_danger_data().get("score", 1.0))
		var got := float(top) / float(bottom)
		check(is_equal_approx(got, want),
			"The same run on tier %d scores %s times a tier-%d run: %d vs %d where the tier promises x%.1f"
				% [TOP_TIER, got, BOTTOM_TIER, top, bottom, want])

# --- 2. the ladder's bottom rung is untouched ----------------------------------

## The regression guard. Every leaderboard entry in the game was written by this
## formula, and every number already banked was banked under x1.0 -- so if the
## multiplier ever reached into calculate_score() instead of submit_run(), the
## canonical Novice score would move and every stored run would be wrong by a factor
## of the tier it was earned on.
func _test_the_bottom_tier_is_the_raw_formula() -> void:
	# 1800*12 + 3000*28 + 5000*2 + 3*2500 = 21600 + 84000 + 10000 + 7500
	var raw := LeaderboardManager.calculate_score(RAW_RUN_TIME, RAW_KILLS, RAW_GOLD, RAW_SCROLLS.size())
	check(raw == 123100, "The raw formula still reads 123100, got %d" % raw)

	GameManager.danger_level = BOTTOM_TIER
	var submitted := _submit()
	check(submitted == raw,
		"A tier-%d run is banked at the raw formula, unscaled: %d where the formula says %d"
			% [BOTTOM_TIER, submitted, raw])

# --- 3. applied once -----------------------------------------------------------

## The ordering hazard. The multiplier could land on the formula, on the entry after
## it is built, and on the daily high score as well as the entry -- and two of those
## three compound. A tier-5 run submitted through both would be 121x, which still
## sorts correctly and still looks like a big number, so nothing would look broken.
## The ratio in case 1 is what catches it.
func _test_the_multiplier_is_applied_once() -> void:
	GameManager.danger_level = TOP_TIER
	var top := _submit()
	var want := _scaled(RAW_RUN_TIME, RAW_KILLS, RAW_GOLD, RAW_SCROLLS.size())
	check(is_equal_approx(float(top), want),
		"The tier-%d run is the formula scaled once: %d where %d is expected, not %d (applied twice)"
			% [TOP_TIER, top, int(want), int(want * float(GameManager.get_danger_data()["score"]))])

	# And the board agrees with the submissions: one entry per submit, no more. Every
	# run here carries identical stats, so a duplicate would sit invisibly alongside
	# its twin on the table and inflate the player's rank count without changing any
	# score -- which no single-entry check would notice.
	var banked := 0
	for e in LeaderboardManager.tournament_entries:
		if e.get("is_player", false):
			banked += 1
	check(banked == _submits,
		"%d submissions banked %d entries: exactly one each" % [_submits, banked])

# --- 4. the daily board, which is the same number and has to agree ---------------

## daily_high_score is written from the same total_score, a few lines below, so it is
## covered by the same fix -- but it is the number the daily trial gates its reward
## on, so a run that scored 11x on the tournament board and 1x on the daily one would
## read as a worse run than it was.
func _test_the_daily_high_score_carries_it_too() -> void:
	GameManager.danger_level = TOP_TIER
	var top := _submit()
	GameManager.danger_level = BOTTOM_TIER
	var bottom := _submit()
	check(int(LeaderboardManager.daily_high_score) == top,
		"The daily high score is the tier-%d run: %d where that run scored %d"
			% [TOP_TIER, LeaderboardManager.daily_high_score, top])
	check(int(LeaderboardManager.daily_high_score) > bottom,
		"The daily high score kept the bigger of the two: %d, not the tier-%d run's %d"
			% [LeaderboardManager.daily_high_score, BOTTOM_TIER, bottom])

# --- 5. the promise on screen is the number applied -----------------------------

## The one that matters. Every other case pins a number; this pins the number to the
## string the player actually read, by building that string through the same Loc entry
## character_select_ui.gd uses and parsing the multiplier back out of it. So if the
## DANGER table is rebalanced, or the desc string is edited, or the three arguments
## are passed in a different order, this fails -- instead of the two halves of the
## promise drifting apart in silence, which is the bug itself.
func _test_the_promise_on_screen_is_the_number_applied() -> void:
	GameManager.danger_level = BOTTOM_TIER
	var bottom := _submit()
	GameManager.danger_level = TOP_TIER
	var top := _submit()

	var d := GameManager.get_danger_data()
	var shown: String = Loc.tf("danger.desc", [
		int(float(d["hp"]) * 100.0), int(float(d["speed"]) * 100.0), float(d["score"])])
	var advertised := _multiplier_in(shown)
	if not check(advertised > 0.0, "The screen states a multiplier: \"%s\"" % shown):
		return
	if bottom <= 0:
		return
	var applied := float(top) / float(bottom)
	check(is_equal_approx(applied, advertised),
		"The tier promises \"%s\" and delivers x%.2f: the string and the score have drifted apart"
			% [shown, applied])

# --- helpers -------------------------------------------------------------------

## Submit one run at the current tier and read back the score of *that* run, found
## by reference identity against a snapshot of the board taken beforehand. Not off the
## rank, and not off the top of the table: the board is sorted descending on every
## submit, so once an 11x run is on it, the 1x run submitted after it does not lead --
## and every run here carries the same stats, so they cannot be told apart by value.
func _submit() -> int:
	var before := LeaderboardManager.tournament_entries.duplicate()
	LeaderboardManager.submit_run("beggar", RAW_RUN_TIME, RAW_KILLS, RAW_GOLD, RAW_SCROLLS)
	_submits += 1
	for e in LeaderboardManager.tournament_entries:
		var known := false
		for b in before:
			if is_same(e, b):
				known = true
				break
		if not known:
			return int(e.get("score", 0))
	_failures.append("submit_run() banked nothing at tier %d" % GameManager.danger_level)
	push_error("CHECK FAILED: submit_run() banked nothing at tier %d" % GameManager.danger_level)
	return -1

## What the tier promises, as a number. The same two lines submit_run() now runs,
## written out here so the test states the expectation rather than calling the thing
## under test back on itself.
func _scaled(run_time: float, kills: int, gold: int, scrolls: int) -> float:
	return roundf(float(LeaderboardManager.calculate_score(run_time, kills, gold, scrolls))
		* float(GameManager.get_danger_data().get("score", 1.0)))

## The "11.0" out of "Enemy HP 300% - Speed 160% - Score x11.0". Parsed rather than
## reformatted, so the test reads the player-facing string instead of restating it.
func _multiplier_in(text: String) -> float:
	var marker := text.to_lower().rfind("x")
	if marker < 0:
		return 0.0
	return float(text.substr(marker + 1).strip_edges())

## {"bytes": <contents>, "existed": <bool>} -- a missing file is restored by removal
## rather than by writing an empty stub, and a re-serialised ConfigFile reorders keys,
## so the bytes go back exactly as they were.
func _grab(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"bytes": PackedByteArray(), "existed": false}
	var bytes := f.get_buffer(f.get_length())
	f.close()
	return {"bytes": bytes, "existed": true}

func _finish() -> void:
	GameManager.danger_level = _danger_backup
	var restored := _put_back(BOARD_PATH, _board) and _put_back(SAVE_PATH, _save)
	if not restored:
		check(false, "The developer's save files were restored byte for byte")

	if _failures.is_empty():
		print("=== ALL EXPANSION 36.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

func _put_back(path: String, snapshot: Dictionary) -> bool:
	if not bool(snapshot.get("existed", false)):
		if FileAccess.file_exists(path):
			return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
		return true
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(snapshot["bytes"])
	f.close()
	return true
