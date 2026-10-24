class_name ExperienceGem
extends Area2D

## Collectible XP Gem dropped by defeated enemies with satisfying loot pop physics.

@export var xp_value: float = 1.0
@export var base_fly_speed: float = 350.0

var target: Node2D = null
var current_speed: float = 50.0
var toss_vel: Vector2 = Vector2.ZERO
var toss_timer: float = 0.22
var bob_time: float = 0.0

## Milestone 3b: ceiling on live gem nodes. Every gem is an Area2D running its own
## _process, its own magnet check and its own pickup signal; a 40-bat swarm used
## to leave 150+ of them littering the arena. Past this many, a new gem folds
## its XP into the closest one on the floor and frees itself -- the player is
## paid in full, there are just fewer nodes to pay them.
const MAX_ACTIVE_GEMS: int = 45
const MERGE_RADIUS: float = 160.0
## Squared once here: the search runs per gem drop and the radius never changes.
const MERGE_RADIUS_SQ: float = MERGE_RADIUS * MERGE_RADIUS

func _ready() -> void:
	add_to_group("gems")
	if _absorb_into_neighbour():
		return

	if GameManager and GameManager.selected_stage == "zombie_city":
		var spr = get_node_or_null("Sprite2D")
		if spr and ResourceLoader.exists("res://assets/textures/bio_vial.png"):
			spr.texture = load("res://assets/textures/bio_vial.png")

	# Magnet arc trail: glowing jade fragments trailing behind during magnetic pull
	var trail = CPUParticles2D.new()
	trail.name = "MagnetTrail"
	trail.amount = 8
	trail.lifetime = 0.3
	trail.pre_process_time = 0.0
	trail.explosiveness = 0.8
	trail.speed_scale = 0.5
	trail.direction = Vector2.ZERO
	trail.gravity = Vector2.ZERO
	trail.spread = 0.0
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 30.0
	trail.scale_amount_min = 0.3
	trail.scale_amount_max = 0.6
	trail.color = Color(0.4, 1.0, 0.6, 0.8)
	trail.color_ramp = Gradient.new()
	trail.color_ramp.set_offsets(PackedFloat32Array([0.0, 1.0]))
	trail.color_ramp.set_colors(PackedColorArray([Color(0.5, 1.0, 0.7, 0.9), Color(0.3, 0.8, 0.4, 0.0)]))
	trail.emitting = false
	trail.z_index = 10
	add_child(trail)

	# Kinetic pop impulse in random outward direction
	var angle = randf() * TAU
	var speed = randf_range(60.0, 130.0)
	toss_vel = Vector2(cos(angle), sin(angle)) * speed

	# Squash-and-stretch pop tween on spawn (proportional 16px gem)
	scale = Vector2(0.2, 0.2)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(0.65, 0.65), 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(0.5, 0.5), 0.10)

func _process(delta: float) -> void:
	bob_time += delta * 4.0
	
	if is_instance_valid(target):
		current_speed += 950.0 * delta
		var dist = global_position.distance_to(target.global_position)
		global_position = global_position.move_toward(target.global_position, current_speed * delta)
		# Smooth magnetic suction squash
		var suction = clampf(dist / 40.0, 0.35, 1.0)
		scale = Vector2(0.5, 0.5) * suction
		
		# Emit magnet arc trail particles during pull
		var trail = get_node_or_null("MagnetTrail")
		if trail:
			trail.emitting = true
			trail.global_position = global_position
		if dist < 18.0:
			collect()
	elif toss_timer > 0.0:
		toss_timer -= delta
		global_position += toss_vel * delta
		toss_vel = toss_vel.move_toward(Vector2.ZERO, 400.0 * delta)
	else:
		# Subtle vertical gleam bob
		position.y += sin(bob_time) * 0.15

## Milestone 3b: the per-node drop shadow is gone (45+ shadowed circles a frame
## is real fill-rate for a shadow nobody sees under a moving magnet pull). This
## folds the new gem into the closest live one once the floor is saturated.
## Returns true when this node merged itself away and should not run.
func _absorb_into_neighbour() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var live := 0
	var best: ExperienceGem = null
	var best_dist := MERGE_RADIUS_SQ
	for other in tree.get_nodes_in_group("gems"):
		# coin.gd shares this group -- a gold coin must never be eaten by a gem.
		# A gem that already handed its XP away is still in the group until the
		# frame ends, so it must not count as live NOR be folded into: that is
		# how 80 drops turned into 80 nodes carrying 115 XP.
		if other is ExperienceGem and other != self and is_instance_valid(other) \
				and not other.is_queued_for_deletion():
			live += 1
			var d := global_position.distance_squared_to(other.global_position)
			if d < best_dist:
				best_dist = d
				best = other
	if live < MAX_ACTIVE_GEMS or best == null:
		return false
	best.xp_value += xp_value
	queue_free()
	return true

func target_player(player_ref: Node2D) -> void:
	target = player_ref

static var _gem_streak_count: int = 0
static var _last_gem_time: float = 0.0

const PITCH_SCALE_STEPS: Array[float] = [
	1.0,        # Root C
	1.12246,    # D
	1.25992,    # E
	1.33484,    # F
	1.49831,    # G
	1.68179,    # A
	1.88775,    # B
	2.0,        # High C (Octave)
	2.24492,    # High D
	2.51984     # High E
]

func collect() -> void:
	if is_instance_valid(target) and target.has_method("add_xp"):
		var now = Time.get_ticks_msec() / 1000.0
		if now - _last_gem_time < 0.85:
			_gem_streak_count += 1
		else:
			_gem_streak_count = 0
		_last_gem_time = now
		
		var pitch_idx = mini(_gem_streak_count, PITCH_SCALE_STEPS.size() - 1)
		var pitch = PITCH_SCALE_STEPS[pitch_idx]
		if SoundManager and SoundManager.has_method("play_pitched"):
			SoundManager.play_pitched("gem", pitch)
		elif SoundManager:
			SoundManager.play("gem", 0.08)
		target.add_xp(xp_value)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		collect()
