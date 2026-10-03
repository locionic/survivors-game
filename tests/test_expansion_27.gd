extends Node

## Automated Test Suite for Expansion 27.0:
## "Lưỡi Cùng Giờ" -- the Chrono Hourglass covered four of the five weapons with a
## cooldown.
##
## The relic reads "-20% Weapon Cooldowns", and the one place that applied it listed
## the weapons by hand:
##
##     MainWeapon, LightningWeapon, FireballWeapon, AxeWeapon
##
## That is four of the five nodes in the scene that read speed_multiplier into their
## cooldown (slash_weapon.gd:82 does exactly what the other four do). SlashWeapon --
## Độc Cô Cửu Kiếm, the tier-3 blade -- was simply not in the list, so a player who
## owned the relic and the blade got no cooldown reduction from either. OrbitingWeapon
## is legitimately excluded: it has no speed_multiplier and no cooldown at all.
##
## The fix sweeps the Weapons container instead of naming nodes, which also means the
## next weapon added to the scene is covered without anyone remembering to list it.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

var _relics_backup: Array[String] = []
var _player: Player = null

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 27.0 TEST SUITE ===")
	GameManager.is_run_active = false
	_relics_backup = GameManager.collected_relics.duplicate()

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.current_health = _player.max_health

	_test_the_blade_gets_the_relic_too()
	_test_every_weapon_with_a_cooldown_is_covered()
	_test_the_sweep_is_idempotent()
	_test_no_relic_still_means_no_change()

	GameManager.collected_relics = _relics_backup
	_drop(_player)

	if _failures.is_empty():
		print("=== ALL EXPANSION 27.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the weapon the list was missing ---------------------------------------

func _test_the_blade_gets_the_relic_too() -> void:
	var slash := _weapon("SlashWeapon")
	if not check(slash != null, "Precondition: the player has a SlashWeapon"):
		return
	# Same shape of precondition as the other four: the relic is a no-op on a node
	# that has no cooldown to shorten, so this is the field under test.
	check("speed_multiplier" in slash, "Precondition: the slash reads a speed_multiplier")

	_normalise_all_speeds()
	_grant_relic("chrono_hourglass")
	_player.apply_relic_effects()

	check(is_equal_approx(float(slash.get("speed_multiplier")), 1.25),
		"Độc Cô Cửu Kiếm gets the Chrono Hourglass cooldown reduction, got %s"
			% slash.get("speed_multiplier"))

# --- 2. and it is a sweep, not a longer list ---------------------------------

func _test_every_weapon_with_a_cooldown_is_covered() -> void:
	_normalise_all_speeds()
	_player.apply_relic_effects()

	var covered: Array[String] = []
	for w in _weapons().get_children():
		if "speed_multiplier" in w:
			covered.append(w.name)
			check(is_equal_approx(float(w.get("speed_multiplier")), 1.25),
				"%s reads a speed_multiplier into its cooldown and must be covered, got %s"
					% [w.name, w.get("speed_multiplier")])

	check(covered.size() >= 5,
		"Five weapons in the scene have a cooldown to shorten, the sweep covered %d (%s)"
			% [covered.size(), ", ".join(covered)])

	# OrbitingWeapon orbits on a rotation, it has no attack cooldown -- so it is the
	# one node the "in node" guard is there to skip. Asserted because if it ever grew
	# a cooldown, the guard would need to start covering it.
	var orbit := _weapon("OrbitingWeapon")
	if check(orbit != null, "Precondition: the player has an OrbitingWeapon"):
		check(not ("speed_multiplier" in orbit),
			"OrbitingWeapon still has no cooldown to shorten, so excluding it is correct")

# --- 3. a relic that can be applied twice must not compound -------------------

## The relic is granted through add_relic(), which is one-shot today, but a floor of
## 1.25 applied as a multiply would quietly grow the player's attack speed on every
## future call. maxf() is what makes this safe to re-run.
func _test_the_sweep_is_idempotent() -> void:
	_normalise_all_speeds()
	_player.apply_relic_effects()
	_player.apply_relic_effects()
	_player.apply_relic_effects()

	for w in _weapons().get_children():
		if "speed_multiplier" in w:
			check(is_equal_approx(float(w.get("speed_multiplier")), 1.25),
				"%s is still 1.25 after three applications, got %s" % [w.name, w.get("speed_multiplier")])

	# A weapon already faster than the floor keeps its own speed rather than being
	# dragged down to it.
	var slash := _weapon("SlashWeapon")
	slash.set("speed_multiplier", 1.6)
	_player.apply_relic_effects()
	check(is_equal_approx(float(slash.get("speed_multiplier")), 1.6),
		"A weapon already above the floor keeps its own speed, got %s" % slash.get("speed_multiplier"))

# --- 4. and without the relic nothing happens --------------------------------

func _test_no_relic_still_means_no_change() -> void:
	_normalise_all_speeds()
	GameManager.collected_relics.erase("chrono_hourglass")
	_player.apply_relic_effects()

	for w in _weapons().get_children():
		if "speed_multiplier" in w:
			check(is_equal_approx(float(w.get("speed_multiplier")), 1.0),
				"Without the relic %s is untouched, got %s" % [w.name, w.get("speed_multiplier")])

# --- helpers ----------------------------------------------------------------

## Every weapon's speed_multiplier reset to the field's own default, so the
## developer's save cannot make this suite pass or fail for the wrong reason. The
## relic applies a floor of 1.25, which is only observable from below it.
func _normalise_all_speeds() -> void:
	for w in _weapons().get_children():
		if "speed_multiplier" in w:
			w.set("speed_multiplier", 1.0)

## Written into the list directly rather than through add_relic(), which looks the
## relic up the same way but which this suite has no reason to fire for its signal
## side effects.
func _grant_relic(id: String) -> void:
	if not GameManager.collected_relics.has(id):
		GameManager.collected_relics.append(id)

func _weapons() -> Node2D:
	return _player.get_node("Weapons")

func _weapon(weapon_name: String) -> Node:
	return _weapons().get_node_or_null(weapon_name)

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()
