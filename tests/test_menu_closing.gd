extends Node

## Integration test suite verifying menu opening, closing, pause synchronization, and nested transitions.

func _ready() -> void:
	print("=== RUNNING MENU CLOSING & MODAL SYNCHRONIZATION TEST SUITE ===")
	
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene loads")
	var main = main_scene.instantiate()
	add_child(main)
	
	var hud: HUD = main.get_node("HUD")
	assert(hud != null, "HUD exists in main scene")
	
	# Initial state check
	assert(get_tree().paused == false, "Initial state: game is not paused")
	assert(hud.pause_panel.visible == false, "Pause panel starts hidden")
	assert(hud.char_select_modal.visible == false, "Character select starts hidden")
	assert(hud.world_map_modal.visible == false, "World map starts hidden")
	assert(hud.shop_panel.visible == false, "Shop panel starts hidden")
	
	# --- 1. DIRECT PAUSE OPEN / CLOSE ---
	hud.open_pause_menu()
	assert(hud.pause_panel.visible == true, "Pause menu opens")
	assert(get_tree().paused == true, "Game is paused when pause menu open")
	
	hud.close_pause_menu()
	assert(hud.pause_panel.visible == false, "Pause menu closes via close_pause_menu()")
	assert(get_tree().paused == false, "Game is unpaused after close_pause_menu()")
	
	hud.toggle_pause()
	assert(hud.pause_panel.visible == true, "toggle_pause() opens pause panel")
	assert(get_tree().paused == true, "Game is paused")
	
	hud.toggle_pause()
	assert(hud.pause_panel.visible == false, "toggle_pause() closes pause panel")
	assert(get_tree().paused == false, "Game is unpaused")
	
	# Resume button and Header Close button
	hud.open_pause_menu()
	hud.resume_button.emit_signal("pressed")
	assert(hud.pause_panel.visible == false, "Resume button closes pause panel")
	assert(get_tree().paused == false, "Game unpaused after Resume button pressed")
	
	hud.open_pause_menu()
	if hud.pause_close_header_button:
		hud.pause_close_header_button.emit_signal("pressed")
		assert(hud.pause_panel.visible == false, "Header ✖ button closes pause panel")
		assert(get_tree().paused == false, "Game unpaused after Header ✖ button pressed")
	print("✔ Direct Pause Menu open/close/toggle verified.")
	
	# --- 2. HERO SELECT FROM PAUSE MENU (THE REPORTED BUG SCENARIO) ---
	hud.open_pause_menu()
	assert(hud.pause_panel.visible == true, "In pause menu")
	assert(get_tree().paused == true, "Game is paused")
	
	# Open hero select from pause
	hud.open_character_select("pause")
	assert(hud.pause_panel.visible == false, "Pause panel hidden while hero select open")
	assert(hud.char_select_modal.visible == true, "Hero select modal is open")
	assert(get_tree().paused == true, "Game remains paused in hero select")
	
	# Close hero select
	hud.char_select_modal.close_ui()
	assert(hud.char_select_modal.visible == false, "Hero select closed")
	assert(hud.pause_panel.visible == true, "Pause panel restored after closing hero select")
	assert(get_tree().paused == true, "Game is STILL paused upon returning to pause panel")
	
	# Crucial: Player clicks Resume
	hud.resume_button.emit_signal("pressed")
	assert(hud.pause_panel.visible == false, "Pause panel successfully closes on Resume button!")
	assert(get_tree().paused == false, "Game successfully unpauses after returning from Hero Select!")
	print("✔ Hero Select from Pause Menu bug fix verified (no stuck pause menu).")
	
	# --- 3. SHOP FROM PAUSE MENU ---
	hud.open_pause_menu()
	hud._open_shop(true)
	assert(hud.pause_panel.visible == false, "Pause panel hidden while shop open")
	assert(hud.shop_panel.visible == true, "Shop panel is open")
	assert(get_tree().paused == true, "Game remains paused in shop")
	
	# Close shop via close button
	hud.close_shop_button.emit_signal("pressed")
	assert(hud.shop_panel.visible == false, "Shop panel closed")
	assert(hud.pause_panel.visible == true, "Pause panel restored after closing shop")
	assert(get_tree().paused == true, "Game remains paused")
	
	# Close pause menu via Resume
	hud.close_pause_menu()
	assert(hud.pause_panel.visible == false, "Pause panel closed")
	assert(get_tree().paused == false, "Game unpaused")
	print("✔ Blacksmith Shop from Pause Menu transitions verified.")
	
	# --- 4. TOPBAR HERO SELECT & TOPBAR WORLD MAP ---
	# Hero select from topbar
	hud.open_character_select("topbar")
	assert(hud.char_select_modal.visible == true, "Hero select opens from topbar")
	assert(get_tree().paused == true, "Game pauses while hero select open")
	hud.char_select_modal.close_ui()
	assert(hud.char_select_modal.visible == false, "Hero select closes")
	assert(hud.pause_panel.visible == false, "Pause panel is not shown for topbar source")
	assert(get_tree().paused == false, "Game unpauses cleanly after topbar hero select")
	
	# World map from topbar
	hud.open_world_map()
	assert(hud.world_map_modal.visible == true, "World map opens")
	assert(get_tree().paused == true, "Game pauses while world map open")
	hud.world_map_modal.close_map()
	assert(hud.world_map_modal.visible == false, "World map closes")
	assert(hud.pause_panel.visible == false, "Pause panel not shown")
	assert(get_tree().paused == false, "Game unpauses cleanly after world map")
	print("✔ Topbar Hero Select and World Map transitions verified.")
	
	# --- 5. HIERARCHICAL INPUT (ESCAPE KEY) ---
	# Escape when in World Map
	hud.open_world_map()
	var esc_event = InputEventKey.new()
	esc_event.pressed = true
	esc_event.keycode = KEY_ESCAPE
	hud._unhandled_input(esc_event)
	assert(hud.world_map_modal.visible == false, "Escape closes World Map")
	assert(get_tree().paused == false, "Game unpaused after Escape closed World Map")
	
	# Escape when in Hero Select
	hud.open_character_select("topbar")
	hud._unhandled_input(esc_event)
	assert(hud.char_select_modal.visible == false, "Escape closes Hero Select")
	assert(get_tree().paused == false, "Game unpaused after Escape closed Hero Select")
	
	# Escape when in Shop (from pause)
	hud.open_pause_menu()
	hud._open_shop(true)
	hud._unhandled_input(esc_event)
	assert(hud.shop_panel.visible == false, "Escape closes Shop")
	assert(hud.pause_panel.visible == true, "Returned to Pause panel")
	hud._unhandled_input(esc_event)
	assert(hud.pause_panel.visible == false, "Second Escape closes Pause panel")
	assert(get_tree().paused == false, "Game unpaused after closing Pause panel")
	print("✔ Hierarchical Escape key modal closing verified.")
	
	# --- 6. SHOP HEADER BUTTON & BACKDROP CLICK CLOSING ---
	hud._open_shop(false)
	assert(hud.shop_panel.visible == true, "Shop panel opens")
	assert(hud.shop_backdrop != null and hud.shop_backdrop.visible == true, "Shop backdrop visible")
	# Test Header Close Button ✖
	assert(hud.shop_close_header_button != null, "Shop close header button exists")
	hud.shop_close_header_button.emit_signal("pressed")
	assert(hud.shop_panel.visible == false, "Header ✖ button closes Shop")
	assert(hud.shop_backdrop.visible == false, "Shop backdrop hidden on close")
	
	# Test Backdrop Click to close
	hud._open_shop(false)
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	hud.shop_backdrop.emit_signal("gui_input", click_event)
	assert(hud.shop_panel.visible == false, "Clicking shop backdrop closes shop")
	assert(hud.shop_backdrop.visible == false, "Shop backdrop hidden")
	print("✔ Shop Header Close Button and Backdrop Click closing verified.")
	
	# --- 7. ALTAR, HERMIT, SHENRON & CODEX MODAL HARDENING ---
	# AltarModal backdrop click & ESC
	if hud.altar_modal:
		hud.altar_modal.open_ui()
		assert(hud.altar_modal.visible == true, "Altar modal opens")
		if hud.altar_modal.backdrop:
			hud.altar_modal.backdrop.emit_signal("gui_input", click_event)
			assert(hud.altar_modal.visible == false, "Altar modal closes on backdrop click")
		hud.altar_modal.open_ui()
		hud._unhandled_input(esc_event)
		assert(hud.altar_modal.visible == false, "Altar modal closes on ESC")
		print("✔ AltarModal backdrop click and ESC closing verified.")
		
	# HermitShopModal backdrop click & ESC
	if hud.hermit_modal:
		hud.hermit_modal.open_ui()
		assert(hud.hermit_modal.visible == true, "Hermit shop opens")
		if hud.hermit_modal.backdrop:
			hud.hermit_modal.backdrop.emit_signal("gui_input", click_event)
			assert(hud.hermit_modal.visible == false, "Hermit modal closes on backdrop click")
		hud.hermit_modal.open_ui()
		hud._unhandled_input(esc_event)
		assert(hud.hermit_modal.visible == false, "Hermit modal closes on ESC")
		print("✔ HermitShopModal backdrop click and ESC closing verified.")
		
	# ShenronWishModal ESC and dismiss button
	hud._open_shenron_modal()
	assert(hud.shenron_modal.visible == true, "Shenron modal opens")
	hud._unhandled_input(esc_event)
	assert(hud.shenron_modal.visible == false, "Shenron modal closes on ESC")
	print("✔ ShenronWishModal ESC closing verified.")

	# Cleanup
	main.free()
	print("=== ALL MENU CLOSING & MODAL TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)
