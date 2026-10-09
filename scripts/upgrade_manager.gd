class_name UpgradeManager
extends CanvasLayer

## UpgradeManager: Pauses the game on level up, selects 3 random upgrades, and applies player bonuses.
## Expansion 19.0: Level-up choice agency with Reroll (Tẩy Tủy) and Skip (Bỏ Qua +30 Vàng).
## Expansion 20.0: Tinh Võ Hợp Nhất — dual-weapon synergy fusions (Lotus Storm / Frost Sovereign).

signal upgrade_selected(upgrade_id: String)
signal arsenal_updated(levels: Dictionary)

@onready var panel: PanelContainer = get_node_or_null("UpgradePanel")
@onready var options_container: HBoxContainer = get_node_or_null("UpgradePanel/VBox/OptionsContainer")

var action_bar: HBoxContainer = null
var reroll_button: Button = null
var skip_button: Button = null

var player: Node2D = null
var weapon: Node2D = null
var orbit_weapon: Node2D = null
var lightning_weapon: Node2D = null
var fire_weapon: Node2D = null
var axe_weapon: Node2D = null
var slash_weapon: Node2D = null

var max_rerolls: int = 2
var rerolls_remaining: int = 2
var current_offered_upgrades: Array[Dictionary] = []

var weapon_levels: Dictionary = {
	"dagger": 1,
	"shield": 1,
	"lightning": 0,
	"fireball": 0,
	"axe": 0,
	"slash": 0
}

var evolved_weapons: Dictionary = {
	"dagger": false,
	"shield": false,
	"lightning": false,
	"fireball": false,
	"axe": false,
	"slash": false
}

# Expansion 20.0: Tinh Võ Hợp Nhất — dual-weapon synergy fusions (one per pair, one-shot)
var synergies_evolved: Dictionary = {
	"bao_vu": false,
	"bang_phach": false
}

## Milestone 1: all six võ học can be carried at once (was 3).
const MAX_WEAPONS: int = 6

## Each fusion tier adds this fraction of base damage, so stacking two same-type
## weapons is a real power spike rather than pure slot economy.
const TIER_DAMAGE_BONUS: float = 0.35
const MAX_WEAPON_TIER: int = 4

## Physical weapon tray for the Tàng Kinh Các shop: up to MAX_WEAPONS copies,
## each {"id": String, "tier": int}. weapon_levels stays the per-type level ledger
## the level-up catalog reads; the arsenal is what you own and fuse.
var arsenal: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 10 call sites resolve this node via get_first_node_in_group("upgrade_manager");
	# main.tscn sets the group in the editor, but registering here too means any
	# instantiation path (test harness, a scene that forgets the editor flag) resolves.
	add_to_group("upgrade_manager")
	rerolls_remaining = max_rerolls
	
	if panel:
		panel.visible = false
		options_container = panel.get_node_or_null("VBox/OptionsContainer")
		# The title was a baked-in Label text in main.tscn and nothing in code ever
		# touched it, so it had no route to Loc and read English in every locale.
		# main.tscn leaves it empty now; the string is written here instead.
		var title_label := panel.get_node_or_null("VBox/Title") as Label
		if title_label:
			title_label.text = Loc.t("hud.level_up")
	
	# Configure initial weapon levels based on selected character
	if GameManager:
		var char_data = GameManager.get_selected_character_data()
		var starters: Array = char_data.get("starter_weapons", ["dagger", "shield"])
		for w in weapon_levels.keys():
			weapon_levels[w] = 1 if starters.has(w) else 0
	
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("leveled_up", Callable(self, "_on_player_leveled_up"))
		weapon = player.get_node_or_null("Weapons/MainWeapon")
		orbit_weapon = player.get_node_or_null("Weapons/OrbitingWeapon")
		lightning_weapon = player.get_node_or_null("Weapons/LightningWeapon")
		fire_weapon = player.get_node_or_null("Weapons/FireballWeapon")
		axe_weapon = player.get_node_or_null("Weapons/AxeWeapon")
		slash_weapon = player.get_node_or_null("Weapons/SlashWeapon")
	
	call_deferred("emit_signal", "arsenal_updated", weapon_levels)

func _unhandled_input(event: InputEvent) -> void:
	if not panel or not panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_select_card_index(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_select_card_index(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_select_card_index(2)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			if rerolls_remaining > 0:
				reroll_upgrades()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_X or event.keycode == KEY_ESCAPE:
			skip_upgrade()
			get_viewport().set_input_as_handled()

func _on_player_leveled_up(_new_level: int) -> void:
	show_upgrade_selection()

func get_active_weapon_count() -> int:
	var count = 0
	for w in weapon_levels.keys():
		if weapon_levels[w] > 0:
			count += 1
	return count

# --- Milestone 1: physical arsenal, tiers, fusing -----------------------------

const TIER_NAMES: Array[String] = ["T1 Trắng", "T2 Lục", "T3 Lam", "T4 Hoàng Kim"]
const TIER_COLORS: Array[Color] = [
	Color(0.92, 0.92, 0.95), Color(0.55, 0.95, 0.55), Color(0.45, 0.75, 1.0), Color(1.0, 0.82, 0.3)
]
## Milestone 3a: the `name` here is the CANONICAL English spelling and must stay
## byte-identical to Loc.STRINGS["weapon.<id>.name"]["en"] -- the regression suite
## asserts that equality so the three tables cannot drift apart. The localised
## string comes from get_weapon_name(); this const is the offline fallback.
const WEAPON_INFO: Dictionary = {
	"dagger": {"name": "Thousand Daggers", "icon": "🗡️"},
	"shield": {"name": "Eight Trigrams Shield", "icon": "🛡️"},
	"lightning": {"name": "Heaven's Wrath", "icon": "⚡"},
	"fireball": {"name": "Apocalypse Meteor", "icon": "🔥"},
	"axe": {"name": "Dog-Beating Staff", "icon": "🪓"},
	"slash": {"name": "Nine Swords Cleave", "icon": "⚔️"}
}

## The localised name for a weapon id, falling back to the id itself so an
## unknown weapon still renders something readable.
func get_weapon_name(weapon_id: String) -> String:
	return Loc.t("weapon.%s.name" % weapon_id, WEAPON_INFO.get(weapon_id, {}).get("name", weapon_id))

# --- Phase 1: card rarity & iconography --------------------------------------

## Four tiers, weakest first. A card's own flags decide its tier, so no catalog
## entry carries rarity data and the next card written is classified for free. The
## ordering is the size of the thing, not a display preference: an unlock opens a
## whole võ học, a synergy fuses two at Lv.5, an evolution replaces one.
func card_rarity(upgrade: Dictionary) -> int:
	if upgrade.get("is_evolution", false):
		return UITheme.RARITY_LEGENDARY
	if upgrade.get("is_synergy", false):
		return UITheme.RARITY_EPIC
	if String(upgrade.get("id", "")).begins_with("unlock_"):
		return UITheme.RARITY_RARE
	return UITheme.RARITY_COMMON

## The card's võ học badge, keyed by id rather than listed per card: every id is
## already "<weapon>_<action>" (or unlock_/evolve_<weapon>), so the next card a
## weapon gains is illustrated the moment it is written. The table doubles as the
## exception list -- orbit_shield and orbit_speed upgrade the shield but are named
## for the orbit, and damage / attack_speed / projectile_count upgrade the dagger
## but predate its id.
const CARD_ICONS: Dictionary = {
	"dagger": "⚔",
	"shield": "◈",
	"lightning": "⚡",
	"fireball": "🔥",
	"axe": "🪓",
	"slash": "⚔",
	"orbit": "◈",
	"damage": "💥",
	"attack_speed": "💨",
	"projectile_count": "✦",
	"move_speed": "👢",
	"magnet": "🌀",
	"max_hp": "💪",
	"might_surge": "🌋",
	"synergy": "⚡",
	"area": "💫",
	"duration": "⏱",
	"cooldown": "⚡",
	"armor": "◈",
	"luck": "🍀",
}

## Falls back to a neutral mark rather than no badge: a card whose icon lookup
## missed is a bug worth seeing on screen, not a gap worth hiding.
##
## Whole id first, then its first token. The single-token rule on its own is the
## obvious version and it is wrong for half the table -- attack_speed, move_speed,
## max_hp and might_surge are each two tokens, so "attack" and "move" found
## nothing and five of the game's own cards shipped with a placeholder. Universal
## cards carry the whole id in the table; weapon cards carry only the weapon, and
## take the token.
func card_icon(upgrade_id: String) -> String:
	var key := upgrade_id
	if key.begins_with("evolve_") or key.begins_with("unlock_"):
		key = key.substr(key.find("_") + 1)
	if CARD_ICONS.has(key):
		return CARD_ICONS[key]
	return CARD_ICONS.get(key.split("_")[0], "✦")

func get_arsenal_count() -> int:
	return arsenal.size()

## Highest fusion tier owned for this weapon type. 0 = none owned.
func get_weapon_tier(id: String) -> int:
	var best := 0
	for w in arsenal:
		if w.get("id", "") == id:
			best = maxi(best, int(w.get("tier", 1)))
	return best

func count_at_tier(id: String, tier: int) -> int:
	var n := 0
	for w in arsenal:
		if w.get("id", "") == id and int(w.get("tier", 1)) == tier:
			n += 1
	return n

## Two weapons of the same type AND same tier fuse into one of tier+1, freeing a
## slot. A maxed tier has nothing to fuse into, so it reports false.
func can_fuse(id: String, tier: int) -> bool:
	return tier < MAX_WEAPON_TIER and count_at_tier(id, tier) >= 2

func fuse_weapons(id: String, tier: int) -> bool:
	if not can_fuse(id, tier):
		return false
	var seen := 0
	var kept: Array[Dictionary] = []
	for w in arsenal:
		if w.get("id", "") == id and int(w.get("tier", 1)) == tier and seen < 2:
			seen += 1
			continue
		kept.append(w)
	kept.append({"id": id, "tier": tier + 1})
	arsenal = kept
	SoundManager.play("level_up", 0.1)
	apply_arsenal_bonuses()
	emit_signal("arsenal_updated", weapon_levels)
	return true

func add_weapon(id: String, tier: int = 1) -> bool:
	if arsenal.size() >= MAX_WEAPONS:
		return false
	arsenal.append({"id": id, "tier": clampi(tier, 1, MAX_WEAPON_TIER)})
	# Keep the level ledger in step so the level-up catalog still offers upgrades
	# for a type the shop just handed the player.
	if int(weapon_levels.get(id, 0)) < 1:
		weapon_levels[id] = 1
		evolved_weapons[id] = false
		if player and player.has_method("activate_weapon"):
			player.activate_weapon(id)
	apply_arsenal_bonuses()
	emit_signal("arsenal_updated", weapon_levels)
	return true

func remove_weapon_at(index: int) -> Dictionary:
	if index < 0 or index >= arsenal.size():
		return {}
	var removed = arsenal[index]
	arsenal.remove_at(index)
	apply_arsenal_bonuses()
	emit_signal("arsenal_updated", weapon_levels)
	return removed

## Total damage multiplier the arsenal grants: every point of tier above 1 is
## worth TIER_DAMAGE_BONUS. Pushed onto the live weapon nodes so the number the
## shop shows is the number the player feels.
func get_arsenal_damage_mult() -> float:
	var excess := 0
	for w in arsenal:
		excess += maxi(0, int(w.get("tier", 1)) - 1)
	return 1.0 + float(excess) * TIER_DAMAGE_BONUS

func apply_arsenal_bonuses() -> void:
	if not player:
		return
	var mult := get_arsenal_damage_mult()
	for node in [weapon, orbit_weapon, lightning_weapon, fire_weapon, axe_weapon, slash_weapon]:
		if is_instance_valid(node) and "tier_damage_mult" in node:
			node.set("tier_damage_mult", mult)

func tier_label(tier: int) -> String:
	return TIER_NAMES[clampi(tier - 1, 0, TIER_NAMES.size() - 1)]

func tier_color(tier: int) -> Color:
	return TIER_COLORS[clampi(tier - 1, 0, TIER_COLORS.size() - 1)]

func get_upgrade_catalog() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	
	# 1. Super Weapon Evolutions (weapons at Level >= 5 that haven't evolved yet)
	if weapon_levels.get("dagger", 0) >= 5 and not evolved_weapons.get("dagger", false):
		options.append({
			"id": "evolve_dagger",
			"title": "[TIỆT KỸ] VÔ ẢNH THẦN CHÂM (Thousand Blades)",
			"desc": "TIỆT KỸ TIẾN HÓA!\n(Phi Đao Lv.5 + Thân Pháp Thần Tốc)\nBắn bão 8 Phi Kim Astral xuyên thấu 360° vô tận!",
			"is_evolution": true
		})
	if weapon_levels.get("shield", 0) >= 5 and not evolved_weapons.get("shield", false):
		options.append({
			"id": "evolve_shield",
			"title": "[TIỆT KỸ] THÁI CỰC HỘ THỂ (Solar Bulwark)",
			"desc": "TIỆT KỸ TIẾN HÓA!\n(Khiên Bát Quái Lv.5 + Nhâm Mạch Hộ Thể)\n5 Khiên Thái Cực quang minh xoay cực tốc phản đòn!",
			"is_evolution": true
		})
	if weapon_levels.get("lightning", 0) >= 5 and not evolved_weapons.get("lightning", false):
		options.append({
			"id": "evolve_lightning",
			"title": "[TIỆT KỸ] CỬU THIÊN HUYỀN LÔI (Heaven's Wrath)",
			"desc": "TIỆT KỸ TIẾN HÓA!\n(Thiên Lôi Lv.5 + Đốc Mạch Bạo Kích)\n4 luồng Sấm Sét giật liên hoàn kèm sóng xung kích bạo kích 100%!",
			"is_evolution": true
		})
	if weapon_levels.get("fireball", 0) >= 5 and not evolved_weapons.get("fireball", false):
		options.append({
			"id": "evolve_fireball",
			"title": "[TIỆT KỸ] KIM CƯƠNG HỎA CHƯỞNG (Apocalypse Meteor)",
			"desc": "TIỆT KỸ TIẾN HÓA!\n(Hỏa Cầu Lv.5 + Hỏa Luân Bộc Phá)\nThiên thạch lửa khổng lồ phát nổ để lại biển lửa thiêu đốt!",
			"is_evolution": true
		})
	if weapon_levels.get("axe", 0) >= 5 and not evolved_weapons.get("axe", false):
		options.append({
			"id": "evolve_axe",
			"title": "[TIỆT KỸ] CÀN KHÔN ĐẠI NA DI (Reaper's Cleave)",
			"desc": "TIỆT KỸ TIẾN HÓA!\n(Đả Cẩu Trận Lv.5 + Dịch Cân Kinh)\n3 Lưỡi hái tinh vân xoay tròn có lực hút hố đen gom quái!",
			"is_evolution": true
		})
	if weapon_levels.get("slash", 0) >= 5 and not evolved_weapons.get("slash", false):
		options.append({
			"id": "evolve_slash",
			"title": "[TIỆT KỸ] ĐỘC CÔ CỬU KIẾM QUY TÔNG (Nine Swords Cleave)",
			"desc": "TIỆT KỸ TIẾN HÓA!\n(Cửu Kiếm Lv.5 + Đan Điền Khí Hải)\nTrảm kích hoàng kim 180° uy lực vô song chém nát vạn ma!",
			"is_evolution": true
		})

	# 2. Tinh Võ Hợp Nhất — DUAL-WEAPON SYNERGY FUSIONS (both partners at Lv.5)
	if weapon_levels.get("dagger", 0) >= 5 and weapon_levels.get("axe", 0) >= 5 and not synergies_evolved.get("bao_vu", false):
		options.append({
			"id": "synergy_bao_vu",
			"title": "[HỢP NHẤT] BÃO VŨ LÊ HOA CHÂM (Lotus Storm)",
			"desc": "TIỆT KỸ HỢP NHẤT (Phi Đao Lv.5 + Đả Cẩu Trận Lv.5)!\nBắn ra 16 phi châm xoay tròn 360 độ xé toạc toàn màn hình kèm độc tính cực mạnh!",
			"is_synergy": true
		})
	if weapon_levels.get("slash", 0) >= 5 and weapon_levels.get("shield", 0) >= 5 and not synergies_evolved.get("bang_phach", false):
		options.append({
			"id": "synergy_bang_phach",
			"title": "[HỢP NHẤT] BĂNG PHÁCH THẦN KIẾM (Frost Sovereign)",
			"desc": "TIỆT KỸ HỢP NHẤT (Cửu Kiếm Lv.5 + Khiên Bát Quái Lv.5)!\nTrảm kích băng phách đóng băng kẻ địch non-boss trong 1.5s và kích nổ băng toái!",
			"is_synergy": true
		})

	# 3. Weapon Unlocks (restricted by 3-weapon slot cap)
	if get_active_weapon_count() < MAX_WEAPONS:
		if weapon_levels.get("dagger", 0) == 0:
			options.append({
				"id": "unlock_dagger",
				"title": "[MỚI] Ám Khí Phi Đao",
				"desc": "[VÕ HỌC MỚI - Ô %d/%d]\nPhi đao tự động nhắm bắn mục tiêu gần nhất." % [get_active_weapon_count() + 1, MAX_WEAPONS]
			})
		if weapon_levels.get("shield", 0) == 0:
			options.append({
				"id": "unlock_shield",
				"title": "[MỚI] Khiên Bát Quái",
				"desc": "[VÕ HỌC MỚI - Ô %d/%d]\nBát quái hộ thể xoay quanh đẩy lùi kẻ địch áp sát." % [get_active_weapon_count() + 1, MAX_WEAPONS]
			})
		if weapon_levels.get("lightning", 0) == 0:
			options.append({
				"id": "unlock_lightning",
				"title": "[MỚI] Cửu Thiên Lôi Điện",
				"desc": "[VÕ HỌC MỚI - Ô %d/%d]\nTriệu hồi sấm sét từ thiên hà trừng phạt quái vật." % [get_active_weapon_count() + 1, MAX_WEAPONS]
			})
		if weapon_levels.get("fireball", 0) == 0:
			options.append({
				"id": "unlock_fireball",
				"title": "[MỚI] Liệt Hỏa Chưởng Cầu",
				"desc": "[VÕ HỌC MỚI - Ô %d/%d]\nPhóng cầu lửa bộc phá gây sát thương diện rộng." % [get_active_weapon_count() + 1, MAX_WEAPONS]
			})
		if weapon_levels.get("axe", 0) == 0:
			options.append({
				"id": "unlock_axe",
				"title": "[MỚI] Đả Cẩu Trận (Arc Axe)",
				"desc": "[VÕ HỌC MỚI - Ô %d/%d]\nNém bổng pháp/rìu xoay tròn theo hình cầu vồng xuyên thấu." % [get_active_weapon_count() + 1, MAX_WEAPONS]
			})
		if weapon_levels.get("slash", 0) == 0:
			options.append({
				"id": "unlock_slash",
				"title": "[MỚI] Độc Cô Cửu Kiếm (Slash Arc)",
				"desc": "[VÕ HỌC MỚI - Ô %d/%d]\nTrảm kích hình bán nguyệt theo hướng di chuyển xé toạc kẻ địch." % [get_active_weapon_count() + 1, MAX_WEAPONS]
			})

	# 4. Standard Weapon Upgrades (Rank 1 to 4)
	if weapon_levels.get("dagger", 0) >= 1 and weapon_levels.get("dagger", 0) < 5:
		options.append({"id": "damage", "title": "Tôi Độc Phi Đao", "desc": "+25%% Sát Thương Phi Đao (Cấp %d/5)" % (weapon_levels["dagger"] + 1)})
		options.append({"id": "attack_speed", "title": "Liên Hoàn Thủ", "desc": "+20%% Tốc Đánh Phi Đao (Cấp %d/5)" % (weapon_levels["dagger"] + 1)})
		options.append({"id": "projectile_count", "title": "Song Phi Tiêu", "desc": "+1 Phi Đao mỗi lượt bắn (Cấp %d/5)" % (weapon_levels["dagger"] + 1)})
		
	if weapon_levels.get("shield", 0) >= 1 and weapon_levels.get("shield", 0) < 5:
		options.append({"id": "orbit_shield", "title": "Lưỡng Nghi Khiên", "desc": "+1 Lưỡi Khiên Hộ Thể (Cấp %d/5)" % (weapon_levels["shield"] + 1)})
		options.append({"id": "orbit_speed", "title": "Phong Toàn Bộ", "desc": "+30%% Tốc Độ Xoay Khiên (Cấp %d/5)" % (weapon_levels["shield"] + 1)})
		
	if weapon_levels.get("lightning", 0) >= 1 and weapon_levels.get("lightning", 0) < 5:
		options.append({"id": "lightning_strike", "title": "Lôi Đình Vạn Quân", "desc": "+1 Luồng Sấm Sét đồng thời (Cấp %d/5)" % (weapon_levels["lightning"] + 1)})
		options.append({"id": "lightning_damage", "title": "Cửu Tiêu Lôi Đình", "desc": "+30%% Sát Thương Sấm Sét (Cấp %d/5)" % (weapon_levels["lightning"] + 1)})
		# The last weapon with a cooldown and no card for it. Sấm Sét reads
		# speed_multiplier into base_cooldown / (speed_multiplier * attack_speed) at
		# lightning_weapon.gd:25 -- the same formula character for character as the
		# Cầu Lửa at fireball_weapon.gd:42 -- and the Chrono Hourglass relic sweeps
		# that field on it like any other weapon, so the axis is live and
		# player-facing. It was simply unreachable: lightning exposed upgrade_strikes
		# and upgrade_damage and no third, so no level-up could ever touch it, and a
		# lightning build could not make its slowest weapon (base_cooldown 2.4, the
		# longest in the tray) any faster. +25% is the same number Cầu Lửa, Rìu and
		# Cửu Kiếm grant for this formula.
		options.append({"id": "lightning_speed", "title": "Lôi Trận Vân Tung", "desc": "+25%% Tốc Đánh Sấm Sét (Cấp %d/5)" % (weapon_levels["lightning"] + 1)})
		
	if weapon_levels.get("fireball", 0) >= 1 and weapon_levels.get("fireball", 0) < 5:
		options.append({"id": "fireball_count", "title": "Tam Muội Chân Hỏa", "desc": "+1 Cầu Lửa đồng thời (Cấp %d/5)" % (weapon_levels["fireball"] + 1)})
		options.append({"id": "fireball_damage", "title": "Bộc Liệt Chưởng", "desc": "+35%% Sát Thương Cầu Lửa (Cấp %d/5)" % (weapon_levels["fireball"] + 1)})
		options.append({"id": "fireball_radius", "title": "Liệt Hỏa Phần Thiên", "desc": "+35%% Phạm Vi Nổ Cầu Lửa (Cấp %d/5)" % (weapon_levels["fireball"] + 1)})
		# Every other weapon offers a card for its speed axis, and the fireball's own
		# upgrade_fire_rate() was the only upgrade method in the codebase that no card
		# could reach. Its cooldown is base_cooldown / (speed_multiplier * attack_speed),
		# character for character the same formula as slash_weapon.gd:82 -- so this is
		# the same "+25%" the Cửu Kiếm card grants, not a new mechanic.
		options.append({"id": "fireball_speed", "title": "Chuyển Luân Hỏa Chương", "desc": "+25%% Tốc Đánh Cầu Lửa (Cấp %d/5)" % (weapon_levels["fireball"] + 1)})
		
	if weapon_levels.get("axe", 0) >= 1 and weapon_levels.get("axe", 0) < 5:
		options.append({"id": "axe_count", "title": "Bổng Ảnh Tung Hoành", "desc": "+1 Rìu/Bổng ném ra (Cấp %d/5)" % (weapon_levels["axe"] + 1)})
		options.append({"id": "axe_damage", "title": "Đoạt Mệnh Bổng", "desc": "+35%% Sát Thương Rìu/Bổng (Cấp %d/5)" % (weapon_levels["axe"] + 1)})
		options.append({"id": "axe_speed", "title": "Cuồng Phong Bổng Pháp", "desc": "+25%% Tốc Độ Bay Của Rìu (Cấp %d/5)" % (weapon_levels["axe"] + 1)})

	if weapon_levels.get("slash", 0) >= 1 and weapon_levels.get("slash", 0) < 5:
		options.append({"id": "slash_damage", "title": "Phá Kiếm Thức", "desc": "+35%% Sát Thương Cửu Kiếm (Cấp %d/5)" % (weapon_levels["slash"] + 1)})
		options.append({"id": "slash_speed", "title": "Phá Đao Thức", "desc": "+25%% Tốc Đánh Cửu Kiếm (Cấp %d/5)" % (weapon_levels["slash"] + 1)})
		options.append({"id": "slash_range", "title": "Phá Khí Thức", "desc": "+25%% Bán Kính & Tầm Trảm Kích (Cấp %d/5)" % (weapon_levels["slash"] + 1)})

	# 5. Universal Passive Upgrades
	options.append({"id": "move_speed", "title": "Lăng Ba Vi Bộ", "desc": "+15% Tốc Độ Di Chuyển Thần Tốc"})
	options.append({"id": "magnet", "title": "Hấp Tinh Đại Pháp", "desc": "+30% Phạm Vi Hút Ngọc & Vàng"})
	options.append({"id": "max_hp", "title": "Kim Cang Bất Hoại", "desc": "+25 Máu Tối Đa & Hồi Phục 25 HP"})
	options.append({"id": "might_surge", "title": "Bồ Đề Tâm Pháp", "desc": "+12% Sức Mạnh Sát Thương Toàn Thân"})

	return options

func _ensure_ui_nodes() -> void:
	if not panel:
		panel = get_node_or_null("UpgradePanel")
	if not panel:
		panel = PanelContainer.new()
		panel.name = "UpgradePanel"
		panel.visible = false
		add_child(panel)
		
	var vbox = panel.get_node_or_null("VBox")
	if not vbox:
		vbox = VBoxContainer.new()
		vbox.name = "VBox"
		panel.add_child(vbox)
		
	if not options_container:
		options_container = vbox.get_node_or_null("OptionsContainer")
	if not options_container:
		options_container = HBoxContainer.new()
		options_container.name = "OptionsContainer"
		vbox.add_child(options_container)
	
	action_bar = vbox.get_node_or_null("ActionBar")
	if not action_bar:
		action_bar = HBoxContainer.new()
		action_bar.name = "ActionBar"
		action_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		action_bar.add_theme_constant_override("separation", 24)
		vbox.add_child(action_bar)
		
	reroll_button = action_bar.get_node_or_null("RerollButton")
	if not reroll_button:
		reroll_button = Button.new()
		reroll_button.name = "RerollButton"
		reroll_button.custom_minimum_size = Vector2(250, 42)
		reroll_button.pressed.connect(Callable(self, "reroll_upgrades"))
		action_bar.add_child(reroll_button)
		
	skip_button = action_bar.get_node_or_null("SkipButton")
	if not skip_button:
		skip_button = Button.new()
		skip_button.name = "SkipButton"
		skip_button.custom_minimum_size = Vector2(250, 42)
		skip_button.pressed.connect(Callable(self, "skip_upgrade"))
		action_bar.add_child(skip_button)

func _update_action_bar_ui() -> void:
	if reroll_button:
		reroll_button.add_theme_font_override("font", UITheme.get_body_bold_font())
		reroll_button.add_theme_font_size_override("font_size", 14)
		if rerolls_remaining > 0:
			reroll_button.text = Loc.tf("hud.reroll", [rerolls_remaining, max_rerolls])
			reroll_button.disabled = false
			reroll_button.add_theme_stylebox_override("normal", UITheme.make_button_style(UITheme.LACQUER, UITheme.BORDER, 8))
			reroll_button.add_theme_stylebox_override("hover", UITheme.make_button_style(UITheme.LACQUER.lightened(0.1), UITheme.GOLD, 8))
			reroll_button.add_theme_color_override("font_color", UITheme.GOLD)
		else:
			reroll_button.text = Loc.t("hud.reroll_spent")
			reroll_button.disabled = true
			reroll_button.add_theme_stylebox_override("disabled", UITheme.make_button_style(UITheme.INK_DIM, UITheme.BORDER, 8))
			reroll_button.add_theme_color_override("font_disabled_color", UITheme.MUTED)
			
	if skip_button:
		skip_button.add_theme_font_override("font", UITheme.get_body_bold_font())
		skip_button.add_theme_font_size_override("font_size", 14)
		skip_button.text = "BỎ QUA (+30 VÀNG) / SKIP (X)"
		skip_button.add_theme_stylebox_override("normal", UITheme.make_button_style(UITheme.LACQUER, UITheme.GOLD_DIM, 8))
		skip_button.add_theme_stylebox_override("hover", UITheme.make_button_style(UITheme.LACQUER.lightened(0.1), UITheme.GOLD, 8))
		skip_button.add_theme_color_override("font_color", UITheme.GOLD)

func show_upgrade_selection() -> void:
	get_tree().paused = true
	_ensure_ui_nodes()
	if panel:
		panel.visible = true
	_populate_cards()
	_update_action_bar_ui()

func _populate_cards() -> void:
	_ensure_ui_nodes()
	if not options_container:
		return

	# Clear old buttons. No explicit tween cleanup: every tween below is created on
	# the card it animates (btn.create_tween()), so queue_free() takes the hover lift
	# and the epic pulse down with it.
	for child in options_container.get_children():
		child.queue_free()

	current_offered_upgrades.clear()
	var catalog = get_upgrade_catalog()

	# Prioritize evolutions and synergy fusions if available
	var evolutions = catalog.filter(func(item): return item.get("is_evolution", false) or item.get("is_synergy", false))
	var non_evolutions = catalog.filter(func(item): return not item.get("is_evolution", false) and not item.get("is_synergy", false))
	non_evolutions.shuffle()

	for ev in evolutions:
		current_offered_upgrades.append(ev)
		if current_offered_upgrades.size() >= 3:
			break

	for item in non_evolutions:
		if current_offered_upgrades.size() >= 3:
			break
		current_offered_upgrades.append(item)

	for idx in range(current_offered_upgrades.size()):
		options_container.add_child(_build_card(current_offered_upgrades[idx], idx))

## One card. The Button keeps the click target and the focus ring; everything it
## draws is a child Label, because a Button centres a single text blob vertically
## and there is no room in that for a badge above a title above a description.
func _build_card(upgrade: Dictionary, idx: int) -> Button:
	var rarity := card_rarity(upgrade)
	var accent: Color = UITheme.RARITY_BORDER[rarity]
	var btn := Button.new()
	# 232x190 rather than the old 240x170: three cards plus two 16px separations is
	# 728px, and UpgradePanel is 760 wide with 14px of content margin each side.
	# At 240 it overflowed and the third card's border was clipped by the panel.
	btn.custom_minimum_size = Vector2(232, 190)
	btn.focus_mode = Control.FOCUS_NONE
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pivot_offset = Vector2(116, 95)
	# One stylebox for all three states: a themed Button recolours on hover by
	# itself, which would drop the aura the instant the mouse arrived.
	var sb := UITheme.rarity_style(rarity)
	for state in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(state, sb)

	var id := String(upgrade.get("id", ""))
	var icon_text := card_icon(id)
	_card_label(btn, icon_text, UITheme.get_body_bold_font(), 34,
			UITheme.RARITY_BORDER[rarity], Rect2(0, 12, 232, 44), false, HORIZONTAL_ALIGNMENT_CENTER)
	_card_label(btn, "%d. %s" % [idx + 1, upgrade.get("title", id)], UITheme.get_body_bold_font(),
			14, UITheme.rarity_text(rarity), Rect2(12, 60, 208, 44), true)
	_card_label(btn, String(upgrade.get("desc", "")), UITheme.get_body_font(),
			11, UITheme.MUTED, Rect2(12, 106, 208, 76), true)
	_card_label(btn, UITheme.RARITY_NAMES[rarity], UITheme.get_body_bold_font(),
			9, accent.darkened(0.15), Rect2(12, 4, 208, 14), false, HORIZONTAL_ALIGNMENT_RIGHT)

	if rarity >= UITheme.RARITY_EPIC:
		_pulse_aura(btn, sb, rarity)
	if rarity == UITheme.RARITY_LEGENDARY:
		btn.add_child(_ember_motes(accent))

	# The HBoxContainer owns position and rewrites it on every re-sort, so the lift
	# is measured from the laid-out value rather than from wherever the last tween
	# left the card. `resized` is the moment the container has actually done that --
	# and the pivot has to move with the real height, which the container stretches.
	# Stored as meta because a GDScript lambda captures locals by value, so a plain
	# `var base_y` assigned inside one of these callbacks would stay 0.0 forever and
	# lift the card to an absolute y of -12.
	btn.resized.connect(func():
		btn.set_meta("base_y", btn.position.y)
		btn.pivot_offset = btn.size * 0.5)
	btn.mouse_entered.connect(func():
		SoundManager.play("ui_hover", 0.2)
		_card_lift(btn, true))
	btn.mouse_exited.connect(func(): _card_lift(btn, false))

	var captured := upgrade
	btn.pressed.connect(func():
		_qi_burst(btn.global_position + btn.size * 0.5, accent)
		select_upgrade(captured))
	return btn

## A text line inside a card. IGNORE on the mouse filter because the Button is the
## thing being clicked and a Label on top of it would eat the press.
func _card_label(parent: Control, text: String, font: Font, font_size: int, color: Color,
		rect: Rect2, wrap: bool, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.position = rect.position
	l.size = rect.size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.clip_text = true
	parent.add_child(l)
	return l

## Lift 12px and grow 5% under the cursor, back down on leave. Off the base the
## container laid out rather than the current value, so a hover interrupted by a
## reroll cannot leave a card stranded half-raised.
func _card_lift(btn: Button, entered: bool) -> void:
	var base_y := float(btn.get_meta("base_y", btn.position.y))
	var tw := btn.create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "position:y", base_y + (-12.0 if entered else 0.0), 0.12)
	tw.tween_property(btn, "scale", Vector2.ONE * (1.05 if entered else 1.0), 0.12)

## Tuyệt Kỹ's pulsing aura, on the stylebox's own shadow rather than a node
## behind the card, so the pulse and the glow cannot drift apart.
func _pulse_aura(btn: Button, sb: StyleBoxFlat, rarity: int) -> void:
	var peak := UITheme.RARITY_GLOW[rarity].a
	var rest := peak * 0.35
	var tw := btn.create_tween().set_loops()
	tw.tween_method(func(a: float): sb.shadow_color.a = a, rest, peak, 0.7)
	tw.tween_method(func(a: float): sb.shadow_color.a = a, peak, rest, 0.7)

## Thần Công's ember rays. CPUParticles2D draws nothing at all without a texture,
## so the mote is a 5x5 white dot generated once and shared by every card.
static var _mote: Texture2D = null

static func mote_texture() -> Texture2D:
	if _mote == null:
		var img := Image.create(5, 5, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		_mote = ImageTexture.create_from_image(img)
	return _mote

func _ember_motes(color: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = mote_texture()
	p.amount = 16
	p.lifetime = 1.4
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(110, 90)
	p.direction = Vector2.UP
	p.spread = 55.0
	p.gravity = Vector2(0, -34)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 26.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.8
	p.color = color
	return p

## The confirmation burst, at the card the player actually clicked rather than at
## the panel centre. Freed on a timer: the tree unpauses on the next line, so this
## one gets to tick.
func _qi_burst(global_pos: Vector2, color: Color) -> void:
	var p := CPUParticles2D.new()
	p.texture = mote_texture()
	p.position = global_pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 30
	p.lifetime = 0.75
	p.spread = 180.0
	p.gravity = Vector2(0, 260)
	p.initial_velocity_min = 130.0
	p.initial_velocity_max = 400.0
	p.scale_amount_min = 1.2
	p.scale_amount_max = 3.4
	p.damping_min = 40.0
	p.damping_max = 90.0
	p.color = color
	add_child(p)
	get_tree().create_timer(1.3).timeout.connect(p.queue_free)

func _select_card_index(index: int) -> void:
	if index >= 0 and index < current_offered_upgrades.size():
		select_upgrade(current_offered_upgrades[index])

func reroll_upgrades() -> bool:
	if rerolls_remaining <= 0:
		return false
	if panel and not panel.visible:
		return false
		
	rerolls_remaining -= 1
	SoundManager.play("powerup", 0.15)
	if player:
		FloatingText.spawn(player.global_position + Vector2(0, -35), "TẨY TỦY HOÁN CỐT!", Color(0.4, 0.9, 1.0))
		
	_populate_cards()
	_update_action_bar_ui()
	return true

func skip_upgrade() -> void:
	if panel and not panel.visible:
		return
	if GameManager:
		GameManager.add_gold(30)
	if panel:
		panel.visible = false
	get_tree().paused = false
	SoundManager.play("coin", 0.15)
	if player:
		FloatingText.spawn(player.global_position + Vector2(0, -32), "+30 VÀNG (BỎ QUA)", Color(1.0, 0.85, 0.2))
	emit_signal("upgrade_selected", "skip")

func reset_rerolls() -> void:
	rerolls_remaining = max_rerolls
	_update_action_bar_ui()

func select_upgrade(upgrade_data: Dictionary) -> void:
	var id: String = upgrade_data["id"]
	match id:
		# Super Weapon Evolutions
		"evolve_dagger":
			evolved_weapons["dagger"] = true
			if weapon and weapon.has_method("evolve_to_thousand_blades"):
				weapon.evolve_to_thousand_blades()
		"evolve_shield":
			evolved_weapons["shield"] = true
			if orbit_weapon and orbit_weapon.has_method("evolve_to_solar_bulwark"):
				orbit_weapon.evolve_to_solar_bulwark()
		"evolve_lightning":
			evolved_weapons["lightning"] = true
			if lightning_weapon and lightning_weapon.has_method("evolve_to_heavens_wrath"):
				lightning_weapon.evolve_to_heavens_wrath()
		"evolve_fireball":
			evolved_weapons["fireball"] = true
			if fire_weapon and fire_weapon.has_method("evolve_to_apocalypse_meteor"):
				fire_weapon.evolve_to_apocalypse_meteor()
		"evolve_axe":
			evolved_weapons["axe"] = true
			if axe_weapon and axe_weapon.has_method("evolve_to_reapers_cleave"):
				axe_weapon.evolve_to_reapers_cleave()
		"evolve_slash":
			evolved_weapons["slash"] = true
			if slash_weapon and slash_weapon.has_method("evolve_to_nine_swords"):
				slash_weapon.evolve_to_nine_swords()

		# Tinh Võ Hợp Nhất (Dual-Weapon Synergy Fusions)
		"synergy_bao_vu":
			synergies_evolved["bao_vu"] = true
			if weapon and weapon.has_method("evolve_to_lotus_storm"):
				weapon.evolve_to_lotus_storm()
		"synergy_bang_phach":
			synergies_evolved["bang_phach"] = true
			if slash_weapon and slash_weapon.has_method("evolve_to_frost_sovereign"):
				slash_weapon.evolve_to_frost_sovereign()

		# Weapon Unlocks
		"unlock_dagger":
			weapon_levels["dagger"] = 1
			if player and player.has_method("activate_weapon"):
				player.activate_weapon("dagger")
		"unlock_shield":
			weapon_levels["shield"] = 1
			if player and player.has_method("activate_weapon"):
				player.activate_weapon("shield")
		"unlock_lightning":
			weapon_levels["lightning"] = 1
			if player and player.has_method("activate_weapon"):
				player.activate_weapon("lightning")
		"unlock_fireball":
			weapon_levels["fireball"] = 1
			if player and player.has_method("activate_weapon"):
				player.activate_weapon("fireball")
		"unlock_axe":
			weapon_levels["axe"] = 1
			if player and player.has_method("activate_weapon"):
				player.activate_weapon("axe")
		"unlock_slash":
			weapon_levels["slash"] = 1
			if player and player.has_method("activate_weapon"):
				player.activate_weapon("slash")

		# Standard Weapon Upgrades
		"damage":
			weapon_levels["dagger"] += 1
			if weapon: weapon.damage_multiplier += 0.25
		"attack_speed":
			weapon_levels["dagger"] += 1
			if weapon: weapon.speed_multiplier += 0.20
		"projectile_count":
			weapon_levels["dagger"] += 1
			if weapon: weapon.projectile_count += 1
		"orbit_shield":
			weapon_levels["shield"] += 1
			if orbit_weapon and orbit_weapon.has_method("add_shield"):
				orbit_weapon.add_shield()
		"orbit_speed":
			weapon_levels["shield"] += 1
			if orbit_weapon and orbit_weapon.has_method("upgrade_speed"):
				orbit_weapon.upgrade_speed(1.2)
		"lightning_strike":
			weapon_levels["lightning"] += 1
			if lightning_weapon and lightning_weapon.has_method("upgrade_strikes"):
				lightning_weapon.upgrade_strikes()
		"lightning_damage":
			weapon_levels["lightning"] += 1
			if lightning_weapon and lightning_weapon.has_method("upgrade_damage"):
				lightning_weapon.upgrade_damage(0.30)
		# Written onto the field directly rather than through a new upgrade_speed()
		# method, matching "attack_speed" above for the one other weapon whose cards
		# touch speed_multiplier without an upgrade_ wrapper.
		"lightning_speed":
			weapon_levels["lightning"] += 1
			if lightning_weapon: lightning_weapon.speed_multiplier += 0.25
		"fireball_count":
			weapon_levels["fireball"] += 1
			if fire_weapon and fire_weapon.has_method("upgrade_count"):
				fire_weapon.upgrade_count()
		"fireball_damage":
			weapon_levels["fireball"] += 1
			if fire_weapon and fire_weapon.has_method("upgrade_damage"):
				fire_weapon.upgrade_damage(0.35)
		"fireball_radius":
			weapon_levels["fireball"] += 1
			if fire_weapon and fire_weapon.has_method("upgrade_blast_radius"):
				fire_weapon.upgrade_blast_radius(0.35)
		"fireball_speed":
			weapon_levels["fireball"] += 1
			if fire_weapon and fire_weapon.has_method("upgrade_fire_rate"):
				fire_weapon.upgrade_fire_rate(0.25)
		"axe_count":
			weapon_levels["axe"] += 1
			if axe_weapon and axe_weapon.has_method("upgrade_count"):
				axe_weapon.upgrade_count()
		"axe_damage":
			weapon_levels["axe"] += 1
			if axe_weapon and axe_weapon.has_method("upgrade_damage"):
				axe_weapon.upgrade_damage(0.35)
		"axe_speed":
			weapon_levels["axe"] += 1
			if axe_weapon and axe_weapon.has_method("upgrade_speed"):
				axe_weapon.upgrade_speed(0.25)
		"slash_damage":
			weapon_levels["slash"] += 1
			if slash_weapon and slash_weapon.has_method("upgrade_damage"):
				slash_weapon.upgrade_damage(0.35)
		"slash_speed":
			weapon_levels["slash"] += 1
			if slash_weapon and slash_weapon.has_method("upgrade_speed"):
				slash_weapon.upgrade_speed(0.25)
		"slash_range":
			weapon_levels["slash"] += 1
			if slash_weapon and slash_weapon.has_method("upgrade_range"):
				slash_weapon.upgrade_range(0.25)
		# Both of these used to multiply the field in place, which the next
		# refresh_meta_stats() undid -- the run's most-picked card silently did
		# nothing the moment the player opened the pause shop. They are offered at
		# every level-up, so this is the most-repeated bug in the file. See
		# Player.run_speed_mult / run_magnet_mult.
		"move_speed":
			if player: player.multiply_run_speed(1.15)
		"magnet":
			if player: player.multiply_run_magnet(1.30)
		"max_hp":
			if player:
				player.add_run_max_hp(25.0)
				player.heal(25.0)
		"might_surge":
			if player:
				player.add_run_might(0.12)

	if panel:
		panel.visible = false
	get_tree().paused = false
	emit_signal("upgrade_selected", id)
	emit_signal("arsenal_updated", weapon_levels)
