class_name AxeProjectile
extends Area2D

## High arcing battleaxe that spins through the air and pierces enemy swarms.

@export var base_damage: float = 38.0
@export var fall_gravity: float = 850.0

var velocity: Vector2 = Vector2(0, -420.0)
var damage_multiplier: float = 1.0
var hit_cooldowns: Dictionary = {}
## Expansion 21.0: weapon tag for the Chiến Tích DPS breakdown.
var weapon_id: String = "axe"

func _ready() -> void:
	var timer = get_tree().create_timer(2.4)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	velocity.y += fall_gravity * delta
	global_position += velocity * delta
	$Sprite2D.rotation += 22.0 * delta
	
	# Update hit cooldowns
	for enemy in hit_cooldowns.keys():
		hit_cooldowns[enemy] -= delta
		if hit_cooldowns[enemy] <= 0:
			hit_cooldowns.erase(enemy)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and not body.get("is_dead"):
		if not hit_cooldowns.has(body):
			hit_cooldowns[body] = 0.35 # Hit cooldown per enemy
			if body.has_method("take_damage"):
				var dealt = base_damage * damage_multiplier
				body.take_damage(dealt, global_position)
				GameManager.record_weapon_damage(weapon_id, dealt)
