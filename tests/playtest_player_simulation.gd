extends Node2D

## Playtest Player Simulation:
## Simulates an active player session, exercising movement, directional attacks,
## swarms, gem collection streaks, level-up choices, and boss encounters.
##
## Expansion 49.0: this suite asserted nothing. It ended on an unconditional
## "executed cleanly with zero fatal errors" and get_tree().quit(0), so the
## claim was printed whether or not it was true. That mattered more than usual
## here, because the two things it needs are fetched with `if spawner:` /
## `if upgrade_mgr:` -- rename either node in main.tscn and the bot runs its
## full 45 seconds with no enemies and no level-ups, kills nothing, and still
## reports a clean session forever after. A playtest that cannot detect the
## player never spawned is the one failure it exists to catch.

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

## select_character() and start_new_run() both reach save_game_data(), and 45
## seconds of combat pays its own gold in. The gate snapshots and restores the
## save around every suite, so this sidecar is for running the bot by hand.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.playbak"
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
	print("==================================================")
	print("🎮 [PLAYTEST BOT] INITIATING REAL-TIME GAMEPLAY SESSION 🎮")
	print("==================================================")

	_backup_save()
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

	# The whole run below is gated on these two nodes existing. Without the
	# spawner the bot fights nothing; without the UpgradeManager it never
	# levels. Both used to be guarded by a bare `if`, which turned a renamed
	# node in main.tscn into a 45-second no-op that still reported success.
	check(spawner != null,
		"main.tscn still exposes an EnemySpawner -- without one this playtest simulates nothing")
	check(upgrade_mgr != null,
		"main.tscn still exposes an UpgradeManager -- without one the bot never levels up")

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

	# The bot reaching this line is itself evidence it ran, but it is not the
	# same claim as "nothing went wrong": the checks above have already judged
	# whether there was anything to play at all.
	# Accumulated delta overshoots the window slightly, so this is a "ran the
	# full distance" check rather than a float equality one -- what it has to
	# rule out is the loop bailing out early, not a last-bit rounding.
	check(absf(sim_time - max_sim_time) < 0.5,
		"The playtest ran its full %ds window, stopped at %.2fs" % [int(max_sim_time), sim_time])
	check(GameManager.kills > 0,
		"The bot actually fought -- 45 seconds of play killed nothing, so the sim is not exercising combat")

	_restore_save()
	get_tree().paused = false

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("✔ Playtest session executed cleanly with zero fatal errors.")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)
