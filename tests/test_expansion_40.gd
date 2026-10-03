extends Node

## Automated Test Suite for Expansion 40.0:
## "Hai thẻ nâng cấp tự xóa chính mình" -- two level-up cards were erased by the
## next stat rebuild, so the run's most common pick did nothing.
##
## Every level-up offers four Universal Passive cards unconditionally
## (upgrade_manager.gd:383-388), and two of them multiply a player field in place:
##
##     upgrade_manager.gd:704   player.move_speed *= 1.15
##     upgrade_manager.gd:707   player.magnet_radius *= 1.30
##
## Both of those fields are REASSIGNED from a base expression on every
## refresh_meta_stats() -- player.gd:338 and :339 -- so the in-place multiply is
## discarded by the next rebuild. There is no run-scoped source for either, so
## unlike the Liệt Hỏa Phần Thiên radius (fireball_weapon.gd:21) or the meridian
## cooldown (player.gd:396), nothing had been routed to preserve them: the numbers
## were being multiplied onto a value the next call replaced.
##
## The rebuild is not a rare event. Nine sites call refresh_meta_stats(), three of
## them in the pause shop the player opens between any two fights:
##
##     hud.gd:1237   bought a meta upgrade      hud.gd:1278   bought a meridian
##     hud.gd:2236   (settings / respec)         game_manager.gd:490, :1026
##     codex_manager.gd:203   claimed a codex reward
##     character_select_ui.gd:330   re-equipped gear
##
## So: pick "+15% Tốc Độ Di Chuyển Thần Tốc", open the pause shop, buy one Vitality
## rank for 40 gold, and the speed card is gone. The magnet card is worse, because
## refresh_meta_stats() pushes magnet_radius into the Area2D's CircleShape2D at
## player.gd:345 -- the shape is what actually vacuums gems -- so both the number
## and the thing that does the collecting are rolled back together.
##
## The fix is the pattern the file already used for move speed: a run-scoped
## multiplier that survives the rebuild. run_speed_mult already existed for the
## wave shop's Speed scroll; run_magnet_mult did not exist and does now.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## buy_meridian_upgrade() spends total_gold and persists to user://save_data.cfg,
## so this suite needs the developer's real meta wallet back at the end.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e40bak"
var _had_save: bool = false

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

var _meridians_backup: Dictionary = {}
var _equipment_backup: Dictionary = {}
var _player: Player = null
var _up: UpgradeManager = null

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
	print("=== RUNNING EXPANSION 40.0 TEST SUITE ===")
	# Keep the tree inert so the suite, not the autoload, decides when a run runs.
	GameManager.is_run_active = false

	_meridians_backup = GameManager.meridian_upgrades.duplicate()
	for mid in GameManager.MERIDIANS.keys():
		GameManager.meridian_upgrades.erase(mid)
	# Vạn Hạc Hai adds a FLAT +30 to move_speed at player.gd:421, after the rebuild
	# line, so it does not scale with the card's multiplier. Leave it equipped and
	# "base * 1.15" is simply the wrong formula -- same lesson as pinning
	# storm_amulet before measuring damage. Cleared so the card is measured against
	# a clean rebuild; restored at teardown because buy_meridian_upgrade() persists
	# equipment_slots.
	_equipment_backup = GameManager.equipment_slots.duplicate()
	for slot in GameManager.equipment_slots.keys():
		GameManager.equipment_slots[slot] = ""
	# Five ranks cost 1437 and buy_meridian_upgrade() refuses rather than clamps.
	GameManager.total_gold = 999999

	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)
	GameManager.select_character("knight")
	_player.apply_character_data()
	_player.current_health = _player.max_health
	# apply_character_data() assigns char_speed_mult but does not rebuild, so
	# move_speed is still whatever the scene shipped with. Baseline against the
	# rebuild's own output instead -- the invariant under test is "the card
	# multiplies the value refresh_meta_stats() produces", so the base has to be
	# that value or the assertion is measuring the wrong pair of numbers.
	_player.refresh_meta_stats()
	_up = UpgradeManager.new()
	add_child(_up)
	_up.player = _player
	await get_tree().process_frame

	_test_the_speed_card_survives_a_rebuild()
	_test_the_magnet_card_survives_a_rebuild()

	GameManager.meridian_upgrades = _meridians_backup
	GameManager.equipment_slots = _equipment_backup
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 40.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. move speed ------------------------------------------------------------

## "Lăng Ba Vi Bộ" -- offered at every single level-up, so this is the most-picked
## card in the game and the one that vanishes most easily.
func _test_the_speed_card_survives_a_rebuild() -> void:
	var promised := _advertised("move_speed")
	if not check(promised > 1.0, "The move speed card is in the catalog offering a multiplier"):
		return

	var base := _player.move_speed
	_up.select_upgrade({"id": "move_speed"})
	check(is_equal_approx(_player.move_speed, base * promised),
		"The card grants its advertised +%d%% immediately (expected %s, got %s)"
			% [int(round((promised - 1.0) * 100.0)), base * promised, _player.move_speed])

	# The bug. refresh_meta_stats() reassigns move_speed from
	# (230 + bonuses) * char_speed_mult * run_speed_mult, so anything multiplied
	# onto the previous value is gone -- and this is the shared rebuild all nine
	# of its callers route through.
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.move_speed, base * promised),
		"...and survives the stat rebuild (expected %s, got %s)" % [base * promised, _player.move_speed])

	# End to end, through a purchase a player can actually make: the pause shop's
	# meridian rows call refresh_meta_stats() from inside buy_meridian_upgrade().
	GameManager.meridian_upgrades.erase("doc_mach")
	GameManager.buy_meridian_upgrade("doc_mach")
	check(is_equal_approx(_player.move_speed, base * promised),
		"...and survives buying a meridian from the pause shop (expected %s, got %s)"
			% [base * promised, _player.move_speed])
	GameManager.meridian_upgrades.erase("doc_mach")

	# And it stacks with itself rather than replacing: two cards, two multiplies.
	# A run multiplier that were assigned rather than multiplied would read 1.15.
	var once := _player.move_speed
	_up.select_upgrade({"id": "move_speed"})
	check(is_equal_approx(_player.move_speed, once * promised),
		"Two copies stack multiplicatively (expected %s, got %s)" % [once * promised, _player.move_speed])
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.move_speed, once * promised),
		"...and the stack survives a rebuild too (expected %s, got %s)"
			% [once * promised, _player.move_speed])

# --- 2. pickup range ----------------------------------------------------------

## "Hấp Tinh Đại Pháp". The same card shape, plus the shape radius: line 345 writes
## magnet_radius into the CollisionShape2D, and that circle is what the player's
## MagnetArea tests incoming gems against, so a rolled-back magnet_radius takes
## the collector with it.
func _test_the_magnet_card_survives_a_rebuild() -> void:
	var promised := _advertised("magnet")
	if not check(promised > 1.0, "The magnet card is in the catalog offering a multiplier"):
		return

	var base := _player.magnet_radius
	_up.select_upgrade({"id": "magnet"})
	check(is_equal_approx(_player.magnet_radius, base * promised),
		"The card grants its advertised +%d%% immediately (expected %s, got %s)"
			% [int(round((promised - 1.0) * 100.0)), base * promised, _player.magnet_radius])

	_player.refresh_meta_stats()
	check(is_equal_approx(_player.magnet_radius, base * promised),
		"...and survives the stat rebuild (expected %s, got %s)" % [base * promised, _player.magnet_radius])

	var shape: CircleShape2D = _magnet_shape()
	if check(shape != null, "The MagnetArea carries the CircleShape2D that collects gems"):
		check(is_equal_approx(shape.radius, base * promised),
			"...and so does the collection shape itself (expected %s, got %s)"
				% [base * promised, shape.radius])

	GameManager.meridian_upgrades.erase("doc_mach")
	GameManager.buy_meridian_upgrade("doc_mach")
	check(is_equal_approx(_player.magnet_radius, base * promised),
		"...and survives buying a meridian from the pause shop (expected %s, got %s)"
			% [base * promised, _player.magnet_radius])
	GameManager.meridian_upgrades.erase("doc_mach")

# --- helpers -------------------------------------------------------------------

func _magnet_shape() -> CircleShape2D:
	if not _player.magnet_area or not _player.magnet_area.has_node("CollisionShape2D"):
		return null
	var shape = _player.magnet_area.get_node("CollisionShape2D").shape
	return shape as CircleShape2D

## The multiplier the catalog's own desc advertises, as a ratio. Read from the live
## catalog rather than restated, for the reason Expansion 39.0 gave: a test that
## hardcodes the code's constant cannot tell a card that works from a card that is
## wrong in the same direction as the assertion. Parsed out of the string the player
## reads -- "+15% Tốc Độ..." and "+30% Phạm Vi..." -- so a rebalance of the card
## follows the card.
func _advertised(card_id: String) -> float:
	for row in _up.get_upgrade_catalog():
		if String(row.get("id", "")) != card_id:
			continue
		var desc: String = String(row.get("desc", ""))
		var n := ""
		for c in desc:
			if c >= "0" and c <= "9":
				n += c
			elif not n.is_empty():
				break
		return 1.0 + float(n) * 0.01 if not n.is_empty() else 0.0
	return 0.0