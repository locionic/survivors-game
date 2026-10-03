extends "res://tests/suite_base.gd"

## Comprehensive test suite verifying Expansion 13.0:
## Game Feel & Retention Masterclass (FTUE, Sound Effects, Vignette, Boss BGM & Celestial Flash).

func _ready() -> void:
	print("=== RUNNING EXPANSION 13.0 GAME FEEL & RETENTION TEST SUITE ===")
	
	# Hermetic reset
	GameManager.is_first_run = true
	GameManager.dragon_pearls_collected = 0
	GameManager.meridian_upgrades = {"nham_mach": 0, "doc_mach": 0, "xung_mach": 0, "dan_dien": 0}
	
	# 1. Test FTUE flag in GameManager
	check(GameManager.is_first_run == true, "GameManager starts with is_first_run = true for new player")
	GameManager.mark_first_run_completed()
	check(GameManager.is_first_run == false, "GameManager marks first run completed")
	print("✔ GameManager FTUE first-run state management verified.")
	
	# 2. Test SoundManager audio registrations and dynamic BGM switching
	check(SoundManager.sounds.has("shield_break"), "SoundManager registers shield_break")
	check(SoundManager.sounds.has("boss_bgm"), "SoundManager registers boss_bgm")
	
	var initial_stream = SoundManager.bgm_player.stream
	SoundManager.play_boss_bgm()
	check(SoundManager.bgm_player.stream == SoundManager.sounds["boss_bgm"], "Boss BGM correctly loaded into bgm_player")
	
	SoundManager.restore_normal_bgm()
	check(SoundManager.bgm_player.stream != SoundManager.sounds["boss_bgm"], "Normal BGM restored from boss war loop")
	print("✔ SoundManager dynamic Boss War BGM & shield_break registration verified.")
	
	# 3. Setup Player & Test Qi Shield Break Sound / Shake
	GameManager.select_character("knight")
	var player_scene = load("res://scenes/player.tscn")
	check(player_scene != null, "Player scene exists")
	var player = player_scene.instantiate()
	add_child(player)
	player.apply_character_data()
	
	# Setup camera for shake test
	var cam = Camera2D.new()
	cam.set_script(load("res://scripts/camera.gd"))
	cam.add_to_group("camera")
	add_child(cam)
	
	player.qi_shield_current = 15.0
	player.qi_shield_max = 20.0
	check(player.qi_shield_current == 15.0, "Qi shield has 15 HP")
	
	# Deal 35 damage -> breaks shield completely accounting for armor
	player.take_damage(35.0)

	check(player.qi_shield_current == 0.0, "Qi shield shattered to 0")
	check(cam.shake_intensity > 0.0, "Camera shake applied on shield break")
	print("✔ Qi Shield break visual & audio feedback verified.")
	
	# 4. Setup HUD via Main Scene & Verify Danger Vignette, FTUE Banner, Celestial Flash
	GameManager.is_first_run = true # Re-enable to test HUD banner creation
	var main_scene = load("res://scenes/main.tscn")
	check(main_scene != null, "Main scene exists")
	var main = main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	var hud: HUD = main.get_node("HUD")
	check(hud != null, "HUD node exists in main scene")
	
	# Verify FTUE banner exists and is visible
	check(hud.ftue_banner != null, "FTUE banner instantiated")
	check(hud.ftue_banner.visible == true, "FTUE banner is visible on first run")
	
	# Trigger kills to 3 in score update -> auto-dismiss
	hud._on_score_updated(3, 10.0)
	check(GameManager.is_first_run == false, "Kills >= 3 marked first run completed")
	print("✔ HUD FTUE Onboarding Banner presentation & auto-dismissal verified.")
	
	# Danger Vignette verification
	check(hud.danger_vignette != null, "Danger vignette ColorRect initialized")
	hud._on_player_health_changed(80.0, 100.0)
	check(hud.danger_vignette.visible == false, "Danger vignette hidden when HP is 80%")
	
	hud._on_player_health_changed(20.0, 100.0)
	check(hud.danger_vignette.visible == true, "Danger vignette active when HP <= 25%")
	
	hud._on_player_died()
	check(hud.danger_vignette.visible == false, "Danger vignette dismissed on player death")
	print("✔ Low-HP (<25%) Danger Vignette activation & death dismissal verified.")
	
	# Celestial Flash verification
	check(hud.celestial_flash != null, "Celestial flash ColorRect initialized")
	check(hud.celestial_flash.visible == false, "Celestial flash initially hidden")
	hud._on_dragon_pearl_collected(7, 7)
	check(hud.celestial_flash.visible == true, "Celestial flash triggered on 7th dragon pearl collection")
	print("✔ 7th Dragon Pearl Celestial Flash visual trigger verified.")
	
	# Boss Bar BGM integration verification
	var mock_boss = Node2D.new()
	var boss_script = GDScript.new()
	boss_script.source_code = "extends Node2D\nvar boss_name: String = 'Minotaur King'\nvar max_health: float = 500.0\nvar current_health: float = 500.0\nsignal boss_health_changed(cur: float, max_val: float)\nsignal boss_defeated()\n"
	boss_script.reload()
	mock_boss.set_script(boss_script)
	add_child(mock_boss)
	
	hud.attach_boss_bar(mock_boss)
	check(SoundManager.bgm_player.stream == SoundManager.sounds["boss_bgm"], "Boss BGM active during boss fight")
	
	mock_boss.emit_signal("boss_defeated")
	check(SoundManager.bgm_player.stream != SoundManager.sounds["boss_bgm"], "Normal BGM restored upon boss defeat")
	print("✔ Boss Bar dynamic combat BGM trigger and defeat restoration verified.")
	
	# Blood Moon BGM integration verification
	hud._on_blood_moon_started(30.0)
	check(SoundManager.bgm_player.stream == SoundManager.sounds["boss_bgm"], "Boss BGM active during Blood Moon")
	hud._on_blood_moon_ended()
	check(SoundManager.bgm_player.stream != SoundManager.sounds["boss_bgm"], "Normal BGM restored when Blood Moon ends")
	print("✔ Blood Moon dynamic combat BGM trigger and conclusion restoration verified.")
	
	# Cleanup
	mock_boss.queue_free()
	main.queue_free()
	player.queue_free()
	
	if _failures.is_empty():
		print("=== ALL EXPANSION 13.0 TESTS PASSED CLEANLY! ===")
	get_tree().quit(_exit_code())
