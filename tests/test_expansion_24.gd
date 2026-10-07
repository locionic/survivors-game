extends Node

## Automated Test Suite for Expansion 24.0:
## "Hoang Tàn" -- the two leftovers from the same audit: a DoT rate that latched
## forever, and a meridian that described an effect nothing applied.
##
## Both are regressions over live, silent bugs:
##   * apply_burn()/apply_poison() do max() on the dps -- correct while the effect
##     is up, wrong forever after, because the timer decayed and the rate did not.
##     One 35.2 dragon breath silently upgraded every later fireball burn to 35.2
##     for the rest of the fight.
##   * Đan Điền has read "+30% Dragon Soul & +20% AoE per level" in the meridian
##     table since the Codex shipped. The Dragon Soul half was wired; the AoE half
##     was not, because blast_radius_multiplier is rebuilt by one line in
##     refresh_meta_stats() and that line had no dan_dien term.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")

## buy_meridian_upgrade() persists to user://save_data.cfg immediately, so this
## suite would spend the developer's real meta gold. Backed up and restored.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.m24bak"
var _had_save: bool = false

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

var _meridians_backup: Dictionary = {}
var _player: Player = null
var _victim: Node2D = null

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
	print("=== RUNNING EXPANSION 24.0 TEST SUITE ===")
	GameManager.is_run_active = false
	_meridians_backup = GameManager.meridian_upgrades.duplicate()

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.current_health = _player.max_health
	# This suite is about what lands on a victim, so the player's own weapons are
	# silenced: a live fireball would keep re-applying burn and the dps being
	# measured would be the player's, not the test's.
	_freeze_player_weapons()

	await _test_burn_rate_is_handed_back_when_the_burn_ends()
	await _test_poison_rate_is_handed_back_too()
	await _test_thermal_shockwave_does_not_leave_a_burn_behind()
	await _test_dan_dien_aoe_is_real()

	_drop(_victim)
	_drop(_player)
	GameManager.meridian_upgrades = _meridians_backup
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 24.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. burn_dps ------------------------------------------------------------

## The original bug in one shape. apply_burn() did
##     burn_timer = max(burn_timer, duration)
##     burn_dps   = max(burn_dps, dps)
## and only the first of those ever came back down. The rate was a per-enemy
## high-water mark for the rest of the fight.
func _test_burn_rate_is_handed_back_when_the_burn_ends() -> void:
	_player.char_burn_mult = 1.0
	_victim = _spawn_victim(9000.0)
	_victim.apply_burn(0.4, 40.0)
	check(is_equal_approx(_victim.burn_dps, 40.0),
		"A 40 dps burn is applied at 40 dps, got %s" % _victim.burn_dps)

	# Overlapping burns should still take the strongest: max() is right here.
	_victim.apply_burn(0.4, 12.0)
	check(is_equal_approx(_victim.burn_dps, 40.0),
		"A weaker burn on top of a stronger one does not lower the rate, got %s" % _victim.burn_dps)

	await _await_handed_back(_victim, "burn_timer", "burn_dps")
	check(_victim.burn_timer <= 0.0, "Precondition: the burn has expired (timer %s)" % _victim.burn_timer)
	check(is_equal_approx(_victim.burn_dps, 0.0),
		"The burn rate is handed back when the effect ends, got %s" % _victim.burn_dps)

	# The consequence, in the value the DoT tick actually reads:
	# `max(1.0, burn_dps * 0.35)` in enemy._physics_process(). Measured on the
	# field rather than as a health delta on purpose -- the test scene has a live
	# player, live collision bodies and projectiles in flight, and an HP delta
	# picks up hits that have nothing to do with the burn. The rate the engine
	# will read is the whole claim, so that is what is asserted.
	_victim.current_health = 9000.0
	_victim.apply_burn(0.4, 40.0)
	await _await_handed_back(_victim, "burn_timer", "burn_dps")
	check(is_equal_approx(_victim.burn_dps, 0.0),
		"Precondition: the 40 dps burn expired and handed its rate back, got %s" % _victim.burn_dps)

	_victim.apply_burn(0.4, 10.0)
	check(is_equal_approx(_victim.burn_dps, 10.0),
		"A later 10 dps burn ticks at max(1.0, 10.0 * 0.35) = 3.5, not at the old 40 dps high-water mark of 14 (got %s)" % _victim.burn_dps)
	check(is_equal_approx(maxf(1.0, _victim.burn_dps * 0.35), 3.5),
		"...so the tick the engine computes is the weak one")

# --- 2. and the same for poison ---------------------------------------------

func _test_poison_rate_is_handed_back_too() -> void:
	_victim.poison_dps = 0.0
	_victim.poison_timer = 0.0
	_victim.apply_poison(0.4, 26.0)
	check(is_equal_approx(_victim.poison_dps, 26.0),
		"A 26 dps poison is applied at 26 dps, got %s" % _victim.poison_dps)

	await _await_handed_back(_victim, "poison_timer", "poison_dps")
	check(_victim.poison_timer <= 0.0, "Precondition: the poison has expired (timer %s)" % _victim.poison_timer)
	check(is_equal_approx(_victim.poison_dps, 0.0),
		"The poison rate is handed back when the effect ends, got %s" % _victim.poison_dps)

	_victim.apply_poison(2.0, 6.0)
	check(is_equal_approx(_victim.poison_dps, 6.0),
		"A later 6 dps poison is not silently upgraded to the old 26 dps, got %s" % _victim.poison_dps)

# --- 3. and the shockwave that cancels a burn ------------------------------

## apply_burn() and apply_freeze() both hand off to _trigger_thermal_shockwave()
## when the other element is up, and that cleared the timer -- but not the rate.
func _test_thermal_shockwave_does_not_leave_a_burn_behind() -> void:
	_victim.burn_dps = 0.0
	_victim.burn_timer = 0.0
	_victim.freeze_timer = 0.0
	_victim.apply_burn(3.0, 44.0)
	check(is_equal_approx(_victim.burn_dps, 44.0), "Precondition: the burn is up at 44 dps")

	_victim.apply_freeze(1.0)
	check(is_equal_approx(_victim.burn_timer, 0.0) and is_equal_approx(_victim.freeze_timer, 0.0),
		"Precondition: the shockwave fired and cancelled both elements")
	check(is_equal_approx(_victim.burn_dps, 0.0),
		"The shockwave clears the burn rate too, not just the timer, got %s" % _victim.burn_dps)

# --- 4. Đan Điền's advertised AoE ------------------------------------------

## game_manager.gd reads "+30% Dragon Soul & +20% AoE per level". The Dragon Soul
## half was applied (dragon_soul_harvest_mult, +30% a rank). The AoE half had no
## term anywhere: refresh_meta_stats() rebuilds blast_radius_multiplier from
## char_area_bonus and the Pyro meta stat, and the meridian was simply not
## in the list.
func _test_dan_dien_aoe_is_real() -> void:
	GameManager.meridian_upgrades.erase("dan_dien")
	_player.refresh_meta_stats()
	var fire_wpn = _player.get_node_or_null("Weapons/FireballWeapon")
	if not check(fire_wpn != null and "blast_radius_multiplier" in fire_wpn,
			"Precondition: the player has a FireballWeapon with a blast radius"):
		return
	var base := float(fire_wpn.blast_radius_multiplier)
	# Đan Điền adds its +20% *inside* the parenthesis in refresh_meta_stats(), and
	# Ỷ Thiên Kiếm's +25% then scales the whole expression -- so the per-rank step
	# observed here is 0.20 * sword, not a flat 0.20. Read the factor from the save
	# rather than hardcoding a number that only holds on one machine's equipment.
	var sword := 1.25 if GameManager.has_equipped("y_thien_kiem") and fire_wpn.has_method("upgrade_blast_radius") else 1.0

	GameManager.meridian_upgrades["dan_dien"] = 5
	_player.refresh_meta_stats()
	var five := float(fire_wpn.blast_radius_multiplier)
	check(is_equal_approx(five - base, 5.0 * 0.20 * sword),
		"5 ranks of Đan Điền are +100%% AoE before Ỷ Thiên Kiếm (expected a step of %s, got %s)" % [5.0 * 0.20 * sword, five - base])

	# The real purchase path, not just the recompute: buy_meridian_upgrade()
	# calls refresh_meta_stats() for every meridian, so this is the same line a
	# player in the pause menu would run.
	GameManager.meridian_upgrades.erase("dan_dien")
	_player.refresh_meta_stats()
	GameManager.total_gold = 999999
	GameManager.buy_meridian_upgrade("dan_dien")
	var one := float(fire_wpn.blast_radius_multiplier)
	check(is_equal_approx(one - base, 0.20 * sword),
		"Buying one rank grants exactly one +20%% (expected a step of %s, got %s)" % [0.20 * sword, one - base])
	check(is_equal_approx(five - base, 5.0 * (one - base)),
		"...and the effect is linear in the rank, not compounding")

	# The other advertised half, to show the meridian was half-wired and this is
	# the half that was missing.
	check(is_equal_approx(_player.dragon_soul_harvest_mult, 1.30),
		"One rank is also +30%% Dragon Soul harvest, got %s" % _player.dragon_soul_harvest_mult)

	GameManager.meridian_upgrades.erase("dan_dien")
	_player.refresh_meta_stats()
	check(is_equal_approx(float(fire_wpn.blast_radius_multiplier), base),
		"Dropping the meridian back to zero restores the base radius, got %s" % fire_wpn.blast_radius_multiplier)

# --- helpers ----------------------------------------------------------------

## A victim isolated from autonomous targeting while its own DoT is measured.
##
## `player = null` and a long way out, deliberately. With a player attached the
## enemy chases, walks into the knight's shield_charge (45 x might, one hit for
## 58) and its HP delta stops being a measurement of burn at all. It is also
## removed from the enemies group: a projectile already in flight can outlive
## its disabled weapon and refresh this victim's burn during the expiry wait.
## The direct status-effect calls below do not require group membership.
func _spawn_victim(hp: float) -> Node2D:
	GameManager.collected_relics.erase("storm_amulet")
	var e := ENEMY_SCENE.instantiate() as Node2D
	add_child(e)
	e.remove_from_group("enemies")
	e.player = null
	e.global_position = Vector2(2000, 0)
	e.max_health = hp
	e.current_health = hp
	e.move_speed = 0.0
	return e

func _freeze_player_weapons() -> void:
	for w in _player.get_node("Weapons").get_children():
		w.set_physics_process(false)
		w.process_mode = Node.PROCESS_MODE_DISABLED

## Waits for a DoT effect to be fully handed back, giving up after `max_frames`.
##
## This replaces a fixed `_physics_frames(40)` at the three burn/poison preconditions,
## and the fixed count was the suite's own flakiness. 40 physics ticks is 0.667s
## against a 0.4s burn, which is ample -- unless something re-applies the effect
## mid-wait. _freeze_player_weapons() disables the weapon NODES, but a projectile
## already in flight is parented to the scene, not to the weapon
## (fireball_weapon.gd:94), so it keeps firing: fireball_projectile.gd:63 re-applies
## a 3.5s burn on impact. Whether a fireball happens to be mid-flight is pure frame
## timing, so the precondition read a live 2.88s timer about one run in four.
##
## It waits on the timer AND the rate together, not the timer alone. enemy.gd:182-188
## zeroes `burn_dps` in the same tick the timer crosses zero, so a fireball landing
## one frame after that crossing puts the rate straight back to 40 -- and a waiter that
## returned the instant the timer read 0.0 would still be asserting a stale value.
## Measured 2026-10-02: 2 of 8 runs failed on the timer alone, and 1 of 12 after that
## fix; the joint condition is what the precondition actually means.
##
## Note that FireballProjectile extends Area2D directly rather than projectile.gd, so
## it never joins the "projectiles" group -- freezing by group would have missed
## exactly the case that matters. Waiting for the thing being asserted is both simpler
## and correct regardless of what is in flight.
func _await_handed_back(node: Node, timer_prop: String, rate_prop: String, max_frames: int = 600) -> void:
	for _i in max_frames:
		if float(node.get(timer_prop)) <= 0.0 and float(node.get(rate_prop)) <= 0.0:
			return
		await get_tree().physics_frame

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()
