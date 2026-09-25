class_name HermitShopUI
extends Control

## HermitShopUI: Wandering Hermit ("Lão Ngoan Đồng") secret shop for elixirs and gambles.

signal item_purchased(item_id: String)
signal closed

@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var items_container: HBoxContainer = $CenterContainer/PanelContainer/VBox/ItemsContainer
@onready var gold_label: Label = $CenterContainer/PanelContainer/VBox/GoldHeader/GoldLabel
@onready var close_btn: Button = $CenterContainer/PanelContainer/VBox/CloseButton
@onready var backdrop: ColorRect = get_node_or_null("Backdrop")

const ITEMS: Array[Dictionary] = [
	{
		"id": "cuu_chuyen_dan",
		"title": "Cửu Chuyển Hoàn Hồn Đan",
		"icon": "💊",
		"cost": 120,
		"effect": "Hồi 100% HP & Khí Thuẫn. Vĩnh viễn +15% Max HP trong trận.",
		"color": Color(0.25, 0.95, 0.45)
	},
	{
		"id": "tay_tuy_dan",
		"title": "Tẩy Tủy Hoán Cốt Đan",
		"icon": "⚡",
		"cost": 160,
		"effect": "Khai thông kinh mạch: +20% Sát Thương & +15% Tốc Đánh toàn vũ khí.",
		"color": Color(1.0, 0.85, 0.2)
	},
	{
		"id": "van_menh_que",
		"title": "Vận Mệnh Quẻ Bói",
		"icon": "🎲",
		"cost": 100,
		"effect": "Gieo quẻ thiên cơ: 70% ra 2 Rương Báu + 200 Vàng; 30% triệu hồi Quái Tinh Anh.",
		"color": Color(0.85, 0.4, 1.0)
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if close_btn:
		close_btn.pressed.connect(close_ui)
	if backdrop:
		backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				close_ui()
		)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_ui()
		get_viewport().set_input_as_handled()

func open_ui() -> void:
	visible = true
	get_tree().paused = true
	_refresh_ui()

func close_ui() -> void:
	visible = false
	get_tree().paused = false
	emit_signal("closed")

func _refresh_ui() -> void:
	if gold_label and GameManager:
		gold_label.text = "Túi Tiền: %d 🪙" % GameManager.total_gold
		
	if not items_container:
		return
		
	for c in items_container.get_children():
		c.queue_free()
		
	for item in ITEMS:
		var card = _create_item_card(item)
		items_container.add_child(card)

func _create_item_card(item: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 270)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	sb.border_color = item.get("color", Color.WHITE)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var icon_lbl = Label.new()
	icon_lbl.text = item.get("icon", "✨")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 32)
	vbox.add_child(icon_lbl)
	
	var title_lbl = Label.new()
	title_lbl.text = item.get("title", "")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", item.get("color", Color.WHITE))
	vbox.add_child(title_lbl)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var desc_lbl = Label.new()
	desc_lbl.text = item.get("effect", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.95))
	vbox.add_child(desc_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var cost = item.get("cost", 100)
	var can_afford = GameManager and GameManager.total_gold >= cost
	
	var buy_btn = Button.new()
	buy_btn.text = "Mua (%d 🪙)" % cost
	buy_btn.add_theme_font_size_override("font_size", 12)
	buy_btn.disabled = not can_afford
	
	var i_id = item.get("id", "")
	buy_btn.pressed.connect(func():
		_buy_item(i_id, cost)
	)
	vbox.add_child(buy_btn)
	
	panel.add_child(vbox)
	return panel

func _buy_item(item_id: String, cost: int) -> void:
	if not GameManager or GameManager.total_gold < cost:
		return
		
	GameManager.total_gold -= cost
	GameManager.emit_signal("gold_updated", GameManager.total_gold)
	GameManager.save_game_data()
	
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("apply_hermit_item"):
		p.apply_hermit_item(item_id)
		
	emit_signal("item_purchased", item_id)
	close_ui()
