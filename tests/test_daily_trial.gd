extends Node

## Expansion 52.0: the daily trial advertised twelve gameplay modifiers and
## implemented none of them.
##
## Four challenges, three claimed effects each -- "+50% damage", "quái vật +20%
## tốc độ", "khí thuẫn x2", "champion xuất hiện gấp đôi", "hồi chiêu −30%",
## "goblin x3" -- carried as `might_mult` / `speed_mult` keys that nothing in the
## codebase ever read. The panel at leaderboard_ui.gd:209 printed the string
## verbatim, so a player was told what the day did to their run, and the day did
## nothing to their run.
##
## The modifiers were not wired up rather than unwired by mistake. There is no
## trial run to apply them to -- submit_run() fires on every run the player
## finishes and pays for beating today's score. The only wiring that fits would
## hand every player a silent +35% might on that date with nothing in the HUD
## explaining it, which is a worse bug than the copy. So the copy was corrected
## and the dead keys deleted; the four challenges are a score-and-reward
## challenge and now say so.
##
## The table also moved from a literal rebuilt on every get_daily_trial_info()
## call to `const MUTATORS`, which is what makes all four checkable instead of
## only whichever one the calendar picked today. That hoist introduces one new
## hazard -- a shared constant that a caller could scribble on -- so the last
## test here is about `.duplicate()` still doing its job.
##
## Both halves of the defect are now unreintroducible: a key nothing reads fails
## (the table is pinned to exactly the keys the panel consumes), and a modifier
## the game does not implement fails (no description may quote a gameplay
## number).

var _failures: Array[String] = []

## The only keys a challenge row is allowed to carry. `title`, `desc` and
## `reward_gold` are read off the trial dict by leaderboard_ui.gd; `id` is the
## row's stable identity, used here to name a failure and nowhere else. Anything
## else -- `might_mult`, `speed_mult`, a `spawn_mult` someone adds next year --
## is a key the game would have to be seen reading before it earns a place.
const ALLOWED_KEYS: Array[String] = ["id", "title", "desc", "reward_gold"]

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()

func _ready() -> void:
	print("=== RUNNING EXPANSION 52.0: DAILY TRIAL HONESTY TEST SUITE ===")
	GameManager.is_run_active = false

	_test_the_table_is_reachable_and_todays_challenge_comes_from_it()
	_test_every_key_on_a_challenge_is_one_the_game_reads()
	_test_no_description_quotes_a_number_the_game_does_not_implement()
	_test_the_shared_constant_cannot_be_scribbled_on()

	get_tree().paused = false
	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)
	if unique.is_empty():
		print("=== ALL DAILY TRIAL TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. The hoist did not lose the rotation ----------------------------------

func _test_the_table_is_reachable_and_todays_challenge_comes_from_it() -> void:
	check(LeaderboardManager.MUTATORS.size() == 4,
		"The daily trial still rotates through four challenges, got %d" % LeaderboardManager.MUTATORS.size())

	var trial := LeaderboardManager.get_daily_trial_info()
	var today_id := String(trial.get("id", ""))
	check(not today_id.is_empty(), "Today's challenge carries an id")

	var found := false
	for m in LeaderboardManager.MUTATORS:
		if String(m.get("id", "")) == today_id:
			found = true
			break
	check(found, "Today's challenge id '%s' comes from MUTATORS -- the const and get_daily_trial_info() disagree" % today_id)

	# The fields the panel reads back off the returned dict are still attached;
	# they are added after the .duplicate(), so a botched hoist shows up here.
	check(trial.has("date") and trial.has("completed") and trial.has("high_score"),
		"Today's challenge still carries date / completed / high_score for the panel")

	var ids: Dictionary = {}
	for m in LeaderboardManager.MUTATORS:
		var mid := String(m.get("id", ""))
		check(not mid.is_empty(), "Every challenge has an id")
		check(not ids.has(mid), "Challenge id '%s' appears twice in the rotation" % mid)
		ids[mid] = true

	print("OK The four challenges rotate and today's comes out of MUTATORS.")

# --- 2. No key on a challenge row goes unread ---------------------------------

## The exact defect: `might_mult` and `speed_mult` sat on all four rows and were
## read by nothing, so the panel advertised a modifier the game never applied.
## Pinning the key set catches the next one by name.
func _test_every_key_on_a_challenge_is_one_the_game_reads() -> void:
	for m in LeaderboardManager.MUTATORS:
		var mid := String(m.get("id", "?"))
		var extra: Array[String] = []
		for k in m.keys():
			if not ALLOWED_KEYS.has(String(k)):
				extra.append("%s on '%s' is read by nothing" % [k, mid])
		check(extra.is_empty(),
			"No challenge row carries a key the game never reads: %s" % "; ".join(extra))

	# And the other direction: the three keys the panel depends on must actually
	# be read there. A key that is allowed but unrendered is the same defect
	# wearing a different hat, and the file moves when the UI is retouched.
	var ui := _read("res://scripts/leaderboard_ui.gd")
	check(not ui.is_empty(), "leaderboard_ui.gd is readable from res:// -- without it this proves nothing")
	for k in ["title", "desc", "reward_gold"]:
		check(ui.contains("trial.get(\"%s\"" % k),
			"The daily panel reads '%s' off the challenge (leaderboard_ui.gd)" % k)

	print("OK Every challenge key is read by the panel that displays it.")

# --- 3. The copy states what the game does ------------------------------------

## The daily trial modifies no gameplay value, so no description may quote one.
## A number in these strings is the tell: it promises a magnitude, and there is
## no code path that could deliver one.
func _test_no_description_quotes_a_number_the_game_does_not_implement() -> void:
	for m in LeaderboardManager.MUTATORS:
		var mid := String(m.get("id", "?"))
		var desc := String(m.get("desc", ""))
		check(not desc.is_empty(), "Challenge '%s' has a description" % mid)

		var digits := false
		for i in desc.length():
			if desc[i] >= "0" and desc[i] <= "9":
				digits = true
				break
		check(not digits,
			"Challenge '%s' quotes no gameplay number -- the daily trial modifies nothing: %s" % [mid, desc])
		check(not desc.contains("%"),
			"Challenge '%s' quotes no percentage -- nothing scales the run: %s" % [mid, desc])

	print("OK No challenge description promises a modifier that does not exist.")

# --- 4. The const is not shared mutable state -------------------------------

## The one new hazard this change introduces. get_daily_trial_info() stamps four
## runtime fields onto the row it hands back; without the .duplicate() those
## would land on the constant and leak into tomorrow's, yesterday's, and every
## other challenge's row -- turning the panel's "CHƯA THAM GIA" into "ĐÃ THAM
## GIA" for all four.
func _test_the_shared_constant_cannot_be_scribbled_on() -> void:
	var trial := LeaderboardManager.get_daily_trial_info()
	trial["title"] = "SCRIBBLED"
	trial["reward_gold"] = 0

	var again := LeaderboardManager.get_daily_trial_info()
	check(String(again.get("title", "")) != "SCRIBBLED",
		"Mutating the returned challenge does not write through to MUTATORS")
	check(int(again.get("reward_gold", 0)) > 0,
		"Tomorrow's challenge keeps its advertised reward after today's was scribbled on")

	print("OK The shared constant survives a caller scribbling on the row it was handed.")