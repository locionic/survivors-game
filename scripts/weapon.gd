class_name Weapon
extends Node2D

## Auto-targeting weapon component that finds nearest enemies and fires projectiles.

@export var projectile_scene: PackedScene
@export var base_damage: float = 18.0
@export var base_cooldown: float = 0.85
@export var attack_range: float = 400.0
@export var projectile_count: int = 1
@export var is_active: bool = true

var cooldown_timer: float = 0.0
var damage_multiplier: float = 1.0
## Fusion tier multiplier pushed in by UpgradeManager.apply_arsenal_bonuses().
var tier_damage_mult: float = 1.0
var speed_multiplier: float = 1.0
## Extra targets each projectile carries. Đường Môn sets this to 1 at character
## load; 0 is every other sect, and every spawned blade defaults to pierce=1.
var pierce_bonus: int = 0
var is_evolved: bool = false

# Expansion 20.0: Tinh Võ Hợp Nhất — Bão Vũ Lê Hoa Châm (Dagger Lv.5 + Axe Lv.5)
var is_lotus_storm: bool = false
const LOTUS_STORM_PROJECTILES: int = 16

var thousand_blade_tex: Texture2D = null

func _ready() -> void:
	thousand_blade_tex = load("res://assets/textures/thousand_blade.png")

func _process(delta: float) -> void:
	if not is_active:
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		var target = find_closest_enemy()
		if target != null or is_evolved:
			var target_pos = target.global_position if target else global_position + Vector2.RIGHT
			fire_at(target_pos)
			cooldown_timer = max(0.12, base_cooldown / speed_multiplier)

func find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist_sq: float = attack_range * attack_range
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node2D and not enemy.get("is_dead"):
			var dist_sq = global_position.distance_squared_to(enemy.global_position)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				closest = enemy
				
	return closest

func fire_at(target_pos: Vector2) -> void:
	if not projectile_scene:
		return
		
	SoundManager.play("shoot", 0.18 if is_evolved else 0.12)
	var base_direction = global_position.direction_to(target_pos)
	
	if is_evolved:
		# Thousand Blades / Lotus Storm: 360-degree storm of piercing astral blades
		var count = projectile_count
		var step = TAU / float(count)
		var rotation_offset = Time.get_ticks_msec() * 0.002
		for i in range(count):
			var proj = projectile_scene.instantiate()
			if proj:
				var angle = i * step + rotation_offset
				var dir = Vector2(cos(angle), sin(angle))
				proj.set("direction", dir)
				proj.set("damage", base_damage * damage_multiplier * tier_damage_mult * _get_player_might())
				proj.set("speed", 550.0)
				proj.set("pierce", 999)
				proj.global_position = global_position
				proj.rotation = angle
				if thousand_blade_tex:
					var spr = proj.get_node_or_null("Sprite2D")
					if spr:
						spr.texture = thousand_blade_tex
						spr.scale = Vector2(1.5, 1.5)
				get_tree().current_scene.add_child(proj)
		return

	for i in range(projectile_count):
		var proj = projectile_scene.instantiate()
		if proj:
			var angle_offset = 0.0
			if projectile_count > 1:
				angle_offset = deg_to_rad((i - (projectile_count - 1) / 2.0) * 12.0)
				
			var spread_dir = base_direction.rotated(angle_offset)
			proj.set("direction", spread_dir)
			proj.set("damage", base_damage * damage_multiplier * tier_damage_mult * _get_player_might())
			proj.set("pierce", 1 + pierce_bonus)
			proj.global_position = global_position
			proj.rotation = spread_dir.angle()
			get_tree().current_scene.add_child(proj)

func evolve_to_thousand_blades() -> void:
	is_evolved = true
	is_active = true
	base_damage = 32.0
	base_cooldown = 0.42
	projectile_count = 8
	FloatingText.spawn(global_position + Vector2(0, -45), "⚡ EVOLVED: THOUSAND BLADES! ⚡", Color(1.0, 0.88, 0.2))

## Expansion 20.0: Tinh Võ Hợp Nhất — Bão Vũ Lê Hoa Châm.
## 16 needles in a full 360° ring (step = 2*PI/16) that shred the whole screen.
func evolve_to_lotus_storm() -> void:
	is_lotus_storm = true
	is_evolved = true
	is_active = true
	projectile_count = LOTUS_STORM_PROJECTILES
	base_damage = max(base_damage, 90.0)
	base_cooldown = 0.36
	attack_range = max(attack_range, 620.0)
	FloatingText.spawn(global_position + Vector2(0, -45), "🌟 HỢP NHẤT: BÃO VŨ LÊ HOA CHÂM! 🌟", Color(0.45, 1.0, 0.85))

func _get_player_might() -> float:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_might_multiplier"):
		return p.get_might_multiplier()
	return 1.0

