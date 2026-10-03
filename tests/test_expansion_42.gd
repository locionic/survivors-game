extends Node

## Automated Test Suite for Expansion 42.0:
## "Miễn Nhiễm Hiệu Ứng Làm Chậm" -- Vân Hạc Hài promises immunity to slow effects and
## granted it against exactly one of the two.
##
## The boots' own row (game_manager.gd:151) reads:
##
##     "+30 Tốc độ di chuyển & Miễn nhiễm hiệu ứng làm chậm"
##
## The +30 landed in refresh_meta_stats() and has always been right. The immunity
## was a guard inside apply_blizzard_slow() only. But the glacial champion's aura
## does not call that function -- it writes the lease field straight onto the
## player, every physics frame it is within 170px:
##
##     enemy.gd:251     player.glacial_slow_timer = maxf(..., 0.2)
##
## and the timer was consumed in the movement maths with no gate at all. So the
## boots ignored a blizzard and did nothing about the one slow a player meets in
## every wave -- the exact promise the row had been making for the rest of the
## game.
##
## The fix puts the gate where both timers are consumed rather than in each of the
## two producers, so the glacial aura needed no change and the next slow to be
## added is covered by writing no new code at all.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")

## equip_gear() persists to user://save_data.cfg immediately.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e42bak"
var _had_save: bool = false

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

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
	print("=== RUNNING EXPANSION 42.0 TEST SUITE ===")
	GameManager.is_run_active = false

	_equipment_backup = GameManager.equipment_slots.duplicate()
	GameManager.equipment_slots["boots"] = ""
	_meridians_backup = GameManager.meridian_upgrades.duplicate()
	for mid in GameManager.MERIDIANS.keys():
		GameManager.meridian_upgrades.erase(mid)
	GameManager.total_gold = 999999

	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)
	_player.current_health = _player.max_health
	await get_tree().process_frame

	# Awaited, not just called. A function containing await is a coroutine: called
	# bare it suspends at its first await and _ready() marches straight on, so the
	# cases that wait on physics frames would run only the lines before that await
	# and then be cut off by the quit() below. Two of the four cases here are
	# exactly that shape, and the symptom is a suite that looks green.
	await _test_the_glacial_aura_still_slows_a_barefoot_player()
	await _test_the_glacial_aura_cannot_slow_an_immune_player()
	await _test_the_blizzard_immunity_still_holds()
	await _test_both_slows_at_once()

	_drop(_player)
	GameManager.equipment_slots = _equipment_backup
	GameManager.meridian_upgrades = _meridians_backup
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 42.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the slow is real without the boots -----------------------------------

## The control for every other case here. If the glacial aura did nothing at all,
## "the boots do nothing to it" would be a test that passes for the wrong reason --
## which is the failure mode a fix of this shape is most likely to have.
func _test_the_glacial_aura_still_slows_a_barefoot_player() -> void:
	check(not _player.is_slow_immune(),
		"With no boots the player is not immune to anything")

	_player.glacial_slow_timer = 0.0
	var champ := _spawn_glacial_champion()
	await _physics_frames(3)

	check(_player.glacial_slow_timer > 0.0,
		"A glacial champion inside 170px takes a slow lease, got %s" % _player.glacial_slow_timer)
	check(_player.get_slow_multiplier() < 1.0,
		"...and that lease costs a barefoot player speed (multiplier %s)" % _player.get_slow_multiplier())

	_drop(champ)
	await _physics_frames(24)
	_player.glacial_slow_timer = 0.0

# --- 2. the bug ----------------------------------------------------------------

## The same champion, the same three frames, the same aura radius -- with the boots
## the row has advertised since the gear was added.
func _test_the_glacial_aura_cannot_slow_an_immune_player() -> void:
	check(GameManager.equip_gear("boots", "van_hac_hai"),
		"Vân Hạc Hài equips")
	_player.refresh_meta_stats()
	check(_player.is_slow_immune(),
		"The boots grant the slow immunity their row advertises")

	_player.glacial_slow_timer = 0.0
	var champ := _spawn_glacial_champion()
	await _physics_frames(3)

	# The aura may still take its lease -- the champion is still doing what it was
	# built to do, and nothing about the boots is meant to disarm an elite. The
	# claim under test is that the lease no longer costs the player speed.
	check(is_equal_approx(_player.get_slow_multiplier(), 1.0),
		"A glacial champion cannot slow an immune player (multiplier %s, lease %s)"
			% [_player.get_slow_multiplier(), _player.glacial_slow_timer])

	# And the lease it does take still expires on its own, so immunity is not a
	# second latch left over from Expansion 23.0's fix.
	_drop(champ)
	await _physics_frames(24)
	check(_player.glacial_slow_timer <= 0.0,
		"The lease still expires on its own once the champion is gone, got %s" % _player.glacial_slow_timer)

	# Boots off, and the very same timer bites again -- proving the gate really is
	# the equipment and not some residue this case left on the player.
	GameManager.equipment_slots["boots"] = ""
	check(not _player.is_slow_immune(),
		"Taking the boots off ends the immunity")
	_player.glacial_slow_timer = 0.2
	check(_player.get_slow_multiplier() < 1.0,
		"...and the glacial slow bites again straight afterwards (multiplier %s)"
			% _player.get_slow_multiplier())
	_player.glacial_slow_timer = 0.0
	GameManager.equip_gear("boots", "van_hac_hai")

# --- 3. the half that already worked -------------------------------------------

## The blizzard guard was the one place the immunity was checked, so it is the
## regression this fix could most easily have broken.
func _test_the_blizzard_immunity_still_holds() -> void:
	_player.blizzard_slow_timer = 0.0
	_player.apply_blizzard_slow(3.0)
	check(is_equal_approx(_player.blizzard_slow_timer, 0.0),
		"An immune player never takes the blizzard slow (timer %s)" % _player.blizzard_slow_timer)
	check(is_equal_approx(_player.get_slow_multiplier(), 1.0),
		"...and pays no blizzard penalty (multiplier %s)" % _player.get_slow_multiplier())

	GameManager.equipment_slots["boots"] = ""
	_player.apply_blizzard_slow(3.0)
	check(_player.blizzard_slow_timer > 0.0,
		"A barefoot player does take it (timer %s)" % _player.blizzard_slow_timer)
	check(_player.get_slow_multiplier() < 1.0,
		"...and pays the penalty (multiplier %s)" % _player.get_slow_multiplier())
	_player.blizzard_slow_timer = 0.0
	GameManager.equip_gear("boots", "van_hac_hai")

# --- 4. both at once ----------------------------------------------------------

## Glacial and blizzard are two independent timers. Immunity has to suppress the
## sum, not one term of it.
func _test_both_slows_at_once() -> void:
	GameManager.equipment_slots["boots"] = "van_hac_hai"
	check(_player.is_slow_immune(), "Equipping the boots through the slot map is enough")

	_player.glacial_slow_timer = 0.2
	_player.blizzard_slow_timer = 3.0
	check(is_equal_approx(_player.get_slow_multiplier(), 1.0),
		"Both slows at once cost an immune player nothing (multiplier %s)"
			% _player.get_slow_multiplier())

	GameManager.equipment_slots["boots"] = ""
	var both := _player.get_slow_multiplier()
	check(both < 1.0, "The same two slows together do cost a barefoot player (multiplier %s)" % both)
	check(both < _player.GLACIAL_SLOW,
		"...by both factors, not just the glacial one (multiplier %s, glacial alone %s)"
			% [both, _player.GLACIAL_SLOW])

	_player.glacial_slow_timer = 0.0
	_player.blizzard_slow_timer = 0.0
	GameManager.equip_gear("boots", "van_hac_hai")

# --- helpers -------------------------------------------------------------------

func _spawn_glacial_champion() -> Node2D:
	var e := ENEMY_SCENE.instantiate() as Node2D
	e.player = _player
	add_child(e)
	e.global_position = _player.global_position + Vector2(100, 0)
	e.current_health = 9000.0
	e.set_physics_process(true)
	e.is_champion = true
	e.champion_affix = "glacial"
	return e

func _physics_frames(n: int) -> void:
	for _i in range(n):
		await get_tree().physics_frame

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
		await get_tree().process_frame
