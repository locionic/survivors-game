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

## Where the flight began, and the bow the arc bows to. Set the first time the
## magnet catches this gem and then held, so the bow is the pickup's own and not
## recomputed from a player who is already moving.
var _flight_from: Vector2 = Vector2.ZERO
var _flight_side: float = 1.0
var _flight_time: float = 0.0
var _trail: CPUParticles2D = null

## The arc is a fraction of the run, not a fixed offset: a coin pulled across the
## floor bows noticeably, a gem lifted the last ten pixels leans in. sqrt keeps
## the midpoint bulge steady while that term grows.
const FLIGHT_ARC: float = 0.34
const FLIGHT_DURATION: float = 0.26

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
		var dist := global_position.distance_to(target.global_position)
		# An eased arc across the chord the pickup was caught on, not a straight
		# slide: the bow is widest halfway and flattens to zero on arrival, so the
		# gem curves in rather than skidding. The chord is measured from where the
		# flight began but re-drawn to wherever the player is now, so a moving
		# target is still caught.
		_flight_time = minf(_flight_time + delta, FLIGHT_DURATION)
		var progress := ease(_flight_time / FLIGHT_DURATION, Tween.TRANS_CUBIC)
		var chord := target.global_position - _flight_from
		var bow := chord.orthogonal().normalized() * _flight_side * FLIGHT_ARC * sqrt(chord.length())
		# The bulge is what decays to zero: by the last quarter of the flight the
		# gem is on the straight line into the player.
		bow *= (1.0 - progress)
		global_position = _flight_from.lerp(target.global_position, progress) + bow
		if _trail == null:
			_start_trail()
		# Smooth magnetic suction squash
		var suction = clampf(dist / 40.0, 0.35, 1.0)
		scale = Vector2(0.5, 0.5) * suction
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
	if is_instance_valid(player_ref) and target != player_ref:
		_begin_flight()
	target = player_ref

## Anchors the arc. Called once, when the magnet catches this gem and not while it
## is already in the air: re-anchoring each frame would collapse the chord to a
## per-frame step and the bow would vanish. The side is a coin flip so a fan of
## gems caught by a super magnet curves outward from each other instead of
## overlapping into a single smeared line.
func _begin_flight() -> void:
	_flight_from = global_position
	_flight_time = 0.0
	_flight_side = 1.0 if randf() < 0.5 else -1.0

## A stub of light left behind on the run in. It is a CHILD of the gem on purpose:
## child nodes do not inherit groups, so a trail can never be counted by the
## milestone 3b swarm cap or picked up by a group scan as loot.
func _start_trail() -> void:
	_trail = CPUParticles2D.new()
	_trail.texture = UpgradeManager.mote_texture()
	_trail.local_coords = false
	_trail.amount = 14
	_trail.lifetime = 0.22
	_trail.spread = 180.0
	_trail.gravity = Vector2.ZERO
	_trail.initial_velocity_min = 4.0
	_trail.initial_velocity_max = 18.0
	_trail.scale_amount_min = 0.7
	_trail.scale_amount_max = 1.5
	_trail.color = Color(0.55, 0.95, 1.0, 0.75)
	_trail.z_index = -1
	add_child(_trail)

## The golden pop at the moment of collection. The award below it is unchanged --
## this only draws the payoff, it does not compute or scale it. Rooted on
## current_scene and null-guarded the same way FloatingText.spawn is, because most
## test suites never set one.
func _sparkle() -> void:
	var tree := get_tree()
	var root := tree.current_scene if tree != null else null
	if root == null:
		return
	var p := CPUParticles2D.new()
	p.texture = UpgradeManager.mote_texture()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 18
	p.lifetime = 0.45
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.damping_min = 120.0
	p.damping_max = 200.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(1.0, 0.86, 0.35, 1.0)
	p.global_position = global_position
	root.call_deferred("add_child", p)
	var t := tree.create_timer(0.6)
	t.timeout.connect(p.queue_free)

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
		_sparkle()
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Only the 18px proximity test in _process may cash this gem in. Collecting
	# here fired on first touch of the 8px pickup body and swallowed the gem whole
	# seconds before the magnet finished pulling it, which is the invisible pickup
	# this flight exists to make visible.
	if body.is_in_group("player") and target != body:
		_begin_flight()
		target = body
