extends "res://tests/suite_base.gd"

## Expansion 56.0: the pause panel's PYRO readout was one of six stat sources.
##
## Expansion 45.0 fixed exactly this bug for MIGHT -- `_build_might_bonus()` sums
## four sources and the panel reported only the meta upgrade's. ARMOR went with it.
## PYRO was the same defect left behind, and it was the worst-placed of the six:
## the blast expression at player.gd:391 has six terms and pyro is the smallest.
##
## Measured 2026-10-01 at pyro 5 + Dan Dien 3 + Y Thien Kiem equipped:
##
##   PAUSE PANEL SHOWS: PYRO: +60%
##   ACTUAL BONUS IS   : PYRO: +175%      (blast_radius_multiplier = 2.75)
##
## 115 points of a stat the player paid for and could not see. The other end is
## worse for trust rather than magnitude: pyro 0 with Cai Bang printed "+0%" while
## every fireball was thrown 40% wider than base, because the character's
## area_of_effect_bonus is a term in the same expression and was never read.
##
## The suite reads the rendered label off a real instantiated HUD rather than
## recomputing the expression, because the label is the thing that was wrong. A
## test that duplicated the fixed formula would pass against the broken panel for
## as long as both copies stayed equal.

## Build a main scene with the given meta/meridian/gear state already written.
## The dicts are assigned directly rather than through buy_meta_upgrade() /
## buy_meridian_upgrade() / equip_gear() -- all three call save_game_data(), and a
## test that spends the developer's gold is a test that fails differently on
## Tuesday than it did on Monday.
func _world() -> Node:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("refresh_meta_stats"):
		p.refresh_meta_stats()
	return main

## The number the panel actually put on screen, parsed back out of its text.
func _shown_pyro(hud: Node) -> int:
	var label = hud.get_node_or_null("PausePanel/VBox/StatsLabel")
	if label == null:
		return -999
	hud._refresh_pause_stats()
	var m := RegEx.new()
	m.compile("PYRO: \\+(-?\\d+)%")
	var r := m.search(label.text)
	if r == null:
		return -999
	return int(r.get_string(1))

## The number the game actually applies, straight off the field the fireball is
## thrown with (fireball_weapon.gd:86 -- fb.blast_radius *= blast_radius_multiplier).
func _actual_pyro() -> int:
	var p = get_tree().get_first_node_in_group("player")
	if p == null:
		return -999
	var fb = p.get_node_or_null("Weapons/FireballWeapon")
	if fb == null:
		return -999
	return int(roundf((fb.blast_radius_multiplier - 1.0) * 100.0))

func _test_panel_reports_the_real_blast_bonus() -> void:
	GameManager.meta_upgrades["pyro"] = 5
	GameManager.meridian_upgrades["dan_dien"] = 3
	GameManager.equipment_slots["weapon"] = "y_thien_kiem"
	var main = _world()
	var hud = main.get_node_or_null("HUD")
	if not check(hud != null, "HUD node exists on the main scene"):
		main.queue_free()
		return

	var shown := _shown_pyro(hud)
	var actual := _actual_pyro()
	check(shown != -999, "PausePanel StatsLabel exists and renders a PYRO figure")
	check(actual != -999, "the player carries a FireballWeapon to read a blast multiplier from")
	check(actual == 175,
		"fixture sanity: pyro 5 + dan_dien 3 + y_thien_kiem should be a +175%% blast bonus, got %d" % actual)
	check(shown == actual,
		"pause panel shows PYRO +%d%% while the fireball actually fires at +%d%%" % [shown, actual])

	main.queue_free()

func _test_zero_pyro_still_reports_the_equipped_sword() -> void:
	# The other end of the same bug: a player who bought no pyro at all was told
	# they had no AoE bonus. Y Thien Kiem's 1.25 multiplies the whole expression,
	# so even with pyro 0 and no meridian the honest answer is not zero.
	GameManager.meta_upgrades["pyro"] = 0
	GameManager.meridian_upgrades["dan_dien"] = 0
	var main = _world()
	var hud = main.get_node_or_null("HUD")
	if not check(hud != null, "HUD node exists on the main scene"):
		main.queue_free()
		return

	var shown := _shown_pyro(hud)
	var actual := _actual_pyro()
	check(shown == actual,
		"with pyro 0 the panel shows PYRO +%d%% but the blast is +%d%%" % [shown, actual])
	check(actual > 0, "Y Thien Kiem alone is a +25%% blast bonus, fixture says %d" % actual)

	main.queue_free()

func _ready() -> void:
	print("=== RUNNING EXPANSION 56.0: HUD STAT READOUT TEST SUITE ===")
	GameManager.is_run_active = false

	_test_panel_reports_the_real_blast_bonus()
	_test_zero_pyro_still_reports_the_equipped_sword()

	if _failures.is_empty():
		print("=== ALL EXPANSION 56.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())