extends Node

## Automated Test Suite for Expansion 32.0:
## "Cầu Lửa Mất Rộng Mỗi Lần Mua Thêm" -- the AoE radius the shop sells, refunded
## to zero by the next stat rebuild.
##
## Player.refresh_meta_stats() owns blast_radius_multiplier: it *reassigns* the
## field from the character, meridian and meta AoE sources, and it has twelve call
## sites of which three are routine --
##
##     GameManager.buy_meta_upgrade()   ->  p.refresh_meta_stats()
##     GameManager.equip_gear()         ->  p.refresh_meta_stats()   # free, repeatable
##     CodexManager                     ->  p.refresh_meta_stats()
##
## The fireball's own AoE radius was written straight onto that field:
##
##     func upgrade_blast_radius(bonus: float) -> void:
##         blast_radius_multiplier += bonus
##
## so buying Liệt Hỏa Phần Thiên ("+35% Phạm Vi Nổ Cầu Lửa") moved 1.55 -> 1.90
## and the next rebuild put it back to 1.55. The player paid for the card, then
## lost it for opening a shop or re-equipping a pair of boots. The Apocalypse
## Meteor's own widening was assigned the same way (blast_radius_multiplier = 2.2)
## and so was erased on the same schedule, meaning the evolved fireball reliably
## gained its damage and silently lost its width.
##
## The asymmetry is the proof this is a defect and not a design choice: nothing
## rebuilds the fireball's damage_multiplier, so the +35% damage card survived
## every one of those same call sites while the +35% radius card did not.
##
## The codebase already had both halves of the answer. max_health and might keep
## their run-scoped sources in run_max_hp_bonus / run_might_bonus precisely so a
## rebuild folds them back in rather than erasing them, and refresh_meta_stats()'
## own comment names the hazard -- "anything applied to blast_radius_multiplier
## directly ... would be wiped on the first refresh". The fireball was the one
## source that had not been moved to its own field yet.
##
## The suite below checks the general rule (a rebuild is a fixed point, over every
## derived field rather than just the one that broke) and then the specific
## promises: the card survives, the evolution survives, they stack in either
## order, and the Ỷ Thiên Kiếm's quarter is still exactly reversible.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

## The fields refresh_meta_stats() derives rather than accumulates, plus the two
## the fireball owns that a rebuild is allowed to rebuild (radius) or must not
## (damage). qi_shield_current is deliberately absent: the line above qi_shield_max
## is a top-up, not a rebuild, and is commented as such -- a shield drained to zero
## by a hit is *meant* to come partly back when the stat rebuild runs.
## current_health is absent for the same reason: it moves by the max_health delta to
## stay in step with the new cap. Everything listed here must satisfy
## f(f(x)) == f(x), or the rebuild is a ratchet.
const PLAYER_DERIVED: Array[String] = [
	"max_health", "move_speed", "magnet_radius", "meta_might_bonus",
	"crit_chance_bonus", "skill_cooldown_max", "dragon_soul_harvest_mult",
]
const FIREBALL_FIELDS: Array[String] = ["blast_radius_multiplier", "damage_multiplier"]
const REBUILDS: int = 5

## The two sources a run buys, and the size of each. Stated here rather than read
## off the card so the suite says what it expects the shop to have sold.
const CARD_BONUS: float = 0.35
const EVOLUTION_BONUS: float = 1.2

var _player: Player = null
var _slots_backup: Dictionary = {}
var _file_backup: PackedByteArray = PackedByteArray()
var _file_existed: bool = false

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 32.0 TEST SUITE ===")
	GameManager.is_run_active = false

	_file_existed = FileAccess.file_exists("user://save_data.cfg")
	if _file_existed:
		_file_backup = FileAccess.get_file_as_bytes("user://save_data.cfg")
	_slots_backup = GameManager.equipment_slots.duplicate(true)

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	if not check(_player.has_method("refresh_meta_stats"), "Precondition: the player loaded"):
		_finish()
		return

	_test_the_rebuild_is_a_fixed_point()
	_test_the_radius_card_survives_a_rebuild()
	_test_the_evolution_survives_a_rebuild()
	_test_the_two_sources_stack_in_either_order()
	_test_the_sword_is_exactly_reversible_and_still_scales_the_blast()
	_test_radius_upgrades_are_treated_like_damage_upgrades()

	_finish()

# --- 1. the general rule, over every derived field ------------------------------

## The invariant, checked over the whole set rather than over the one field that
## happened to break: rebuilding the stats N times is the same as rebuilding them
## once. A source reintroduced outside the expression fails here whichever way it
## was reintroduced -- an assignment the rebuild does not make shows up as a value
## a rebuild *reduces*.
func _test_the_rebuild_is_a_fixed_point() -> void:
	_fireball().upgrade_blast_radius(CARD_BONUS)
	_fireball().evolve_to_apocalypse_meteor()
	_rebuild()
	var after_one := _derived_state()
	_rebuild()
	for i in REBUILDS:
		_rebuild()
	var after_many := _derived_state()

	for field in PLAYER_DERIVED + FIREBALL_FIELDS:
		check(is_equal_approx(float(after_one[field]), float(after_many[field])),
			"%d rebuilds leave %s where one left it, went %s -> %s"
				% [REBUILDS + 1, field, after_one[field], after_many[field]])

# --- 2. the card the player paid for --------------------------------------------

## The whole defect in one assertion: take the card, then let the game rebuild the
## stats the way buying a Vitality point or re-equipping a boot does, and the width
## is still there. Against the code before the fix the radius came back at the bare
## base -- 1.55 having been 1.90.
func _test_the_radius_card_survives_a_rebuild() -> void:
	_fresh_weapon()
	_rebuild()
	var before: float = _radius()
	_fireball().upgrade_blast_radius(CARD_BONUS)
	_rebuild()
	check(is_equal_approx(_radius(), before + CARD_BONUS),
		"The +35%% radius card survives a stat rebuild, went %s -> %s (expected %s)"
			% [before, _radius(), before + CARD_BONUS])

# --- 3. the evolution ------------------------------------------------------------

## The same schedule, the other source. Assigning 2.2 outright read correctly until
## the next rebuild, so the evolved Cầu Lửa held its 2.4x damage and quietly lost
## the 2.2x width that goes with it.
func _test_the_evolution_survives_a_rebuild() -> void:
	_fresh_weapon()
	_rebuild()
	var before: float = _radius()
	_fireball().evolve_to_apocalypse_meteor()
	_rebuild()
	check(is_equal_approx(_radius(), before + EVOLUTION_BONUS),
		"Apocalypse Meteor's widening survives a stat rebuild, went %s -> %s (expected %s)"
			% [before, _radius(), before + EVOLUTION_BONUS])

# --- 4. order independence ---------------------------------------------------------

## Both sources are additive bonuses, so a card bought before the evolution and a
## card bought after it have to arrive at the same place. If either were assigned
## absolutely this would differ, and the player would be quietly punished for the
## order they happened to level up in.
func _test_the_two_sources_stack_in_either_order() -> void:
	_fresh_weapon()
	var bare: float = _radius()

	_fresh_weapon()
	_fireball().evolve_to_apocalypse_meteor()
	_fireball().upgrade_blast_radius(CARD_BONUS)
	_rebuild()
	var evolved_first: float = _radius()

	_fresh_weapon()
	_fireball().upgrade_blast_radius(CARD_BONUS)
	_fireball().evolve_to_apocalypse_meteor()
	_rebuild()
	var card_first: float = _radius()

	check(is_equal_approx(card_first, evolved_first),
		"Card-then-evolve and evolve-then-card agree, got %s and %s" % [card_first, evolved_first])
	# The two orders agreeing is not enough on its own: against the code before the
	# fix both orders erased both sources and so agreed with each other at the bare
	# base. Measured against that base, this is where "they stack" is decided.
	check(is_equal_approx(card_first, bare + CARD_BONUS + EVOLUTION_BONUS),
		"Both sources are in the same blast, got %s where %s sits at %s"
			% [card_first, bare + CARD_BONUS + EVOLUTION_BONUS, bare])

# --- 5. the sword still behaves ---------------------------------------------------

## Ỷ Thiên Kiếm is the one multiplicative source, so it became a `?:` term inside
## the rebuild expression rather than an `*=` after it -- where its correctness
## depended on the assignment happening to run first. Both halves are checked: it
## still widens the blast by a quarter, and it still comes all the way off again.
func _test_the_sword_is_exactly_reversible_and_still_scales_the_blast() -> void:
	_fresh_weapon()
	_fireball().upgrade_blast_radius(CARD_BONUS)

	_equip(GameManager.equip_gear("weapon", ""))
	_rebuild()
	var bare: float = _radius()
	_equip(GameManager.equip_gear("weapon", "y_thien_kiem"))
	_rebuild()
	var with_sword: float = _radius()
	_equip(GameManager.equip_gear("weapon", ""))
	_rebuild()

	check(is_equal_approx(with_sword, bare * 1.25),
		"Ỷ Thiên Kiếm widens the blast by exactly 1.25x, got %s where %s says %s"
			% [with_sword, bare, bare * 1.25])
	check(is_equal_approx(_radius(), bare),
		"Taking it off puts the whole quarter back, %s -> %s" % [with_sword, _radius()])

# --- 6. the asymmetry, closed -------------------------------------------------------

## The evidence this was a defect rather than a balance choice: the fireball's
## damage card already survived every rebuild, because nothing reassigns
## damage_multiplier. Both axes are asserted together, so the next source added to
## one and forgotten in the other fails here.
func _test_radius_upgrades_are_treated_like_damage_upgrades() -> void:
	_fresh_weapon()
	_rebuild()
	var radius_before: float = _radius()
	var damage_before: float = float(_fireball().get("damage_multiplier"))

	_fireball().upgrade_blast_radius(CARD_BONUS)
	_fireball().upgrade_damage(0.35)
	_rebuild()

	check(is_equal_approx(_radius(), radius_before + CARD_BONUS),
		"The radius card holds across a rebuild, %s -> %s" % [radius_before, _radius()])
	check(is_equal_approx(float(_fireball().get("damage_multiplier")), damage_before + 0.35),
		"The damage card holds across the same rebuild, %s -> %s"
			% [damage_before, _fireball().get("damage_multiplier")])

# --- helpers ------------------------------------------------------------------

func _rebuild() -> void:
	_player.refresh_meta_stats()

func _fireball() -> Node:
	return _player.get_node("Weapons/FireballWeapon")

func _radius() -> float:
	return float(_fireball().get("blast_radius_multiplier"))

## A fireball with neither run-scoped source *and no Ỷ Thiên Kiếm*, so each case
## measures from the bare base rather than from whatever the case before it, or
## the developer, left equipped. The sword is multiplicative and sits outside the
## sum, so with it on, a card is worth +0.4375 rather than +0.35 -- every assertion
## below would still be right about the game and wrong about the arithmetic. Gear
## is inherited from the shared save, which other suites in the batch also change,
## so it is pinned here rather than assumed.
func _fresh_weapon() -> void:
	_equip(GameManager.equip_gear("weapon", ""))
	var fire := _fireball()
	fire.set("run_blast_radius_bonus", 0.0)
	fire.set("is_evolved", false)
	fire.set("fireball_count", 1)
	fire.set("damage_multiplier", 1.0)
	_rebuild()

func _equip(ok: bool) -> void:
	if not ok:
		check(false, "equip_gear() rejected a gear id the catalog defines")

## Every derived field, keyed by bare name so the check loop can index one
## dictionary with one list. The weapon's two are read off the weapon rather than
## the player; a field that did not exist on the node it was asked of comes back
## null and fails here instead of being silently skipped.
func _derived_state() -> Dictionary:
	var s := {}
	for field in PLAYER_DERIVED:
		check(_player.get(field) != null, "The player has a %s field to rebuild" % field)
		s[field] = float(_player.get(field))
	for field in FIREBALL_FIELDS:
		check(_fireball().get(field) != null, "The fireball has a %s field" % field)
		s[field] = float(_fireball().get(field))
	return s

func _finish() -> void:
	GameManager.equipment_slots = _slots_backup
	GameManager.save_game_data()
	if _file_existed:
		var f := FileAccess.open("user://save_data.cfg", FileAccess.WRITE)
		if f:
			f.store_buffer(_file_backup)
			f.close()
	elif FileAccess.file_exists("user://save_data.cfg"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save_data.cfg"))
	if is_instance_valid(_player):
		remove_child(_player)
		_player.queue_free()

	if _failures.is_empty():
		print("=== ALL EXPANSION 32.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)
