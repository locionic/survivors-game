class_name FireballProjectile
extends Area2D

## Blazing meteor projectile that explodes on impact dealing AoE splash damage.

@export var speed: float = 340.0
@export var base_damage: float = 32.0
@export var blast_radius: float = 75.0

var direction: Vector2 = Vector2.RIGHT
var damage_multiplier: float = 1.0
## Expansion 21.0: weapon tag for the Chiến Tích DPS breakdown.
var weapon_id: String = "fireball"

func _ready() -> void:
	rotation = direction.angle()
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(explode)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	$Sprite2D.rotation += 10.0 * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and not body.get("is_dead"):
		explode()

func explode() -> void:
	SoundManager.play("explosion", 0.15)
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(8.0)
		
	# Spawn Fiery Explosion Particles
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 22
	particles.lifetime = 0.35
	particles.explosiveness = 0.92
	particles.spread = 180.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 140.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.5
	particles.color = Color(1.0, 0.45, 0.1)
	particles.global_position = global_position
	get_tree().current_scene.add_child(particles)
	var p_timer = get_tree().create_timer(0.4)
	p_timer.timeout.connect(particles.queue_free)
	
	# AoE Damage to all enemies within blast radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	var total_dmg = base_damage * damage_multiplier
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			if global_position.distance_to(enemy.global_position) <= blast_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(total_dmg, global_position)
					GameManager.record_weapon_damage(weapon_id, total_dmg)
				if enemy.has_method("apply_burn"):
					enemy.apply_burn(3.5, 18.0)
	
	queue_free()
