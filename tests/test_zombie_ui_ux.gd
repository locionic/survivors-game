extends Node

## Test Suite for Zombie Outbreak UI/UX Polish:
## Tests Overdrive HUD indicator, Kill Streak announcements, Boss bio-warning banners,
## Tactical Arsenal badge icons, and Outbreak Dossier navigation.

var _failures: Array[String] = []

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING ZOMBIE UI/UX POLISH TEST SUITE ===")
	var orig_stage = GameManager.selected_stage if GameManager else "martial_arts"
	if GameManager:
		GameManager.is_run_active = false
		GameManager.selected_stage = "zombie_city"

	_test_tactical_arsenal_badges()
	_test_boss_warning_banner_and_audio()
	_test_kill_streak_announcer()
	_test_overdrive_hud_indicator()
	_test_dossier_ui_flow()

	if GameManager:
		GameManager.selected_stage = orig_stage

	if _failures.is_empty():
		print("PASSED: All Zombie UI/UX Polish tests passed 100% cleanly!")
	else:
		push_error("FAILED: %d assertions failed in Zombie UI/UX tests!" % _failures.size())

	get_tree().quit(0 if _failures.is_empty() else 1)

func _test_tactical_arsenal_badges() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node_or_null("HUD")
	check(hud != null, "HUD exists in main scene")
	if not hud:
		main.queue_free()
		return
		
	var levels = {"dagger": 2, "shield": 1, "lightning": 0, "fireball": 0, "axe": 0, "slash": 0}
	hud._on_arsenal_updated(levels)
	
	check(hud.dagger_badge.text.contains("🔫"), "Dagger badge displays tactical pistol 🔫 in zombie_city")
	check(hud.shield_badge.text.contains("🛡️"), "Shield badge displays riot shield 🛡️ in zombie_city")
	
	main.queue_free()
	print("✔ Tactical arsenal badge icons verified.")

func _test_boss_warning_banner_and_audio() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node_or_null("HUD")
	if not hud:
		main.queue_free()
		return
		
	var c_heard: Array[String] = []
	var cb = func(cue): c_heard.append(String(cue))
	SoundManager.sfx_played.connect(cb)
	
	hud._on_wave_event_announced("MUTANT JUGGERNAUT", true)
	check(hud.warning_banner.visible, "Warning banner is visible on boss entrance")
	check(hud.warning_banner.text.contains("MUTANT JUGGERNAUT") or hud.warning_banner.text.contains("BIO-THREAT"),
		"Warning banner carries boss alert text: %s" % hud.warning_banner.text)
	check(c_heard.has("boss_alarm"), "Boss entrance plays boss_alarm siren in zombie_city")
	
	SoundManager.sfx_played.disconnect(cb)
	main.queue_free()
	print("✔ Tactical boss biohazard banner styling and audio cue verified.")

func _test_kill_streak_announcer() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node_or_null("HUD")
	if not hud:
		main.queue_free()
		return
		
	hud.last_streak_announced = 0
	hud._on_score_updated(50, 60.0)
	check(hud.last_streak_announced == 50, "Last streak announced updated to 50")
	check(hud.warning_banner.text.contains("50 KILLS") or hud.warning_banner.text.contains("MASSACRE"),
		"Banner carries 50 kills streak: %s" % hud.warning_banner.text)
		
	hud._on_score_updated(250, 180.0)
	check(hud.last_streak_announced == 250, "Last streak announced updated to 250")
	check(hud.warning_banner.text.contains("250 KILLS") or hud.warning_banner.text.contains("REAPER"),
		"Banner carries 250 kills streak: %s" % hud.warning_banner.text)
		
	main.queue_free()
	print("✔ Zombie Outbreak kill streak announcements verified.")

func _test_overdrive_hud_indicator() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud = main.get_node_or_null("HUD")
	var player = main.get_node_or_null("Player")
	if not hud or not player:
		main.queue_free()
		return
	hud.player = player
		
	# Overdrive inactive
	player.overdrive_buff_timer = 0.0
	hud._process(0.016)
	check(hud.overdrive_label == null or not hud.overdrive_label.visible,
		"Overdrive label is hidden when buff is inactive")
		
	# Overdrive active
	player.overdrive_buff_timer = 10.5
	hud._process(0.016)
	check(hud.overdrive_label != null and hud.overdrive_label.visible,
		"Overdrive label is visible when buff is active")
	check(hud.overdrive_label.text.contains("OVERDRIVE"),
		"Overdrive label displays OVERDRIVE text: %s" % hud.overdrive_label.text)
		
	main.queue_free()
	print("✔ Adrenaline Overdrive HUD indicator verified.")

func _test_dossier_ui_flow() -> void:
	var dossier_scene = load("res://scenes/zombie_dossier_ui.tscn")
	var dossier = dossier_scene.instantiate()
	add_child(dossier)
	
	dossier.open_ui("survivors")
	check(dossier.visible, "Dossier opens visibly")
	check(dossier.current_tab == "survivors", "Initial tab is survivors")
	
	dossier._switch_tab("monsters")
	check(dossier.current_tab == "monsters", "Switched tab to monsters")
	
	dossier._switch_tab("airdrop")
	check(dossier.current_tab == "airdrop", "Switched tab to airdrop")
	
	dossier.close_ui()
	check(not dossier.visible, "Dossier closes cleanly")
	
	dossier.queue_free()
	print("✔ Outbreak Dossier navigation flow verified.")
