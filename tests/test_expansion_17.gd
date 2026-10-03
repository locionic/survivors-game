extends "res://tests/suite_base.gd"

## Comprehensive test suite verifying Expansion 17.0:
## Visual Overhaul, Atmospheric Polish & Cinematic Main Menu (Đại Tu Thị Giác Toàn Diện).

func _ready() -> void:
	print("=== RUNNING EXPANSION 17.0 VISUAL OVERHAUL & TITLE SCREEN TEST SUITE ===")
	
	# 1. Test FloatingText Outlines & Pop Scale Bounce
	check(FloatingText != null, "FloatingText singleton exists")
	FloatingText.spawn(Vector2(100, 100), "128", Color(1.0, 0.9, 0.2))
	check(FloatingText.label_pool.size() > 0, "FloatingText pool populated")
	var sample_lbl = FloatingText.label_pool[0]
	check(sample_lbl.has_theme_constant_override("outline_size"), "FloatingText has outline size override")
	check(sample_lbl.get_theme_constant("outline_size") == 4, "FloatingText outline size is 4px for high contrast")
	check(sample_lbl.has_theme_color_override("font_outline_color"), "FloatingText has font outline color override")
	print("✔ Floating text high-contrast outlines and scale bounce verified.")
	
	# 2. Test Player Soft Drop Shadows & Visual Feedback
	var player_scene = load("res://scenes/player.tscn")
	check(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	check(player.has_method("_draw"), "Player implements custom _draw() for drop shadow")
	player.queue_free()
	print("✔ Player drop shadow implementation verified.")
	
	# 3. Test Enemy Drop Shadow, White Hit-Flash & Kinetic Recoil
	var enemy_scene = load("res://scenes/enemy.tscn")
	check(enemy_scene != null, "Enemy scene exists")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	check(enemy.has_method("_draw"), "Enemy implements custom _draw() for drop shadow")
	check(enemy.has_method("spawn_death_particles"), "Enemy implements custom soul flame death particles")
	
	# Test hit flash & squash recoil
	var base_scale = enemy.sprite.scale if enemy.sprite else Vector2.ONE
	enemy.take_damage(25.0, Vector2(50, 50))
	check(enemy.modulate.r >= 3.0, "Enemy flashes pure white (modulate > 3.0) on hit")
	if enemy.sprite:
		check(enemy.sprite.scale.x > base_scale.x, "Enemy sprite executes punchy squash-and-stretch recoil on hit")
	enemy.queue_free()
	print("✔ Enemy drop shadow, pure white hit-flash, and kinetic recoil verified.")
	
	# 4. Test Companion Drop Shadows
	var companion_scene = load("res://scenes/companion.tscn")
	if companion_scene:
		var comp = companion_scene.instantiate()
		add_child(comp)
		check(comp.has_method("_draw"), "Companion implements custom _draw() for drop shadow")
		comp.queue_free()
		print("✔ Companion soft drop shadow verified.")
		
	# 5. Test Gem & Coin Drop Shadows & Kinetic Loot Pop Physics
	var gem_scene = load("res://scenes/gem.tscn")
	check(gem_scene != null, "Gem scene exists")
	var gem = gem_scene.instantiate()
	add_child(gem)
	# Milestone 3b: the per-gem drop shadow is gone on purpose. A swarm used to
	# leave 150+ gems on the floor, and every one of them was another draw item
	# every frame for a shadow the magnet drags across the ground anyway.
	check(not gem.has_method("_draw"), "Gem no longer draws a per-node drop shadow")
	check("toss_vel" in gem and "toss_timer" in gem, "Gem has kinetic loot pop toss physics")
	check(gem.toss_vel != Vector2.ZERO or gem.toss_timer > 0.0, "Gem applies toss velocity on spawn")
	gem.queue_free()
	
	var coin_scene = load("res://scenes/coin.tscn")
	check(coin_scene != null, "Coin scene exists")
	var coin = coin_scene.instantiate()
	add_child(coin)
	check(coin.has_method("_draw"), "Coin implements custom _draw() for drop shadow")
	check("toss_vel" in coin and "toss_timer" in coin, "Coin has kinetic loot pop toss physics")
	check(coin.toss_vel != Vector2.ZERO or coin.toss_timer > 0.0, "Coin applies toss velocity on spawn")
	coin.queue_free()
	print("✔ Gems and Coins drop shadows and kinetic loot pop physics verified.")
	
	# 6. Test Main Scene Integration: Cinematic Vignette & Ambient Weather Particles
	var main_scene = load("res://scenes/main.tscn")
	check(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node_or_null("HUD")
	check(hud != null, "HUD exists under main")
	check(hud.cinematic_vignette != null, "HUD creates CinematicVignette overlay")
	check(hud.cinematic_vignette.texture is GradientTexture2D, "CinematicVignette uses GradientTexture2D radial mask")
	check(hud.ambient_weather != null, "HUD creates AmbientWeather CPUParticles2D")
	
	# Test weather adapting to stage
	GameManager.select_stage("mount_hua")
	hud._update_ambient_weather()
	check(hud.ambient_weather.amount >= 60, "Mount Hua stage features dense mountain blizzard particles")
	check(hud.ambient_weather.color.b > 0.9, "Mount Hua snowflakes have crisp cyan/white tone")
	
	GameManager.select_stage("plains")
	hud._update_ambient_weather()
	check(hud.ambient_weather.amount == 35, "Ba Lăng Huyện stage features gentle drifting wind motes")
	print("✔ Cinematic Vignette and Stage-Adaptive Ambient Weather verified.")
	
	# 7. Test Cinematic Title Screen / Main Menu Component
	var title_screen = hud.get_node_or_null("TitleScreen")
	check(title_screen != null, "TitleScreen attached under HUD")
	check(title_screen.start_button != null, "TitleScreen has primary StartButton CTA")
	check(title_screen.hero_name_label != null, "TitleScreen has HeroNameLabel")
	check(title_screen.hero_sprite != null, "TitleScreen has HeroSpritePreview")
	check(title_screen.stage_name_label != null, "TitleScreen has StageNameLabel")
	check(title_screen.gold_label != null, "TitleScreen has GoldLabel")
	
	# Test Hero Showcase updates on hero change
	GameManager.select_character("pyro")
	title_screen.refresh_all()
	check("Ignis" in title_screen.hero_name_label.text, "TitleScreen hero showcase updates to Ignis")
	
	# Test Stage Badge updates on stage change
	GameManager.select_stage("mount_hua")
	title_screen.refresh_all()
	check("Hoa Sơn" in title_screen.stage_name_label.text, "TitleScreen stage badge updates to Mount Hua")
	
	# Test TitleScreen Open and Close Lifecycles
	title_screen.open_screen()
	check(title_screen.visible == true, "TitleScreen open_screen() makes it visible")
	
	# Test Start Run from Title Screen
	title_screen.start_run()
	check(title_screen.is_starting == true, "TitleScreen transitions to starting run state")
	
	# Test Return to Title Screen from Pause or GameOver
	hud.return_to_title_screen()
	check(title_screen.visible == true, "return_to_title_screen() restores title screen visibility")
	check(GameManager.is_run_active == false, "Run is inactive while on title screen")
	check(hud.pause_panel.visible == false, "Pause panel hidden on return to title")
	check(hud.game_over_panel.visible == false, "Game Over panel hidden on return to title")
	print("✔ Cinematic Title Screen, Hero Showcase, Stage Badge, and Return flow verified.")
	
	# 8. Test Navigation & Return Buttons
	check(hud.pause_title_button != null, "PauseTitleButton exists in PausePanel")
	check(hud.game_over_title_button != null, "GameOverTitleButton exists in GameOverPanel")
	
	if _failures.is_empty():
		print("=== ALL EXPANSION 17.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())
