class_name ToxicBilePuddle
extends Area2D

## Toxic Bile Puddle:
## Persistent acidic biohazard hazard pool left behind by Bloaters and Toxic Spitters.
## Inflicts corrosive tick damage and slows players walking through it.
## Can be incinerated and neutralized by explosive barrel detonations.

@export var lifetime: float = 7.5
@export var tick_interval: float = 0.50
@export var tick_damage: float = 4.0

var current_time: float = 0.0
var tick_timer: float = 0.0
var is_incinerated: bool = false
var player_inside: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	add_to_group("toxic_puddles")
	add_to_group("hazard_zones")
	z_index = 240
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_incinerated:
		return

	current_time += delta
	if current_time >= lifetime:
		queue_free()
		return
	elif current_time >= lifetime - 1.5:
		# Smooth fade out in the final 1.5 seconds
		modulate.a = max(0.0, (lifetime - current_time) / 1.5)

	# Gentle organic bubbling pulse
	if sprite:
		var pulse := sin(current_time * 5.0) * 0.05
		sprite.scale = Vector2(1.0 + pulse, 1.0 - pulse)

	# Corrosive tick damage to player inside the sludge
	if player_inside and is_instance_valid(player_inside):
		tick_timer -= delta
		if tick_timer <= 0.0:
			tick_timer = tick_interval
			if player_inside.has_method("take_damage"):
				player_inside.take_damage(tick_damage)
				FloatingText.spawn(
					player_inside.global_position + Vector2(randf_range(-12, 12), -24),
					"☣️ -%d" % int(tick_damage),
					Color(0.35, 1.0, 0.45)
				)
			if player_inside.has_method("apply_toxic_slow"):
				player_inside.apply_toxic_slow(0.65)

func _on_body_entered(body: Node2D) -> void:
	if is_incinerated:
		return
	if body.is_in_group("player"):
		player_inside = body
		if body.has_method("apply_toxic_slow"):
			body.apply_toxic_slow(0.65)
		# Immediate initial tick
		tick_timer = 0.15

func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		player_inside = null

func incinerate() -> void:
	if is_incinerated:
		return
	is_incinerated = true
	player_inside = null
	
	if collision_shape:
		collision_shape.disabled = true

	# Fiery neutralization burst
	var p = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 26
	p.lifetime = 0.45
	p.spread = 180.0
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 160.0
	p.scale_amount_min = 2.5
	p.scale_amount_max = 5.5
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.8, 0.2, 1.0), Color(1.0, 0.35, 0.05, 0.8), Color(0.2, 0.2, 0.2, 0.0)])
	p.color_ramp = grad
	p.global_position = global_position
	p.z_index = 950
	
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(p)
		var p_t = get_tree().create_timer(0.55)
		p_t.timeout.connect(p.queue_free)

	FloatingText.spawn(global_position + Vector2(0, -22), "🔥 ĐÃ HỎA THIÊU BILE!", Color(1.0, 0.7, 0.2))
	SoundManager.play("explosion", 0.2)
	
	visible = false
	var t = get_tree().create_timer(0.05)
	t.timeout.connect(queue_free)
