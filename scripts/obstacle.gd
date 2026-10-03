class_name WorldObstacle
extends StaticBody2D

## World Obstacle: Physical pillars, fire braziers, and ancient tombs that block pathing and add tactical kiting terrain.

@export_enum("pillar", "brazier", "tomb") var obstacle_type: String = "pillar"
@export var coin_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var fire_particles: CPUParticles2D = get_node_or_null("FireParticles")

var is_broken: bool = false

func _ready() -> void:
	add_to_group("obstacles")
	_setup_obstacle()

func _setup_obstacle() -> void:
	var tex_path = "res://assets/textures/pillar.png"
	match obstacle_type:
		"brazier":
			tex_path = "res://assets/textures/brazier.png"
			if fire_particles:
				fire_particles.emitting = true
				fire_particles.color = Color(1.0, 0.6, 0.1, 0.8)
		"tomb":
			tex_path = "res://assets/textures/tomb.png"
			if fire_particles:
				fire_particles.emitting = false
		"pillar":
			tex_path = "res://assets/textures/pillar.png"
			if fire_particles:
				fire_particles.emitting = false
				
	if ResourceLoader.exists(tex_path) and sprite:
		sprite.texture = load(tex_path)

func break_tomb() -> void:
	if obstacle_type != "tomb" or is_broken:
		return
	is_broken = true
	SoundManager.play("hit", 0.2)
	# Spawn a gold coin
	if coin_scene:
		var coin = coin_scene.instantiate()
		coin.global_position = global_position
		# "gold_value", not "coin_value". The enemy declares @export var coin_value
		# and the coin it pays out declares @export var gold_value -- two classes,
		# two names -- and this wrote the enemy's name onto the coin. Object.set()
		# on a property that does not exist is a silent no-op: no error, no return
		# value, the coin simply keeps its default of 1. Measured 2026-10-01, so
		# every tomb paid 1 gold instead of 3 and scripts/ci.sh's `SCRIPT ERROR:`
		# grep never saw it, because nothing was ever reported. The guard this
		# replaced, `coin.has_method("set")`, was worse than nothing: every Object
		# has set(), so it always passed and read like a check that had happened.
		coin.set("gold_value", 3)
		get_tree().current_scene.call_deferred("add_child", coin)
	# Fade modulate slightly
	modulate = Color(0.6, 0.6, 0.6, 0.8)
