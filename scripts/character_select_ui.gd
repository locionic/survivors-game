class_name CharacterSelectUI
extends Control

## CharacterSelectUI: Interactive character, stage, and equipment selector.

signal closed
signal character_selected(char_id: String)
signal stage_selected(stage_id: String)

@onready var cards_container: HBoxContainer = find_child("CardsContainer", true, false)
@onready var close_button: Button = find_child("CloseButton", true, false)
@onready var header_close_button: Button = find_child("HeaderCloseButton", true, false)
@onready var backdrop: Control = find_child("Backdrop", true, false)
@onready var title_label: Label = find_child("TitleLabel", true, false)
@onready var dialog_panel: PanelContainer = find_child("DialogPanel", true, false)

var stage_plains_btn: Button = null
var stage_hua_btn: Button = null
var gear_weapon_btn: Button = null
var gear_armor_btn: Button = null
var gear_boots_btn: Button = null

var was_paused_before_open: bool = false

## Milestone 3a — the danger picker and the language chip, both built in code so
## the .tscn stays a plain layout and neither control can drift out of sync with
## GameManager / Loc.
var _danger_row: HBoxContainer = null
var _danger_label: Label = null
var _locale_button: Button = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resolve_nodes()
	_install_danger_row()
	_install_locale_toggle()
	
	if close_button:
		close_button.pressed.connect(close_ui)
	if header_close_button:
		header_close_button.pressed.connect(close_ui)
	if backdrop:
		backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				close_ui()
		)
		
	if stage_plains_btn:
		stage_plains_btn.pressed.connect(func(): _on_stage_selected("plains"))
	if stage_hua_btn:
		stage_hua_btn.pressed.connect(func(): _on_stage_selected("mount_hua"))
		
	if gear_weapon_btn:
		gear_weapon_btn.pressed.connect(func(): _on_gear_toggled("weapon", "y_thien_kiem"))
	if gear_armor_btn:
		gear_armor_btn.pressed.connect(func(): _on_gear_toggled("armor", "nhuyen_vi_giap"))
	if gear_boots_btn:
		gear_boots_btn.pressed.connect(func(): _on_gear_toggled("boots", "van_hac_hai"))

func _resolve_nodes() -> void:
	if not cards_container:
		cards_container = find_child("CardsContainer", true, false)
	if not close_button:
		close_button = find_child("CloseButton", true, false)
	if not header_close_button:
		header_close_button = find_child("HeaderCloseButton", true, false)
	if not backdrop:
		backdrop = find_child("Backdrop", true, false)
	if not title_label:
		title_label = find_child("TitleLabel", true, false)
	if not dialog_panel:
		dialog_panel = find_child("DialogPanel", true, false)
		
	stage_plains_btn = find_child("StagePlainsBtn", true, false)
	stage_hua_btn = find_child("StageHuaBtn", true, false)
	gear_weapon_btn = find_child("GearWeaponBtn", true, false)
	gear_armor_btn = find_child("GearArmorBtn", true, false)
	gear_boots_btn = find_child("GearBootsBtn", true, false)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C):
		close_ui()
		get_viewport().set_input_as_handled()

func open_ui() -> void:
	_resolve_nodes()
	was_paused_before_open = get_tree().paused
	visible = true
	get_tree().paused = true
	render_cards()
	_refresh_danger_row()

# --- Milestone 3a: danger level + language -------------------------------------

## The danger row sits under the header so the tier is chosen in the same breath
## as the hero -- both decide how the run feels, and both are locked in before
## the first wave opens.
func _install_danger_row() -> void:
	if _danger_row or not dialog_panel:
		return
	_danger_row = HBoxContainer.new()
	_danger_row.name = "DangerRow"
	_danger_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_danger_row.add_theme_constant_override("separation", 10)
	dialog_panel.add_child(_danger_row)

	_danger_row.add_child(_mini_button("[", "danger_down"))
	_danger_label = Label.new()
	_danger_label.custom_minimum_size = Vector2(360, 0)
	_danger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_danger_row.add_child(_danger_label)
	_danger_row.add_child(_mini_button("]", "danger_up"))

	_refresh_danger_row()

## Hero card copy is localised too, so a language switch re-renders the cards
## rather than leaving a half-English roster on screen.
func _install_locale_toggle() -> void:
	if _locale_button:
		return
	_locale_button = Loc.make_toggle_button()
	_locale_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_locale_button.position = Vector2(-150, 14)
	add_child(_locale_button)
	if not Loc.locale_changed.is_connected(_on_locale_changed):
		Loc.locale_changed.connect(_on_locale_changed)

func _on_locale_changed(_new_locale: String) -> void:
	_refresh_danger_row()
	if visible:
		render_cards()

func _mini_button(text: String, action: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(34, 30)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): _on_danger_stepped(action))
	return b

func _on_danger_stepped(direction: String) -> void:
	var step := 1 if direction == "danger_up" else -1
	GameManager.set_danger_level(GameManager.danger_level + step)
	SoundManager.play("button_click", 0.5)
	_refresh_danger_row()

## Shows the tier, its two names and the exact numbers it applies -- the whole
## point of a difficulty ladder is that the player can see what they picked.
func _refresh_danger_row() -> void:
	if not _danger_label or not GameManager:
		return
	var d := GameManager.get_danger_data()
	var level := GameManager.danger_level
	_danger_label.text = "%s  [%d]  %s\n%s" % [
		GameManager.get_danger_name(), level,
		Loc.t("danger.%d.name" % level, "Novice"),
		Loc.tf("danger.desc", [int(d["hp"] * 100.0), int(d["speed"] * 100.0), float(d["score"])])
	]

func close_ui() -> void:
	if not visible:
		return
	visible = false
	if not was_paused_before_open:
		get_tree().paused = false
	emit_signal("closed")

func _update_stage_and_gear_ui() -> void:
	if not GameManager:
		return
		
	var st = GameManager.selected_stage
	if stage_plains_btn:
		stage_plains_btn.text = ("✓ " if st == "plains" else "") + "🌲 Ba Lăng Huyện"
		stage_plains_btn.modulate = Color(0.4, 1.0, 0.5) if st == "plains" else Color(0.8, 0.8, 0.8)
	if stage_hua_btn:
		stage_hua_btn.text = ("✓ " if st == "mount_hua" else "") + "❄️ Đỉnh Hoa Sơn (Bão Tuyết)"
		stage_hua_btn.modulate = Color(0.4, 0.9, 1.0) if st == "mount_hua" else Color(0.8, 0.8, 0.8)
		
	if gear_weapon_btn:
		var has_wpn = GameManager.has_equipped("y_thien_kiem")
		gear_weapon_btn.text = ("✓ " if has_wpn else "+ ") + "⚔️ Ỷ Thiên Kiếm"
		gear_weapon_btn.modulate = Color(0.3, 0.85, 1.0) if has_wpn else Color(0.7, 0.7, 0.7)
		
	if gear_armor_btn:
		var has_arm = GameManager.has_equipped("nhuyen_vi_giap")
		gear_armor_btn.text = ("✓ " if has_arm else "+ ") + "🛡️ Nhuyễn Vị Giáp"
		gear_armor_btn.modulate = Color(1.0, 0.8, 0.25) if has_arm else Color(0.7, 0.7, 0.7)
		
	if gear_boots_btn:
		var has_bts = GameManager.has_equipped("van_hac_hai")
		gear_boots_btn.text = ("✓ " if has_bts else "+ ") + "🥾 Vân Hạc Hài"
		gear_boots_btn.modulate = Color(0.4, 0.95, 0.6) if has_bts else Color(0.7, 0.7, 0.7)

func _on_stage_selected(stage_id: String) -> void:
	if not GameManager:
		return
	GameManager.select_stage(stage_id)
	SoundManager.play("button_click")
	
	var bg = get_tree().current_scene.get_node_or_null("Background")
	if bg:
		var st_data = GameManager.get_selected_stage_data()
		var tex_path = st_data.get("texture_path", "")
		if ResourceLoader.exists(tex_path):
			bg.texture = load(tex_path)
			
	emit_signal("stage_selected", stage_id)
	_update_stage_and_gear_ui()

func _on_gear_toggled(slot: String, gear_id: String) -> void:
	if not GameManager:
		return
	if GameManager.equipment_slots.get(slot, "") == gear_id:
		GameManager.equip_gear(slot, "")
	else:
		GameManager.equip_gear(slot, gear_id)
	SoundManager.play("powerup", 0.15)
	_update_stage_and_gear_ui()

func render_cards() -> void:
	_resolve_nodes()
	_update_stage_and_gear_ui()
	if not cards_container:
		return
		
	for child in cards_container.get_children():
		child.queue_free()
		
	var active_id = GameManager.selected_character if GameManager else "knight"
	var characters = GameManager.CHARACTERS.values() if GameManager else []
	
	for char_data in characters:
		var char_id: String = char_data["id"]
		var is_current: bool = (char_id == active_id)
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(235, 360)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Style card
		var card_sb = StyleBoxFlat.new()
		if is_current:
			card_sb.bg_color = Color(0.12, 0.20, 0.32, 0.95)
			card_sb.border_color = Color(0.0, 0.85, 1.0, 1.0)
			card_sb.set_border_width_all(3)
		else:
			card_sb.bg_color = Color(0.08, 0.10, 0.15, 0.92)
			card_sb.border_color = Color(0.25, 0.30, 0.40, 0.8)
			card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(8)
		card_sb.set_content_margin_all(12)
		card.add_theme_stylebox_override("panel", card_sb)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)
		
		# Portrait container
		var portrait_ctr = CenterContainer.new()
		portrait_ctr.custom_minimum_size = Vector2(0, 68)
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(64, 64)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var tex_path = char_data.get("texture_path", "")
		if ResourceLoader.exists(tex_path):
			tex_rect.texture = load(tex_path)
		portrait_ctr.add_child(tex_rect)
		vbox.add_child(portrait_ctr)
		
		# Name & Title -- routed through Loc so the roster follows the language.
		var name_lbl = Label.new()
		name_lbl.text = Loc.t("char.%s.name" % char_id, char_data["name"])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 17)
		if is_current:
			name_lbl.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
		vbox.add_child(name_lbl)

		var title_lbl = Label.new()
		title_lbl.text = Loc.t("char.%s.title" % char_id, char_data["title"])
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.8))
		title_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(title_lbl)
		
		# Separator
		var sep = HSeparator.new()
		vbox.add_child(sep)
		
		# Description / Passives
		var desc_lbl = Label.new()
		desc_lbl.text = char_data["description"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.9))
		vbox.add_child(desc_lbl)
		
		# Action Button
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		if is_current:
			btn.text = "✓ " + Loc.t("ui.active_hero", "ACTIVE HERO")
			btn.disabled = true
		else:
			btn.text = Loc.t("ui.select_hero", "Select Hero")
			btn.pressed.connect(func():
				_on_hero_selected(char_id)
			)
		vbox.add_child(btn)
		
		cards_container.add_child(card)

func _on_hero_selected(char_id: String) -> void:
	if GameManager:
		GameManager.select_character(char_id)
		
	SoundManager.play("powerup", 0.2)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("apply_character_data"):
			player.apply_character_data()
		if player.has_method("refresh_meta_stats"):
			player.refresh_meta_stats()
			
	emit_signal("character_selected", char_id)
	render_cards()
