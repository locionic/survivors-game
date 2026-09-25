class_name HermitNPC
extends Node2D

## HermitNPC: Wandering Taoist master ("Lão Ngoan Đồng") appearing as an in-run lucky encounter.

@export var interaction_radius: float = 75.0

var player_inside: bool = false
var pulse_time: float = 0.0
var times_visited: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var particles: CPUParticles2D = $Particles

func _init() -> void:
	add_to_group("hermit_npcs")

func _ready() -> void:
	add_to_group("hermit_npcs")
	if sprite and ResourceLoader.exists("res://assets/textures/hermit_npc.png"):

		sprite.texture = load("res://assets/textures/hermit_npc.png")
	if particles:
		particles.emitting = true
	_update_label()

func _process(delta: float) -> void:
	pulse_time += delta * 3.5
	
	# Gentle floating bob animation
	if sprite:
		sprite.position.y = sin(pulse_time * 1.5) * 3.0
		
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
		
	var dist = global_position.distance_to(player.global_position)
	player_inside = (dist <= interaction_radius)
	
	if player_inside and Input.is_action_just_pressed("ui_accept"):
		trigger_hermit()
		
	_update_label()
	queue_redraw()

func _update_label() -> void:
	if not label:
		return
	if player_inside:
		var pulse = 0.8 + 0.2 * sin(pulse_time * 2.0)
		label.text = "🧙‍♂️ [E / SPACE] KỲ NGỘ GIANG HỒ"
		label.modulate = Color(0.35, 0.95, 1.0, pulse)
	else:
		label.text = "🧙‍♂️ LÃO NGOAN ĐỒNG"
		label.modulate = Color(0.85, 0.9, 1.0, 0.85)

func trigger_hermit() -> void:
	times_visited += 1
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("open_hermit_modal"):
		hud.open_hermit_modal(self)

func on_shop_finished() -> void:
	FloatingText.spawn(global_position + Vector2(0, -38), "🧙‍♂️ HỮU DUYÊN TƯƠNG PHÙNG!", Color(0.4, 0.95, 1.0))

func _draw() -> void:
	var radius = interaction_radius
	var col = Color(0.3, 0.85, 1.0, 0.25)
	if player_inside:
		col = Color(0.4, 0.95, 1.0, 0.45 + 0.15 * sin(pulse_time))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, col, 2.0)
