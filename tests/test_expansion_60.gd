extends "res://tests/suite_base.gd"

## Expansion 60.0: a Treasure Goblin paid 0 Long Hồn.
##
## enemy.gd's death payload granted Long Hồn on a chain -- 35.0 for a boss, 12.0 for
## a champion, and then:
##
##     elif name.begins_with("TreasureGoblin") or enemy_type == "goblin":
##         charge_gain = 15.0
##
## That branch could not fire. A TreasureGoblin is its own class (`class_name
## TreasureGoblin extends CharacterBody2D`) and does NOT extend Enemy, so enemy.gd's
## die() never runs for one -- and both disjuncts are false besides:
##
##   * `name.begins_with("TreasureGoblin")` -- enemy.tscn's root node is named
##     "Enemy"; the node named "TreasureGoblin" runs goblin.gd, which never reaches
##     this file.
##   * `enemy_type == "goblin"` -- `enemy_type` is not a member at all. It is a local
##     at enemy.gd:691, `var enemy_type = "bat" if is_bat_type else ("skeleton" if
##     name.begins_with("Skeleton") else "")`, so it can only ever hold "bat",
##     "skeleton" or "". No scene sets it; no code assigns it.
##
## So the loudest kill in a run -- one that announces itself, drops a guaranteed mega
## chest, a relic and ten coins, and pays 80 gold -- advanced the ultimate bar by
## nothing. Measured before the fix: a trash mob awarded +2.60 (2.0 through a 1.3
## harvest multiplier), a goblin 0.
##
## ci.sh could not have caught this either: it greps for `SCRIPT ERROR:`, and an
## unreachable elif reports nothing at all.
##
## WHAT THIS SUITE DELIBERATELY DOES NOT DO: it never calls die(). die() pays gold,
## and GameManager.add_gold() calls save_game_data() with no suppression switch, so
## exercising it rewrites user://save_data.cfg -- outside this repository. The award
## is therefore a separate method precisely so the number that regressed can be
## measured here. The trade-off is real and worth stating: this proves the award
## pays 15, not that die() invokes it. `die()` calling `_award_dragon_soul()` is one
## line and both are greppable; the number itself lives in only one place.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const GOBLIN_SCENE := preload("res://scenes/goblin.tscn")

var _live: Player = null
var _gob: TreasureGoblin = null

## A fresh Knight with the harvest multiplier pinned to 1.0 and the bar zeroed, so a
## measured award is the bare charge_gain rather than a relic-scaled version of it.
func _hero() -> Player:
	# free(), not queue_free(): part of this _ready() is synchronous, so a deferred
	# free can still be pending when the next player is added and both are in the
	# "player" group at once -- and the group lookup then silently returns the wrong.
	if is_instance_valid(_live):
		_live.free()
	GameManager.selected_character = "knight"
	_live = PLAYER_SCENE.instantiate() as Player
	add_child(_live)
	_live.apply_character_data()
	_live.dragon_soul_harvest_mult = 1.0
	_live.dragon_soul = 0.0
	return _live

func _goblin() -> TreasureGoblin:
	if is_instance_valid(_gob):
		_gob.free()
	_gob = GOBLIN_SCENE.instantiate() as TreasureGoblin
	add_child(_gob)
	return _gob

# --- 1. the root cause ------------------------------------------------------

func _test_a_treasure_goblin_is_not_an_enemy() -> void:
	# The canary. This is the fact the misplaced elif hid: a goblin never runs
	# enemy.gd, so anything a goblin is owed has to be granted in goblin.gd.
	var gob = _goblin()
	check(not (gob is Enemy),
		"TreasureGoblin must not extend Enemy -- if it did, enemy.gd's die() would run and this whole bug could not happen")
	check(gob is CharacterBody2D, "TreasureGoblin is still a CharacterBody2D")
	check(gob.has_method("_award_dragon_soul"),
		"the goblin owns its own soul award, because enemy.gd's is unreachable from here")

# --- 2. the promise ---------------------------------------------------------

func _test_killing_a_goblin_pays_fifteen_soul() -> void:
	_hero()
	var gob = _goblin()
	gob._award_dragon_soul()
	check(is_equal_approx(_live.dragon_soul, 15.0),
		"a Treasure Goblin pays 15 Long Hồn, got %.2f -- 0 is the bug this suite exists for"
		% _live.dragon_soul)

# --- 3. the harvest multiplier still applies --------------------------------

func _test_the_relic_multiplier_scales_it() -> void:
	# apply_relic_effects sets this to 1.0 + dan*0.30; a hero who paid for that relic
	# should see 15 * 1.3 = 19.5, not a flat 15.
	_hero()
	_live.dragon_soul_harvest_mult = 1.3
	_goblin()._award_dragon_soul()
	check(is_equal_approx(_live.dragon_soul, 19.5),
		"the 1.3 harvest multiplier scales the 15 to 19.5, got %.2f" % _live.dragon_soul)

# --- 4. a full bar is still a full bar --------------------------------------

func _test_the_bar_still_caps() -> void:
	# 15 x 7 = 105 > 100, so the cap inside add_dragon_soul is what stops the bar
	# overflowing -- not the goblin quietly paying less than advertised.
	_hero()
	var gob = _goblin()
	for _i in 7:
		gob._award_dragon_soul()
	check(is_equal_approx(_live.dragon_soul, _live.dragon_soul_max),
		"seven goblins (105 soul) cap the bar at dragon_soul_max = 100, got %.2f of %.2f"
		% [_live.dragon_soul, _live.dragon_soul_max])

# --- 5. and the guard still guards ------------------------------------------

func _test_no_player_means_no_crash() -> void:
	# The real job of the is_instance_valid guard: a goblin that despawns with the
	# player gone must not take the run down with a null dereference.
	_hero()
	_live.free()
	_live = null
	_goblin()._award_dragon_soul()
	check(true, "a goblin awarding soul with no player in the tree does not crash")

func _ready() -> void:
	print("=== RUNNING EXPANSION 60.0 TEST SUITE ===")

	# No user:// access anywhere in this suite -- see the header.
	GameManager.selected_character = "knight"

	await _test_a_treasure_goblin_is_not_an_enemy()
	await _test_killing_a_goblin_pays_fifteen_soul()
	await _test_the_relic_multiplier_scales_it()
	await _test_the_bar_still_caps()
	await _test_no_player_means_no_crash()

	if is_instance_valid(_gob):
		_gob.free()
	if is_instance_valid(_live):
		_live.free()

	if _failures.is_empty():
		print("=== ALL EXPANSION 60.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())