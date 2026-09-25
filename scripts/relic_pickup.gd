class_name RelicPickup
extends Area2D

## RelicPickup: Collectible ancient artifact providing run-long passive enhancements.

@export var relic_id: String = "vampire_fang"

@onready var label: Label = $Visual/IconLabel
@onready var halo: Node2D = $Visual/Halo
@onready var visual: Node2D = $Visual

var time_passed: float = 0.0
var relic_data: Dictionary = {}

func _ready() -> void:
	add_to_group("relics")
	time_passed = randf() * 10.0
	
	if GameManager and GameManager.RELICS.has(relic_id):
		relic_data = GameManager.RELICS[relic_id]
	else:
		relic_data = {"id": relic_id, "name": "Ancient Relic", "icon": "💎", "color": Color.CYAN}
		
	if label:
		label.text = relic_data.get("icon", "💎")
	
	body_entered.connect(_on_body_entered)
	
	# Spawn bounce in animation
	scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)

func set_relic(new_id: String) -> void:
	relic_id = new_id
	if GameManager and GameManager.RELICS.has(relic_id):
		relic_data = GameManager.RELICS[relic_id]
	if label:
		label.text = relic_data.get("icon", "💎")
	queue_redraw()

func _process(delta: float) -> void:
	time_passed += delta
	if visual:
		# Floating bob motion
		visual.position.y = sin(time_passed * 4.0) * 5.0
		# Pulse halo
		if halo:
			var pulse = 0.9 + 0.2 * sin(time_passed * 6.0)
			halo.scale = Vector2(pulse, pulse)

func _draw() -> void:
	# Draw glowing pedestal / base aura
	var color = relic_data.get("color", Color(1.0, 0.85, 0.2))
	draw_circle(Vector2(0, 10), 16.0, Color(color.r, color.g, color.b, 0.25))
	draw_arc(Vector2(0, 10), 16.0, 0, TAU, 24, Color(color.r, color.g, color.b, 0.8), 2.0)
	draw_circle(Vector2(0, 10), 6.0, color)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(player: Node2D) -> void:
	if GameManager:
		GameManager.add_relic(relic_id)
		
	var r_name = relic_data.get("name", "Ancient Relic")
	var icon = relic_data.get("icon", "✨")
	FloatingText.spawn(global_position, "%s %s!" % [icon, r_name.to_upper()], relic_data.get("color", Color(1.0, 0.9, 0.2)))
	SoundManager.play("powerup", 0.15)
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(6.0)
		
	# Spawn sparkle burst
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = 20
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 130.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.0
	particles.color = relic_data.get("color", Color(1.0, 0.85, 0.2))
	particles.global_position = global_position
	get_tree().current_scene.add_child(particles)
	var t = get_tree().create_timer(0.6)
	t.timeout.connect(particles.queue_free)
	
	queue_free()
