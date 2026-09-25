class_name Projectile
extends Area2D

## Projectile fired by weapons towards target directions or enemies.

@export var speed: float = 450.0
@export var damage: float = 15.0
@export var pierce: int = 1
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
## Expansion 21.0: which weapon this bolt belongs to, for the Chiến Tích DPS breakdown.
var weapon_id: String = "dagger"

func _ready() -> void:
	add_to_group("projectiles")
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		GameManager.record_weapon_damage(weapon_id, damage)
		if randf() < 0.20 and body.has_method("apply_poison"):
			body.apply_poison(2.5, 12.0)
		pierce -= 1
		if pierce <= 0:
			queue_free()
