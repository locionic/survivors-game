class_name DemonicAltar
extends Node2D

## DemonicAltar: Interactive in-world altar that summons the Demonic Risk-Reward Pact modal.

@export var activation_radius: float = 75.0
@export var altar_name: String = "Tế Đàn Tà Thần"

var is_activated: bool = false
var player_inside: bool = false
var pulse_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var particles: CPUParticles2D = $Particles

func _ready() -> void:
	add_to_group("demonic_altars")
	if sprite and ResourceLoader.exists("res://assets/textures/demonic_altar.png"):
		sprite.texture = load("res://assets/textures/demonic_altar.png")
	if particles:
		particles.emitting = true
	_update_label()

func _process(delta: float) -> void:
	pulse_time += delta * 3.0
	if is_activated:
		_update_label()
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
		
	var dist = global_position.distance_to(player.global_position)
	player_inside = (dist <= activation_radius)
	
	if player_inside and Input.is_action_just_pressed("ui_accept"):
		trigger_altar()
		
	_update_label()
	queue_redraw()

func _update_label() -> void:
	if not label:
		return
	if is_activated:
		label.text = "🩸 ĐÃ KÝ KHẾ ƯỚC"
		label.modulate = Color(0.6, 0.4, 0.6, 0.7)
	elif player_inside:
		var pulse = 0.8 + 0.2 * sin(pulse_time * 2.0)
		label.text = "🩸 [E / SPACE] HIẾN TẾ TÀ THẦN"
		label.modulate = Color(1.0, 0.2, 0.35, pulse)
	else:
		label.text = "🩸 TẾ ĐÀN TÀ THẦN"
		label.modulate = Color(0.85, 0.6, 0.7, 0.8)

func trigger_altar() -> void:
	if is_activated:
		return
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("open_altar_modal"):
		hud.open_altar_modal(self)

func on_pact_signed(pact_id: String) -> void:
	is_activated = true
	if particles:
		particles.color = Color(0.9, 0.1, 0.2, 0.9)
		particles.amount = 25
	FloatingText.spawn(global_position + Vector2(0, -35), "🩸 KHẾ ƯỚC ĐÃ KÝ!", Color(1.0, 0.2, 0.3))

func _draw() -> void:
	if is_activated:
		return
	var radius = activation_radius
	var col = Color(0.9, 0.15, 0.3, 0.25)
	if player_inside:
		col = Color(1.0, 0.2, 0.4, 0.45 + 0.15 * sin(pulse_time))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, col, 2.0)
