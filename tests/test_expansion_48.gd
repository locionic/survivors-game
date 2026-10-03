extends Node

## Automated Test Suite for Expansion 48.0:
## "The AoE card did nothing when you bought it" -- the Liệt Hỏa Phần Thiên card and the
## Apocalypse Meteor's own widening both add to run_blast_radius_bonus, and that field
## only reaches the blast through the rebuild in Player.refresh_meta_stats():
##
##     player.gd:391   fire_wpn.blast_radius_multiplier = ((1.0 + char_area_bonus) \
##                        + GameManager.get_meta_stat("pyro") * 0.12 \
##                        + float(GameManager.get_meridian_stat("dan_dien") * 0.20) \
##                        + fire_wpn.run_blast_radius_bonus) * sword_range
##
##     fireball_weapon.gd:108   run_blast_radius_bonus += bonus     # the card
##     fireball_weapon.gd:130   run_blast_radius_bonus += 1.2       # the evolution
##
## Neither writer calls that rebuild, and nothing else on the level-up path does
## either -- UpgradeManager.select_upgrade() hands the card to upgrade_blast_radius()
## and returns (upgrade_manager.gd:686), and the button that bought it
## (upgrade_manager.gd:526) connects straight to that. So the bonus is banked and
## invisible: blast_radius_multiplier keeps the number it had, and the field the
## projectile actually reads (fireball_weapon.gd:74, `fb.blast_radius *=
## blast_radius_multiplier`) is unchanged until some unrelated trigger happens to
## rebuild -- a relic pickup, a meta purchase, a gear toggle.
##
## Measured, at the moment of the purchase, with nothing else called in between:
##
##     blast_radius_multiplier  1.0 -> 1.0     (advertised +35%)
##
## This is the mirror of Expansion 44.0, which moved this bonus OFF
## blast_radius_multiplier and onto a run-scoped field so a rebuild would fold it
## back in rather than erase it. The write was relocated and the rebuild that
## applies it was never triggered -- so the card is durable and inert.
##
## The claim under test is an invariant, not a number: buying a card changes the
## field the game plays from, on that frame. Every expected value here is parsed out
## of the card's own description or read off the live node, so no number in this file
## restates a constant that lives in the game.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const UPGRADE_MANAGER: GDScript = preload("res://scripts/upgrade_manager.gd")

const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e48bak"
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

func _fireball() -> Node:
	return _player.get_node_or_null("Weapons/FireballWeapon")

func _radius() -> float:
	var w = _fireball()
	return w.blast_radius_multiplier if w else -1.0

## The percentage the card's own description promises, parsed rather than restated.
func _advertised() -> float:
	for entry in _um.get_upgrade_catalog():
		if entry.get("id", "") == "fireball_radius":
			var m := RegEx.new()
			m.compile("\\+(\\d+)%%?")
			var r := m.search(str(entry.get("desc", "")))
			if r:
				return float(r.get_string(1)) / 100.0
	return -1.0

func _ready() -> void:
	_backup_save()
	print("=== RUNNING EXPANSION 48.0 TEST SUITE ===")
	GameManager.is_run_active = false

	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)
	await get_tree().process_frame

	# After the player, so the weapon references UpgradeManager resolves in its own
	# _ready() -- and activate_weapon() only flips is_active on the node already in
	# the tree, so those references stay valid for the whole run.
	_um = UPGRADE_MANAGER.new() as UpgradeManager
	add_child(_um)
	await get_tree().process_frame

	# Pinned, not inherited. Every one of these is a term in the rebuild at
	# player.gd:391, and the developer's save carries meta levels, a meridian and a
	# piece of equipment that would each shift the base out from under the ratio.
	GameManager.select_character("knight")
	for k in GameManager.meta_upgrades.keys():
		GameManager.meta_upgrades[k] = 0
	for k in GameManager.meridian_upgrades.keys():
		GameManager.meridian_upgrades[k] = 0
	GameManager.equipment_slots = {}
	_um.weapon_levels["fireball"] = 1
	_player.activate_weapon("fireball")
	await get_tree().process_frame
	_player.refresh_meta_stats()

	await _test_control_the_unbought_fireball_has_its_base_radius()
	await _test_buying_the_aoe_card_widens_the_blast_immediately()
	await _test_buying_the_card_twice_keeps_both_widths()
	await _test_the_card_survives_a_rebuild()
	await _test_the_evolution_widens_the_blast_immediately()

	_restore_save()
	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)
	if unique.is_empty():
		print("=== ALL EXPANSION 48.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

## Control: the thing the next four cases measure against. An un-bought fireball's
## blast is whatever the rebuild says it is, and the card is on offer at all -- if
## either is false, every ratio below is measuring nothing.
func _test_control_the_unbought_fireball_has_its_base_radius() -> void:
	check(_fireball() != null, "the player owns a FireballWeapon node")
	var base := _radius()
	check(base > 0.0, "a fresh fireball has a positive blast radius multiplier (%s)" % base)
	check(_advertised() > 0.0, "the AOE card advertises a positive percentage")
	var offered := false
	for entry in _um.get_upgrade_catalog():
		if entry.get("id", "") == "fireball_radius":
			offered = true
	check(offered, "the AOE card is offered with the fireball at rank 1")

## The defect. Nothing is called between the purchase and the reading -- no
## refresh_meta_stats(), no relic pickup, no gear toggle. Whatever rebuilds the
## field is inside the purchase itself, or it is not there at all.
func _test_buying_the_aoe_card_widens_the_blast_immediately() -> void:
	var base := _radius()
	var advertised := _advertised()
	_um.select_upgrade({"id": "fireball_radius"})
	var after := _radius()
	check(is_equal_approx(after - base, advertised),
		"buying the AOE card widens the blast on that frame (got %s, expected %s + %s)" % [after, base, advertised])

## Two ranks of the card, bought the way the game offers them -- the catalog hands out
## one rank per pick and both picks come back to back here. A rebuild that folds the
## field in once must fold in both.
func _test_buying_the_card_twice_keeps_both_widths() -> void:
	var before := _radius()
	var advertised := _advertised()
	_um.select_upgrade({"id": "fireball_radius"})
	_um.select_upgrade({"id": "fireball_radius"})
	var after := _radius()
	check(is_equal_approx(after - before, advertised * 2.0),
		"two ranks of the AOE card are both live (got %s, expected %s + %s)" % [after, before, advertised * 2.0])

## The guard against fixing this the wrong way. A bare
## `blast_radius_multiplier += bonus` would pass all three cases above and is exactly
## what Expansion 44.0 removed, because refresh_meta_stats() reassigns the field from
## base -- so a meta purchase, a codex unlock or a gear toggle would refund every
## width the player bought. This is the case that says the rebuild, not an
## accumulation, is what has to happen.
func _test_the_card_survives_a_rebuild() -> void:
	var before := _radius()
	_player.refresh_meta_stats()
	check(is_equal_approx(_radius(), before),
		"a rebuild keeps the width the player bought (%s -> %s)" % [before, _radius()])

## The same defect through the other writer. The evolution adds its own 1.2 to the
## same run-scoped field, and is offered at rank 5 -- so a player who invested in the
## card arrives here and evolved into a blast that was still the old size.
func _test_the_evolution_widens_the_blast_immediately() -> void:
	var before := _radius()
	_um.weapon_levels["fireball"] = 5
	_um.select_upgrade({"id": "evolve_fireball"})
	var fireball := _fireball()
	check(fireball.is_evolved, "the fireball evolves")
	check(_radius() > before,
		"evolving widens the blast on that frame (got %s, expected more than %s)" % [_radius(), before])
