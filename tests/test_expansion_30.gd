extends Node

## Automated Test Suite for Expansion 30.0:
## "Cầu Lửa Không Có Nhịp" -- the weapon whose one upgrade no card could reach.
##
## Every weapon exposes `upgrade_*` methods, and every one of those methods was reachable
## from some card in get_upgrade_catalog() -- except one. fireball_weapon.gd had:
##
##     func upgrade_fire_rate(bonus: float) -> void:
##         speed_multiplier += bonus
##
## and no card in the catalog ever called it. It was the only upgrade method in the
## codebase with zero callers. The fireball's cooldown is
##
##     cooldown_timer = max(0.22, base_cooldown / (speed_multiplier * _get_player_attack_speed()))
##
## which is character for character the same formula as slash_weapon.gd:82 -- and the
## Cửu Kiếm does have a "+25%" card for exactly that field. So the fireball was the one
## weapon of six whose fire rate could never be improved, and the code to do it had been
## sitting unused since the weapon was written.
##
## The other five weapons were checked before concluding this was an oversight rather
## than a balance choice. The Khiên Bát Quái and Cửu Thiên Lôi each offer two cards and
## expose exactly two methods; nothing is missing on either. Phi Đao writes its three
## fields directly (weapon.damage_multiplier += 0.25) instead of via methods, so it has
## no upgrade_ methods to be missing a card for.
##
## The suite below never infers which card belongs to which weapon at runtime. It
## observes, for each weapon, which of that weapon's own numeric properties its cards
## actually move, and requires that to be at least the number of upgrade_ methods the
## weapon exposes. Adding a method without a card, or a card that does nothing, both
## fail it.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

## Scene node name -> the weapon it holds, so the checks read as the weapons do.
const WEAPON_NODES: Array[String] = [
	"MainWeapon", "OrbitingWeapon", "LightningWeapon", "FireballWeapon", "AxeWeapon", "SlashWeapon",
]

## Catalog id -> the scene node that id upgrades. The dagger is the one weapon whose
## cards are not prefixed by weapon name, which is why this table is stated rather than
## inferred. Expansion 30.0 added fireball_speed; Expansion 33.0 added lightning_speed,
## the last weapon with a cooldown and no card for it.
const WEAPON_BY_ID: Dictionary = {
	"damage": "MainWeapon", "attack_speed": "MainWeapon", "projectile_count": "MainWeapon",
	"orbit_shield": "OrbitingWeapon", "orbit_speed": "OrbitingWeapon",
	"lightning_strike": "LightningWeapon", "lightning_damage": "LightningWeapon",
	"lightning_speed": "LightningWeapon",
	"fireball_count": "FireballWeapon", "fireball_damage": "FireballWeapon",
	"fireball_radius": "FireballWeapon", "fireball_speed": "FireballWeapon",
	"axe_count": "AxeWeapon", "axe_damage": "AxeWeapon", "axe_speed": "AxeWeapon",
	"slash_damage": "SlashWeapon", "slash_speed": "SlashWeapon", "slash_range": "SlashWeapon",
}

var _player: Player = null
var _mgr: UpgradeManager = null
var _levels_backup: Dictionary = {}
var _evolved_backup: Dictionary = {}

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 30.0 TEST SUITE ===")
	GameManager.is_run_active = false

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_mgr = UpgradeManager.new()
	add_child(_mgr)   # _ready() resolves all six weapons off the player it finds in the group
	if not check(_mgr.fire_weapon != null, "Precondition: the manager wired all six weapons"):
		_finish()
		return

	_levels_backup = _mgr.weapon_levels.duplicate()
	_evolved_backup = _mgr.evolved_weapons.duplicate()

	_test_the_fireball_offers_a_fire_rate_card()
	_test_taking_it_moves_the_field_the_cooldown_reads()
	_test_no_weapon_has_an_upgrade_method_no_card_can_reach()
	_test_all_four_axes_of_the_holy_flame_are_reachable()

	_finish()

func _finish() -> void:
	if is_instance_valid(_mgr):
		_mgr.weapon_levels = _levels_backup
		_mgr.evolved_weapons = _evolved_backup
	_drop(_mgr)
	_drop(_player)

	if _failures.is_empty():
		print("=== ALL EXPANSION 30.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the card exists --------------------------------------------------------

func _test_the_fireball_offers_a_fire_rate_card() -> void:
	_focus("FireballWeapon", 1)
	var ids := _offered_ids()
	check(ids.has("fireball_speed"),
		"The Cầu Lửa offers a fire-rate card, it offers %s" % ", ".join(ids))

	# Not offered once it is at max rank, like every other weapon's cards.
	_focus("FireballWeapon", 5)
	check(not _offered_ids().has("fireball_speed"),
		"At rank 5 the fire-rate card stops being offered")

# --- 2. and it moves the field the cooldown actually reads ----------------------

func _test_taking_it_moves_the_field_the_cooldown_reads() -> void:
	_focus("FireballWeapon", 1)
	var fire := _weapon("FireballWeapon")
	var before: float = fire.get("speed_multiplier")
	var level_before: int = _mgr.weapon_levels["fireball"]

	_mgr.select_upgrade({"id": "fireball_speed", "title": "", "desc": ""})

	check(is_equal_approx(float(fire.get("speed_multiplier")), before + 0.25),
		"The card adds +25%% to the fireball's speed_multiplier, went %s -> %s"
			% [before, fire.get("speed_multiplier")])
	check(_mgr.weapon_levels["fireball"] == level_before + 1,
		"Taking it counts toward the weapon's rank, went %d -> %d"
			% [level_before, _mgr.weapon_levels["fireball"]])

	# The advertised number and the applied number are the same number, which is the
	# whole of the card's promise: 1.0 -> 1.25 is a quarter off the cooldown.
	check(is_equal_approx(float(fire.get("speed_multiplier")), 1.25),
		"A rank-1 Cầu Lửa firing at 1.25x, got %s" % fire.get("speed_multiplier"))

# --- 3. the class guard, over all six weapons ----------------------------------

## W at rank 1 and the other five at 5 with evolved set excludes every unlock (which
## needs rank 0), every evolution (rank >= 5) and every other weapon's cards (rank
## >= 5), so the catalog holds W's own cards plus the four universal passives. The
## passives move the player, not a weapon, so they cannot be counted for W.
func _test_no_weapon_has_an_upgrade_method_no_card_can_reach() -> void:
	for node_name in WEAPON_NODES:
		var weapon := _weapon(node_name)
		var methods := _upgrade_methods(weapon)
		var expected_ids: Array[String] = []
		for id in WEAPON_BY_ID:
			if WEAPON_BY_ID[id] == node_name:
				expected_ids.append(str(id))

		var touched: Array[String] = []
		var duds: Array[String] = []
		for id in expected_ids:
			_focus(node_name, 1)
			# Re-focused per card so each is observed in isolation: two cards that
			# happen to move the same field must not be counted as two axes.
			var before := _numeric_state()
			_mgr.select_upgrade({"id": str(id), "title": "", "desc": ""})
			var moved := _moved(before, _numeric_state())
			if moved.is_empty():
				duds.append(str(id))
			for m in moved:
				if not touched.has(m):
					touched.append(m)

		check(duds.is_empty(),
			"Every %s card moves something, these do not: %s" % [node_name, ", ".join(duds)])
		check(touched.size() >= methods.size(),
			"%s reaches at least its %d upgrade methods from %d cards (moved: %s)"
				% [node_name, methods.size(), expected_ids.size(), ", ".join(touched)])

		# The floor above is a count of upgrade_* methods, so it is structurally blind
		# to a weapon that reads speed_multiplier into its cooldown while exposing no
		# method for it -- which is exactly the Sấm Sét shape, and the reason the
		# Chrono Hourglass sweep could reach that field on it while no card could.
		# Stated off the field the cooldown actually reads, so a weapon with no wrapper
		# at all still has to be reachable. OrbitingWeapon has no speed_multiplier and
		# no cooldown, so get() returns null and it is skipped on its own.
		if weapon.get("speed_multiplier") != null:
			check(touched.has("%s.speed_multiplier" % node_name),
				"%s can raise the speed_multiplier its own cooldown reads (its cards moved: %s)"
					% [node_name, ", ".join(touched)])

# --- 4. and the fireball's four axes are all distinct --------------------------

## The check above is a floor (>=), because Phi Đao has no upgrade_ methods at all.
## The fireball is the weapon this expansion is about, so its four axes are pinned
## individually: count, damage, radius, fire rate, each its own field.
func _test_all_four_axes_of_the_holy_flame_are_reachable() -> void:
	_focus("FireballWeapon", 1)
	var fire := _weapon("FireballWeapon")

	for id in ["fireball_count", "fireball_damage", "fireball_radius", "fireball_speed"]:
		_focus("FireballWeapon", 1)
		var before := _numeric_state()
		_mgr.select_upgrade({"id": str(id), "title": "", "desc": ""})
		check(not _moved(before, _numeric_state()).is_empty(), "%s moves the Cầu Lửa" % id)

		# Bought one at a time, each against its own baseline, so no two of them can turn
	# out to be the same field renamed. Counted as "no field is moved by two cards"
	# rather than as a total, because Expansion 48.0 made the radius card write two
	# fields on purpose: run_blast_radius_bonus, the run-scoped source, and
	# blast_radius_multiplier, which the rebuild derives from it and the projectile
	# reads. Before that fix this card moved only the first of the two -- which is why
	# a total of four used to come out right while the axis the game plays from sat
	# untouched. The invariant is that the four axes do not COLLIDE, not that they
	# touch four fields between them.
	var moved_by: Dictionary = {}
	var rate_before := 0.0
	for id in ["fireball_count", "fireball_damage", "fireball_radius", "fireball_speed"]:
		_focus("FireballWeapon", 1)
		var before := _numeric_state()
		_mgr.select_upgrade({"id": str(id), "title": "", "desc": ""})
		if str(id) == "fireball_speed":
			rate_before = float(before["FireballWeapon.speed_multiplier"])
		for m in _moved(before, _numeric_state()):
			if not m.begins_with("FireballWeapon."):
				continue
			moved_by[m] = "%s %s" % [moved_by.get(m, ""), id]
	var shared: Array[String] = []
	for field in moved_by.keys():
		if not String(moved_by[field]).strip_edges().is_empty() and String(moved_by[field]).strip_edges().split(" ").size() > 1:
			shared.append("%s (%s)" % [field, String(moved_by[field]).strip_edges()])
	check(shared.is_empty(),
		"The four Cầu Lửa cards move four different fields, %s" % ", ".join(shared))

	# The fire rate is asserted as this batch's own delta, not as an absolute: earlier
	# tests in the suite each took the card too, and an absolute here would be reading
	# the whole suite's history rather than the four cards in front of it. The batch is
	# four separate purchases now, so "this batch's own delta" is the baseline captured
	# on the iteration that takes the fire-rate card -- the same value the old
	# single-baseline block read, for the same reason.
	var key := "FireballWeapon.speed_multiplier"
	check(is_equal_approx(float(_numeric_state()[key]), rate_before + 0.25),
		"This batch's fire-rate card adds +25%% on top of whatever it was at, went %s -> %s"
			% [rate_before, _numeric_state()[key]])

# --- helpers ------------------------------------------------------------------

## Puts one weapon at the given rank and the rest at max-and-evolved, so the catalog
## contains that weapon's own cards and the universal passives, nothing else. Rank 5
## with evolved set is what excludes the other five: their stat cards need rank < 5,
## their evolutions need evolved false, and their unlocks need rank 0.
func _focus(node_name: String, rank: int) -> void:
	for n in WEAPON_NODES:
		_mgr.weapon_levels[_id_of(n)] = 5
		_mgr.evolved_weapons[_id_of(n)] = true
	_mgr.weapon_levels[_id_of(node_name)] = rank
	_mgr.evolved_weapons[_id_of(node_name)] = false

func _id_of(node_name: String) -> String:
	match node_name:
		"MainWeapon": return "dagger"
		"OrbitingWeapon": return "shield"
		"LightningWeapon": return "lightning"
		"FireballWeapon": return "fireball"
		"AxeWeapon": return "axe"
		"SlashWeapon": return "slash"
	return node_name

func _weapon(node_name: String) -> Node:
	return _player.get_node("Weapons").get_node_or_null(node_name)

## Every float and int property of every weapon, as {"Node.prop": value}. Nothing is
## stepped here, so nothing decays between two reads of the same node.
func _numeric_state() -> Dictionary:
	var s: Dictionary = {}
	for n in WEAPON_NODES:
		var w := _weapon(n)
		if w == null:
			continue
		for p in w.get_property_list():
			var t := int(p.get("type", 0))
			if t != TYPE_FLOAT and t != TYPE_INT:
				continue
			var pname := str(p.get("name", ""))
			s["%s.%s" % [n, pname]] = float(w.get(pname))
	return s

func _moved(before: Dictionary, after: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for k in after:
		if before.has(k) and not is_equal_approx(float(before[k]), float(after[k])):
			out.append(str(k))
	return out

## The upgrade_* methods a weapon actually exposes. Read off the object rather than
## from a hand-written list, so a method added tomorrow is counted the day it lands.
func _upgrade_methods(w: Node) -> Array[String]:
	var out: Array[String] = []
	if w == null:
		return out
	for m in w.get_method_list():
		var n := str(m.get("name", ""))
		if n.begins_with("upgrade_"):
			out.append(n)
	return out

func _offered_ids() -> Array[String]:
	var out: Array[String] = []
	for item in _mgr.get_upgrade_catalog():
		out.append(str(item.get("id", "")))
	return out

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()
