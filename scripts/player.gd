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
## The character's un-upgraded timer. refresh_meta_stats() derives skill_cooldown_max
## from THIS, never from its own output: a multiplier computed off a value it just
## wrote compounds, so every unrelated meta purchase shaved another 8% off the timer
## (0.92^20 by the late-game shop is a skill firing 3x faster than it ever sold for).
var skill_cooldown_base: float = 5.5
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
## Permanent multiplicative might from the hermit's pacts. Held apart from
## might_multiplier so a Might Surge landing on top of the Blood Covenant and
## expiring 25s later takes its own bonus back and leaves the pact standing --
## these used to share one field with a single reset, so whichever writer
## touched it last silently deleted whichever writer went quiet.
var might_flat_bonus: float = 1.0
## A lease, refreshed every frame by a nearby glacial champion's aura and decayed
## here. The champion can hold an aura but cannot un-hold it, so the speed comes
## back on its own when the player walks away or kills it.
var glacial_slow_timer: float = 0.0
const GLACIAL_SLOW: float = 0.65

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
## Expansion 47.0: how much of MainWeapon.speed_multiplier *this* character
## added, so re-applying a character can take its own contribution back out
## instead of stacking another copy of it on top. See apply_character_data().
var applied_char_attack_speed: float = 0.0
var drunken_buff_timer: float = 0.0
var walk_phase: float = 0.0
var footstep_side: float = 1.0
var phoenix_feather_used: bool = false
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

## Expansion 22.0: everything bought *during a run* that touches one of the four
## headline stats. These live in their own fields for the same reason the char_*
## fields above do: refresh_meta_stats() rebuilds max_health / move_speed /
## meta_might_bonus / crit_chance_bonus from their bases, and that recompute is
## reachable mid-run from the pause-menu meta shop. Anything a run-scoped source
## wrote straight onto the live stat was therefore erased by the player's next
## Vitality purchase -- the +100 HP from a Shenron wish, the +15% from a hermit
## elixir, the crit from Bát Hoang Bí Điển, all silently refunded to zero.
var run_max_hp_bonus: float = 0.0
var run_might_bonus: float = 0.0
var run_speed_mult: float = 1.0

## The "Hấp Tinh Đại Pháp" card used to do `magnet_radius *= 1.30` in place, but the
## next refresh_meta_stats() reassigns that field from a base expression -- and that
## refresh also writes the CircleShape2D the MagnetArea actually collects with, so
## the number and the collector were rolled back together. Same shape as
## run_speed_mult, and same fix: a run-scoped source the rebuild reads from.
var run_magnet_mult: float = 1.0
var run_crit_bonus: float = 0.0

## Trade-off penalties, as their own multiplicative term -- deliberately NOT written
## into any weapon's speed_multiplier. The wave shop's crit item is "+crit, attacks
## 15% slower" and used to sweep `speed_multiplier *= 0.85` across the arsenal,
## which is the same field the Chrono Hourglass floors. The two are different kinds
## of number: the relic is a *guarantee* ("your cooldowns are at least 20% shorter"),
## the shop item is a *price*. Clamping the field for one silently erased the other,
## so the relic owner paid 15% fire rate for a discount they could not use. Split, the
## floor is a floor and the penalty is still a penalty: a Knight with the relic and
## one crit reads 1.25 * 0.85 = 1.0625, which is slower than the relic promises and
## slower than no crit at all. Composed into get_attack_speed_multiplier(), which
## all five weapons already read, so one term covers the whole arsenal.
var run_attack_speed_penalty: float = 1.0

## Tà Ma Lệnh Bài's three numbers, kept together so the codex description and the
## implementation cannot drift apart.
const RELIC_RAGE_HP_RATIO: float = 0.50
const RELIC_RAGE_CRIT_DAMAGE: float = 0.25
const RELIC_RAGE_ATTACK_SPEED: float = 1.15
## Huyết Ma Kiếm: healed straight off damage dealt, read beside the shop and
## character lifesteal in enemy.take_damage().
const RELIC_LIFESTEAL: float = 0.04
## Chrono Hourglass: the floor every weapon's speed_multiplier is held to. Named so
## the codex text and the implementation cannot drift apart. Read by
## _apply_cooldown_floor() and wave_shop_ui._set_weapon_speed().
const CHRONO_COOLDOWN_FLOOR: float = 1.25

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
		# Idempotent, not a ratchet. The pause menu's hero button (hud.gd:245) opens
		# this screen mid-run and character_select_ui.gd:325 re-applies the character to
		# the live player, so hero -> hero -> back to Ranger stacked "+35% Tốc Đánh" to
		# +70%, then +105%. A bare `= 1.0 + bonus` would also be idempotent, and would
		# refund every Tốc Đánh card the player has bought, because upgrade_fire_rate
		# accumulates into this same field. So take back exactly what this line last
		# added -- no more. The old `if data.has()` guard is gone because a hero with
		# no bonus now correctly *removes* the previous hero's rather than leaving it.
		main_wpn.speed_multiplier -= applied_char_attack_speed
		applied_char_attack_speed = float(data.get("attack_speed_bonus", 0.0))
		main_wpn.speed_multiplier += applied_char_attack_speed
		# The subtract above can land below the Chrono Hourglass floor, so the relic
		# has to be re-asserted here. See _apply_cooldown_floor().
		_apply_cooldown_floor()
			
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
	# The derived value is rebuilt from this, so it has to be reseated whenever the
	# character (and with it the un-upgraded timer) changes.
	skill_cooldown_base = skill_cooldown_max

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
	var new_max = _base_max_health()
	var hp_delta = new_max - max_health
	max_health = new_max
	if hp_delta > 0:
		current_health = min(max_health, current_health + hp_delta)

	var codex_spd = CodexManager.bonus_speed if CodexManager else 0.0
	move_speed = (230.0 + char_speed_bonus + codex_spd + GameManager.get_meta_stat("swiftness") * 20.0) * char_speed_mult * run_speed_mult
	magnet_radius = _base_magnet_radius()
	meta_might_bonus = _build_might_bonus()

	if magnet_area and magnet_area.has_node("CollisionShape2D"):
		var shape = magnet_area.get_node("CollisionShape2D").shape
		if shape is CircleShape2D:
			shape.radius = magnet_radius

	# Cái Bang's +40% AoE is the base here, not an add-on: this line runs again on
	# every meta-upgrade, so anything applied to blast_radius_multiplier directly
	# in apply_character_data() would be wiped on the first refresh.
	var fire_wpn = get_node_or_null("Weapons/FireballWeapon")
	if fire_wpn and "blast_radius_multiplier" in fire_wpn and "run_blast_radius_bonus" in fire_wpn:
		# Đan Điền's advertised "+20% AoE" rides here: blast_radius_multiplier is
		# the only player-facing AoE radius that scales with a multiplier, and
		# this is the one line that rebuilds it, so a source left out of it is a
		# source that silently does nothing -- and, because this line *assigns*,
		# a source that keeps its own field is one this line has to fold back in.
		#
		# That is what run_blast_radius_bonus is: the fireball's own run-scoped
		# width, bought from the shop. It was written onto blast_radius_multiplier
		# itself, so the Liệt Hỏa Phần Thiên card survived exactly until the player
		# bought a meta upgrade, unlocked a codex quest, or re-equipped a piece of
		# gear -- every one of which lands here, and equip_gear() is free.
		#
		# Ỷ Thiên Kiếm's "+25% Bán kính tầm đánh" is the one source that is
		# multiplicative rather than additive, so it scales the sum -- the sword
		# widens the blast by a quarter, whatever is in it. It used to be applied
		# further down as `blast_radius_multiplier *= 1.25`, which was correct only
		# by luck: it landed after this assignment, so it scaled a value that had
		# just been rebuilt from base. A source sitting anywhere but this expression
		# is either erased or, if it multiplies, a ratchet.
		var sword_range := 1.25 if GameManager.has_equipped("y_thien_kiem") else 1.0
		fire_wpn.blast_radius_multiplier = ((1.0 + char_area_bonus) \
			+ GameManager.get_meta_stat("pyro") * 0.12 \
			+ float(GameManager.get_meridian_stat("dan_dien") * 0.20) \
			+ fire_wpn.run_blast_radius_bonus) * sword_range
		
	# Meridian Cultivation (Hệ Thống Kinh Mạch)
	if GameManager:
		var nham = GameManager.get_meridian_stat("nham_mach")
		var nham_max := float(nham * 30)
		# Grant only the capacity that was just bought -- never top up to the new cap.
		# This function is a stat rebuild and runs from a dozen call sites, the cheapest
		# being _close_shop() and the free equip_gear(), so topping up here made every one
		# of them a free full recharge. A shield broken to 0 by a hit refilled itself the
		# moment the player opened and closed the menu. For a shield nothing has touched
		# yet the two are the same number; they only diverge once the charge is spent.
		qi_shield_current = minf(nham_max, qi_shield_current + maxf(0.0, nham_max - qi_shield_max))
		qi_shield_max = nham_max
		qi_shield_regen_rate = float(nham * 1.5)
		
		var doc = GameManager.get_meridian_stat("doc_mach")
		crit_chance_bonus = float(doc * 0.07) + run_crit_bonus

		var xung = GameManager.get_meridian_stat("xung_mach")
		move_speed += float(xung * 15.0)
		# From the character's base, not from the last derived value -- see
		# skill_cooldown_base. This function runs on every meta and meridian
		# purchase, so an in-place multiply was a silent infinite discount.
		#
		# 0.10, and the meridian row it applies is the one that says so: "+15 Move
		# Speed & -10% Cooldown". It was 0.08 -- the only number in that table that
		# did not match its own description, where Nhâm Mạch's 30/1.5, Đốc Mạch's
		# 7/35 and Đan Điền's 30 are all applied verbatim and this row's other
		# half, move_speed, lands on its 15 exactly. So a player paid 1437 gold
		# across five ranks for a 40% cut against a 50% promise, and the 2.5s
		# floor was never the reason: the knight's 5.5s base is 2.75s at this rate.
		skill_cooldown_max = maxf(2.5, skill_cooldown_base * (1.0 - float(xung * 0.10)))
		
		var dan = GameManager.get_meridian_stat("dan_dien")
		dragon_soul_harvest_mult = 1.0 + float(dan * 0.30)
		
		# Wuxia Equipment bonuses
		if GameManager.has_equipped("van_hac_hai"):
			move_speed += 30.0
		# Ỷ Thiên Kiếm's radius bonus moved up into the blast_radius_multiplier
		# assignment. It was here as `*=` on the value this function had just
		# rebuilt, which is right only because the assignment happens to run first
		# -- and every source of AoE radius now lives in one expression.

		
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

## The one place max_health is defined. refresh_meta_stats() and every add_run_max_hp()
## both go through here, so the four callers that used to write the stat directly --
## the wave shop's Tẩy Tủy Đan, the Shenron's Bất Tử Chân Thân, the hermit's Cửu
## Chuyển Hoàn Hồn, UpgradeManager's universal +25 card -- cannot drift out of it.
## The 20 HP floor lives here rather than at the callers: a stack of max-HP-cutting
## scrolls drives the raw sum negative, and only the summed value knows that.
func _base_max_health() -> float:
	return maxf(20.0, 100.0 + char_hp_bonus + GameManager.get_meta_stat("vitality") * 25.0 + run_max_hp_bonus)

## Same contract for might. Ỷ Thiên Kiếm's +15% used to be added inline at the tail
## of refresh_meta_stats(), which meant add_run_might() -- rebuilding the stat
## without that tail -- quietly deleted an equipped weapon the first time a player
## bought Cửu Âm Chân Kinh. Every source is in the expression now.
func _build_might_bonus() -> float:
	var bonus := GameManager.get_meta_stat("might") * 0.10 + char_might_bonus + run_might_bonus
	if GameManager.has_equipped("y_thien_kiem"):
		bonus += 0.15
	return bonus

## Same contract for pickup range. The Golden Horseshoe's advertised "+60 Magnet
## Radius" used to be written straight onto the MagnetArea's CircleShape2D by
## apply_relic_effects(), while refresh_meta_stats() wrote that same shape from
## plain magnet_radius -- so the relic bought radius the player kept until their
## first pause-shop purchase, and the pause panel, which prints magnet_radius, sat
## 60 below the circle the game was really collecting with. The same line also
## re-added char_magnet_bonus on top of a base that already contained it, so a mage
## (60) or a beggar (25) double-counted their own bonus while holding the relic.
##
## One expression, one writer, read from the relic list the way _build_might_bonus
## reads the equipped gear -- so there is no ordering left to get wrong.
func _base_magnet_radius() -> float:
	var radius := 140.0 + char_magnet_bonus + GameManager.get_meta_stat("magnetism") * 30.0
	if GameManager.has_relic("golden_horseshoe"):
		radius += 60.0
	return radius * run_magnet_mult

# --- run-scoped stat sources --------------------------------------------------
# Each returns the stat immediately (so the HUD is right before the next frame)
# without writing the recomputed fields, which is what made the value erasable.

func add_run_max_hp(amount: float) -> void:
	run_max_hp_bonus += amount
	max_health = _base_max_health()
	current_health = minf(current_health, max_health)
	_update_hp_displays()

func add_run_might(amount: float) -> void:
	run_might_bonus += amount
	meta_might_bonus = _build_might_bonus()

func multiply_run_speed(mult: float) -> void:
	run_speed_mult *= mult
	refresh_meta_stats()

func multiply_run_magnet(mult: float) -> void:
	run_magnet_mult *= mult
	refresh_meta_stats()

func add_run_crit(amount: float) -> void:
	run_crit_bonus += amount
	crit_chance_bonus = float(GameManager.get_meridian_stat("doc_mach") * 0.07) + run_crit_bonus

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
	if glacial_slow_timer > 0.0:
		glacial_slow_timer = maxf(0.0, glacial_slow_timer - delta)
	# The blizzard's decay used to sit in the non-dash branch below, beside the speed
	# maths that consumes it, so dashing stopped the clock and handed the debuff the
	# dash back as free time -- 4.5s of slow that lasted 4.5s plus every dash in it.
	# A timer's decay belongs with the other timers.
	if blizzard_slow_timer > 0.0:
		blizzard_slow_timer = maxf(0.0, blizzard_slow_timer - delta)
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

	# input_direction is a one-frame latch: cleared here, filled by the poll below, read
	# by the movement maths. The clear used to sit in the non-dash branch, so a dash left
	# the previous frame's stick reading frozen in place -- the poll below could not run
	# again until the dash ended, and the frame after that the player drifted once in a
	# direction they had already let go of.
	input_direction = Vector2.ZERO
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
		var effective_speed = move_speed * speed_multiplier * get_slow_multiplier()
		effective_speed *= get_blood_rush_speed_multiplier()
		if is_dragon_awakened:
			effective_speed *= 1.65
		elif drunken_buff_timer > 0.0:
			effective_speed *= 1.35
		var target_vel = input_direction.normalized() * effective_speed
		if input_direction != Vector2.ZERO:
			velocity = velocity.move_toward(target_vel, effective_speed * 14.0 * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, effective_speed * 18.0 * delta)

	
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
		if is_berserker_brand_active():
			if sprite and not is_moving:
				var pulse = (sin(walk_phase * 3.0) + 1.0) * 0.5
				sprite.modulate = Color(1.0 + pulse * 0.6, 0.4, 0.3)
		elif sprite:
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
	
	# Minh Giáo trades survivability for damage: 15% more of everything, applied
	# after armor so the sect's fragility is a real flat multiplier.
	var final_damage = max(1.0, amount - float(get_armor_bonus())) * char_damage_taken_mult
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

	# Relics that feed a stat are read inside refresh_meta_stats() now, so the rebuild
	# is the only thing that has to run -- called here so picking a relic off the floor
	# still moves the stat on that frame, which is what this function promised. The
	# CircleShape2D it used to write here is written by that rebuild, and by nothing
	# else; two writers that disagreed on the same shape is how the +60 came to live
	# in the circle but never in the magnet_radius the pause panel displays.
	refresh_meta_stats()

	if GameManager.has_relic("chrono_hourglass"):
		_apply_cooldown_floor()

## Chrono Hourglass ("Giảm 20% Thời Gian Hồi Chiêu") is a floor on every weapon's
## speed_multiplier, not a one-time bump. Clamping it once at pickup left the relic
## alive only by luck of arrival order, because the field has other writers: pick
## the relic up on the Knight (1.0 -> 1.25) and a later hero switch subtracts the
## *character's* bonus and lands back on 1.00; pick it up on the Ranger, whose +35%
## has already carried the value past 1.25, and the clamp is a no-op that records
## nothing -- so that same switch erases the relic outright. Measured 2026-10-01:
## pickup as Ranger read 1.35, switching to the Knight read 1.00, the relic gone.
##
## Every writer of the field re-asserts it through here, which is what makes the
## promise order-independent rather than a lottery. Rebuilding the field from a
## base instead would have been the obvious fix and is wrong: upgrade_fire_rate and
## the Tốc Đánh cards accumulate into this same float by `+=`, and the wave shop
## multiplies it by 0.85, so any rebuild refunds cards the player paid for.
##
## Swept across the whole container rather than listed weapon by weapon. The list
## this replaced named four of the five weapons that read speed_multiplier into
## their cooldown -- SlashWeapon (Độc Cô Cửu Kiếm) was missing, so a relic reading
## "-20% Weapon Cooldowns" did nothing at all for the blade. OrbitingWeapon has no
## cooldown, so the "in node" guard skips it on its own, and the next weapon added
## to the scene is covered without anyone having to remember to add it here.
func _apply_cooldown_floor() -> void:
	if not GameManager or not GameManager.has_relic("chrono_hourglass"):
		return
	var weapons := get_node_or_null("Weapons")
	if not weapons:
		return
	for w in weapons.get_children():
		if "speed_multiplier" in w:
			w.set("speed_multiplier", maxf(float(w.get("speed_multiplier")), CHRONO_COOLDOWN_FLOOR))

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
	return (1.0 + meta_might_bonus) * might_flat_bonus * get_berserker_brand_multiplier() * might_multiplier * char_damage_mult

## Expansion 46.0: the one copy of the armour sum. take_damage() built this inline
## while the HUD's ARMOR and DEF readouts derived it from get_meta_stat("armor")
## alone -- one term of four -- so a player holding +3 character armour, Nhuyễn Vị
## Giáp and a wave-shop purchase was told he had 2. Repaired the way 45.0's might
## readout was: by deleting the second copy rather than restating the first. Both
## readers ask here, so a fifth source cannot be added without the panel seeing it.
func get_armor_bonus() -> int:
	var meta_arm = GameManager.get_meta_stat("armor") if GameManager else 0
	var equip_arm = 2 if (GameManager and GameManager.has_equipped("nhuyen_vi_giap")) else 0
	return meta_arm + char_armor_bonus + equip_arm + shop_armor_bonus

## Berserker Brand: at least 1.5x damage below 40% HP, never *less* than what the
## player already had. It used to be written straight onto might_multiplier with
## max(), which overwrote the Blood Covenant's 1.45 and was then never given
## back. Read here instead, so the relic lifts the player to 1.5x and no further.
func is_berserker_brand_active() -> bool:
	return GameManager != null and GameManager.has_relic("berserker_brand") \
		and current_health / maxf(1.0, max_health) <= 0.40

func get_berserker_brand_multiplier() -> float:
	return 1.50 if is_berserker_brand_active() else 1.0

## Minh Giáo's +60% elemental burn, read by enemy.apply_burn() -- the single
## point every burn source (fireball, spirit sword, dragon breath) routes through.
func get_burn_multiplier() -> float:
	return char_burn_mult

## Expansion 22.0: Tà Ma Lệnh Bài (demonic_token) and Huyết Ma Kiếm (blood_blade).
## Both were registered in codex_manager._register_codex_relic() with a full
## description and a quest behind them, and neither had an effect anywhere in the
## codebase -- the codex told the player what the relic would do and then did
## nothing. Same single-read-point contract as the two above: enemy.take_damage()
## holds the only crit roll and the only lifesteal read, and each weapon holds one
## cooldown line, so these stay honest without a single weapon knowing they exist.
func is_demonic_rage_active() -> bool:
	if not GameManager or not GameManager.has_relic("demonic_token"):
		return false
	return current_health / maxf(1.0, max_health) <= RELIC_RAGE_HP_RATIO

## +25% crit damage while raging, plus Đốc Mạch's advertised +35% per rank -- the
## meridian table has claimed that since the Codex shipped and nothing read it.
## 2.2 is the engine constant, unchanged.
func get_crit_damage_multiplier() -> float:
	var bonus := float(GameManager.get_meridian_stat("doc_mach") * 0.35)
	if is_demonic_rage_active():
		bonus += RELIC_RAGE_CRIT_DAMAGE
	return 1.0 + bonus

## +15% attack speed while raging. Divided into the cooldown rather than multiplied
## into each weapon's speed_multiplier, so a weapon bought mid-rage inherits it and
## nothing compounds while the player sits below the threshold.
##
## Cái Bang's Say Rượu Bát Tiên contributes the second term. Its card advertises
## "+40% Né Đòn & +50% Tốc Đánh trong 6.0s" and only the dodge half existed: the
## dodge is gated on drunken_buff_timer at player.gd:766, and this function was the
## sole attack-speed hook in the game -- it returned 1.0 with no timer check, so
## measured 2026-10-01 the multiplier was 1.0 before the skill and 1.0 during it.
##
## Composed rather than ternary'd because the two are now independent sources and
## the next one will be too. Multiplicative, like the relic: two buffs stacking to
## +70% reads as stronger than either, which is what a player expects from a stack.
func get_attack_speed_multiplier() -> float:
	var mult := 1.0
	if is_demonic_rage_active():
		mult *= RELIC_RAGE_ATTACK_SPEED
	if drunken_buff_timer > 0.0:
		mult *= 1.50
	mult *= run_attack_speed_penalty
	return mult

## The wave shop's trade-off items. Separate from the weapon field on purpose -- see
## run_attack_speed_penalty for why a penalty and a floor cannot share one float.
func multiply_run_attack_speed(mult: float) -> void:
	run_attack_speed_penalty *= mult

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
			add_run_max_hp(100.0)
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
			might_flat_bonus += 0.45
			_update_hp_displays()
			FloatingText.spawn(global_position + Vector2(0, -35), "🩸 HUYẾT KHẾ: +45% SÁT THƯƠNG!", Color(1.0, 0.2, 0.2))
		"abyssal_frenzy":
			has_abyssal_frenzy = true
			var spawner = get_tree().get_first_node_in_group("enemy_spawner")
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

## Vân Hạc Hài advertises "Miễn Nhiễm Hiệu Ứng Làm Chậm" -- immune to slow effects,
## not to one slow in particular. The check used to live only inside
## apply_blizzard_slow(), so the glacial champion's aura, which writes the lease
## field outright at enemy.gd:251 and never went near that function, slowed an
## immune player for as long as they stood in a 170px aura.
##
## Both timers are consumed in one place, so the immunity is read here rather than
## in each producer: one gate, and the next slow to be added is covered by writing
## no new code at all.
func is_slow_immune() -> bool:
	return GameManager != null and GameManager.has_equipped("van_hac_hai")

## Every slow that actually costs the player speed. The glacial lease expires on
## its own (see _physics_process), so neither timer here needs a writer to undo it.
func get_slow_multiplier() -> float:
	if is_slow_immune():
		return 1.0
	var mult := 1.0
	if glacial_slow_timer > 0.0:
		mult *= GLACIAL_SLOW
	if blizzard_slow_timer > 0.0:
		mult *= 0.75
	return mult

func apply_blizzard_slow(duration: float = 3.0) -> void:
	if is_slow_immune():
		FloatingText.spawn(global_position + Vector2(0, -28), "🥾 MIỄN NHIỄM HÀN BĂNG!", Color(0.4, 0.95, 0.6))
		return
	blizzard_slow_timer = duration
	FloatingText.spawn(global_position + Vector2(0, -28), "❄️ HÀN KHÍ LÀM CHẬM!", Color(0.4, 0.85, 1.0))

func apply_hermit_item(item_id: String) -> void:
	SoundManager.play("elixir_drink", 0.1)
	match item_id:
		"cuu_chuyen_dan":
			# +15% of the max it has *right now*, banked as a flat bonus so the next
			# meta-shop refresh cannot shrink it back.
			add_run_max_hp(max_health * 0.15)
			current_health = max_health
			qi_shield_current = qi_shield_max
			_update_hp_displays()
			emit_signal("qi_shield_changed", qi_shield_current, qi_shield_max)
			FloatingText.spawn(global_position + Vector2(0, -35), "💊 CỬU CHUYỂN HOÀN HỒN: FULL HP & +15% MAX HP!", Color(0.2, 1.0, 0.4))
		"tay_tuy_dan":
			might_flat_bonus += 0.20
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
				var spawner = get_tree().get_first_node_in_group("enemy_spawner")
				if spawner and spawner.has_method("spawn_specific_enemy"):
					for i in range(2):
						var offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(90, 150)
						spawner.spawn_specific_enemy("skeleton_brute", global_position + offset)




