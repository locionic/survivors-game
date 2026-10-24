extends Node

func _ready() -> void:
	if GameManager:
		GameManager.select_stage("zombie_city")
	
	var char_select_scene = load("res://scenes/character_select_ui.tscn")
	var char_select = char_select_scene.instantiate()
	add_child(char_select)
	char_select.open_ui()
	char_select._on_stage_selected("zombie_city")
	
	await get_tree().create_timer(0.6).timeout
	
	var img = get_viewport().get_texture().get_image()
	var out_path = "/home/runner/.gemini/antigravity-cli/brain/312e7ef8-b4eb-4a7e-883f-742f00331c53/zombie_char_select_preview.png"
	img.save_png(out_path)
	print("SAVED_CHAR_SELECT_SCREENSHOT: " + out_path)
	get_tree().quit(0)
