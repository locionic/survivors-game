extends Node

func _ready() -> void:
	print("=== RUNNING EXTENSIVE EXPANSION 6.0 TEST SUITE ===")
	
	# 1. GameManager Currency & Meta-progression
	GameManager.start_new_run()
	assert(GameManager.run_gold == 0, "run_gold must be 0 at start")
	GameManager.add_gold(10)
	assert(GameManager.run_gold == 10, "run_gold should be 10")
	GameManager.double_run_gold()
	assert(GameManager.run_gold == 20, "run_gold doubled to 20")
	print("✔ Gold collection and double multiplier verified.")
	
	# 2. Meta Upgrades (Armor & Pyro)
	GameManager.meta_upgrades["armor"] = 1
	GameManager.meta_upgrades["pyro"] = 1
	var init_armor = 1
	var init_pyro = 1
	GameManager.add_gold(1000)
	GameManager.buy_meta_upgrade("armor")
	GameManager.buy_meta_upgrade("pyro")
	assert(GameManager.get_meta_stat("armor") == init_armor + 1, "Armor rank increased")
	assert(GameManager.get_meta_stat("pyro") == init_pyro + 1, "Pyro rank increased")
	print("✔ Armor and Pyro meta-upgrades verified.")
	
	# 3. Audio & Sound Manager
	assert(SoundManager.sounds.has("explosion"), "SoundManager should load explosion sound")
	assert(SoundManager.sounds.has("axe"), "SoundManager should load axe sound")
	assert(SoundManager.sounds.has("powerup"), "SoundManager should load powerup sound")
	assert(SoundManager.sounds.has("boss_alarm"), "SoundManager should load boss_alarm sound")
	assert(SoundManager.sounds.has("shrine_activate"), "SoundManager should load shrine_activate sound")
	var was_muted = SoundManager.is_muted
	var toggled = SoundManager.toggle_mute()
	assert(toggled != was_muted, "Audio toggle mute should flip state")
	SoundManager.toggle_mute() # Revert
	print("✔ SoundManager 6.0 sounds and mute toggle verified.")
	
	# 4. Weapons: Fireball, Battleaxe, & Might Multiplier
	var fire_scene = load("res://scenes/fireball_weapon.tscn")
	assert(fire_scene != null, "FireballWeapon scene exists")
	var fire_wpn = fire_scene.instantiate()
	assert(fire_wpn.fireball_scene != null, "FireballWeapon has fireball_scene")
	fire_wpn.upgrade_count()
	assert(fire_wpn.fireball_count == 2, "Fireball count upgrades properly")
	fire_wpn.free()
	
	var axe_scene = load("res://scenes/axe_weapon.tscn")
	assert(axe_scene != null, "AxeWeapon scene exists")
	var axe_wpn = axe_scene.instantiate()
	assert(axe_wpn.axe_scene != null, "AxeWeapon has axe_scene")
	axe_wpn.upgrade_count()
	assert(axe_wpn.axe_count == 2, "Axe count upgrades properly")
	axe_wpn.free()
	print("✔ Fireball and Battleaxe weapons verified.")
	
	# 5. Enemies: Necromancer & Behemoth
	var necro_scene = load("res://scenes/necromancer.tscn")
	assert(necro_scene != null, "Necromancer scene exists")
	var necro = necro_scene.instantiate()
	assert(necro.is_ranged == true, "Necromancer is marked ranged")
	assert(necro.projectile_scene != null, "Necromancer has projectile_scene")
	necro.free()
	
	var behemoth_scene = load("res://scenes/behemoth.tscn")
	assert(behemoth_scene != null, "Behemoth scene exists")
	var behemoth = behemoth_scene.instantiate()
	assert(behemoth.is_boss == true, "Behemoth is marked boss")
	assert(behemoth.is_radial_boss == true, "Behemoth has radial boss attacks")
	behemoth.free()
	print("✔ Necromancer and Infernal Behemoth enemies verified.")
	
	# 6. Power-up Items
	var pup_scene = load("res://scenes/powerup.tscn")
	assert(pup_scene != null, "PowerUp scene exists")
	var pup = pup_scene.instantiate()
	pup.set_type("meat")
	assert(pup.powerup_type == "meat", "Powerup sets meat type")
	pup.set_type("magnet")
	assert(pup.powerup_type == "magnet", "Powerup sets magnet type")
	pup.set_type("nuke")
	assert(pup.powerup_type == "nuke", "Powerup sets nuke type")
	pup.free()
	print("✔ Power-up pickup verified for meat, magnet, and nuke.")
	
	# 7. Player Scene with Buffs
	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	assert(player.get_node("Weapons/MainWeapon") != null, "Player has Daggers")
	assert(player.get_node("Weapons/OrbitingWeapon") != null, "Player has Shield")
	assert(player.get_node("Weapons/LightningWeapon") != null, "Player has Lightning")
	assert(player.get_node("Weapons/FireballWeapon") != null, "Player has Fireball")
	assert(player.get_node("Weapons/AxeWeapon") != null, "Player has Axe")
	
	# Test Player Buffs
	assert(player.get_might_multiplier() == 1.0, "Base might multiplier is 1.0")
	player.apply_might_buff(10.0, 1.4)
	assert(player.get_might_multiplier() == 1.4, "Might buff sets multiplier to 1.4")
	player.apply_speed_buff(10.0, 1.5)
	assert(player.speed_multiplier == 1.5, "Speed buff sets speed multiplier to 1.5")
	player.free()
	print("✔ Player 5-weapon arsenal and temporary buffs verified.")
	
	# 8. Landmark System & Shrines
	var lm_scene = load("res://scenes/landmark.tscn")
	assert(lm_scene != null, "Landmark scene exists")
	var fountain = lm_scene.instantiate()
	fountain.landmark_id = "fountain"
	fountain.landmark_name = "Sanctuary of Vitality"
	assert(fountain.is_discovered == false, "Landmark starts undiscovered")
	assert(GameManager.is_landmark_discovered("fountain") == false, "GameManager starts undiscovered")
	
	# Test Player interaction with Fountain
	var test_player = load("res://scenes/player.tscn").instantiate()
	test_player.current_health = 50.0
	fountain._handle_player_inside(test_player, 0.6)
	assert(test_player.current_health > 50.0, "Fountain restores player health")
	
	# Test Might Shrine
	var might = lm_scene.instantiate()
	might.landmark_id = "might"
	might.landmark_name = "Altar of Might"
	might._handle_player_inside(test_player, 0.6)
	assert(test_player.might_buff_timer > 0.0, "Might shrine grants might buff to player")
	
	# Test Speed Shrine
	var speed = lm_scene.instantiate()
	speed.landmark_id = "speed"
	speed.landmark_name = "Shrine of Swiftness"
	speed._handle_player_inside(test_player, 0.6)
	assert(test_player.speed_buff_timer > 0.0, "Speed shrine grants speed buff to player")
	
	# Test Vault
	var vault = lm_scene.instantiate()
	vault.landmark_id = "vault"
	vault.landmark_name = "Vault of the Ancients"
	assert(vault.chest_scene != null, "Vault has chest_scene export")
	assert(vault.coin_scene != null, "Vault has coin_scene export")
	add_child(vault)
	vault.discover(test_player)
	assert(GameManager.is_landmark_discovered("vault") == true, "Vault discovery recorded in GameManager")
	remove_child(vault)
	
	fountain.free()
	might.free()
	speed.free()
	vault.free()
	test_player.free()
	print("✔ Landmark shrines, healing, buffs, and discovery rewards verified.")

	
	# 9. World Obstacles
	var obs_scene = load("res://scenes/obstacle.tscn")
	assert(obs_scene != null, "Obstacle scene exists")
	var pillar = obs_scene.instantiate()
	pillar.obstacle_type = "pillar"
	assert(pillar.get_node("CollisionShape2D") != null, "Obstacle has physical collision")
	pillar.free()
	
	var tomb = obs_scene.instantiate()
	tomb.obstacle_type = "tomb"
	add_child(tomb)
	assert(tomb.is_broken == false, "Tomb starts unbroken")
	tomb.break_tomb()
	assert(tomb.is_broken == true, "Tomb breaks on hit")
	remove_child(tomb)
	tomb.free()
	print("✔ World obstacles (pillars, tombs) verified.")
	
	# 10. Minimap Radar and World Map UI
	var map_ui_scene = load("res://scenes/world_map_ui.tscn")
	assert(map_ui_scene != null, "WorldMapUI scene exists")
	var map_ui = map_ui_scene.instantiate()
	add_child(map_ui)
	assert(map_ui.visible == false, "WorldMapUI starts hidden")
	map_ui.open_map()
	assert(map_ui.visible == true, "WorldMapUI opens properly")
	assert(get_tree().paused == true, "Opening world map pauses the game")
	map_ui.close_map()
	assert(map_ui.visible == false, "WorldMapUI closes properly")
	assert(get_tree().paused == false, "Closing world map unpauses game")
	remove_child(map_ui)
	map_ui.free()
	print("✔ Interactive WorldMapUI verified.")
	
	# 11. Persistence verification (Save & Load)
	var prev_gold = GameManager.total_gold
	GameManager.add_gold(50)
	GameManager.save_game_data()
	GameManager.load_save_data()
	assert(GameManager.total_gold >= prev_gold + 50, "Save and load preserves gold")
	print("✔ Save/Load persistent storage verified.")
	
	# 12. Full Main Scene Hierarchy
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	assert(main.get_node("Biomes") != null, "Biomes container exists")
	assert(main.get_node("Landmarks") != null, "Landmarks container exists")
	assert(main.get_node("Obstacles") != null, "Obstacles container exists")
	assert(main.get_node("Landmarks/Fountain") != null, "Fountain landmark placed in world")
	assert(main.get_node("Landmarks/MightShrine") != null, "Might shrine placed in world")
	assert(main.get_node("Landmarks/SpeedShrine") != null, "Speed shrine placed in world")
	assert(main.get_node("Landmarks/Vault") != null, "Vault landmark placed in world")
	
	var hud = main.get_node("HUD")
	assert(hud != null, "HUD exists")
	assert(hud.get_node("GameUI/TopBar/AudioButton") != null, "AudioButton exists")
	# Milestone 4: MapButton left the combat TopBar; PauseMapButton replaced it.
	assert(hud.get_node_or_null("GameUI/TopBar/MapButton") == null, "MapButton is off the combat TopBar")
	assert(hud.get_node("PausePanel/VBox/PauseMapButton") != null, "PauseMapButton exists in PausePanel")
	assert(hud.get_node("GameUI/TopBar/PauseButton") != null, "PauseButton exists in TopBar")
	assert(hud.get_node("GameUI/Minimap") != null, "Minimap radar exists in GameUI")
	assert(hud.get_node("PausePanel/VBox/PauseShopButton") != null, "PauseShopButton exists in PausePanel")
	assert(hud.get_node("WorldMapModal") != null, "WorldMapModal exists in HUD")
	main.free()
	print("✔ Full Main scene, Biomes, Landmarks, Minimap, Pause Shop, and Map Modal 6.0 verified.")
	
	print("=== ALL WORLD EXPLORATION 6.0 VERIFICATION TESTS PASSED! ===")
	get_tree().quit(0)

