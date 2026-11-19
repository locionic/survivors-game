class_name ToxicProjectile
extends Area2D

## Toxic Projectile:
## Corrosive acid glob fired by Toxic Spitters and Mutant Bosses.
## On contact with the player or on expiration, it splashes into a persistent Toxic Bile Puddle!

@export var speed: float = 175.0
@export var damage: float = 12.0
@export var lifetime: float = 3.2
@export var puddle_scene: PackedScene = preload("res://scenes/toxic_bile_puddle.tscn")

var direction: Vector2 = Vector2.RIGHT
var is_detonated: bool = false

func _ready() -> void:
	add_to_group("enemy_projectiles")
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_detonate_and_splash)

func _physics_process(delta: float) -> void:
	if is_detonated:
		return
	global_position += direction * speed * delta
	if has_node("Sprite2D"):
		$Sprite2D.rotation += 9.0 * delta

func _on_body_entered(body: Node2D) -> void:
	if is_detonated:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		_detonate_and_splash()

func _detonate_and_splash() -> void:
	if is_detonated:
		return
	is_detonated = true
	
	if puddle_scene and get_tree():
		var parent = get_tree().current_scene if get_tree().current_scene else get_parent()
		if parent:
			var puddle = puddle_scene.instantiate()
			if puddle:
				puddle.global_position = global_position
				parent.call_deferred("add_child", puddle)
	
	# Acid splash particle burst
	var splash = CPUParticles2D.new()
	splash.emitting = true
	splash.one_shot = true
	splash.explosiveness = 0.92
	splash.amount = 14
	splash.lifetime = 0.35
	splash.spread = 180.0
	splash.initial_velocity_min = 40.0
	splash.initial_velocity_max = 90.0
	splash.scale_amount_min = 2.0
	splash.scale_amount_max = 4.0
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(0.5, 1.0, 0.35, 1.0), Color(0.15, 0.7, 0.25, 0.0)])
	splash.color_ramp = grad
	splash.global_position = global_position
	splash.z_index = 850
	
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(splash)
		var t = get_tree().create_timer(0.4)
		t.timeout.connect(splash.queue_free)
		
	SoundManager.play("hit", 0.15)
	queue_free()
