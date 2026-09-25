class_name CodexUI
extends Control

## CodexUI: Modal interface displaying the Wuxia Unlock Codex (Sổ Tay Thành Tựu & Mở Khóa Võ Lâm).

signal closed

@onready var close_btn: Button = $CenterContainer/PanelContainer/VBox/HeaderBar/CloseButton
@onready var quest_list_container: VBoxContainer = $CenterContainer/PanelContainer/VBox/Scroll/QuestListContainer
@onready var progress_label: Label = $CenterContainer/PanelContainer/VBox/HeaderBar/ProgressLabel
@onready var progress_bar: ProgressBar = $CenterContainer/PanelContainer/VBox/ProgressBar
@onready var backdrop: ColorRect = get_node_or_null("Backdrop")

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
	if CodexManager:
		CodexManager.codex_updated.connect(refresh_list)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_ui()
		get_viewport().set_input_as_handled()

func open_ui() -> void:
	visible = true
	get_tree().paused = true
	refresh_list()

func close_ui() -> void:
	visible = false
	get_tree().paused = false
	emit_signal("closed")

func refresh_list() -> void:
	if not quest_list_container or not CodexManager:
		return
		
	for child in quest_list_container.get_children():
		child.queue_free()
		
	var pct = CodexManager.get_completion_percentage()
	if progress_label:
		progress_label.text = "Tiến độ: %d / %d (%.0f%%)" % [CodexManager.unlocked_count, CodexManager.quests.size(), pct]
	if progress_bar:
		progress_bar.value = pct
		
	for q in CodexManager.quests:
		var card = _create_quest_card(q)
		quest_list_container.add_child(card)

func _create_quest_card(q: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 72)
	
	var sb = StyleBoxFlat.new()
	if q["claimed"]:
		sb.bg_color = Color(0.08, 0.12, 0.1, 0.9)
		sb.border_color = Color(0.2, 0.65, 0.35, 0.8)
	elif q["unlocked"]:
		sb.bg_color = Color(0.14, 0.12, 0.05, 0.95)
		sb.border_color = Color(1.0, 0.85, 0.25, 0.95)
	else:
		sb.bg_color = Color(0.06, 0.07, 0.1, 0.9)
		sb.border_color = Color(0.25, 0.28, 0.35, 0.7)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", sb)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	
	# Icon
	var icon_lbl = Label.new()
	icon_lbl.text = q.get("icon", "📜")
	icon_lbl.add_theme_font_size_override("font_size", 24)
	hbox.add_child(icon_lbl)
	
	# Details VBox
	var details = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 3)
	
	var title_lbl = Label.new()
	title_lbl.text = q.get("title", "")
	title_lbl.add_theme_font_size_override("font_size", 13)
	if q["unlocked"]:
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	else:
		title_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	details.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = q.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	details.add_child(desc_lbl)
	
	var reward_lbl = Label.new()
	reward_lbl.text = "🎁 Thưởng: " + q.get("reward_desc", "")
	reward_lbl.add_theme_font_size_override("font_size", 10)
	reward_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
	details.add_child(reward_lbl)
	
	hbox.add_child(details)
	
	# Progress & Action Button VBox
	var action_vbox = VBoxContainer.new()
	action_vbox.custom_minimum_size = Vector2(130, 0)
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.add_theme_constant_override("separation", 4)
	
	var prog_text = "%d / %d" % [min(q["progress"], q["target"]), q["target"]]
	if q["type"] == "time":
		prog_text = "%02d:%02d / %02d:%02d" % [int(q["progress"] / 60), int(q["progress"]) % 60, int(q["target"] / 60), int(q["target"]) % 60]
	var prog_lbl = Label.new()
	prog_lbl.text = prog_text
	prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog_lbl.add_theme_font_size_override("font_size", 10)
	prog_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	action_vbox.add_child(prog_lbl)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 30)
	btn.add_theme_font_size_override("font_size", 11)
	
	if q["claimed"]:
		btn.text = "✅ ĐÃ NHẬN"
		btn.disabled = true
	elif q["unlocked"]:
		btn.text = "🎁 NHẬN THƯỞNG"
		btn.disabled = false
		var q_id = q.get("id", "")
		btn.pressed.connect(func():
			CodexManager.claim_reward(q_id)
		)
	else:
		btn.text = "🔒 CHƯA ĐẠT"
		btn.disabled = true
	action_vbox.add_child(btn)
	
	hbox.add_child(action_vbox)
	panel.add_child(hbox)
	return panel
