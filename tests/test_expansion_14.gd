extends "res://tests/suite_base.gd"

## Comprehensive test suite verifying Expansion 14.0:
## Đại Hội Võ Lâm (Martial Tournament Leaderboard, Daily Celestial Trial & Cái Bang Beggar Hero).

func _ready() -> void:
	print("=== RUNNING EXPANSION 14.0 TOURNAMENT & CÁI BANG TEST SUITE ===")

	# This suite calls submit_run() twice -- once directly, once through
	# hud._on_player_died() -- and submit_run() pays the Daily Trial reward the
	# first time a day is completed. Holding the developer's real purse for the
	# duration means the run leaves no gold behind.
	var gold_before = GameManager.total_gold

	# 1. Verify Cái Bang Hero Archetype
	check(GameManager.CHARACTERS.has("beggar"), "Cái Bang archetype registered in GameManager")
	var beggar_data = GameManager.CHARACTERS["beggar"]
	check(beggar_data["name"] == "Tiêu Lãng", "Cái Bang hero name is Tiêu Lãng")
	check(beggar_data["skill_id"] == "drunken_brew", "Cái Bang signature skill is drunken_brew")
	# Milestone 2 rebalanced Cái Bang up to +30% dodge against -20 Max HP.
	check(beggar_data["dodge_bonus"] == 0.30, "Cái Bang has +30% innate dodge chance")
	check(ResourceLoader.exists(beggar_data["texture_path"]), "Cái Bang texture exists")
	print("✔ Cái Bang (Beggar Sect) archetype definitions verified.")
	
	# 2. Setup Player with Cái Bang & Test Drunken Brew Skill + Dodge
	GameManager.select_character("beggar")
	var player_scene = load("res://scenes/player.tscn")
	check(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	
	check(player.char_dodge_bonus == 0.30, "Player inherits 30% dodge bonus")
	check(player.skill_id == "drunken_brew", "Player skill configured to drunken_brew")
	check(player.skill_cooldown_max == 7.5, "Drunken brew cooldown set to 7.5s")
	
	# Trigger Drunken Brew skill
	player.skill_cooldown_timer = 0.0
	var used = player.activate_hero_skill()
	check(used == true, "Drunken brew skill activated successfully")
	check(player.drunken_buff_timer > 5.5, "Drunken buff timer active for 6 seconds")
	check(SoundManager.sounds.has("wine_drink"), "wine_drink sound registered in SoundManager")
	check(SoundManager.sounds.has("fanfare"), "fanfare sound registered in SoundManager")
	
	# Test Dodge by rolling it, not by summing it.
	#
	# The check this replaces was `var total_dodge = player.char_dodge_bonus + 0.40`
	# against a `>= 0.55` bound -- test-local arithmetic over two values it already
	# held, on a stale 15% constant from before Milestone 2 raised Cái Bang to 30%.
	# It would still pass with the entire `randf() < total_dodge` branch deleted
	# from Player.take_damage() (player.gd:767), which is the only place the roll
	# exists. So measure the roll: n = 300 gives sd ~7.9 trials at p = 0.70, and
	# the bands below sit ~3.7 sd out on the buffed side and ~10 sd from the 0.30
	# an unbuffed beggar rolls -- far enough that neither a real run nor the three
	# gate runs can graze the edge by luck.
	player.drunken_buff_timer = 6.0
	var buffed_rate := _dodge_rate(player, 300)
	check(buffed_rate > 0.58 and buffed_rate < 0.82,
		"Drunken Brew puts the real dodge roll at ~70%% (0.30 innate + 0.40 buff), measured %.1f%% over 300 hits"
		% (buffed_rate * 100.0))
	player.drunken_buff_timer = 0.0
	var bare_rate := _dodge_rate(player, 300)
	check(bare_rate > 0.20 and bare_rate < 0.40,
		"Without the buff the roll falls back to Cái Bang's innate 30%%, measured %.1f%% over 300 hits -- if the buff stops reaching player.gd:767 these two rates swap"
		% (bare_rate * 100.0))
	print("✔ Cái Bang Say Rượu Bát Tiên skill & Dodge evasion mechanics verified.")
	
	# 3. Test LeaderboardManager Scoring & Persistence
	check(LeaderboardManager != null, "LeaderboardManager autoload exists")
	LeaderboardManager.reset_leaderboard_data()
	var default_masters = LeaderboardManager.get_top_entries()
	check(default_masters.size() >= 10, "Leaderboard has at least 10 masters populated")
	check(default_masters[0]["name"] == "Tiêu Phong", "Rank #1 is Tiêu Phong (Cái Bang Bang Chủ)")
	
	# Score calculation formula test
	# Score = run_time * 12 + kills * 28 + gold * 2 + scrolls * 2500
	var calculated_score = LeaderboardManager.calculate_score(100.0, 50, 200, 2)
	# 100*12 + 50*28 + 200*2 + 2*2500 = 1200 + 1400 + 400 + 5000 = 8000
	check(calculated_score == 8000, "Leaderboard scoring formula verified")
	
	# Set player nickname
	LeaderboardManager.set_player_nickname("Vô Kỵ")
	check(LeaderboardManager.player_nickname == "Vô Kỵ", "Player nickname set and saved")
	
	# Submit a legendary God Run (e.g. 1800s, 3000 kills, 5000 gold, 3 scrolls)
	# Score: 1800*12 + 3000*28 + 5000*2 + 3*2500 = 21600 + 84000 + 10000 + 7500 = 123,100
	var rank = LeaderboardManager.submit_run("beggar", 1800.0, 3000, 5000, ["dichcankinh", "lucmach", "thaicuc"])
	check(rank == 1, "Player achieved Rank #1 in Đại Hội Võ Lâm")
	var top_entries = LeaderboardManager.get_top_entries()
	check(top_entries[0]["name"] == "Vô Kỵ", "Player Vô Kỵ is now #1 on the Hall of Fame")
	check(top_entries[0]["is_player"] == true, "Entry correctly tagged as player")
	print("✔ LeaderboardManager ranking, scoring, and Hall of Fame submission verified.")
	
	# 4. Test Daily Seeded Celestial Trial
	var daily_info = LeaderboardManager.get_daily_trial_info()
	check(daily_info.has("title"), "Daily trial has mutator title")
	check(daily_info.has("desc"), "Daily trial has mutator description")
	check(daily_info.has("reward_gold"), "Daily trial has gold bounty reward")
	check(daily_info.has("date"), "Daily trial tracks calendar date")
	print("✔ Thử Thách Hằng Ngày (Daily Seeded Trial) mutator rotation verified.")
	
	# 5. Test Main Scene, HUD Tournament Button & LeaderboardUI Integration
	var main_scene = load("res://scenes/main.tscn")
	check(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	
	var hud = main.get_node("HUD")
	check(hud != null, "HUD exists in main scene")
	check(hud.leaderboard_modal != null, "LeaderboardModal instantiated in HUD")
	# Milestone 4: the TopBar no longer carries non-combat navigation. The pause
	# menu is the single entry point, so that is what must be wired.
	check(hud.get_node_or_null("GameUI/TopBar/LeaderboardButton") == null,
		"LeaderboardButton is off the combat TopBar")
	check(hud.pause_leaderboard_button != null, "PauseLeaderboardButton exists in PausePanel")
	check(hud.game_over_leaderboard_button != null, "GameOverLeaderboardButton exists in GameOverPanel")
	
	# Open Tournament Modal
	hud.open_leaderboard("topbar")
	check(hud.leaderboard_modal.visible == true, "Leaderboard modal opens")
	check(get_tree().paused == true, "Game pauses when tournament board is opened")
	
	# Test Tab Switching to Daily Trial
	hud.leaderboard_modal._switch_tab("daily")
	check(hud.leaderboard_modal.daily_view.visible == true, "Daily trial view visible")
	check(hud.leaderboard_modal.tournament_view.visible == false, "Tournament view hidden")
	
	# Close Tournament Modal
	hud.leaderboard_modal.close_ui()
	check(hud.leaderboard_modal.visible == false, "Leaderboard modal closes")
	check(get_tree().paused == false, "Game resumes after tournament board closed")
	
	# Test Player Death Tournament Hook
	GameManager.run_time = 600.0
	GameManager.kills = 800
	GameManager.run_gold = 1200
	hud._on_player_died()
	check(hud.game_over_panel.visible == true, "Game over panel visible")
	check("VÕ LÂM" in hud.final_stats_label.text, "Tournament rank announced on Game Over screen")
	print("✔ HUD TopBar, Pause Menu, Game Over hooks & LeaderboardUI tabs verified.")
	
	# Cleanup
	GameManager.total_gold = gold_before
	GameManager.save_game_data()
	player.queue_free()
	main.queue_free()
	
	if _failures.is_empty():
		print("=== ALL EXPANSION 14.0 TESTS PASSED CLEANLY! ===")
	get_tree().quit(_exit_code())

## Rolls Player.take_damage() n times and returns the fraction of hits that dodged,
## read off health rather than off any flag the roll sets.
##
## Three inputs are pinned per trial because all three leave `current_health`
## untouched and would otherwise be scored as a dodge:
##   * `invulnerability_timer` -- a successful dodge arms a 0.25s i-frame
##     (player.gd:768) and a landed hit a 0.35s one (player.gd:828), so every
##     trial after the first would return at the `is_invulnerable` guard on
##     player.gd:762 and the measured rate would read ~0.
##   * `qi_shield_current` -- the Nhâm Mạch shield absorbs the whole hit and
##     returns before any health is lost (player.gd:793). This is one of the four
##     inputs that leak in through the save file every suite shares.
##   * `current_health` -- topped back up so one hit can never end the run, and
##     so a phoenix_feather rebirth (player.gd:811, which restores health to 40%
##     and returns) can never fire either.
##
## 10.0 damage against 100.0 health is deliberate: phoenix_feather only triggers
## when `final_damage >= current_health`, and this keeps it out of reach.
func _dodge_rate(p: Node, n: int) -> float:
	var dodged := 0
	for _i in n:
		p.invulnerability_timer = 0.0
		p.qi_shield_current = 0.0
		p.current_health = 100.0
		var before: float = p.current_health
		p.take_damage(10.0)
		if p.current_health >= before:
			dodged += 1
	return float(dodged) / float(n)
