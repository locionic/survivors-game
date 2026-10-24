class_name GoldCoin
extends Area2D

## Collectible Gold Coin with drop shadow and kinetic loot pop physics.

@export var gold_value: int = 1
@export var base_fly_speed: float = 300.0

var target: Node2D = null
var current_speed: float = 40.0
var toss_vel: Vector2 = Vector2.ZERO
var toss_timer: float = 0.24

func _ready() -> void:
	add_to_group("coins")
	add_to_group("gems") # Handled by magnet
	
	# Kinetic pop impulse in random outward direction
	var angle = randf() * TAU
	var speed = randf_range(50.0, 120.0)
	toss_vel = Vector2(cos(angle), sin(angle)) * speed
	
	# Gentle hover loop & initial pop
	scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.14).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)
	
	var hover = create_tween().set_loops()
	hover.tween_property(self, "scale", Vector2(1.15, 1.15), 0.35)
	hover.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35)
	
	# Magnet arc trail: golden sycee fragments trailing behind during magnetic pull
	var trail = CPUParticles2D.new()
	trail.name = "MagnetTrail"
	trail.amount = 8
	trail.lifetime = 0.3
	trail.pre_process_time = 0.0
	trail.explosiveness = 0.8
	trail.speed_scale = 0.5
	trail.direction = Vector2.ZERO
	trail.gravity = Vector2.ZERO
	trail.spread = 0.0
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 30.0
	trail.scale_amount_min = 0.3
	trail.scale_amount_max = 0.6
	trail.color = Color(1.0, 0.85, 0.2, 0.9)
	trail.color_ramp = Gradient.new()
	trail.color_ramp.set_offsets(PackedFloat32Array([0.0, 1.0]))
	trail.color_ramp.set_colors(PackedColorArray([Color(1.0, 0.95, 0.3, 0.95), Color(0.9, 0.7, 0.1, 0.0)]))
	trail.emitting = false
	trail.z_index = 10
	add_child(trail)

func _process(delta: float) -> void:
	if is_instance_valid(target):
		current_speed += 750.0 * delta
		global_position = global_position.move_toward(target.global_position, current_speed * delta)
		
		# Emit magnet arc trail particles during pull
		var trail = get_node_or_null("MagnetTrail")
		if trail:
			trail.emitting = true
			trail.global_position = global_position
		
		if global_position.distance_to(target.global_position) < 18.0:
			collect()
	elif toss_timer > 0.0:
		toss_timer -= delta
		global_position += toss_vel * delta
		toss_vel = toss_vel.move_toward(Vector2.ZERO, 380.0 * delta)

func _draw() -> void:
	# Subtle drop shadow beneath coin
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.40))
	draw_circle(Vector2.ZERO, 6.0, Color(0.0, 0.0, 0.0, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func target_player(player_ref: Node2D) -> void:
	target = player_ref

func collect() -> void:
	GameManager.add_gold(gold_value)
	SoundManager.play("coin", 0.1)
	FloatingText.spawn(global_position, "+%d" % gold_value, Color(1.0, 0.85, 0.2))
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		collect()
