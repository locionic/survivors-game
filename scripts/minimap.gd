class_name Minimap
extends Control

## Minimap: In-game tactical radar displaying player location, world shrines, and boss direction.

signal open_map_requested

@export var radar_range: float = 2400.0
var radius: float = 60.0
var center: Vector2

var player: Node2D = null

func _ready() -> void:
	custom_minimum_size = Vector2(130, 130)
	size = Vector2(130, 130)
	mouse_filter = Control.MOUSE_FILTER_STOP
	center = size / 2.0
	radius = size.x / 2.0 - 6.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("open_map_requested")

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	queue_redraw()

func _draw() -> void:
	center = size / 2.0
	radius = size.x / 2.0 - 6.0
	
	# Radar background circle
	draw_circle(center, radius, Color(0.05, 0.08, 0.14, 0.88))
	draw_arc(center, radius, 0, TAU, 36, Color(0.2, 0.45, 0.7, 0.9), 2.0)
	
	# Faint concentric range rings
	draw_arc(center, radius * 0.5, 0, TAU, 24, Color(0.15, 0.25, 0.35, 0.4), 1.0)
	
	# Crosshairs
	draw_line(center - Vector2(radius * 0.9, 0), center + Vector2(radius * 0.9, 0), Color(0.15, 0.25, 0.35, 0.35), 1.0)
	draw_line(center - Vector2(0, radius * 0.9), center + Vector2(0, radius * 0.9), Color(0.15, 0.25, 0.35, 0.35), 1.0)
	
	# Compass North Indicator
	draw_string(ThemeDB.fallback_font, center + Vector2(-4, -radius + 12), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.0, 0.8, 1.0, 0.85))
	
	if not is_instance_valid(player):
		return
		
	var p_pos = player.global_position
	
	# Draw Landmarks
	var landmarks = get_tree().get_nodes_in_group("landmarks")
	for lm in landmarks:
		if not is_instance_valid(lm):
			continue
		var offset = lm.global_position - p_pos
		var dist = offset.length()
		var lm_id = lm.get("landmark_id") if "landmark_id" in lm else "fountain"
		var is_disc = lm.get("is_discovered") if "is_discovered" in lm else false
		
		# Color per landmark type
		var dot_color = Color(0.2, 0.9, 0.5) # Fountain
		match lm_id:
			"might": dot_color = Color(1.0, 0.35, 0.15)
			"speed": dot_color = Color(0.25, 0.9, 1.0)
			"vault": dot_color = Color(1.0, 0.85, 0.2)
			
		if not is_disc:
			dot_color = dot_color.lerp(Color.WHITE, 0.4)
			
		var clamped_dist = min(dist / radar_range * radius, radius - 6.0)
		var dot_pos = center + offset.normalized() * clamped_dist
		
		# If outside radar range, draw a small directional triangle on the rim
		if dist > radar_range:
			var rim_pos = center + offset.normalized() * (radius - 5.0)
			draw_circle(rim_pos, 3.0, dot_color)
		else:
			# Draw blip on radar
			draw_circle(dot_pos, 4.0, dot_color)
			draw_arc(dot_pos, 5.5, 0, TAU, 12, Color.BLACK, 1.0)
			
	# Draw Active Bosses
	var bosses = get_tree().get_nodes_in_group("bosses")
	for boss in bosses:
		if is_instance_valid(boss) and not boss.get("is_dead"):
			var b_offset = boss.global_position - p_pos
			var b_dist = b_offset.length()
			var b_clamped = min(b_dist / radar_range * radius, radius - 6.0)
			var b_pos = center + b_offset.normalized() * b_clamped
			# Pulsing red skull dot
			var pulse = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.008)
			draw_circle(b_pos, 5.5, Color(1.0, 0.15, 0.15, pulse))
			draw_arc(b_pos, 7.0, 0, TAU, 12, Color(1.0, 0.8, 0.2), 1.5)
			
	# Player Dot in Center (Green arrow / circle)
	draw_circle(center, 4.5, Color(0.1, 1.0, 0.4))
	draw_arc(center, 6.0, 0, TAU, 16, Color.BLACK, 1.2)
	if "velocity" in player and player.velocity.length_squared() > 1.0:
		var dir = player.velocity.normalized()
		draw_line(center, center + dir * 9.0, Color(0.1, 1.0, 0.4), 2.0)
