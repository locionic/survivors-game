class_name Player
extends CharacterBody2D

## Player controller handling movement, health, XP leveling, meta-upgrades, and weapon inventory.

signal health_changed(current: float, max_val: float)
signal xp_changed(current: float, required: float, level: int)
signal leveled_up(new_level: int)
signal died
signal skill_used(skill_id: String, cooldown: float)
signal skill_cooldown_progress(current_cd: float, max_cd: float)
signal skill_ready
signal dragon_soul_changed(current: float, max_val: float)
signal dragon_awakened(duration: float)
signal dragon_ended
signal qi_shield_changed(current: float, max_val: float)

@export var move_speed: float = 230.0
@export var max_health: float = 100.0
@export var magnet_radius: float = 140.0

var current_health: float = 100.0
var level: int = 1
var current_xp: float = 0.0
var xp_to_next_level: float = 10.0
var invulnerability_timer: float = 0.0
var is_invulnerable: bool:
	get:
		return invulnerability_timer > 0.0 or is_dragon_awakened or is_dashing
	set(val):
		if val:
			invulnerability_timer = max(invulnerability_timer, 0.25)
		else:
			invulnerability_timer = 0.0

# Active Hero Skill & Tactical Dash state
var skill_id: String = "shield_charge"
var skill_name: String = "Shield Charge"
var skill_icon: String = "🛡️"
var skill_cooldown_timer: float = 0.0
var skill_cooldown_max: float = 5.5
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_velocity: Vector2 = Vector2.ZERO
var last_move_dir: Vector2 = Vector2.RIGHT
var input_direction: Vector2 = Vector2.ZERO

# Active landmark buff timers and multipliers
var might_buff_timer: float = 0.0
var might_multiplier: float = 1.0
var speed_buff_timer: float = 0.0
var speed_multiplier: float = 1.0
var meta_might_bonus: float = 0.0

# Expansion 21.0: Vạn Nhân Trảm — Blood Rush (kill-streak rampage buff)
var blood_rush_timer: float = 0.0
const BLOOD_RUSH_DURATION: float = 5.0
const BLOOD_RUSH_SPEED_MULT: float = 1.20
const BLOOD_RUSH_COOLDOWN_RATE: float = 1.25

# Long Hồn (Dragon Soul Awakening) state
var dragon_soul: float = 0.0
var dragon_soul_max: float = 100.0
var is_dragon_awakened: bool = false
var dragon_duration_timer: float = 0.0
var dragon_duration_max: float = 8.5
var dragon_breath_timer: float = 0.0
var original_texture: Texture2D = null
var dragon_texture: Texture2D = null

# Meridian Cultivation (Hệ Thống Kinh Mạch) stats
var qi_shield_max: float = 0.0
var qi_shield_current: float = 0.0
var qi_shield_regen_rate: float = 0.0
var crit_chance_bonus: float = 0.0
var dragon_soul_harvest_mult: float = 1.0

# Expansion 12.0: Võ Học Bí Tịch & Thất Long Châu
var yijinjing_timer: float = 2.0
var lucmach_timer: float = 0.5
var thaicuc_tick_timer: float = 0.0
var golden_frenzy_timer: float = 0.0
var van_kiem_timer: float = 0.0
var van_kiem_interval: float = 0.0

# Active Character Class stats & bonuses
var char_armor_bonus: int = 0
var char_might_bonus: float = 0.0
var char_xp_mult: float = 1.0
var char_speed_bonus: float = 0.0
var char_speed_mult: float = 1.0
var char_hp_bonus: float = 0.0
var char_magnet_bonus: float = 0.0
var char_dodge_bonus: float = 0.0
# Milestone 2 (Môn Phái Độc Bản): the rest of the sect trade-offs. Each one has
# to reach the damage path it names rather than sit in a menu -- see
# get_might_multiplier(), take_damage(), get_burn_multiplier(), and the pierce
# and heal handoffs in apply_character_data().
var char_damage_mult: float = 1.0
var char_slash_damage_mult: float = 1.0
var char_damage_taken_mult: float = 1.0
var char_lifesteal_bonus: float = 0.0
var char_combo_heal: float = 0.0
var char_burn_mult: float = 1.0
var char_area_bonus: float = 0.0
var drunken_buff_timer: float = 0.0
var walk_phase: float = 0.0
var footstep_side: float = 1.0
var phoenix_feather_used: bool = false
var relic_magnet_bonus: float = 0.0
var has_blood_covenant: bool = false
var has_abyssal_frenzy: bool = false
var has_hermit_sacrifice: bool = false
var blizzard_slow_timer: float = 0.0
var base_sprite_scale: Vector2 = Vector2(0.42, 0.42)

# Milestone 1: permanent modifiers bought from the Tàng Kinh Các shop. Kept as
# separate fields rather than folded into the base stats so a scroll's tradeoff
# stays legible in one place.
var shop_lifesteal: float = 0.0
var shop_armor_bonus: int = 0

# Milestone 3: Võ Lâm Cộng Hưởng. Both synergies are passive and key off the live
# arsenal rather than a level gate -- carry both halves and the passive is simply
# there. refresh_synergies() is the only place either flag flips.
const THUNDERFIRE_RADIUS: float = 130.0
const THUNDERFIRE_DAMAGE: float = 55.0
## A crit-heavy build lands one every swing, so the detonation rate is capped
## rather than letting a single arc clear a screen.
const THUNDERFIRE_COOLDOWN: float = 0.35
const SWORD_QI_PER_SLASH: int = 2
const SWORD_QI_DAMAGE: float = 22.0

var has_thunderfire: bool = false
var has_thousand_swords: bool = false
var thunderfire_cd: float = 0.0


@onready var magnet_area: Area2D = $MagnetArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var weapons_container: Node2D = $Weapons
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var overhead_hp: ProgressBar = get_node_or_null("OverheadHP")
@onready var dust_particles: CPUParticles2D = get_node_or_null("DustParticles")

func _ready() -> void:
	add_to_group("player")
	apply_character_data()
	refresh_meta_stats()
	
	# Codex: Thần Long Lệnh (Bonus starting pearls)
	if CodexManager and CodexManager.bonus_starting_pearls > 0 and GameManager and GameManager.dragon_pearls_collected == 0:
		for i in range(CodexManager.bonus_starting_pearls):
			GameManager.collect_dragon_pearl()
	current_health = max_health
	_update_hp_displays()
	emit_signal("xp_changed", current_xp, xp_to_next_level, level)
	emit_signal("dragon_soul_changed", dragon_soul, dragon_soul_max)
	emit_signal("qi_shield_changed", qi_shield_current, qi_shield_max)
	_spawn_companion()

func apply_character_data() -> void:
	if not GameManager:
		return
	var data = GameManager.get_selected_character_data()
	
	char_hp_bonus = data.get("base_hp_bonus", 0.0)
	char_armor_bonus = data.get("armor_bonus", 0)
	char_speed_bonus = data.get("speed_bonus", 0.0)
	char_speed_mult = data.get("speed_mult", 1.0)
	char_magnet_bonus = data.get("magnet_bonus", 0.0)
	char_might_bonus = data.get("might_bonus", 0.0)
	char_xp_mult = data.get("xp_mult", 1.0)
	char_dodge_bonus = data.get("dodge_bonus", 0.0)
	char_damage_mult = data.get("damage_mult", 1.0)
	char_slash_damage_mult = data.get("slash_damage_mult", 1.0)
	char_damage_taken_mult = data.get("damage_taken_mult", 1.0)
	char_lifesteal_bonus = data.get("lifesteal_bonus", 0.0)
	char_combo_heal = data.get("combo_heal", 0.0)
	char_burn_mult = data.get("burn_mult", 1.0)
	char_area_bonus = data.get("area_of_effect_bonus", 0.0)

	# Load character texture
	var tex_path = data.get("texture_path", "res://assets/textures/player.png")
	if ResourceLoader.exists(tex_path) and sprite:
		sprite.texture = load(tex_path)

	# Configure starter weapons
	var starters: Array = data.get("starter_weapons", ["dagger", "shield"])
	_configure_weapons(starters)

	# Đường Môn: each dagger carries one extra target. Pushed onto the weapon
	# rather than read back per shot so the six-slot arsenal stays swappable.
	var pierce_bonus := int(data.get("piercing_bonus", 0))
	var main_wpn = get_node_or_null("Weapons/MainWeapon")
	if main_wpn:
		main_wpn.set("pierce_bonus", pierce_bonus)
		if data.has("attack_speed_bonus"):
			main_wpn.speed_multiplier += data["attack_speed_bonus"]
			
	# Active Skill Setup
	skill_id = data.get("skill_id", "shield_charge")
	skill_name = data.get("skill_name", "Shield Charge")
	skill_icon = data.get("skill_icon", "🛡️")
	match skill_id:
		"shield_charge":
			skill_cooldown_max = 5.5
		"inferno_blink":
			skill_cooldown_max = 5.0
		"shadow_roll":
			skill_cooldown_max = 4.2
		"frost_singularity":
			skill_cooldown_max = 6.5
		"drunken_brew":
			skill_cooldown_max = 7.5
		_:
			skill_cooldown_max = 5.0

## The six arsenal slots, id -> live node. Built per call rather than cached at
## @onready because the shop grants weapons mid-run and the tree is only fully
## populated by the time a caller asks.
func _weapon_nodes() -> Dictionary:
	return {
		"dagger": get_node_or_null("Weapons/MainWeapon"),
		"shield": get_node_or_null("Weapons/OrbitingWeapon"),
		"lightning": get_node_or_null("Weapons/LightningWeapon"),
		"fireball": get_node_or_null("Weapons/FireballWeapon"),
		"axe": get_node_or_null("Weapons/AxeWeapon"),
		"slash": get_node_or_null("Weapons/SlashWeapon")
	}

func _configure_weapons(starters: Array) -> void:
	var wpn_map := _weapon_nodes()

	for w_id in wpn_map.keys():
		var node = wpn_map[w_id]
		if node:
			var is_start = starters.has(w_id)
			node.set("is_active", is_start)
			if node.has_method("rebuild_shields"):
				node.rebuild_shields()
	refresh_synergies()

func activate_weapon(weapon_id: String) -> void:
	var wpn_map := _weapon_nodes()
	if wpn_map.has(weapon_id) and wpn_map[weapon_id]:
		var node = wpn_map[weapon_id]
		node.set("is_active", true)
		if node.has_method("rebuild_shields"):
			node.rebuild_shields()
		refresh_synergies()

## Milestone 3: re-read the live arsenal and flip whichever synergies it now
## completes. Both weapon-granting paths funnel through here, so a starting
## loadout and a mid-run purchase are treated identically.
func refresh_synergies() -> void:
	var wpn_map := _weapon_nodes()
	var is_live := func(id: String) -> bool:
		return is_instance_valid(wpn_map.get(id)) and bool(wpn_map[id].get("is_active"))

	var was_thunderfire := has_thunderfire
	has_thunderfire = is_live.call("fireball") and is_live.call("lightning")
	has_thousand_swords = is_live.call("dagger") and is_live.call("slash")

	if has_thunderfire and not was_thunderfire:
		SoundManager.play("elemental_burst", 0.1)
		FloatingText.spawn(global_position + Vector2(0, -46), "⚡🔥 LÔI HỎA LIÊN HOÀN!", Color(1.0, 0.6, 0.2))

func perform_slash(dir: Vector2 = Vector2.ZERO) -> Array[Node2D]:
	var slash_node = get_node_or_null("Weapons/SlashWeapon")
	if slash_node and slash_node.has_method("perform_slash"):
		return slash_node.perform_slash(dir)
	return []

## ui_attack path: walks the blade's Nhất Kiếm -> Song Phong -> Cửu Kiếm Quy Tông
## chain. No blade equipped means no hit -- the other weapons fire on their own.
func trigger_signature_combo() -> bool:
	var slash_node = get_node_or_null("Weapons/SlashWeapon")
	if slash_node and slash_node.has_method("trigger_combo_attack"):
		return slash_node.trigger_combo_attack()
	return false

func get_combo_step() -> int:
	var slash_node = get_node_or_null("Weapons/SlashWeapon")
	return slash_node.combo_step if slash_node else 0

func refresh_meta_stats() -> void:
	if not GameManager:
		return
	var base_hp = 100.0 + char_hp_bonus
	var new_max = base_hp + GameManager.get_meta_stat("vitality") * 25.0
	var hp_delta = new_max - max_health
	max_health = new_max
	if hp_delta > 0:
		current_health = min(max_health, current_health + hp_delta)
		
	var codex_spd = CodexManager.bonus_speed if CodexManager else 0.0
	move_speed = (230.0 + char_speed_bonus + codex_spd + GameManager.get_meta_stat("swiftness") * 20.0) * char_speed_mult
	magnet_radius = 140.0 + char_magnet_bonus + GameManager.get_meta_stat("magnetism") * 30.0
	meta_might_bonus = GameManager.get_meta_stat("might") * 0.10 + char_might_bonus

	if magnet_area and magnet_area.has_node("CollisionShape2D"):
		var shape = magnet_area.get_node("CollisionShape2D").shape
		if shape is CircleShape2D:
			shape.radius = magnet_radius

	# Cái Bang's +40% AoE is the base here, not an add-on: this line runs again on
	# every meta-upgrade, so anything applied to blast_radius_multiplier directly
	# in apply_character_data() would be wiped on the first refresh.
	var fire_wpn = get_node_or_null("Weapons/FireballWeapon")
	if fire_wpn and "blast_radius_multiplier" in fire_wpn:
		fire_wpn.blast_radius_multiplier = (1.0 + char_area_bonus) + GameManager.get_meta_stat("pyro") * 0.12
		
	# Meridian Cultivation (Hệ Thống Kinh Mạch)
	if GameManager:
		var nham = GameManager.get_meridian_stat("nham_mach")
		qi_shield_max = float(nham * 30)
		qi_shield_regen_rate = float(nham * 1.5)
		qi_shield_current = qi_shield_max
		
		var doc = GameManager.get_meridian_stat("doc_mach")
		crit_chance_bonus = float(doc * 0.07)
		
		var xung = GameManager.get_meridian_stat("xung_mach")
		move_speed += float(xung * 15.0)
		skill_cooldown_max = max(2.5, skill_cooldown_max * (1.0 - float(xung * 0.08)))
		
		var dan = GameManager.get_meridian_stat("dan_dien")
		dragon_soul_harvest_mult = 1.0 + float(dan * 0.30)
		
		# Wuxia Equipment bonuses
		if GameManager.has_equipped("van_hac_hai"):
			move_speed += 30.0
		if GameManager.has_equipped("y_thien_kiem"):
			meta_might_bonus += 0.15
			if fire_wpn and fire_wpn.has_method("upgrade_blast_radius"):
				fire_wpn.blast_radius_multiplier *= 1.25

		
	emit_signal("qi_shield_changed", qi_shield_current, qi_shield_max)
	_update_hp_displays()
	
	# Style overhead HP
	if overhead_hp:
		var bg_sb = StyleBoxFlat.new()
		bg_sb.bg_color = Color(0.06, 0.06, 0.1, 0.85)
		bg_sb.border_color = Color(0.3, 0.3, 0.4, 0.9)
		bg_sb.set_border_width_all(1)
		bg_sb.set_corner_radius_all(3)
		overhead_hp.add_theme_stylebox_override("background", bg_sb)
		
		var fill_sb = StyleBoxFlat.new()
		fill_sb.bg_color = Color(0.18, 0.85, 0.4, 1.0)
		fill_sb.set_corner_radius_all(3)
		overhead_hp.add_theme_stylebox_override("fill", fill_sb)

func _draw() -> void:
	# Soft dual-layer ellipse drop shadow beneath feet
	var shadow_col = Color(0.0, 0.0, 0.0, 0.22 if is_dragon_awakened else 0.38)
	var shadow_y = 20.0 if is_dragon_awakened else 15.0
	var shadow_scale = Vector2(1.2, 0.45) if not is_dragon_awakened else Vector2(1.4, 0.50)
	draw_set_transform(Vector2(0, shadow_y), 0.0, shadow_scale)
	draw_circle(Vector2.ZERO, 14.0, shadow_col)
	draw_circle(Vector2.ZERO, 8.0, Color(0.0, 0.0, 0.0, 0.20))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _physics_process(delta: float) -> void:

	if invulnerability_timer > 0.0:
		invulnerability_timer -= delta
	if might_buff_timer > 0.0:
		might_buff_timer -= delta
		if might_buff_timer <= 0.0:
			might_multiplier = 1.0
	if speed_buff_timer > 0.0:
		speed_buff_timer -= delta
		if speed_buff_timer <= 0.0:
			speed_multiplier = 1.0
	if blood_rush_timer > 0.0:
		blood_rush_timer = max(0.0, blood_rush_timer - delta)
	if thunderfire_cd > 0.0:
		thunderfire_cd = maxf(0.0, thunderfire_cd - delta)

	# Qi Shield & HP Regeneration from Nhâm Mạch
	if qi_shield_regen_rate > 0.0:
		if current_health < max_health:
			heal(qi_shield_regen_rate * delta)
		if qi_shield_current < qi_shield_max:
			qi_shield_current = min(qi_shield_max, qi_shield_current + (qi_shield_regen_rate * 0.75) * delta)
			emit_signal("qi_shield_changed", qi_shield_current, qi_shield_max)

	# Hero skill cooldown processing
	if skill_cooldown_timer > 0.0:
		# Blood Rush drains the skill cooldown 25% faster.
		skill_cooldown_timer -= delta * get_blood_rush_cooldown_rate()
		emit_signal("skill_cooldown_progress", skill_cooldown_timer, skill_cooldown_max)
		if skill_cooldown_timer <= 0.0:
			skill_cooldown_timer = 0.0
			emit_signal("skill_ready")

	if input_direction == Vector2.ZERO:
		input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_direction == Vector2.ZERO:
			var joy = get_tree().get_first_node_in_group("joystick")
			if joy and joy.has_method("get_output"):
				input_direction = joy.get_output()
			
	if input_direction.length_squared() > 0.01:
		last_move_dir = input_direction.normalized()

	# Active Hero Skill / Tactical Dash trigger
	if Input.is_action_just_pressed("dash"):
		activate_hero_skill()

	# Manual 3-Hit Signature Combo. Only the blade answers this; the other five
	# weapons keep auto-casting so the off-hand arsenal stays hands-off.
	if Input.is_action_just_pressed("ui_attack"):
		trigger_signature_combo()

	# Long Hồn (Dragon Soul Awakening) trigger
	if Input.is_action_just_pressed("ultimate_skill"):
		activate_dragon_awakening()

	# Process active Dragon Soul Awakening state
	if is_dragon_awakened:
		dragon_duration_timer -= delta
		invulnerability_timer = max(invulnerability_timer, 0.5)
		
		# Dragon Breath channeling
		dragon_breath_timer -= delta
		if dragon_breath_timer <= 0.0:
			dragon_breath_timer = 0.20
			_execute_dragon_breath()
			
		if dragon_duration_timer <= 0.0:
			revert_dragon_awakening()

	# Expansion 12: Martial Arts Scrolls (Võ Học Bí Tịch)
	if GameManager:
		if GameManager.has_scroll("yijinjing"):
			yijinjing_timer -= delta
			if yijinjing_timer <= 0.0:
				yijinjing_timer = 7.5
				_trigger_yijinjing_pulse()
				
		if GameManager.has_scroll("lucmach"):
			lucmach_timer -= delta
			if lucmach_timer <= 0.0:
				lucmach_timer = 0.65
				_fire_lucmach_beam()
				
		if GameManager.has_scroll("thaicuc"):
			_process_thaicuc_aura(delta)

	# Expansion 12: Shenron Wishes Timers
	if golden_frenzy_timer > 0.0:
		golden_frenzy_timer -= delta
		
	if van_kiem_timer > 0.0:
		van_kiem_timer -= delta
		van_kiem_interval -= delta
		if van_kiem_interval <= 0.0:
			van_kiem_interval = 0.18
			_summon_van_kiem_sword()

	if drunken_buff_timer > 0.0:
		drunken_buff_timer = max(0.0, drunken_buff_timer - delta)
		
	if is_dashing:
		dash_timer -= delta
		velocity = dash_velocity
		
		# Shield charge contact battering
		if skill_id == "shield_charge":
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and not e.get("is_dead") and global_position.distance_to(e.global_position) < 68.0:
					if e.has_method("take_damage"):
						e.take_damage(45.0 * get_might_multiplier(), global_position)
						if "knockback" in e:
							e.knockback = (e.global_position - global_position).normalized() * 500.0
							
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		var effective_speed = move_speed * speed_multiplier
		effective_speed *= get_blood_rush_speed_multiplier()
		if blizzard_slow_timer > 0.0:
			blizzard_slow_timer -= delta
			effective_speed *= 0.75
		if is_dragon_awakened:
			effective_speed *= 1.65
		elif drunken_buff_timer > 0.0:
			effective_speed *= 1.35
		var target_vel = input_direction.normalized() * effective_speed
		if input_direction != Vector2.ZERO:
			velocity = velocity.move_toward(target_vel, effective_speed * 14.0 * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, effective_speed * 18.0 * delta)
		input_direction = Vector2.ZERO

	
	var is_moving = velocity.length_squared() > 1.0
	
	# Squash-and-Stretch walking animation & Dragon flight breathing
	if sprite:
		if is_dragon_awakened:
			walk_phase += delta * 18.0
			var wing_flap = sin(walk_phase) * 0.15
			sprite.scale = Vector2(1.8 * (1.0 + wing_flap), 1.8 * (1.0 - wing_flap))
			sprite.rotation = sin(walk_phase * 0.3) * 0.08
			var aura_glow = (sin(walk_phase * 0.4) + 1.0) * 0.5
			sprite.modulate = Color(1.3 + aura_glow * 0.4, 1.1 + aura_glow * 0.2, 0.4)
			if velocity.x != 0:
				sprite.flip_h = velocity.x < 0
		elif drunken_buff_timer > 0.0:
			walk_phase += delta * 18.0
			var sway = sin(walk_phase * 0.6) * 0.15
			sprite.scale = base_sprite_scale
			sprite.rotation = sway
			sprite.modulate = Color(1.35, 1.15, 0.4)
			if velocity.x != 0:
				sprite.flip_h = velocity.x < 0
		elif is_moving:
			walk_phase += delta * 15.0
			var stretch = sin(walk_phase) * 0.10
			sprite.scale = base_sprite_scale * Vector2(1.0 + stretch, 1.0 - stretch)
			sprite.rotation = sin(walk_phase * 0.5) * 0.08
			sprite.modulate = Color.WHITE
			if velocity.x != 0:
				sprite.flip_h = velocity.x < 0
		else:
			walk_phase += delta * 3.5
			var breath = sin(walk_phase) * 0.035
			sprite.scale = base_sprite_scale * Vector2(1.0 - breath, 1.0 + breath)
			sprite.rotation = move_toward(sprite.rotation, 0.0, delta * 6.0)
			sprite.modulate = Color.WHITE

		var halo = get_node_or_null("QiHalo")
		if halo:
			var halo_pulse = 1.0 + sin(walk_phase * 2.5) * 0.08
			halo.scale = Vector2(0.65, 0.45) * halo_pulse
	
	# Dust particle effects on movement
	if dust_particles:
		dust_particles.emitting = is_moving
		if is_moving:
			dust_particles.position = Vector2(footstep_side * 6.0, 14.0)
			if sin(walk_phase) > 0.9:
				footstep_side = -footstep_side
			
	# Relic: Berserker Brand damage boost when below 40% HP
	if GameManager and GameManager.has_relic("berserker_brand"):
		var hp_ratio = current_health / max(1.0, max_health)
		if hp_ratio <= 0.40:
			might_multiplier = max(might_multiplier, 1.50)
			if sprite and not is_moving:
				var pulse = (sin(walk_phase * 3.0) + 1.0) * 0.5
				sprite.modulate = Color(1.0 + pulse * 0.6, 0.4, 0.3)
		elif might_buff_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE

	# Expansion 21.0: Blood Rush reddish-gold pulse (outranks the Berserker Brand tint)
	if blood_rush_timer > 0.0 and not is_dragon_awakened and sprite:
		var rush_pulse = (sin(walk_phase * 4.0) + 1.0) * 0.5
		sprite.modulate = Color(1.0 + rush_pulse * 0.45, 0.62 + rush_pulse * 0.28, 0.30 + rush_pulse * 0.15)

	move_and_slide()

func _update_hp_displays() -> void:
	emit_signal("health_changed", current_health, max_health)
	if overhead_hp:
		overhead_hp.max_value = max_health
		overhead_hp.value = current_health
		var ratio = current_health / max(1.0, max_health)
		var fill_sb = overhead_hp.get_theme_stylebox("fill")
		if fill_sb is StyleBoxFlat:
			if ratio < 0.30:
				fill_sb.bg_color = Color(0.92, 0.22, 0.22)
			elif ratio < 0.60:
				fill_sb.bg_color = Color(0.95, 0.65, 0.15)
			else:
				fill_sb.bg_color = Color(0.18, 0.85, 0.4)

func take_damage(amount: float) -> void:
	if current_health <= 0 or is_invulnerable:
		return
		
	# Dodge check (Cái Bang Thần Hành & Say Rượu)
	var total_dodge = char_dodge_bonus + (0.40 if drunken_buff_timer > 0.0 else 0.0)
	if total_dodge > 0.0 and randf() < total_dodge:
		invulnerability_timer = 0.25
		FloatingText.spawn(global_position + Vector2(0, -28), "💨 NÉ ĐÒN!", Color(0.35, 1.0, 0.65))
		SoundManager.play("shoot", 0.3)
		if GameManager and GameManager.has_relic("drunken_gourd"):
			_proc_drunken_gourd_splash()
		return
	
	var meta_arm = GameManager.get_meta_stat("armor") if GameManager else 0
	var equip_arm = 2 if (GameManager and GameManager.has_equipped("nhuyen_vi_giap")) else 0
	var total_armor = meta_arm + char_armor_bonus + equip_arm + shop_armor_bonus
	# Minh Giáo trades survivability for damage: 15% more of everything, applied
	# after armor so the sect's fragility is a real flat multiplier.
	var final_damage = max(1.0, amount - float(total_armor)) * char_damage_taken_mult
	if has_blood_covenant:
		final_damage *= 1.20
	
	# Nhuyễn Vị Giáp reflect 40% damage back to nearby foes
	if GameManager and GameManager.has_equipped("nhuyen_vi_giap") and final_damage > 0:
		var reflect_dmg = max(1.0, final_damage * 0.40)
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and global_position.distance_to(e.global_position) < 180.0:
				if e.has_method("take_damage"):
					e.take_damage(reflect_dmg, global_position)
		FloatingText.spawn(global_position + Vector2(0, -32), "🛡️ PHẢN THƯƠNG!", Color(1.0, 0.8, 0.2))

	
	# Nhâm Mạch Qi Shield absorption
	if qi_shield_current > 0.0:
		if qi_shield_current >= final_damage:
			qi_shield_current -= final_damage
			invulnerability_timer = 0.20
			FloatingText.spawn(global_position, "☯️ KHÍ THUẪN -%d" % int(final_damage), Color(0.3, 0.9, 1.0))
			emit_signal("qi_shield_changed", qi_shield_current, qi_shield_max)
			return
		else:
			final_damage -= qi_shield_current
			qi_shield_current = 0.0
			SoundManager.play("shield_break", 0.1)
			FloatingText.spawn(global_position, "☯️ KHÍ THUẪN VỠ!", Color(0.3, 0.9, 1.0))
			emit_signal("qi_shield_changed", 0.0, qi_shield_max)
			var cam = get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("shake"):
				cam.shake(7.0)
	
	# Relic: Phoenix Feather death prevention
	if final_damage >= current_health and GameManager and GameManager.has_relic("phoenix_feather") and not phoenix_feather_used:
		phoenix_feather_used = true
		invulnerability_timer = 2.5
		current_health = max_health * 0.40
		_update_hp_displays()
		FloatingText.spawn(global_position + Vector2(0, -28), "🔥 PHOENIX REBIRTH! 🔥", Color(1.0, 0.6, 0.1))
		SoundManager.play("powerup")
		var cam = get_tree().get_first_node_in_group("camera")
		if cam and cam.has_method("shake"):
			cam.shake(14.0)
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and global_position.distance_to(e.global_position) < 240.0:
				if e.has_method("take_damage"):
					e.take_damage(60.0, global_position)
		return
	
	invulnerability_timer = 0.35 # 0.35s i-frame on hit
	current_health = max(0.0, current_health - final_damage)
	_update_hp_displays()
	FloatingText.spawn(global_position, str(int(final_damage)), Color(1.0, 0.25, 0.25))
	SoundManager.play("hurt")
	
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(9.0)

	# Milestone 4p2: the hit itself. Shake sells the shove, hit-stop sells the
	# weight -- the 70ms of real time where the world holds still is what tells
	# the player something actually connected. GameManager owns the release, so
	# a dying player cannot leave the engine at 0.2 for the rest of the session.
	if GameManager and GameManager.has_method("trigger_hitstop"):
		GameManager.trigger_hitstop(0.07, GameManager.HITSTOP_SCALE)

	# Visual feedback: flash red & squish slightly
	modulate = Color(1.0, 0.4, 0.4)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	
	if current_health <= 0:
		die()

func apply_relic_effects() -> void:
	if not GameManager:
		return
		
	if GameManager.has_relic("golden_horseshoe"):
		relic_magnet_bonus = 60.0
		if magnet_area and magnet_area.has_node("CollisionShape2D"):
			var shape = magnet_area.get_node("CollisionShape2D").shape
			if shape is CircleShape2D:
				shape.radius = magnet_radius + char_magnet_bonus + relic_magnet_bonus
				
	if GameManager.has_relic("chrono_hourglass"):
		var wpns = [
			get_node_or_null("Weapons/MainWeapon"),
			get_node_or_null("Weapons/LightningWeapon"),
			get_node_or_null("Weapons/FireballWeapon"),
			get_node_or_null("Weapons/AxeWeapon")
		]
		for w in wpns:
			if w and "speed_multiplier" in w:
				w.speed_multiplier = max(w.speed_multiplier, 1.25)

func trigger_storm_amulet_proc(origin_pos: Vector2) -> void:
	if not GameManager or not GameManager.has_relic("storm_amulet"):
		return
	if randf() > 0.25:
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead") and origin_pos.distance_to(e.global_position) < 320.0:
			valid_enemies.append(e)
			
	if not valid_enemies.is_empty():
		var target = valid_enemies.pick_random()
		if target and target.has_method("take_damage"):
			target.take_damage(40.0, global_position)
			SoundManager.play("thunder", 0.15)
			FloatingText.spawn(target.global_position + Vector2(0, -20), "⚡ STORM PROC!", Color(0.2, 0.9, 1.0))

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	_update_hp_displays()
	if amount >= 5.0:
		FloatingText.spawn(global_position, "+%d HP" % int(amount), Color(0.25, 0.95, 0.45))

func apply_might_buff(duration: float = 25.0, mult: float = 1.4) -> void:
	might_buff_timer = max(might_buff_timer, duration)
	might_multiplier = mult
	FloatingText.spawn(global_position + Vector2(0, -32), "⚔️ MIGHT SURGE! +40% DMG", Color(1.0, 0.45, 0.2))

func apply_speed_buff(duration: float = 20.0, mult: float = 1.5) -> void:
	speed_buff_timer = max(speed_buff_timer, duration)
	speed_multiplier = mult
	FloatingText.spawn(global_position + Vector2(0, -32), "💨 WIND SURGE! +50% SPD", Color(0.25, 1.0, 0.65))

## Every weapon funnels its damage through here, so this is the one place the
## Nga Mi -15% base-damage trade-off has to be applied -- folding it in any other
## spot would miss whichever weapon nobody remembered to patch.
func get_might_multiplier() -> float:
	return (1.0 + meta_might_bonus) * might_multiplier * char_damage_mult

## Minh Giáo's +60% elemental burn, read by enemy.apply_burn() -- the single
## point every burn source (fireball, spirit sword, dragon breath) routes through.
func get_burn_multiplier() -> float:
	return char_burn_mult

## Lôi Hỏa Liên Hoàn: every crit detonates. enemy.take_damage() holds the only crit
## roll in the game, so that one call site is the entire hook -- no weapon has to
## know this passive exists. The cooldown is set before the sweep so the damage this
## deals (which can itself crit) cannot chain into a second detonation.
func trigger_thunderfire_burst(origin_pos: Vector2) -> void:
	if not has_thunderfire or thunderfire_cd > 0.0:
		return
	thunderfire_cd = THUNDERFIRE_COOLDOWN

	var dmg := THUNDERFIRE_DAMAGE * get_might_multiplier()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.get("is_dead"):
			continue
		if e.global_position.distance_to(origin_pos) > THUNDERFIRE_RADIUS:
			continue
		if e.has_method("take_damage"):
			e.take_damage(dmg, origin_pos)
		if e.has_method("apply_burn"):
			e.apply_burn(3.0, 14.0)

	_spawn_skill_shockwave(Color(1.0, 0.45, 0.15, 0.85), THUNDERFIRE_RADIUS)
	SoundManager.play("explosion", 0.25)

## Vạn Kiếm Quy Tông: the blade calls the swarm. Called from slash_weapon after a
## connecting sweep -- a whiffed slash sends nothing, so the reward tracks the hit
## rather than the swing.
func release_sword_qi(targets: Array) -> void:
	if not has_thousand_swords:
		return
	var sword_scene := load("res://scenes/spirit_sword_projectile.tscn")
	if not sword_scene:
		return

	for i in range(SWORD_QI_PER_SLASH):
		var sword = sword_scene.instantiate()
		var anchor: Node2D = targets[i % targets.size()] if not targets.is_empty() else self
		sword.global_position = global_position
		var aim := (anchor.global_position - global_position).normalized()
		sword.direction = aim if aim != Vector2.ZERO else Vector2.RIGHT
		sword.damage = SWORD_QI_DAMAGE * get_might_multiplier()
		sword.pierce = 2
		sword.homing = true
		var p := get_parent()
		if p:
			p.add_child(sword)
		else:
			add_child(sword)
	SoundManager.play("qi_laser", 0.12)

## Expansion 21.0: Vạn Nhân Trảm — Blood Rush rampage buff.
func activate_blood_rush(duration: float = BLOOD_RUSH_DURATION) -> void:
	blood_rush_timer = max(blood_rush_timer, duration)
	FloatingText.spawn(global_position + Vector2(0, -40), "🩸 CUỒNG BẠO! +20% TỐC ĐỘ / +25% HỒI CHIÊU", Color(1.0, 0.35, 0.25))
	_spawn_skill_shockwave(Color(1.0, 0.4, 0.2, 0.8), 120.0)

func get_blood_rush_speed_multiplier() -> float:
	return BLOOD_RUSH_SPEED_MULT if blood_rush_timer > 0.0 else 1.0

func get_blood_rush_cooldown_rate() -> float:
	return BLOOD_RUSH_COOLDOWN_RATE if blood_rush_timer > 0.0 else 1.0

func revive(health_percentage: float = 0.5) -> void:
	current_health = max_health * health_percentage
	_update_hp_displays()
	modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.3, 0.1).set_loops(6)
	tween.chain().tween_property(self, "modulate:a", 1.0, 0.1)

func die() -> void:
	if is_dragon_awakened:
		revert_dragon_awakening()
	emit_signal("died")

func add_xp(amount: float) -> void:
	var mult = char_xp_mult
	if GameManager and GameManager.is_blood_moon:
		mult *= 2.0
	current_xp += amount * mult
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1
		xp_to_next_level = floor(xp_to_next_level * 1.35 + 5.0)
		SoundManager.play("level_up")
		emit_signal("leveled_up", level)
	
	emit_signal("xp_changed", current_xp, xp_to_next_level, level)

func perform_dash(dir: Vector2 = Vector2.ZERO) -> void:
	var dash_dir = dir
	if dash_dir == Vector2.ZERO:
		dash_dir = last_move_dir if last_move_dir != Vector2.ZERO else Vector2.RIGHT
	dash_dir = dash_dir.normalized()
	is_dashing = true
	dash_timer = 0.25
	dash_velocity = dash_dir * 540.0
	invulnerability_timer = max(invulnerability_timer, 0.25)
	SoundManager.play("shoot", 0.25)
	FloatingText.spawn(global_position + Vector2(0, -28), "💨 THÂN PHÁP!", Color(0.35, 1.0, 0.65))

func activate_hero_skill() -> bool:
	if skill_cooldown_timer > 0.0 or current_health <= 0:
		return false
		
	var cd_mult = 0.8 if (GameManager and GameManager.has_relic("chrono_hourglass")) else 1.0
	skill_cooldown_timer = skill_cooldown_max * cd_mult
	emit_signal("skill_used", skill_id, skill_cooldown_timer)
	
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir = input_direction.normalized() if input_direction.length_squared() > 0.01 else last_move_dir
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
		
	match skill_id:
		"shield_charge":
			is_dashing = true
			dash_timer = 0.35
			dash_velocity = dir * 560.0
			invulnerability_timer = 0.90
			FloatingText.spawn(global_position + Vector2(0, -32), "🛡️ SHIELD CHARGE!", Color(0.3, 0.9, 1.0))
			SoundManager.play("powerup", 0.15)
			var cam = get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("shake"):
				cam.shake(8.0)
			_spawn_skill_shockwave(Color(0.2, 0.8, 1.0, 0.8), 50.0)
			
		"inferno_blink":
			invulnerability_timer = 0.50
			var start_pos = global_position
			var target_pos = global_position + dir * 200.0
			global_position = target_pos
			FloatingText.spawn(target_pos + Vector2(0, -32), "🔥 INFERNO BLINK!", Color(1.0, 0.5, 0.1))
			SoundManager.play("powerup", 0.2)
			var cam = get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("shake"):
				cam.shake(8.0)
			_spawn_skill_shockwave(Color(1.0, 0.4, 0.1, 0.8), 70.0)
			
			# Scorched damage to nearby enemies at origin & destination
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and not e.get("is_dead"):
					var d1 = start_pos.distance_to(e.global_position)
					var d2 = target_pos.distance_to(e.global_position)
					if d1 < 95.0 or d2 < 95.0:
						if e.has_method("take_damage"):
							e.take_damage(70.0 * get_might_multiplier(), target_pos)
							
		"shadow_roll":
			is_dashing = true
			dash_timer = 0.28
			dash_velocity = dir * 620.0
			invulnerability_timer = 0.65
			FloatingText.spawn(global_position + Vector2(0, -32), "💨 SHADOW ROLL!", Color(0.25, 1.0, 0.6))
			SoundManager.play("shoot", 0.2)
			var cam = get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("shake"):
				cam.shake(6.0)
				
			# Radial volley of 10 piercing shadow daggers
			var main_wpn = get_node_or_null("Weapons/MainWeapon")
			var p_scene = main_wpn.projectile_scene if main_wpn and "projectile_scene" in main_wpn else null
			if p_scene:
				var count = 10
				var step = TAU / float(count)
				for i in range(count):
					var p = p_scene.instantiate()
					if p:
						var p_dir = Vector2(cos(i * step), sin(i * step))
						p.direction = p_dir
						p.damage = 25.0 * get_might_multiplier()
						p.pierce = 2
						p.speed = 520.0
						p.global_position = global_position
						get_tree().current_scene.call_deferred("add_child", p)
						
		"frost_singularity":
			invulnerability_timer = 0.60
			FloatingText.spawn(global_position + Vector2(0, -35), "❄️ FROST STASIS NOVA!", Color(0.4, 0.9, 1.0))
			SoundManager.play("thunder", 0.25)
			var cam = get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("shake"):
				cam.shake(10.0)
			_spawn_skill_shockwave(Color(0.4, 0.85, 1.0, 0.9), 280.0)
			
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and not e.get("is_dead") and global_position.distance_to(e.global_position) <= 280.0:
					if e.has_method("apply_freeze"):
						e.apply_freeze(2.4)
					if e.has_method("take_damage"):
						var frost_dmg = 35.0 * get_might_multiplier()
						if GameManager and GameManager.selected_stage == "mount_hua":
							frost_dmg *= 1.50
						e.take_damage(frost_dmg, global_position)

						
		"drunken_brew":
			drunken_buff_timer = 6.0
			invulnerability_timer = 0.50
			FloatingText.spawn(global_position + Vector2(0, -35), "🍶 SAY RƯỢU BÁT TIÊN!", Color(1.0, 0.85, 0.2))
			SoundManager.play("wine_drink", 0.1)
			var cam = get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("shake"):
				cam.shake(8.0)
			_spawn_skill_shockwave(Color(1.0, 0.82, 0.2, 0.9), 160.0)
			
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and not e.get("is_dead") and global_position.distance_to(e.global_position) <= 160.0:
					if e.has_method("take_damage"):
						e.take_damage(35.0 * get_might_multiplier(), global_position)
					if "knockback" in e:
						e.knockback = (e.global_position - global_position).normalized() * 450.0
						
		_:
			# Default dash
			is_dashing = true
			dash_timer = 0.3
			dash_velocity = dir * 500.0
			invulnerability_timer = 0.5
			FloatingText.spawn(global_position, "DASH!", Color.WHITE)
			
	return true

func _spawn_skill_shockwave(color: Color, radius: float) -> void:
	var p = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 24
	p.lifetime = 0.45
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = radius * 1.4
	p.initial_velocity_max = radius * 2.2
	p.scale_amount_min = 2.5
	p.scale_amount_max = 4.5
	p.color = color
	p.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", p)
	var t = get_tree().create_timer(0.5)
	t.timeout.connect(p.queue_free)

func _on_magnet_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("gems") and area.has_method("target_player"):
		area.target_player(self)

func add_dragon_soul(amount: float) -> void:
	if is_dragon_awakened or current_health <= 0:
		return
	var final_amount = amount * dragon_soul_harvest_mult
	var old_soul = dragon_soul
	dragon_soul = min(dragon_soul_max, dragon_soul + final_amount)
	emit_signal("dragon_soul_changed", dragon_soul, dragon_soul_max)
	if old_soul < dragon_soul_max and dragon_soul >= dragon_soul_max:
		FloatingText.spawn(global_position + Vector2(0, -36), "🐉 LONG HỒN ĐẦY! [R] 🐉", Color(1.0, 0.85, 0.2))
		SoundManager.play("powerup", 0.1)

func activate_dragon_awakening() -> bool:
	if dragon_soul < dragon_soul_max or is_dragon_awakened or current_health <= 0:
		return false
		
	dragon_soul = 0.0
	emit_signal("dragon_soul_changed", 0.0, dragon_soul_max)
	is_dragon_awakened = true
	dragon_duration_timer = dragon_duration_max
	invulnerability_timer = dragon_duration_max
	
	# Swap to Golden Celestial Dragon form
	if sprite:
		if original_texture == null:
			original_texture = sprite.texture
		if dragon_texture == null:
			if ResourceLoader.exists("res://assets/textures/dragon_form.png"):
				dragon_texture = load("res://assets/textures/dragon_form.png")
			elif FileAccess.file_exists("res://assets/textures/dragon_form.png"):
				var img = Image.load_from_file("res://assets/textures/dragon_form.png")
				if img:
					dragon_texture = ImageTexture.create_from_image(img)
					dragon_texture.take_over_path("res://assets/textures/dragon_form.png")
		if dragon_texture:
			sprite.texture = dragon_texture
			
	SoundManager.play("dragon_roar", 0.05)
	var cam = get_tree().get_first_node_in_group("camera")
	if cam and cam.has_method("shake"):
		cam.shake(16.0)
		
	FloatingText.spawn(global_position + Vector2(0, -40), "🐉 KIM LONG THÁNH GIÁNG! 🐉", Color(1.0, 0.85, 0.15))
	_spawn_skill_shockwave(Color(1.0, 0.8, 0.2, 0.9), 180.0)
	emit_signal("dragon_awakened", dragon_duration_max)
	return true

func revert_dragon_awakening() -> void:
	if not is_dragon_awakened:
		return
	is_dragon_awakened = false
	dragon_duration_timer = 0.0
	if sprite and original_texture:
		sprite.texture = original_texture
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2(1.4, 1.4)
	FloatingText.spawn(global_position + Vector2(0, -28), "Long Hồn Tiêu Tán", Color(0.85, 0.85, 0.95))
	emit_signal("dragon_ended")

func _execute_dragon_breath() -> void:
	SoundManager.play("dragon_breath", 0.18)
	var enemies = get_tree().get_nodes_in_group("enemies")
	var breath_radius = 210.0
	var breath_damage = 55.0 * get_might_multiplier()
	
	# Spawn fiery golden particles in aura
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.amount = 18
	particles.lifetime = 0.35
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 190.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.5
	particles.color = Color(1.0, 0.75, 0.15)
	particles.global_position = global_position
	get_tree().current_scene.add_child(particles)
	var t = get_tree().create_timer(0.4)
	t.timeout.connect(particles.queue_free)
	
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			var dist = global_position.distance_to(e.global_position)
			if dist <= breath_radius:
				if e.has_method("take_damage"):
					e.take_damage(breath_damage, global_position)
				if e.has_method("apply_burn"):
					e.apply_burn(4.0, 22.0)
				if "knockback" in e:
					e.knockback = (e.global_position - global_position).normalized() * 420.0

func _spawn_companion() -> void:
	var existing = get_tree().get_nodes_in_group("companions")
	if not existing.is_empty():
		return
	var comp_scene = load("res://scenes/companion.tscn")
	if comp_scene:
		var comp = comp_scene.instantiate()
		var chosen_id = GameManager.selected_companion if GameManager else "dragon_whelp"
		comp.companion_id = chosen_id
		comp.global_position = global_position + Vector2(-36, -28)
		var p = get_parent()
		if p:
			p.call_deferred("add_child", comp)
		else:
			call_deferred("add_child", comp)

func apply_scroll_effects() -> void:
	pass

func _trigger_yijinjing_pulse() -> void:
	SoundManager.play("buddha_gong", 0.15)
	FloatingText.spawn(global_position + Vector2(0, -32), "🦁 SƯ TỬ HỐNG! 卍", Color(1.0, 0.85, 0.2))
	var pulse_radius = 260.0
	var pulse_damage = 80.0 * get_might_multiplier()
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			var dist = global_position.distance_to(e.global_position)
			if dist <= pulse_radius:
				if e.has_method("take_damage"):
					e.take_damage(pulse_damage, global_position)
				if "knockback" in e:
					e.knockback = (e.global_position - global_position).normalized() * 450.0
				if e.has_method("apply_freeze"):
					e.apply_freeze(1.5)

func _fire_lucmach_beam() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_target: Node2D = null
	var min_d_sq = 450.0 * 450.0
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			var d_sq = global_position.distance_squared_to(e.global_position)
			if d_sq < min_d_sq:
				min_d_sq = d_sq
				best_target = e
	if not best_target:
		return
	var sword_scene = load("res://scenes/spirit_sword_projectile.tscn")
	if not sword_scene:
		return
	var sword = sword_scene.instantiate()
	sword.global_position = global_position
	sword.direction = (best_target.global_position - global_position).normalized()
	sword.damage = 35.0 * get_might_multiplier()
	sword.pierce = 3
	var p = get_parent()
	if p:
		p.add_child(sword)
	else:
		add_child(sword)
	SoundManager.play("qi_laser", 0.12)

func _process_thaicuc_aura(delta: float) -> void:
	thaicuc_tick_timer -= delta
	var radius = 130.0
	var r_sq = radius * radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			if global_position.distance_squared_to(e.global_position) <= r_sq:
				if e.has_method("apply_slow"):
					e.apply_slow(0.5, 0.50)
				if thaicuc_tick_timer <= 0.0 and e.has_method("take_damage"):
					e.take_damage(15.0 * get_might_multiplier() * 0.5, global_position)
	if thaicuc_tick_timer <= 0.0:
		thaicuc_tick_timer = 0.5

func _summon_van_kiem_sword() -> void:
	var sword_scene = load("res://scenes/spirit_sword_projectile.tscn")
	if not sword_scene:
		return
	var sword = sword_scene.instantiate()
	var spawn_pos = global_position + Vector2(randf_range(-280, 280), -340.0)
	var target_enemies = get_tree().get_nodes_in_group("enemies")
	var target_pos = global_position + Vector2(randf_range(-160, 160), randf_range(-160, 160))
	if not target_enemies.is_empty():
		var random_enemy = target_enemies[randi() % target_enemies.size()]
		if is_instance_valid(random_enemy):
			target_pos = random_enemy.global_position
	sword.global_position = spawn_pos
	sword.direction = (target_pos - spawn_pos).normalized()
	sword.damage = 60.0 * get_might_multiplier()
	sword.pierce = 5
	var p = get_parent()
	if p:
		p.add_child(sword)
	else:
		add_child(sword)
	SoundManager.play("qi_laser", 0.07)

func apply_shenron_wish(wish_id: String) -> void:
	match wish_id:
		"wish_wealth":
			GameManager.add_gold(1500)
			golden_frenzy_timer = 30.0
			FloatingText.spawn(global_position + Vector2(0, -36), "💰 KIM SƠN BẠC HẢI! +1500 VÀNG", Color(1.0, 0.85, 0.2))
		"wish_immortality":
			max_health += 100.0
			current_health = max_health
			qi_shield_max += 50.0
			qi_shield_current = qi_shield_max
			phoenix_feather_used = false
			_update_hp_displays()
			emit_signal("qi_shield_changed", qi_shield_current, qi_shield_max)
			FloatingText.spawn(global_position + Vector2(0, -36), "☯️ BẤT TỬ CHÂN THÂN! +100 HP +50 KHÍ THUẪN", Color(0.2, 0.9, 0.6))
		"wish_swords":
			van_kiem_timer = 20.0
			FloatingText.spawn(global_position + Vector2(0, -36), "⚔️ VẠN KIẾM QUY TÔNG! ⚔️", Color(0.3, 0.8, 1.0))
			var cam = get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("shake"):
				cam.shake(12.0)

func _proc_drunken_gourd_splash() -> void:
	SoundManager.play("wine_drink", 0.15)
	FloatingText.spawn(global_position + Vector2(0, -42), "🍶 RƯỢU THÁNH TRẢM MA (120)!", Color(1.0, 0.85, 0.2))
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead") and global_position.distance_to(e.global_position) <= 140.0:
			if e.has_method("take_damage"):
				e.take_damage(120.0 * get_might_multiplier(), global_position)

func apply_demonic_pact(pact_id: String) -> void:
	match pact_id:
		"blood_covenant":
			has_blood_covenant = true
			current_health = max(10.0, current_health * 0.65)
			might_multiplier += 0.45
			_update_hp_displays()
			FloatingText.spawn(global_position + Vector2(0, -35), "🩸 HUYẾT KHẾ: +45% SÁT THƯƠNG!", Color(1.0, 0.2, 0.2))
		"abyssal_frenzy":
			has_abyssal_frenzy = true
			var spawner = get_tree().get_first_node_in_group("spawner")
			if spawner:
				if "spawn_interval" in spawner:
					spawner.spawn_interval *= 0.70
			FloatingText.spawn(global_position + Vector2(0, -35), "👹 TÀ KHÍ: QUÁI TĂNG TỐC & 2x XP/VÀNG!", Color(0.8, 0.3, 1.0))
		"hermit_sacrifice":
			has_hermit_sacrifice = true
			qi_shield_max = 0.0
			qi_shield_current = 0.0
			emit_signal("qi_shield_changed", 0.0, 0.0)
			if GameManager:
				GameManager.add_gold(500)
				var chest_res = load("res://scenes/chest.tscn")
				if chest_res:
					var ch = chest_res.instantiate()
					ch.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
					get_tree().current_scene.call_deferred("add_child", ch)
			FloatingText.spawn(global_position + Vector2(0, -35), "🚫 ĐỘC CÔ: PHONG ẤN KHÍ THUẪN | +500 VÀNG & RƯƠNG!", Color(1.0, 0.75, 0.1))

func apply_blizzard_slow(duration: float = 3.0) -> void:
	if GameManager and GameManager.has_equipped("van_hac_hai"):
		FloatingText.spawn(global_position + Vector2(0, -28), "🥾 MIỄN NHIỄM HÀN BĂNG!", Color(0.4, 0.95, 0.6))
		return
	blizzard_slow_timer = duration
	FloatingText.spawn(global_position + Vector2(0, -28), "❄️ HÀN KHÍ LÀM CHẬM!", Color(0.4, 0.85, 1.0))

func apply_hermit_item(item_id: String) -> void:
	SoundManager.play("elixir_drink", 0.1)
	match item_id:
		"cuu_chuyen_dan":
			max_health *= 1.15
			current_health = max_health
			qi_shield_current = qi_shield_max
			_update_hp_displays()
			emit_signal("qi_shield_changed", qi_shield_current, qi_shield_max)
			FloatingText.spawn(global_position + Vector2(0, -35), "💊 CỬU CHUYỂN HOÀN HỒN: FULL HP & +15% MAX HP!", Color(0.2, 1.0, 0.4))
		"tay_tuy_dan":
			might_multiplier += 0.20
			var main_wpn = get_node_or_null("Weapons/MainWeapon")
			if main_wpn and "speed_multiplier" in main_wpn:
				main_wpn.speed_multiplier += 0.15
			FloatingText.spawn(global_position + Vector2(0, -35), "⚡ TẨY TỦY HOÁN CỐT: +20% SÁT THƯƠNG & +15% TỐC ĐÁNH!", Color(1.0, 0.85, 0.2))
		"van_menh_que":
			if randf() < 0.70:
				FloatingText.spawn(global_position + Vector2(0, -35), "🎲 ĐẠI CÁT ĐẠI LỢI: +2 RƯƠNG BÁU & 200 VÀNG!", Color(1.0, 0.85, 0.1))
				SoundManager.play("powerup")
				if GameManager:
					GameManager.add_gold(200)
				var chest_res = load("res://scenes/chest.tscn")
				if chest_res:
					for i in range(2):
						var ch = chest_res.instantiate()
						ch.global_position = global_position + Vector2(randf_range(-35, 35), randf_range(-35, 35))
						get_tree().current_scene.call_deferred("add_child", ch)
			else:
				FloatingText.spawn(global_position + Vector2(0, -35), "⚠️ HẠ HẠ QUẺ: YÊU MA XUẤT HIỆN!", Color(1.0, 0.2, 0.2))
				SoundManager.play("thunder", 0.2)
				var spawner = get_tree().get_first_node_in_group("spawner")
				if spawner and spawner.has_method("spawn_specific_enemy"):
					for i in range(2):
						var offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(90, 150)
						spawner.spawn_specific_enemy("skeleton_brute", global_position + offset)




