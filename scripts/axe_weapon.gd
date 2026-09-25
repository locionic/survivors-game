class_name AxeWeapon
extends Node2D

## Holy Arc Axe: Throws heavy spinning battleaxes in high piercing arcs over hordes.

@export var axe_scene: PackedScene
@export var base_cooldown: float = 2.0
@export var axe_count: int = 1
@export var is_active: bool = true

var cooldown_timer: float = 0.8
var damage_multiplier: float = 1.0
## Fusion tier multiplier pushed in by UpgradeManager.apply_arsenal_bonuses().
var tier_damage_mult: float = 1.0
var speed_multiplier: float = 1.0
var is_evolved: bool = false
var scythe_tex: Texture2D = null

func _ready() -> void:
	scythe_tex = load("res://assets/textures/reapers_scythe.png")

func _process(delta: float) -> void:
	if not is_active:
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		throw_axes()
		cooldown_timer = max(0.25, base_cooldown / speed_multiplier)

func throw_axes() -> void:
	if not axe_scene:
		return
		
	SoundManager.play("axe", 0.18 if is_evolved else 0.12)
	
	for i in range(axe_count):
		var axe = axe_scene.instantiate()
		if axe:
			var h_speed = 0.0
			if axe_count > 1:
				h_speed = (float(i) - float(axe_count - 1) / 2.0) * (140.0 if is_evolved else 110.0) + randf_range(-25, 25)
			else:
				h_speed = randf_range(-100.0, 100.0)
				
			axe.velocity = Vector2(h_speed, -480.0 + randf_range(-30, 30))
			axe.damage_multiplier = damage_multiplier * tier_damage_mult * _get_player_might()
			if is_evolved and scythe_tex:
				var spr = axe.get_node_or_null("Sprite2D")
				if spr:
					spr.texture = scythe_tex
					spr.scale = Vector2(1.45, 1.45)
				axe.base_damage = 50.0
				axe.fall_gravity = 600.0
			axe.global_position = global_position
			get_tree().current_scene.add_child(axe)

func _get_player_might() -> float:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_might_multiplier"):
		return p.get_might_multiplier()
	return 1.0

func upgrade_count() -> void:
	axe_count += 1

func upgrade_damage(bonus: float) -> void:
	damage_multiplier += bonus

func upgrade_speed(bonus: float) -> void:
	speed_multiplier += bonus

func evolve_to_reapers_cleave() -> void:
	is_evolved = true
	is_active = true
	axe_count = 3
	base_cooldown = 0.95
	damage_multiplier = 2.4
	SoundManager.play("powerup", 0.25)
	FloatingText.spawn(global_position + Vector2(0, -45), "💀 EVOLVED: REAPER'S CLEAVE! 💀", Color(0.95, 0.2, 0.3))

