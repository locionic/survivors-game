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
		
	if weapon_levels.get("fireball", 0) >= 1 and weapon_levels.get("fireball", 0) < 5:
		options.append({"id": "fireball_count", "title": "Tam Muội Chân Hỏa", "desc": "+1 Cầu Lửa đồng thời (Cấp %d/5)" % (weapon_levels["fireball"] + 1)})
		options.append({"id": "fireball_damage", "title": "Bộc Liệt Chưởng", "desc": "+35%% Sát Thương Cầu Lửa (Cấp %d/5)" % (weapon_levels["fireball"] + 1)})
		options.append({"id": "fireball_radius", "title": "Liệt Hỏa Phần Thiên", "desc": "+35%% Phạm Vi Nổ Cầu Lửa (Cấp %d/5)" % (weapon_levels["fireball"] + 1)})
		
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
			reroll_button.text = "TẨY TỦY (REROLL) [%d/%d] (R)" % [rerolls_remaining, max_rerolls]
			reroll_button.disabled = false
			reroll_button.add_theme_stylebox_override("normal", UITheme.make_button_style(UITheme.LACQUER, UITheme.BORDER, 8))
			reroll_button.add_theme_stylebox_override("hover", UITheme.make_button_style(UITheme.LACQUER.lightened(0.1), UITheme.GOLD, 8))
			reroll_button.add_theme_color_override("font_color", UITheme.GOLD)
		else:
			reroll_button.text = "TẨY TỦY (HẾT LƯỢT)"
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
		
	# Clear old buttons
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
		var upgrade = current_offered_upgrades[idx]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(240, 170)
		btn.text = "[%d] %s\n\n%s" % [idx + 1, upgrade["title"], upgrade["desc"]]
		
		# Style evolution cards with glowing golden border and background
		if upgrade.get("is_evolution", false) or upgrade.get("is_synergy", false):
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.24, 0.16, 0.04, 0.95)
			sb.border_color = Color(1.0, 0.85, 0.25, 1.0) if not upgrade.get("is_synergy", false) else Color(0.45, 1.0, 0.85, 1.0)
			sb.set_border_width_all(3)
			sb.set_corner_radius_all(6)
			sb.set_content_margin_all(8)
			btn.add_theme_stylebox_override("normal", sb)
			btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5) if not upgrade.get("is_synergy", false) else Color(0.6, 1.0, 0.9))
		else:
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.08, 0.12, 0.18, 0.92)
			sb.border_color = Color(0.25, 0.45, 0.65, 0.85)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(6)
			sb.set_content_margin_all(8)
			btn.add_theme_stylebox_override("normal", sb)
			
		var captured_upgrade = upgrade
		btn.pressed.connect(func(): select_upgrade(captured_upgrade))
		options_container.add_child(btn)

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
		"move_speed":
			if player: player.move_speed *= 1.15
		"magnet":
			if player:
				player.magnet_radius *= 1.30
				if player.magnet_area and player.magnet_area.has_node("CollisionShape2D"):
					var shape = player.magnet_area.get_node("CollisionShape2D").shape
					if shape is CircleShape2D:
						shape.radius = player.magnet_radius
		"max_hp":
			if player:
				player.max_health += 25.0
				player.heal(25.0)
		"might_surge":
			if player:
				player.meta_might_bonus += 0.12

	if panel:
		panel.visible = false
	get_tree().paused = false
	emit_signal("upgrade_selected", id)
	emit_signal("arsenal_updated", weapon_levels)
