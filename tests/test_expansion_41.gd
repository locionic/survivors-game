extends Node

## Automated Test Suite for Expansion 41.0:
## "Ngựa Vàng Cho Tầm Hút, Rồi Cửa Hàng Lấy Mất" -- the Golden Horseshoe's advertised
## +60 pickup radius survived exactly until the player opened the pause shop.
##
## Two functions wrote the MagnetArea's CircleShape2D and they disagreed:
##
##     player.gd:352   refresh_meta_stats()    shape.radius = magnet_radius
##     player.gd:833   apply_relic_effects()   shape.radius = magnet_radius
##                                                  + char_magnet_bonus
##                                                  + relic_magnet_bonus
##
## refresh_meta_stats() has nine callers, three of them in the pause shop the player
## opens between any two fights (hud.gd:1237, :1278, :2236), plus game_manager.gd:490
## and :1026, codex_manager.gd:203 and character_select_ui.gd:330. apply_relic_effects()
## has one, and it runs only on the single frame the relic is first picked off the
## floor (relic_pickup.gd:65 -> add_relic -> game_manager.gd:690). The rebuild always
## wins, so: collect the relic mid-run, walk into any shop, and the +60 is gone for the
## rest of the run.
##
## Two further faults sat in that one line:
##
##   * char_magnet_bonus was added on top of magnet_radius, which already contains it
##     (player.gd:346). Mage carries 60 and Beggar 25, so those two double-counted
##     their own pickup bonus for as long as they held the relic.
##   * magnet_radius -- the field the pause panel displays (hud.gd:687, :961) -- never
##     got the +60 at all, so the panel showed a pickup range 60 smaller than the circle
##     the game was actually collecting with.
##
## The fix is the pattern this file already uses twice, for might and for max health:
## the relic is read where the stat is rebuilt rather than written onto the result,
## exactly like _build_might_bonus()'s GameManager.has_equipped("y_thien_kiem") check.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## buy_meridian_upgrade() spends total_gold and persists to user://save_data.cfg.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e41bak"
var _had_save: bool = false

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

var _relics_backup: Array[String] = []
var _equipment_backup: Dictionary = {}
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
	print("=== RUNNING EXPANSION 41.0 TEST SUITE ===")
	GameManager.is_run_active = false

	# Three fixtures the measurement must not inherit, each restored at teardown.
	# Same lesson as pinning storm_amulet: a stat is measured against a known state,
	# not against whoever's save is on disk.
	_relics_backup = GameManager.collected_relics.duplicate()
	GameManager.collected_relics.erase("golden_horseshoe")
	_equipment_backup = GameManager.equipment_slots.duplicate()
	for slot in GameManager.equipment_slots.keys():
		GameManager.equipment_slots[slot] = ""
	_meridians_backup = GameManager.meridian_upgrades.duplicate()
	for mid in GameManager.MERIDIANS.keys():
		GameManager.meridian_upgrades.erase(mid)
	# Five ranks cost 1437 and buy_meridian_upgrade() refuses rather than clamps.
	GameManager.total_gold = 999999

	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)
	GameManager.select_character("knight")
	_player.apply_character_data()
	_player.refresh_meta_stats()
	await get_tree().process_frame

	_test_the_horseshoe_reaches_both_the_field_and_the_shape()
	_test_the_horseshoe_survives_the_rebuild()
	_test_the_horseshoe_is_counted_once()

	GameManager.collected_relics = _relics_backup
	GameManager.equipment_slots = _equipment_backup
	GameManager.meridian_upgrades = _meridians_backup
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 41.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the relic lands on both the number and the circle ---------------------

## The two halves of the same pickup range. magnet_radius is what the pause panel
## prints; the CircleShape2D is what the MagnetArea tests incoming gems against.
## Before the fix only the shape ever moved, so the two disagreed by the relic's
## whole bonus for as long as the player held it.
func _test_the_horseshoe_reaches_both_the_field_and_the_shape() -> void:
	var advertised := _relic_pickup_bonus()
	if not check(advertised > 0.0, "Golden Horseshoe advertises a pickup radius bonus"):
		return

	var expected := _base_pickup_range() + advertised
	_collect_relic()

	check(is_equal_approx(_player.magnet_radius, expected),
		"The field the pause panel displays includes the advertised +%s (expected %s, got %s)"
			% [advertised, expected, _player.magnet_radius])

	var shape := _magnet_shape()
	if check(shape != null, "The MagnetArea carries the CircleShape2D that collects gems"):
		check(is_equal_approx(shape.radius, expected),
			"...and so does the collection circle (expected %s, got %s)" % [expected, shape.radius])
		check(is_equal_approx(shape.radius, _player.magnet_radius),
			"...and the two agree, because exactly one function writes the circle (field %s, circle %s)"
				% [_player.magnet_radius, shape.radius])

# --- 2. the rebuild no longer erases it ---------------------------------------

func _test_the_horseshoe_survives_the_rebuild() -> void:
	var advertised := _relic_pickup_bonus()
	if not check(advertised > 0.0, "Golden Horseshoe advertises a pickup radius bonus"):
		return

	var expected := _base_pickup_range() + advertised
	_collect_relic()

	# The bug. Nine callers reach here and three of them are the pause shop, so this
	# is the single line that decides whether the relic outlives the player's first
	# purchase of anything at all.
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.magnet_radius, expected),
		"The bonus survives refresh_meta_stats() (expected %s, got %s)" % [expected, _player.magnet_radius])

	var shape := _magnet_shape()
	if shape:
		check(is_equal_approx(shape.radius, expected),
			"...including the collection circle (expected %s, got %s)" % [expected, shape.radius])

	# End to end, through the purchase the player actually makes: the pause shop's
	# meridian rows call refresh_meta_stats() from inside buy_meridian_upgrade().
	GameManager.buy_meridian_upgrade("doc_mach")
	check(is_equal_approx(_player.magnet_radius, expected),
		"...and survives buying a meridian from the pause shop (expected %s, got %s)"
			% [expected, _player.magnet_radius])
	GameManager.meridian_upgrades.erase("doc_mach")

# --- 3. no double count --------------------------------------------------------

## Mage's +60 and the relic's +60 are two different bonuses and both are real. The
## old line added char_magnet_bonus on top of a magnet_radius that already contained
## it, so holding the relic made a mage collect in a 320 circle rather than a 260.
## Comparing the with- and without-relic rebuilds is character-agnostic: whatever the
## character's own bonus is, holding the relic must move the circle by exactly the
## amount the relic advertises, no more.
func _test_the_horseshoe_is_counted_once() -> void:
	var advertised := _relic_pickup_bonus()
	if not check(advertised > 0.0, "Golden Horseshoe advertises a pickup radius bonus"):
		return

	GameManager.select_character("mage")
	_player.apply_character_data()

	GameManager.collected_relics.erase("golden_horseshoe")
	_player.refresh_meta_stats()
	var without := _player.magnet_radius

	_collect_relic()
	_player.refresh_meta_stats()
	var with_relic := _player.magnet_radius

	check(is_equal_approx(with_relic - without, advertised),
		"A character's own pickup bonus is counted once: holding the relic widens the circle by its advertised +%s and nothing more (moved %s)"
			% [advertised, with_relic - without])

	var shape := _magnet_shape()
	if shape:
		check(is_equal_approx(shape.radius, with_relic),
			"...and the circle still matches the field (field %s, circle %s)" % [with_relic, shape.radius])

# --- helpers -------------------------------------------------------------------

## Add the relic the way the floor pickup does. add_relic() reaches the player
## through the "player" group and calls apply_relic_effects() on it -- the single
## frame the old code applied the bonus on.
func _collect_relic() -> void:
	GameManager.collected_relics.erase("golden_horseshoe")
	check(GameManager.add_relic("golden_horseshoe"),
		"The Golden Horseshoe is collectable for this measurement")

## The pickup range the rebuild produces with no relic in hand, on the current
## character. Everything except the relic's own contribution, including any
## character bonus and any meta magnetism rank.
func _base_pickup_range() -> float:
	GameManager.collected_relics.erase("golden_horseshoe")
	_player.refresh_meta_stats()
	return _player.magnet_radius

func _magnet_shape() -> CircleShape2D:
	if not _player.magnet_area or not _player.magnet_area.has_node("CollisionShape2D"):
		return null
	return _player.magnet_area.get_node("CollisionShape2D").shape as CircleShape2D

## The radius the relic's own desc advertises, parsed rather than restated, for the
## reason Expansion 39.0 gave: a test that hardcodes the code's number cannot tell a
## relic that works from one that is wrong in the same direction as the assertion.
## "+50% Gold drops & +60 Magnet Radius" -- the first number is the other half of
## this relic, so the parser takes the field after the "&".
func _relic_pickup_bonus() -> float:
	var desc: String = String(GameManager.RELICS["golden_horseshoe"]["desc"])
	var parts: PackedStringArray = desc.split("&")
	if parts.size() < 2:
		return 0.0
	var n := ""
	for c in parts[1]:
		if c >= "0" and c <= "9":
			n += c
		elif not n.is_empty():
			break
	return float(n) if not n.is_empty() else 0.0