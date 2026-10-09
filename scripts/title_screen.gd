class_name TitleScreen
extends Control

## TitleScreen: Atmospheric cinematic main menu with Hero Showcase, Stage Badge, glowing CTA, and meta progression access.

signal start_run_pressed
signal hero_select_pressed
signal world_map_pressed
signal shop_pressed
signal leaderboard_pressed
signal codex_pressed

@onready var start_button: Button = find_child("StartButton", true, false)
@onready var start_hint: Label = find_child("StartHintLabel", true, false)
@onready var hero_name_label: Label = find_child("HeroNameLabel", true, false)
@onready var hero_desc_label: Label = find_child("HeroDescLabel", true, false)
@onready var hero_sprite: TextureRect = find_child("HeroSpritePreview", true, false)
@onready var stage_name_label: Label = find_child("StageNameLabel", true, false)
@onready var stage_desc_label: Label = find_child("StageDescLabel", true, false)
@onready var stage_icon: Label = find_child("StageIconPreview", true, false)
@onready var gold_label: Label = find_child("GoldLabel", true, false)

@onready var nav_hero_btn: Button = find_child("NavHeroBtn", true, false)
@onready var nav_map_btn: Button = find_child("NavMapBtn", true, false)
@onready var nav_shop_btn: Button = find_child("NavShopBtn", true, false)
@onready var nav_rank_btn: Button = find_child("NavRankBtn", true, false)
@onready var nav_codex_btn: Button = find_child("NavCodexBtn", true, false)
@onready var change_hero_btn: Button = find_child("ChangeHeroBtn", true, false)
@onready var change_stage_btn: Button = find_child("ChangeStageBtn", true, false)

var pulse_tween: Tween = null
var hero_bob_tween: Tween = null
var is_starting: bool = false
var self_locale_button: Button = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_nodes()
	_connect_signals()
	_apply_theme()
	_setup_cta_pulse()
	_install_locale_toggle()
	refresh_all()

## Milestone 4. Baked in code rather than into the .tscn so the scene and the
## token module can never drift -- one edit here restyles the whole screen.
func _apply_theme() -> void:
	var main_title := find_child("MainTitle", true, false) as Label
	if main_title:
		main_title.add_theme_font_override("font", UITheme.get_display_font())
		main_title.add_theme_font_size_override("font_size", 52)
		main_title.add_theme_color_override("font_color", UITheme.GOLD)
		# A dark rim keeps Cinzel's thin serifs legible over the particle backdrop.
		main_title.add_theme_color_override("font_outline_color", UITheme.INK)
		main_title.add_theme_constant_override("outline_size", 10)

	var sub_title := find_child("SubTitle", true, false) as Label
	if sub_title:
		sub_title.add_theme_color_override("font_color", UITheme.MUTED)

	for card_name in ["HeroCard", "StageCard"]:
		var card := find_child(card_name, true, false) as PanelContainer
		if card:
			card.add_theme_stylebox_override("panel", UITheme.make_card_panel())
		for header_name in ["HeroTitle", "StageTitle"]:
			var header := find_child(header_name, true, false) as Label
			if header:
				header.add_theme_font_override("font", UITheme.get_body_bold_font())
				header.add_theme_color_override("font_color", UITheme.GOLD)

	for desc_name in ["HeroDescLabel", "StageDescLabel"]:
		var desc := find_child(desc_name, true, false) as Label
		if desc:
			desc.add_theme_color_override("font_color", UITheme.MUTED)

	if start_button:
		start_button.add_theme_font_override("font", UITheme.get_body_bold_font())
		start_button.add_theme_font_size_override("font_size", 20)
		start_button.add_theme_color_override("font_color", UITheme.TEXT_ON_GOLD)
		start_button.add_theme_color_override("font_hover_color", UITheme.TEXT_ON_GOLD)
		start_button.add_theme_color_override("font_pressed_color", UITheme.TEXT_ON_GOLD)
		start_button.add_theme_stylebox_override("normal", UITheme.make_cta_button_style())
		start_button.add_theme_stylebox_override("hover",
			UITheme.make_button_style(UITheme.GOLD.lightened(0.12), UITheme.GOLD, 8))
		start_button.add_theme_stylebox_override("pressed",
			UITheme.make_button_style(UITheme.GOLD.darkened(0.18), UITheme.GOLD_DIM, 8))

	var gold_lbl := find_child("GoldLabel", true, false) as Label
	if gold_lbl:
		gold_lbl.add_theme_color_override("font_color", UITheme.GOLD)

## Milestone 3a. Pinned to the top-right corner, above everything else, so the
## language is switchable from the very first frame. The button re-labels itself
## from Loc's locale_changed signal, and a switch re-renders the hero and stage
## copy so the visible text changes immediately.
func _install_locale_toggle() -> void:
	if self_locale_button:
		return
	self_locale_button = Loc.make_toggle_button()
	self_locale_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	self_locale_button.position = Vector2(-196, 18)
	add_child(self_locale_button)
	if not Loc.locale_changed.is_connected(_on_locale_changed):
		Loc.locale_changed.connect(_on_locale_changed)

func _on_locale_changed(_new_locale: String) -> void:
	refresh_all()

func _resolve_nodes() -> void:
	if not start_button:
		start_button = find_child("StartButton", true, false)
	if not start_hint:
		start_hint = find_child("StartHintLabel", true, false)
	if not hero_name_label:
		hero_name_label = find_child("HeroNameLabel", true, false)
	if not hero_desc_label:
		hero_desc_label = find_child("HeroDescLabel", true, false)
	if not hero_sprite:
		hero_sprite = find_child("HeroSpritePreview", true, false)
	if not stage_name_label:
		stage_name_label = find_child("StageNameLabel", true, false)
	if not stage_desc_label:
		stage_desc_label = find_child("StageDescLabel", true, false)
	if not stage_icon:
		stage_icon = find_child("StageIconPreview", true, false)
	if not gold_label:
		gold_label = find_child("GoldLabel", true, false)
		
	if not nav_hero_btn:
		nav_hero_btn = find_child("NavHeroBtn", true, false)
	if not nav_map_btn:
		nav_map_btn = find_child("NavMapBtn", true, false)
	if not nav_shop_btn:
		nav_shop_btn = find_child("NavShopBtn", true, false)
	if not nav_rank_btn:
		nav_rank_btn = find_child("NavRankBtn", true, false)
	if not nav_codex_btn:
		nav_codex_btn = find_child("NavCodexBtn", true, false)
	if not change_hero_btn:
		change_hero_btn = find_child("ChangeHeroBtn", true, false)
	if not change_stage_btn:
		change_stage_btn = find_child("ChangeStageBtn", true, false)

func _connect_signals() -> void:
	if start_button and not start_button.pressed.is_connected(start_run):
		start_button.pressed.connect(start_run)
		
	if nav_hero_btn and not nav_hero_btn.pressed.is_connected(_on_hero_clicked):
		nav_hero_btn.pressed.connect(_on_hero_clicked)
	if change_hero_btn and not change_hero_btn.pressed.is_connected(_on_hero_clicked):
		change_hero_btn.pressed.connect(_on_hero_clicked)
		
	if nav_map_btn and not nav_map_btn.pressed.is_connected(_on_map_clicked):
		nav_map_btn.pressed.connect(_on_map_clicked)
	if change_stage_btn and not change_stage_btn.pressed.is_connected(_on_map_clicked):
		change_stage_btn.pressed.connect(_on_map_clicked)
		
	if nav_shop_btn and not nav_shop_btn.pressed.is_connected(_on_shop_clicked):
		nav_shop_btn.pressed.connect(_on_shop_clicked)
	if nav_rank_btn and not nav_rank_btn.pressed.is_connected(_on_rank_clicked):
		nav_rank_btn.pressed.connect(_on_rank_clicked)
	if nav_codex_btn and not nav_codex_btn.pressed.is_connected(_on_codex_clicked):
		nav_codex_btn.pressed.connect(_on_codex_clicked)
		
	if GameManager:
		if not GameManager.character_selected.is_connected(_on_character_changed):
			GameManager.character_selected.connect(_on_character_changed)
		if not GameManager.stage_selected.is_connected(_on_stage_changed):
			GameManager.stage_selected.connect(_on_stage_changed)
		if not GameManager.gold_updated.is_connected(_on_gold_changed):
			GameManager.gold_updated.connect(_on_gold_changed)

func _setup_cta_pulse() -> void:
	if not start_button:
		return
	start_button.pivot_offset = Vector2(190, 28)
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(start_button, "scale", Vector2(1.04, 1.04), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func refresh_all() -> void:
	_resolve_nodes()
	_refresh_hero()
	_refresh_stage()
	_refresh_gold()

func _refresh_hero() -> void:
	if not GameManager:
		return
	var char_data = GameManager.get_selected_character_data()
	if hero_name_label:
		hero_name_label.text = "%s - %s" % [char_data.get("name", "Sir Kaelen"), char_data.get("title", "The Royal Knight")]
	if hero_desc_label:
		hero_desc_label.text = char_data.get("description", "").split("\n")[0]
	if hero_sprite:
		var tex_path = char_data.get("texture_path", "")
		if ResourceLoader.exists(tex_path):
			hero_sprite.texture = load(tex_path)
		hero_sprite.pivot_offset = Vector2(36, 36)
		if hero_bob_tween and hero_bob_tween.is_valid():
			hero_bob_tween.kill()
		hero_bob_tween = create_tween().set_loops()
		hero_bob_tween.tween_property(hero_sprite, "scale", Vector2(1.10, 1.10), 1.1).set_trans(Tween.TRANS_SINE)
		hero_bob_tween.tween_property(hero_sprite, "scale", Vector2(1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE)

func _refresh_stage() -> void:
	if not GameManager:
		return
	var stage_data = GameManager.get_selected_stage_data()
	var s_id = stage_data.get("id", "plains")
	if stage_name_label:
		stage_name_label.text = stage_data.get("name", "Ba Lăng Huyện")
	if stage_desc_label:
		stage_desc_label.text = stage_data.get("desc", "")
	if stage_icon:
		# Thematic icons matching stage environment
		stage_icon.text = "❄" if s_id == "mount_hua" else "⛩"
		stage_icon.add_theme_color_override("font_color", stage_data.get("color", UITheme.GOLD))

func _refresh_gold() -> void:
	if gold_label and GameManager:
		gold_label.text = "Vàng Tích Lũy: %d" % GameManager.total_gold

func _on_character_changed(_char_id: String) -> void:
	_refresh_hero()

func _on_stage_changed(_stage_id: String) -> void:
	_refresh_stage()

func _on_gold_changed(_g: int) -> void:
	_refresh_gold()

func _on_hero_clicked() -> void:
	SoundManager.play_ui_click()
	emit_signal("hero_select_pressed")

func _on_map_clicked() -> void:
	SoundManager.play_ui_click()
	emit_signal("world_map_pressed")

func _on_shop_clicked() -> void:
	SoundManager.play_ui_click()
	emit_signal("shop_pressed")

func _on_rank_clicked() -> void:
	SoundManager.play_ui_click()
	emit_signal("leaderboard_pressed")

func _on_codex_clicked() -> void:
	SoundManager.play_ui_click()
	emit_signal("codex_pressed")

func open_screen() -> void:
	is_starting = false
	visible = true
	modulate.a = 1.0
	refresh_all()

func close_screen() -> void:
	visible = false

func start_run() -> void:
	if is_starting:
		return
	is_starting = true
	SoundManager.play_ui_click()
	
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		visible = false
		emit_signal("start_run_pressed")
	)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or is_starting:
		return
		
	# Check if any other modal is open
	var hud = get_parent()
	if hud:
		var char_modal = hud.get_node_or_null("CharacterSelectModal")
		var map_modal = hud.get_node_or_null("WorldMapModal")
		var rank_modal = hud.get_node_or_null("LeaderboardModal")
		var codex_modal = hud.get_node_or_null("CodexModal")
		var shop_panel = hud.get_node_or_null("ShopPanel")
		if (char_modal and char_modal.visible) or (map_modal and map_modal.visible) or \
		   (rank_modal and rank_modal.visible) or (codex_modal and codex_modal.visible) or \
		   (shop_panel and shop_panel.visible):
			return
			
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		get_viewport().set_input_as_handled()
		start_run()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_C:
				get_viewport().set_input_as_handled()
				_on_hero_clicked()
			KEY_M:
				get_viewport().set_input_as_handled()
				_on_map_clicked()
			KEY_L:
				get_viewport().set_input_as_handled()
				_on_rank_clicked()
			KEY_Q:
				get_viewport().set_input_as_handled()
				_on_codex_clicked()
