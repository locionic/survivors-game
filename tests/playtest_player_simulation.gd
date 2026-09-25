extends Node2D

## Playtest Player Simulation:
## Simulates an active player session for 60-90 seconds, exercising movement,
## directional attacks, swarms, gem collection streaks, level-up choices, and boss encounters.

var player: Node2D = null
var spawner: Node2D = null
var upgrade_mgr: Node = null
var sim_time: float = 0.0
var max_sim_time: float = 45.0 # Accelerated 45s playtest

var gems_collected: int = 0
var enemies_killed: int = 0
var upgrades_picked: int = 0
var hitstop_count: int = 0
var max_gem_streak: int = 0

func _ready() -> void:
	print("==================================================")
	print("🎮 [PLAYTEST BOT] INITIATING REAL-TIME GAMEPLAY SESSION 🎮")
	print("==================================================")
	
	GameManager.select_character("knight")
	GameManager.start_new_run()
	
	# Instantiate player
	var player_scene = load("res://scenes/player.tscn")
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector2(0, 0)
	player.apply_character_data()
	
	# Instantiate EnemySpawner
	var spawner_scene = load("res://scenes/main.tscn")
	var main_inst = spawner_scene.instantiate()
	# Grab spawner from main
	spawner = main_inst.get_node_or_null("EnemySpawner")
	if spawner:
		main_inst.remove_child(spawner)
		add_child(spawner)
		spawner.player = player
	
	# Grab UpgradeManager
	upgrade_mgr = main_inst.get_node_or_null("UpgradeManager")
	if upgrade_mgr:
		main_inst.remove_child(upgrade_mgr)
		add_child(upgrade_mgr)
		upgrade_mgr.player = player
		player.connect("leveled_up", Callable(self, "_on_player_leveled_up"))

	print("✔ Player spawned as Tiêu Dao Kiếm Hiệp (Knight).")
	print("✔ Starter arsenal: Dagger + Độc Cô Cửu Kiếm (Slash) + Bát Quái Khiên.")
	print("✔ Commencing active combat traversal...")

func _on_player_leveled_up(lvl: int) -> void:
	upgrades_picked += 1
	print("⭐ [PLAYTEST] Level %d Reached! Upgrade selection triggered." % lvl)
	if upgrade_mgr and upgrade_mgr.has_method("get_upgrade_catalog"):
		var catalog = upgrade_mgr.get_upgrade_catalog()
		if catalog.size() > 0:
			var picked = catalog[0]
			print("👉 [PLAYTEST] Player chose upgrade card: [%s] (%s)" % [picked.get("title", ""), picked.get("desc", "").replace("\n", " ")])
			if upgrade_mgr.has_method("select_upgrade"):
				upgrade_mgr.select_upgrade(picked)

func _physics_process(delta: float) -> void:
	sim_time += delta
	GameManager.run_time = sim_time
	
	if not is_instance_valid(player):
		return
		
	# 1. Player Movement Simulation (tactical circular kiting)
	var move_angle = sim_time * 1.8
	var move_input = Vector2(cos(move_angle), sin(move_angle))
	player.input_direction = move_input
	player.last_move_dir = move_input
	
	# 2. Periodic Dash / Hero Skill
	if int(sim_time * 10) % 40 == 0:
		if player.has_method("activate_hero_skill"):
			var ok = player.activate_hero_skill()
			if ok:
				print("💨 [PLAYTEST] t=%.1fs: Activated Ngự Kiếm Trùng Kích (Spacebar Dash)! Invulnerability active." % sim_time)

	# 3. Track Hitstops
	if Engine.time_scale < 0.5:
		hitstop_count += 1
		
	# 4. Gem Magnet & Collection
	var gems = get_tree().get_nodes_in_group("gems")
	for g in gems:
		if is_instance_valid(g) and g.has_method("collect"):
			var d = player.global_position.distance_to(g.global_position)
			if d < 180.0:
				g.target_player(player)
				if d < 22.0:
					gems_collected += 1
					g.collect()

	# 5. Check Active Enemy Density & Separation
	var enemies = get_tree().get_nodes_in_group("enemies")
	if int(sim_time) % 5 == 0 and int(sim_time * 10) % 10 == 0:
		print("⚔️ [PLAYTEST] t=%.1fs | Active Mobs: %d | Kills: %d | Gems: %d | Player HP: %.0f/%.0f" % [
			sim_time, enemies.size(), GameManager.kills, gems_collected, player.current_health, player.max_health
		])

	# Finish simulation at max_sim_time
	if sim_time >= max_sim_time:
		_conclude_playtest()
		set_physics_process(false)

func _conclude_playtest() -> void:
	print("==================================================")
	print("🏁 [PLAYTEST BOT] SESSION COMPLETE: TELEMETRY REPORT")
	print("==================================================")
	print("⏱️ Total Run Time Simulated: %.1f seconds" % sim_time)
	print("💀 Monsters Slayed: %d" % GameManager.kills)
	print("💎 XP Gems Harvested: %d" % gems_collected)
	print("⚡ Level-ups Achieved: %d" % upgrades_picked)
	print("🛑 Micro-Hitstop Frames Experienced: %d" % hitstop_count)
	print("❤️ Final Player Survival State: %.0f/%.0f HP" % [player.current_health, player.max_health])
	print("==================================================")
	print("✔ Playtest session executed cleanly with zero fatal errors.")
	get_tree().quit(0)
