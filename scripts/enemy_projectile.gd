class_name EnemyProjectile
extends Area2D

## Projectile fired by ranged enemies and bosses towards the player.

@export var speed: float = 160.0
@export var damage: float = 12.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("enemy_projectiles")
	rotation = direction.angle()
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	# Subtle spin
	$Sprite2D.rotation += 8.0 * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
