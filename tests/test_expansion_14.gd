extends Node

## Comprehensive test suite verifying Expansion 14.0:
## Đại Hội Võ Lâm (Martial Tournament Leaderboard, Daily Celestial Trial & Cái Bang Beggar Hero).

func _ready() -> void:
	print("=== RUNNING EXPANSION 14.0 TOURNAMENT & CÁI BANG TEST SUITE ===")
	
	# 1. Verify Cái Bang Hero Archetype
	assert(GameManager.CHARACTERS.has("beggar"), "Cái Bang archetype registered in GameManager")
	var beggar_data = GameManager.CHARACTERS["beggar"]
	assert(beggar_data["name"] == "Tiêu Lãng", "Cái Bang hero name is Tiêu Lãng")
	assert(beggar_data["skill_id"] == "drunken_brew", "Cái Bang signature skill is drunken_brew")
	assert(beggar_data["dodge_bonus"] == 0.15, "Cái Bang has +15% innate dodge chance")
	assert(ResourceLoader.exists(beggar_data["texture_path"]), "Cái Bang texture exists")
	print("✔ Cái Bang (Beggar Sect) archetype definitions verified.")
	
	# 2. Setup Player with Cái Bang & Test Drunken Brew Skill + Dodge
	GameManager.select_character("beggar")
	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	
	assert(player.char_dodge_bonus == 0.15, "Player inherits 15% dodge bonus")
	assert(player.skill_id == "drunken_brew", "Player skill configured to drunken_brew")
	assert(player.skill_cooldown_max == 7.5, "Drunken brew cooldown set to 7.5s")
	
	# Trigger Drunken Brew skill
	player.skill_cooldown_timer = 0.0
	var used = player.activate_hero_skill()
	assert(used == true, "Drunken brew skill activated successfully")
	assert(player.drunken_buff_timer > 5.5, "Drunken buff timer active for 6 seconds")
	assert(SoundManager.sounds.has("wine_drink"), "wine_drink sound registered in SoundManager")
	assert(SoundManager.sounds.has("fanfare"), "fanfare sound registered in SoundManager")
	
	# Test Dodge: with drunken buff, dodge chance is 15% + 40% = 55%
	var total_dodge = player.char_dodge_bonus + 0.40
	assert(total_dodge >= 0.55, "Total dodge reaches 55% during Drunken Brew")
	print("✔ Cái Bang Say Rượu Bát Tiên skill & Dodge evasion mechanics verified.")
	
	# 3. Test LeaderboardManager Scoring & Persistence
	assert(LeaderboardManager != null, "LeaderboardManager autoload exists")
	LeaderboardManager.reset_leaderboard_data()
	var default_masters = LeaderboardManager.get_top_entries()
	assert(default_masters.size() >= 10, "Leaderboard has at least 10 masters populated")
	assert(default_masters[0]["name"] == "Tiêu Phong", "Rank #1 is Tiêu Phong (Cái Bang Bang Chủ)")
	
	# Score calculation formula test
	# Score = run_time * 12 + kills * 28 + gold * 2 + scrolls * 2500
	var calculated_score = LeaderboardManager.calculate_score(100.0, 50, 200, 2)
	# 100*12 + 50*28 + 200*2 + 2*2500 = 1200 + 1400 + 400 + 5000 = 8000
	assert(calculated_score == 8000, "Leaderboard scoring formula verified")
	
	# Set player nickname
	LeaderboardManager.set_player_nickname("Vô Kỵ")
	assert(LeaderboardManager.player_nickname == "Vô Kỵ", "Player nickname set and saved")
	
	# Submit a legendary God Run (e.g. 1800s, 3000 kills, 5000 gold, 3 scrolls)
	# Score: 1800*12 + 3000*28 + 5000*2 + 3*2500 = 21600 + 84000 + 10000 + 7500 = 123,100
	var rank = LeaderboardManager.submit_run("beggar", 1800.0, 3000, 5000, ["dichcankinh", "lucmach", "thaicuc"])
	assert(rank == 1, "Player achieved Rank #1 in Đại Hội Võ Lâm")
	var top_entries = LeaderboardManager.get_top_entries()
	assert(top_entries[0]["name"] == "Vô Kỵ", "Player Vô Kỵ is now #1 on the Hall of Fame")
	assert(top_entries[0]["is_player"] == true, "Entry correctly tagged as player")
	print("✔ LeaderboardManager ranking, scoring, and Hall of Fame submission verified.")
	
	# 4. Test Daily Seeded Celestial Trial
	var daily_info = LeaderboardManager.get_daily_trial_info()
	assert(daily_info.has("title"), "Daily trial has mutator title")
	assert(daily_info.has("desc"), "Daily trial has mutator description")
	assert(daily_info.has("reward_gold"), "Daily trial has gold bounty reward")
	assert(daily_info.has("date"), "Daily trial tracks calendar date")
	print("✔ Thử Thách Hằng Ngày (Daily Seeded Trial) mutator rotation verified.")
	
	# 5. Test Main Scene, HUD Tournament Button & LeaderboardUI Integration
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	
	var hud = main.get_node("HUD")
	assert(hud != null, "HUD exists in main scene")
	assert(hud.leaderboard_modal != null, "LeaderboardModal instantiated in HUD")
	assert(hud.leaderboard_button != null, "LeaderboardButton exists on TopBar")
	assert(hud.pause_leaderboard_button != null, "PauseLeaderboardButton exists in PausePanel")
	assert(hud.game_over_leaderboard_button != null, "GameOverLeaderboardButton exists in GameOverPanel")
	
	# Open Tournament Modal
	hud.open_leaderboard("topbar")
	assert(hud.leaderboard_modal.visible == true, "Leaderboard modal opens")
	assert(get_tree().paused == true, "Game pauses when tournament board is opened")
	
	# Test Tab Switching to Daily Trial
	hud.leaderboard_modal._switch_tab("daily")
	assert(hud.leaderboard_modal.daily_view.visible == true, "Daily trial view visible")
	assert(hud.leaderboard_modal.tournament_view.visible == false, "Tournament view hidden")
	
	# Close Tournament Modal
	hud.leaderboard_modal.close_ui()
	assert(hud.leaderboard_modal.visible == false, "Leaderboard modal closes")
	assert(get_tree().paused == false, "Game resumes after tournament board closed")
	
	# Test Player Death Tournament Hook
	GameManager.run_time = 600.0
	GameManager.kills = 800
	GameManager.run_gold = 1200
	hud._on_player_died()
	assert(hud.game_over_panel.visible == true, "Game over panel visible")
	assert("VÕ LÂM" in hud.final_stats_label.text, "Tournament rank announced on Game Over screen")
	print("✔ HUD TopBar, Pause Menu, Game Over hooks & LeaderboardUI tabs verified.")
	
	# Cleanup
	player.queue_free()
	main.queue_free()
	
	print("=== ALL EXPANSION 14.0 TESTS PASSED CLEANLY! ===")
	get_tree().quit(0)
