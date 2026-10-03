class_name SlashWeapon
extends Node2D

## Directional Sweeping Sword Arc (Độc Cô Cửu Kiếm):
## Attacks along the player's movement direction / facing orientation rather than pure auto-aim.
## Features punchy multi-target cleave damage, camera screen shake, and crisp audio.
## Expansion 20.0: Băng Phách Thần Kiếm (Frost Sovereign) synergy fusion — Slash Lv.5 + Shield Lv.5.

@export var base_damage: float = 38.0
@export var base_cooldown: float = 1.0
@export var slash_range: float = 110.0
@export var slash_angle_deg: float = 120.0
@export var is_active: bool = true

# Expansion 20.0: Tinh Võ Hợp Nhất — Băng Phách Thần Kiếm.
# slash_arc is in RADIANS; > 0 overrides slash_angle_deg. 0.0 == no override.
var is_frost_sovereign: bool = false
var slash_damage: float = 0.0
var slash_arc: float = 0.0
const FROST_SOVEREIGN_FREEZE: float = 1.5

var cooldown_timer: float = 0.0
var damage_multiplier: float = 1.0
## Fusion tier multiplier pushed in by UpgradeManager.apply_arsenal_bonuses().
var tier_damage_mult: float = 1.0
var speed_multiplier: float = 1.0
var is_evolved: bool = false

var facing_direction: Vector2 = Vector2.RIGHT
var last_slash_direction: Vector2 = Vector2.RIGHT
var slash_texture: Texture2D = null

# --- Milestone 1: manual 3-Hit Signature Combo --------------------------------
## The blade is the player's active weapon; the other five auto-cast. Mashing
## ui_attack walks Nhất Kiếm -> Song Phong -> Cửu Kiếm Quy Tông, then the chain
## breaks and reopens at step 0. Letting the combo lapse past COMBO_RESET_TIME
## (or simply never clicking) falls back to the old auto-slash.
const COMBO_RESET_TIME: float = 0.8
const COMBO_ARC: Array[float] = [120.0, 150.0, 220.0]
const COMBO_MULT: Array[float] = [1.0, 1.35, 2.2]
const COMBO_RECOVERY: Array[float] = [0.2, 0.22, 0.32]
## Milestone 3b: knockback now runs ALONG the blade, not radially away from the
## player, and the finisher hits nearly twice as hard. A swing throws the mob the
## way you were already cutting, which is what makes a clean arc into a pile
## read as a pile. Cửu Kiếm Quy Tông is meant to be the payoff, not step three.
const COMBO_KNOCKBACK: Array[float] = [240.0, 240.0, 450.0]
## The finisher's camera kick goes 6.0 -> 8.0. Two swings nudge the frame; the
## Cửu Kiếm Quy Tông punches it.
const COMBO_SHAKE: Array[float] = [5.5, 5.5, 8.0]
const COMBO_NAMES: Array[String] = ["Nhất Kiếm", "Song Phong", "Cửu Kiếm Quy Tông"]
## Song Phong is the backhand: the cone bisector sits off the facing axis so the
## blade sweeps the target the other way round.
const COMBO_REVERSE_OFFSET_DEG: float = 75.0

var combo_step: int = 0
var combo_reset_timer: float = 0.0

func _ready() -> void:
	slash_texture = load("res://assets/textures/slash_arc.png")

func _process(delta: float) -> void:
	if not is_active:
		return
		
	# Update facing direction tracking player movement
	var current_facing = _get_facing_direction()
	if current_facing != Vector2.ZERO:
		facing_direction = current_facing
		
	cooldown_timer -= delta
	# The chain only holds while the player keeps swinging; let it lapse and the
	# next hit reopens at Nhất Kiếm.
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_reset_timer = 0.0
			combo_step = 0
	if cooldown_timer <= 0.0:
		# Auto fallback always plays the plain opening strike; the finisher is
		# earned by the player clicking through the chain.
		perform_slash()
		cooldown_timer = max(0.18, base_cooldown / (speed_multiplier * _get_player_attack_speed()))

## Player-driven swing. Returns false when the blade is still in recovery.
func trigger_combo_attack() -> bool:
	if not is_active or cooldown_timer > 0.0:
		return false
	var step := combo_step
	perform_slash(Vector2.ZERO, step)
	combo_step = (combo_step + 1) % 3
	combo_reset_timer = COMBO_RESET_TIME
	cooldown_timer = COMBO_RECOVERY[step]
	return true

func combo_damage_mult_for(step: int) -> float:
	return COMBO_MULT[clampi(step, 0, COMBO_MULT.size() - 1)]

func combo_arc_for(step: int) -> float:
	return COMBO_ARC[clampi(step, 0, COMBO_ARC.size() - 1)]

## Milestone 3b: where the blade points. Priority is right stick, then the mouse
## cursor, then travel direction, then the last committed facing.
##
## The cursor is the primary aim for every PC player because it is the one thing
## they are actually pointing with -- a click must put the blade where the
## pointer is, not wherever they last walked. Touchscreens are excluded: there
## is no cursor there, and the virtual joystick's last_move_dir is the honest
## answer. A cursor parked on top of the player (< 20px) is not an aim
## direction, so it falls through instead of jittering the blade.
func _get_facing_direction() -> Vector2:
	var aim := _get_stick_aim()
	if aim != Vector2.ZERO:
		return aim
	var p = _get_player()
	if is_instance_valid(p):
		if not DisplayServer.is_touchscreen_available():
			var to_cursor: Vector2 = get_global_mouse_position() - p.global_position
			if to_cursor.length() > 20.0:
				return to_cursor.normalized()
		if "last_move_dir" in p and p.last_move_dir != Vector2.ZERO:
			return p.last_move_dir.normalized()
		elif "velocity" in p and p.velocity.length_squared() > 0.01:
			return p.velocity.normalized()
	if facing_direction != Vector2.ZERO:
		return facing_direction.normalized()
	return Vector2.RIGHT

## Right analog stick as a direction, or ZERO when it is at rest. The actions are
## declared in project.godot with a 0.35 deadzone, so a resting stick reads zero
## and the mouse/keyboard path stays in charge.
static func _get_stick_aim() -> Vector2:
	if not InputMap.has_action("aim_left"):
		return Vector2.ZERO
	var v := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	return v.normalized() if v.length() > 0.15 else Vector2.ZERO

func _get_player() -> Node2D:
	var p = get_parent()
	while p != null:
		if p is CharacterBody2D or p.is_in_group("player"):
			return p as Node2D
		p = p.get_parent()
	return get_tree().get_first_node_in_group("player") if get_tree() else null

func _get_player_might() -> float:
	var p = _get_player()
	if is_instance_valid(p) and p.has_method("get_might_multiplier"):
		return p.get_might_multiplier()
	return 1.0

## Expansion 22.0: Tà Ma Lệnh Bài's +15% attack speed below 50% HP. Divided into
## the cooldown here rather than multiplied into speed_multiplier, so the relic
## applies to a weapon bought mid-rage and cannot compound while the player is
## already under the threshold.
func _get_player_attack_speed() -> float:
	var p = _get_player()
	if is_instance_valid(p) and p.has_method("get_attack_speed_multiplier"):
		return p.get_attack_speed_multiplier()
	return 1.0

## Đường Môn trades the blade for the blade-thrower: their melee is half a hit.
func _get_slash_multiplier() -> float:
	var p = _get_player()
	return p.char_slash_damage_mult if is_instance_valid(p) and "char_slash_damage_mult" in p else 1.0

func _get_combo_heal() -> float:
	var p = _get_player()
	return p.char_combo_heal if is_instance_valid(p) and "char_combo_heal" in p else 0.0

func perform_slash(override_dir: Vector2 = Vector2.ZERO, combo_step_override: int = -1) -> Array[Node2D]:
	var step := 0 if combo_step_override < 0 else clampi(combo_step_override, 0, 2)
	var facing = override_dir if override_dir != Vector2.ZERO else _get_facing_direction()
	facing = facing.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.RIGHT

	facing_direction = facing
	last_slash_direction = facing

	# Spawn visual arc animation
	_spawn_slash_visual(facing, step)

	# Crisp audio
	if SoundManager.sounds.has("slash"):
		SoundManager.play("slash", 0.15)
	else:
		SoundManager.play("axe", 0.15)

	# Screen shake
	var cam = get_tree().get_first_node_in_group("camera") if get_tree() else null
	if cam and cam.has_method("shake"):
		cam.shake(COMBO_SHAKE[step] if not is_evolved else COMBO_SHAKE[step] + 4.0)

	var hit_enemies: Array[Node2D] = []
	if not get_tree():
		return hit_enemies

	var enemies = get_tree().get_nodes_in_group("enemies")
	# The combo arc is a floor, not an override: an evolution (180° cleave, 220°
	# Frost Sovereign) still opens the cone wider than the bare opening strike.
	var evolution_arc := slash_arc if slash_arc > 0.0 else deg_to_rad(180.0 if is_evolved else slash_angle_deg)
	var cos_half = cos(maxf(evolution_arc, deg_to_rad(COMBO_ARC[step])) / 2.0)
	# Song Phong swings backhand; knockback still shoves away from the player.
	var cone_dir: Vector2 = facing.rotated(deg_to_rad(COMBO_REVERSE_OFFSET_DEG)) if step == 1 else facing

	var effective_range = slash_range * (1.35 if is_evolved else 1.0)
	if GameManager and GameManager.has_equipped("y_thien_kiem"):
		effective_range *= 1.25

	var base_hit_damage = slash_damage if slash_damage > 0.0 else (base_damage if not is_evolved else 75.0)
	var eff_dmg = base_hit_damage * damage_multiplier * tier_damage_mult * COMBO_MULT[step] * _get_player_might()
	eff_dmg *= _get_slash_multiplier()
	if GameManager and GameManager.has_equipped("y_thien_kiem"):
		eff_dmg *= 1.15

	# Nga Mi's Cửu Kiếm Quy Tông is a sip of life as much as a kill. Charged
	# before the sweep so the heal lands even on a whiffed finisher.
	if step == 2 and _get_combo_heal() > 0.0:
		var player := _get_player()
		if is_instance_valid(player) and player.has_method("heal"):
			player.heal(_get_combo_heal())
			FloatingText.spawn(player.global_position + Vector2(0, -40), "🩸 HỒI MÁU!", Color(0.35, 1.0, 0.6))

	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			var to_e = e.global_position - global_position
			var dist = to_e.length()
			if dist <= effective_range:
				var e_dir = to_e.normalized() if dist > 0.001 else facing
				var dot = cone_dir.dot(e_dir)
				# Check if within directional sweeping arc cone
				if dot >= (cos_half - 0.001):
					hit_enemies.append(e)
					if e.has_method("take_damage"):
						e.take_damage(eff_dmg, global_position)
						GameManager.record_weapon_damage("slash", eff_dmg)
					if "knockback" in e:
						e.knockback = facing * (COMBO_KNOCKBACK[step] * (1.6 if is_evolved else 1.0))
					# Frost Sovereign: freeze non-boss targets solid for 1.5s
					if is_frost_sovereign and "freeze_timer" in e and not e.get("is_boss"):
						e.freeze_timer = FROST_SOVEREIGN_FREEZE
						FloatingText.spawn(e.global_position + Vector2(0, -30), "❄️ BĂNG PHÁCH!", Color(0.45, 0.95, 1.0))
					FloatingText.spawn(e.global_position + Vector2(0, -18), "⚔️ TRẢM!", Color(0.4, 0.95, 1.0))

	# Milestone 3: Vạn Kiếm Quy Tông -- a connecting sweep calls the swarm. A
	# whiffed slash sends nothing, so the reward tracks the hit, not the swing.
	if not hit_enemies.is_empty():
		var qi_player := _get_player()
		if is_instance_valid(qi_player) and qi_player.has_method("release_sword_qi"):
			qi_player.release_sword_qi(hit_enemies)

	return hit_enemies

func _spawn_slash_visual(facing: Vector2, step: int = 0) -> void:
	if not slash_texture:
		slash_texture = load("res://assets/textures/slash_arc.png")
	if not slash_texture or not get_tree():
		return

	var slash_sprite = Sprite2D.new()
	slash_sprite.texture = slash_texture
	slash_sprite.top_level = true

	# Song Phong reads as a backhand: mirrored sprite, thrown from the off-hand side.
	var visual_dir := facing.rotated(deg_to_rad(COMBO_REVERSE_OFFSET_DEG)) if step == 1 else facing
	var offset_dist = [40.0, 34.0, 62.0][step] * (1.35 if is_evolved else 1.0)
	slash_sprite.global_position = global_position + visual_dir * offset_dist
	slash_sprite.rotation = visual_dir.angle()

	var base_scale = Vector2(2.4, 2.4) if not is_evolved else Vector2(3.6, 3.6)
	# The finisher is a shockwave, not a cleave -- draw it wider and hotter.
	base_scale *= [1.0, 0.95, 1.55][step]
	slash_sprite.scale = base_scale * 0.7
	if step == 1:
		slash_sprite.scale.x = -slash_sprite.scale.x
	if not is_evolved and step == 2:
		slash_sprite.modulate = Color(1.4, 0.95, 0.35, 0.98)
	else:
		slash_sprite.modulate = Color(0.4, 0.9, 1.2, 0.95) if not is_evolved else Color(1.3, 1.1, 0.3, 0.95)
	
	var scene = get_tree().current_scene
	if not scene:
		scene = get_parent()
	if scene:
		scene.add_child(slash_sprite)
		var tw = slash_sprite.create_tween()
		if tw:
			tw.set_parallel(true)
			tw.tween_property(slash_sprite, "scale", base_scale * 1.35, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(slash_sprite, "modulate:a", 0.0, 0.20)
			tw.chain().tween_callback(slash_sprite.queue_free)
		else:
			slash_sprite.queue_free()

func upgrade_damage(amount: float = 0.35) -> void:
	damage_multiplier += amount

func upgrade_speed(amount: float = 0.25) -> void:
	speed_multiplier += amount

func upgrade_range(amount: float = 0.25) -> void:
	slash_range *= (1.0 + amount)

func evolve_to_nine_swords() -> void:
	is_evolved = true
	is_active = true
	base_damage = 75.0
	base_cooldown = 0.65
	# A floor, not an assignment, and this file is the proof of why: the other slash
	# evolution nine lines below already writes `max(slash_range, 150.0)`. "Phá Khí
	# Thức" scales this field by 1.25 at ranks 1-4, so a full build reaches 268.55
	# before the rank-5 evolution is even offered, and a bare `=` handed it back 140.
	# It also made the two fusions order-dependent: evolving frost-first left 150 here,
	# evolving nine-swords-first left 140, for a weapon that is otherwise identical.
	slash_range = max(slash_range, 140.0)
	slash_angle_deg = 180.0
	FloatingText.spawn(global_position + Vector2(0, -45), "⚡ TIẾN HÓA: ĐỘC CÔ CỬU KIẾM QUY TÔNG! ⚡", Color(1.0, 0.88, 0.2))

## Expansion 20.0: Tinh Võ Hợp Nhất — Băng Phách Thần Kiếm.
## Over 225° cleave that flash-freezes every non-boss it touches for 1.5s.
func evolve_to_frost_sovereign() -> void:
	is_frost_sovereign = true
	is_evolved = true
	is_active = true
	slash_damage = max(base_damage, 110.0)
	slash_arc = max(slash_arc, PI * 1.3)
	# Keep the legacy fields coherent so older readers see the same numbers
	base_damage = slash_damage
	slash_angle_deg = rad_to_deg(slash_arc)
	base_cooldown = 0.55
	slash_range = max(slash_range, 150.0)
	FloatingText.spawn(global_position + Vector2(0, -45), "🌟 HỢP NHẤT: BĂNG PHÁCH THẦN KIẾM! 🌟", Color(0.45, 1.0, 0.85))
	# Milestone 4p2: a synergy fusion is the biggest payoff in a run, so it earns
	# the deepest stop the web export tolerates.
	if GameManager and GameManager.has_method("trigger_hitstop"):
		GameManager.trigger_hitstop(0.09, GameManager.HITSTOP_SCALE)
