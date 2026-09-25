class_name VirtualJoystick
extends Control

## Virtual touch joystick for mobile and web touch controls.

signal joystick_moved(output: Vector2)

@export var max_radius: float = 55.0

var output: Vector2 = Vector2.ZERO
var is_active: bool = false
var touch_index: int = -1
var center_pos: Vector2 = Vector2.ZERO
var knob_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	center_pos = size / 2.0
	knob_pos = center_pos
	add_to_group("joystick")

func _draw() -> void:
	center_pos = size / 2.0
	# Base circle
	var base_col = Color(0.15, 0.2, 0.3, 0.55 if is_active else 0.35)
	draw_circle(center_pos, max_radius, base_col)
	draw_arc(center_pos, max_radius, 0, TAU, 32, Color(0.4, 0.6, 0.9, 0.7 if is_active else 0.4), 2.0)
	
	# Handle/Knob
	var knob_col = Color(0.3, 0.75, 1.0, 0.85 if is_active else 0.55)
	draw_circle(knob_pos, 22.0, knob_col)
	draw_arc(knob_pos, 22.0, 0, TAU, 24, Color.WHITE, 1.5)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			is_active = true
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
