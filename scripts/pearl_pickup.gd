class_name PearlPickup
extends Area2D

## Collectible Dragon Pearl (Long Châu) for summoning Thần Long (Shenron).

@export var pearl_index: int = 1
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var halo: Node2D = get_node_or_null("Halo")

var time_passed: float = 0.0
var target: Node2D = null
var current_speed: float = 80.0

func _ready() -> void:
	add_to_group("pearls")
	time_passed = randf() * 10.0
	body_entered.connect(_on_body_entered)
	
	# Spawn scale-in bounce
	scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)

func _process(delta: float) -> void:
	time_passed += delta
	
	if is_instance_valid(target):
		current_speed += 900.0 * delta
		global_position = global_position.move_toward(target.global_position, current_speed * delta)
		if global_position.distance_to(target.global_position) < 20.0:
			_collect()
		return
		
	# Floating bob and gentle rotation
	if sprite:
		sprite.position.y = sin(time_passed * 4.5) * 4.0
		sprite.rotation = sin(time_passed * 2.0) * 0.15
	if halo:
		var pulse = 1.0 + 0.25 * sin(time_passed * 6.0)
		halo.scale = Vector2(pulse, pulse)

func _draw() -> void:
	# Outer glowing aura ring
	draw_circle(Vector2(0, 4), 14.0, Color(1.0, 0.75, 0.1, 0.25))
	draw_arc(Vector2(0, 4), 15.0, 0, TAU, 24, Color(1.0, 0.85, 0.2, 0.7), 2.0)

func target_player(player_ref: Node2D) -> void:
	target = player_ref

func _collect() -> void:
	if GameManager:
		GameManager.collect_dragon_pearl()
		FloatingText.spawn(global_position + Vector2(0, -20), "⭐ LONG CHÂU [%d/7]" % GameManager.dragon_pearls_collected, Color(1.0, 0.85, 0.2))
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()
