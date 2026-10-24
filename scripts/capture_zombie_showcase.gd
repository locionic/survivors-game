extends Node

## Captures high-res screenshots of Zombie Mode Title, Char Select, and Dossier UI

func _ready() -> void:
	if GameManager:
		GameManager.select_stage("zombie_city")
		GameManager.select_character("swat")

	# 1. Capture Title Screen
	var title_scene = load("res://scenes/title_screen.tscn").instantiate()
	add_child(title_scene)
	title_scene.open_screen()
	title_scene._refresh_stage()
	title_scene._refresh_hero()
	await get_tree().create_timer(0.5).timeout
	_save_screen("zombie_title_screen_final.png")
	title_scene.queue_free()
	await get_tree().create_timer(0.2).timeout

	# 2. Capture Character Select UI
	var char_select = load("res://scenes/character_select_ui.tscn").instantiate()
	add_child(char_select)
	char_select.open_ui()
	char_select._on_stage_selected("zombie_city")
	await get_tree().create_timer(0.5).timeout
	_save_screen("zombie_char_select_final.png")
	char_select.queue_free()
	await get_tree().create_timer(0.2).timeout

	# 3. Capture Outbreak Dossier - Survivors Tab
	var dossier = load("res://scenes/zombie_dossier_ui.tscn").instantiate()
	add_child(dossier)
	dossier.open_ui("survivors")
	await get_tree().create_timer(0.5).timeout
	_save_screen("zombie_dossier_survivors.png")

	# 4. Capture Outbreak Dossier - Monsters Tab
	dossier._switch_tab("monsters")
	await get_tree().create_timer(0.5).timeout
	_save_screen("zombie_dossier_monsters.png")

	# 5. Capture Outbreak Dossier - Airdrop Tab
	dossier._switch_tab("airdrop")
	await get_tree().create_timer(0.5).timeout
	_save_screen("zombie_dossier_airdrop.png")
	dossier.queue_free()

	print("=== All 5 showcase screenshots saved successfully! ===")
	get_tree().quit(0)

func _save_screen(filename: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var art_path = "/home/runner/.gemini/antigravity-cli/brain/312e7ef8-b4eb-4a7e-883f-742f00331c53/" + filename
		var promo_path = "assets/promo/" + filename
		img.save_png(art_path)
		img.save_png(promo_path)
		print("Saved: ", filename)
