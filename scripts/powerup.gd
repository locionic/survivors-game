class_name PowerUp
extends Area2D

## Field power-up pickup: Meat (Heal), Super Magnet (Vacuum all gems/coins), Holy Nuke (Screen wipe).

@export_enum("meat", "magnet", "nuke") var powerup_type: String = "meat"
@export var base_heal: float = 35.0

@onready var sprite: Sprite2D = $Sprite2D

var textures: Dictionary = {
	"meat": preload("res://assets/textures/meat.png"),
	"magnet": preload("res://assets/textures/super_magnet.png"),
	"nuke": preload("res://assets/textures/nuke.png")
}

func _ready() -> void:
	add_to_group("powerups")
	_apply_texture()
	
	# Gentle hover/pulse animation
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.4)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

func set_type(type: String) -> void:
	powerup_type = type
	_apply_texture()

func _apply_texture() -> void:
	if sprite and textures.has(powerup_type):
		sprite.texture = textures[powerup_type]

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)

func collect(player: Node2D) -> void:
	match powerup_type:
		"meat":
			if player.has_method("heal"):
				player.heal(base_heal)
			SoundManager.play("powerup", 0.05)
			FloatingText.spawn(global_position, "+%d HP" % int(base_heal), Color(0.2, 1.0, 0.4))
			
		"magnet":
			# Vacuum all gems and coins across map
			SoundManager.play("powerup", 0.1)
			FloatingText.spawn(global_position, "SUPER MAGNET!", Color(1.0, 0.85, 0.2))
			var pickups = get_tree().get_nodes_in_group("gems") + get_tree().get_nodes_in_group("coins")
			for item in pickups:
				if is_instance_valid(item) and item.has_method("target_player"):
					item.target_player(player)
					
		"nuke":
			# Detonate all standard enemies on screen
			SoundManager.play("explosion", 0.1)
			FloatingText.spawn(global_position, "HOLY NUKE!", Color(1.0, 0.3, 0.2))
			
			var cam = get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("shake"):
				cam.shake(14.0)
				
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if is_instance_valid(enemy) and not enemy.get("is_dead"):
					if not enemy.get("is_boss"):
						enemy.die()
					else:
						# Bosses take 100 holy damage instead of instakill
						if enemy.has_method("take_damage"):
							enemy.take_damage(100.0, global_position)
	
	queue_free()
