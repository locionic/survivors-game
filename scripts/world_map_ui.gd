class_name WorldMapUI
extends Control

## WorldMapUI: Fullscreen interactive map viewer showing biomes, landmarks, and player position.

signal closed

@onready var map_canvas: Control = find_child("MapCanvas", true, false)
@onready var stats_label: Label = find_child("StatsLabel", true, false)
@onready var landmarks_container: VBoxContainer = find_child("LandmarksList", true, false)
@onready var close_button: Button = find_child("CloseButton", true, false)
@onready var header_close_button: Button = find_child("HeaderCloseButton", true, false)
@onready var backdrop: Control = find_child("Backdrop", true, false)

var player: Node2D = null
var was_paused_before_open: bool = false
const WORLD_EXTENTS: Vector2 = Vector2(2500.0, 2200.0)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resolve_nodes()
	
	if close_button:
		close_button.pressed.connect(close_map)
	if header_close_button:
		header_close_button.pressed.connect(close_map)
	if backdrop:
		backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				close_map()
		)
	if map_canvas:
		map_canvas.draw.connect(_on_map_canvas_draw)

func _resolve_nodes() -> void:
	if not map_canvas:
		map_canvas = find_child("MapCanvas", true, false)
	if not stats_label:
		stats_label = find_child("StatsLabel", true, false)
	if not landmarks_container:
		landmarks_container = find_child("LandmarksList", true, false)
	if not close_button:
		close_button = find_child("CloseButton", true, false)
	if not header_close_button:
		header_close_button = find_child("HeaderCloseButton", true, false)
	if not backdrop:
		backdrop = find_child("Backdrop", true, false)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M):
		close_map()
		get_viewport().set_input_as_handled()

func open_map() -> void:
	_resolve_nodes()
	was_paused_before_open = get_tree().paused
	player = get_tree().get_first_node_in_group("player")
	visible = true
	get_tree().paused = true
	_refresh_landmarks_list()
	if map_canvas:
		map_canvas.queue_redraw()

func close_map() -> void:
	if not visible:
		return
	visible = false
	if not was_paused_before_open:
		get_tree().paused = false
	emit_signal("closed")

func _process(_delta: float) -> void:
	if visible and map_canvas:
		map_canvas.queue_redraw()

func _refresh_landmarks_list() -> void:
	_resolve_nodes()
	if not landmarks_container or not stats_label:
		return
		
	for child in landmarks_container.get_children():
		child.queue_free()
		
	var landmarks = [
		{"id": "fountain", "name": "Sanctuary of Vitality", "region": "North-West", "icon": "💚", "bonus": "+8 HP/sec Sacred Pool"},
		{"id": "might", "name": "Altar of Might", "region": "North-East", "icon": "⚔️", "bonus": "+40% Damage Surge"},
		{"id": "speed", "name": "Shrine of Swiftness", "region": "South-West", "icon": "💨", "bonus": "+50% Movement Speed"},
		{"id": "vault", "name": "Vault of the Ancients", "region": "South-East", "icon": "👑", "bonus": "+60 Gold & 2 Treasure Chests"}
	]
	
	var discovered_count = 0
	for lm in landmarks:
		var is_found = GameManager.is_landmark_discovered(lm["id"])
		if is_found:
			discovered_count += 1
			
		var row = PanelContainer.new()
		var row_sb = StyleBoxFlat.new()
		row_sb.bg_color = Color(0.12, 0.16, 0.24, 0.8) if is_found else Color(0.08, 0.1, 0.14, 0.6)
		row_sb.border_color = Color(0.0, 0.7, 1.0, 0.7) if is_found else Color(0.2, 0.25, 0.35, 0.5)
		row_sb.set_border_width_all(1)
		row_sb.set_corner_radius_all(4)
		row_sb.set_content_margin_all(6)
		row.add_theme_stylebox_override("panel", row_sb)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		row.add_child(vbox)
		
		var title_lbl = Label.new()
		title_lbl.text = "%s %s" % [lm["icon"], lm["name"] if is_found else "??? Unknown Landmark"]
		title_lbl.modulate = Color(1.0, 0.85, 0.3) if is_found else Color(0.65, 0.7, 0.75)
		title_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = "%s - %s" % [lm["region"], lm["bonus"] if is_found else "Unexplored Realm"]
		desc_lbl.modulate = Color(0.75, 0.8, 0.85, 0.8)
		desc_lbl.add_theme_font_size_override("font_size", 10)
		vbox.add_child(desc_lbl)
		
		var status_lbl = Label.new()
		status_lbl.text = "STATUS: DISCOVERED ✓" if is_found else "STATUS: UNKNOWN (EXPLORE)"
		status_lbl.modulate = Color(0.2, 0.9, 0.4) if is_found else Color(0.9, 0.5, 0.2)
		status_lbl.add_theme_font_size_override("font_size", 10)
		vbox.add_child(status_lbl)
		
		landmarks_container.add_child(row)
		
	var pct = int(float(discovered_count) / float(landmarks.size()) * 100.0)
	stats_label.text = "🗺️ EXPLORATION PROGRESS\n%d / %d Landmarks Discovered (%d%%)" % [discovered_count, landmarks.size(), pct]

func _on_map_canvas_draw() -> void:
	if not map_canvas:
		return
		
	var c_size = map_canvas.size
	var origin = c_size / 2.0
	
	# Background parchment parchment-slate
	map_canvas.draw_rect(Rect2(Vector2.ZERO, c_size), Color(0.06, 0.08, 0.12, 0.96))
	
	# Biome quadrant regions
	var nw_rect = Rect2(0, 0, origin.x, origin.y)
	var ne_rect = Rect2(origin.x, 0, origin.x, origin.y)
	var sw_rect = Rect2(0, origin.y, origin.x, origin.y)
	var se_rect = Rect2(origin.x, origin.y, origin.x, origin.y)
	
	map_canvas.draw_rect(nw_rect, Color(0.04, 0.16, 0.10, 0.35)) # Emerald grove
	map_canvas.draw_rect(ne_rect, Color(0.12, 0.06, 0.16, 0.35)) # Crypts
	map_canvas.draw_rect(sw_rect, Color(0.18, 0.08, 0.04, 0.35)) # Scorched wastes
	map_canvas.draw_rect(se_rect, Color(0.16, 0.14, 0.04, 0.35)) # Sunken treasury
	
	# Biome grid & crosshairs
	map_canvas.draw_line(Vector2(origin.x, 0), Vector2(origin.x, c_size.y), Color(0.2, 0.3, 0.4, 0.5), 1.5)
	map_canvas.draw_line(Vector2(0, origin.y), Vector2(c_size.x, origin.y), Color(0.2, 0.3, 0.4, 0.5), 1.5)
	
	# Outer border
	map_canvas.draw_rect(Rect2(Vector2.ZERO, c_size), Color(0.0, 0.65, 1.0, 0.8), false, 2.0)
	
	# Biome labels
	map_canvas.draw_string(ThemeDB.fallback_font, Vector2(16, 24), "🌿 ANCIENT GROVE (NW)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 0.9, 0.5, 0.8))
	map_canvas.draw_string(ThemeDB.fallback_font, Vector2(origin.x + 16, 24), "🪦 CURSED CRYPTS (NE)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.5, 1.0, 0.8))
	map_canvas.draw_string(ThemeDB.fallback_font, Vector2(16, origin.y + 24), "🌋 SCORCHED WASTES (SW)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.6, 0.3, 0.8))
	map_canvas.draw_string(ThemeDB.fallback_font, Vector2(origin.x + 16, origin.y + 24), "👑 SUNKEN TREASURY (SE)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.85, 0.3, 0.8))
	map_canvas.draw_string(ThemeDB.fallback_font, origin + Vector2(-45, -8), "🏰 CITADEL", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.7, 0.8, 0.9, 0.7))
	
	# Draw Landmarks
	var landmarks = get_tree().get_nodes_in_group("landmarks")
	for lm in landmarks:
		if not is_instance_valid(lm):
			continue
		var lm_pos = lm.global_position
		var canvas_pos = _world_to_canvas(lm_pos, c_size)
		var lm_id = lm.get("landmark_id") if "landmark_id" in lm else "fountain"
		var is_disc = GameManager.is_landmark_discovered(lm_id)
		
		var pin_color = Color(0.2, 0.9, 0.5)
		var icon_str = "💚"
		match lm_id:
			"might":
				pin_color = Color(1.0, 0.35, 0.15)
				icon_str = "⚔️"
			"speed":
				pin_color = Color(0.25, 0.9, 1.0)
				icon_str = "💨"
			"vault":
				pin_color = Color(1.0, 0.85, 0.2)
				icon_str = "👑"
				
		if is_disc:
			map_canvas.draw_circle(canvas_pos, 8.0, pin_color)
			map_canvas.draw_arc(canvas_pos, 10.0, 0, TAU, 16, Color.WHITE, 1.5)
			map_canvas.draw_string(ThemeDB.fallback_font, canvas_pos + Vector2(-28, 20), lm.get("landmark_name") if "landmark_name" in lm else "", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, pin_color)
		else:
			map_canvas.draw_circle(canvas_pos, 6.0, Color(0.4, 0.4, 0.5, 0.6))
			map_canvas.draw_string(ThemeDB.fallback_font, canvas_pos + Vector2(-6, 4), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 1.0, 1.0, 0.75))
			
	# Draw Player location pin
	if is_instance_valid(player):
		var p_canvas = _world_to_canvas(player.global_position, c_size)
		var pulse = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.009)
		# Pulse halo
		map_canvas.draw_circle(p_canvas, 10.0 * pulse, Color(0.0, 0.8, 1.0, 0.3))
		# Pin
		map_canvas.draw_circle(p_canvas, 5.5, Color(0.0, 0.95, 1.0))
		map_canvas.draw_arc(p_canvas, 7.0, 0, TAU, 16, Color.WHITE, 2.0)
		# Label
		var coord_str = "📍 YOU (%d, %d)" % [int(player.global_position.x), int(player.global_position.y)]
		map_canvas.draw_string(ThemeDB.fallback_font, p_canvas + Vector2(-35, -12), coord_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 1.0, 0.4))

func _world_to_canvas(world_pos: Vector2, canvas_size: Vector2) -> Vector2:
	var norm_x = (world_pos.x / (WORLD_EXTENTS.x * 2.0)) + 0.5
	var norm_y = (world_pos.y / (WORLD_EXTENTS.y * 2.0)) + 0.5
	norm_x = clamp(norm_x, 0.05, 0.95)
	norm_y = clamp(norm_y, 0.05, 0.95)
	return Vector2(norm_x * canvas_size.x, norm_y * canvas_size.y)
