class_name SpiritSwordProjectile
extends Area2D

## Celestial Flying Spirit Sword (Thần Kiếm) fired by Lục Mạch Thần Kiếm or Vạn Kiếm Quy Tông.

@export var speed: float = 620.0
@export var damage: float = 35.0
@export var pierce: int = 3
@export var lifetime: float = 2.5

## Milestone 3: Vạn Kiếm Quy Tông's blades steer onto whatever is closest. Off by
## default so the two straight-line callers (Lục Mạch Thần Kiếm, Shenron Vạn
## Kiếm) keep the flight they were authored with.
@export var homing: bool = false
@export var homing_turn_rate: float = 7.0
@export var homing_range: float = 900.0

var direction: Vector2 = Vector2.RIGHT
var _homing_target: Node2D = null
var _homing_retarget: float = 0.0

func _ready() -> void:
	add_to_group("projectiles")
	var t = get_tree().create_timer(lifetime)
	t.timeout.connect(queue_free)
	rotation = direction.angle() + PI / 2.0 # Texture points upwards

func _physics_process(delta: float) -> void:
	if homing:
		_steer(delta)
	position += direction * speed * delta

## The group lookup is the expensive half, so it re-acquires four times a second
## rather than every frame; a quarter-second-stale target is well inside one
## sword's flight time.
func _steer(delta: float) -> void:
	_homing_retarget -= delta
	if not is_instance_valid(_homing_target) or _homing_target.get("is_dead"):
		_homing_retarget = 0.0
	if _homing_retarget <= 0.0:
		_homing_retarget = 0.25
		_homing_target = _nearest_enemy()
	if not is_instance_valid(_homing_target):
		return

	var to_target := _homing_target.global_position - global_position
	if to_target.length_squared() < 1.0:
		return
	var steered := direction.lerp(to_target.normalized(), clampf(homing_turn_rate * delta, 0.0, 1.0))
	# A dead-on target lerps to zero, and normalizing that would freeze the blade.
	if steered.length_squared() > 0.001:
		direction = steered.normalized()
		rotation = direction.angle() + PI / 2.0

func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := homing_range * homing_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.get("is_dead"):
			continue
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		if randf() < 0.35 and body.has_method("apply_burn"):
			body.apply_burn(2.5, 14.0)
		SoundManager.play("hit", 0.08)
		pierce -= 1
		if pierce <= 0:
			queue_free()
