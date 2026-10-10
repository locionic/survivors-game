class_name GoldCoin
extends Area2D

## Collectible Gold Coin with drop shadow and kinetic loot pop physics.

@export var gold_value: int = 1
@export var base_fly_speed: float = 300.0

var target: Node2D = null
var current_speed: float = 40.0
var toss_vel: Vector2 = Vector2.ZERO
var toss_timer: float = 0.24

## Where the flight began, and which way it bows. Anchored once when the magnet
## catches the coin -- re-anchoring every frame would collapse the chord to a
## per-frame step and the bow would vanish. Same easing curve as the gem, so a
## fan of loot pulled in by a super magnet curves as one gesture.
var _flight_from: Vector2 = Vector2.ZERO
var _flight_side: float = 1.0
var _flight_time: float = 0.0
var _trail: CPUParticles2D = null

## The arc is a fraction of the run, not a fixed offset: a coin dragged across the
## floor bows noticeably, one lifted the last ten pixels leans in. sqrt keeps the
## midpoint bulge steady while that term grows.
const FLIGHT_ARC: float = 0.34
const FLIGHT_DURATION: float = 0.26

func _ready() -> void:
	add_to_group("coins")
	add_to_group("gems") # Handled by magnet
	
	# Kinetic pop impulse in random outward direction
	var angle = randf() * TAU
	var speed = randf_range(50.0, 120.0)
	toss_vel = Vector2(cos(angle), sin(angle)) * speed
	
	# Gentle hover loop & initial pop
	scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.14).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)
	
	var hover = create_tween().set_loops()
	hover.tween_property(self, "scale", Vector2(1.15, 1.15), 0.35)
	hover.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35)

func _process(delta: float) -> void:
	if is_instance_valid(target):
		# An eased arc across the chord the coin was caught on. Deliberately does
		# NOT write scale: the hover loop in _ready() owns that property forever,
		# and a per-frame write would fight it into a visible stutter.
		_flight_time = minf(_flight_time + delta, FLIGHT_DURATION)
		var progress := ease(_flight_time / FLIGHT_DURATION, Tween.TRANS_CUBIC)
		var chord := target.global_position - _flight_from
		var bow := chord.orthogonal().normalized() * _flight_side * FLIGHT_ARC * sqrt(chord.length())
		# The bulge is what decays to zero: by the last quarter of the flight the
		# coin is on the straight line into the player.
		bow *= (1.0 - progress)
		global_position = _flight_from.lerp(target.global_position, progress) + bow
		if _trail == null:
			_start_trail()
		if global_position.distance_to(target.global_position) < 18.0:
			collect()
	elif toss_timer > 0.0:
		toss_timer -= delta
		global_position += toss_vel * delta
		toss_vel = toss_vel.move_toward(Vector2.ZERO, 380.0 * delta)

func _draw() -> void:
	# Subtle drop shadow beneath coin
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.40))
	draw_circle(Vector2.ZERO, 6.0, Color(0.0, 0.0, 0.0, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func target_player(player_ref: Node2D) -> void:
	if is_instance_valid(player_ref) and target != player_ref:
		_begin_flight()
	target = player_ref

## Anchors the arc. Once per catch, never per frame -- see the note on
## _flight_from. The side is a coin flip so a spread of coins fans out on the way
## in instead of stacking into one line.
func _begin_flight() -> void:
	_flight_from = global_position
	_flight_time = 0.0
	_flight_side = 1.0 if randf() < 0.5 else -1.0

## A stub of light left behind on the run in. A CHILD of the coin on purpose:
## child nodes do not inherit groups, so the milestone 3b swarm cap and the
## companion vacuum's group scans can never see or count it as loot.
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
	_trail.color = Color(1.0, 0.86, 0.35, 0.8)
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

func collect() -> void:
	GameManager.add_gold(gold_value)
	SoundManager.play("coin", 0.1)
	FloatingText.spawn(global_position, "+%d" % gold_value, Color(1.0, 0.85, 0.2))
	_sparkle()
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Only the 18px proximity test in _process may cash this coin in. Collecting
	# here fired on first touch of the 8px pickup body and swallowed the coin whole
	# seconds before the magnet finished pulling it, which is the invisible pickup
	# this flight exists to make visible.
	if body.is_in_group("player") and target != body:
		_begin_flight()
		target = body
