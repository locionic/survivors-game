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
	{"kind": "scroll", "id": "lang_ba_vi_bo", "title": "🥋 Lăng Ba Vi Bộ", "price": 50,
		"desc": "+25% Tốc Chạy\n−4 Giáp", "apply": "speed_up", "value": 0.25},
	{"kind": "scroll", "id": "kim_cuong_bat_hoai", "title": "💎 Kim Cương Bất Hoại", "price": 60,
		"desc": "+8 Giáp\n−15% Tốc Chạy", "apply": "armor_up", "value": 8.0},
	{"kind": "scroll", "id": "hap_tinh_dai_phap", "title": "🩸 Hấp Tinh Đại Pháp", "price": 65,
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
		return false
	_spend(cost)
	reroll_uses += 1
	SoundManager.play("powerup", 0.15)
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
		return false

	_spend(price)
	if entry.get("kind", "") == "weapon":
		var up := _get_upgrade_manager()
		if not is_instance_valid(up) or not up.add_weapon(entry["id"]):
			# Full arsenal: refund rather than silently swallowing the gold.
			GameManager.run_gold += price
			GameManager.emit_signal("gold_updated", GameManager.total_gold)
			return false
	else:
		_apply_scroll(entry)

	# A spent slot empties out and can be rerolled into something else.
	cards[index]["data"] = {}
	cards[index]["locked"] = false
	SoundManager.play("powerup", 0.2)
	_refresh_all()
	return true

func _apply_scroll(entry: Dictionary) -> void:
	var p := _get_player()
	if not is_instance_valid(p):
		return
	var value := float(entry.get("value", 0.0))
	match entry.get("apply", ""):
		"might_up":
			p.meta_might_bonus += value
			p.max_health = maxf(20.0, p.max_health - 20.0)
		"speed_up":
			p.move_speed *= 1.0 + value
			p.shop_armor_bonus = maxi(0, p.shop_armor_bonus - 4)
		"armor_up":
			p.shop_armor_bonus += int(value)
			p.move_speed *= 0.85
		"lifesteal":
			p.shop_lifesteal += value
			p.max_health = maxf(20.0, p.max_health * 0.85)
		"crit":
			p.crit_chance_bonus += value
			_set_weapon_speed(0.85)
		"max_hp":
			p.max_health += value
			p.heal(value)
			p.move_speed *= 0.90
	p.current_health = minf(p.current_health, p.max_health)

## Attack-speed trade-off: every weapon already exposes speed_multiplier, so the
## penalty is applied across the whole arsenal in one sweep.
func _set_weapon_speed(mult: float) -> void:
	var p := _get_player()
	if not is_instance_valid(p):
		return
	var container := p.get_node_or_null("Weapons")
	if not container:
		return
	for node in container.get_children():
		if "speed_multiplier" in node:
			node.set("speed_multiplier", float(node.get("speed_multiplier")) * mult)

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
	# cards is deliberately NOT cleared: locked cards must survive the wave
	# transition, and this node is reused rather than freed for exactly that.
	if cards.is_empty():
		roll_items()
	else:
		_refresh_cards()
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
	dim.color = Color(0.03, 0.04, 0.07, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	_root.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	# --- 1. Header ---
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 42)
	column.add_child(header)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", HEADER_ACCENT)
	header.add_child(_title_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 24)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	header.add_child(_gold_label)

	# --- 2. Arsenal tray (6 slots) ---
	var arsenal_panel := PanelContainer.new()
	arsenal_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.10, 0.16, 0.95), Color(0.35, 0.55, 0.8, 0.7)))
	column.add_child(arsenal_panel)
	var arsenal_box := VBoxContainer.new()
	arsenal_panel.add_child(arsenal_box)
	var arsenal_title := Label.new()
	arsenal_title.name = "ArsenalTitle"
	arsenal_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	arsenal_box.add_child(arsenal_title)
	_arsenal_row = HBoxContainer.new()
	_arsenal_row.add_theme_constant_override("separation", 6)
	arsenal_box.add_child(_arsenal_row)

	# --- 3. Shop cards (4) ---
	var card_panel := PanelContainer.new()
	card_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.08, 0.05, 0.95), Color(0.8, 0.65, 0.3, 0.7)))
	column.add_child(card_panel)
	var card_box := VBoxContainer.new()
	card_panel.add_child(card_box)
	var card_title := Label.new()
	card_title.text = "📦 CỬA HÀNG TÀNG KINH — chọn 1 món"
	card_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	card_box.add_child(card_title)
	_card_row = HBoxContainer.new()
	_card_row.add_theme_constant_override("separation", 8)
	card_box.add_child(_card_row)

	# --- 4. Action bar ---
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 20)
	column.add_child(bar)

	_reroll_button = Button.new()
	_reroll_button.custom_minimum_size = Vector2(280, 46)
	_reroll_button.pressed.connect(func(): reroll())
	bar.add_child(_reroll_button)

	_next_button = Button.new()
	_next_button.text = "⚔️ VÀO HIỆP TIẾP THEO (SPACE/ENTER)"
	_next_button.custom_minimum_size = Vector2(420, 46)
	_next_button.add_theme_stylebox_override("normal", _panel_style(Color(0.30, 0.10, 0.05, 0.95), Color(1.0, 0.5, 0.2, 1.0)))
	_next_button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	_next_button.pressed.connect(close_shop)
	bar.add_child(_next_button)

func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	return sb

func _refresh_all() -> void:
	_refresh_header()
	_refresh_arsenal()
	_refresh_cards()
	_refresh_reroll_button()

func _refresh_header() -> void:
	if _title_label:
		_title_label.text = "🏛️ TÀNG KINH CÁC — KẾT THÚC HIỆP %d/20" % current_wave
		var summary := get_wave_summary()
		if summary != "":
			_title_label.text += "\n" + summary
	_refresh_gold()

func _refresh_gold() -> void:
	if _gold_label and GameManager:
		_gold_label.text = "💰 %d Vàng" % (GameManager.run_gold + GameManager.total_gold)

func _refresh_reroll_button() -> void:
	if not _reroll_button:
		return
	var cost := get_reroll_cost()
	_reroll_button.text = "🎲 TẨY TỦY (%d Vàng)" % cost
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
		title.text = "🗄️ TỦ BINH ĐẠI (%d/%d)" % [arsenal.size(), up.MAX_WEAPONS]

	for i in range(up.MAX_WEAPONS):
		_arsenal_row.add_child(_build_slot(up, arsenal, i))

func _build_slot(up: Node, arsenal: Array, index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(196, 120)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if index >= arsenal.size():
		panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.06, 0.08, 0.9), Color(0.25, 0.25, 0.3, 0.6)))
		var empty := Label.new()
		empty.text = "Ô %d\n\n— trống —" % (index + 1)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		panel.add_child(empty)
		return panel

	var w: Dictionary = arsenal[index]
	var info: Dictionary = up.WEAPON_INFO.get(w["id"], {"name": w["id"], "icon": "❓"}).duplicate()
	info["name"] = up.get_weapon_name(w["id"]) # localised, canonical
	var tier := int(w.get("tier", 1))
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.11, 0.17, 0.95), up.tier_color(tier)))

	var box := VBoxContainer.new()
	panel.add_child(box)

	var name_label := Label.new()
	name_label.text = "%s %s" % [info["icon"], info["name"]]
	name_label.add_theme_font_size_override("font_size", 15)
	box.add_child(name_label)

	var tier_label := Label.new()
	tier_label.text = "⚔️ %s  •  ô %d" % [up.tier_label(tier), index + 1]
	tier_label.add_theme_color_override("font_color", up.tier_color(tier))
	box.add_child(tier_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)

	# Two of the same type AND the same tier fuse into one tier higher, freeing
	# the slot. A maxed tier has nothing to fuse into.
	var fuseable: bool = tier < up.MAX_WEAPON_TIER and up.count_at_tier(w["id"], tier) >= 2
	var fuse_btn := Button.new()
	fuse_btn.text = "⚡ GHÉP" if fuseable else "⚡ —"
	fuse_btn.custom_minimum_size = Vector2(86, 30)
	fuse_btn.disabled = not fuseable
	if fuseable:
		fuse_btn.add_theme_stylebox_override("normal", _panel_style(Color(0.10, 0.28, 0.14, 0.95), Color(0.4, 1.0, 0.6, 0.9)))
		fuse_btn.add_theme_color_override("font_color", Color(0.7, 1.0, 0.8))
		var wid := String(w["id"])
		fuse_btn.pressed.connect(func(): _fuse(up, wid, tier))
	row.add_child(fuse_btn)

	var sell_btn := Button.new()
	sell_btn.text = "💰 BÁN %d" % _sell_value(w["id"])
	sell_btn.custom_minimum_size = Vector2(100, 30)
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
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(288, 0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)

	var buy := Button.new()
	buy.custom_minimum_size = Vector2(0, 116)
	buy.disabled = entry.is_empty() or get_gold() < int(entry.get("price", 0))

	if entry.is_empty():
		buy.text = "Ô %d\n\n— đã mua —" % (index + 1)
	else:
		buy.text = "%s\n%s\n\n💰 %d Vàng" % [entry["title"], entry["desc"], int(entry["price"])]
		if entry.get("kind", "") == "scroll":
			buy.add_theme_stylebox_override("normal", _panel_style(Color(0.16, 0.10, 0.05, 0.95), Color(0.9, 0.6, 0.25, 0.9)))
		else:
			buy.add_theme_stylebox_override("normal", _panel_style(Color(0.10, 0.12, 0.18, 0.95), Color(0.3, 0.5, 0.7, 0.85)))
	buy.pressed.connect(func(): purchase_card(index))
	box.add_child(buy)

	var lock_btn := Button.new()
	lock_btn.custom_minimum_size = Vector2(0, 28)
	lock_btn.text = "🔒 KHÓA — giữ qua tẩy tủy" if locked else "🔓 MỞ KHÓA"
	lock_btn.pressed.connect(func(): toggle_lock(index))
	box.add_child(lock_btn)

	return box
