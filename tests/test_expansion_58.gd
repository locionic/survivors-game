extends "res://tests/suite_base.gd"

## Expansion 58.0: the Chrono Hourglass was only kept alive by luck of arrival order.
##
## The relic reads "Giảm 20% Thời Gian Hồi Chiêu" and player.gd implemented it as a
## clamp applied once, at pickup:
##
##     w.set("speed_multiplier", maxf(float(w.get("speed_multiplier")), 1.25))
##
## A floor is a promise about the field's state, not about one moment, and
## speed_multiplier has other writers -- the hero rebuild subtracts the previous
## character's attack_speed_bonus (player.gd:254) and the crit shop item multiplies
## the whole arsenal by 0.85 (wave_shop_ui.gd:188). So whether the relic survived
## depended on nothing but the number it happened to meet.
##
## The second writer above was then removed rather than guarded. Section 3 used to
## assert that the sweep and the floor could share one float, which they could only
## do by cancelling: two crit upgrades on a floored Knight read 1.25 -- a 25% faster
## attack bought for 2x gold. The penalty is now the player's own multiplier
## (player.run_attack_speed_penalty), which the floor never touches.
##
## Measured 2026-10-01, before the fix:
##
##   pickup on the Knight (1.00 -> 1.25), switch to the Ranger -> 1.60, back -> 1.25
##   pickup on the Ranger (1.35, already past the floor, so the clamp is a no-op
##   that records nothing), switch to the Knight -> 1.00
##
## Same relic, same two heroes, opposite outcome. The -20% was simply gone, and no
## UI ever said so. This suite pins the floor as a property of owning the relic.
##
## The assertions read `speed_multiplier` off the weapon rather than timing a shot,
## because that float is the single value every one of the five weapons divides its
## cooldown by (weapon.gd:41 and each subclass's own line).

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const SHOP_SCRIPT := preload("res://scripts/wave_shop_ui.gd")
const RELIC := "chrono_hourglass"
## Ranger carries attack_speed_bonus 0.35 (game_manager.gd, CHARACTERS), which puts
## the field above the floor on its own -- the case that used to lose the relic.
const RANGER_BONUS := 0.35

var _relics_backup: Array[String] = []
var _char_backup: String = ""
## Only ever one player in the tree at a time. player.tscn puts every instance in
## group "player", and wave_shop_ui._get_player() reads that group -- so two live
## players means the shop silently measures whichever the scene tree happens to list
## first, and the suite goes green while testing nothing. See _hero()'s free().
var _live: Player = null

func _hero(hero_id: String) -> Player:
	# free(), not queue_free(): this _ready() never awaits, so a deferred free is
	# still pending when the next player is added and both are in the group.
	if is_instance_valid(_live):
		_live.free()
	# selected_character is assigned directly rather than through select_character(),
	# which calls save_game_data() and would leave the developer's real save on a
	# hero they did not pick. apply_character_data() reads the field, so this
	# configures the player exactly as the game's own hero switch would.
	GameManager.selected_character = hero_id
	_live = PLAYER_SCENE.instantiate() as Player
	add_child(_live)
	_live.apply_character_data()
	return _live

func _speed(p: Player) -> float:
	return float(p.get_node("Weapons/MainWeapon").get("speed_multiplier"))

## What the player actually gets, not either term alone: every weapon divides its
## cooldown by `speed_multiplier * _get_player_attack_speed()` (weapon.gd:41,
## slash_weapon.gd:82, and the same line in the other three). The relic floors the
## first factor and the shop penalty rides the second, so the shipped attack rate is
## their product. Asserting the two halves separately reads as a contradiction; this
## is the number a fire-rate card is really being compared against.
func _fire_rate(p: Player) -> float:
	return _speed(p) * p.get_attack_speed_multiplier()

func _equip_relic(p: Player) -> void:
	# The way the floor pickup does it. add_relic() does not save, so unlike
	# select_character() this cannot reach the developer's save file.
	GameManager.collected_relics.erase(RELIC)
	GameManager.add_relic(RELIC)
	p.apply_relic_effects()

# --- 1. the measured defect ---------------------------------------------------

func _test_the_relic_survives_a_hero_switch_from_above_the_floor() -> void:
	# Ranger is already past 1.25 on its own, so the pickup clamp is a no-op and
	# nothing anywhere records that the relic is owed. This is the exact sequence
	# that measured 1.00 before the fix.
	var p = _hero("ranger")
	if not check(p != null, "player instantiates"):
		return
	_equip_relic(p)
	check(is_equal_approx(_speed(p), 1.0 + RANGER_BONUS),
		"the Ranger sits above the floor before any switch, got %f" % _speed(p))

	GameManager.selected_character = "knight"
	p.apply_character_data()
	check(is_equal_approx(_speed(p), 1.25),
		"a hero switch must not delete the relic's -20%%; got %f" % _speed(p))

# --- 2. arrival order stops mattering ----------------------------------------

func _test_both_pickup_orders_converge_on_the_same_value() -> void:
	# The promise is "your cooldowns are at least 20% shorter", so the hero you held
	# when the relic dropped cannot be part of the answer. Before the fix these two
	# histories ended at 1.25 and 1.00 respectively.
	var below = _hero("knight")          # 1.00, below the floor: clamp does the work
	_equip_relic(below)
	var below_first := _speed(below)

	GameManager.collected_relics.erase(RELIC)
	var above = _hero("ranger")          # 1.35, above the floor: clamp is a no-op
	_equip_relic(above)
	GameManager.selected_character = "knight"
	above.apply_character_data()
	var above_first := _speed(above)

	check(is_equal_approx(below_first, 1.25), "pickup below the floor grants 1.25, got %f" % below_first)
	check(is_equal_approx(above_first, below_first),
		"pickup above the floor must land on the same value; got %f then %f"
		% [below_first, above_first])

# --- 3. the floor and the price are two numbers -------------------------------

func _test_the_floor_survives_the_crit_penalty_and_the_penalty_still_costs() -> void:
	# The crit item is "+crit, attacks 15%% slower". For a while both the penalty and
	# the Chrono Hourglass floor were the same float -- the shop swept
	# `speed_multiplier *= 0.85` over the arsenal and then re-asserted the floor, so
	# the relic owner got the discount for free and the two promises cancelled. The
	# penalty is a price and the floor is a guarantee; only one of them can be a
	# clamp, so the price moved to the player's own multiplier.
	#
	# Both halves matter and they fail in opposite directions. Assert only the field
	# and the test passes the moment the shop stops writing to it at all -- the relic
	# still reads 1.25 while the player attacks at full speed, which is a strictly
	# worse bug than the one this replaced.
	var p = _hero("knight")
	if not check(p != null, "player instantiates"):
		return
	_equip_relic(p)
	var shop = SHOP_SCRIPT.new()
	add_child(shop)
	p.add_to_group("player")
	# The canary. This assertion exists because it did not: with an earlier player's
	# queue_free() still pending, get_first_node_in_group("player") handed the shop a
	# different body than the one measured here, the field it read was already
	# floored, and the whole test passed with the fix reverted out from under it.
	check(shop._get_player() == p,
		"the shop must resolve to this test's player, not a leftover one")

	shop._set_weapon_speed(0.85)
	check(is_equal_approx(_speed(p), 1.25),
		"one crit upgrade leaves the Knight floored, got %f" % _speed(p))
	check(is_equal_approx(_fire_rate(p), 1.25 * 0.85),
		"the crit upgrade is still a real 15%% cost on top of the relic, got %f"
		% _fire_rate(p))
	shop._set_weapon_speed(0.85)
	check(is_equal_approx(_speed(p), 1.25),
		"stacking crit upgrades cannot ratchet the field down, got %f" % _speed(p))
	check(is_equal_approx(_fire_rate(p), 1.25 * 0.85 * 0.85),
		"stacked crit upgrades compound rather than cancelling, got %f"
		% _fire_rate(p))
	shop.free()

func _test_the_penalty_is_not_a_relic_bonus() -> void:
	# The regression the split was meant to prevent, stated as a player-visible
	# number: two crit upgrades and the relic together must leave the Knight slower
	# than a Knight who bought neither, not faster. Before the fix this read 1.25
	# against a baseline 1.00 -- paying 2x gold for a 25% attack-speed discount.
	# The relic has to go BEFORE the player exists. _hero() adds the scene, whose
	# _ready() calls apply_relic_effects() -- leaving RELIC in collected_relics until
	# after that floors the weapon, and apply_relic_effects() cannot undo a floor it
	# no longer considers justified. Read 0.903125 instead of 0.7225 when the two
	# lines are the other way round: the relic leaking in from the previous test.
	GameManager.collected_relics.erase(RELIC)
	var p = _hero("knight")
	p.apply_relic_effects()
	var shop = SHOP_SCRIPT.new()
	add_child(shop)
	p.add_to_group("player")
	shop._set_weapon_speed(0.85)
	shop._set_weapon_speed(0.85)
	var no_relic := _fire_rate(p)
	_equip_relic(p)
	var with_relic := _fire_rate(p)
	shop.free()
	check(is_equal_approx(no_relic, 0.85 * 0.85),
		"a relicless Knight pays the full crit penalty, got %f" % no_relic)
	check(is_equal_approx(with_relic, 1.25 * 0.85 * 0.85),
		"the relic and the penalty must both be visible in the multiplier, got %f" % with_relic)

# --- 4. and none of it without the relic -------------------------------------

func _test_a_player_without_the_relic_gains_nothing() -> void:
	# The floor is guarded on ownership. If it were not, this suite would pass while
	# every weapon in the game quietly attacked 25% faster.
	GameManager.collected_relics.erase(RELIC)
	var p = _hero("knight")
	var before := _speed(p)
	GameManager.selected_character = "ranger"
	p.apply_character_data()
	var ranger_speed := _speed(p)
	GameManager.selected_character = "knight"
	p.apply_character_data()
	check(is_equal_approx(before, 1.0), "a relicless Knight is baseline, got %f" % before)
	check(is_equal_approx(_speed(p), 1.0),
		"no relic means no floor, got %f" % _speed(p))
	check(is_equal_approx(ranger_speed, 1.0 + RANGER_BONUS),
		"the character bonus still applies without the relic, got %f" % ranger_speed)

func _ready() -> void:
	print("=== RUNNING EXPANSION 58.0 TEST SUITE ===")
	GameManager.is_run_active = false

	_relics_backup = GameManager.collected_relics.duplicate()
	_char_backup = GameManager.selected_character
	GameManager.collected_relics.erase(RELIC)

	_test_the_relic_survives_a_hero_switch_from_above_the_floor()
	_test_both_pickup_orders_converge_on_the_same_value()
	_test_the_floor_survives_the_crit_penalty_and_the_penalty_still_costs()
	_test_the_penalty_is_not_a_relic_bonus()
	_test_a_player_without_the_relic_gains_nothing()

	if is_instance_valid(_live):
		_live.free()
		_live = null
	GameManager.collected_relics = _relics_backup
	GameManager.selected_character = _char_backup

	if _failures.is_empty():
		print("=== ALL EXPANSION 58.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())