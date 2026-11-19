extends Node

## Test Suite: Viral Zombie Mechanics (Explosive Barrel Chain Reactions, Airdrops, Overdrive & Arena Props)

var _failures: Array[String] = []

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING TEST SUITE: VIRAL ZOMBIE MECHANICS ===")
	var orig_stage = GameManager.selected_stage if GameManager else "martial_arts"

	_test_explosive_barrel_detonation()
	_test_barrel_chain_reaction()
	_test_airdrop_crate_collection_and_overdrive()
	_test_player_overdrive_speed()

	if GameManager:
		GameManager.selected_stage = orig_stage

	if _failures.is_empty():
		print("PASSED: All Viral Zombie Mechanics tests passed cleanly!")
	else:
		push_error("FAILED: %d assertions failed in Viral Zombie Mechanics tests!" % _failures.size())

	get_tree().quit(0 if _failures.is_empty() else 1)

func _test_explosive_barrel_detonation() -> void:
	var barrel_scene = load("res://scenes/explosive_barrel.tscn") as PackedScene
	check(barrel_scene != null, "Explosive barrel scene loads successfully")
	if not barrel_scene:
		return

	var b = barrel_scene.instantiate()
	add_child(b)
	b.global_position = Vector2(100, 100)

	check(b.is_in_group("explosive_barrels"), "Barrel is in explosive_barrels group")
	check(b.is_in_group("destructibles"), "Barrel is in destructibles group")
	check(b.is_in_group("enemies"), "Barrel is in enemies group for auto-targeting")

	# Create a dummy enemy within blast radius
	var enemy = Area2D.new()
	enemy.add_to_group("enemies")
	enemy.global_position = Vector2(120, 100) # 20px away
	add_child(enemy)

	# Take lethal damage on barrel
	b.take_damage(50.0)
	check(b.is_primed or b.is_detonated, "Barrel is primed or detonated on lethal hit")

	# Force immediate detonation
	b.detonate()
	check(b.is_detonated, "Barrel marked detonated")

	enemy.queue_free()

func _test_barrel_chain_reaction() -> void:
	var barrel_scene = load("res://scenes/explosive_barrel.tscn") as PackedScene
	if not barrel_scene:
		return

	var b1 = barrel_scene.instantiate()
	var b2 = barrel_scene.instantiate()
	add_child(b1)
	add_child(b2)

	b1.global_position = Vector2(200, 200)
	b2.global_position = Vector2(280, 200) # 80px away, well within 175px explosion_radius

	check(not b1.is_detonated, "B1 start un-detonated")
	check(not b2.is_detonated, "B2 start un-detonated")

	# Detonate B1
	b1.detonate()
	check(b1.is_detonated, "B1 detonated")
	check(b2.is_primed or b2.is_detonated, "B2 was caught in blast and primed for chain reaction")

	b2.detonate()
	check(b2.is_detonated, "B2 chain reaction completed")

func _test_airdrop_crate_collection_and_overdrive() -> void:
	var airdrop_scene = load("res://scenes/airdrop_crate.tscn") as PackedScene
	check(airdrop_scene != null, "Airdrop crate scene loads successfully")
	if not airdrop_scene:
		return

	var drop = airdrop_scene.instantiate()
	add_child(drop)
	drop.global_position = Vector2(300, 300)
	drop.target_y = 300.0
	drop.is_landing = false # simulate landed

	check(drop.is_in_group("airdrop_crates"), "Drop is in airdrop_crates group")
	check(drop.is_in_group("pickups"), "Drop is in pickups group")

	var p_scene = load("res://scenes/player.tscn") as PackedScene
	check(p_scene != null, "Player scene exists")
	var player_node = p_scene.instantiate()
	add_child(player_node)

	var orig_gold = GameManager.run_gold if GameManager else 0

	# Collect airdrop
	drop.collect_airdrop(player_node)

	check(drop.is_collected, "Airdrop marked collected")
	if GameManager:
		check(GameManager.run_gold >= orig_gold + 60, "Airdrop awarded +60 gold")

	check(player_node.overdrive_buff_timer > 0.0, "Player received overdrive buff timer")

	player_node.queue_free()

func _test_player_overdrive_speed() -> void:
	var p_scene = load("res://scenes/player.tscn") as PackedScene
	var p = p_scene.instantiate()
	add_child(p)

	var base_mult = p.get_attack_speed_multiplier()
	p.apply_overdrive_buff(6.0)

	check(p.overdrive_buff_timer == 6.0, "Overdrive timer set to 6.0s")
	check(p.get_attack_speed_multiplier() >= base_mult * 1.7, "Attack speed multiplied during Overdrive")

	p.queue_free()
