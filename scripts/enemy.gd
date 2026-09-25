class_name Enemy
extends CharacterBody2D

## Enemy unit with knockback physics, death particles, Champion affixes, telegraphed Boss capabilities,
## and Expansion 20.0 Telegraphed Elite Champions (Tinh Anh Lệnh) with a warn-then-burst shockwave.

signal boss_health_changed(current: float, max_val: float)
signal boss_defeated

@export var max_health: float = 25.0
@export var move_speed: float = 110.0
@export var contact_damage: float = 10.0
@export var knockback_resistance: float = 0.0
@export var is_boss: bool = false
@export var boss_name: String = ""
@export var gem_scene: PackedScene
@export var chest_scene: PackedScene
@export var coin_scene: PackedScene
@export var coin_drop_chance: float = 0.35
@export var coin_value: int = 1
@export var is_ranged: bool = false
@export var projectile_scene: PackedScene
@export var shoot_interval: float = 2.4
@export var preferred_distance: float = 230.0
@export var is_radial_boss: bool = false
@export var radial_interval: float = 3.8
@export var powerup_scene: PackedScene
@export var relic_scene: PackedScene = preload("res://scenes/relic_pickup.tscn")
@export var pearl_scene: PackedScene = preload("res://scenes/pearl_pickup.tscn")
@export var scroll_scene: PackedScene = preload("res://scenes/scroll_pickup.tscn")

# Champion Affix properties
@export var is_champion: bool = false
@export var champion_affix: String = "" # "vampiric", "glacial", "volatile", "swift"
var champ_aura_color: Color = Color.WHITE
var champ_nameplate: Label = null

# Expansion 20.0: Tinh Anh Lệnh — Telegraphed Elite Champion
@export var is_elite_champion: bool = false
@export var elite_burst_radius: float = 190.0
@export var elite_burst_damage: float = 22.0
@export var elite_burst_interval: float = 8.0
@export var elite_telegraph_duration: float = 0.8
var elite_telegraph_timer: float = 8.0
var is_telegraphing_burst: bool = false
var elite_burst_resisted: bool = false
const ELITE_SCALE: float = 1.6
const ELITE_HEALTH_MULT: float = 3.5
const ELITE_GOLD_VALUE: int = 5
const ELITE_GOLD_COINS: int = 10 # 10 x 5 = 50 guaranteed gold

# Boss Telegraphed Attacks
var boss_slam_timer: float = 6.0
var boss_charge_timer: float = 12.0
var is_telegraphing: bool = false
var telegraph_type: String = "" # "slam", "charge"
var telegraph_timer: float = 0.0
var telegraph_duration: float = 1.0
var telegraph_charge_dir: Vector2 = Vector2.ZERO
var charge_duration_remaining: float = 0.0

var current_health: float = 25.0
var player: Node2D = null
var is_dead: bool = false
var damage_cooldown: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var separation_force: Vector2 = Vector2.ZERO
var separation_timer: float = 0.0
var ranged_timer: float = 1.0
var radial_timer: float = 2.0
var anim_time: float = 0.0
var base_sprite_scale: Vector2 = Vector2.ONE
var is_bat_type: bool = false
var is_necro_type: bool = false
var freeze_timer: float = 0.0

# Ngũ Hành (Five Elements) status effects
var burn_timer: float = 0.0
var burn_dps: float = 0.0
var burn_tick_timer: float = 0.0
var poison_timer: float = 0.0
var poison_dps: float = 0.0
var poison_tick_timer: float = 0.0
var slow_timer: float = 0.0
var slow_multiplier: float = 1.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	add_to_group("enemies")
	if is_boss:
		add_to_group("bosses")
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	anim_time = randf() * 10.0
	if sprite:
		base_sprite_scale = sprite.scale
		var path = sprite.texture.resource_path if sprite.texture else ""
		is_bat_type = path.contains("bat") or name.begins_with("Bat")
		is_necro_type = is_ranged or path.contains("necro") or name.begins_with("Necro")
		
	if is_champion and champion_affix != "":
		make_champion(champion_affix)

	if is_elite_champion:
		make_elite_champion()

## Expansion 20.0: Promote this unit to a Tinh Anh Lệnh (Elite Champion):
## 1.6x sprite, 3.5x health, and a telegraphed shockwave burst on a loop.
func make_elite_champion() -> void:
	if elite_burst_resisted:
		return # already promoted
	elite_burst_resisted = true
	is_elite_champion = true
	add_to_group("elite_champions")

	max_health *= ELITE_HEALTH_MULT
	current_health = max_health
	contact_damage *= 1.5
	knockback_resistance = min(0.9, knockback_resistance + 0.3)
	champ_aura_color = Color(1.0, 0.85, 0.15, 0.9)

	# 1.6x the sprite's base scale, and the node itself so hits/hitboxes match
	if sprite:
		base_sprite_scale *= ELITE_SCALE
		sprite.scale = base_sprite_scale
	scale *= ELITE_SCALE

	elite_telegraph_timer = elite_burst_interval
	FloatingText.spawn(global_position + Vector2(0, -46), "⚜️ TINH ANH LỆNH GIÁ THỔNG GIANG! ⚜️", Color(1.0, 0.85, 0.2))

func make_champion(affix: String = "") -> void:
	is_champion = true
	if affix == "":
		var affixes = ["vampiric", "glacial", "volatile", "swift"]
		champion_affix = affixes.pick_random()
	else:
		champion_affix = affix
		
	max_health *= 2.6
	current_health = max_health
	contact_damage *= 1.3
	knockback_resistance = min(0.8, knockback_resistance + 0.35)
	scale = Vector2(1.35, 1.35)
	
	match champion_affix:
		"vampiric":
			champ_aura_color = Color(1.0, 0.2, 0.25, 0.85)
		"glacial":
			champ_aura_color = Color(0.2, 0.9, 1.0, 0.85)
		"volatile":
			champ_aura_color = Color(1.0, 0.55, 0.1, 0.85)
		"swift":
			champ_aura_color = Color(1.0, 0.95, 0.2, 0.85)
			move_speed *= 1.45
			
	if champ_nameplate == null:
		champ_nameplate = Label.new()
		champ_nameplate.text = "★ " + champion_affix.to_upper() + " ★"
		champ_nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		champ_nameplate.add_theme_font_size_override("font_size", 10)
		champ_nameplate.add_theme_color_override("font_color", champ_aura_color)
		champ_nameplate.position = Vector2(-50, -32)
		champ_nameplate.custom_minimum_size = Vector2(100, 16)
		add_child(champ_nameplate)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	anim_time += delta
	if damage_cooldown > 0.0:
		damage_cooldown -= delta

	# Process Ngũ Hành (Five Elements) DoT status effects
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0.0:
			burn_tick_timer = 0.35
			var b_dmg = max(1.0, burn_dps * 0.35)
			current_health -= b_dmg
			FloatingText.spawn(global_position + Vector2(randf_range(-8, 8), -18), str(int(b_dmg)), Color(1.0, 0.45, 0.1))
			if sprite and freeze_timer <= 0.0:
				sprite.modulate = Color(1.8, 0.6, 0.3)
			if is_boss:
				emit_signal("boss_health_changed", current_health, max_health)
			if current_health <= 0:
				die()
				return

	if poison_timer > 0.0:
		poison_timer -= delta
		poison_tick_timer -= delta
		if poison_tick_timer <= 0.0:
			poison_tick_timer = 0.45
			var p_dmg = max(1.0, poison_dps * 0.45)
			current_health -= p_dmg
			FloatingText.spawn(global_position + Vector2(randf_range(-8, 8), -22), str(int(p_dmg)), Color(0.25, 0.95, 0.3))
			if sprite and freeze_timer <= 0.0 and burn_timer <= 0.0:
				sprite.modulate = Color(0.35, 1.6, 0.35)
			if is_boss:
				emit_signal("boss_health_changed", current_health, max_health)
			if current_health <= 0:
				die()
				return

	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_multiplier = 1.0

	if freeze_timer > 0.0:
		freeze_timer -= delta
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		if sprite:
			sprite.modulate = Color(0.4, 0.85, 1.25)
		return

	var dist_sq: float = 9999999.0
	var is_near_screen: bool = true
	if is_instance_valid(player):
		dist_sq = global_position.distance_squared_to(player.global_position)
		is_near_screen = dist_sq < 562500.0 # 750px screen radius

	if is_champion and is_near_screen:
		if Engine.get_physics_frames() % 3 == 0:
			queue_redraw()
		# Glacial champion slowing aura
		if champion_affix == "glacial" and dist_sq < 28900.0:
			player.speed_multiplier = min(player.speed_multiplier, 0.65)

	# --- BOSS TELEGRAPHED COMBAT ---
	if is_boss and is_instance_valid(player):
		queue_redraw()
		if is_telegraphing:
			telegraph_timer -= delta
			velocity = Vector2.ZERO
			move_and_slide()
			
			if telegraph_timer <= 0.0:
				_execute_boss_telegraph()
			return
		elif charge_duration_remaining > 0.0:
			# Charging forward at high speed
			charge_duration_remaining -= delta
			velocity = telegraph_charge_dir * 420.0
			move_and_slide()
			
			if damage_cooldown <= 0.0 and global_position.distance_to(player.global_position) < 85.0:
				if player.has_method("take_damage"):
					player.take_damage(contact_damage * 1.5)
				damage_cooldown = 0.5
			return
		else:
			# Manage cooldowns to initiate telegraphed attacks
			boss_slam_timer -= delta
			if boss_slam_timer <= 0.0:
				is_telegraphing = true
				telegraph_type = "slam"
				telegraph_duration = 1.2
				telegraph_timer = 1.2
				FloatingText.spawn(global_position + Vector2(0, -50), "⚠️ GROUND SLAM! ⚠️", Color(1.0, 0.25, 0.2))
				return
				
			boss_charge_timer -= delta
			if boss_charge_timer <= 0.0:
				is_telegraphing = true
				telegraph_type = "charge"
				telegraph_duration = 0.85
				telegraph_timer = 0.85
				telegraph_charge_dir = global_position.direction_to(player.global_position)
				FloatingText.spawn(global_position + Vector2(0, -50), "⚠️ BULL RUSH! ⚠️", Color(1.0, 0.5, 0.15))
				return

	# --- ELITE CHAMPION TELEGRAPHED SHOCKWAVE (Expansion 20.0) ---
	if is_elite_champion and is_instance_valid(player):
		queue_redraw()
		if is_telegraphing_burst:
			velocity = Vector2.ZERO
			move_and_slide()
			elite_telegraph_timer -= delta
			if elite_telegraph_timer <= 0.0:
				_execute_elite_burst()
			return
		else:
			elite_telegraph_timer -= delta
			if elite_telegraph_timer <= 0.0:
				is_telegraphing_burst = true
				elite_telegraph_timer = elite_telegraph_duration
				SoundManager.play("boss_alarm", 0.25)
				FloatingText.spawn(global_position + Vector2(0, -54), "⚠️ CHẤN ĐỘNG TINH ANH! ⚠️", Color(1.0, 0.25, 0.2))
				return

	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		var direction = global_position.direction_to(player.global_position)
		
		# Movement logic (standard swarming vs ranged spacing)
		var move_dir = direction
		if is_ranged:
			if dist < preferred_distance - 30.0:
				move_dir = -direction
			elif dist < preferred_distance + 40.0:
				move_dir = Vector2.ZERO
				
		# Flip sprite toward player
		if sprite and direction.x != 0:
			sprite.flip_h = direction.x < 0
			
		# Distinct procedural animations per enemy archetype (culled off-screen)
		if sprite and is_near_screen:
			if is_bat_type:
				var flap = sin(anim_time * 24.0)
				sprite.scale = base_sprite_scale * Vector2(1.0, 0.75 + flap * 0.35)
				sprite.position.y = sin(anim_time * 8.0) * 4.0
				sprite.rotation = (direction.x * 0.12) + sin(anim_time * 8.0) * 0.08
			elif is_necro_type:
				sprite.position.y = sin(anim_time * 4.2) * 5.5
				var breath = sin(anim_time * 3.0) * 0.06
				sprite.scale = base_sprite_scale * Vector2(1.0 - breath, 1.0 + breath)
				if ranged_timer <= 0.45:
					sprite.modulate = Color(1.8, 0.4, 2.0)
				else:
					sprite.modulate = Color.WHITE
			elif is_boss:
				var stomp = sin(anim_time * 6.5)
				sprite.scale = base_sprite_scale * Vector2(1.0 + stomp * 0.10, 1.0 - stomp * 0.10)
				sprite.rotation = stomp * 0.07
				if current_health / max(1.0, max_health) < 0.50:
					var rage_pulse = (sin(anim_time * 10.0) + 1.0) * 0.5
					sprite.modulate = Color(1.0 + rage_pulse * 0.8, 0.3, 0.3)
			else:
				var sway = sin(anim_time * 11.0)
				sprite.rotation = sway * 0.14
				sprite.position.y = -abs(sway) * 2.8
				sprite.scale = base_sprite_scale * Vector2(1.0 + sway * 0.05, 1.0 - sway * 0.05)
			
		# Soft flocking / boid separation (prevents single-pixel stacking)
		separation_timer -= delta
		if separation_timer <= 0.0 and is_near_screen:
			separation_timer = randf_range(0.08, 0.14)
			separation_force = Vector2.ZERO
			var enemies = get_tree().get_nodes_in_group("enemies")
			var sep_radius = 32.0 if is_boss else 22.0
			var checked = 0
			for other in enemies:
				if other != self and is_instance_valid(other) and not other.get("is_dead"):
					var diff = global_position - other.global_position
					var other_dist_sq = diff.length_squared()
					if other_dist_sq > 0.1 and other_dist_sq < (sep_radius * sep_radius):
						var d = sqrt(other_dist_sq)
						separation_force += (diff / d) * ((sep_radius - d) * 6.5)
					checked += 1
					if checked > 25:
						break

		# Apply movement + separation + knockback decay
		var current_speed = move_speed * (slow_multiplier if slow_timer > 0.0 else 1.0)
		velocity = move_dir * current_speed + separation_force + knockback
		knockback = knockback.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		
		# Ranged projectile casting
		if is_ranged and projectile_scene and is_near_screen:
			ranged_timer -= delta
			if ranged_timer <= 0.0:
				ranged_timer = shoot_interval
				_shoot_at_player()
				
		# Radial projectile wave for Behemoth
		if is_radial_boss and projectile_scene:
			radial_timer -= delta
			if radial_timer <= 0.0:
				radial_timer = radial_interval
				_shoot_radial_wave()
		
		# Contact damage check (O(1) distance squared check)
		if damage_cooldown <= 0.0:
			var hit_dist_sq = 5625.0 if is_boss else 1936.0 # 75^2 or 44^2
			if dist_sq < hit_dist_sq:
				if player.has_method("take_damage"):
					player.take_damage(contact_damage)
				# Vampiric Champion heal on hit
				if is_champion and champion_affix == "vampiric":
					current_health = min(max_health, current_health + 8.0)
					FloatingText.spawn(global_position + Vector2(0, -20), "+8 HP (Vamp)", Color(0.9, 0.2, 0.3))
				damage_cooldown = 0.65

func _execute_boss_telegraph() -> void:
	is_telegraphing = false
	if telegraph_type == "slam":
		boss_slam_timer = 9.5
		SoundManager.play("thunder", 0.3)
		var cam = get_tree().get_first_node_in_group("camera")
		if cam and cam.has_method("shake"):
			cam.shake(16.0)
			
		# Check AoE damage in 140px radius
		if is_instance_valid(player) and global_position.distance_to(player.global_position) < 140.0:
			if player.has_method("take_damage"):
				player.take_damage(28.0)
				
		# Slam shockwave effect
		var particles = CPUParticles2D.new()
		particles.emitting = true
		particles.one_shot = true
		particles.explosiveness = 0.95
		particles.amount = 28
		particles.lifetime = 0.45
		particles.spread = 180.0
		particles.initial_velocity_min = 120.0
		particles.initial_velocity_max = 240.0
		particles.scale_amount_min = 3.0
		particles.scale_amount_max = 6.0
		particles.color = Color(1.0, 0.3, 0.15)
		particles.global_position = global_position
		get_tree().current_scene.add_child(particles)
		var t = get_tree().create_timer(0.5)
		t.timeout.connect(particles.queue_free)
		
	elif telegraph_type == "charge":
		boss_charge_timer = 13.0
		charge_duration_remaining = 0.55
		SoundManager.play("shoot", 0.4)

## Expansion 20.0: Elite Champion shockwave — fires the moment the 0.8s warning ends.
func _execute_elite_burst() -> void:
	is_telegraphing_burst = false
	elite_telegraph_timer = elite_burst_interval
	SoundManager.play("thunder", 0.35)
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(14.0)

	# Contact damage inside the shockwave ring
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= elite_burst_radius:
		if player.has_method("take_damage"):
			player.take_damage(elite_burst_damage)
		if damage_cooldown <= 0.0:
			damage_cooldown = 0.65

	# Expanding shockwave ring
	var ring = CPUParticles2D.new()
	ring.emitting = true
	ring.one_shot = true
	ring.explosiveness = 0.95
	ring.amount = 30
	ring.lifetime = 0.5
	ring.spread = 180.0
	ring.initial_velocity_min = 140.0
	ring.initial_velocity_max = 280.0
	ring.scale_amount_min = 3.0
	ring.scale_amount_max = 6.5
	ring.color = Color(1.0, 0.8, 0.2)
	ring.global_position = global_position
	get_tree().current_scene.add_child(ring)
	var t = get_tree().create_timer(0.55)
	t.timeout.connect(ring.queue_free)

	FloatingText.spawn(global_position + Vector2(0, -40), "💥 CHẤN ĐỘNG! 💥", Color(1.0, 0.7, 0.1))
	queue_redraw()

func _draw() -> void:
	if not is_dead:
		var shadow_radius = 28.0 if is_boss else (11.0 if not is_bat_type else 8.0)
		var shadow_y = 22.0 if is_boss else (13.0 if not is_bat_type else 15.0)
		var shadow_alpha = 0.38 if not is_bat_type else 0.20
		draw_set_transform(Vector2(0, shadow_y), 0.0, Vector2(1.15, 0.45))
		draw_circle(Vector2.ZERO, shadow_radius, Color(0.0, 0.0, 0.0, shadow_alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if is_champion and not is_dead:
		var pulse = 20.0 + 3.0 * sin(anim_time * 7.0)
		draw_arc(Vector2.ZERO, pulse, 0, TAU, 24, champ_aura_color, 2.0)
		draw_circle(Vector2.ZERO, pulse * 0.75, Color(champ_aura_color.r, champ_aura_color.g, champ_aura_color.b, 0.18))

	# Elite Champion: persistent gold crown ring, plus the red warn circle during telegraph
	if is_elite_champion and not is_dead:
		var elite_ring = 26.0 + 3.0 * sin(anim_time * 5.0)
		draw_arc(Vector2.ZERO, elite_ring, 0, TAU, 28, Color(1.0, 0.85, 0.15, 0.9), 2.5)
		if is_telegraphing_burst:
			var burst_progress = 1.0 - clamp(elite_telegraph_timer / max(0.01, elite_telegraph_duration), 0.0, 1.0)
			draw_circle(Vector2.ZERO, elite_burst_radius * burst_progress, Color(1.0, 0.12, 0.12, 0.20))
			draw_arc(Vector2.ZERO, elite_burst_radius, 0, TAU, 40, Color(1.0, 0.2, 0.2, 0.9), 3.0)
			var flash = (sin(anim_time * 26.0) + 1.0) * 0.5
			draw_arc(Vector2.ZERO, elite_burst_radius * burst_progress, 0, TAU, 32, Color(1.0, 0.85, 0.25, flash), 2.0)

		
	if is_boss and is_telegraphing:
		var progress = 1.0 - (telegraph_timer / max(0.01, telegraph_duration))
		if telegraph_type == "slam":
			var slam_radius = 140.0
			draw_circle(Vector2.ZERO, slam_radius * progress, Color(1.0, 0.15, 0.15, 0.25))
			draw_arc(Vector2.ZERO, slam_radius, 0, TAU, 32, Color(1.0, 0.2, 0.2, 0.85), 2.5)
			var flash = (sin(anim_time * 24.0) + 1.0) * 0.5
			draw_arc(Vector2.ZERO, slam_radius * progress, 0, TAU, 24, Color(1.0, 0.8, 0.2, flash), 1.5)
		elif telegraph_type == "charge":
			var end_pt = telegraph_charge_dir * 380.0
			draw_line(Vector2.ZERO, end_pt, Color(1.0, 0.2, 0.2, 0.85), 3.0)
			draw_circle(end_pt, 9.0 + 3.0 * sin(anim_time * 16.0), Color(1.0, 0.4, 0.2, 0.9))

func _shoot_at_player() -> void:
	if not projectile_scene or not is_instance_valid(player):
		return
	var proj = projectile_scene.instantiate()
	if proj:
		proj.direction = global_position.direction_to(player.global_position)
		proj.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", proj)
		SoundManager.play("shoot", 0.3)

func _shoot_radial_wave() -> void:
	if not projectile_scene:
		return
	SoundManager.play("thunder", 0.25)
	for i in range(10):
		var proj = projectile_scene.instantiate()
		if proj:
			var angle = (float(i) / 10.0) * TAU
			proj.direction = Vector2(cos(angle), sin(angle))
			proj.speed = 140.0
			proj.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", proj)

func take_damage(amount: float, source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	# crit_chance_bonus is written by the player (Đốc Mạch + shop scrolls) but every
	# weapon funnels through this one function, so this is the only roll that matters.
	var crit_chance := 0.12
	var lifesteal := 0.0
	if is_instance_valid(player):
		if "crit_chance_bonus" in player:
			crit_chance += player.crit_chance_bonus
		if "shop_lifesteal" in player:
			lifesteal = player.shop_lifesteal

	var is_crit = randf() < crit_chance
	var final_amount = amount * 2.2 if is_crit else amount
	current_health -= final_amount

	if lifesteal > 0.0 and player.has_method("heal"):
		player.heal(final_amount * lifesteal)
	
	if is_crit:
		FloatingText.spawn(global_position, "CRIT " + str(int(final_amount)) + "!", Color(1.0, 0.25, 0.1))
		var cam = get_tree().get_first_node_in_group("camera")
		if cam and cam.has_method("shake"):
			cam.shake(5.0)
	else:
		FloatingText.spawn(global_position, str(int(final_amount)), Color(1.0, 0.5, 0.2) if is_boss else Color(1.0, 0.9, 0.2))
		
	SoundManager.play("hit", 0.25 if is_crit else 0.1)
	
	# Trigger Storm Amulet relic if player has it
	if player and player.has_method("trigger_storm_amulet_proc"):
		player.trigger_storm_amulet_proc(global_position)
	
	# Knockback calculation
	if source_pos != Vector2.ZERO:
		var push_dir = (global_position - source_pos).normalized()
		var push_force = max(0.0, 260.0 * (1.0 - knockback_resistance))
		knockback += push_dir * push_force
	
	# Pure white hit flash and punchy squash recoil
	modulate = Color(4.0, 4.0, 4.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.06)
	if sprite:
		sprite.scale = base_sprite_scale * Vector2(1.30, 0.70)
		var sq_tw = create_tween()
		sq_tw.tween_property(sprite, "scale", base_sprite_scale, 0.10).set_trans(Tween.TRANS_BACK)
	queue_redraw()

	
	if is_boss:
		emit_signal("boss_health_changed", current_health, max_health)
	
	if current_health <= 0:
		die()

func apply_freeze(duration: float) -> void:
	if is_dead:
		return
	if burn_timer > 0.0:
		_trigger_thermal_shockwave()
		return
	freeze_timer = max(freeze_timer, duration)
	FloatingText.spawn(global_position + Vector2(0, -20), "❄️ BĂNG ĐÔNG!", Color(0.4, 0.85, 1.0))

func apply_burn(duration: float, dps: float = 18.0) -> void:
	if is_dead:
		return
	if freeze_timer > 0.0:
		_trigger_thermal_shockwave()
		return
	burn_timer = max(burn_timer, duration)
	burn_dps = max(burn_dps, dps)
	FloatingText.spawn(global_position + Vector2(0, -20), "🔥 THIÊU ĐỐT!", Color(1.0, 0.45, 0.1))

func _trigger_thermal_shockwave() -> void:
	freeze_timer = 0.0
	burn_timer = 0.0
	SoundManager.play("elemental_burst", 0.15)
	FloatingText.spawn(global_position + Vector2(0, -32), "💥 BĂNG HỎA BẠO KÍCH (140)!", Color(0.2, 0.95, 1.0))
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(8.0)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead") and global_position.distance_to(e.global_position) <= 130.0:
			if e.has_method("take_damage"):
				e.take_damage(140.0, global_position)

func apply_poison(duration: float, dps: float = 14.0) -> void:
	if is_dead:
		return
	poison_timer = max(poison_timer, duration)
	poison_dps = max(poison_dps, dps)
	FloatingText.spawn(global_position + Vector2(0, -20), "🧪 TRÚNG ĐỘC!", Color(0.3, 0.95, 0.3))

func apply_slow(duration: float, factor: float = 0.5) -> void:
	if is_dead:
		return
	slow_timer = max(slow_timer, duration)
	slow_multiplier = min(slow_multiplier, factor)
	FloatingText.spawn(global_position + Vector2(0, -20), "❄️ LÀM CHẬM!", Color(0.35, 0.8, 1.0))

func die() -> void:
	is_dead = true
	
	# Micro-Hitstop on enemy kill for bone-crushing impact
	if GameManager and GameManager.has_method("trigger_hitstop"):
		if is_boss or is_champion:
			GameManager.trigger_hitstop(0.085, 0.02)
		else:
			GameManager.trigger_hitstop(0.035, 0.08)
	
	# Record kill in GameManager with enemy type and champion flag
	var enemy_type = "bat" if is_bat_type else ("skeleton" if name.begins_with("Skeleton") else "")
	if GameManager:
		GameManager.add_kill(enemy_type, is_champion)
		
	# Report to CodexManager
	if CodexManager:
		CodexManager.report_stat("cumulative_kills", 1)
		if GameManager:
			CodexManager.report_stat("run_kills", GameManager.kills)
		if is_boss:
			CodexManager.report_stat("boss_kill", 1)
		
	# Award Long Hồn (Dragon Soul) to Player
	var p = get_tree().get_first_node_in_group("player")
	if is_instance_valid(p) and p.has_method("add_dragon_soul"):
		var charge_gain = 2.0
		if is_boss:
			charge_gain = 35.0
		elif is_champion:
			charge_gain = 12.0
		elif name.begins_with("TreasureGoblin") or enemy_type == "goblin":
			charge_gain = 15.0
		p.add_dragon_soul(charge_gain)
	
	# Volatile Champion death explosion
	if is_champion and champion_affix == "volatile" and projectile_scene:
		_shoot_radial_wave()
	
	# Spawn explosion particles
	spawn_death_particles()
	
	if is_boss:
		emit_signal("boss_defeated")
		# Guaranteed Relic, Dragon Pearl, and Scroll from Boss
		_spawn_relic_drop()
		_spawn_pearl_drop()
		_spawn_scroll_drop()
		# Spawn Treasure Chest on boss death
		if chest_scene:
			var chest = chest_scene.instantiate()
			if chest:
				chest.global_position = global_position
				get_tree().current_scene.call_deferred("add_child", chest)
		# Dramatic boss gold scatter (8 coins of 5 gold each)
		if coin_scene:
			for i in range(8):
				var coin = coin_scene.instantiate()
				if coin:
					coin.set("gold_value", coin_value)
					var angle = (float(i) / 8.0) * TAU
					var offset = Vector2(cos(angle), sin(angle)) * randf_range(30.0, 55.0)
					coin.global_position = global_position + offset
					get_tree().current_scene.call_deferred("add_child", coin)
	else:
		# Expansion 20.0: Elite Champion guaranteed high-value loot (chest, else 50 gold)
		if is_elite_champion:
			if chest_scene:
				var elite_chest = chest_scene.instantiate()
				elite_chest.global_position = global_position
				get_tree().current_scene.add_child(elite_chest)
			elif coin_scene:
				for i in range(ELITE_GOLD_COINS):
					var c = coin_scene.instantiate()
					if c:
						c.set("gold_value", ELITE_GOLD_VALUE)
						var a = (float(i) / float(ELITE_GOLD_COINS)) * TAU
						c.global_position = global_position + Vector2(cos(a), sin(a)) * randf_range(24.0, 52.0)
						get_tree().current_scene.add_child(c)

		# Champion drop bonuses
		if is_champion:
			# Extra gold coins
			if coin_scene:
				for i in range(3):
					var coin = coin_scene.instantiate()
					if coin:
						coin.set("gold_value", coin_value * 2)
						coin.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
						get_tree().current_scene.call_deferred("add_child", coin)
			# 40% chance of dropping a Relic
			if randf() < 0.40:
				_spawn_relic_drop()
			# 50% chance of dropping a Dragon Pearl
			if randf() < 0.50:
				_spawn_pearl_drop()
			# 35% chance of dropping a Martial Scroll
			if randf() < 0.35:
				_spawn_scroll_drop()
				
		# Spawn XP Gem
		if gem_scene:
			var gem = gem_scene.instantiate()
			if gem:
				gem.global_position = global_position
				get_tree().current_scene.call_deferred("add_child", gem)
				
		# Spawn Gold Coin
		if coin_scene and randf() < coin_drop_chance:
			var coin = coin_scene.instantiate()
			if coin:
				coin.set("gold_value", coin_value)
				coin.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))
				get_tree().current_scene.call_deferred("add_child", coin)
				
		# Spawn Field Power-up (8% chance)
		if powerup_scene and randf() < 0.08:
			var pup = powerup_scene.instantiate()
			if pup:
				var types = ["meat", "meat", "magnet", "nuke"]
				pup.set_type(types.pick_random())
				pup.global_position = global_position
				get_tree().current_scene.call_deferred("add_child", pup)
			
	queue_free()

func _spawn_relic_drop() -> void:
	if not relic_scene:
		return
	var relic = relic_scene.instantiate()
	if relic:
		var uncollected = []
		if GameManager:
			for r_id in GameManager.RELICS.keys():
				if not GameManager.has_relic(r_id):
					uncollected.append(r_id)
		var chosen_id = uncollected.pick_random() if not uncollected.is_empty() else GameManager.RELICS.keys().pick_random()
		if relic.has_method("set_relic"):
			relic.set_relic(chosen_id)
		relic.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", relic)

func _spawn_pearl_drop() -> void:
	if not pearl_scene or not GameManager or GameManager.dragon_pearls_collected >= 7:
		return
	var pearl = pearl_scene.instantiate()
	if pearl:
		pearl.global_position = global_position + Vector2(randf_range(-14, 14), randf_range(-14, 14))
		get_tree().current_scene.call_deferred("add_child", pearl)

func _spawn_scroll_drop() -> void:
	if not scroll_scene or not GameManager:
		return
	var uncollected: Array[String] = []
	for s_id in GameManager.MARTIAL_SCROLLS.keys():
		if not GameManager.has_scroll(s_id):
			uncollected.append(s_id)
	if uncollected.is_empty():
		return
	var chosen_id = uncollected.pick_random()
	var scroll = scroll_scene.instantiate()
	if scroll:
		if scroll.has_method("set_scroll"):
			scroll.set_scroll(chosen_id)
		scroll.global_position = global_position + Vector2(randf_range(-18, 18), randf_range(-18, 18))
		get_tree().current_scene.call_deferred("add_child", scroll)

func spawn_death_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = 36 if (is_boss or is_champion) else 18
	particles.lifetime = 0.45
	particles.spread = 180.0
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 180.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.0
	var grad = Gradient.new()
	var base_col = champ_aura_color if is_champion else (Color(1.0, 0.35, 0.15) if is_boss else Color(0.85, 0.4, 1.0))
	grad.colors = PackedColorArray([Color(base_col.r, base_col.g, base_col.b, 0.95), Color(base_col.r * 1.3, base_col.g * 1.3, base_col.b * 1.3, 0.0)])
	particles.color_ramp = grad
	particles.global_position = global_position
	
	get_tree().current_scene.add_child(particles)
	var timer = get_tree().create_timer(0.55)
	timer.timeout.connect(particles.queue_free)

