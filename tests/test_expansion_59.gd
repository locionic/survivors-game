extends "res://tests/suite_base.gd"

## Expansion 59.0: a tomb paid 1 gold. A landmark paid 8. Both were supposed to
## pay 3 and 40.
##
## GoldCoin declares `@export var gold_value: int = 1` (coin.gd:6). Enemy declares
## `@export var coin_value: int = 1` (enemy.gd:20). Two classes, two names, and the
## drop code reached for the enemy's:
##
##     obstacle.gd:49   if coin.has_method("set"):  coin.set("coin_value", 3)
##     landmark.gd:123  if coin.has_method("set"):  coin.set("coin_value", 5)
##
## Object.set() on a property the object does not have is a silent no-op. No error,
## no return value, the coin keeps its default. Measured 2026-10-01 with a probe:
##
##     gold_value at spawn              : 1
##     "coin_value" in coin             : false
##     after set("coin_value", 3)       : gold_value = 1   (intent: 3)
##     after set("gold_value", 3)       : gold_value = 3
##
## So this could never have been caught by the gate. scripts/ci.sh fails a suite on
## `SCRIPT ERROR:`, and a mistyped property name reports nothing at all.
##
## The `has_method("set")` guard that fenced both writes was worse than no guard:
## every Object in GDScript has set(), so it always passed and read like a check that
## had happened. What would have caught this is `"gold_value" in coin`, which is the
## third test here.
##
## Both call sites are exercised through the game's own drop code rather than by
## re-deriving the expected number. The Vault test calls the leaf
## `_spawn_vault_treasures()` rather than the public `discover()` that gates it:
## discover() additionally calls GameManager.add_gold() and discover_landmark(),
## both of which persist to user://save_data.cfg -- outside this repository -- and
## neither has anything to do with the coin value under test.

const OBSTACLE_SCENE := preload("res://scenes/obstacle.tscn")
const LANDMARK_SCENE := preload("res://scenes/landmark.tscn")
const COIN_SCENE := preload("res://scenes/coin.tscn")

## Coins land via call_deferred("add_child", ...), so they are not in the tree
## until the frame ends. Every drop site is followed by an await.
func _coins() -> Array[Node]:
	return get_tree().get_nodes_in_group("coins")

func _clear_coins() -> void:
	for c in _coins():
		c.free()

# --- 1. the tomb -------------------------------------------------------------

func _test_breaking_a_tomb_pays_three_gold() -> void:
	_clear_coins()
	var tomb = OBSTACLE_SCENE.instantiate()
	add_child(tomb)
	tomb.obstacle_type = "tomb"
	tomb.break_tomb()
	await get_tree().process_frame

	var dropped := _coins()
	check(dropped.size() == 1, "breaking a tomb drops exactly one coin, got %d" % dropped.size())
	# Read through get(), not `.gold_value`: dropped is Array[Node], so the element
	# is a static Node and GDScript rejects an undeclared member on it at parse
	# time -- which aborts _ready() before quit() and hangs the suite for the full
	# 120s timeout rather than reporting anything.
	if dropped.size() == 1:
		check(int(dropped[0].get("gold_value")) == 3,
			"a tomb is worth 3 gold, got %d -- the write named a property GoldCoin does not have"
			% int(dropped[0].get("gold_value")))
	tomb.queue_free()

# --- 2. the Vault ------------------------------------------------------------

func _test_discovering_the_vault_pays_forty_gold() -> void:
	_clear_coins()
	var vault = LANDMARK_SCENE.instantiate()
	add_child(vault)
	vault.landmark_id = "vault"

	vault._spawn_vault_treasures()
	await get_tree().process_frame

	var dropped := _coins()
	check(dropped.size() == 8,
		"the Vault scatters 8 coins, got %d" % dropped.size())
	var total := 0
	for c in dropped:
		total += int(c.get("gold_value"))
	check(total == 40,
		"the Vault is worth 40 gold across its 8 coins, got %d" % total)
	if dropped.size() == 8:
		check(int(dropped[0].get("gold_value")) == 5,
			"each Vault coin is worth 5, got %d" % int(dropped[0].get("gold_value")))
	vault.queue_free()

# --- 3. and the guard that was never one -------------------------------------

func _test_a_coin_really_accepts_the_property_the_drop_code_names() -> void:
	# The canary, and the check the deleted `has_method("set")` should have been.
	# Every Object has set(), so that guard always passed -- including on a coin
	# with no property to write to, which is exactly when passing mattered.
	var coin = COIN_SCENE.instantiate()
	add_child(coin)
	check("gold_value" in coin, "GoldCoin declares gold_value")
	check(not ("coin_value" in coin),
		"GoldCoin must not declare coin_value -- that is the enemy's name, and having both would hide the next mix-up rather than catch it")
	check(int(coin.get("gold_value")) == 1, "a coin defaults to 1 gold, got %d" % int(coin.get("gold_value")))
	coin.set("gold_value", 3)
	check(int(coin.get("gold_value")) == 3,
		"writing gold_value must actually land, got %d -- Object.set() on a missing property is a silent no-op"
		% int(coin.get("gold_value")))
	coin.free()

func _ready() -> void:
	print("=== RUNNING EXPANSION 59.0 TEST SUITE ===")
	GameManager.is_run_active = false
	# Both drop sites parent onto `get_tree().current_scene`, which is only set when
	# the scene is entered as the main one. Set it explicitly so the suite measures
	# the coin value whether or not Godot was launched via the .tscn path.
	get_tree().current_scene = self

	await _test_breaking_a_tomb_pays_three_gold()
	await _test_discovering_the_vault_pays_forty_gold()
	_test_a_coin_really_accepts_the_property_the_drop_code_names()

	_clear_coins()

	if _failures.is_empty():
		print("=== ALL EXPANSION 59.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())