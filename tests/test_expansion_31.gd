extends Node

## Automated Test Suite for Expansion 31.0:
## "Phần Thưởng Hằng Ngày Không Bao Giờ Được Trả" -- the daily reward the game
## promises on screen and never pays.
##
## The Daily Trial panel in leaderboard_ui.gd:211 renders
##
##     daily_reward_lbl.text = "💰 Phần Thưởng Hoàn Thành: +%d Vàng" % trial.get("reward_gold", 500)
##
## off the very dict get_daily_trial_info() returns, and the four trials carry
## 600 / 750 / 800 / 900 gold. The status line on the panel below it reads
##
##     comp = trial.get("completed", false)  ->  "✅ ĐÃ THAM GIA HÔM NAY"
##
## and the only assignment of that flag in the entire codebase was
## submit_run()'s. So the game detected completion, told the player it had
## happened, and never moved the gold. This is not a typo in a reward_type or a
## mismatch between two spellings of a key -- there was no line that paid
## anything at all. The sibling system that shares the key name pays correctly
## (game_manager.gd:562 and :778 both do add_gold(b["reward_gold"]) for
## bounties), which is what makes the omission here easy to miss on a read.
##
## The suite drives the real autoloads, so the payout path is exercised end to
## end rather than asserted against a copy of the logic. Everything it disturbs
## is restored byte-for-byte in _finish(), because submit_run() writes two of the
## three shared save files.

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

var _gold_backup: int = 0
var _run_gold_backup: int = 0
var _blood_moon_backup: bool = false
var _entries_backup: Array[Dictionary] = []
var _completed_backup: bool = false
var _high_score_backup: int = 0
var _date_backup: String = ""

## The three files submit_run() and add_meta_gold() can write. Held as raw bytes
## rather than re-serialised, so a restore is provably a restore.
const SAVE_FILES: Array[String] = [
	"user://save_data.cfg", "user://leaderboard_data.cfg", "user://codex_data.cfg",
]
var _file_backup: Dictionary = {}
var _file_existed: Dictionary = {}

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 31.0 TEST SUITE ===")
	GameManager.is_run_active = false

	_backup()

	_test_the_advertised_number_is_the_number_paid()
	_test_it_is_paid_once_and_not_on_every_run()
	_test_the_first_run_of_a_new_day_pays()
	_test_the_payout_is_meta_gold_and_not_run_gold()
	_test_the_payout_is_flat_whatever_the_run_looked_like()
	_test_completion_and_payment_cannot_be_separated()

	_finish()

# --- 1. the number on the panel is the number in the purse ------------------------

## The panel is never instantiated here (it needs the full UI tree), so the
## advertised figure is read the same way the panel reads it: out of the dict
## get_daily_trial_info() hands back, with the same .get(key, default) the UI
## uses. The default is not 0, so an absent key fails here rather than quietly
## becoming a payout of nothing.
func _test_the_advertised_number_is_the_number_paid() -> void:
	var advertised: int = int(LeaderboardManager.get_daily_trial_info().get("reward_gold", 0))
	check(advertised > 0, "Today's trial advertises a gold reward, got %d" % advertised)

	_fresh_day()
	var before: int = GameManager.total_gold
	LeaderboardManager.submit_run("knight", 10.0, 5, 0, [])

	check(GameManager.total_gold == before + advertised,
		"Finishing the trial pays exactly the advertised %d, purse went %d -> %d"
			% [advertised, before, GameManager.total_gold])
	check(LeaderboardManager.daily_completed,
		"Completing the trial is what the panel reports as ✅ ĐÃ THAM GIA HÔM NAY")

# --- 2. once, not on every run ---------------------------------------------------

## The completion flag is a high watermark, so beating it is the normal outcome of
## a second run. Payout therefore cannot hang off the score comparison -- it hangs
## off the completion flag flipping, or the player could farm the daily 600 by
## dying repeatedly.
func _test_it_is_paid_once_and_not_on_every_run() -> void:
	_fresh_day()
	LeaderboardManager.submit_run("knight", 10.0, 5, 0, [])   # pays
	var after_first: int = GameManager.total_gold

	LeaderboardManager.submit_run("knight", 1.0, 0, 0, [])    # worse than the first
	check(GameManager.total_gold == after_first,
		"A worse run pays nothing, purse went %d -> %d" % [after_first, GameManager.total_gold])

	# A new daily best, not just any run: the score comparison still passes here.
	LeaderboardManager.submit_run("knight", 900.0, 900, 0, [])
	check(GameManager.total_gold == after_first,
		"Beating the daily record still pays nothing, purse went %d -> %d"
			% [after_first, GameManager.total_gold])
	check(LeaderboardManager.daily_high_score > 0,
		"The record itself still moved, which is what that run was for")

	# And the flag has to survive all of it, or tomorrow's reset has nothing to reset.
	check(LeaderboardManager.daily_completed, "The day is still marked complete after three runs")

# --- 3. the first run of a new day -----------------------------------------------

## get_daily_trial_info() is the only thing that rolls the date over, and the
## rollover is what clears daily_completed. Stale `true` left over from yesterday
## is exactly the state the guard in submit_run() meets, so this is the case that
## decides whether the call has to come before the guard. Reorder it and the run
## scores, skips the payout, and then has its own completion flag cleared by the
## rollover -- a whole day of the reward lost and the panel claiming nobody played.
func _test_the_first_run_of_a_new_day_pays() -> void:
	var advertised: int = int(LeaderboardManager.get_daily_trial_info().get("reward_gold", 0))
	var before: int = GameManager.total_gold

	LeaderboardManager.last_daily_date = "1999-01-01"   # yesterday, as far as the file knows
	check(LeaderboardManager.daily_completed, "Precondition: yesterday was completed")

	LeaderboardManager.submit_run("knight", 20.0, 9, 0, [])

	check(GameManager.total_gold == before + advertised,
		"The first run of a new day pays the reward, purse went %d -> %d"
			% [before, GameManager.total_gold])
	check(LeaderboardManager.daily_completed,
		"And the day is marked complete, not left reading CHƯA THAM GIA after a run just ended")

# --- 4. meta gold, not run gold --------------------------------------------------

## run_gold is what the end-of-run Double Gold rewarded ad doubles, and it is also
## the figure the game-over panel prints as "Gold Earned". A daily reward is a
## meta-layer payout for showing up once, so paying it through add_gold() would
## both mislabel the run's earnings and hand the player a free second doubling.
func _test_the_payout_is_meta_gold_and_not_run_gold() -> void:
	_fresh_day()
	var run_gold_before: int = GameManager.run_gold
	LeaderboardManager.submit_run("knight", 30.0, 11, 0, [])

	check(GameManager.run_gold == run_gold_before,
		"The daily payout does not touch run_gold, went %d -> %d"
			% [run_gold_before, GameManager.run_gold])

# --- 5. a flat number, not one scaled by the run that just ended -----------------

## add_gold() multiplies by golden_horseshoe, doubles under Blood Moon, and applies
## the Codex gold bonus. Those describe coins that dropped while those conditions
## were live; a flat daily reward owes none of them. This is the assertion that
## distinguishes the fix from a one-liner calling add_gold() instead.
func _test_the_payout_is_flat_whatever_the_run_looked_like() -> void:
	_fresh_day()
	var advertised: int = int(LeaderboardManager.get_daily_trial_info().get("reward_gold", 0))
	GameManager.is_blood_moon = true
	var before: int = GameManager.total_gold
	LeaderboardManager.submit_run("knight", 40.0, 13, 0, [])

	check(GameManager.total_gold == before + advertised,
		"Blood Moon does not double the daily reward, purse went %d -> %d (advertised %d)"
			% [before, GameManager.total_gold, advertised])

	# Non-positive rewards must move nothing at all rather than debit the player.
	var before_zero: int = GameManager.total_gold
	GameManager.add_meta_gold(0)
	GameManager.add_meta_gold(-50)
	check(GameManager.total_gold == before_zero,
		"A zero or negative meta payout changes nothing, went %d -> %d"
			% [before_zero, GameManager.total_gold])

# --- 6. completion and payment are the same event --------------------------------

## The panel's ✅ is what the player is shown as proof they were paid, so a run
## that does not score must not set that flag either. Asserted with the daily
## record already out of reach, which is the only state in which the score
## comparison and the completion flag can be told apart.
func _test_completion_and_payment_cannot_be_separated() -> void:
	_fresh_day()
	LeaderboardManager.daily_high_score = 10_000_000
	var before: int = GameManager.total_gold

	LeaderboardManager.submit_run("knight", 1.0, 0, 0, [])

	check(LeaderboardManager.daily_high_score == 10_000_000,
		"A run that does not beat the record leaves the record alone")
	check(not LeaderboardManager.daily_completed,
		"A run that does not beat the record does not mark the day complete")
	check(GameManager.total_gold == before,
		"And pays nothing, purse went %d -> %d" % [before, GameManager.total_gold])

# --- helpers ------------------------------------------------------------------

## Puts the trial in the state a player finds it in on waking up: today, unplayed,
## no record. Written as an explicit reset rather than by calling
## get_daily_trial_info() with a stale date, because that path also calls
## save_leaderboard_data() and the point of these cases is the payout, not the save.
func _fresh_day() -> void:
	LeaderboardManager.last_daily_date = _today()
	LeaderboardManager.daily_completed = false
	LeaderboardManager.daily_high_score = 0

func _today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.get("year", 2026), d.get("month", 9), d.get("day", 17)]

func _backup() -> void:
	_gold_backup = GameManager.total_gold
	_run_gold_backup = GameManager.run_gold
	_blood_moon_backup = GameManager.is_blood_moon
	_completed_backup = LeaderboardManager.daily_completed
	_high_score_backup = LeaderboardManager.daily_high_score
	_date_backup = LeaderboardManager.last_daily_date
	_entries_backup = LeaderboardManager.tournament_entries.duplicate(true)
	for path in SAVE_FILES:
		_file_existed[path] = FileAccess.file_exists(path)
		if _file_existed[path]:
			_file_backup[path] = FileAccess.get_file_as_bytes(path)

func _finish() -> void:
	GameManager.total_gold = _gold_backup
	GameManager.run_gold = _run_gold_backup
	GameManager.is_blood_moon = _blood_moon_backup
	LeaderboardManager.daily_completed = _completed_backup
	LeaderboardManager.daily_high_score = _high_score_backup
	LeaderboardManager.last_daily_date = _date_backup
	LeaderboardManager.tournament_entries = _entries_backup
	GameManager.save_game_data()
	LeaderboardManager.save_leaderboard_data()
	for path in SAVE_FILES:
		if _file_existed[path]:
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f:
				f.store_buffer(_file_backup[path])
				f.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	if _failures.is_empty():
		print("=== ALL EXPANSION 31.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)
