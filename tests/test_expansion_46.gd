extends Node

## Automated Test Suite for Expansion 46.0:
## "ARMOR: +0" -- the panel under-reported the damage reduction you were getting,
## the sibling defect of Expansion 45.0 on the line two below it.
##
## 45.0 fixed the MIGHT readout, which restated one term of the four-term sum in
## _build_might_bonus(). The two stats printed next to it had the identical shape:
##
##     hud.gd:694   var armor = GameManager.get_meta_stat("armor")      # "ARMOR: +%d"
##     hud.gd:966   var armor = GameManager.get_meta_stat("armor")      # "DEF %d"
##
## while the armour the game actually subtracts is built in player.gd:757:
##
##     var meta_arm  = GameManager.get_meta_stat("armor") if GameManager else 0
##     var equip_arm = 2 if (GameManager and GameManager.has_equipped("nhuyen_vi_giap")) else 0
##     var total_armor = meta_arm + char_armor_bonus + equip_arm + shop_armor_bonus
##
## Three of the four sources are invisible on the panel: the character's innate
## armour (player.gd:212), Nhuyễn Vị Giáp's flat 2, and every point bought in the
## wave shop (player.gd:136, run-scoped and specifically supposed to be a *run*
## number the player can watch).
##
## The claim under test is behavioural, not arithmetical: the panel must report the
## damage reduction take_damage() actually applies. So the expected value is
## MEASURED -- hit the player with a known amount and difference the health -- and
## the number on the label is compared against that. Nothing here restates the
## formula, so the suite cannot pass by agreeing with a stale copy of it.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## equip_gear() and friends persist to user://save_data.cfg immediately.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e46bak"
var _had_save: bool = false

var _failures: Array[String] = []

const PROBE: float = 60.0

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

## Read the integer out of "...<marker><digits>..." and return -1 if the marker is
## absent or nothing numeric follows. -1 is not a legal displayed value, so a broken
## parse fails the check rather than quietly comparing equal.
func _parse_int(text: String, marker: String) -> int:
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

## The armour the game actually applies: deal a known hit and difference the health.
## take_damage()'s dodge roll, qi shield, damage-taken multiplier and blood covenant
## are all neutralised in _bootstrap() so the probe isolates armour alone, and the
## 1000 HP keeps the phoenix-feather rebirth branch out of reach.
func _measured_armor() -> int:
	_player.current_health = 1000.0
	# take_damage() sets i-frames on every hit, and the very first line guards on
	# is_invulnerable -- so without clearing this, every probe after the first deals
	# nothing and reads as "armour absorbed the whole hit". The control case caught it.
	_player.invulnerability_timer = 0.0
	_player.take_damage(PROBE)
	return int(roundf(PROBE - (1000.0 - _player.current_health)))

func _read_pause_armor() -> int:
	_hud._refresh_pause_stats()
	return _parse_int(_hud.pause_stats_label.text, "ARMOR: +")

func _read_passives_def() -> int:
	_hud._update_passives_display()
	return _parse_int(_hud.passives_label.text, "DEF ")

func _ready() -> void:
	_backup_save()
	await _bootstrap()
	if not _failures.is_empty():
		_finish()
		return

	await _test_the_pause_panel_reports_the_damage_reduction_you_get()
	await _test_the_passives_bar_reports_it_too()
	await _test_the_equipped_giap_reaches_the_display()
	await _test_a_shop_armor_bonus_reaches_the_display()
	await _test_with_only_meta_armor_the_panel_still_matches()

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
	# Hermetic: own every input to take_damage()'s damage line, whatever the shared
	# save has equipped or collected.
	GameManager.equipment_slots["armor"] = ""
	_player.char_armor_bonus = 0
	_player.shop_armor_bonus = 0
	_player.char_damage_taken_mult = 1.0
	_player.char_dodge_bonus = 0.0
	_player.drunken_buff_timer = 0.0
	_player.has_blood_covenant = false
	_player.qi_shield_current = 0.0
	_player.is_invulnerable = false
	_player.refresh_meta_stats()

## The headline case: all four sources contributing at once.
func _test_the_pause_panel_reports_the_damage_reduction_you_get() -> void:
	_player.char_armor_bonus = 3
	_player.shop_armor_bonus = 4
	var actual := _measured_armor()
	var shown := _read_pause_armor()
	check(shown == actual,
		"the pause panel reports the whole armour bonus (shown %d, actually applied %d)" % [shown, actual])

## The passives bar is on screen every frame, so an under-report there is worse.
func _test_the_passives_bar_reports_it_too() -> void:
	_player.char_armor_bonus = 3
	_player.shop_armor_bonus = 4
	var actual := _measured_armor()
	var shown := _read_passives_def()
	check(shown == actual,
		"the passives bar reports the whole armour bonus (shown %d, actually applied %d)" % [shown, actual])

## Nhuyễn Vị Giáp's flat 2. Asserted in both directions so the result cannot come out
## right by accident from whatever the shared save happens to have equipped.
func _test_the_equipped_giap_reaches_the_display() -> void:
	GameManager.equipment_slots["armor"] = "nhuyen_vi_giap"
	var with_giap := _measured_armor()
	var with_giap_shown := _read_pause_armor()
	GameManager.equipment_slots["armor"] = ""
	var without_giap := _measured_armor()
	var without_giap_shown := _read_pause_armor()

	check(with_giap_shown == with_giap,
		"the pause panel includes Nhuyễn Vị Giáp's armour (shown %d, actually applied %d)" % [with_giap_shown, with_giap])
	check(without_giap_shown == without_giap,
		"the pause panel drops it when the giáp is unequipped (shown %d, actually applied %d)" % [without_giap_shown, without_giap])

## The run-scoped source: bought during the run, so exactly the kind of number a
## player watches the panel for.
func _test_a_shop_armor_bonus_reaches_the_display() -> void:
	_player.shop_armor_bonus = 7
	_player.char_armor_bonus = 0
	var actual := _measured_armor()
	var shown := _read_pause_armor()
	check(shown == actual,
		"a run-scoped shop armour bonus reaches the display (shown %d, actually applied %d)" % [shown, actual])

## Control. With the three non-meta sources at zero the two expressions agree, so
## this passes both before and after the fix -- which is the point: it proves the
## probe and the label parse are sound, and the other cases fail for the right reason.
func _test_with_only_meta_armor_the_panel_still_matches() -> void:
	_player.char_armor_bonus = 0
	_player.shop_armor_bonus = 0
	GameManager.equipment_slots["armor"] = ""
	var actual := _measured_armor()
	var shown := _read_pause_armor()
	check(shown == actual,
		"with only the meta upgrade contributing, the panel still matches (shown %d, actually applied %d)" % [shown, actual])

func _finish() -> void:
	_restore_save()
	if _failures.is_empty():
		print("=== EXPANSION 46.0: ALL CHECKS PASSED ===")
		get_tree().quit(0)
	else:
		print("=== EXPANSION 46.0: %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAILED: %s" % f)
		get_tree().quit(1)
