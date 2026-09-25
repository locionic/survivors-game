class_name OrbitingWeapon
extends Node2D

## Weapon that keeps rotating shields around the player (like King Bible / Orbiting Blades).

@export var shield_scene: PackedScene
@export var orbit_radius: float = 90.0
@export var orbit_speed: float = 3.5
@export var shield_count: int = 2
@export var base_damage: float = 12.0
## Fusion tier multiplier pushed in by UpgradeManager.apply_arsenal_bonuses().
var tier_damage_mult: float = 1.0
@export var is_active: bool = true

var current_angle: float = 0.0
var active_shields: Array[Node2D] = []
var is_evolved: bool = false
var solar_shield_tex: Texture2D = null

func _ready() -> void:
	solar_shield_tex = load("res://assets/textures/solar_shield.png")
	if is_active:
		rebuild_shields()

func _process(delta: float) -> void:
	if not is_active:
		return
	current_angle += orbit_speed * delta
	if current_angle >= TAU:
		current_angle -= TAU
		
	var count = active_shields.size()
	if count == 0:
		return
		
	var effective_dmg = base_damage * tier_damage_mult * _get_player_might()
	var angle_step = TAU / float(count)
	for i in range(count):
		var shield = active_shields[i]
		if is_instance_valid(shield):
			var angle = current_angle + i * angle_step
			shield.position = Vector2(cos(angle), sin(angle)) * orbit_radius
			shield.rotation = angle + PI / 2.0
			shield.set("damage", effective_dmg)

func _get_player_might() -> float:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_might_multiplier"):
		return p.get_might_multiplier()
	return 1.0


func rebuild_shields() -> void:
	for shield in active_shields:
		if is_instance_valid(shield):
			shield.queue_free()
	active_shields.clear()
	
	if not shield_scene or not is_active:
		return
		
	for i in range(shield_count):
		var shield = shield_scene.instantiate() as Node2D
		if shield:
			shield.set("damage", base_damage)
			if is_evolved and solar_shield_tex:
				var spr = shield.get_node_or_null("Sprite2D")
				if spr:
					spr.texture = solar_shield_tex
					spr.scale = Vector2(1.4, 1.4)
			add_child(shield)
			active_shields.append(shield)

func add_shield() -> void:
	shield_count += 1
	rebuild_shields()

func upgrade_damage(bonus: float) -> void:
	base_damage += bonus
	for shield in active_shields:
		if is_instance_valid(shield):
			shield.set("damage", base_damage)

func upgrade_speed(bonus: float) -> void:
	orbit_speed += bonus

func evolve_to_solar_bulwark() -> void:
	is_evolved = true
	is_active = true
	shield_count = 5
	orbit_speed = 5.2
	orbit_radius = 110.0
	base_damage = 28.0
	rebuild_shields()
	SoundManager.play("powerup", 0.25)
	FloatingText.spawn(global_position + Vector2(0, -45), "☀️ EVOLVED: SOLAR BULWARK! ☀️", Color(1.0, 0.75, 0.1))

