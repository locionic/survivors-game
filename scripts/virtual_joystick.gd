class_name VirtualJoystick
extends Control

## Dynamic Floating Virtual Touch Joystick for mobile and web touch controls.
## Wherever the player touches/clicks and drags on the lower screen, the joystick spawns
## at that position and drives movement smoothly, matching Survivor.io's 1-stick feel.

signal joystick_moved(output: Vector2)

@export var max_radius: float = 60.0

var output: Vector2 = Vector2.ZERO
var is_active: bool = false
var touch_index: int = -1
var center_pos: Vector2 = Vector2.ZERO
var knob_pos: Vector2 = Vector2.ZERO
var fade_alpha: float = 0.0

func _ready() -> void:
	center_pos = size / 2.0
	knob_pos = center_pos
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_to_group("joystick")

func _process(delta: float) -> void:
	var target_alpha = 1.0 if is_active else 0.35
	if not is_equal_approx(fade_alpha, target_alpha):
		fade_alpha = move_toward(fade_alpha, target_alpha, delta * 5.0)
		queue_redraw()

func _draw() -> void:
	if fade_alpha <= 0.02:
		return
		
	var is_zombie := GameManager and GameManager.selected_stage == "zombie_city"
	var ring_col = Color(0.15, 0.85, 0.45, 0.75 * fade_alpha) if is_zombie else Color(0.4, 0.7, 1.0, 0.65 * fade_alpha)
	var fill_col = Color(0.08, 0.14, 0.12, 0.45 * fade_alpha) if is_zombie else Color(0.08, 0.12, 0.2, 0.40 * fade_alpha)
	var knob_col = Color(0.2, 1.0, 0.5, 0.90 * fade_alpha) if is_zombie else Color(0.35, 0.85, 1.0, 0.85 * fade_alpha)

	# Base circular field
	draw_circle(center_pos, max_radius, fill_col)
	draw_arc(center_pos, max_radius, 0, TAU, 36, ring_col, 2.5)
	draw_arc(center_pos, max_radius * 0.45, 0, TAU, 24, Color(ring_col.r, ring_col.g, ring_col.b, ring_col.a * 0.35), 1.2)

	# Floating Handle / Knob
	draw_circle(knob_pos, 22.0, knob_col)
	draw_arc(knob_pos, 22.0, 0, TAU, 28, Color(1.0, 1.0, 1.0, 0.95 * fade_alpha), 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			is_active = true
			center_pos = event.position
			knob_pos = event.position
			_update_knob(event.position)
		elif not event.pressed and event.index == touch_index:
			_reset_joystick()

	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update_knob(event.position)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				touch_index = 0
				is_active = true
				center_pos = event.position
				knob_pos = event.position
				_update_knob(event.position)
			else:
				_reset_joystick()

	elif event is InputEventMouseMotion:
		if is_active and touch_index == 0:
			_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	var diff = touch_pos - center_pos
	if diff.length() > max_radius:
		diff = diff.normalized() * max_radius
	knob_pos = center_pos + diff
	output = diff / max_radius
	emit_signal("joystick_moved", output)
	queue_redraw()

func _reset_joystick() -> void:
	is_active = false
	touch_index = -1
	knob_pos = center_pos
	output = Vector2.ZERO
	emit_signal("joystick_moved", Vector2.ZERO)
	queue_redraw()

func get_output() -> Vector2:
	return output
