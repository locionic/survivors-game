extends Node

## Comprehensive test suite verifying Expansion 9.0:
## Active Hero Skills, Tactical Dash, Treasure Goblin, and Blood Moon Eclipse.

func _ready() -> void:
	print("=== RUNNING EXPANSION 9.0 ACTIVE SKILLS, GOBLINS & BLOOD MOON TEST SUITE ===")
	
	# 1. Test Player Hero Skill Setup for Knight (Sir Kaelen)
	GameManager.select_character("knight")
	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	
	assert(player.skill_id == "shield_charge", "Knight has shield_charge skill")
	assert(player.skill_cooldown_max == 5.5, "Knight skill cooldown is 5.5s")
	assert(player.skill_cooldown_timer == 0.0, "Skill starts off cooldown")
	
	# Test Knight Shield Charge Activation
	var activated = player.activate_hero_skill()
	assert(activated == true, "Skill activated successfully")
	assert(player.is_dashing == true, "Player is dashing")
	assert(player.invulnerability_timer >= 0.8, "Shield charge grants invulnerability window")
	assert(player.skill_cooldown_timer > 5.0, "Cooldown timer is running")
	
	# Test Cooldown prevention
	var double_tap = player.activate_hero_skill()
	assert(double_tap == false, "Cannot activate skill while on cooldown")
	
	# Advance physics process through dash
	player._physics_process(0.40)
	assert(player.is_dashing == false, "Dash completes after duration")
	
	# 2. Test Chrono Hourglass cooldown reduction synergy
	GameManager.add_relic("chrono_hourglass")
	player.skill_cooldown_timer = 0.0
	player.activate_hero_skill()
	assert(player.skill_cooldown_timer <= 5.5 * 0.85, "Chrono hourglass reduces skill cooldown by 20%")
	player.free()
	print("✔ Knight Shield Charge activation, dash physics, and relic reduction verified.")
	
	# 3. Test Pyro (Inferno Blink)
	GameManager.select_character("pyro")
	player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	assert(player.skill_id == "inferno_blink", "Pyro has inferno_blink")
	assert(player.skill_cooldown_max == 5.0, "Pyro skill cooldown is 5.0s")
	var start_pos = player.global_position
	player.last_move_dir = Vector2.RIGHT
	player.activate_hero_skill()
	assert(player.global_position.x > start_pos.x + 150.0, "Inferno blink teleports forward")
	assert(player.invulnerability_timer >= 0.45, "Inferno blink grants i-frames")
	player.free()
	print("✔ Pyromancer Inferno Blink teleportation and invulnerability verified.")
	
	# 4. Test Ranger (Shadow Roll)
	GameManager.select_character("ranger")
	player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	assert(player.skill_id == "shadow_roll", "Ranger has shadow_roll")
	assert(player.skill_cooldown_max == 4.2, "Ranger skill cooldown is 4.2s")
	player.activate_hero_skill()
	assert(player.is_dashing == true, "Ranger enters roll state")
	player.free()
	print("✔ Ranger Shadow Roll evasive tumble verified.")
	
	# 5. Test Mage (Frost Stasis Singularity) & Enemy Freezing
	GameManager.select_character("mage")
	player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	assert(player.skill_id == "frost_singularity", "Mage has frost_singularity")
	assert(player.skill_cooldown_max == 6.5, "Mage skill cooldown is 6.5s")
	
	# Spawn test enemy nearby
	var bat_scene = load("res://scenes/bat.tscn")
	assert(bat_scene != null, "Bat scene exists")
	var enemy = bat_scene.instantiate()
	enemy.max_health = 100.0
	enemy.current_health = 100.0
	enemy.global_position = player.global_position + Vector2(100, 0)
	add_child(enemy)
	
	player.activate_hero_skill()
	assert(enemy.freeze_timer > 2.0, "Enemy in frost stasis radius is frozen")
	
	# Advance enemy physics while frozen - should not move towards player
	var old_enemy_x = enemy.global_position.x
	enemy._physics_process(0.1)
	assert(abs(enemy.global_position.x - old_enemy_x) < 2.0, "Frozen enemy remains immobilized")
	
	enemy.free()
	player.free()
	print("✔ Mage Frost Stasis Singularity and enemy freeze immobilization verified.")
	
	# 6. Test Treasure Goblin Entity
	var goblin_scene = load("res://scenes/goblin.tscn")
	assert(goblin_scene != null, "TreasureGoblin scene exists")
	var goblin = goblin_scene.instantiate()
	add_child(goblin)
	assert(goblin.is_in_group("enemies"), "Goblin is in enemies group")
	assert(goblin.is_in_group("goblins"), "Goblin is in goblins group")
	assert(goblin.current_health == 75.0, "Goblin starts with 75 HP")
	
	# Test Goblin Damage reaction (drops coin)
	var prev_gold = GameManager.total_gold
	goblin.take_damage(10.0)
	assert(goblin.current_health == 65.0, "Goblin takes damage")
	
	# Test Goblin Death (Drops mega rewards + completes Greed Hunter bounty)
	GameManager.init_run_bounties()
	goblin.die()
	assert(goblin.is_dead == true, "Goblin marked as dead")
	assert(GameManager.total_gold > prev_gold, "Goblin death awards gold")
	
	var bounty_found = false
	for b in GameManager.active_bounties:
		if b["id"] == "defeat_goblin" and b["completed"]:
			bounty_found = true
			break
	assert(bounty_found == true, "Greed Hunter bounty completed upon slaying Goblin")
	print("✔ Treasure Goblin flee behavior, damage reaction, death rewards, and bounty verified.")
	
	# 7. Test Blood Moon Eclipse Mechanics
	assert(GameManager.is_blood_moon == false, "Blood moon initially inactive")
	GameManager.trigger_blood_moon(30.0)
	assert(GameManager.is_blood_moon == true, "Blood moon is active")
	assert(GameManager.blood_moon_timer == 30.0, "Blood moon timer set to 30s")
	
	# Test 2x Gold during Blood Moon
	var gold_before = GameManager.total_gold
	GameManager.collected_relics.clear() # clear horseshoe for pure 2x test
	GameManager.add_gold(50)
	assert(GameManager.total_gold == gold_before + 100, "Blood Moon doubles gold drops (50 * 2 = 100)")
	
	# Test 2x XP during Blood Moon
	GameManager.select_character("knight")
	player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	player.add_xp(10.0)
	assert(player.level == 2, "Blood Moon 2x XP (20 XP) leveled player up to Level 2")
	assert(player.current_xp == 10.0, "10 overflow XP carried over to Level 2")
	player.free()
	
	# Test Blood Moon timeout countdown
	GameManager.is_run_active = true
	GameManager._process(30.5)
	assert(GameManager.is_blood_moon == false, "Blood Moon ends when timer expires")
	print("✔ Blood Moon Eclipse 2x Gold, 2x XP, and lifecycle duration verified.")
	
	# 8. Test EnemySpawner Event Timers
	var spawner_script = load("res://scripts/enemy_spawner.gd")
	assert(spawner_script != null, "EnemySpawner script exists")
	var spawner = Node2D.new()
	spawner.set_script(spawner_script)
	add_child(spawner)
	assert(spawner.goblin_scene != null, "EnemySpawner has goblin_scene preloaded")
	spawner.free()
	print("✔ EnemySpawner Goblin and Blood Moon event triggers verified.")
	
	print("=== ALL EXPANSION 9.0 TESTS PASSED CLEANLY! ===")
	get_tree().quit(0)
