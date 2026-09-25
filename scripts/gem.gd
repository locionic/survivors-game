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

func _ready() -> void:
	add_to_group("gems")
	
	# Kinetic pop impulse in random outward direction
	var angle = randf() * TAU
	var speed = randf_range(60.0, 130.0)
	toss_vel = Vector2(cos(angle), sin(angle)) * speed
	
	# Squash-and-stretch pop tween on spawn
	scale = Vector2(0.4, 0.4)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)

func _process(delta: float) -> void:
	bob_time += delta * 4.0
	
	if is_instance_valid(target):
		current_speed += 850.0 * delta
		global_position = global_position.move_toward(target.global_position, current_speed * delta)
		if global_position.distance_to(target.global_position) < 18.0:
			collect()
	elif toss_timer > 0.0:
		toss_timer -= delta
		global_position += toss_vel * delta
		toss_vel = toss_vel.move_toward(Vector2.ZERO, 400.0 * delta)
	else:
		# Subtle vertical gleam bob
		position.y += sin(bob_time) * 0.15

func _draw() -> void:
	# Subtle drop shadow beneath gem
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.40))
	draw_circle(Vector2.ZERO, 5.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
