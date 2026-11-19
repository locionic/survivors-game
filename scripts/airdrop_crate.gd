class_name AirdropCrate
extends Area2D

## Emergency Military Airdrop Crate:
## Descends via parachute with a green signal flare. When opened by the player,
## triggers a screen-wide tactical bio-purge, drops high-value loot, and grants
## 12 seconds of Adrenaline Overdrive.

@export var descend_speed: float = 140.0

var target_y: float = 0.0
var is_landing: bool = true
var time_alive: float = 0.0
var is_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var flare_particles: CPUParticles2D = null

func _ready() -> void:
	add_to_group("airdrop_crates")
	add_to_group("pickups")
	target_y = global_position.y
	global_position.y -= 300.0
	
	body_entered.connect(_on_body_entered)
	_setup_flare_particles()

func _setup_flare_particles() -> void:
	flare_particles = CPUParticles2D.new()
	flare_particles.emitting = true
	flare_particles.amount = 16
	flare_particles.lifetime = 0.8
	flare_particles.direction = Vector2(0, -1)
	flare_particles.spread = 25.0
	flare_particles.gravity = Vector2(0, -40)
	flare_particles.initial_velocity_min = 35.0
	flare_particles.initial_velocity_max = 70.0
	flare_particles.scale_amount_min = 2.5
	flare_particles.scale_amount_max = 5.0
	# Neon green emergency flare smoke
	flare_particles.color = Color(0.2, 1.0, 0.45, 0.85)
	add_child(flare_particles)

func _process(delta: float) -> void:
	time_alive += delta
	
	if is_landing:
		global_position.y += descend_speed * delta
		# Parachute slight swaying oscillation
		global_position.x += sin(time_alive * 4.0) * 0.8
		if global_position.y >= target_y:
			global_position.y = target_y
			is_landing = false
			SoundManager.play("hit", 0.22)
			var cam = get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("shake"):
				cam.shake(4.0)
	else:
		# Pulsing glow once landed on ground
		var pulse = (sin(time_alive * 6.0) + 1.0) * 0.5
		if sprite:
			sprite.modulate = Color(1.0 + pulse * 0.5, 1.0 + pulse * 0.8, 1.0, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body.is_in_group("player"):
		return
	is_collected = true
	collect_airdrop(body)

func collect_airdrop(player: Node2D) -> void:
	is_collected = true
	SoundManager.play("quest_complete", 0.35)
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(9.0)

	FloatingText.spawn(global_position + Vector2(0, -45), "⭐ AIRDROP: ADRENALINE OVERDRIVE! ⭐", Color(0.3, 1.0, 0.45))

	# 1. Screen-wide Tactical Nuke Strike (vaporizes trash enemies)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			if e.has_method("take_damage"):
				e.take_damage(450.0 if not e.get("is_boss") else 150.0, global_position)

	# 2. Adrenaline Overdrive Buff (Applies temporary attack speed and move speed bonus)
	if is_instance_valid(player) and player.has_method("apply_overdrive_buff"):
		player.apply_overdrive_buff(12.0)

	# 3. Gold Credits & Bio-Vials
	if GameManager:
		GameManager.add_gold(60)
	
	var gem_scene = load("res://scenes/gem.tscn") as PackedScene
	if gem_scene and get_tree() and get_tree().current_scene:
		for i in range(8):
			var gem = gem_scene.instantiate()
			if gem:
				var a = (float(i) / 8.0) * TAU
				var offset = Vector2(cos(a), sin(a)) * randf_range(25.0, 55.0)
				gem.global_position = global_position + offset
				get_tree().current_scene.call_deferred("add_child", gem)

	# 4. Burst Particles on Pickup
	var burst = CPUParticles2D.new()
	burst.emitting = true
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.amount = 32
	burst.lifetime = 0.5
	burst.spread = 180.0
	burst.initial_velocity_min = 100.0
	burst.initial_velocity_max = 220.0
	burst.scale_amount_min = 2.5
	burst.scale_amount_max = 5.5
	burst.color = Color(0.25, 1.0, 0.45, 0.9)
	burst.global_position = global_position
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(burst)
		var t = get_tree().create_timer(0.6)
		t.timeout.connect(burst.queue_free)

	queue_free()
