class_name LightningWeapon
extends Node2D

## Holy Thunder Weapon: Calls down devastating lightning bolts from the heavens.

@export var base_damage: float = 45.0
@export var base_cooldown: float = 2.4
@export var strike_count: int = 1
@export var attack_range: float = 500.0
@export var is_active: bool = true

var cooldown_timer: float = 1.0
var damage_multiplier: float = 1.0
## Fusion tier multiplier pushed in by UpgradeManager.apply_arsenal_bonuses().
var tier_damage_mult: float = 1.0
var speed_multiplier: float = 1.0
var is_evolved: bool = false

func _process(delta: float) -> void:
	if not is_active:
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		fire_lightning()
		cooldown_timer = max(0.25, base_cooldown / (speed_multiplier * _get_player_attack_speed()))

func fire_lightning() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_targets: Array[Node2D] = []
	var range_sq = attack_range * attack_range
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node2D and not enemy.get("is_dead"):
			if global_position.distance_squared_to(enemy.global_position) <= range_sq:
				valid_targets.append(enemy)
				
	if valid_targets.is_empty():
		return
		
	var targets_to_hit: Array[Node2D] = []
	var count_to_pick = min(strike_count, valid_targets.size())
	for i in range(count_to_pick):
		var pick = valid_targets.pick_random()
		if not targets_to_hit.has(pick):
			targets_to_hit.append(pick)
	
	for target in targets_to_hit:
		if is_instance_valid(target):
			strike_target(target.global_position, target)

func strike_target(pos: Vector2, target: Node2D) -> void:
	SoundManager.play("thunder", 0.15)
	
	# Screen shake on lightning impact
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(7.0)
		
	# Spawn Lightning Bolt Visual (Line2D)
	var line = Line2D.new()
	line.width = 6.0
	line.default_color = Color(0.8, 0.95, 1.0, 1.0)
	
	# Zig-zag bolt from sky
	var current_pt = Vector2(pos.x + randf_range(-40, 40), pos.y - 700.0)
	line.add_point(current_pt)
	for seg in range(6):
		var progress = float(seg + 1) / 6.0
		var next_pt = current_pt.lerp(pos, progress) + Vector2(randf_range(-25, 25), 0)
		line.add_point(next_pt)
	line.add_point(pos)
	
	get_tree().current_scene.add_child(line)
	
	# Fade out bolt
	var tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(line.queue_free)
	
	# Electric spark particles at ground zero
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 14
	particles.lifetime = 0.3
	particles.explosiveness = 0.9
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.color = Color(0.4, 0.85, 1.0)
	particles.global_position = pos
	get_tree().current_scene.add_child(particles)
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(particles.queue_free)
	
	# Apply damage & knockback
	var total_dmg = base_damage * damage_multiplier * tier_damage_mult * _get_player_might()
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(total_dmg, pos)
		GameManager.record_weapon_damage("lightning", total_dmg)

	# Evolved AoE shockwave: deals 60% splash damage to surrounding enemies
	if is_evolved:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e != target and e is Node2D and not e.get("is_dead"):
				if pos.distance_to(e.global_position) <= 100.0:
					if e.has_method("take_damage"):
						e.take_damage(total_dmg * 0.6, pos)
						GameManager.record_weapon_damage("lightning", total_dmg * 0.6)

func _get_player_might() -> float:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_might_multiplier"):
		return p.get_might_multiplier()
	return 1.0

## Expansion 22.0: Tà Ma Lệnh Bài's +15% attack speed below 50% HP. Divided into
## the cooldown here rather than multiplied into speed_multiplier, so the relic
## applies to a weapon bought mid-rage and cannot compound while the player is
## already under the threshold.
func _get_player_attack_speed() -> float:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_attack_speed_multiplier"):
		return p.get_attack_speed_multiplier()
	return 1.0

func upgrade_strikes() -> void:
	strike_count += 1

func upgrade_damage(bonus: float) -> void:
	damage_multiplier += bonus

func evolve_to_heavens_wrath() -> void:
	is_evolved = true
	is_active = true
	# A floor, not an assignment. "Lôi Đình Vạn Quân" adds to this field at ranks 1-4
	# and the evolution is only offered at rank 5, so a full build arrives here at 5
	# and a bare `=` handed it back 4. Same fault as orbit_speed in the sibling file;
	# see Expansion 44.0 in the README.
	strike_count = maxi(strike_count, 4)
	base_damage = 90.0
	base_cooldown = 1.1
	SoundManager.play("powerup", 0.25)
	FloatingText.spawn(global_position + Vector2(0, -45), "⚡ EVOLVED: HEAVEN'S WRATH! ⚡", Color(0.4, 0.9, 1.0))

