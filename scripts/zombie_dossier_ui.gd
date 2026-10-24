class_name ZombieDossierUI
extends Control

## ZombieDossierUI: Tactical Outbreak Dossier showcasing Flow Agent generated
## survivor operatives, mutated bio-bosses, and military supply caches.

signal closed

@onready var close_btn: Button = find_child("CloseButton", true, false)
@onready var tab_survivors_btn: Button = find_child("TabSurvivorsBtn", true, false)
@onready var tab_monsters_btn: Button = find_child("TabMonstersBtn", true, false)
@onready var tab_airdrop_btn: Button = find_child("TabAirdropBtn", true, false)
@onready var content_container: MarginContainer = find_child("ContentContainer", true, false)
@onready var backdrop: Control = find_child("Backdrop", true, false)

var current_tab: String = "survivors"
var selected_survivor_idx: int = 0
var was_paused_before_open: bool = false

const SURVIVORS: Array[Dictionary] = [
	{
		"id": "swat",
		"name": "Corporal Miller (SWAT Lead Operator)",
		"title": "Chỉ Huy Biệt Đội Tác Chiến Phản Ứng Nhanh",
		"role": "Tank / Ballistics Vanguard",
		"art": "res://assets/promo/swat_survivor_art.png",
		"stats": "HP: 130 | Giáp: 3 | Sát thương súng: +15% | Tốc độ: +5%",
		"skill": "🛡️ Tuyệt kỹ: Lăn Tác Chiến Flashbang (SPACE) — Né đòn 0.9s và làm choáng diện rộng",
		"lore": "Từng là trung sĩ trưởng đội SWAT Metro, Miller chỉ huy các tuyến phòng thủ cuối cùng trước khi phòng tuyến đô thị sụp đổ. Được trang bị áo giáp chống đạn cấp IV và súng lục chiến thuật 9mm tinh chỉnh."
	},
	{
		"id": "medic",
		"name": "Dr. Evelyn Hayes (Field Medic)",
		"title": "Bác Sĩ Quân Y Dã Chiến Kháng Virus",
		"role": "Support / Bio-Regeneration",
		"art": "res://assets/promo/medic_art.png",
		"stats": "HP: 115 | Giáp: 1 | Tốc độ: +10% | Thu hoạch ống nghiệm: +25%",
		"skill": "💉 Tuyệt kỹ: Sóng Khử Khuẩn Sinh Học (SPACE) — Hồi 35 HP và làm chậm toàn bộ thây ma 60%",
		"lore": "Nhà dịch tễ học hàng đầu thuộc Viện Nghiên Cứu Đột Biến Gen. Sử dụng thiết bị máy chiếu xung điện sinh học và súng tiêm kháng thể để giải cứu các thành viên còn sống sót."
	},
	{
		"id": "pyro_z",
		"name": "Blaze (Demolitionist)",
		"title": "Chuyên Gia Hỏa Lực Hạng Nặng & Phá Dỡ",
		"role": "Area Denial / Burn Heavy",
		"art": "res://assets/promo/pyro_art.png",
		"stats": "HP: 110 | Giáp: 0 | Hỏa lực diện rộng: +55% | Bỏng kéo dài",
		"skill": "🔥 Tuyệt kỹ: Bộc Phá Napalm (SPACE) — Kích nổ bình xăng thiêu rụi toàn bộ thây ma 260px",
		"lore": "Thợ hàn công nghiệp chuyển sang chế tạo bom xăng tự chế và súng phun lửa áp lực cao. Không có ổ dịch nào mà vài trăm lít napalm cháy âm ỉ không thể thanh tẩy."
	},
	{
		"id": "scout",
		"name": "Ghost (Wasteland Scout)",
		"title": "Trinh Sát Cơ Động Vùng Đất Chết",
		"role": "High Speed / Dual SMG Flanker",
		"art": "res://assets/promo/scout_art.png",
		"stats": "HP: 100 | Giáp: 0 | Tốc độ chạy: +30% | Tốc độ bắn: +35%",
		"skill": "⚡ Tuyệt kỹ: Tiêm Adrenaline Khẩn Cấp (SPACE) — Tăng +50% tốc độ và gấp đôi tốc độ xả đạn",
		"lore": "Tay trinh sát bí ẩn hoạt động đơn độc trong khu cách ly. Lướt qua các ngõ hẻm đen tối với cặp tiểu liên họng giảm thanh, dọn dẹp các ổ thây ma mai phục trước khi đội quân chính đến."
	},
	{
		"id": "biker",
		"name": "Axel (Outlaw Brawler)",
		"title": "Quái Xế Cận Chiến Búa Tạ",
		"role": "Melee Berserker / Crowd Splatter",
		"art": "res://assets/promo/biker_art.png",
		"stats": "HP: 140 | Giáp: 2 | Sát thương đập: +35% | Hút máu cận chiến",
		"skill": "🪓 Tuyệt kỹ: Cuồng Nộ Búa Tạ (SPACE) — Đập búa xoay 360 độ hất văng mọi thây ma và hồi 20 HP",
		"lore": "Cựu thủ lĩnh băng mô tô đường phố. Khi đại dịch biến cả thành phố thành địa ngục, Axel gia cố chiếc búa tạ công trình và lưỡi rìu dã chiến để đập tan sọ bất kỳ kẻ nhiễm bệnh nào ngáng đường."
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if close_btn:
		close_btn.pressed.connect(close_ui)
	if tab_survivors_btn:
		tab_survivors_btn.pressed.connect(func(): _switch_tab("survivors"))
	if tab_monsters_btn:
		tab_monsters_btn.pressed.connect(func(): _switch_tab("monsters"))
	if tab_airdrop_btn:
		tab_airdrop_btn.pressed.connect(func(): _switch_tab("airdrop"))
	if backdrop:
		backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				close_ui()
		)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_ui()
		get_viewport().set_input_as_handled()

func open_ui(initial_tab: String = "survivors") -> void:
	was_paused_before_open = get_tree().paused
	get_tree().paused = true
	visible = true
	_switch_tab(initial_tab)

func close_ui() -> void:
	if not visible:
		return
	visible = false
	if not was_paused_before_open:
		get_tree().paused = false
	emit_signal("closed")

func _switch_tab(tab_name: String) -> void:
	current_tab = tab_name
	SoundManager.play("ui_click", 0.3)
	
	if tab_survivors_btn:
		tab_survivors_btn.modulate = Color(0.2, 1.0, 0.5) if tab_name == "survivors" else Color(0.7, 0.7, 0.7)
	if tab_monsters_btn:
		tab_monsters_btn.modulate = Color(1.0, 0.3, 0.3) if tab_name == "monsters" else Color(0.7, 0.7, 0.7)
	if tab_airdrop_btn:
		tab_airdrop_btn.modulate = Color(1.0, 0.85, 0.2) if tab_name == "airdrop" else Color(0.7, 0.7, 0.7)

	if not content_container:
		return
	for c in content_container.get_children():
		c.queue_free()

	match tab_name:
		"survivors":
			_render_survivors_tab()
		"monsters":
			_render_monsters_tab()
		"airdrop":
			_render_airdrop_tab()

func _render_survivors_tab() -> void:
	var root_hbox = HBoxContainer.new()
	root_hbox.add_theme_constant_override("separation", 16)
	content_container.add_child(root_hbox)

	# Left survivor list selector
	var left_scroll = ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(250, 420)
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(left_vbox)
	root_hbox.add_child(left_scroll)

	for i in range(SURVIVORS.size()):
		var s = SURVIVORS[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 52)
		btn.text = "%s\n%s" % [s["name"], s["role"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if i == selected_survivor_idx:
			btn.modulate = Color(0.2, 1.0, 0.6)
		btn.pressed.connect(func():
			selected_survivor_idx = i
			_render_survivors_tab()
		)
		left_vbox.add_child(btn)

	# Right hero detail panel
	var s_data = SURVIVORS[selected_survivor_idx]
	var detail_hbox = HBoxContainer.new()
	detail_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_hbox.add_theme_constant_override("separation", 18)
	root_hbox.add_child(detail_hbox)

	# Art TextureRect
	var art_frame = PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(300, 360)
	var art_sb = StyleBoxFlat.new()
	art_sb.bg_color = Color(0.04, 0.06, 0.08, 0.95)
	art_sb.border_color = Color(0.2, 0.8, 0.5, 0.8)
	art_sb.set_border_width_all(2)
	art_sb.set_corner_radius_all(8)
	art_frame.add_theme_stylebox_override("panel", art_sb)

	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(280, 340)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists(s_data["art"]):
		tex_rect.texture = load(s_data["art"])
	art_frame.add_child(tex_rect)
	detail_hbox.add_child(art_frame)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 8)
	detail_hbox.add_child(info_vbox)

	var name_lbl = Label.new()
	name_lbl.text = s_data["name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	info_vbox.add_child(name_lbl)

	var title_lbl = Label.new()
	title_lbl.text = s_data["title"]
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.85))
	info_vbox.add_child(title_lbl)

	info_vbox.add_child(HSeparator.new())

	var stats_lbl = Label.new()
	stats_lbl.text = "📊 CHỈ SỐ: " + s_data["stats"]
	stats_lbl.add_theme_font_size_override("font_size", 12)
	stats_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	info_vbox.add_child(stats_lbl)

	var skill_lbl = Label.new()
	skill_lbl.text = s_data["skill"]
	skill_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_lbl.add_theme_font_size_override("font_size", 12)
	skill_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	info_vbox.add_child(skill_lbl)

	info_vbox.add_child(HSeparator.new())

	var lore_lbl = Label.new()
	lore_lbl.text = s_data["lore"]
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lore_lbl.add_theme_font_size_override("font_size", 11)
	lore_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	info_vbox.add_child(lore_lbl)

	var deploy_btn = Button.new()
	deploy_btn.custom_minimum_size = Vector2(0, 42)
	deploy_btn.text = "☣️ TRIỂN KHAI VÀO KHU CÁCH LY NÀY (DEPLOY)"
	deploy_btn.modulate = Color(0.2, 1.0, 0.5)
	deploy_btn.pressed.connect(func():
		if GameManager:
			GameManager.select_stage("zombie_city")
			GameManager.select_character(s_data["id"])
		SoundManager.play("powerup", 0.3)
		close_ui()
	)
	info_vbox.add_child(deploy_btn)

func _render_monsters_tab() -> void:
	var root_hbox = HBoxContainer.new()
	root_hbox.add_theme_constant_override("separation", 18)
	content_container.add_child(root_hbox)

	# Card 1: Bio-Titan
	var titan_card = _create_monster_card(
		"BIO-TITAN APEX ABOMINATION",
		"Trùm Cuối Biến Dị — Thảm Họa Sinh Học Cấp 5",
		"res://assets/promo/mutant_boss_art.png",
		"Máu: 8000+ | Sát thương: 45 | Kháng đẩy lùi: 95%",
		"⚠️ Kỹ Năng Đột Biến:\n- Chấn Động Tàn Phá: Dộng mặt đất gây rung chấn 180px\n- Càn Quét Xung Kích: Húc thẳng nghiền nát mọi chướng ngại\n- Phóng Hóa Chất Ăn Mòn: Bắn chùm acid phóng xạ 360 độ",
		Color(1.0, 0.25, 0.25)
	)
	root_hbox.add_child(titan_card)

	# Card 2: Toxic Spitter
	var spitter_card = _create_monster_card(
		"TOXIC SPITTER MUTANT",
		"Quái Vật Biến Dị Bắn Tỉa Axit Tầm Xa",
		"res://assets/promo/toxic_spitter_art.png",
		"Máu: 450 | Tốc độ: 80 | Tầm bắn: 500px",
		"⚠️ Cơ Chế Tác Chiến:\n- Luôn giữ cự ly cách xa người chơi\n- Bắn liên tục bọc dịch nhầy độc tính cao làm chậm và đốt máu\n- Khi chết phát nổ thành vũng lầy ăn mòn",
		Color(0.25, 1.0, 0.4)
	)
	root_hbox.add_child(spitter_card)

func _create_monster_card(m_name: String, m_title: String, m_art: String, m_stats: String, m_desc: String, col: Color) -> Control:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.94)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var img_ctr = CenterContainer.new()
	img_ctr.custom_minimum_size = Vector2(0, 180)
	var tex = TextureRect.new()
	tex.custom_minimum_size = Vector2(170, 170)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists(m_art):
		tex.texture = load(m_art)
	img_ctr.add_child(tex)
	vbox.add_child(img_ctr)

	var name_lbl = Label.new()
	name_lbl.text = m_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", col)
	vbox.add_child(name_lbl)

	var title_lbl = Label.new()
	title_lbl.text = m_title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 10)
	title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	vbox.add_child(title_lbl)

	vbox.add_child(HSeparator.new())

	var stats_lbl = Label.new()
	stats_lbl.text = m_stats
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 11)
	stats_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vbox.add_child(stats_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = m_desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	vbox.add_child(desc_lbl)

	return panel

func _render_airdrop_tab() -> void:
	var root_hbox = HBoxContainer.new()
	root_hbox.add_theme_constant_override("separation", 20)
	content_container.add_child(root_hbox)

	var art_frame = PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(320, 360)
	var art_sb = StyleBoxFlat.new()
	art_sb.bg_color = Color(0.04, 0.06, 0.08, 0.95)
	art_sb.border_color = Color(1.0, 0.8, 0.2, 0.8)
	art_sb.set_border_width_all(2)
	art_sb.set_corner_radius_all(8)
	art_frame.add_theme_stylebox_override("panel", art_sb)

	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(300, 340)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists("res://assets/promo/airdrop_crate_art.png"):
		tex_rect.texture = load("res://assets/promo/airdrop_crate_art.png")
	art_frame.add_child(tex_rect)
	root_hbox.add_child(art_frame)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 10)
	root_hbox.add_child(info_vbox)

	var title_lbl = Label.new()
	title_lbl.text = "📦 HÒM TIẾP TẾ QUÂN SỰ KHẨN CẤP (AIRDROP CACHE)"
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	info_vbox.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Hàng viện trợ chiến thuật thả bằng dù từ trực thăng vận tải dã chiến"
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	info_vbox.add_child(sub_lbl)

	info_vbox.add_child(HSeparator.new())

	var body_lbl = Label.new()
	body_lbl.text = "Định kỳ trong trận chiến sinh tồn tại Khu Cách Ly, máy bay vận tải dã chiến sẽ thả các hòm tiếp tế quân sự gia cố xuống ngẫu nhiên trên bản đồ.\n\n" + \
		"🎁 NỘI DUNG TIẾP TẾ:\n" + \
		"1. Hộp Đạn Hạng Nặng: Nâng cấp tức thì 1 cấp độ cho toàn bộ vũ khí hỏa lực\n" + \
		"2. Serum Kháng Sinh Miễn Dịch: Hồi phục 100% Máu và xóa bỏ mọi hiệu ứng nhiễm độc acid\n" + \
		"3. Pháo Điện Từ Nam Châm: Thu hút toàn bộ ống nghiệm sinh học trên toàn bộ bản đồ\n" + \
		"4. Tên Lửa Chiến Thuật Tận Diệt (Nuke): Quét sạch toàn bộ đàn thây ma đang bao vây!"
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_lbl.add_theme_font_size_override("font_size", 11)
	body_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	info_vbox.add_child(body_lbl)
