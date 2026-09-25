class_name SpiritSwordProjectile
extends Area2D

## Celestial Flying Spirit Sword (Thần Kiếm) fired by Lục Mạch Thần Kiếm or Vạn Kiếm Quy Tông.

@export var speed: float = 620.0
@export var damage: float = 35.0
@export var pierce: int = 3
@export var lifetime: float = 2.5

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("projectiles")
	var t = get_tree().create_timer(lifetime)
	t.timeout.connect(queue_free)
	rotation = direction.angle() + PI / 2.0 # Texture points upwards

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		if randf() < 0.35 and body.has_method("apply_burn"):
			body.apply_burn(2.5, 14.0)
		SoundManager.play("hit", 0.08)
		pierce -= 1
		if pierce <= 0:
			queue_free()
