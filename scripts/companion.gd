class_name Companion
extends CharacterBody2D

## Martial Spirit Companion (Linh Thú / Đồng Hành) fighting alongside the hero and vacuuming loot.

@export var companion_id: String = "dragon_whelp" # "dragon_whelp" or "white_tiger"
@export var companion_name: String = "Tiểu Kim Long"
@export var attack_interval: float = 1.35
@export var attack_damage: float = 28.0
@export var attack_range: float = 240.0
@export var vacuum_radius: float = 175.0

var player: CharacterBody2D = null
var anim_time: float = 0.0
var attack_timer: float = 0.5
var vacuum_timer: float = 0.1
var target_offset: Vector2 = Vector2(-36.0, -28.0)
var level: int = 1

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var nameplate: Label = get_node_or_null("Nameplate")

func _ready() -> void:
	add_to_group("companions")
	player = get_tree().get_first_node_in_group("player")
	apply_companion_type(companion_id)
	
	if player and player.has_signal("leveled_up"):
		player.leveled_up.connect(_on_player_leveled_up)
	if GameManager:
		GameManager.companion_changed.connect(set_companion)

func set_companion(type_id: String) -> void:
	companion_id = type_id
	apply_companion_type(type_id)

func apply_companion_type(type_id: String) -> void:
	companion_id = type_id
	match type_id:
		"dragon_whelp":
			companion_name = "Tiểu Kim Long"
			attack_interval = 1.30
			attack_damage = 28.0
			attack_range = 250.0
			if sprite:
				var tex_path = "res://assets/textures/companion_dragon.png"
				if ResourceLoader.exists(tex_path):
					sprite.texture = load(tex_path)
				elif FileAccess.file_exists(tex_path):
					var img = Image.load_from_file(tex_path)
					if img:
						sprite.texture = ImageTexture.create_from_image(img)
		"white_tiger":
			companion_name = "Bạch Hổ Thần Thú"
			attack_interval = 1.10
			attack_damage = 36.0
			attack_range = 190.0
			if sprite:
				var tex_path = "res://assets/textures/companion_tiger.png"
				if ResourceLoader.exists(tex_path):
					sprite.texture = load(tex_path)
				elif FileAccess.file_exists(tex_path):
					var img = Image.load_from_file(tex_path)
					if img:
						sprite.texture = ImageTexture.create_from_image(img)
						
	if nameplate:
		nameplate.text = companion_name
		nameplate.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if type_id == "dragon_whelp" else Color(0.4, 0.9, 1.0))

func _physics_process(delta: float) -> void:
	anim_time += delta
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
		
	# Smooth following physics with hovering oscillation
	var hover_y = sin(anim_time * 4.5) * 5.0
	var follow_target = player.global_position + target_offset + Vector2(0.0, hover_y)
	global_position = global_position.lerp(follow_target, delta * 6.5)
	
	# Sprite direction and wing/body flutter
	if sprite:
		if player.velocity.x != 0:
			sprite.flip_h = player.velocity.x < 0
		if companion_id == "dragon_whelp":
			var wing_flutter = sin(anim_time * 16.0) * 0.12
			sprite.scale = Vector2(1.0 + wing_flutter, 1.0 - wing_flutter)
		else:
			var pounce_bob = abs(sin(anim_time * 6.0)) * 0.10
			sprite.scale = Vector2(1.0 - pounce_bob, 1.0 + pounce_bob)

	# Periodic magnetic loot vacuum
	vacuum_timer -= delta
	if vacuum_timer <= 0.0:
		vacuum_timer = 0.15
		_vacuum_nearby_loot()
		
	# Autonomous combat attack
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = attack_interval
		_execute_companion_attack()

func _vacuum_nearby_loot() -> void:
	if not is_instance_valid(player):
		return
	var v_sq = vacuum_radius * vacuum_radius
	
	# Attract XP gems towards player
	var gems = get_tree().get_nodes_in_group("gems")
	for g in gems:
		if is_instance_valid(g) and global_position.distance_squared_to(g.global_position) <= v_sq:
			if g.has_method("target_player"):
				g.target_player(player)
				
	# Auto-gather coins
	var coins = get_tree().get_nodes_in_group("coins")
	for c in coins:
		if is_instance_valid(c) and global_position.distance_squared_to(c.global_position) <= v_sq:
			if c.has_method("target_player"):
				c.target_player(player)
			elif global_position.distance_to(c.global_position) < 45.0:
				if GameManager and "gold_value" in c:
					GameManager.add_gold(c.gold_value)
				SoundManager.play("coin", 0.15)
				c.queue_free()

func _execute_companion_attack() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_target: Node2D = null
	var min_dist_sq: float = attack_range * attack_range
	
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			var d_sq = global_position.distance_squared_to(e.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				best_target = e
				
	if not best_target:
		return
		
	var might = player.get_might_multiplier() if (player and player.has_method("get_might_multiplier")) else 1.0
	var final_dmg = (attack_damage + float(level * 4)) * might
	
	if companion_id == "dragon_whelp":
		_dragon_whelp_attack(best_target, final_dmg)
	else:
		_white_tiger_attack(best_target, final_dmg)

func _dragon_whelp_attack(target: Node2D, dmg: float) -> void:
	SoundManager.play("pet_attack", 0.15)
	var dir = global_position.direction_to(target.global_position)
	
	# Spawn glowing Chi Orb projectile
	var p = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.amount = 14
	p.lifetime = 0.3
	p.spread = 45.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(1.0, 0.85, 0.2)
	p.global_position = global_position
	get_tree().current_scene.add_child(p)
	var t = get_tree().create_timer(0.35)
	t.timeout.connect(p.queue_free)
	
	if target.has_method("take_damage"):
		target.take_damage(dmg, global_position)
	if target.has_method("apply_burn") and randf() < 0.40:
		target.apply_burn(3.0, 16.0)
	FloatingText.spawn(target.global_position + Vector2(0, -18), "🐉 %d" % int(dmg), Color(1.0, 0.85, 0.2))

func _white_tiger_attack(target: Node2D, dmg: float) -> void:
	SoundManager.play("pet_attack", 0.2)
	var dir = global_position.direction_to(target.global_position)
	
	# Pounce slash particles
	var p = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.amount = 16
	p.lifetime = 0.25
	p.spread = 90.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 160.0
	p.initial_velocity_max = 280.0
	p.scale_amount_min = 2.5
	p.scale_amount_max = 5.0
	p.color = Color(0.4, 0.9, 1.0)
	p.global_position = target.global_position
	get_tree().current_scene.add_child(p)
	var t = get_tree().create_timer(0.3)
	t.timeout.connect(p.queue_free)
	
	if target.has_method("take_damage"):
		target.take_damage(dmg, global_position)
	if "knockback" in target:
		target.knockback = dir * 380.0
	FloatingText.spawn(target.global_position + Vector2(0, -18), "🐅 %d" % int(dmg), Color(0.4, 0.9, 1.0))

func _on_player_leveled_up(_new_lvl: int) -> void:
	level += 1
	attack_damage += 2.5
	vacuum_radius = min(320.0, vacuum_radius + 6.0)
	FloatingText.spawn(global_position + Vector2(0, -24), "★ %s Lv.%d! ★" % [companion_name, level], Color(1.0, 0.9, 0.2))

func _draw() -> void:
	# Soft ellipse drop shadow beneath companion
	draw_set_transform(Vector2(0, 11), 0.0, Vector2(1.1, 0.45))
	draw_circle(Vector2.ZERO, 9.0, Color(0.0, 0.0, 0.0, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

