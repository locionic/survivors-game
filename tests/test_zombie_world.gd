extends "res://tests/suite_base.gd"

## Test Suite for Project Z-Survivor (Zombie World Outbreak Mode)

func _ready() -> void:
	print("=== RUNNING PROJECT Z-SURVIVOR TEST SUITE ===")
	GameManager.is_run_active = false
	
	_test_stage_registry()
	_test_zombie_survivor_roster()
	_test_zombie_enemies()
	_test_dossier_ui_and_flow_art()
	_test_player_skills()
	_test_zombie_sfx()
	
	if _failures.is_empty():
		print("=== ALL PROJECT Z-SURVIVOR TESTS PASSED 100% CLEANLY! ===")
	else:
		print("=== TEST FAILURES ENCOUNTERED: ", _failures.size(), " ===")

func _test_stage_registry() -> void:
	check(GameManager.STAGES.has("zombie_city"), "STAGES must have zombie_city")
	var st = GameManager.STAGES["zombie_city"]
	check(st["id"] == "zombie_city", "Stage id must be zombie_city")
	check(st.has("icon") and st["icon"] == "☣️", "Stage must have ☣️ icon")
	check(ResourceLoader.exists(st["texture_path"]), "Stage asphalt texture must exist: %s" % st["texture_path"])
	print("✔ Zombie City quarantine stage verified.")

func _test_zombie_survivor_roster() -> void:
	check(GameManager.ZOMBIE_CHARACTERS.size() == 5, "Must have exactly 5 zombie survivors")
	var expected_ids = ["swat", "medic", "pyro_z", "scout", "biker"]
	for id in expected_ids:
		check(GameManager.ZOMBIE_CHARACTERS.has(id), "Roster must include %s" % id)
		var c = GameManager.ZOMBIE_CHARACTERS[id]
		check(ResourceLoader.exists(c["texture_path"]), "Texture must exist for %s: %s" % [id, c["texture_path"]])
		check(ResourceLoader.exists(c["portrait_path"]), "Portrait art must exist for %s: %s" % [id, c["portrait_path"]])
		check(c.has("skill_id") and c["skill_id"] != "", "Skill id must be defined for %s" % id)
	print("✔ All 5 Zombie Survivor operatives & Flow Agent portraits verified.")

func _test_zombie_enemies() -> void:
	var scenes = [
		{"path": "res://scenes/zombie_walker.tscn", "hp": 26.0},
		{"path": "res://scenes/zombie_runner.tscn", "hp": 16.0},
		{"path": "res://scenes/zombie_bloater.tscn", "hp": 52.0}
	]
	for sc in scenes:
		check(ResourceLoader.exists(sc["path"]), "Scene file must exist: %s" % sc["path"])
		var res: PackedScene = load(sc["path"])
		check(res != null, "PackedScene must load: %s" % sc["path"])
		var inst = res.instantiate()
		check(inst != null, "Instance must instantiate: %s" % sc["path"])
		check(inst.is_in_group("enemies"), "Enemy must be in 'enemies' group")
		check(is_equal_approx(inst.max_health, sc["hp"]), "Max health expected %f, got %f" % [sc["hp"], inst.max_health])
		inst.free()
	print("✔ Zombie Walker, Runner, and Bloater enemies verified.")

func _test_dossier_ui_and_flow_art() -> void:
	var dossier_scene: PackedScene = load("res://scenes/zombie_dossier_ui.tscn")
	check(dossier_scene != null, "ZombieDossierUI scene must load")
	var ui: ZombieDossierUI = dossier_scene.instantiate()
	add_child(ui)
	ui.open_ui("survivors")
	check(ui.visible, "Dossier must be visible on open")
	ui._switch_tab("monsters")
	check(ui.current_tab == "monsters", "Tab must switch to monsters")
	ui._switch_tab("airdrop")
	check(ui.current_tab == "airdrop", "Tab must switch to airdrop")
	ui.close_ui()
	check(not ui.visible, "Dossier must be hidden on close")
	ui.queue_free()

	# Verify Flow Agent asset files on disk
	var flow_arts = [
		"res://assets/textures/zombie_title_bg.png",
		"res://assets/promo/swat_survivor_art.png",
		"res://assets/promo/medic_art.png",
		"res://assets/promo/pyro_art.png",
		"res://assets/promo/scout_art.png",
		"res://assets/promo/biker_art.png",
		"res://assets/promo/mutant_boss_art.png",
		"res://assets/promo/toxic_spitter_art.png",
		"res://assets/promo/airdrop_crate_art.png"
	]
	for art in flow_arts:
		check(ResourceLoader.exists(art), "Flow Agent asset must exist: %s" % art)
	print("✔ Zombie Dossier UI and all 9 Flow Agent assets verified.")

func _test_player_skills() -> void:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	check(player_scene != null, "Player scene must load")
	var p = player_scene.instantiate()
	add_child(p)

	var skills_to_test = ["swat", "medic", "pyro_z", "scout", "biker"]
	for char_id in skills_to_test:
		GameManager.selected_character = char_id
		p.apply_character_data()
		p.skill_cooldown_timer = 0.0
		var ok = p.activate_hero_skill()
		check(ok, "Skill for %s must activate" % char_id)
		check(p.skill_cooldown_timer > 0.0, "Skill cooldown must be set for %s" % char_id)
	p.queue_free()
	print("✔ All 5 survivor signature active skills verified.")

func _test_zombie_sfx() -> void:
	var expected_sfx = ["gunshot", "shotgun", "zombie_groan", "zombie_hit"]
	for sfx in expected_sfx:
		check(SoundManager.sounds.has(sfx), "SoundManager must load %s" % sfx)
	print("✔ Ballistic & Zombie audio sound effects verified.")
