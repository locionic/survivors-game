class_name FireballWeapon
extends Node2D

## Inferno Staff: Auto-aims and unleashes exploding fireballs into enemy swarms.

@export var fireball_scene: PackedScene
@export var base_cooldown: float = 1.8
@export var attack_range: float = 480.0
@export var fireball_count: int = 1
@export var is_active: bool = true

var cooldown_timer: float = 0.5
var damage_multiplier: float = 1.0
## Fusion tier multiplier pushed in by UpgradeManager.apply_arsenal_bonuses().
var tier_damage_mult: float = 1.0
var speed_multiplier: float = 1.0
var blast_radius_multiplier: float = 1.0
var is_evolved: bool = false
var meteor_tex: Texture2D = null

func _ready() -> void:
	meteor_tex = load("res://assets/textures/apocalypse_meteor.png")

func _process(delta: float) -> void:
	if not is_active:
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		fire_fireball()
		cooldown_timer = max(0.22, base_cooldown / speed_multiplier)

func fire_fireball() -> void:
	if not fireball_scene:
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_targets: Array[Node2D] = []
	var range_sq = attack_range * attack_range
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node2D and not enemy.get("is_dead"):
			if global_position.distance_squared_to(enemy.global_position) <= range_sq:
				valid_targets.append(enemy)
				
	if valid_targets.is_empty():
		return
		
	# Target random enemies in range without full array shuffle
	var targets_to_shoot: Array[Node2D] = []
	var count_to_pick = min(fireball_count, valid_targets.size())
	for i in range(count_to_pick):
		var pick = valid_targets.pick_random()
		if not targets_to_shoot.has(pick):
			targets_to_shoot.append(pick)
	
	for target in targets_to_shoot:
		if is_instance_valid(target):
			var fb = fireball_scene.instantiate()
			if fb:
				var dir = global_position.direction_to(target.global_position)
				fb.direction = dir
				fb.damage_multiplier = damage_multiplier * tier_damage_mult * _get_player_might()
				fb.blast_radius *= blast_radius_multiplier
				if is_evolved and meteor_tex:
					var spr = fb.get_node_or_null("Sprite2D")
					if spr:
						spr.texture = meteor_tex
						spr.scale = Vector2(1.5, 1.5)
					fb.blast_radius = max(fb.blast_radius, 160.0)
				fb.global_position = global_position
				get_tree().current_scene.add_child(fb)
				SoundManager.play("shoot", 0.22 if is_evolved else 0.18)

func _get_player_might() -> float:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_might_multiplier"):
		return p.get_might_multiplier()
	return 1.0

func upgrade_count() -> void:
	fireball_count += 1

func upgrade_damage(bonus: float) -> void:
	damage_multiplier += bonus

func upgrade_blast_radius(bonus: float) -> void:
	blast_radius_multiplier += bonus

func upgrade_fire_rate(bonus: float) -> void:
	speed_multiplier += bonus

func evolve_to_apocalypse_meteor() -> void:
	is_evolved = true
	is_active = true
	fireball_count = 3
	base_cooldown = 1.1
	damage_multiplier = 2.4
	blast_radius_multiplier = 2.2
	SoundManager.play("powerup", 0.25)
	FloatingText.spawn(global_position + Vector2(0, -45), "☄️ EVOLVED: APOCALYPSE METEOR! ☄️", Color(1.0, 0.45, 0.1))

