extends Node

## Test Suite for Project Z-Survivor Milestone 4:
## Bio-Contamination, Toxic Bile Puddles, Corrosive Projectiles, and Mutant Apex Bosses.

var _failures: Array[String] = []

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING ZOMBIE BIO-CONTAMINATION & APEX BOSS TEST SUITE ===")
	var orig_stage = GameManager.selected_stage if GameManager else "martial_arts"
	if GameManager:
		GameManager.is_run_active = false
		GameManager.selected_stage = "zombie_city"

	_test_toxic_puddle_mechanics()
	_test_barrel_incineration_synergy()
	await _test_toxic_projectile_and_spitter()
	_test_mutant_bosses()
	_test_player_toxic_slow()

	if GameManager:
		GameManager.selected_stage = orig_stage

	if _failures.is_empty():
		print("PASSED: All Zombie Bio-Contamination & Apex Boss tests passed cleanly!")
	else:
		push_error("FAILED: %d assertions failed in Bio-Contamination tests!" % _failures.size())

	get_tree().quit(0 if _failures.is_empty() else 1)

func _test_toxic_puddle_mechanics() -> void:
	var puddle_scene = load("res://scenes/toxic_bile_puddle.tscn") as PackedScene
	check(puddle_scene != null, "ToxicBilePuddle scene must load")
	var puddle = puddle_scene.instantiate()
	add_child(puddle)
	
	check(puddle.is_in_group("toxic_puddles"), "Puddle must be in 'toxic_puddles' group")
	check(puddle.is_in_group("hazard_zones"), "Puddle must be in 'hazard_zones' group")
	check(puddle.lifetime >= 7.0, "Puddle lifetime must be >= 7.0s")
	check(puddle.tick_damage >= 3.0, "Puddle tick damage must be >= 3.0")
	
	# Test player entering puddle
	var player_scene = load("res://scenes/player.tscn") as PackedScene
	var p = player_scene.instantiate()
	add_child(p)
	puddle._on_body_entered(p)
	check(puddle.player_inside == p, "Player must be registered as inside puddle")
	
	# Process one damage tick
	puddle.tick_timer = 0.0
	var prev_hp: float = p.current_health
	puddle._process(0.01)
	check(p.current_health < prev_hp, "Player HP must decrease from toxic tick damage")
	check(p.toxic_slime_timer > 0.0, "Player must receive toxic slow debuff")
	
	puddle._on_body_exited(p)
	check(puddle.player_inside == null, "Player must be cleared on body exit")
	
	p.queue_free()
	puddle.queue_free()
	print("✔ Toxic bile puddle lifecycle, tick damage, and slow mechanics verified.")

func _test_barrel_incineration_synergy() -> void:
	var barrel_scene = load("res://scenes/explosive_barrel.tscn") as PackedScene
	var puddle_scene = load("res://scenes/toxic_bile_puddle.tscn") as PackedScene
	var b = barrel_scene.instantiate()
	var puddle = puddle_scene.instantiate()
	add_child(b)
	add_child(puddle)
	
	b.global_position = Vector2(100, 100)
	puddle.global_position = Vector2(140, 100) # within 40px, well within blast radius
	
	check(not puddle.is_incinerated, "Puddle must start un-incinerated")
	b.detonate()
	check(puddle.is_incinerated, "Barrel explosion must incinerate nearby toxic bile puddle")
	
	b.queue_free()
	puddle.queue_free()
	print("✔ Interactive synergy: Explosive barrel blast incinerates toxic puddles verified.")

func _test_toxic_projectile_and_spitter() -> void:
	var projectile_scene = load("res://scenes/toxic_projectile.tscn") as PackedScene
	check(projectile_scene != null, "ToxicProjectile scene must load")
	var proj = projectile_scene.instantiate()
	add_child(proj)
	check(proj.is_in_group("enemy_projectiles"), "Projectile must be in 'enemy_projectiles' group")
	check(proj.speed > 100.0, "Projectile speed must be > 100")
	check(proj.damage > 5.0, "Projectile damage must be > 5")
	proj.queue_free()
	
	var spitter_scene = load("res://scenes/zombie_spitter.tscn") as PackedScene
	check(spitter_scene != null, "ZombieSpitter scene must load")
	var spitter = spitter_scene.instantiate()
	add_child(spitter)
	check(spitter.is_in_group("enemies"), "Spitter must be in 'enemies' group")
	check(spitter.is_ranged, "Spitter must be marked as ranged")
	check(spitter.projectile_scene != null, "Spitter must have projectile scene wired")
	check(is_equal_approx(spitter.max_health, 36.0), "Spitter max HP must be 36.0")
	
	# Clear any previous puddles before testing spitter death
	for p_old in get_tree().get_nodes_in_group("toxic_puddles"):
		p_old.queue_free()
	await get_tree().process_frame

	# Verify death triggers bile puddle spawn
	var before_count = get_tree().get_nodes_in_group("toxic_puddles").size()
	spitter.die()
	await get_tree().process_frame
	var after_count = get_tree().get_nodes_in_group("toxic_puddles").size()
	check(after_count > before_count, "Spitter death must spawn a toxic bile puddle")
	
	# Clean up spawned puddles
	for p_node in get_tree().get_nodes_in_group("toxic_puddles"):
		p_node.queue_free()
	print("✔ Zombie Spitter ranged attributes and death puddle verified.")

func _test_mutant_bosses() -> void:
	var juggernaut_scene = load("res://scenes/mutant_juggernaut.tscn") as PackedScene
	check(juggernaut_scene != null, "Mutant Juggernaut scene must load")
	var jugg = juggernaut_scene.instantiate()
	add_child(jugg)
	check(jugg.is_boss, "Juggernaut must be marked as boss")
	check(jugg.is_in_group("bosses"), "Juggernaut must be in 'bosses' group")
	check(jugg.boss_name.contains("JUGGERNAUT"), "Juggernaut boss_name must contain JUGGERNAUT")
	check(is_equal_approx(jugg.max_health, 750.0), "Juggernaut max HP must be 750.0")
	jugg.queue_free()
	
	var bio_titan_scene = load("res://scenes/bio_titan.tscn") as PackedScene
	check(bio_titan_scene != null, "Bio-Titan scene must load")
	var titan = bio_titan_scene.instantiate()
	add_child(titan)
	check(titan.is_boss, "Bio-Titan must be marked as boss")
	check(titan.is_in_group("bosses"), "Bio-Titan must be in 'bosses' group")
	check(titan.boss_name.contains("BIO-TITAN"), "Bio-Titan boss_name must contain BIO-TITAN")
	check(is_equal_approx(titan.max_health, 2400.0), "Bio-Titan max HP must be 2400.0")
	titan.queue_free()
	print("✔ Mutant Juggernaut and Bio-Titan apex bosses verified.")

func _test_player_toxic_slow() -> void:
	var player_scene = load("res://scenes/player.tscn") as PackedScene
	var p = player_scene.instantiate()
	add_child(p)
	
	p.apply_toxic_slow(1.0)
	check(p.toxic_slime_timer > 0.0, "Player toxic slime timer must be active")
	var slow_mult: float = p.get_slow_multiplier()
	check(is_equal_approx(slow_mult, 0.80), "Toxic slow multiplier must be 0.80, got %f" % slow_mult)
	
	p.queue_free()
	print("✔ Player toxic slow debuff formula verified.")
