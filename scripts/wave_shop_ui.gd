class_name WaveShopUI
extends CanvasLayer

## Tàng Kinh Các — the intermission martial shop between Võ Đài waves.
##
## Built entirely in code (same precedent as UpgradeManager) so scenes/wave_shop_ui.tscn
## stays a one-node scene and scripts/hud.gd stays untouched. Every purchasable
## action is exposed as a plain method (roll_items / purchase_card / reroll /
## toggle_lock) so the headless suite can drive the economy without a viewport.
##
## Prices are fixed constants: the only escalating number in the shop is the
## reroll, which climbs 15g + 5g per use within a wave. That is the inflation lock.

signal shop_closed(next_wave: int)

const CARD_COUNT: int = 4
const REROLL_BASE_COST: int = 15
const REROLL_COST_STEP: int = 5
const SELL_REFUND: float = 0.60
const HEADER_ACCENT: Color = Color(1.0, 0.82, 0.35)

const WEAPON_POOL: Array[Dictionary] = [
	{"kind": "weapon", "id": "dagger", "title": "🗡️ Ám Khí Phi Đao", "price": 40, "desc": "Tự động nhắm bắn mục tiêu gần nhất."},
	{"kind": "weapon", "id": "shield", "title": "🛡️ Khiên Bát Quái", "price": 45, "desc": "Khiên hộ thể xoay quanh đẩy lùi kẻ địch."},
	{"kind": "weapon", "id": "lightning", "title": "⚡ Cửu Thiên Lôi Điện", "price": 55, "desc": "Sấm sét từ thiên hà trừng phạt quái vật."},
	{"kind": "weapon", "id": "fireball", "title": "🔥 Liệt Hỏa Chưởng Cầu", "price": 50, "desc": "Cầu lửa bộc phá gây sát thương diện rộng."},
	{"kind": "weapon", "id": "axe", "title": "🪓 Đả Cẩu Trận", "price": 50, "desc": "Rìu xoay tròn xuyên thấu theo hình cầu vồng."},
	{"kind": "weapon", "id": "slash", "title": "⚔️ Độc Cô Cửu Kiếm", "price": 60, "desc": "Trảm kích bán nguyệt theo hướng di chuyển."}
]

## Brotato-style radical trade-offs: every scroll gives something real and takes
## something real. The `apply` keys name which player stat gets the boon; the
## paired cost is applied per-id further down, keeping each scroll's two halves
## side by side instead of split across two match arms.
const SCROLL_POOL: Array[Dictionary] = [
	{"kind": "scroll", "id": "cuu_am_chan_kinh", "title": "📜 Cửu Âm Chân Kinh", "price": 55,
		"desc": "+30% Sức Mạnh toàn thân\n−20 Máu Tối Đa", "apply": "might_up", "value": 0.30},
	{"kind": "scroll", "id": "lang_ba_vi_bo", "title": "🥋 Phi Hành Thủ Pháp", "price": 50,
		"desc": "+25% Tốc Chạy\n−4 Giáp", "apply": "speed_up", "value": 0.25},
	{"kind": "scroll", "id": "kim_cuong_bat_hoai", "title": "💎 Kim Cương Bất Hoại", "price": 60,
		"desc": "+8 Giáp\n−15% Tốc Chạy", "apply": "armor_up", "value": 8.0},
	{"kind": "scroll", "id": "hap_tinh_dai_phap", "title": "🩸 Hút Hồn Thủ Pháp", "price": 65,
		"desc": "+8% Hút Sinh Lực\n−15% Máu Tối Đa", "apply": "lifesteal", "value": 0.08},
	{"kind": "scroll", "id": "bat_hoang_bi_dien", "title": "⚡ Bát Hoang Bí Điển", "price": 55,
		"desc": "+35% Tỷ Lệ Bạo Kích\n−15% Tốc Đánh", "apply": "crit", "value": 0.35},
	{"kind": "scroll", "id": "tay_tuy_dan", "title": "🍵 Tẩy Tủy Đan", "price": 45,
		"desc": "+50 Máu Tối Đa\n−10% Tốc Chạy", "apply": "max_hp", "value": 50.0}
]

var cards: Array[Dictionary] = []
var current_wave: int = 1
var reroll_uses: int = 0

## Milestone 2: what the bell paid for the hiệp that just ended, copied off the
## director on open. Held here rather than read live so the banner keeps showing
## the payout while the player spends the money it just earned.
var payout_wave: int = 0
var payout_clear_gold: int = 0
var payout_interest: int = 0

var _root: Control = null
var _title_label: Label = null
var _gold_label: Label = null
var _arsenal_row: HBoxContainer = null
var _card_row: HBoxContainer = null
var _reroll_button: Button = null
var _next_button: Button = null

func _ready() -> void:
	add_to_group("wave_shop")
	# The tree is paused while the shop is up, so this whole subtree ignores it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			close_shop()

# --- economy ------------------------------------------------------------------

func get_reroll_cost() -> int:
	return REROLL_BASE_COST + REROLL_COST_STEP * reroll_uses

func get_gold() -> int:
	return GameManager.run_gold if GameManager else 0

func _spend(amount: int) -> void:
	GameManager.run_gold -= amount
	GameManager.emit_signal("gold_updated", GameManager.total_gold)

## Fill the four slots. Locked slots keep the card they already hold; only the
## unlocked ones are redrawn.
func roll_items() -> void:
	var pool: Array = []
	pool.append_array(WEAPON_POOL)
	pool.append_array(SCROLL_POOL)

	while cards.size() < CARD_COUNT:
		cards.append({"data": {}, "locked": false})

	for i in range(cards.size()):
		if cards[i].get("locked", false) and not cards[i]["data"].is_empty():
			continue
		cards[i]["data"] = pool[randi() % pool.size()]
	_refresh_cards()

func reroll() -> bool:
	var cost := get_reroll_cost()
	if get_gold() < cost:
		SoundManager.play_ui_deny()
		return false
	_spend(cost)
	reroll_uses += 1
	SoundManager.play_ui_buy()
	roll_items()
	_refresh_gold()
	return true

func toggle_lock(index: int) -> bool:
	if index < 0 or index >= cards.size():
		return false
	cards[index]["locked"] = not cards[index]["locked"]
	SoundManager.play("coin", 0.05)
	_refresh_cards()
	return cards[index]["locked"]

## Buy the card in `index`: a weapon joins the arsenal, a scroll rewrites the
## player's stats in place. False when the slot is empty or unaffordable.
func purchase_card(index: int) -> bool:
	if index < 0 or index >= cards.size():
		return false
	var entry: Dictionary = cards[index]["data"]
	if entry.is_empty():
		return false
	var price := int(entry.get("price", 0))
	if get_gold() < price:
		SoundManager.play_ui_deny()
		return false

	_spend(price)
	if entry.get("kind", "") == "weapon":
		var up := _get_upgrade_manager()
		if not is_instance_valid(up) or not up.add_weapon(entry["id"]):
			# Full arsenal: refund rather than silently swallowing the gold.
			GameManager.run_gold += price
			GameManager.emit_signal("gold_updated", GameManager.total_gold)
			SoundManager.play_ui_deny()
			return false
	else:
		_apply_scroll(entry)

	# A spent slot empties out and can be rerolled into something else.
	cards[index]["data"] = {}
	cards[index]["locked"] = false
	SoundManager.play_ui_buy()
	_refresh_all()
	return true

func _apply_scroll(entry: Dictionary) -> void:
	var p := _get_player()
	if not is_instance_valid(p):
		return
	var value := float(entry.get("value", 0.0))
	# Every branch goes through the player's add_run_* helpers rather than writing
	# the live stat. The meta shop is reachable from the pause menu, so a direct
	# `p.max_health -= 20` here used to evaporate the moment the player bought a
	# single Vitality level with the run's own gold.
	match entry.get("apply", ""):
		"might_up":
			p.add_run_might(value)
			p.add_run_max_hp(-20.0)
		"speed_up":
			p.multiply_run_speed(1.0 + value)
			p.shop_armor_bonus = maxi(0, p.shop_armor_bonus - 4)
		"armor_up":
			p.shop_armor_bonus += int(value)
			p.multiply_run_speed(0.85)
		"lifesteal":
			p.shop_lifesteal += value
			p.add_run_max_hp(-p.max_health * 0.15)
		"crit":
			p.add_run_crit(value)
			_set_weapon_speed(0.85)
		"max_hp":
			p.add_run_max_hp(value)
			p.heal(value)
			p.multiply_run_speed(0.90)
	p.current_health = minf(p.current_health, p.max_health)

## Attack-speed trade-off. This is a price, not a guarantee, so it lands on the
## player's own multiplier instead of any weapon's speed_multiplier -- the field the
## Chrono Hourglass floors. The sweep used to live here, which meant the floor and
## the penalty were the same float: whoever clamped last won, and a relic owner got
## the crit item's discount for free while a player without the relic paid full price
## for the same upgrade. One player-level term also needs no container walk and no
## re-assertion -- all five weapons read get_attack_speed_multiplier() already.
func _set_weapon_speed(mult: float) -> void:
	var p := _get_player()
	if not is_instance_valid(p):
		return
	if p.has_method("multiply_run_attack_speed"):
		p.call("multiply_run_attack_speed", mult)

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") if get_tree() else null

func _get_upgrade_manager() -> Node:
	return get_tree().get_first_node_in_group("upgrade_manager") if get_tree() else null

# --- open / close -------------------------------------------------------------

func open_for_wave(wave_num: int) -> void:
	current_wave = wave_num
	reroll_uses = 0
	_read_payout()
	# Banking paid out. The savings interest gets its own coin cue so the player
	# hears the purse grow before the spending starts -- and so "earned" never
	# sounds like the "spent" cue a purchase fires.
	if payout_interest > 0:
		SoundManager.play("coin", 0.15)
	# Roll fresh items for the new wave; roll_items preserves cards flagged as locked.
	roll_items()
	show()
	_refresh_all()

## Pull the last end_wave() payout off the director so the header can show the
## player what banking their gold actually earned. A shop opened without one (a
## test, or the very first round) simply shows no banner.
func _read_payout() -> void:
	payout_wave = 0
	payout_clear_gold = 0
	payout_interest = 0
	var director := get_tree().get_first_node_in_group("wave_director") if get_tree() else null
	if is_instance_valid(director) and director.last_clear_gold > 0:
		payout_wave = current_wave - 1
		payout_clear_gold = director.last_clear_gold
		payout_interest = director.last_interest_earned

func get_wave_summary() -> String:
	if payout_wave <= 0:
		return ""
	return "Hoàn thành Hiệp %d! Thưởng: +%d Vàng | Lợi tức tiết kiệm: +%d Vàng" % [
		payout_wave, payout_clear_gold, payout_interest]

func close_shop() -> void:
	hide()
	var director := get_tree().get_first_node_in_group("wave_director") if get_tree() else null
	if is_instance_valid(director) and director.has_method("advance_to_next_wave"):
		director.advance_to_next_wave()
	else:
		get_tree().paused = false
	emit_signal("shop_closed", current_wave + 1)

# --- UI construction ----------------------------------------------------------

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "ShopRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.04, 0.05, 0.08, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	_root.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	# --- 1. Header ---
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 48)
	column.add_child(header)

	_title_label = Label.new()
	_title_label.add_theme_font_override("font", UITheme.get_display_font())
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", UITheme.GOLD)
	_title_label.add_theme_color_override("font_outline_color", UITheme.INK)
	_title_label.add_theme_constant_override("outline_size", 4)
	header.add_child(_title_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_gold_label = Label.new()
	_gold_label.add_theme_font_override("font", UITheme.get_body_bold_font())
	_gold_label.add_theme_font_size_override("font_size", 22)
	_gold_label.add_theme_color_override("font_color", UITheme.GOLD)
	header.add_child(_gold_label)

	# --- 2. Arsenal tray (6 slots) ---
	var arsenal_panel := PanelContainer.new()
	arsenal_panel.add_theme_stylebox_override("panel", UITheme.make_card_panel(UITheme.LACQUER, UITheme.BORDER, 8, 1))
	column.add_child(arsenal_panel)

	var arsenal_box := VBoxContainer.new()
	arsenal_box.add_theme_constant_override("separation", 6)
	arsenal_panel.add_child(arsenal_box)

	var arsenal_title := Label.new()
	arsenal_title.name = "ArsenalTitle"
	arsenal_title.add_theme_font_override("font", UITheme.get_body_bold_font())
	arsenal_title.add_theme_font_size_override("font_size", 13)
	arsenal_title.add_theme_color_override("font_color", UITheme.MUTED)
	arsenal_box.add_child(arsenal_title)

	_arsenal_row = HBoxContainer.new()
	_arsenal_row.add_theme_constant_override("separation", 8)
	arsenal_box.add_child(_arsenal_row)

	# --- 3. Shop cards (4) ---
	var card_panel := PanelContainer.new()
	card_panel.add_theme_stylebox_override("panel", UITheme.make_card_panel(UITheme.LACQUER, UITheme.BORDER, 8, 1))
	column.add_child(card_panel)

	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 8)
	card_panel.add_child(card_box)

	var card_title := Label.new()
	card_title.text = "CỬA HÀNG TÀNG KINH — CHỌN 1 MÓN"
	card_title.add_theme_font_override("font", UITheme.get_body_bold_font())
	card_title.add_theme_font_size_override("font_size", 13)
	card_title.add_theme_color_override("font_color", UITheme.MUTED)
	card_box.add_child(card_title)

	_card_row = HBoxContainer.new()
	_card_row.add_theme_constant_override("separation", 10)
	card_box.add_child(_card_row)

	# --- 4. Action bar ---
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 24)
	column.add_child(bar)

	_reroll_button = Button.new()
	_reroll_button.custom_minimum_size = Vector2(260, 44)
	_reroll_button.add_theme_font_override("font", UITheme.get_body_bold_font())
	_reroll_button.add_theme_font_size_override("font_size", 15)
	_reroll_button.add_theme_stylebox_override("normal", UITheme.make_button_style(UITheme.LACQUER, UITheme.BORDER, 8))
	_reroll_button.add_theme_stylebox_override("hover", UITheme.make_button_style(UITheme.LACQUER.lightened(0.1), UITheme.GOLD, 8))
	_reroll_button.add_theme_color_override("font_color", UITheme.GOLD)
	_reroll_button.mouse_entered.connect(func(): SoundManager.play_ui_hover())
	_reroll_button.pressed.connect(func(): reroll())
	bar.add_child(_reroll_button)

	_next_button = Button.new()
	_next_button.text = "VÀO HIỆP TIẾP THEO (SPACE / ENTER)"
	_next_button.custom_minimum_size = Vector2(380, 44)
	_next_button.add_theme_font_override("font", UITheme.get_body_bold_font())
	_next_button.add_theme_font_size_override("font_size", 15)
	_next_button.add_theme_stylebox_override("normal", UITheme.make_cta_button_style())
	_next_button.add_theme_stylebox_override("hover", UITheme.make_button_style(UITheme.GOLD.lightened(0.12), UITheme.GOLD, 8))
	_next_button.add_theme_stylebox_override("pressed", UITheme.make_button_style(UITheme.GOLD.darkened(0.18), UITheme.GOLD_DIM, 8))
	_next_button.add_theme_color_override("font_color", UITheme.TEXT_ON_GOLD)
	_next_button.add_theme_color_override("font_hover_color", UITheme.TEXT_ON_GOLD)
	_next_button.add_theme_color_override("font_pressed_color", UITheme.TEXT_ON_GOLD)
	_next_button.mouse_entered.connect(func(): SoundManager.play_ui_hover())
	_next_button.pressed.connect(func():
		SoundManager.play_ui_click()
		close_shop()
	)
	bar.add_child(_next_button)

func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	return UITheme.make_card_panel(bg, border, 8, 2)

func _refresh_all() -> void:
	_refresh_header()
	_refresh_arsenal()
	_refresh_cards()
	_refresh_reroll_button()

func _refresh_header() -> void:
	if _title_label:
		_title_label.text = "TÀNG KINH CÁC — KẾT THÚC HIỆP %d/20" % current_wave
		var summary := get_wave_summary()
		if summary != "":
			_title_label.text += "\n" + summary
	_refresh_gold()

func _refresh_gold() -> void:
	if _gold_label and GameManager:
		# run_gold, not the sum. get_gold() below returns run_gold and _spend()
		# deducts from it, and every card's buy button is gated on get_gold() >= price
		# -- so this label is the number the player reasons with when deciding what to
		# buy, and it was showing a total_gold the shop would never spend. A player
		# holding 100 run gold and 2831 banked read "VÀNG: 2931" over a shop that
		# refused everything under 2931. The hermit shop has always displayed the one
		# currency it spends; this is the same rule, and it is the run currency rather
		# than the persistent one because a wave purchase is a run purchase.
		_gold_label.text = "VÀNG: %d" % get_gold()

func _refresh_reroll_button() -> void:
	if not _reroll_button:
		return
	var cost := get_reroll_cost()
	_reroll_button.text = "TẨY TỦY (%d Vàng)" % cost
	_reroll_button.disabled = get_gold() < cost

func _refresh_arsenal() -> void:
	if not _arsenal_row:
		return
	for child in _arsenal_row.get_children():
		child.queue_free()

	var up := _get_upgrade_manager()
	if not is_instance_valid(up):
		return
	var arsenal: Array = up.arsenal
	var title := _arsenal_row.get_parent().get_node_or_null("ArsenalTitle")
	if title:
		title.text = "TỦ BINH KHÍ (%d/%d)" % [arsenal.size(), up.MAX_WEAPONS]

	for i in range(up.MAX_WEAPONS):
		_arsenal_row.add_child(_build_slot(up, arsenal, i))

func _build_slot(up: Node, arsenal: Array, index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 116)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if index >= arsenal.size():
		panel.add_theme_stylebox_override("panel", UITheme.make_card_panel(UITheme.INK_DIM, UITheme.BORDER, 8, 1))
		var empty := Label.new()
		empty.text = "Ô %d\n— TRỐNG —" % (index + 1)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_font_override("font", UITheme.get_body_font())
		empty.add_theme_color_override("font_color", UITheme.MUTED)
		panel.add_child(empty)
		return panel

	var w: Dictionary = arsenal[index]
	var wid := String(w["id"])
	var info: Dictionary = up.WEAPON_INFO.get(wid, {"name": wid, "icon": ""}).duplicate()
	info["name"] = up.get_weapon_name(wid)
	var tier := int(w.get("tier", 1))
	var tier_col: Color = up.tier_color(tier)

	panel.add_theme_stylebox_override("panel", UITheme.make_card_panel(UITheme.LACQUER, tier_col, 8, 2))

	var margin := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var name_label := Label.new()
	name_label.text = info["name"]
	name_label.add_theme_font_override("font", UITheme.get_body_bold_font())
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", UITheme.TEXT)
	box.add_child(name_label)

	var tier_label := Label.new()
	tier_label.text = "%s  •  Ô %d" % [up.tier_label(tier), index + 1]
	tier_label.add_theme_font_override("font", UITheme.get_body_bold_font())
	tier_label.add_theme_font_size_override("font_size", 11)
	tier_label.add_theme_color_override("font_color", tier_col)
	box.add_child(tier_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)

	var fuseable: bool = tier < up.MAX_WEAPON_TIER and up.count_at_tier(w["id"], tier) >= 2
	var fuse_btn := Button.new()
	fuse_btn.text = "GHÉP" if fuseable else "—"
	fuse_btn.custom_minimum_size = Vector2(80, 26)
	fuse_btn.disabled = not fuseable
	fuse_btn.add_theme_font_override("font", UITheme.get_body_bold_font())
	fuse_btn.add_theme_font_size_override("font_size", 11)
	if fuseable:
		fuse_btn.add_theme_stylebox_override("normal", UITheme.make_button_style(Color("#10281E"), UITheme.JADE, 6))
		fuse_btn.add_theme_color_override("font_color", UITheme.JADE)
		fuse_btn.mouse_entered.connect(func(): SoundManager.play_ui_hover())
		fuse_btn.pressed.connect(func():
			_fuse(up, wid, tier)
			SoundManager.play_ui_click()
		)
	else:
		fuse_btn.add_theme_stylebox_override("normal", UITheme.make_button_style(UITheme.INK_DIM, UITheme.BORDER, 6))
		fuse_btn.add_theme_color_override("font_color", UITheme.MUTED)
	row.add_child(fuse_btn)

	var sell_btn := Button.new()
	sell_btn.text = "BÁN %d" % _sell_value(w["id"])
	sell_btn.custom_minimum_size = Vector2(80, 26)
	sell_btn.add_theme_font_override("font", UITheme.get_body_bold_font())
	sell_btn.add_theme_font_size_override("font_size", 11)
	sell_btn.add_theme_stylebox_override("normal", UITheme.make_button_style(UITheme.INK, UITheme.BORDER, 6))
	sell_btn.add_theme_color_override("font_color", UITheme.GOLD)
	sell_btn.mouse_entered.connect(func(): SoundManager.play_ui_hover())
	sell_btn.pressed.connect(func(): _sell(up, index))
	row.add_child(sell_btn)

	return panel

func _fuse(up: Node, id: String, tier: int) -> void:
	if up.fuse_weapons(id, tier):
		_refresh_all()

func _sell(up: Node, index: int) -> void:
	var removed: Dictionary = up.remove_weapon_at(index)
	if removed.is_empty():
		return
	var refund := _sell_value(removed["id"])
	GameManager.run_gold += refund
	GameManager.emit_signal("gold_updated", GameManager.total_gold)
	SoundManager.play("coin", 0.1)
	_refresh_all()

## 60% of list price, the Brotato sell rate.
func _sell_value(id: String) -> int:
	for item in WEAPON_POOL:
		if item["id"] == id:
			return int(float(item["price"]) * SELL_REFUND)
	return 0

func _refresh_cards() -> void:
	if not _card_row:
		return
	for child in _card_row.get_children():
		child.queue_free()

	for i in range(cards.size()):
		_card_row.add_child(_build_card(i))

func _build_card(index: int) -> Control:
	var entry: Dictionary = cards[index]["data"]
	var locked: bool = cards[index].get("locked", false)

	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(270, 185)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var is_scroll: bool = entry.get("kind", "") == "scroll"
	var border_col: Color = UITheme.GOLD if locked else (Color("#5C7CFA") if is_scroll else UITheme.BORDER)
	var bg_col: Color = Color("#181B26") if locked else UITheme.LACQUER
	card_panel.add_theme_stylebox_override("panel", UITheme.make_card_panel(bg_col, border_col, 10, 2 if locked else 1))

	var margin := MarginContainer.new()
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 10)
	card_panel.add_child(margin)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(card_vbox)

	if entry.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "— ĐÃ MUA —"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_lbl.add_theme_font_override("font", UITheme.get_body_bold_font())
		empty_lbl.add_theme_color_override("font_color", UITheme.MUTED)
		card_vbox.add_child(empty_lbl)
		return card_panel

	# 1. Top row: Type Tag + Lock toggle button
	var top_bar := HBoxContainer.new()
	card_vbox.add_child(top_bar)

	var type_badge := Label.new()
	type_badge.text = "[ BÍ TỊCH ]" if is_scroll else "[ VÕ HỌC T1 ]"
	type_badge.add_theme_font_override("font", UITheme.get_body_bold_font())
	type_badge.add_theme_font_size_override("font_size", 11)
	type_badge.add_theme_color_override("font_color", Color("#5C7CFA") if is_scroll else UITheme.GOLD)
	top_bar.add_child(type_badge)

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(top_spacer)

	var lock_btn := Button.new()
	lock_btn.text = "ĐÃ KHÓA" if locked else "KHÓA"
	lock_btn.custom_minimum_size = Vector2(74, 24)
	lock_btn.add_theme_font_override("font", UITheme.get_body_bold_font())
	lock_btn.add_theme_font_size_override("font_size", 10)
	if locked:
		lock_btn.add_theme_stylebox_override("normal", UITheme.make_button_style(Color("#2A2410"), UITheme.GOLD, 5))
		lock_btn.add_theme_color_override("font_color", UITheme.GOLD)
	else:
		lock_btn.add_theme_stylebox_override("normal", UITheme.make_button_style(UITheme.INK, UITheme.BORDER, 5))
		lock_btn.add_theme_color_override("font_color", UITheme.MUTED)
	lock_btn.mouse_entered.connect(func(): SoundManager.play_ui_hover())
	lock_btn.pressed.connect(func():
		toggle_lock(index)
		SoundManager.play_ui_click()
	)
	top_bar.add_child(lock_btn)

	# 2. Title
	var title_lbl := Label.new()
	title_lbl.text = entry.get("title", "")
	title_lbl.add_theme_font_override("font", UITheme.get_body_bold_font())
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", UITheme.TEXT)
	card_vbox.add_child(title_lbl)

	# 3. Description
	var desc_lbl := Label.new()
	desc_lbl.text = entry.get("desc", "")
	desc_lbl.add_theme_font_override("font", UITheme.get_body_font())
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", UITheme.MUTED)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(desc_lbl)

	# 4. Buy Button
	var price := int(entry.get("price", 0))
	var can_afford: bool = get_gold() >= price
	var buy_btn := Button.new()
	buy_btn.text = "MUA: %d VÀNG" % price
	buy_btn.custom_minimum_size = Vector2(0, 36)
	buy_btn.disabled = not can_afford
	buy_btn.add_theme_font_override("font", UITheme.get_body_bold_font())
	buy_btn.add_theme_font_size_override("font_size", 13)

	if can_afford:
		buy_btn.add_theme_stylebox_override("normal", UITheme.make_cta_button_style())
		buy_btn.add_theme_stylebox_override("hover", UITheme.make_button_style(UITheme.GOLD.lightened(0.12), UITheme.GOLD, 8))
		buy_btn.add_theme_stylebox_override("pressed", UITheme.make_button_style(UITheme.GOLD.darkened(0.18), UITheme.GOLD_DIM, 8))
		buy_btn.add_theme_color_override("font_color", UITheme.TEXT_ON_GOLD)
		buy_btn.add_theme_color_override("font_hover_color", UITheme.TEXT_ON_GOLD)
		buy_btn.add_theme_color_override("font_pressed_color", UITheme.TEXT_ON_GOLD)
	else:
		buy_btn.add_theme_stylebox_override("normal", UITheme.make_button_style(UITheme.INK_DIM, UITheme.BORDER, 8))
		buy_btn.add_theme_stylebox_override("disabled", UITheme.make_button_style(UITheme.INK_DIM, UITheme.BORDER, 8))
		buy_btn.add_theme_color_override("font_color", UITheme.MUTED)
		buy_btn.add_theme_color_override("font_disabled_color", UITheme.MUTED)

	buy_btn.mouse_entered.connect(func():
		if can_afford:
			SoundManager.play_ui_hover()
	)
	buy_btn.pressed.connect(func(): purchase_card(index))
	card_vbox.add_child(buy_btn)

	return card_panel
