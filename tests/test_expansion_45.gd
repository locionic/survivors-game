extends Node

## Automated Test Suite for Expansion 45.0:
## "The Pause Panel Under-Reports Your Might" -- a player-facing stat that reports
## one of four sources and calls it the whole number.
##
## The damage the game actually deals is built in player.gd:456:
##
##     func _build_might_bonus() -> float:
##         var bonus := GameManager.get_meta_stat("might") * 0.10 + char_might_bonus + run_might_bonus
##         if GameManager.has_equipped("y_thien_kiem"):
##             bonus += 0.15
##         return bonus
##
## and that lands in `meta_might_bonus`, the additive term of get_might_multiplier().
## The comment above that function records that this very omission was already fixed
## *in the computation* -- Ỷ Thiên Kiếm's +15% used to be added inline at the tail of
## refresh_meta_stats(), and add_run_might() silently deleted it. The fix never
## reached the two places the player READS the number:
##
##     hud.gd:688   var might = GameManager.get_meta_stat("might") * 10   # pause panel
##     hud.gd:962   var might = GameManager.get_meta_stat("might") * 10   # passives bar
##
## Both restate a single term of a four-term sum. A knight with +20% character might
## and a +15% run bonus is shown "MIGHT: +0%" and "ATK +0%" while genuinely dealing
## 35% more damage. The passives bar is the worse of the two: it is on screen for
## every frame of every run, and unlike the pause panel there is no way to look
## anywhere else and notice.
##
## The claim under test is an invariant, not a number: whatever the panel prints must
## equal the bonus the damage formula actually uses. Every expected value is read off
## the live player as `meta_might_bonus`, so nothing here restates a constant that
## lives in the game, and the suite cannot pass by agreeing with a stale copy.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## equip_gear() and friends persist to user://save_data.cfg immediately.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e45bak"
var _had_save: bool = false

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

var _main: Node = null
var _hud: HUD = null
var _player: Player = null

func _backup_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		_had_save = true
		var src := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var dst := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		dst.store_buffer(src.get_buffer(src.get_length()))
		src.close()
		dst.close()

func _restore_save() -> void:
	if not _had_save:
		return
	var src := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	var dst := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	dst.store_buffer(src.get_buffer(src.get_length()))
	src.close()
	dst.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_PATH))

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

## Read the integer out of "...<marker><digits>%..." and return -1 if the marker is
## absent or nothing numeric follows it. -1 is not a legal displayed value, so a
## broken parse fails the check rather than quietly comparing equal.
func _parse_pct(text: String, marker: String) -> int:
	var at := text.find(marker)
	if at < 0:
		return -1
	var digits := ""
	for c in text.substr(at + marker.length()):
		if c.is_valid_int():
			digits += c
		else:
			break
	return int(digits) if digits != "" else -1

## The number the game actually uses, straight off the live node.
func _real_might_pct() -> int:
	return int(roundf(_player.meta_might_bonus * 100.0))

func _read_pause_panel() -> int:
	_hud._refresh_pause_stats()
	return _parse_pct(_hud.pause_stats_label.text, "MIGHT: +")

func _read_passives_bar() -> int:
	_hud._update_passives_display()
	return _parse_pct(_hud.passives_label.text, "ATK +")

func _ready() -> void:
	_backup_save()
	await _bootstrap()
	if not _failures.is_empty():
		_finish()
		return

	await _test_the_pause_panel_reports_the_whole_might_bonus()
	await _test_the_passives_bar_reports_the_whole_might_bonus()
	await _test_a_run_scoped_might_bonus_reaches_the_display()
	await _test_the_equipped_kiem_tail_reaches_the_display()
	await _test_with_no_bonuses_the_display_still_matches()

	_finish()

func _bootstrap() -> void:
	GameManager.select_character("knight")
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.apply_character_data()
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await get_tree().process_frame
	_hud = _main.get_node_or_null("HUD")
	if not check(_hud != null, "HUD node exists in main scene"):
		return
	_hud.player = _player
	# Hermetic: whatever weapon the shared save has equipped, this suite owns it.
	GameManager.equipment_slots["weapon"] = ""
	_player.run_might_bonus = 0.0
	_player.char_might_bonus = 0.0
	_player.refresh_meta_stats()

## The headline case: a character bonus the panel cannot see.
func _test_the_pause_panel_reports_the_whole_might_bonus() -> void:
	_player.char_might_bonus = 0.20
	_player.refresh_meta_stats()
	var expected := _real_might_pct()
	var shown := _read_pause_panel()
	check(shown == expected,
		"the pause panel shows the whole might bonus, not just the meta upgrade (shown %d, actual %d)" % [shown, expected])

## The passives bar is on screen every frame, so an under-report there is worse.
func _test_the_passives_bar_reports_the_whole_might_bonus() -> void:
	_player.char_might_bonus = 0.20
	_player.refresh_meta_stats()
	var expected := _real_might_pct()
	var shown := _read_passives_bar()
	check(shown == expected,
		"the passives bar shows the whole might bonus (shown %d, actual %d)" % [shown, expected])

## The run-scoped source is the one the sibling comment warns about: it is added at
## runtime, so the panel has to follow it without a refresh being asked for.
func _test_a_run_scoped_might_bonus_reaches_the_display() -> void:
	_player.char_might_bonus = 0.0
	_player.add_run_might(0.25)
	var expected := _real_might_pct()
	var pause_shown := _read_pause_panel()
	var passives_shown := _read_passives_bar()
	check(pause_shown == expected,
		"a run-scoped might bonus reaches the pause panel (shown %d, actual %d)" % [pause_shown, expected])
	check(passives_shown == expected,
		"a run-scoped might bonus reaches the passives bar (shown %d, actual %d)" % [passives_shown, expected])

## The Ỷ Thiên Kiếm tail. Asserted in both directions so the result cannot come out
## right by accident from whatever the shared save happens to have equipped.
func _test_the_equipped_kiem_tail_reaches_the_display() -> void:
	GameManager.equipment_slots["weapon"] = "y_thien_kiem"
	_player.refresh_meta_stats()
	var with_kiem := _read_pause_panel()
	var with_kiem_expected := _real_might_pct()
	GameManager.equipment_slots["weapon"] = ""
	_player.refresh_meta_stats()
	var without_kiem := _read_pause_panel()
	var without_kiem_expected := _real_might_pct()

	check(with_kiem == with_kiem_expected,
		"the pause panel includes the equipped Ỷ Thiên Kiếm bonus (shown %d, actual %d)" % [with_kiem, with_kiem_expected])
	check(without_kiem == without_kiem_expected,
		"the pause panel drops the Ỷ Thiên Kiếm bonus when it is unequipped (shown %d, actual %d)" % [without_kiem, without_kiem_expected])

## Control. With every non-meta source at zero the two expressions agree, so this
## passes both before and after the fix -- which is the point: it proves the parse
## and the label format are sound, and that the other cases fail for the right reason.
func _test_with_no_bonuses_the_display_still_matches() -> void:
	_player.char_might_bonus = 0.0
	_player.run_might_bonus = 0.0
	_player.refresh_meta_stats()
	var expected := _real_might_pct()
	var shown := _read_pause_panel()
	check(shown == expected,
		"with only the meta upgrade contributing, the panel still matches (shown %d, actual %d)" % [shown, expected])

func _finish() -> void:
	_restore_save()
	if _failures.is_empty():
		print("=== EXPANSION 45.0: ALL CHECKS PASSED ===")
		get_tree().quit(0)
	else:
		print("=== EXPANSION 45.0: %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAILED: %s" % f)
		get_tree().quit(1)
