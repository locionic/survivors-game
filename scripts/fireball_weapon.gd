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

## The AoE radius bought *during a run*: the Liệt Hỏa Phần Thiên card and the
## Apocalypse Meteor's own widening. It is deliberately not part of
## blast_radius_multiplier, because Player.refresh_meta_stats() **reassigns** that
## field to rebuild the character / meridian / meta AoE sources and it has twelve
## call sites -- one of which, GameManager.equip_gear(), is free and repeatable.
## A bonus written straight onto blast_radius_multiplier was therefore refunded to
## zero the moment the player bought a radius card and then opened the meta shop or
## toggled a piece of gear. Same contract as the player's run_max_hp_bonus and
## run_might_bonus: a run-scoped source gets its own field and rides in the
## expression, so a rebuild folds it back in instead of erasing it.
var run_blast_radius_bonus: float = 0.0:
	set(value):
		run_blast_radius_bonus = value
		# Expansion 48.0: the fold-in below only ever ran when something *else* called
		# refresh_meta_stats() -- a relic pickup, a meta purchase, a gear toggle. Both
		# writers here are on the level-up path and neither reached it, so the card and
		# the evolution banked their width and fired the old blast size until the
		# player happened to open the meta shop. Rebuilding on the write rather than in
		# the two writers is what makes this true for the next writer too.
		var p := get_tree().get_first_node_in_group("player") if get_tree() else null
		if p and p.has_method("refresh_meta_stats"):
			p.refresh_meta_stats()

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
		cooldown_timer = max(0.22, base_cooldown / (speed_multiplier * _get_player_attack_speed()))

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

## Expansion 22.0: Tà Ma Lệnh Bài's +15% attack speed below 50% HP. Divided into
## the cooldown here rather than multiplied into speed_multiplier, so the relic
## applies to a weapon bought mid-rage and cannot compound while the player is
## already under the threshold.
func _get_player_attack_speed() -> float:
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("get_attack_speed_multiplier"):
		return p.get_attack_speed_multiplier()
	return 1.0

func upgrade_count() -> void:
	fireball_count += 1

func upgrade_damage(bonus: float) -> void:
	damage_multiplier += bonus

func upgrade_blast_radius(bonus: float) -> void:
	run_blast_radius_bonus += bonus

func upgrade_fire_rate(bonus: float) -> void:
	speed_multiplier += bonus

func evolve_to_apocalypse_meteor() -> void:
	is_evolved = true
	is_active = true
	# A floor, not an assignment. "Tam Muội Chân Hỏa" adds to this field at ranks 1-4
	# and the evolution is only offered at rank 5, so a full build arrives here at 5
	# and a bare `=` handed it back 3. Same fault as orbit_speed in the sibling file;
	# see Expansion 44.0 in the README.
	fireball_count = maxi(fireball_count, 3)
	base_cooldown = 1.1
	damage_multiplier = 2.4
	# The evolved Cầu Lửa opens out to 2.2x its own base, so the run-scoped half
	# carries the 1.2 above the 1.0 floor. It used to assign blast_radius_multiplier
	# outright, which read correctly until the next refresh_meta_stats() -- from a
	# meta purchase, a codex unlock, or simply re-equipping a piece of gear -- put
	# the radius straight back to the un-evolved number. damage_multiplier is safe
	# from all of that because nothing rebuilds it, which is exactly the asymmetry:
	# evolving the fireball reliably widened its damage and silently lost its width.
	run_blast_radius_bonus += 1.2
	SoundManager.play("powerup", 0.25)
	FloatingText.spawn(global_position + Vector2(0, -45), "☄️ EVOLVED: APOCALYPSE METEOR! ☄️", Color(1.0, 0.45, 0.1))

