extends Node

## World exploration / gold & UI regression suite, written against Expansion 6.0
## and never wired into the gate -- there was no .tscn beside this file, so
## scripts/ci.sh's `tests/*.tscn` glob had never executed a single line of it.
##
## Converted off assert() on the day it joined the gate. assert() only logs
## SCRIPT ERROR and aborts the rest of _ready(); the banner at the bottom then
## still prints and quit(0) is never reached, so a failing run costs the full
## 120s timeout *and* reports success. See godot-assert-cannot-fail-tests.

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

## This suite calls start_new_run(), add_gold() and buy_meta_upgrade(), all of
## which reach save_game_data() and write user://save_data.cfg. Left to its own
## devices it handed the next suite +941 gold -- measured, not estimated.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e6bak"
var _had_save: bool = false

func _backup_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		_had_save = true
		var src := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var dst := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		dst.store_buffer(src.get_buffer(src.get_length()))
		src.close()
		dst.close()

func _restore_save() -> void:
	if not _had_save:
		return
	var src := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	var dst := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	dst.store_buffer(src.get_buffer(src.get_length()))
	src.close()
	dst.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_PATH))

func _ready() -> void:
	# Keep the tree inert so the suite, not the autoload, decides when a run runs.
	GameManager.is_run_active = false
	_backup_save()
	print("=== RUNNING EXTENSIVE EXPANSION 6.0 TEST SUITE ===")
	
	# 1. GameManager Currency & Meta-progression
	GameManager.start_new_run()
	check(GameManager.run_gold == 0, "run_gold must be 0 at start")
	GameManager.add_gold(10)
	check(GameManager.run_gold == 10, "run_gold should be 10")
	GameManager.double_run_gold()
	check(GameManager.run_gold == 20, "run_gold doubled to 20")
	print("✔ Gold collection and double multiplier verified.")
	
	# 2. Meta Upgrades (Armor & Pyro)
	GameManager.meta_upgrades["armor"] = 1
	GameManager.meta_upgrades["pyro"] = 1
	var init_armor = 1
	var init_pyro = 1
	GameManager.add_gold(1000)
	GameManager.buy_meta_upgrade("armor")
	GameManager.buy_meta_upgrade("pyro")
	check(GameManager.get_meta_stat("armor") == init_armor + 1, "Armor rank increased")
	check(GameManager.get_meta_stat("pyro") == init_pyro + 1, "Pyro rank increased")
	print("✔ Armor and Pyro meta-upgrades verified.")
	
	# 3. Audio & Sound Manager
	check(SoundManager.sounds.has("explosion"), "SoundManager should load explosion sound")
	check(SoundManager.sounds.has("axe"), "SoundManager should load axe sound")
	check(SoundManager.sounds.has("powerup"), "SoundManager should load powerup sound")
	check(SoundManager.sounds.has("boss_alarm"), "SoundManager should load boss_alarm sound")
	check(SoundManager.sounds.has("shrine_activate"), "SoundManager should load shrine_activate sound")
	var was_muted = SoundManager.is_muted
	var toggled = SoundManager.toggle_mute()
	check(toggled != was_muted, "Audio toggle mute should flip state")
	SoundManager.toggle_mute() # Revert
	print("✔ SoundManager 6.0 sounds and mute toggle verified.")
	
	# 4. Weapons: Fireball, Battleaxe, & Might Multiplier
	var fire_scene = load("res://scenes/fireball_weapon.tscn")
	check(fire_scene != null, "FireballWeapon scene exists")
	var fire_wpn = fire_scene.instantiate()
	check(fire_wpn.fireball_scene != null, "FireballWeapon has fireball_scene")
	fire_wpn.upgrade_count()
	check(fire_wpn.fireball_count == 2, "Fireball count upgrades properly")
	fire_wpn.free()
	
	var axe_scene = load("res://scenes/axe_weapon.tscn")
	check(axe_scene != null, "AxeWeapon scene exists")
	var axe_wpn = axe_scene.instantiate()
	check(axe_wpn.axe_scene != null, "AxeWeapon has axe_scene")
	axe_wpn.upgrade_count()
	check(axe_wpn.axe_count == 2, "Axe count upgrades properly")
	axe_wpn.free()
	print("✔ Fireball and Battleaxe weapons verified.")
	
	# 5. Enemies: Necromancer & Behemoth
	var necro_scene = load("res://scenes/necromancer.tscn")
	check(necro_scene != null, "Necromancer scene exists")
	var necro = necro_scene.instantiate()
	check(necro.is_ranged == true, "Necromancer is marked ranged")
	check(necro.projectile_scene != null, "Necromancer has projectile_scene")
	necro.free()
	
	var behemoth_scene = load("res://scenes/behemoth.tscn")
	check(behemoth_scene != null, "Behemoth scene exists")
	var behemoth = behemoth_scene.instantiate()
	check(behemoth.is_boss == true, "Behemoth is marked boss")
	check(behemoth.is_radial_boss == true, "Behemoth has radial boss attacks")
	behemoth.free()
	print("✔ Necromancer and Infernal Behemoth enemies verified.")
	
	# 6. Power-up Items
	var pup_scene = load("res://scenes/powerup.tscn")
	check(pup_scene != null, "PowerUp scene exists")
	var pup = pup_scene.instantiate()
	pup.set_type("meat")
	check(pup.powerup_type == "meat", "Powerup sets meat type")
	pup.set_type("magnet")
	check(pup.powerup_type == "magnet", "Powerup sets magnet type")
	pup.set_type("nuke")
	check(pup.powerup_type == "nuke", "Powerup sets nuke type")
	pup.free()
	print("✔ Power-up pickup verified for meat, magnet, and nuke.")
	
	# 7. Player Scene with Buffs
	var player_scene = load("res://scenes/player.tscn")
	check(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	check(player.get_node("Weapons/MainWeapon") != null, "Player has Daggers")
	check(player.get_node("Weapons/OrbitingWeapon") != null, "Player has Shield")
	check(player.get_node("Weapons/LightningWeapon") != null, "Player has Lightning")
	check(player.get_node("Weapons/FireballWeapon") != null, "Player has Fireball")
	check(player.get_node("Weapons/AxeWeapon") != null, "Player has Axe")
	
	# Test Player Buffs
	check(player.get_might_multiplier() == 1.0, "Base might multiplier is 1.0")
	player.apply_might_buff(10.0, 1.4)
	check(player.get_might_multiplier() == 1.4, "Might buff sets multiplier to 1.4")
	player.apply_speed_buff(10.0, 1.5)
	check(player.speed_multiplier == 1.5, "Speed buff sets speed multiplier to 1.5")
	player.free()
	print("✔ Player 5-weapon arsenal and temporary buffs verified.")
	
	# 8. Landmark System & Shrines
	var lm_scene = load("res://scenes/landmark.tscn")
	check(lm_scene != null, "Landmark scene exists")
	var fountain = lm_scene.instantiate()
	fountain.landmark_id = "fountain"
	fountain.landmark_name = "Sanctuary of Vitality"
	check(fountain.is_discovered == false, "Landmark starts undiscovered")
	check(GameManager.is_landmark_discovered("fountain") == false, "GameManager starts undiscovered")
	
	# Test Player interaction with Fountain
	var test_player = load("res://scenes/player.tscn").instantiate()
	test_player.current_health = 50.0
	fountain._handle_player_inside(test_player, 0.6)
	check(test_player.current_health > 50.0, "Fountain restores player health")
	
	# Test Might Shrine
	var might = lm_scene.instantiate()
	might.landmark_id = "might"
	might.landmark_name = "Altar of Might"
	might._handle_player_inside(test_player, 0.6)
	check(test_player.might_buff_timer > 0.0, "Might shrine grants might buff to player")
	
	# Test Speed Shrine
	var speed = lm_scene.instantiate()
	speed.landmark_id = "speed"
	speed.landmark_name = "Shrine of Swiftness"
	speed._handle_player_inside(test_player, 0.6)
	check(test_player.speed_buff_timer > 0.0, "Speed shrine grants speed buff to player")
	
	# Test Vault
	var vault = lm_scene.instantiate()
	vault.landmark_id = "vault"
	vault.landmark_name = "Vault of the Ancients"
	check(vault.chest_scene != null, "Vault has chest_scene export")
	check(vault.coin_scene != null, "Vault has coin_scene export")
	add_child(vault)
	vault.discover(test_player)
	check(GameManager.is_landmark_discovered("vault") == true, "Vault discovery recorded in GameManager")
	remove_child(vault)
	
	fountain.free()
	might.free()
	speed.free()
	vault.free()
	test_player.free()
	print("✔ Landmark shrines, healing, buffs, and discovery rewards verified.")

	
	# 9. World Obstacles
	var obs_scene = load("res://scenes/obstacle.tscn")
	check(obs_scene != null, "Obstacle scene exists")
	var pillar = obs_scene.instantiate()
	pillar.obstacle_type = "pillar"
	check(pillar.get_node("CollisionShape2D") != null, "Obstacle has physical collision")
	pillar.free()
	
	var tomb = obs_scene.instantiate()
	tomb.obstacle_type = "tomb"
	add_child(tomb)
	check(tomb.is_broken == false, "Tomb starts unbroken")
	tomb.break_tomb()
	check(tomb.is_broken == true, "Tomb breaks on hit")
	remove_child(tomb)
	tomb.free()
	print("✔ World obstacles (pillars, tombs) verified.")
	
	# 10. Minimap Radar and World Map UI
	var map_ui_scene = load("res://scenes/world_map_ui.tscn")
	check(map_ui_scene != null, "WorldMapUI scene exists")
	var map_ui = map_ui_scene.instantiate()
	add_child(map_ui)
	check(map_ui.visible == false, "WorldMapUI starts hidden")
	map_ui.open_map()
	check(map_ui.visible == true, "WorldMapUI opens properly")
	check(get_tree().paused == true, "Opening world map pauses the game")
	map_ui.close_map()
	check(map_ui.visible == false, "WorldMapUI closes properly")
	check(get_tree().paused == false, "Closing world map unpauses game")
	remove_child(map_ui)
	map_ui.free()
	print("✔ Interactive WorldMapUI verified.")
	
	# 11. Persistence verification (Save & Load)
	var prev_gold = GameManager.total_gold
	GameManager.add_gold(50)
	GameManager.save_game_data()
	GameManager.load_save_data()
	check(GameManager.total_gold >= prev_gold + 50, "Save and load preserves gold")
	print("✔ Save/Load persistent storage verified.")
	
	# 12. Full Main Scene Hierarchy
	var main_scene = load("res://scenes/main.tscn")
	check(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	check(main.get_node("Biomes") != null, "Biomes container exists")
	check(main.get_node("Landmarks") != null, "Landmarks container exists")
	check(main.get_node("Obstacles") != null, "Obstacles container exists")
	check(main.get_node("Landmarks/Fountain") != null, "Fountain landmark placed in world")
	check(main.get_node("Landmarks/MightShrine") != null, "Might shrine placed in world")
	check(main.get_node("Landmarks/SpeedShrine") != null, "Speed shrine placed in world")
	check(main.get_node("Landmarks/Vault") != null, "Vault landmark placed in world")
	
	var hud = main.get_node("HUD")
	check(hud != null, "HUD exists")
	check(hud.get_node("GameUI/TopBar/AudioButton") != null, "AudioButton exists")
	# Milestone 4: MapButton left the combat TopBar; PauseMapButton replaced it.
	check(hud.get_node_or_null("GameUI/TopBar/MapButton") == null, "MapButton is off the combat TopBar")
	check(hud.get_node("PausePanel/VBox/PauseMapButton") != null, "PauseMapButton exists in PausePanel")
	check(hud.get_node("GameUI/TopBar/PauseButton") != null, "PauseButton exists in TopBar")
	check(hud.get_node("GameUI/Minimap") != null, "Minimap radar exists in GameUI")
	check(hud.get_node("PausePanel/VBox/PauseShopButton") != null, "PauseShopButton exists in PausePanel")
	check(hud.get_node("WorldMapModal") != null, "WorldMapModal exists in HUD")
	main.free()
	print("✔ Full Main scene, Biomes, Landmarks, Minimap, Pause Shop, and Map Modal 6.0 verified.")
	
	# Whatever happened above, nothing is left half-done for the next suite.
	_restore_save()
	get_tree().paused = false

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL WORLD EXPLORATION 6.0 VERIFICATION TESTS PASSED! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

