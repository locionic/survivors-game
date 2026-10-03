extends Node

## Automated Test Suite for Expansion 39.0:
## "Xung Mạch bán 8%, bảng ghi 10%" -- the meridian table's numbers are the
## contract, and one of them was not the number the player got.
##
## The MERIDIANS table in game_manager.gd:414 spells out what each rank buys, and
## the pause menu renders those strings verbatim (hud.gd:1264). Seven of the eight
## numbers in that table are applied exactly:
##
##     nham_mach  "+30 Qi Shield & +1.5 HP/s Regen"   player.gd:380, :389
##     doc_mach   "+7% Crit Chance & +35% Crit DMG"   player.gd:392, :903
##     xung_mach  "+15 Move Speed"                    player.gd:395
##     dan_dien   "+30% Dragon Soul & +20% AoE"       player.gd:402, :374
##
## The eighth did not:
##
##     xung_mach  "-10% Cooldown"                     player.gd:399 ->  xung * 0.08
##
## Eight percent, against a row that says ten. Not a rounding artefact and not
## the 2.5s floor reaching early -- at five ranks the knight's 5.5s base is 2.75s
## at the advertised rate and 3.30s at the applied one, so the floor binds on
## neither. The player read "-10% Cooldown", paid 1437 gold across five ranks,
## and got a 40% cut where the row promised 50%.
##
## The suite is table-driven on purpose. A test that pinned only xung_mach would
## have shipped a fix and left the next mistyped decimal free to land, which is
## how this one got here: Expansion 23.0 already found Đốc Mạch advertising a
## +35% Crit DMG it never applied, in this same table, and the fix for that was
## the two numbers that were left, not a rule that caught the third.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## buy_meridian_upgrade() deducts total_gold and persists to user://save_data.cfg
## on every rank, so this suite spends the developer's real meta gold and upgrades.
## Backed up and restored byte-for-byte, same sidecar idiom as the milestone suites.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e39bak"
var _had_save: bool = false

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

var _meridians_backup: Dictionary = {}
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

func _ready() -> void:
	_backup_save()
	print("=== RUNNING EXPANSION 39.0 TEST SUITE ===")
	# Keep the tree inert so the suite, not the autoload, decides when a run runs.
	GameManager.is_run_active = false

	_meridians_backup = GameManager.meridian_upgrades.duplicate()
	# Every prior suite shares one save file (see godot-tests-share-one-save-file.md),
	# so a run of this file may inherit ranks the previous one bought. Starting from
	# zero is the only way the deltas below mean what they say.
	for mid in GameManager.MERIDIANS.keys():
		GameManager.meridian_upgrades.erase(mid)

	# Five ranks of a meridian cost 1437 across the curve, and the buy is refused
	# rather than clamped when the purse is short -- so without this the cases fail
	# on gold rather than on the numbers they are about.
	GameManager.total_gold = 999999

	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)
	# Pin the character: skill_cooldown_base is reseated from the match at
	# player.gd:258, so the cooldown ratio is only readable against a known base.
	GameManager.select_character("knight")
	_player.apply_character_data()
	_player.current_health = _player.max_health
	await get_tree().process_frame

	check(_player.is_in_group("player"),
		"The player is in the group buy_meridian_upgrade() looks it up by -- without this the purchase path never refreshes the stats and every case below would measure a stale player")

	_test_nham_mach()
	_test_doc_mach()
	_test_xung_mach()
	_test_dan_dien()

	for mid in GameManager.MERIDIANS.keys():
		GameManager.meridian_upgrades.erase(mid)
	GameManager.meridian_upgrades = _meridians_backup
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 39.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- the four rows -------------------------------------------------------------

## Nhâm Mạch: capacity and regen, both read straight off the row.
func _test_nham_mach() -> void:
	var q_shield := float(_advertised("nham_mach", 0))
	var q_regen := float(_advertised("nham_mach", 1))
	var zero := _stats()
	if not _buy_to("nham_mach", GameManager.MAX_MERIDIAN_LEVEL):
		check(false, "Nhâm Mạch: five ranks were affordable and bought")
		return
	var five := _stats()
	check(is_equal_approx(float(five["shield_max"]) - float(zero["shield_max"]), q_shield * 5.0),
		"Nhâm Mạch advertises +%d Qi Shield per rank and grants it (expected +%s, got +%s)"
			% [int(q_shield), q_shield * 5.0, float(five["shield_max"]) - float(zero["shield_max"])])
	check(is_equal_approx(float(five["shield_regen"]) - float(zero["shield_regen"]), q_regen * 5.0),
		"Nhâm Mạch advertises +%s HP/s Regen per rank and grants it (expected +%s, got +%s)"
			% [q_regen, q_regen * 5.0, float(five["shield_regen"]) - float(zero["shield_regen"])])

## Đốc Mạch: the pair Expansion 23.0 found half of.
func _test_doc_mach() -> void:
	var c_chance := float(_advertised("doc_mach", 0))
	var c_damage := float(_advertised("doc_mach", 1))
	var zero := _stats()
	if not _buy_to("doc_mach", GameManager.MAX_MERIDIAN_LEVEL):
		check(false, "Đốc Mạch: five ranks were affordable and bought")
		return
	var five := _stats()
	# The row's two halves are both percentages but they live in different units,
	# and that is not a bug worth unifying: crit_chance_bonus is a chance, so +7
	# lands as 0.07 and enemy.take_damage() compares it against randf() directly;
	# get_crit_damage_multiplier() is a ratio over the bare 2.2 crit constant, so
	# +35 lands as 0.35 added to a 1.0. Collapsing them to one convention is a
	# behaviour change to both call sites, and the first draft of this case tried
	# it by accident -- it scaled the chance by 5 and called the 0.35 it got a
	# failure, on a row that was correct.
	check(is_equal_approx(float(five["crit_chance"]) - float(zero["crit_chance"]), c_chance * 5.0 * 0.01),
		"Đốc Mạch advertises +%d%% Crit Chance per rank and grants it (expected +%s, got +%s)"
			% [int(c_chance), c_chance * 5.0 * 0.01, float(five["crit_chance"]) - float(zero["crit_chance"])])
	check(is_equal_approx(float(five["crit_damage"]) - float(zero["crit_damage"]), c_damage * 5.0 * 0.01),
		"Đốc Mạch advertises +%d%% Crit DMG per rank and grants it (expected +%s, got +%s)"
			% [int(c_damage), c_damage * 5.0 * 0.01, float(five["crit_damage"]) - float(zero["crit_damage"])])

## Xung Mạch: the row this suite was written for. Both halves, because the bug
## was in one half of a row whose other half was correct -- a test that only
## checked move speed would have watched 15 land exactly and passed.
func _test_xung_mach() -> void:
	var m_speed := float(_advertised("xung_mach", 0))
	var m_cd := absf(float(_advertised("xung_mach", 1)))
	var zero := _stats()
	if not _buy_to("xung_mach", GameManager.MAX_MERIDIAN_LEVEL):
		check(false, "Xung Mạch: five ranks were affordable and bought")
		return
	var five := _stats()

	check(is_equal_approx(float(five["move_speed"]) - float(zero["move_speed"]), m_speed * 5.0),
		"Xung Mạch advertises +%d Move Speed per rank and grants it (expected +%s, got +%s)"
			% [int(m_speed), m_speed * 5.0, float(five["move_speed"]) - float(zero["move_speed"])])

	# The advertised rate, applied to the cooldown as a multiplier rather than
	# restated as one, because restating it is what hides this class of bug: the
	# first draft of this case compared the result against skill_cooldown_base *
	# 0.6, which is the code's number written out longhand, and passed. m_cd is 10
	# where the code had 8. maxf(2.5, ...) cannot account for the gap either -- the
	# knight's 5.5s base is 2.75s at the advertised rate, so the floor is not what
	# is being hit.
	var expected_cd: float = maxf(2.5, _player.skill_cooldown_base * (1.0 - m_cd * 0.01 * 5.0))
	check(is_equal_approx(float(five["cooldown"]), expected_cd),
		"Xung Mạch advertises -%d%% Cooldown per rank and grants it (expected %s, got %s)"
			% [int(m_cd), expected_cd, five["cooldown"]])
	check(float(five["cooldown"]) < 2.76,
		"...and five ranks actually clear the 2.5s floor on a 5.5s base, so this is the reduction and not the clamp (got %s)" % five["cooldown"])

## Đan Điền: harvest multiplier only. The "+20% AoE" half is deliberately not
## checked -- blast_radius_multiplier is built as a sum of contributions and then
## multiplied by Ỷ Thiên Kiếm's 1.25, so "+20%" names a term in that sum rather
## than a ratio against the result, and a test reading it as x1.2 would assert an
## arithmetic the code never promised.
func _test_dan_dien() -> void:
	var harvest := float(_advertised("dan_dien", 0))
	var zero := _stats()
	if not _buy_to("dan_dien", GameManager.MAX_MERIDIAN_LEVEL):
		check(false, "Đan Điền: five ranks were affordable and bought")
		return
	var five := _stats()
	check(is_equal_approx(float(five["dragon_soul"]) - float(zero["dragon_soul"]), harvest * 5.0 * 0.01),
		"Đan Điền advertises +%d%% Dragon Soul per rank and grants it (expected +%s, got +%s)"
			% [int(harvest), harvest * 5.0 * 0.01, float(five["dragon_soul"]) - float(zero["dragon_soul"])])

# --- helpers -------------------------------------------------------------------

## Everything refresh_meta_stats() derives, in one dictionary so a case is a
## before/after pair and never a hand-picked field.
func _stats() -> Dictionary:
	_player.refresh_meta_stats()
	return {
		"move_speed": _player.move_speed,
		"cooldown": _player.skill_cooldown_max,
		"shield_max": _player.qi_shield_max,
		"shield_regen": _player.qi_shield_regen_rate,
		"crit_chance": _player.crit_chance_bonus,
		"crit_damage": _player.get_crit_damage_multiplier(),
		"dragon_soul": _player.dragon_soul_harvest_mult,
	}

## Buy up to `rank` through the real purchase path, not by writing the
## dictionary. buy_meridian_upgrade() is what a player in the pause menu runs and
## it is the thing that calls refresh_meta_stats(), so a suite that poked
## meridian_upgrades directly would be testing a line no player reaches.
func _buy_to(mid: String, rank: int) -> bool:
	while GameManager.get_meridian_stat(mid) < rank:
		if not GameManager.buy_meridian_upgrade(mid):
			return false
	return true

## The number the meridian row advertises, read off the same string the pause
## menu renders. Parsed rather than restated on purpose: the defect is two numbers
## that disagree, so a suite that hardcoded the code's constant would have agreed
## with the code by being wrong in the same direction. If the row is ever
## legitimately rebalanced, this test follows the row.
func _advertised(meridian_id: String, half: int) -> float:
	var desc: String = String(GameManager.MERIDIANS[meridian_id]["desc"])
	var parts: PackedStringArray = desc.split("&")
	if half >= parts.size():
		return 0.0
	var n := ""
	for c in parts[half]:
		if (c >= "0" and c <= "9") or c == ".":
			n += c
		elif not n.is_empty():
			break
	return float(n) if not n.is_empty() else 0.0
