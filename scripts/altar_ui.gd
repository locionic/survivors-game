class_name AltarUI
extends Control

## AltarUI: Modal displaying Demonic Risk-Reward Pacts at the Demonic Altar.

signal pact_chosen(pact_id: String)
signal closed

@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var cards_container: HBoxContainer = $CenterContainer/PanelContainer/VBox/CardsContainer
@onready var close_btn: Button = $CenterContainer/PanelContainer/VBox/CloseButton
@onready var backdrop: ColorRect = get_node_or_null("Backdrop")

const PACTS: Array[Dictionary] = [
	{
		"id": "blood_covenant",
		"title": "Ma Đạo Huyết Khế",
		"icon": "🩸",
		"curse": "Mất 35% Máu hiện tại & Nhận thêm +20% sát thương",
		"boon": "+45% Sát Thương (Might) & Hồi 4 HP mỗi đòn đánh trúng",
		"border_color": Color(0.9, 0.15, 0.25)
	},
	{
		"id": "abyssal_frenzy",
		"title": "Tà Khí Đồ Sát",
		"icon": "👹",
		"curse": "Quái chạy nhanh hơn +30% & Bầy quái đông hơn +40%",
		"boon": "Nhân đôi toàn bộ Kinh Nghiệm (2x XP) & Tiền Vàng (2x Gold)",
		"border_color": Color(0.75, 0.2, 0.95)
	},
	{
		"id": "hermit_sacrifice",
		"title": "Vạn Cổ Độc Cô",
		"icon": "🚫",
		"curse": "Khí Thuẫn (Qi Shield) bị phong ấn hoàn toàn về 0",
		"boon": "Nhận ngay 1 Rương Cổ Vật Thần Binh ngẫu nhiên + 500 Vàng",
		"border_color": Color(1.0, 0.65, 0.1)
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
	_setup_cards()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_ui()
		get_viewport().set_input_as_handled()

func _setup_cards() -> void:
	if not cards_container:
		return
	for c in cards_container.get_children():
		c.queue_free()
		
	for p in PACTS:
		var card = _create_pact_card(p)
		cards_container.add_child(card)

func _create_pact_card(p: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 290)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.12, 0.95)
	sb.border_color = p.get("border_color", Color.RED)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	var icon_lbl = Label.new()
	icon_lbl.text = p.get("icon", "💀")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(icon_lbl)
	
	var title_lbl = Label.new()
	title_lbl.text = p.get("title", "")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", p.get("border_color", Color.WHITE))
	vbox.add_child(title_lbl)
	
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	# Curse section
	var curse_header = Label.new()
	curse_header.text = "⚠️ LỜI NGUYỄN:"
	curse_header.add_theme_font_size_override("font_size", 11)
	curse_header.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(curse_header)
	
	var curse_lbl = Label.new()
	curse_lbl.text = p.get("curse", "")
	curse_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	curse_lbl.add_theme_font_size_override("font_size", 11)
	curse_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.75))
	vbox.add_child(curse_lbl)
	
	# Boon section
	var boon_header = Label.new()
	boon_header.text = "✨ ÂN ĐIỂN:"
	boon_header.add_theme_font_size_override("font_size", 11)
	boon_header.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	vbox.add_child(boon_header)
	
	var boon_lbl = Label.new()
	boon_lbl.text = p.get("boon", "")
	boon_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boon_lbl.add_theme_font_size_override("font_size", 11)
	boon_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.9))
	vbox.add_child(boon_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn = Button.new()
	btn.text = "KÝ KHẾ ƯỚC"
	btn.add_theme_font_size_override("font_size", 12)
	var p_id = p.get("id", "")
	btn.pressed.connect(func():
		_select_pact(p_id)
	)
	vbox.add_child(btn)
	
	panel.add_child(vbox)
	return panel

func _select_pact(pact_id: String) -> void:
	SoundManager.play("curse_pact")
	close_ui()
	emit_signal("pact_chosen", pact_id)
	if CodexManager:
		CodexManager.report_stat("pact", 1)

func open_ui() -> void:
	visible = true
	get_tree().paused = true

func close_ui() -> void:
	visible = false
	get_tree().paused = false
	emit_signal("closed")
