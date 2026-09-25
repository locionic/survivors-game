class_name OrbitingShield
extends Area2D

## Single orbiting blade/satellite that damages enemies on contact.

@export var damage: float = 12.0
## Expansion 21.0: weapon tag for the Chiến Tích DPS breakdown.
var weapon_id: String = "shield"

func _ready() -> void:
	add_to_group("projectiles")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		GameManager.record_weapon_damage(weapon_id, damage)
