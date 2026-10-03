extends Node

## Automated Test Suite for Expansion 43.0:
## "Evolving Made Your Weapon Worse" -- two of the six evolution functions ASSIGN an
## absolute value onto a field the player has been buying level-up cards into, so the
## evolution silently removes those cards' effect.
##
##     orbiting_weapon.gd:91   orbit_speed = 5.2
##     slash_weapon.gd:309     slash_range = 140.0
##
## Both weapons offer their card at ranks 1-4 and their evolution at rank 5, so full
## investment ALWAYS precedes evolution. The suite's failure messages are the bug:
##
##     CHECK FAILED: ...and evolving does not take it back (5.2 < 8.3)
##     CHECK FAILED: ...and evolving does not take it back (140 < 268.4375)
##
## These two are not subtle design choices. Five sibling evolutions in the same files
## already use the safe form, and slash_weapon.gd:325 -- the OTHER slash evolution,
## nine lines away -- already does `slash_range = max(slash_range, 150.0)`. The same
## field is floored in one evolution and overwritten in the other.
##
## The claim under test is an invariant, not a number: evolving must never lower a
## field the player has bought cards into. Every value here is read off the live
## objects and every card is bought through select_upgrade(), so no figure in this
## file restates a constant that lives in the game.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ORBIT_SCENE: PackedScene = preload("res://scenes/orbiting_weapon.tscn")
const SLASH_SCENE: PackedScene = preload("res://scenes/slash_weapon.tscn")
const UPGRADE_MANAGER: GDScript = preload("res://scripts/upgrade_manager.gd")

## equip_gear() and friends persist to user://save_data.cfg immediately.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e43bak"
var _had_save: bool = false

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

var _player: Player = null
var _um: UpgradeManager = null

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
	print("=== RUNNING EXPANSION 43.0 TEST SUITE ===")
	GameManager.is_run_active = false

	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)
	_player.current_health = _player.max_health
	await get_tree().process_frame

	# _ready() resolves its weapon references from the player in the "player" group,
	# so this must be added after the player is in the tree. activate_weapon() only
	# flips is_active on the node that is already there, so those references stay
	# valid for the whole run.
	_um = UPGRADE_MANAGER.new() as UpgradeManager
	add_child(_um)
	await get_tree().process_frame

	# Pinned rather than inherited: the level at which each card starts being offered
	# is a precondition, and the save's selected character would otherwise decide it.
	_um.weapon_levels["shield"] = 1
	_um.weapon_levels["slash"] = 1
	_um.weapon_levels["dagger"] = 1

	# Awaited, not just called. A function containing await is a coroutine: called
	# bare it suspends at its first await and _ready() marches straight on.
	await _test_evolving_does_not_unbuy_the_shield_speed_cards()
	await _test_evolving_does_not_unbuy_the_slash_range_cards()
	await _test_evolving_still_pays_out_for_an_uninvested_weapon()
	await _test_the_slash_fusions_still_agree_in_either_order()

	_drop(_player)
	_drop(_um)
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 43.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the shield --------------------------------------------------------------

## The Tai Cuc Ho The card, bought through the real catalog until the game stops
## offering it, then evolved through the real card handler.
func _test_evolving_does_not_unbuy_the_shield_speed_cards() -> void:
	var orbit := _orbit()
	var base: float = orbit.orbit_speed
	var bought := _buy_every_offering("orbit_speed")
	check(bought > 0, "the shield speed card is offerable at all, bought %d" % bought)

	var invested: float = orbit.orbit_speed
	check(invested > base,
		"the %d shield speed cards move orbit_speed (%s -> %s)" % [bought, base, invested])

	_um.select_upgrade({"id": "evolve_shield"})
	check(orbit.is_evolved, "the shield evolves")

	check(orbit.orbit_speed >= invested,
		"...and evolving does not take it back (%s < %s)" % [orbit.orbit_speed, invested])

# --- 2. the slash ---------------------------------------------------------------

## Phá Khí Thức, the "+25% Bán Kính & Tầm Trảm Kích" card. upgrade_range() scales
## slash_range multiplicatively, so the loss compounds with every rank bought.
func _test_evolving_does_not_unbuy_the_slash_range_cards() -> void:
	var slash := _slash()
	var base: float = slash.slash_range
	var bought := _buy_every_offering("slash_range")
	check(bought > 0, "the slash range card is offerable at all, bought %d" % bought)

	var invested: float = slash.slash_range
	check(invested > base,
		"the %d slash range cards move slash_range (%s -> %s)" % [bought, base, invested])

	_um.select_upgrade({"id": "evolve_slash"})
	check(slash.is_evolved, "the slash evolves")

	check(slash.slash_range >= invested,
		"...and evolving does not take it back (%s < %s)" % [slash.slash_range, invested])

# --- 3. the control -------------------------------------------------------------

## If every evolution were a bare `max()`, a weapon nobody invested in would evolve
## to exactly its floor and the payoff would be nothing. This is the case that makes
## the fix in cases 1 and 2 a floor rather than a no-op.
func _test_evolving_still_pays_out_for_an_uninvested_weapon() -> void:
	var orbit := ORBIT_SCENE.instantiate() as OrbitingWeapon
	add_child(orbit)
	var orbit_base: float = orbit.orbit_speed
	orbit.evolve_to_solar_bulwark()
	check(orbit.orbit_speed > orbit_base,
		"an uninvested shield still speeds up when it evolves (%s -> %s)" % [orbit_base, orbit.orbit_speed])
	_drop(orbit)

	var slash := SLASH_SCENE.instantiate() as SlashWeapon
	add_child(slash)
	var slash_base: float = slash.slash_range
	slash.evolve_to_nine_swords()
	check(slash.slash_range > slash_base,
		"an uninvested slash still reaches further when it evolves (%s -> %s)" % [slash_base, slash.slash_range])
	_drop(slash)

# --- 4. the sibling fusion ------------------------------------------------------

## Both slash evolutions are reachable in one run (Lv.5 slash + Lv.5 shield), so the
## order is the player's to pick. slash_weapon.gd:210 reads slash_damage in
## preference to base_damage whenever it is non-zero, which is what makes the damage
## number order-independent -- and what makes the range's `max()` at :325 load-bearing
## rather than cosmetic.
func _test_the_slash_fusions_still_agree_in_either_order() -> void:
	var a := SLASH_SCENE.instantiate() as SlashWeapon
	add_child(a)
	a.evolve_to_nine_swords()
	a.evolve_to_frost_sovereign()
	var a_range: float = a.slash_range
	var a_damage: float = a.slash_damage

	var b := SLASH_SCENE.instantiate() as SlashWeapon
	add_child(b)
	b.evolve_to_frost_sovereign()
	b.evolve_to_nine_swords()
	var b_range: float = b.slash_range
	var b_damage: float = b.slash_damage

	check(is_equal_approx(a_damage, b_damage),
		"both fusions agree on damage in either order (%s vs %s)" % [a_damage, b_damage])
	check(is_equal_approx(a_range, b_range),
		"...and on range (%s vs %s)" % [a_range, b_range])
	check(a.slash_range > 0.0 and b.slash_range > 0.0,
		"...and neither order leaves the cleave with no reach (%s, %s)" % [a.slash_range, b.slash_range])

	_drop(a)
	_drop(b)

# --- helpers -------------------------------------------------------------------

func _orbit() -> OrbitingWeapon:
	return _player.get_node_or_null("Weapons/OrbitingWeapon")

func _slash() -> SlashWeapon:
	return _player.get_node_or_null("Weapons/SlashWeapon")

## Buy a card through the real select_upgrade() path for as long as the real catalog
## keeps offering it. The number of ranks a weapon can spend on an axis is therefore
## read out of the game rather than restated here.
func _buy_every_offering(id: String) -> int:
	var bought := 0
	while bought < 12:
		var offered := false
		for card in _um.get_upgrade_catalog():
			if card.get("id", "") == id:
				offered = true
				break
		if not offered:
			break
		_um.select_upgrade({"id": id})
		bought += 1
	return bought

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
		await get_tree().process_frame
