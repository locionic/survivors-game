class_name TreasureGoblin
extends CharacterBody2D

## TreasureGoblin: A speedy elusive golden creature that drops gold when hit and a mega chest + relic if slain before escaping.

@export var max_health: float = 75.0
@export var move_speed: float = 175.0
@export var escape_time: float = 20.0
@export var chest_scene: PackedScene = preload("res://scenes/chest.tscn")
@export var coin_scene: PackedScene = preload("res://scenes/coin.tscn")
@export var relic_scene: PackedScene = preload("res://scenes/relic_pickup.tscn")

var current_health: float = 75.0
var player: Node2D = null
var is_dead: bool = false
var anim_time: float = 0.0
var time_until_escape: float = 20.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var timer_label: Label = $TimerLabel
@onready var particles: CPUParticles2D = $GoldTrail

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("goblins")
	current_health = max_health
	time_until_escape = escape_time
	player = get_tree().get_first_node_in_group("player")
	
	if sprite:
		sprite.modulate = Color(1.0, 0.88, 0.2) # Golden glimmer
		
	if particles:
		particles.emitting = true
		particles.color = Color(1.0, 0.85, 0.2, 0.8)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	anim_time += delta
	time_until_escape -= delta
	
	if timer_label:
		timer_label.text = "🏃 %ds" % max(0, int(ceil(time_until_escape)))
		
	if time_until_escape <= 0.0:
		_escape()
		return
		
	if is_instance_valid(player):
		# Run away from the player in panic
		var flee_dir = -global_position.direction_to(player.global_position)
		# Add erratic zigzag wobble
		var wobble = Vector2(-flee_dir.y, flee_dir.x) * sin(anim_time * 12.0) * 0.4
		var move_dir = (flee_dir + wobble).normalized()
		
		velocity = move_dir * move_speed
		move_and_slide()
		
		if sprite:
			sprite.flip_h = velocity.x < 0
			var bounce = sin(anim_time * 18.0) * 0.15
			sprite.scale = Vector2(1.2 * (1.0 + bounce), 1.2 * (1.0 - bounce))

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
		
	current_health -= amount
	FloatingText.spawn(global_position, "💰 " + str(int(amount)), Color(1.0, 0.9, 0.2))
	SoundManager.play("coin", 0.05)
	
	# Drop a gold coin every time hit
	if coin_scene and randf() < 0.85:
		var coin = coin_scene.instantiate()
		if coin:
			coin.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))
			get_tree().current_scene.call_deferred("add_child", coin)
			
	# Damage flash
	modulate = Color(2.5, 2.5, 1.5)
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if current_health <= 0:
		die()

func _escape() -> void:
	is_dead = true
	FloatingText.spawn(global_position + Vector2(0, -30), "💨 GOBLIN ESCAPED! 💨", Color(0.8, 0.8, 0.8))
	SoundManager.play("shoot", 0.2)
	
	var p = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 20
	p.lifetime = 0.4
	p.spread = 180.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 160.0
	p.color = Color(1.0, 0.9, 0.4)
	p.global_position = global_position
	get_tree().current_scene.add_child(p)
	
	var t = get_tree().create_timer(0.5)
	t.timeout.connect(p.queue_free)
	queue_free()

func die() -> void:
	is_dead = true
	# The second argument credits the "Slay an Elite Champion" bounty. A Treasure Goblin
	# is not a champion of any kind, and this passed a hardcoded true, so every goblin
	# completed a second bounty on top of the one "goblin" already earns. False is
	# stated rather than left to the default so the rejection reads as deliberate.
	GameManager.add_kill("goblin", false)
	GameManager.add_gold(80)
	_award_dragon_soul()

	FloatingText.spawn(global_position + Vector2(0, -40), "👑 GOBLIN SLAIN! +80 GOLD 👑", Color(1.0, 0.85, 0.2))
	SoundManager.play("powerup", 0.3)
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(14.0)
		
	# Spawn guaranteed mega rewards
	if chest_scene:
		var chest = chest_scene.instantiate()
		chest.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", chest)
		
	if relic_scene:
		var relic = relic_scene.instantiate()
		relic.global_position = global_position + Vector2(0, 28)
		get_tree().current_scene.call_deferred("add_child", relic)
		
	if coin_scene:
		for i in range(10):
			var coin = coin_scene.instantiate()
			var angle = (float(i) / 10.0) * TAU
			coin.global_position = global_position + Vector2(cos(angle), sin(angle)) * randf_range(20.0, 60.0)
			get_tree().current_scene.call_deferred("add_child", coin)

	queue_free()

## Long Hồn (dragon soul), 15 of the 100-point bar -- against 2 for a trash mob, 12
## for a champion and 35 for a boss.
##
## This award used to live in enemy.gd, on an elif that could never fire. A
## TreasureGoblin is its own class and does not extend Enemy, so enemy.gd's die()
## never runs for one, and both of that branch's disjuncts were false besides:
## `enemy_type` is not a member there at all but a local (enemy.gd:691) that can
## only ever hold "bat", "skeleton" or ""; and the other tested a node name only a
## goblin has, on a goblin that never runs enemy.gd. Every goblin therefore paid 0
## soul -- on the loudest kill in the run, the one that drops a guaranteed mega
## chest, a relic and ten coins for 80 gold.
##
## Split out of die() on purpose: the payout above runs through add_gold(), which
## saves to user://save_data.cfg unconditionally, so this is the only part of a
## goblin's death that a test can measure without writing outside the repo.
func _award_dragon_soul() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if is_instance_valid(p) and p.has_method("add_dragon_soul"):
		p.add_dragon_soul(15.0)
