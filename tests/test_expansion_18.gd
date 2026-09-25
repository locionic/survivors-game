extends Node

## Comprehensive test suite verifying Expansion 18.0:
## "Thiên Hạ Đệ Nhất: The 8-Minute Climax Run & Martial Synergy Matrix"

func _ready() -> void:
	print("=== RUNNING EXPANSION 18.0 CLIMAX RUN & MARTIAL SYNERGY TEST SUITE ===")
	
	# 1. Thematic Jianghu Unification & Backward Compatibility
	assert(GameManager.CHARACTERS.size() == 5, "5 Jianghu Sect Heroes exist")
	var knight = GameManager.CHARACTERS["knight"]
	var pyro = GameManager.CHARACTERS["pyro"]
	var ranger = GameManager.CHARACTERS["ranger"]
	var mage = GameManager.CHARACTERS["mage"]
	var beggar = GameManager.CHARACTERS["beggar"]
	
	assert("Sir Kaelen" in knight["name"] and "Tiêu Dao" in knight["title"], "Knight unified with Tiêu Dao sect")
	assert("Ignis" in pyro["name"] and "Minh Giáo" in pyro["title"], "Pyro unified with Minh Giáo sect")
	assert("Zephyr" in ranger["name"] and "Đường Môn" in ranger["title"], "Ranger unified with Đường Môn sect")
	assert("Morrigan" in mage["name"] and "Nga Mi" in mage["title"], "Mage unified with Nga Mi sect")
	assert("Cái Bang" in beggar["title"], "Beggar unified with Cái Bang sect")
	print("✔ Jianghu Sect unification & backward compatibility verified.")

	# 2. 3-Weapon Slot Cap
	var up_mgr = UpgradeManager.new()
	var up_panel = PanelContainer.new()
	up_panel.name = "UpgradePanel"
	var up_vbox = VBoxContainer.new()
	up_vbox.name = "VBox"
	var up_opts = HBoxContainer.new()
	up_opts.name = "OptionsContainer"
	up_vbox.add_child(up_opts)
	up_panel.add_child(up_vbox)
	up_mgr.add_child(up_panel)
	add_child(up_mgr)
	
	assert(up_mgr.MAX_WEAPONS == 3, "UpgradeManager enforces MAX_WEAPONS = 3 cap")
	
	# Start with 2 weapons
	up_mgr.weapon_levels = {"dagger": 1, "shield": 1, "lightning": 0, "fireball": 0, "axe": 0}
	assert(up_mgr.get_active_weapon_count() == 2, "Active weapon count is 2")
	var cat_2 = up_mgr.get_upgrade_catalog()
	var unlock_count_2 = 0
	for item in cat_2:
		if str(item["id"]).begins_with("unlock_"):
			unlock_count_2 += 1
	assert(unlock_count_2 > 0, "Weapon unlock cards appear when active weapons < 3")
	
	# Fill 3rd slot
	up_mgr.weapon_levels["lightning"] = 1
	assert(up_mgr.get_active_weapon_count() == 3, "Active weapon count is now 3 (CAPPED)")
	var cat_3 = up_mgr.get_upgrade_catalog()
	var unlock_count_3 = 0
	for item in cat_3:
		if str(item["id"]).begins_with("unlock_"):
			unlock_count_3 += 1
	assert(unlock_count_3 == 0, "Zero unlock cards offered when 3 weapon slots are full")
	print("✔ 3-Weapon slot cap and selective unlock restrictions verified.")

	# 3. Paired Evolutions & Wuxia Catalyst Lore
	up_mgr.weapon_levels["dagger"] = 5
	up_mgr.evolved_weapons["dagger"] = false
	var evol_cat = up_mgr.get_upgrade_catalog()
	var dagger_evol = {}
	for item in evol_cat:
		if item["id"] == "evolve_dagger":
			dagger_evol = item
			break
	assert(not dagger_evol.is_empty(), "evolve_dagger offered at Rank 5")
	assert("VÔ ẢNH THẦN CHÂM" in dagger_evol["title"], "Evolve dagger title updated to Vô Ảnh Thần Châm")
	assert("Phi Đao Lv.5" in dagger_evol["desc"], "Evolve dagger lists weapon requirement")
	assert("Thân Pháp Thần Tốc" in dagger_evol["desc"], "Evolve dagger lists paired catalyst requirement")
	
	up_mgr.queue_free()
	print("✔ Paired evolutions and martial catalyst lore verified.")

	# 4. Spawner 8-Minute Wave Timeline & Final Boss
	var spawner_script = load("res://scripts/enemy_spawner.gd")
	assert(spawner_script != null, "enemy_spawner.gd loaded")
	var spawner = EnemySpawner.new()
	add_child(spawner)
	assert(spawner.demon_emperor_scene != null, "Demon emperor scene preloaded in EnemySpawner")
	assert("swarm_3_triggered" in spawner, "Swarm 3 exists in timeline")
	assert("goblin_3_spawned" in spawner, "Goblin 3 exists in timeline")
	assert("swarm_4_triggered" in spawner, "Swarm 4 exists in timeline")
	assert("boss_3_spawned" in spawner, "Boss 3 exists in timeline")
	assert("demon_emperor_spawned" in spawner, "Demon Emperor final boss exists in timeline")
	
	var emperor = spawner.demon_emperor_scene.instantiate()
	assert(emperor.is_boss == true, "Demon Emperor has is_boss = true")
	assert(emperor.max_health >= 2000.0, "Demon Emperor has raid-tier health (>= 2000 HP)")
	assert("HẮC HUYẾT MA HOÀNG" in emperor.boss_name, "Demon Emperor carries authentic boss title")
	assert(emperor.is_radial_boss == true, "Demon Emperor casts radial dark magic waves")
	emperor.queue_free()
	spawner.queue_free()
	print("✔ 8-Minute Spawner timeline and Demon Emperor Final Boss verified.")

	# 5. Victory Condition & Ascension Modal in Main/HUD
	assert(GameManager.MAX_RUN_TIME == 480.0, "MAX_RUN_TIME is 480.0s (8 minutes)")
	var initial_gold = GameManager.total_gold
	
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "scenes/main.tscn exists")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node_or_null("HUD")
	assert(hud != null, "HUD exists under Main")
	assert(hud.victory_panel != null, "VictoryPanel node instantiated under HUD")
	assert(hud.victory_endless_button != null, "VictoryPanel has Endless Mode button")
	assert(hud.victory_title_button != null, "VictoryPanel has Return to Title button")
	assert(hud.victory_leaderboard_button != null, "VictoryPanel has Leaderboard button")
	assert(hud.victory_panel.visible == false, "VictoryPanel initially hidden")
	
	# Trigger Victory
	GameManager.is_victory_triggered = false
	GameManager.kills = 380
	GameManager.run_time = 480.0
	GameManager.trigger_victory()
	
	assert(GameManager.is_victory_triggered == true, "is_victory_triggered flag set")
	assert(GameManager.total_gold >= initial_gold + 1000, "+1,000 bonus gold awarded upon victory")
	assert(hud.victory_panel.visible == true, "VictoryPanel opened upon victory_achieved signal")
	assert("TUYỆT THẾ CAO THỦ" in hud.victory_title_label.text or "VÕ LÂM MINH CHỦ" in hud.victory_title_label.text, "Martial title awarded on VictoryPanel")
	assert("08:00" in hud.victory_stats_label.text, "Run time 08:00 displayed on VictoryPanel")
	assert("+1,000" in hud.victory_stats_label.text, "+1,000 victory bonus reflected in stats text")
	
	# Test Endless Mode continuation
	hud._on_victory_endless_pressed()
	assert(hud.victory_panel.visible == false, "VictoryPanel hidden on endless mode selection")
	assert(GameManager.is_endless_mode == true, "Endless mode state active in GameManager")
	assert(get_tree().paused == false, "Tree unpaused for endless survival")
	
	main.queue_free()
	print("✔ Victory Condition, Ascension Modal, +1000 Gold Award, and Endless Mode verified.")

	print("=== ALL EXPANSION 18.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(0)
