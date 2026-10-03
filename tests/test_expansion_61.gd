extends "res://tests/suite_base.gd"

## Expansion 61.0: the player-facing copy that was still English.
##
## `Loc` has existed since Expansion 55.0 and 16 of its rows are read, but four
## places were never wired to it. A live itch.io test found them:
##
##   * the four run bounties -- `init_run_bounties()` builds `title`/`desc` as
##     English literals, and hud.gd:726 prints `b["title"]` straight into the
##     pause panel. These were the *known exception* in
##     tests/test_untranslated_copy.gd:41-48, exempted by a canary that failed
##     on purpose if anyone translated them. That canary is deleted alongside
##     this suite, which is what it was written to ask for.
##   * the four landmarks -- `landmark_name` is an @export on landmark.gd:7, set
##     per-instance in main.tscn:133-152, and read at four places including
##     `landmark_name.to_upper()` in the DISCOVERED banner. world_map_ui.gd:87-92
##     carries a SECOND list of the same four landmarks, also in English.
##   * `hud.kills` -- `{"en": "Kills", "vi": "Kills"}` (loc.gd:95). The Vietnamese
##     row is the English word. It has looked translated and been unreadable in
##     Vietnamese since the table shipped.
##   * the level-up title `LEVEL UP! CHOOSE AN UPGRADE` and the reroll button's
##     `(REROLL)` -- both baked into scenes/main.tscn, neither reachable by Loc
##     because neither is ever written from code.
##
## WHAT THIS DOES NOT CLAIM. The plan also lists "weapon tags in the top HUD".
## Those are already localised: hud.gd:967-976 resolves every badge through
## `Loc.weapon_name()` and `Loc.t("evo.%s.name")`. That bullet is satisfied in
## the tree this suite was written against, and there is no test here for it --
## a test for behaviour that was never broken would be decoration.

const LANDMARK_SCENE := preload("res://scenes/landmark.tscn")

## The four ids init_run_bounties() creates. The ids, not the copy, are the
## contract: hud.gd matches on `id`, and Expansion 29.0's suite reads them.
const BOUNTY_IDS: Array[String] = ["slay_bats", "survive_time", "defeat_champion", "defeat_goblin"]

## main.tscn's Landmarks node declares exactly these four (main.tscn:130-152).
const LANDMARK_IDS: Array[String] = ["fountain", "might", "speed", "vault"]

## Vietnamese writes its diacritics as precomposed codepoints, so the test is
## "is this a letter" and not "is this a combining mark" -- the same discriminator
## test_untranslated_copy.gd:64-68 uses, and for the same reason: unicode_at()/
## combining() returns 0 for every character in "Vàng".
##
## The one place this deliberately diverges from that suite is case. Its rows are
## card descriptions and read in sentence case, so it can demand a *lowercase*
## accented letter; three of the rows here are HUD labels that are legitimately all
## caps ("THĂNG CẤP!"), where a lowercase-only test calls its own correct Vietnamese
## untranslated. Folding to lowercase first keeps the check the same for every
## accent while admitting both cases -- and still reports {"vi": "Kills"} as English.
static func _is_vietnamese(s: String) -> bool:
	for i in s.length():
		var c := s[i].to_lower()
		if c != c.to_upper() and c.unicode_at(0) > 127:
			return true
	return false

static func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return "" if f == null else f.get_as_text()

## The Vietnamese row for `key`, or "" if the key or the row is missing.
static func _vi(key: String) -> String:
	var row = Loc.STRINGS.get(key)
	if row is Dictionary and row.has("vi"):
		return String(row["vi"])
	return ""

## Restore whatever the save was carrying. Loc is an autoload shared by every
## suite in the run, and a vi locale left behind would silently translate every
## assertion in whichever suite runs next.
func _restore_locale() -> void:
	Loc.current_locale = Loc.DEFAULT_LOCALE

# --- 1. the bounty table ------------------------------------------------------

func _test_every_bounty_has_a_bilingual_row() -> void:
	for id in BOUNTY_IDS:
		for field in ["title", "desc"]:
			var key := "bounty.%s.%s" % [id, field]
			check(Loc.STRINGS.has(key), "Loc has no %s row" % key)
			check(_is_vietnamese(_vi(key)),
				"%s has no Vietnamese row -- got \"%s\"" % [key, _vi(key)])

func _test_bounty_copy_is_read_from_Loc_at_build_time() -> void:
	Loc.current_locale = "vi"
	GameManager.init_run_bounties()
	check(GameManager.active_bounties.size() == BOUNTY_IDS.size(),
		"expected %d bounties, got %d" % [BOUNTY_IDS.size(), GameManager.active_bounties.size()])
	for b in GameManager.active_bounties:
		var id: String = b["id"]
		for field in ["title", "desc"]:
			check(b[field] == Loc.t("bounty.%s.%s" % [id, field]),
				"bounty %s.%s is not the Loc row: got \"%s\"" % [id, field, b[field]])
		check(_is_vietnamese(b["title"]),
			"bounty %s reads \"%s\" in Vietnamese" % [id, b["title"]])
	_restore_locale()

func _test_the_toggle_retitles_a_bounty_in_flight() -> void:
	# A locale switch mid-run has to reach copy that was built once at run start.
	# Without this, a player who plays in English and switches to Vietnamese sees
	# the pause panel change language around four bounties that stay English.
	Loc.current_locale = "en"
	GameManager.init_run_bounties()
	var before: String = GameManager.active_bounties[0]["title"]
	Loc.current_locale = "vi"
	Loc.emit_signal("locale_changed", "vi")
	var after: String = GameManager.active_bounties[0]["title"]
	check(before != after,
		"the first bounty reads \"%s\" in both languages -- the toggle does not reach it" % before)
	_restore_locale()

func _test_the_source_no_longer_ships_the_english_bounties() -> void:
	# The structural half. Loc could carry a perfect Vietnamese row while the
	# literal that is actually displayed stays English, and every behavioural
	# check above would still pass.
	var src := _read("res://scripts/game_manager.gd")
	if not check(src != "", "could not read res://scripts/game_manager.gd"):
		return
	for s in ['"Bat Hunter"', '"Slay 25 Bats"', '"Iron Resolve"', '"Survive 2 Minutes"',
			'"Champion Slayer"', '"Greed Hunter"']:
		check(not src.contains(s), "game_manager.gd still ships untranslated bounty copy: %s" % s)

# --- 2. the landmarks ---------------------------------------------------------

func _test_every_landmark_has_a_bilingual_row() -> void:
	for id in LANDMARK_IDS:
		for field in ["name", "desc"]:
			var key := "landmark.%s.%s" % [id, field]
			check(Loc.STRINGS.has(key), "Loc has no %s row" % key)
			check(_is_vietnamese(_vi(key)),
				"%s has no Vietnamese row -- got \"%s\"" % [key, _vi(key)])

func _test_a_landmark_names_itself_in_the_active_language() -> void:
	var lm := LANDMARK_SCENE.instantiate() as Landmark
	add_child(lm)
	if not check(lm.has_method("get_display_name"), "Landmark.get_display_name() does not exist"):
		return
	Loc.current_locale = "vi"
	lm.landmark_id = "might"
	check(lm.get_display_name() == Loc.t("landmark.might.name", lm.landmark_name),
		"the Altar of Might does not read its Loc row, got \"%s\"" % lm.get_display_name())
	check(_is_vietnamese(lm.get_display_name()),
		"the Altar of Might reads \"%s\" in Vietnamese" % lm.get_display_name())
	Loc.current_locale = "en"
	check(lm.get_display_name() == Loc.t("landmark.might.name"),
		"the English read does not match the Loc row, got \"%s\"" % lm.get_display_name())
	_restore_locale()
	lm.queue_free()

func _test_the_world_map_does_not_carry_a_second_english_list() -> void:
	# world_map_ui.gd:87-92 held its own hardcoded copy of all four landmarks,
	# alongside the ones main.tscn declares. Two sources of truth for the same
	# four names is how the map and the arena could drift apart, and it left the
	# map with nothing Loc could translate.
	var src := _read("res://scripts/world_map_ui.gd")
	if not check(src != "", "could not read res://scripts/world_map_ui.gd"):
		return
	for s in ['"Altar of Might"', '"Shrine of Swiftness"', '"Vault of the Ancients"']:
		check(not src.contains(s), "world_map_ui.gd still ships a second English copy: %s" % s)
	check(src.contains('Loc.t("landmark.'),
		"world_map_ui.gd should name landmarks through Loc, the way landmark.gd does")

# --- 3. the HUD and the level-up panel ----------------------------------------

func _test_the_kills_row_is_actually_translated() -> void:
	# loc.gd:95 shipped {"en": "Kills", "vi": "Kills"} -- a row that looks filled
	# in and renders English in both languages.
	check(_is_vietnamese(_vi("hud.kills")),
		"hud.kills has no Vietnamese row -- got \"%s\"" % _vi("hud.kills"))

func _test_the_level_up_title_is_localised() -> void:
	var scene := _read("res://scenes/main.tscn")
	if not check(scene != "", "could not read res://scenes/main.tscn"):
		return
	check(not scene.contains("LEVEL UP! CHOOSE AN UPGRADE"),
		"main.tscn still bakes the English level-up title in")
	check(_is_vietnamese(_vi("hud.level_up")),
		"hud.level_up has no Vietnamese row -- got \"%s\"" % _vi("hud.level_up"))
	var ui := _read("res://scripts/upgrade_manager.gd")
	check(ui.contains("hud.level_up"),
		"upgrade_manager.gd never writes the level-up title, so deleting it from the scene blanks it")

func _test_the_reroll_button_is_localised() -> void:
	var ui := _read("res://scripts/upgrade_manager.gd")
	if not check(ui != "", "could not read res://scripts/upgrade_manager.gd"):
		return
	check(not ui.contains("(REROLL)"),
		"upgrade_manager.gd still bakes the English (REROLL) into the button")
	check(_is_vietnamese(_vi("hud.reroll")),
		"hud.reroll has no Vietnamese row -- got \"%s\"" % _vi("hud.reroll"))

func _test_the_kill_counter_uses_loc() -> void:
	var hud := _read("res://scripts/hud.gd")
	if not check(hud != "", "could not read res://scripts/hud.gd"):
		return
	check(not hud.contains('"%d KILLS"'),
		"hud.gd still formats the kill counter as \"%d KILLS\"")
	check(hud.contains("hud.kills_count"),
		"hud.gd should format the kill counter from a Loc row")

func _ready() -> void:
	print("=== RUNNING EXPANSION 61.0: BILINGUAL BOUNTY / LANDMARK / HUD COPY ===")
	GameManager.is_run_active = false

	await _test_every_bounty_has_a_bilingual_row()
	await _test_bounty_copy_is_read_from_Loc_at_build_time()
	await _test_the_toggle_retitles_a_bounty_in_flight()
	await _test_the_source_no_longer_ships_the_english_bounties()
	await _test_every_landmark_has_a_bilingual_row()
	await _test_a_landmark_names_itself_in_the_active_language()
	await _test_the_world_map_does_not_carry_a_second_english_list()
	await _test_the_kills_row_is_actually_translated()
	await _test_the_level_up_title_is_localised()
	await _test_the_reroll_button_is_localised()
	await _test_the_kill_counter_uses_loc()

	_restore_locale()
	if _failures.is_empty():
		print("=== ALL EXPANSION 61.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())
