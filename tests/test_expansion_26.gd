extends Node

## Automated Test Suite for Expansion 26.0:
## "Khi Thừa" -- the Qi Shield that refilled itself every time you opened a menu.
##
## refresh_meta_stats() is a stat rebuild, and the Qi Shield line inside it read
##     qi_shield_max   = float(nham * 30)
##     qi_shield_current = qi_shield_max
## i.e. it topped the charge up to the cap on every call. It is called from a dozen
## places, and the two free ones are the ones a player stumbles into by accident:
## _close_shop() (hud.gd) and equip_gear() (game_manager.gd, which checks no gold at
## all). So the sequence "take a shield-breaking hit -> open the menu -> close it"
## handed back a full shield, for free, as often as you liked.
##
## The fix grants only the capacity that was actually bought. For a shield nothing has
## touched yet that is the same number, which is why this is not a behaviour change
## on a fresh save -- it only diverges once charge has been spent, which is the one
## case that must not refill.
##
## Every assertion here is synchronous and takes no physics frames on purpose: the
## shield regenerates by 0.75 * regen_rate every frame, so one awaited frame between
## draining the shield and reading it back would refill it and hide the bug.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

## GameManager.meridian_upgrades is shared, and buy_meridian_upgrade() would persist
## to the developer's real meta gold. This suite sets the dictionary in memory and
## never calls the purchase path, so only the dictionary itself is snapshotted.
var _meridians_backup: Dictionary = {}
var _player: Player = null

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 26.0 TEST SUITE ===")
	GameManager.is_run_active = false
	_meridians_backup = GameManager.meridian_upgrades.duplicate()

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.current_health = _player.max_health

	_test_a_refresh_does_not_recharge_a_spent_shield()
	_test_a_broken_shield_stays_broken_across_a_refresh()
	_test_buying_a_rank_grants_only_the_new_capacity()
	_test_a_never_touched_shield_still_comes_up_full()

	GameManager.meridian_upgrades = _meridians_backup
	_drop(_player)

	if _failures.is_empty():
		print("=== ALL EXPANSION 26.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. a part-spent shield keeps its charge ---------------------------------

func _test_a_refresh_does_not_recharge_a_spent_shield() -> void:
	_set_meridian("nham_mach", 1)
	_player.qi_shield_current = 0.0
	_player.qi_shield_max = 0.0
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.qi_shield_max, 30.0),
		"Precondition: one Nhâm Mạch rank is a 30 point cap, got %s" % _player.qi_shield_max)
	check(is_equal_approx(_player.qi_shield_current, 30.0),
		"Precondition: an untouched shield comes up full, got %s" % _player.qi_shield_current)

	# The spent case. A shield knocked down to 12 of 30 has 12 left, and a stat rebuild
	# that is not a stat rebuild must not hand the other 18 back.
	_player.qi_shield_current = 12.0
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.qi_shield_current, 12.0),
		"A refresh does not top a part-spent shield back up (got %s of %s)"
			% [_player.qi_shield_current, _player.qi_shield_max])
	check(is_equal_approx(_player.qi_shield_max, 30.0),
		"...and the cap itself is still rebuilt correctly, got %s" % _player.qi_shield_max)

# --- 2. and a broken one is the sharpest version of it ------------------------

## take_damage() sets qi_shield_current = 0.0 on a break, and _close_shop() calls
## refresh_meta_stats() a moment later. That is the exploit in one line.
func _test_a_broken_shield_stays_broken_across_a_refresh() -> void:
	_set_meridian("nham_mach", 1)
	_player.qi_shield_max = 30.0
	_player.qi_shield_current = 0.0

	_player.refresh_meta_stats()
	check(is_equal_approx(_player.qi_shield_current, 0.0),
		"A shield broken to zero is not refilled by the next refresh (got %s of %s)"
			% [_player.qi_shield_current, _player.qi_shield_max])

	# And not by a second one, in case the first only looked like it worked.
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.qi_shield_current, 0.0),
		"...nor by a second refresh (got %s)" % _player.qi_shield_current)

# --- 3. the purchase still pays out ------------------------------------------

func _test_buying_a_rank_grants_only_the_new_capacity() -> void:
	# Started from the field's own zero, not from whatever the previous test left
	# behind. A refresh on a shield that already has its full cap grants nothing by
	# design, so a test that assumed otherwise was asserting the bug.
	_set_meridian("nham_mach", 1)
	_player.qi_shield_max = 0.0
	_player.qi_shield_current = 0.0
	_player.refresh_meta_stats()
	var before := _player.qi_shield_current
	check(before > 0.0, "Precondition: the shield has charge to lose (got %s)" % before)

	# Broken, then a rank is bought: the cap goes 30 -> 60, and the player should be
	# owed the 30 points of capacity they just paid for, and not one point more.
	_player.qi_shield_current = 0.0
	_set_meridian("nham_mach", 2)
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.qi_shield_max, 60.0),
		"Two ranks are a 60 point cap, got %s" % _player.qi_shield_max)
	check(is_equal_approx(_player.qi_shield_current, 30.0),
		"A bought rank grants the new capacity and nothing more (got %s)" % _player.qi_shield_current)

# --- 4. and the untouched case is genuinely unchanged ------------------------

## The property that makes the fix safe on a real save: starting from the field's own
## zero, "grant the delta" and "top up to the cap" are the same number.
func _test_a_never_touched_shield_still_comes_up_full() -> void:
	for ranks in [1, 3, 5]:
		_set_meridian("nham_mach", ranks)
		_player.qi_shield_max = 0.0
		_player.qi_shield_current = 0.0
		_player.refresh_meta_stats()
		check(is_equal_approx(_player.qi_shield_max, float(ranks * 30)),
			"%d ranks give a %d point cap, got %s" % [ranks, ranks * 30, _player.qi_shield_max])
		check(is_equal_approx(_player.qi_shield_current, float(ranks * 30)),
			"...and an untouched shield is full at %d ranks (got %s)" % [ranks, _player.qi_shield_current])

# --- helpers ----------------------------------------------------------------

## Written through the dictionary rather than buy_meridian_upgrade() on purpose: the
## purchase path persists to user://save_data.cfg immediately, and this suite has no
## reason to spend the developer's meta gold. get_meridian_stat() only reads the dict.
func _set_meridian(id: String, level: int) -> void:
	GameManager.meridian_upgrades[id] = level

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()
