extends Node

## Automated Test Suite for Expansion 44.0:
## "Evolving Deleted Your Projectiles" -- the continuation of Expansion 43.0.
##
## 43.0 swept the weapon fields a card *scales* and fixed the two that a bare `=`
## clobbered (orbit_speed, slash_range). It did not sweep the fields a card *counts*,
## and all four of those have the same fault:
##
##     axe_weapon.gd:85          axe_count = 3       (base 1, +1 per card -> 5)
##     fireball_weapon.gd:116    fireball_count = 3  (base 1, +1 per card -> 5)
##     lightning_weapon.gd:136   strike_count = 4     (base 1, +1 per card -> 5)
##     orbiting_weapon.gd:90     shield_count = 5     (base 2, +1 per card -> 6)
##
## Every count card is offered at ranks 1-4 and every evolution at rank 5, so full
## investment always precedes evolution. The failure messages are the bug:
##
##     CHECK FAILED: ...and evolving does not take them away (3 < 5)
##
## A count is the most legible thing on a card -- "+1 Rìu/BỒNG ném ra" -- and the loss
## is the most visible one in the game: projectiles vanish on screen at the exact
## moment the HUD celebrates an evolution.
##
## The claim under test is an invariant, not a number: evolving must never lower a
## field the player has bought cards into. Every value is read off the live node and
## every card is bought through select_upgrade(), so no figure here restates a
## constant that lives in the game.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const AXE_SCENE: PackedScene = preload("res://scenes/axe_weapon.tscn")
const FIREBALL_SCENE: PackedScene = preload("res://scenes/fireball_weapon.tscn")
const LIGHTNING_SCENE: PackedScene = preload("res://scenes/lightning_weapon.tscn")
const ORBIT_SCENE: PackedScene = preload("res://scenes/orbiting_weapon.tscn")
const UPGRADE_MANAGER: GDScript = preload("res://scripts/upgrade_manager.gd")

## equip_gear() and friends persist to user://save_data.cfg immediately.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e44bak"
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
	print("=== RUNNING EXPANSION 44.0 TEST SUITE ===")
	GameManager.is_run_active = false

	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)
	_player.current_health = _player.max_health
	await get_tree().process_frame

	# _ready() resolves its weapon references from the player in the "player" group, so
	# this must be added after the player is in the tree. activate_weapon() only flips
	# is_active on the node that is already there, so those references stay valid.
	_um = UPGRADE_MANAGER.new() as UpgradeManager
	add_child(_um)
	await get_tree().process_frame

	# Pinned rather than inherited: the rank at which each card starts being offered is
	# a precondition, and the save's selected character would otherwise decide it.
	for id in ["dagger", "shield", "lightning", "fireball", "axe", "slash"]:
		_um.weapon_levels[id] = 1

	# Awaited, not just called. A function containing await is a coroutine: called bare
	# it suspends at its first await and _ready() marches straight on.
	await _test_the_axe_keeps_the_axes_the_cards_bought()
	await _test_the_fireball_keeps_the_fireballs_the_cards_bought()
	await _test_the_lightning_keeps_the_strikes_the_cards_bought()
	await _test_the_shield_keeps_the_shields_the_cards_bought()
	await _test_evolving_still_pays_out_for_an_uninvested_weapon()

	_drop(_player)
	_drop(_um)
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 44.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- the four count fields ------------------------------------------------------

## "Bổng Ảnh Tung Hoành" -- "+1 Rìu/Bổng ném ra", bought through the real catalog
## until the game stops offering it, then evolved through the real card handler.
func _test_the_axe_keeps_the_axes_the_cards_bought() -> void:
	var axe := _node("AxeWeapon")
	var base: int = axe.axe_count
	var bought := _buy_every_offering("axe_count")
	check(bought > 0, "the axe count card is offerable at all, bought %d" % bought)

	var invested: int = axe.axe_count
	check(invested > base,
		"the %d axe count cards move axe_count (%d -> %d)" % [bought, base, invested])

	_um.select_upgrade({"id": "evolve_axe"})
	check(axe.is_evolved, "the axe evolves")
	check(axe.axe_count >= invested,
		"...and evolving does not take them away (%d < %d)" % [axe.axe_count, invested])

## "Tam Muội Chân Hỏa" -- "+1 Cầu Lửa đồng thời".
func _test_the_fireball_keeps_the_fireballs_the_cards_bought() -> void:
	var fire := _node("FireballWeapon")
	var base: int = fire.fireball_count
	var bought := _buy_every_offering("fireball_count")
	check(bought > 0, "the fireball count card is offerable at all, bought %d" % bought)

	var invested: int = fire.fireball_count
	check(invested > base,
		"the %d fireball count cards move fireball_count (%d -> %d)" % [bought, base, invested])

	_um.select_upgrade({"id": "evolve_fireball"})
	check(fire.is_evolved, "the fireball evolves")
	check(fire.fireball_count >= invested,
		"...and evolving does not take them away (%d < %d)" % [fire.fireball_count, invested])

## "Lôi Đình Vạn Quân" -- "+1 Luồng Sấm Sét đồng thời".
func _test_the_lightning_keeps_the_strikes_the_cards_bought() -> void:
	var bolt := _node("LightningWeapon")
	var base: int = bolt.strike_count
	var bought := _buy_every_offering("lightning_strike")
	check(bought > 0, "the lightning strike card is offerable at all, bought %d" % bought)

	var invested: int = bolt.strike_count
	check(invested > base,
		"the %d lightning strike cards move strike_count (%d -> %d)" % [bought, base, invested])

	_um.select_upgrade({"id": "evolve_lightning"})
	check(bolt.is_evolved, "the lightning evolves")
	check(bolt.strike_count >= invested,
		"...and evolving does not take them away (%d < %d)" % [bolt.strike_count, invested])

## "Lưỡng Nghi Khiên" -- "+1 Lưỡi Khiên Hộ Thể". This one starts at 2, so four cards
## reach 6 and the evolution's own advertised 5 is one below what the player had.
func _test_the_shield_keeps_the_shields_the_cards_bought() -> void:
	var orbit := _node("OrbitingWeapon")
	var base: int = orbit.shield_count
	var bought := _buy_every_offering("orbit_shield")
	check(bought > 0, "the shield count card is offerable at all, bought %d" % bought)

	var invested: int = orbit.shield_count
	check(invested > base,
		"the %d shield count cards move shield_count (%d -> %d)" % [bought, base, invested])

	_um.select_upgrade({"id": "evolve_shield"})
	check(orbit.is_evolved, "the shield evolves")
	check(orbit.shield_count >= invested,
		"...and evolving does not take them away (%d < %d)" % [orbit.shield_count, invested])

# --- the control ---------------------------------------------------------------

## If every evolution were a bare maxi(), a weapon nobody invested in would evolve to
## exactly its floor and the payoff would be nothing. This is the case that makes the
## fix in the four above a floor rather than a no-op.
func _test_evolving_still_pays_out_for_an_uninvested_weapon() -> void:
	var axe := AXE_SCENE.instantiate() as Node2D
	add_child(axe)
	var axe_base: int = axe.axe_count
	axe.evolve_to_reapers_cleave()
	check(axe.axe_count > axe_base,
		"an uninvested axe still throws more when it evolves (%d -> %d)" % [axe_base, axe.axe_count])
	_drop(axe)

	var fire := FIREBALL_SCENE.instantiate() as Node2D
	add_child(fire)
	var fire_base: int = fire.fireball_count
	fire.evolve_to_apocalypse_meteor()
	check(fire.fireball_count > fire_base,
		"an uninvested fireball still throws more when it evolves (%d -> %d)" % [fire_base, fire.fireball_count])
	_drop(fire)

	var bolt := LIGHTNING_SCENE.instantiate() as Node2D
	add_child(bolt)
	var bolt_base: int = bolt.strike_count
	bolt.evolve_to_heavens_wrath()
	check(bolt.strike_count > bolt_base,
		"an uninvested lightning still strikes more when it evolves (%d -> %d)" % [bolt_base, bolt.strike_count])
	_drop(bolt)

	var orbit := ORBIT_SCENE.instantiate() as Node2D
	add_child(orbit)
	var orbit_base: int = orbit.shield_count
	orbit.evolve_to_solar_bulwark()
	check(orbit.shield_count > orbit_base,
		"an uninvested shield still has more blades when it evolves (%d -> %d)" % [orbit_base, orbit.shield_count])
	_drop(orbit)

# --- helpers -------------------------------------------------------------------

func _node(weapon_node_name: String) -> Node2D:
	return _player.get_node_or_null("Weapons/" + weapon_node_name)

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