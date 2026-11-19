class_name ExplosiveBarrel
extends StaticBody2D

## Explosive Hazard Drum:
## High-impact explosive barrel that detonates on hit, triggering massive screen-clearing
## AoE damage and chain reactions across adjacent barrels.

@export var max_health: float = 30.0
@export var explosion_damage: float = 320.0
@export var explosion_radius: float = 175.0

var current_health: float = 30.0
var is_detonated: bool = false
var is_primed: bool = false
var flash_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var crater_tex: Texture2D = null

func _ready() -> void:
	add_to_group("explosive_barrels")
	add_to_group("destructibles")
	add_to_group("enemies") # Allows player auto-targeting weapons to engage
	current_health = max_health
	if ResourceLoader.exists("res://assets/textures/charred_crater.png"):
		crater_tex = load("res://assets/textures/charred_crater.png")

func _process(delta: float) -> void:
	if is_primed and not is_detonated:
		flash_timer += delta * 24.0
		var f := (sin(flash_timer) + 1.0) * 0.5
		if sprite:
			sprite.modulate = Color(1.0 + f * 1.5, 0.3 + f * 0.2, 0.2, 1.0)

func take_damage(amount: float, _source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_detonated:
		return
	current_health -= amount
	SoundManager.play("hit", 0.18)

	# Visual flash on hit
	if sprite:
		sprite.modulate = Color(2.0, 0.4, 0.3, 1.0)
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	if current_health <= 0.0 and not is_detonated:
		prime_and_detonate()

func prime_and_detonate() -> void:
	if is_detonated or is_primed:
		return
	is_primed = true
	# Short fuse delay (0.12s) allows multiple barrels to create a cascading rhythm
	var t = get_tree().create_timer(0.12)
	t.timeout.connect(detonate)

func detonate() -> void:
	if is_detonated:
		return
	is_detonated = true
	
	# 1. Camera Screen Shake & Audio
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(12.0)
	SoundManager.play("explosion", 0.25)

	# 2. Spawn Charred Crater Decal on the Asphalt
	if crater_tex and get_tree() and get_tree().current_scene:
		var crater = Sprite2D.new()
		crater.texture = crater_tex
		crater.global_position = global_position
		crater.z_index = 250
		get_tree().current_scene.add_child(crater)

	# 3. Massive Fiery Explosion Particles
	var p = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.96
	p.amount = 45
	p.lifetime = 0.55
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 280.0
	p.scale_amount_min = 3.5
	p.scale_amount_max = 8.0
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.95, 0.4, 1.0), Color(1.0, 0.35, 0.05, 0.9), Color(0.25, 0.2, 0.2, 0.0)])
	p.color_ramp = grad
	p.global_position = global_position
	p.z_index = 950
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(p)
		var p_t = get_tree().create_timer(0.65)
		p_t.timeout.connect(p.queue_free)

	# 4. Floating Text
	FloatingText.spawn(global_position + Vector2(0, -35), "💥 KABOOM!", Color(1.0, 0.65, 0.1))

	# 5. Deal Devastating AoE Damage to Zombies in Radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e != self and not e.get("is_dead"):
			if global_position.distance_to(e.global_position) <= explosion_radius:
				if e.has_method("take_damage"):
					e.take_damage(explosion_damage, global_position)

	# 6. Chain Reaction with Neighboring Barrels!
	var barrels = get_tree().get_nodes_in_group("explosive_barrels")
	for b in barrels:
		if is_instance_valid(b) and b != self and not b.is_detonated and not b.is_primed:
			if global_position.distance_to(b.global_position) <= explosion_radius + 40.0:
				b.call_deferred("prime_and_detonate")

	# 7. Drop Bio-Vials and Gold
	_spawn_loot()

	# Remove barrel
	visible = false
	if collision_shape:
		collision_shape.disabled = true
	var cleanup_timer = get_tree().create_timer(0.1)
	cleanup_timer.timeout.connect(queue_free)

func _spawn_loot() -> void:
	if not get_tree() or not get_tree().current_scene:
		return
	# Spawn XP Gem / Bio-Vial
	var gem_scene = load("res://scenes/gem.tscn") as PackedScene
	if gem_scene:
		for i in range(3):
			var gem = gem_scene.instantiate()
			if gem:
				gem.global_position = global_position + Vector2(randf_range(-22, 22), randf_range(-22, 22))
				get_tree().current_scene.call_deferred("add_child", gem)

	# Spawn Gold Coin
	var coin_scene = load("res://scenes/coin.tscn") as PackedScene
	if coin_scene and randf() < 0.75:
		var coin = coin_scene.instantiate()
		if coin:
			coin.set("gold_value", 5)
			coin.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
			get_tree().current_scene.call_deferred("add_child", coin)
