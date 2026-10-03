class_name Landmark
extends Node2D

## Landmark / World Shrine: Discoverable points of interest that grant buffs, rewards, or healing.

@export var landmark_id: String = "fountain" # "fountain", "might", "speed", "vault"
## The English fallbacks. main.tscn overrides these per instance, and both are
## what Loc.t() is handed as its default, so a landmark whose id has no row in
## the string table still shows the copy the arena ships rather than a raw key.
@export var landmark_name: String = "Sanctuary of Vitality"
@export var landmark_desc: String = "Restores vitality to weary adventurers"
@export var activation_radius: float = 72.0
@export var discovery_radius: float = 210.0
@export var cooldown_max: float = 30.0

## The localised name. Every read of `landmark_name` goes through here --
## discover(), the DISCOVERED banner and the floating label -- because the
## @export is still English, and reading it directly is what put an English
## shrine name inside a Vietnamese HUD banner.
func get_display_name() -> String:
	return Loc.t("landmark.%s.name" % landmark_id, landmark_name)

func get_display_desc() -> String:
	return Loc.t("landmark.%s.desc" % landmark_id, landmark_desc)

@export var chest_scene: PackedScene
@export var coin_scene: PackedScene

var is_discovered: bool = false
var cooldown_timer: float = 0.0
var regen_tick_timer: float = 0.0
var player_inside_active: bool = false
var pulse_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var particles: CPUParticles2D = $Particles

func _ready() -> void:
	add_to_group("landmarks")
	_setup_visuals()

func _setup_visuals() -> void:
	if sprite:
		var tex_path = "res://assets/textures/fountain.png"
		match landmark_id:
			"might": tex_path = "res://assets/textures/shrine_might.png"
			"speed": tex_path = "res://assets/textures/shrine_speed.png"
			"vault": tex_path = "res://assets/textures/shrine_vault.png"
		if ResourceLoader.exists(tex_path):
			sprite.texture = load(tex_path)
			
	if particles:
		particles.emitting = true
		match landmark_id:
			"fountain":
				particles.color = Color(0.2, 0.9, 0.6, 0.8)
				particles.initial_velocity_min = 20.0
				particles.initial_velocity_max = 40.0
			"might":
				particles.color = Color(1.0, 0.35, 0.15, 0.8)
				particles.initial_velocity_min = 25.0
				particles.initial_velocity_max = 50.0
			"speed":
				particles.color = Color(0.3, 1.0, 0.85, 0.8)
				particles.initial_velocity_min = 35.0
				particles.initial_velocity_max = 65.0
			"vault":
				particles.color = Color(1.0, 0.85, 0.25, 0.8)
				particles.initial_velocity_min = 15.0
				particles.initial_velocity_max = 30.0

func _process(delta: float) -> void:
	pulse_time += delta * 2.5
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
		
	var dist = global_position.distance_to(player.global_position)
	
	# Discovery check
	if not is_discovered and dist <= discovery_radius:
		discover(player)
		
	# Proximity activation check
	player_inside_active = (dist <= activation_radius)
	if player_inside_active:
		_handle_player_inside(player, delta)
		
	_update_label()
	queue_redraw()

func discover(player: Node2D) -> void:
	is_discovered = true
	GameManager.discover_landmark(landmark_id, get_display_name())
	SoundManager.play("shrine_activate")
	
	# Reward on first discovery
	var xp_reward = 60.0
	var gold_reward = 30
	if landmark_id == "vault":
		xp_reward = 120.0
		gold_reward = 60
		
	if player.has_method("add_xp"):
		player.add_xp(xp_reward)
	GameManager.add_gold(gold_reward)
	
	FloatingText.spawn(global_position + Vector2(0, -40), "🗺️ DISCOVERED: %s!\n+%d XP  +%d GOLD" % [get_display_name().to_upper(), int(xp_reward), gold_reward], Color(1.0, 0.85, 0.2))
	
	# If Vault, pop extra chests and gold coins onto the ground!
	if landmark_id == "vault":
		_spawn_vault_treasures()
		
	# Announce discovery on HUD banner
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("_on_wave_event_announced"):
		hud._on_wave_event_announced("🗺️ DISCOVERED: %s!" % get_display_name().to_upper(), false)

func _spawn_vault_treasures() -> void:
	# Spawn 2 chests and a scattering of gold coins
	for i in range(2):
		if chest_scene:
			var chest = chest_scene.instantiate()
			chest.global_position = global_position + Vector2(randf_range(-55, 55), randf_range(-40, 40))
			get_tree().current_scene.call_deferred("add_child", chest)
			
	for i in range(8):
		if coin_scene:
			var coin = coin_scene.instantiate()
			coin.global_position = global_position + Vector2(randf_range(-70, 70), randf_range(-50, 50))
			# "gold_value", not "coin_value" -- see obstacle.break_tomb(). Writing
			# the enemy's property name onto the coin was a silent no-op, so all eight
			# of these paid 1 gold each instead of 5, and the player lost 32 of the
			# 40 a landmark is worth. Measured 2026-10-01.
			coin.set("gold_value", 5)
			get_tree().current_scene.call_deferred("add_child", coin)
			
	# Guaranteed Ancient Relic from Vault of the Ancients
	var relic_scene = preload("res://scenes/relic_pickup.tscn")
	if relic_scene:
		var relic = relic_scene.instantiate()
		relic.global_position = global_position + Vector2(0, 35)
		get_tree().current_scene.call_deferred("add_child", relic)
			
	SoundManager.play("explosion", 0.2)

func _handle_player_inside(player: Node2D, delta: float) -> void:
	match landmark_id:
		"fountain":
			regen_tick_timer += delta
			if regen_tick_timer >= 0.5:
				regen_tick_timer = 0.0
				if player.has_method("heal"):
					player.heal(4.0) # +8 HP / second
					FloatingText.spawn(player.global_position + Vector2(randf_range(-10, 10), -18), "+4 HP", Color(0.2, 0.9, 0.4))
					
		"might":
			if cooldown_timer <= 0.0:
				cooldown_timer = cooldown_max
				if player.has_method("apply_might_buff"):
					player.apply_might_buff(25.0, 1.4)
				SoundManager.play("powerup")
				
		"speed":
			if cooldown_timer <= 0.0:
				cooldown_timer = cooldown_max
				if player.has_method("apply_speed_buff"):
					player.apply_speed_buff(20.0, 1.5)
				SoundManager.play("powerup")
				
		"vault":
			pass

func _update_label() -> void:
	if not label:
		return
		
	if not is_discovered:
		label.text = "❓ Unknown Landmark"
		label.modulate = Color(0.7, 0.7, 0.7, 0.75)
		return
		
	var status_text = ""
	match landmark_id:
		"fountain":
			status_text = "💚 SACRED POOL (+8 HP/s)"
			label.modulate = Color(0.3, 1.0, 0.5)
		"might":
			if cooldown_timer <= 0.0:
				status_text = "⚔️ READY (STEP IN FOR +40% DMG)"
				label.modulate = Color(1.0, 0.4, 0.2)
			else:
				status_text = "⏳ RECHARGING (%ds)" % int(ceil(cooldown_timer))
				label.modulate = Color(0.7, 0.6, 0.6, 0.8)
		"speed":
			if cooldown_timer <= 0.0:
				status_text = "💨 READY (STEP IN FOR +50% SPD)"
				label.modulate = Color(0.3, 0.9, 1.0)
			else:
				status_text = "⏳ RECHARGING (%ds)" % int(ceil(cooldown_timer))
				label.modulate = Color(0.7, 0.6, 0.6, 0.8)
		"vault":
			status_text = "👑 VAULT OF THE ANCIENTS [OPENED]"
			label.modulate = Color(1.0, 0.85, 0.2)
			
	label.text = "%s\n%s" % [get_display_name(), status_text]

func _draw() -> void:
	if not is_discovered:
		# Faint pulse ring showing mysterious presence
		var faint_alpha = 0.12 + 0.08 * sin(pulse_time)
		draw_arc(Vector2.ZERO, activation_radius, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, faint_alpha), 2.0)
		return
		
	var ring_color = Color(1.0, 1.0, 1.0, 0.3)
	match landmark_id:
		"fountain":
			var a = 0.35 + 0.15 * sin(pulse_time)
			ring_color = Color(0.2, 0.9, 0.5, a)
		"might":
			if cooldown_timer <= 0.0:
				var a = 0.45 + 0.25 * sin(pulse_time)
				ring_color = Color(1.0, 0.35, 0.15, a)
			else:
				ring_color = Color(0.6, 0.3, 0.3, 0.25)
		"speed":
			if cooldown_timer <= 0.0:
				var a = 0.45 + 0.25 * sin(pulse_time)
				ring_color = Color(0.25, 0.9, 1.0, a)
			else:
				ring_color = Color(0.3, 0.5, 0.6, 0.25)
		"vault":
			var a = 0.4 + 0.2 * sin(pulse_time)
			ring_color = Color(1.0, 0.85, 0.2, a)
			
	draw_arc(Vector2.ZERO, activation_radius, 0.0, TAU, 48, ring_color, 2.5)
	# Faint inner filled circle
	draw_circle(Vector2.ZERO, activation_radius, Color(ring_color.r, ring_color.g, ring_color.b, ring_color.a * 0.15))
