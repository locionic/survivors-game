extends "res://tests/suite_base.gd"

## Comprehensive test suite verifying Expansion 10.0:
## Võ Lâm & Dragon Legend Edition (Long Hồn Awakening & Ngũ Hành Five Elements).

func _ready() -> void:
	print("=== RUNNING EXPANSION 10.0 VÕ LÂM & DRAGON LEGEND TEST SUITE ===")
	
	# 1. Setup Player & Test Dragon Soul Gauge Mechanics
	GameManager.select_character("knight")
	GameManager.meridian_upgrades = {"nham_mach": 0, "doc_mach": 0, "xung_mach": 0, "dan_dien": 0}
	var player_scene = load("res://scenes/player.tscn")
	check(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	player.refresh_meta_stats()
	
	check(player.dragon_soul == 0.0, "Dragon soul begins at 0")
	check(player.dragon_soul_max == 100.0, "Dragon soul max capacity is 100")
	check(player.is_dragon_awakened == false, "Player starts in mortal form")
	
	# Test adding Dragon Soul with dictionary closure capture
	var soul_state = {"fired": false, "val": 0.0}
	player.dragon_soul_changed.connect(func(curr, _max_val):
		soul_state["fired"] = true
		soul_state["val"] = curr
	)
	
	player.add_dragon_soul(35.0)
	check(player.dragon_soul == 35.0, "Dragon soul increases correctly")
	check(soul_state["fired"] == true and soul_state["val"] == 35.0, "dragon_soul_changed signal emitted")
	
	# Test cannot activate before 100%
	var premature_activation = player.activate_dragon_awakening()
	check(premature_activation == false, "Cannot activate Dragon Awakening before 100% soul")
	check(player.is_dragon_awakened == false, "Remains mortal")
	
	# Test capping at 100
	player.add_dragon_soul(100.0)
	check(player.dragon_soul == 100.0, "Dragon soul capped at 100")
	print("✔ Dragon Soul accumulation, capping, and premature activation prevention verified.")
	
	# 2. Test Enemy Kill Soul Grants
	var bat_scene = load("res://scenes/bat.tscn")
	check(bat_scene != null, "Bat scene exists")
	
	# Reset soul to 10
	player.dragon_soul = 10.0
	
	# Normal mob kill
	var mob = bat_scene.instantiate()
	add_child(mob)
	mob.die()
	check(player.dragon_soul >= 12.0, "Normal mob death awards +2 Dragon Soul")
	
	# Champion kill
	var champ = bat_scene.instantiate()
	add_child(champ)
	champ.make_champion("volatile")
	champ.die()
	check(player.dragon_soul >= 24.0, "Champion death awards +12 Dragon Soul")
	
	# Boss kill
	var boss = bat_scene.instantiate()
	boss.is_boss = true
	add_child(boss)
	boss.die()
	check(player.dragon_soul >= 59.0, "Boss death awards +35 Dragon Soul")
	print("✔ Enemy kill Dragon Soul harvesting (normal, champion, boss) verified.")
	
	# 3. Test Dragon Awakening Transformation (Kim Long Thần Giáng)
	player.dragon_soul = 100.0
	var awakened_state = {"fired": false}
	player.dragon_awakened.connect(func(_dur):
		awakened_state["fired"] = true
	)
	
	var activated = player.activate_dragon_awakening()
	check(activated == true, "Dragon Awakening activates at 100% soul")
	check(player.is_dragon_awakened == true, "Player transformed into Celestial Golden Dragon")
	check(player.dragon_soul == 0.0, "Dragon soul consumed upon awakening")
	check(awakened_state["fired"] == true, "dragon_awakened signal fired")
	check(player.invulnerability_timer >= 8.0, "Awakening grants celestial invulnerability")
	
	# Test invulnerability against damage
	var hp_before = player.current_health
	player.take_damage(50.0)
	check(player.current_health == hp_before, "Dragon form is completely invulnerable to damage")
	
	# Test dragon texture assignment
	check(player.sprite != null, "Player has sprite")
	check(player.sprite.texture != null, "Player sprite texture assigned")
	check(player.sprite.texture.resource_path.contains("dragon_form"), "Texture switched to Celestial Dragon")
	print("✔ Celestial Golden Dragon transformation, invulnerability, and texture switch verified.")
	
	# 4. Test Dragon Breath (Giáng Long Thập Bát Chưởng Flame Torrent)
	var near_enemy = bat_scene.instantiate()
	near_enemy.max_health = 200.0
	near_enemy.current_health = 200.0
	near_enemy.global_position = player.global_position + Vector2(60, 0)
	add_child(near_enemy)
	
	var far_enemy = bat_scene.instantiate()
	far_enemy.max_health = 200.0
	far_enemy.current_health = 200.0
	far_enemy.global_position = player.global_position + Vector2(400, 0)
	add_child(far_enemy)
	
	player._execute_dragon_breath()
	check(near_enemy.current_health < 200.0, "Near enemy scorched by Dragon Breath")
	check(near_enemy.burn_timer > 0.0, "Near enemy inflicted with Ngũ Hành Fire Burn DoT")
	check(far_enemy.current_health == 200.0, "Far enemy beyond breath radius untouched")
	near_enemy.free()
	far_enemy.free()
	print("✔ Giáng Long Dragon Breath AoE damage and Fire Burn infliction verified.")
	
	# 5. Test Dragon Awakening Reversion
	var ended_state = {"fired": false}
	player.dragon_ended.connect(func():
		ended_state["fired"] = true
	)
	player.revert_dragon_awakening()
	check(player.is_dragon_awakened == false, "Player returned to mortal form")
	check(ended_state["fired"] == true, "dragon_ended signal fired")
	check(player.sprite.texture.resource_path.contains("player.png"), "Sprite texture reverted to hero texture")
	print("✔ Celestial Dragon expiration and mortal form reversion verified.")
	
	# 6. Test Ngũ Hành (Five Elements) Status Effects on Enemies
	var test_dummy = bat_scene.instantiate()
	test_dummy.max_health = 200.0
	test_dummy.current_health = 200.0
	add_child(test_dummy)
	
	# Fire (Hỏa): Burn DoT
	test_dummy.apply_burn(3.0, 30.0)
	check(test_dummy.burn_timer == 3.0, "Burn timer set")
	check(test_dummy.burn_dps == 30.0, "Burn DPS set")
	var hp_before_burn = test_dummy.current_health
	test_dummy._physics_process(0.40)
	check(test_dummy.current_health < hp_before_burn, "Enemy took Fire Burn DoT damage")
	
	# Wood (Mộc): Poison DoT
	test_dummy.apply_poison(3.0, 25.0)
	check(test_dummy.poison_timer == 3.0, "Poison timer set")
	check(test_dummy.poison_dps == 25.0, "Poison DPS set")
	var hp_before_poison = test_dummy.current_health
	test_dummy._physics_process(0.50)
	check(test_dummy.current_health < hp_before_poison, "Enemy took Wood Poison DoT damage")
	
	# Water (Thủy): Slow & Freeze
	test_dummy.burn_timer = 0.0
	test_dummy.apply_slow(2.0, 0.4)
	check(test_dummy.slow_timer == 2.0, "Slow timer set")
	check(test_dummy.slow_multiplier == 0.4, "Slow multiplier reduced to 40%")
	
	test_dummy.apply_freeze(1.5)
	check(test_dummy.freeze_timer == 1.5, "Freeze timer set")
	
	test_dummy.free()
	player.free()
	print("✔ Ngũ Hành Five Elements (Hỏa Burn, Mộc Poison, Thủy Freeze/Slow) verified.")
	
	# 7. Test HUD Dragon Awakening Widget
	var main_scene = load("res://scenes/main.tscn")
	check(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	var hud: HUD = main.get_node("HUD")
	check(hud != null, "HUD exists in main scene")
	
	check(hud.dragon_widget != null, "HUD contains DragonAwakeningWidget")
	check(hud.dragon_button != null, "HUD contains DragonButton")
	check(hud.dragon_bar != null, "HUD contains DragonSoulBar")
	
	# Test HUD updates on soul change
	hud._on_player_dragon_soul_changed(50.0, 100.0)
	check(hud.dragon_bar.value == 50.0, "HUD DragonSoulBar tracks 50% charge")
	check(hud.dragon_button.text.contains("50%"), "HUD button text shows 50%")
	
	# Test HUD ready state at 100%
	hud._on_player_dragon_soul_changed(100.0, 100.0)
	check(hud.dragon_bar.value == 100.0, "HUD bar full at 100%")
	check(hud.dragon_button.text.contains("READY"), "HUD button shows READY prompt")
	
	# Test HUD active state during awakening
	hud._on_player_dragon_awakened(8.5)
	check(hud.is_dragon_active_ui == true, "HUD enters active dragon mode")
	
	hud._on_player_dragon_ended()
	check(hud.is_dragon_active_ui == false, "HUD exits active dragon mode")
	
	main.free()
	print("✔ HUD Dragon Awakening Widget, Soul Meter, and READY state verified.")
	
	if _failures.is_empty():
		print("=== ALL EXPANSION 10.0 TESTS PASSED CLEANLY! ===")
	get_tree().quit(_exit_code())
