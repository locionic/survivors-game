class_name HUD
extends CanvasLayer

## HUD controller displaying health, experience, run timer, live gold, boss health bars, pause menu, monetized Game Over, Meta Shop, and audio controls.

# TopBar elements
@onready var wave_label: Label = get_node_or_null("GameUI/TopBar/WaveLabel")
@onready var level_badge: Label = $GameUI/TopBar/LevelBadge
@onready var hp_bar: ProgressBar = $GameUI/TopBar/HPContainer/HPBar
@onready var hp_label: Label = $GameUI/TopBar/HPContainer/HPLabel
@onready var xp_bar: ProgressBar = $GameUI/TopBar/XPContainer/XPBar
@onready var xp_label: Label = $GameUI/TopBar/XPContainer/XPLabel
@onready var timer_label: Label = $GameUI/TopBar/TimerLabel
@onready var gold_label: Label = $GameUI/TopBar/GoldLabel
@onready var kills_label: Label = $GameUI/TopBar/KillsLabel
@onready var audio_button: Button = $GameUI/TopBar/AudioButton
# Milestone 4: the combat TopBar is decluttered. Map / Hero / Leaderboard / Codex
# are reached from the PausePanel now, so `pause_*_button` is the only handle for
# each. Map previously had no pause entry point, hence PauseMapButton.
@onready var pause_button: Button = $GameUI/TopBar/PauseButton
@onready var minimap: Minimap = get_node_or_null("GameUI/Minimap")
@onready var world_map_modal: WorldMapUI = get_node_or_null("WorldMapModal")
@onready var char_select_modal: CharacterSelectUI = get_node_or_null("CharacterSelectModal")
@onready var pause_map_button: Button = get_node_or_null("PausePanel/VBox/PauseMapButton")
@onready var pause_hero_button: Button = get_node_or_null("PausePanel/VBox/PauseHeroButton")
@onready var game_over_hero_button: Button = get_node_or_null("GameOverPanel/VBox/GameOverHeroButton")
@onready var leaderboard_modal: Control = get_node_or_null("LeaderboardModal")
@onready var pause_leaderboard_button: Button = get_node_or_null("PausePanel/VBox/PauseLeaderboardButton")
@onready var game_over_leaderboard_button: Button = get_node_or_null("GameOverPanel/VBox/GameOverLeaderboardButton")
@onready var codex_modal: Control = get_node_or_null("CodexModal")
@onready var pause_codex_button: Button = get_node_or_null("PausePanel/VBox/PauseCodexButton")
@onready var game_over_codex_button: Button = get_node_or_null("GameOverPanel/VBox/GameOverCodexButton")
@onready var altar_modal: Control = get_node_or_null("AltarModal")
@onready var hermit_modal: Control = get_node_or_null("HermitShopModal")

var char_select_opened_from: String = ""
var leaderboard_opened_from: String = ""
var codex_opened_from: String = ""
var current_active_altar: Node2D = null
var current_active_hermit: Node2D = null
var codex_toast_banner: PanelContainer = null
var last_streak_announced: int = 0
var skill_widget: Control = null
var skill_button: Button = null
var skill_cd_label: Label = null
var blood_moon_overlay: ColorRect = null
var blizzard_overlay: ColorRect = null
var blizzard_timer: float = 0.0
var blizzard_active_timer: float = 0.0
var dragon_widget: Control = null
var dragon_button: Button = null

var dragon_bar: ProgressBar = null
var is_dragon_active_ui: bool = false
var pearl_tray: HBoxContainer = null
var pearl_labels: Array[Label] = []
var shenron_modal: PanelContainer = null
var shenron_cards_container: HBoxContainer = null
var danger_vignette: ColorRect = null
var ftue_banner: PanelContainer = null
var celestial_flash: ColorRect = null

# Expansion 21.0: Bảo Rương Kim Quy modal + Chiến Tích Bảng report labels
var chest_modal: PanelContainer = null
var chest_modal_title: Label = null
var chest_modal_list: VBoxContainer = null
var milestone_banner: PanelContainer = null
var dps_labels: Dictionary = {}

# Arsenal Bar
@onready var arsenal_bar: HBoxContainer = $GameUI/ArsenalBar
@onready var dagger_badge: Label = $GameUI/ArsenalBar/DaggerBadge
@onready var shield_badge: Label = $GameUI/ArsenalBar/ShieldBadge
@onready var thunder_badge: Label = $GameUI/ArsenalBar/ThunderBadge
@onready var fireball_badge: Label = $GameUI/ArsenalBar/FireballBadge
@onready var axe_badge: Label = $GameUI/ArsenalBar/AxeBadge
@onready var passives_label: Label = $GameUI/ArsenalBar/PassivesLabel

# Event Banner & Controls
@onready var warning_banner: Label = $GameUI/WarningBanner
@onready var virtual_joystick: Control = $GameUI/VirtualJoystick

# Boss Bar
@onready var boss_bar_container: VBoxContainer = $GameUI/BossBarContainer
@onready var boss_name_label: Label = $GameUI/BossBarContainer/BossNameLabel
@onready var boss_hp_bar: ProgressBar = $GameUI/BossBarContainer/BossHPContainer/BossHPBar
@onready var boss_hp_text: Label = $GameUI/BossBarContainer/BossHPContainer/BossHPText

# Pause Panel
@onready var pause_panel: PanelContainer = $PausePanel
@onready var pause_stats_label: Label = $PausePanel/VBox/StatsLabel
@onready var pause_arsenal_label: Label = $PausePanel/VBox/ArsenalLabel
@onready var resume_button: Button = $PausePanel/VBox/ResumeButton
@onready var restart_run_button: Button = $PausePanel/VBox/RestartRunButton
@onready var pause_title_button: Button = get_node_or_null("PausePanel/VBox/PauseTitleButton")
@onready var pause_close_header_button: Button = get_node_or_null("PausePanel/VBox/HeaderBar/PauseCloseHeaderButton")

# Game Over / Revive screen
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var final_stats_label: Label = $GameOverPanel/VBox/StatsLabel
@onready var revive_button: Button = $GameOverPanel/VBox/ReviveButton
@onready var double_gold_button: Button = $GameOverPanel/VBox/DoubleGoldButton
@onready var shop_button: Button = $GameOverPanel/VBox/ShopButton
@onready var game_over_title_button: Button = get_node_or_null("GameOverPanel/VBox/GameOverTitleButton")
@onready var restart_button: Button = $GameOverPanel/VBox/RestartButton

# Victory Panel
@onready var victory_panel: PanelContainer = get_node_or_null("VictoryPanel")
@onready var victory_title_label: Label = get_node_or_null("VictoryPanel/VBox/TitleAwardLabel")
@onready var victory_stats_label: Label = get_node_or_null("VictoryPanel/VBox/StatsLabel")
@onready var victory_endless_button: Button = get_node_or_null("VictoryPanel/VBox/EndlessButton")
@onready var victory_title_button: Button = get_node_or_null("VictoryPanel/VBox/VictoryTitleButton")
@onready var victory_leaderboard_button: Button = get_node_or_null("VictoryPanel/VBox/VictoryLeaderboardButton")

# Meta Shop Panel
@onready var shop_backdrop: ColorRect = get_node_or_null("ShopBackdrop")
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var shop_gold_label: Label = find_child("ShopGoldLabel", true, false)
@onready var shop_items_container: VBoxContainer = find_child("ItemsContainer", true, false)
@onready var close_shop_button: Button = find_child("CloseShopButton", true, false)
@onready var pause_shop_button: Button = get_node_or_null("PausePanel/VBox/PauseShopButton")
@onready var shop_close_header_button: Button = find_child("ShopCloseHeaderButton", true, false)

@onready var title_screen: Control = get_node_or_null("TitleScreen")
var cinematic_vignette: TextureRect = null
var ambient_weather: CPUParticles2D = null
var shop_opened_from_pause: bool = false
var pause_locale_button: Button = null
var shop_opened_from_title: bool = false
var world_map_opened_from: String = ""
var player: Node2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	game_over_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if shop_backdrop:
		shop_backdrop.visible = false
		shop_backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_close_shop()
		)
	if shop_panel:
		shop_panel.visible = false
	if boss_bar_container:
		boss_bar_container.visible = false
	if pause_panel:
		pause_panel.visible = false
	if warning_banner:
		warning_banner.visible = false
		
	if GameManager and not GameManager.victory_achieved.is_connected(_on_victory_achieved):
		GameManager.victory_achieved.connect(_on_victory_achieved)
	if GameManager and not GameManager.kill_milestone_reached.is_connected(_on_kill_milestone_reached):
		GameManager.kill_milestone_reached.connect(_on_kill_milestone_reached)
		
	_setup_ui_styles()
	_setup_hero_skill_widget()
	_setup_dragon_awakening_widget()
	_setup_dragon_pearl_tray()
	_setup_shenron_modal()
	_setup_chest_modal()
	_setup_danger_vignette()
	_setup_cinematic_vignette()
	_setup_ambient_weather()
	_setup_celestial_flash()
	_setup_ftue_banner()
	_setup_title_screen()
	
	player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("health_changed"):
			player.connect("health_changed", Callable(self, "_on_player_health_changed"))
		if player.has_signal("xp_changed"):
			player.connect("xp_changed", Callable(self, "_on_player_xp_changed"))
		if player.has_signal("died"):
			player.connect("died", Callable(self, "_on_player_died"))
		if player.has_signal("skill_used"):
			player.connect("skill_used", Callable(self, "_on_player_skill_used"))
		if player.has_signal("skill_cooldown_progress"):
			player.connect("skill_cooldown_progress", Callable(self, "_on_player_skill_cd_progress"))
		if player.has_signal("skill_ready"):
			player.connect("skill_ready", Callable(self, "_on_player_skill_ready"))
		if player.has_signal("dragon_soul_changed"):
			player.connect("dragon_soul_changed", Callable(self, "_on_player_dragon_soul_changed"))
		if player.has_signal("dragon_awakened"):
			player.connect("dragon_awakened", Callable(self, "_on_player_dragon_awakened"))
		if player.has_signal("dragon_ended"):
			player.connect("dragon_ended", Callable(self, "_on_player_dragon_ended"))
		if player.has_signal("qi_shield_changed"):
			player.connect("qi_shield_changed", Callable(self, "_on_player_qi_shield_changed"))
		
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.gold_updated.connect(_on_gold_updated)
	GameManager.relic_collected.connect(func(_id, _data): _update_passives_display())
	GameManager.scroll_collected.connect(func(_id): _update_passives_display())
	GameManager.equipment_updated.connect(func(_slot, _id): _update_passives_display())
	GameManager.stage_selected.connect(func(_id): 
		_update_passives_display()
		_update_ambient_weather()
	)
	GameManager.blood_moon_started.connect(_on_blood_moon_started)
	GameManager.blood_moon_ended.connect(_on_blood_moon_ended)
	GameManager.bounty_completed.connect(func(bounty):
		var title = bounty.get("title", "Bounty")
		var gold = bounty.get("reward_gold", 50)
		_on_wave_event_announced("🎯 BOUNTY COMPLETE: %s (+%d Gold)!" % [title, gold], false)
	)
	
	var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_mgr and upgrade_mgr.has_signal("arsenal_updated"):
		upgrade_mgr.connect("arsenal_updated", Callable(self, "_on_arsenal_updated"))
			
	var spawner = get_tree().root.find_child("EnemySpawner", true, false)
	if spawner and spawner.has_signal("wave_event_announced"):
		spawner.connect("wave_event_announced", Callable(self, "_on_wave_event_announced"))

	# Võ Đài wave counter. Absent in scenes without a WaveDirector, so the label
	# simply stays at its authored default.
	var wave_dir = get_tree().get_first_node_in_group("wave_director")
	if wave_dir:
		wave_dir.connect("wave_started", Callable(self, "_on_wave_started"))
		wave_dir.connect("wave_timer_updated", Callable(self, "_on_wave_timer_updated"))
		wave_dir.connect("wave_completed", Callable(self, "_on_wave_completed"))

	revive_button.pressed.connect(_on_revive_pressed)
	double_gold_button.pressed.connect(_on_double_gold_pressed)
	if shop_button:
		shop_button.pressed.connect(func(): _open_shop(false))
	if pause_shop_button:
		pause_shop_button.pressed.connect(func(): _open_shop(true))
	if close_shop_button:
		close_shop_button.pressed.connect(_close_shop)
	if shop_close_header_button:
		shop_close_header_button.pressed.connect(_close_shop)
	restart_button.pressed.connect(_on_restart_pressed)
	
	if audio_button:
		audio_button.pressed.connect(_on_audio_toggle)
	if pause_map_button:
		pause_map_button.pressed.connect(func(): open_world_map("pause"))
	if pause_hero_button:
		pause_hero_button.pressed.connect(func(): open_character_select("pause"))
	if game_over_hero_button:
		game_over_hero_button.pressed.connect(func(): open_character_select("game_over"))
	if char_select_modal:
		char_select_modal.closed.connect(_on_char_select_closed)
		char_select_modal.character_selected.connect(func(_c):
			_update_passives_display()
		)
	if pause_leaderboard_button:
		pause_leaderboard_button.pressed.connect(func(): open_leaderboard("pause"))
	if game_over_leaderboard_button:
		game_over_leaderboard_button.pressed.connect(func(): open_leaderboard("game_over"))
	if leaderboard_modal:
		leaderboard_modal.closed.connect(_on_leaderboard_closed)
	if pause_codex_button:
		pause_codex_button.pressed.connect(func(): open_codex("pause"))
	if game_over_codex_button:
		game_over_codex_button.pressed.connect(func(): open_codex("game_over"))
	if codex_modal:
		codex_modal.closed.connect(_on_codex_closed)
	if altar_modal:
		altar_modal.pact_chosen.connect(_on_pact_chosen)
	if hermit_modal:
		hermit_modal.item_purchased.connect(_on_hermit_item_purchased)
		hermit_modal.closed.connect(_on_hermit_closed)

	if minimap:
		minimap.open_map_requested.connect(open_world_map)
	if world_map_modal and not world_map_modal.closed.is_connected(_on_world_map_closed):
		world_map_modal.closed.connect(_on_world_map_closed)
	if pause_button:
		pause_button.pressed.connect(toggle_pause)
	_install_pause_locale_toggle()
	if resume_button:
		resume_button.pressed.connect(close_pause_menu)
	if pause_close_header_button:
		pause_close_header_button.pressed.connect(close_pause_menu)
	if pause_title_button:
		pause_title_button.pressed.connect(return_to_title_screen)
	if game_over_title_button:
		game_over_title_button.pressed.connect(return_to_title_screen)
	if restart_run_button:
		restart_run_button.pressed.connect(_on_restart_pressed)
	if victory_endless_button:
		victory_endless_button.pressed.connect(_on_victory_endless_pressed)
	if victory_title_button:
		victory_title_button.pressed.connect(return_to_title_screen)
	if victory_leaderboard_button:
		victory_leaderboard_button.pressed.connect(func(): open_leaderboard("victory"))
		
	# Initial gold & level display
	_on_gold_updated(GameManager.total_gold)
	_update_passives_display()

## Milestone 3a: the language chip lives in the pause VBox rather than being
## positioned, so it lands in the same column as Resume / Restart and stays
## reachable with a stick (every sibling is focusable, this one is deliberately
## not -- ui_accept reaches Resume first).
func _install_pause_locale_toggle() -> void:
	if pause_locale_button:
		return
	var vbox = get_node_or_null("PausePanel/VBox")
	if not vbox:
		return
	pause_locale_button = Loc.make_toggle_button()
	vbox.add_child(pause_locale_button)

func _unhandled_input(event: InputEvent) -> void:
	# Expansion 21.0: the jackpot ceremony is modal — ENTER/SPACE dismisses it first.
	if chest_modal and chest_modal.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_close_chest_modal()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			toggle_world_map()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_C:
			toggle_character_select()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_L:
			toggle_leaderboard()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_Q:
			toggle_codex()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P):
		if shenron_modal and shenron_modal.visible:
			_close_shenron_modal()
			get_viewport().set_input_as_handled()
			return
		# Prioritized hierarchical closing: topmost open modal closes first
		if codex_modal and codex_modal.visible:
			codex_modal.close_ui()
			get_viewport().set_input_as_handled()
		elif hermit_modal and hermit_modal.visible:
			hermit_modal.close_ui()
			get_viewport().set_input_as_handled()
		elif altar_modal and altar_modal.visible:
			altar_modal.close_ui()
			get_viewport().set_input_as_handled()

		elif leaderboard_modal and leaderboard_modal.visible:
			leaderboard_modal.close_ui()
			get_viewport().set_input_as_handled()
		elif char_select_modal and char_select_modal.visible:
			char_select_modal.close_ui()
			get_viewport().set_input_as_handled()
		elif world_map_modal and world_map_modal.visible:
			world_map_modal.close_map()
			get_viewport().set_input_as_handled()
		elif shop_panel and shop_panel.visible:
			_close_shop()
			get_viewport().set_input_as_handled()
		elif pause_panel and pause_panel.visible:
			close_pause_menu()
			get_viewport().set_input_as_handled()
		elif not game_over_panel.visible:
			var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
			if not (upgrade_mgr and upgrade_mgr.panel and upgrade_mgr.panel.visible):
				open_pause_menu()
				get_viewport().set_input_as_handled()

func open_character_select(source: String = "topbar") -> void:
	if (shop_panel and shop_panel.visible) or (world_map_modal and world_map_modal.visible):
		return
	var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_mgr and upgrade_mgr.panel and upgrade_mgr.panel.visible:
		return
		
	char_select_opened_from = source
	if source == "pause" and pause_panel:
		pause_panel.visible = false
	elif source == "game_over" and game_over_panel:
		game_over_panel.visible = false
		
	if char_select_modal:
		char_select_modal.open_ui()

func _on_char_select_closed() -> void:
	if char_select_opened_from == "pause":
		if pause_panel:
			pause_panel.visible = true
			_refresh_pause_stats()
		get_tree().paused = true
	elif char_select_opened_from == "game_over":
		if game_over_panel:
			game_over_panel.visible = true
		get_tree().paused = true
	elif char_select_opened_from == "title":
		if title_screen:
			title_screen.refresh_all()
		get_tree().paused = false
	else:
		get_tree().paused = false
	char_select_opened_from = ""
	_update_passives_display()

func toggle_character_select() -> void:
	if char_select_modal:
		if char_select_modal.visible:
			char_select_modal.close_ui()
		else:
			open_character_select("topbar")

func open_leaderboard(source: String = "topbar") -> void:
	if (shop_panel and shop_panel.visible) or (world_map_modal and world_map_modal.visible) or (char_select_modal and char_select_modal.visible):
		return
	var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_mgr and upgrade_mgr.panel and upgrade_mgr.panel.visible:
		return
		
	leaderboard_opened_from = source
	if source == "pause" and pause_panel:
		pause_panel.visible = false
	elif source == "game_over" and game_over_panel:
		game_over_panel.visible = false
	elif source == "victory" and victory_panel:
		victory_panel.visible = false
		
	if leaderboard_modal:
		leaderboard_modal.open_ui("tournament")

func _on_leaderboard_closed() -> void:
	if leaderboard_opened_from == "pause":
		if pause_panel:
			pause_panel.visible = true
			_refresh_pause_stats()
		get_tree().paused = true
	elif leaderboard_opened_from == "game_over":
		if game_over_panel:
			game_over_panel.visible = true
		get_tree().paused = true
	elif leaderboard_opened_from == "victory":
		if victory_panel:
			victory_panel.visible = true
		get_tree().paused = true
	elif leaderboard_opened_from == "title":
		if title_screen:
			title_screen.refresh_all()
		get_tree().paused = false
	else:
		get_tree().paused = false
	leaderboard_opened_from = ""

func toggle_leaderboard() -> void:
	if leaderboard_modal:
		if leaderboard_modal.visible:
			leaderboard_modal.close_ui()
		else:
			open_leaderboard("topbar")

func open_codex(source: String = "topbar") -> void:
	if game_over_panel.visible and source != "game_over":
		return
	var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_mgr and upgrade_mgr.panel and upgrade_mgr.panel.visible:
		return
		
	codex_opened_from = source
	if source == "pause" and pause_panel:
		pause_panel.visible = false
	elif source == "game_over" and game_over_panel:
		game_over_panel.visible = false
		
	if codex_modal:
		codex_modal.open_ui()

func _on_codex_closed() -> void:
	if codex_opened_from == "pause":
		if pause_panel:
			pause_panel.visible = true
			_refresh_pause_stats()
		get_tree().paused = true
	elif codex_opened_from == "game_over":
		if game_over_panel:
			game_over_panel.visible = true
		get_tree().paused = true
	elif codex_opened_from == "title":
		if title_screen:
			title_screen.refresh_all()
		get_tree().paused = false
	else:
		get_tree().paused = false
	codex_opened_from = ""

func toggle_codex() -> void:
	if codex_modal:
		if codex_modal.visible:
			codex_modal.close_ui()
		else:
			open_codex("topbar")

func open_altar_modal(altar_node: Node2D) -> void:
	if altar_modal:
		current_active_altar = altar_node
		altar_modal.open_ui()

func _on_pact_chosen(pact_id: String) -> void:
	if current_active_altar and current_active_altar.has_method("on_pact_signed"):
		current_active_altar.on_pact_signed(pact_id)
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("apply_demonic_pact"):
		p.apply_demonic_pact(pact_id)
	current_active_altar = null

func open_hermit_modal(hermit_node: Node2D) -> void:
	current_active_hermit = hermit_node
	if not hermit_modal:
		var h_res = load("res://scenes/hermit_shop_ui.tscn")
		if h_res:
			hermit_modal = h_res.instantiate()
			add_child(hermit_modal)
			hermit_modal.item_purchased.connect(_on_hermit_item_purchased)
			hermit_modal.closed.connect(_on_hermit_closed)
	if hermit_modal and hermit_modal.has_method("open_ui"):
		hermit_modal.open_ui()

func _on_hermit_item_purchased(item_id: String) -> void:
	if current_active_hermit and current_active_hermit.has_method("on_shop_finished"):
		current_active_hermit.on_shop_finished()
	_update_passives_display()

func _on_hermit_closed() -> void:
	current_active_hermit = null


func announce_codex_unlock(title: String, reward_desc: String) -> void:
	if not is_inside_tree():
		return
	if codex_toast_banner and is_instance_valid(codex_toast_banner):
		codex_toast_banner.queue_free()
		
	codex_toast_banner = PanelContainer.new()
	codex_toast_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.09, 0.03, 0.95)
	sb.border_color = Color(1.0, 0.85, 0.25, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	codex_toast_banner.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	var t_lbl = Label.new()
	t_lbl.text = "🏆 THÀNH TỰU MỞ KHÓA: " + title
	t_lbl.add_theme_font_size_override("font_size", 13)
	t_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(t_lbl)
	
	var r_lbl = Label.new()
	r_lbl.text = "🎁 " + reward_desc
	r_lbl.add_theme_font_size_override("font_size", 11)
	r_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
	r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(r_lbl)
	
	codex_toast_banner.add_child(vbox)
	
	codex_toast_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	codex_toast_banner.offset_left = -220
	codex_toast_banner.offset_right = 220
	codex_toast_banner.offset_top = 58
	codex_toast_banner.offset_bottom = 108
	
	add_child(codex_toast_banner)
	
	codex_toast_banner.scale = Vector2(0.8, 0.8)
	codex_toast_banner.pivot_offset = Vector2(220, 25)
	var tw = create_tween()
	tw.tween_property(codex_toast_banner, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_property(codex_toast_banner, "scale", Vector2(1.0, 1.0), 0.1)
	tw.tween_interval(3.0)
	tw.tween_property(codex_toast_banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		if is_instance_valid(codex_toast_banner):
			codex_toast_banner.queue_free()
	)

func open_world_map(source: String = "topbar") -> void:
	world_map_opened_from = source
	if (shop_panel and shop_panel.visible) or (char_select_modal and char_select_modal.visible):
		return
	# The pause panel is a valid origin, not a blocker -- open_leaderboard() and
	# open_codex() already treat it that way.
	if source != "title" and source != "pause" and (game_over_panel.visible or (pause_panel and pause_panel.visible)):
		return
	var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_mgr and upgrade_mgr.panel and upgrade_mgr.panel.visible:
		return
	if source == "pause" and pause_panel:
		pause_panel.visible = false
	if world_map_modal:
		world_map_modal.open_map()

func _on_world_map_closed() -> void:
	if world_map_opened_from == "title":
		if title_screen:
			title_screen.refresh_all()
		get_tree().paused = false
	elif world_map_opened_from == "pause":
		if pause_panel:
			pause_panel.visible = true
			_refresh_pause_stats()
		get_tree().paused = true
	world_map_opened_from = ""

func toggle_world_map() -> void:
	if world_map_modal:
		if world_map_modal.visible:
			world_map_modal.close_map()
		else:
			open_world_map()



func _on_audio_toggle() -> void:
	var muted = SoundManager.toggle_mute()
	if audio_button:
		audio_button.text = "SFX: OFF" if muted else "SFX: ON"

func _on_wave_event_announced(message: String, is_boss: bool) -> void:
	if not warning_banner:
		return
	warning_banner.text = message
	warning_banner.visible = true
	warning_banner.modulate = Color(1.0, 0.25, 0.2) if is_boss else Color(1.0, 0.85, 0.2)
	warning_banner.scale = Vector2(0.8, 0.8)
	warning_banner.pivot_offset = warning_banner.size / 2.0
	
	var tw = create_tween()
	tw.tween_property(warning_banner, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_property(warning_banner, "scale", Vector2(1.0, 1.0), 0.15)
	tw.tween_interval(2.0)
	tw.tween_property(warning_banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		warning_banner.visible = false
		warning_banner.modulate.a = 1.0
	)

func close_pause_menu() -> void:
	if pause_panel:
		pause_panel.visible = false
	get_tree().paused = false

func open_pause_menu() -> void:
	if game_over_panel.visible or (shop_panel and shop_panel.visible) or (char_select_modal and char_select_modal.visible) or (world_map_modal and world_map_modal.visible):
		return
	var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_mgr and upgrade_mgr.panel and upgrade_mgr.panel.visible:
		return
	if pause_panel:
		pause_panel.visible = true
		_refresh_pause_stats()
	get_tree().paused = true

func toggle_pause() -> void:
	if pause_panel and pause_panel.visible:
		close_pause_menu()
	else:
		open_pause_menu()

func _refresh_pause_stats() -> void:
	var mins = int(GameManager.run_time / 60.0)
	var secs = int(GameManager.run_time) % 60
	var cur_hp = int(player.current_health) if player else 100
	var max_hp = int(player.max_health) if player else 100
	var spd = int(player.move_speed) if player else 230
	var mag = int(player.magnet_radius) if player else 140
	# The whole bonus, read off the player, rather than the meta upgrade's single term.
	# _build_might_bonus() sums four sources -- meta, character, run-scoped, and the
	# equipped Ỷ Thiên Kiếm -- and this used to report only the first, so the player was
	# shown a smaller number than the damage they were actually dealing.
	# See Expansion 45.0 in the README.
	var might = int(roundf(player.meta_might_bonus * 100.0)) if player else int(GameManager.get_meta_stat("might") * 10)
	var armor = player.get_armor_bonus() if player else int(GameManager.get_meta_stat("armor"))
	# The same mistake as might, one line below it: pyro is the smallest of the six
	# sources in refresh_meta_stats()'s blast expression and this reported only it.
	# Measured 2026-10-01 at pyro 5 + Dan Dien 3 + Y Thien Kiem: the panel read
	# "PYRO: +60%" while the fireball was being thrown at (1.0 + 0.60 + 0.60) * 1.25
	# = 2.75, i.e. +175%. The other four terms -- the character's area_of_effect_bonus,
	# the Dan Dien meridian, the run-scoped blast radius, and Y Thien Kiem's 1.25 --
	# were all applied to every fireball and none of them were on screen. A player at
	# pyro 0 with Cai Bang was told they had no AoE bonus at all while firing a blast
	# 40% wider than base.
	#
	# Read off the fireball rather than recomputed: blast_radius_multiplier is the one
	# field fireball_weapon.gd:86 actually multiplies blast_radius by, so whatever it
	# says is the blast, with no chance of this drifting from player.gd:391 again.
	var pyro = GameManager.get_meta_stat("pyro") * 12
	if player:
		var fire_wpn = player.get_node_or_null("Weapons/FireballWeapon")
		if fire_wpn and "blast_radius_multiplier" in fire_wpn:
			pyro = int(roundf((fire_wpn.blast_radius_multiplier - 1.0) * 100.0))
	
	var relic_info = "None"
	if GameManager and not GameManager.collected_relics.is_empty():
		var r_names = []
		for r_id in GameManager.collected_relics:
			var r_data = GameManager.RELICS.get(r_id, {})
			r_names.append(r_data.get("name", ""))
		relic_info = ", ".join(r_names)

	var bounty_info = ""
	if GameManager and not GameManager.active_bounties.is_empty():
		var b_strs = []
		for b in GameManager.active_bounties:
			var status = "DONE" if b.get("completed", false) else "%d/%d" % [b.get("current", 0), b.get("target", 1)]
			b_strs.append("%s [%s]" % [b.get("title", ""), status])
		bounty_info = "\nBOUNTIES: " + " | ".join(b_strs)

	pause_stats_label.text = "TIME: %02d:%02d   |   KILLS: %d   |   GOLD: %d\nHP: %d/%d   |   SPEED: %d   |   MAGNET: %d\nMIGHT: +%d%%   |   ARMOR: +%d   |   PYRO: +%d%%\nRELICS: %s%s" % [
		mins, secs, GameManager.kills, GameManager.run_gold,
		cur_hp, max_hp, spd, mag, might, armor, pyro,
		relic_info, bounty_info
	]
	
	var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
	var lvls = upgrade_mgr.weapon_levels if upgrade_mgr else {"dagger": 1, "shield": 1, "lightning": 1, "fireball": 1, "axe": 1}
	pause_arsenal_label.text = "ACTIVE ARSENAL:\n• Daggers Spread: Rank %d\n• Aegis Orbiting Shield: Rank %d\n• Holy Thunder Strike: Rank %d\n• Inferno Fireballs: Rank %d\n• Piercing Battleaxes: Rank %d" % [
		lvls.get("dagger", 1), lvls.get("shield", 1), lvls.get("lightning", 1), lvls.get("fireball", 1), lvls.get("axe", 1)
	]

func _setup_ui_styles() -> void:
	# TopBar typography. Wave and Timer carry the "what's happening now" read, but
	# they stay on the bold BODY face, not the Cinzel display face: their text is
	# Vietnamese ("HIỆP", "GIỜ") and Cinzel carries no Vietnamese diacritics, so the
	# display face would render those labels as tofu. Cinzel is ASCII-only here,
	# so it is reserved for MainTitle.
	for clock_label in [wave_label, timer_label]:
		if clock_label:
			clock_label.add_theme_font_override("font", UITheme.get_body_bold_font())
			clock_label.add_theme_color_override("font_color", UITheme.TEXT)
			clock_label.add_theme_color_override("font_outline_color", UITheme.INK)
			clock_label.add_theme_constant_override("outline_size", 4)
	if gold_label:
		gold_label.add_theme_font_override("font", UITheme.get_body_bold_font())
		gold_label.add_theme_color_override("font_color", UITheme.GOLD)
	if level_badge:
		level_badge.add_theme_font_override("font", UITheme.get_body_bold_font())
	for meter_text in [hp_label, xp_label]:
		if meter_text:
			meter_text.add_theme_font_override("font", UITheme.get_body_bold_font())
			meter_text.add_theme_color_override("font_color", UITheme.TEXT)
			meter_text.add_theme_color_override("font_outline_color", UITheme.INK)
			meter_text.add_theme_constant_override("outline_size", 4)

	# Level badge styling
	if level_badge:
		var lvl_sb = StyleBoxFlat.new()
		lvl_sb.bg_color = Color(0.1, 0.14, 0.22, 0.9)
		lvl_sb.border_color = Color(0.0, 0.75, 1.0, 0.9)
		lvl_sb.set_border_width_all(2)
		lvl_sb.set_corner_radius_all(4)
		level_badge.add_theme_stylebox_override("normal", lvl_sb)
		
	# HP Bar styling -- Vermilion per the Milestone 4 tokens. It used to be green,
	# which read as "safe" on a bar whose whole job is to signal danger.
	if hp_bar:
		hp_bar.add_theme_stylebox_override("background",
			UITheme.make_card_panel(UITheme.INK_DIM, UITheme.VERMILION.darkened(0.45), 4, 1))
		hp_bar.add_theme_stylebox_override("fill",
			UITheme.make_card_panel(UITheme.VERMILION, UITheme.VERMILION, 4, 0))

	# XP Bar styling -- Jade.
	if xp_bar:
		xp_bar.add_theme_stylebox_override("background",
			UITheme.make_card_panel(UITheme.INK_DIM, UITheme.JADE.darkened(0.55), 4, 1))
		xp_bar.add_theme_stylebox_override("fill",
			UITheme.make_card_panel(UITheme.JADE, UITheme.JADE, 4, 0))

	# Boss Bar styling
	if boss_hp_bar:
		var b_bg = StyleBoxFlat.new()
		b_bg.bg_color = Color(0.15, 0.03, 0.05, 0.9)
		b_bg.border_color = Color(0.45, 0.08, 0.12, 0.9)
		b_bg.set_border_width_all(1)
		b_bg.set_corner_radius_all(4)
		boss_hp_bar.add_theme_stylebox_override("background", b_bg)
		
		var b_fill = StyleBoxFlat.new()
		b_fill.bg_color = Color(0.92, 0.22, 0.22, 1.0)
		b_fill.set_corner_radius_all(4)
		boss_hp_bar.add_theme_stylebox_override("fill", b_fill)

	# Pause panel. It is the only way into Map / Hero / Leaderboard / Codex now,
	# so it gets the full card treatment and its Resume button the CTA treatment.
	if pause_panel:
		pause_panel.add_theme_stylebox_override("panel", UITheme.make_card_panel())
	for nav_button in [pause_map_button, pause_hero_button, pause_leaderboard_button,
			pause_codex_button, pause_shop_button, resume_button]:
		if nav_button:
			nav_button.add_theme_font_override("font", UITheme.get_body_bold_font())
			nav_button.add_theme_stylebox_override("normal", UITheme.make_button_style())
			nav_button.add_theme_stylebox_override("hover",
				UITheme.make_button_style(UITheme.LACQUER.lightened(0.10), UITheme.GOLD_DIM))
			nav_button.add_theme_stylebox_override("pressed",
				UITheme.make_button_style(UITheme.LACQUER.darkened(0.20)))
			nav_button.add_theme_stylebox_override("focus",
				UITheme.make_card_panel(Color(0, 0, 0, 0), UITheme.GOLD_DIM))
	if resume_button:
		resume_button.add_theme_color_override("font_color", UITheme.TEXT_ON_GOLD)
		resume_button.add_theme_color_override("font_hover_color", UITheme.TEXT_ON_GOLD)
		resume_button.add_theme_color_override("font_pressed_color", UITheme.TEXT_ON_GOLD)
		resume_button.add_theme_stylebox_override("normal", UITheme.make_cta_button_style())
		resume_button.add_theme_stylebox_override("hover",
			UITheme.make_button_style(UITheme.GOLD.lightened(0.12), UITheme.GOLD, 8))
		resume_button.add_theme_stylebox_override("pressed",
			UITheme.make_button_style(UITheme.GOLD.darkened(0.18), UITheme.GOLD_DIM, 8))

	# Arsenal badge styling
	var badges = [dagger_badge, shield_badge, thunder_badge, fireball_badge, axe_badge]
	for badge in badges:
		if badge:
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.08, 0.10, 0.15, 0.8)
			sb.border_color = Color(0.24, 0.30, 0.42, 0.7)
			sb.set_border_width_all(1)
			sb.set_corner_radius_all(3)
			sb.set_content_margin_all(4)
			badge.add_theme_stylebox_override("normal", sb)

	# Victory Panel styling
	if victory_panel:
		var vic_sb = StyleBoxFlat.new()
		vic_sb.bg_color = Color(0.10, 0.08, 0.03, 0.95)
		vic_sb.border_color = Color(1.0, 0.85, 0.25, 1.0)
		vic_sb.set_border_width_all(3)
		vic_sb.set_corner_radius_all(10)
		vic_sb.set_content_margin_all(16)
		victory_panel.add_theme_stylebox_override("panel", vic_sb)

	if victory_endless_button:
		var eb_sb = StyleBoxFlat.new()
		eb_sb.bg_color = Color(0.20, 0.15, 0.05, 0.95)
		eb_sb.border_color = Color(1.0, 0.85, 0.3, 1.0)
		eb_sb.set_border_width_all(2)
		eb_sb.set_corner_radius_all(6)
		victory_endless_button.add_theme_stylebox_override("normal", eb_sb)
		victory_endless_button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))

	# Shop Panel styling
	if shop_panel:
		var shop_sb = StyleBoxFlat.new()
		shop_sb.bg_color = Color(0.06, 0.08, 0.12, 0.98)
		shop_sb.border_color = Color(0.9, 0.75, 0.25, 0.95)
		shop_sb.set_border_width_all(2)
		shop_sb.set_corner_radius_all(8)
		shop_sb.content_margin_left = 16.0
		shop_sb.content_margin_top = 14.0
		shop_sb.content_margin_right = 16.0
		shop_sb.content_margin_bottom = 14.0
		shop_panel.add_theme_stylebox_override("panel", shop_sb)

var qi_shield_val: float = 0.0
var qi_shield_max_val: float = 0.0

func _on_player_qi_shield_changed(current: float, max_val: float) -> void:
	qi_shield_val = current
	qi_shield_max_val = max_val
	if is_instance_valid(player):
		_on_player_health_changed(player.current_health, player.max_health)

func _on_player_health_changed(current: float, max_val: float) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = current
	if hp_label:
		if qi_shield_max_val > 0.0:
			hp_label.text = "%d/%d HP [QI %d]" % [int(current), int(max_val), int(qi_shield_val)]
		else:
			hp_label.text = "%d / %d HP" % [int(current), int(max_val)]
	
	# Color shift & Danger Vignette on low HP
	var ratio = current / max(1.0, max_val)
	if danger_vignette:
		danger_vignette.visible = (ratio <= 0.25 and current > 0)
	var fill_sb = hp_bar.get_theme_stylebox("fill")
	if fill_sb is StyleBoxFlat:
		if ratio < 0.30:
			fill_sb.bg_color = Color(0.90, 0.20, 0.20)
		elif ratio < 0.60:
			fill_sb.bg_color = Color(0.95, 0.65, 0.15)
		else:
			fill_sb.bg_color = UITheme.VERMILION

func _on_player_xp_changed(current: float, required: float, level: int) -> void:
	xp_bar.max_value = required
	xp_bar.value = current
	if xp_label:
		xp_label.text = "%d / %d XP" % [int(current), int(required)]
	if level_badge:
		level_badge.text = "LV %d" % level
	_update_passives_display()

func _on_score_updated(kills: int, time: float) -> void:
	kills_label.text = Loc.tf("hud.kills_count", [kills])
	var mins = int(time / 60.0)
	var secs = int(time) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	
	if kills >= 3 and ftue_banner and ftue_banner.visible:
		_dismiss_ftue_banner()
	
	# Kill Streak Announcements
	if kills >= 25 and last_streak_announced < 25:
		last_streak_announced = 25
		_on_wave_event_announced("25 KILLS: KILLING SPREE!", false)
	elif kills >= 50 and last_streak_announced < 50:
		last_streak_announced = 50
		_on_wave_event_announced("50 KILLS: UNSTOPPABLE SLAYER!", false)
	elif kills >= 100 and last_streak_announced < 100:
		last_streak_announced = 100
		_on_wave_event_announced("100 KILLS: RAMPAGE!", false)
	elif kills >= 200 and last_streak_announced < 200:
		last_streak_announced = 200
		_on_wave_event_announced("200 KILLS: LEGENDARY!", true)
	elif kills >= 350 and last_streak_announced < 350:
		last_streak_announced = 350
		_on_wave_event_announced("350 KILLS: GODLIKE!", true)

func _on_gold_updated(new_total: int) -> void:
	if gold_label:
		gold_label.text = "%d G" % GameManager.run_gold
		# Gold collection pop effect
		var tw = create_tween()
		tw.tween_property(gold_label, "scale", Vector2(1.22, 1.22), 0.08)
		tw.tween_property(gold_label, "scale", Vector2(1.0, 1.0), 0.12)
	if shop_gold_label:
		shop_gold_label.text = "Tổng Vàng: %d" % new_total

func _on_arsenal_updated(levels: Dictionary) -> void:
	var upgrade_mgr = get_tree().get_first_node_in_group("upgrade_manager")
	var ev = upgrade_mgr.evolved_weapons if upgrade_mgr else {}

	# Milestone 3a: the base names come from Loc (the canonical table) and the
	# evolved names from their own rows, so the badges cannot drift away from the
	# dps report or the shop cards. Icon, evolved flag and level suffix per badge.
	_badge(dagger_badge, "dagger", "⚔", levels, ev, Color(1.0, 0.85, 0.2))
	_badge(shield_badge, "shield", "◈", levels, ev, Color(1.0, 0.85, 0.2))
	_badge(thunder_badge, "lightning", "⚡", levels, ev, Color(0.4, 0.9, 1.0))
	_badge(fireball_badge, "fireball", "🔥", levels, ev, Color(1.0, 0.5, 0.2))
	_badge(axe_badge, "axe", "🪓", levels, ev, Color(1.0, 0.3, 0.4))

	_update_passives_display()

## One badge, three states: evolved (EVO + gold), owned (name + level), locked.
func _badge(badge: Label, weapon_id: String, icon: String, levels: Dictionary, ev: Dictionary, evo_color: Color) -> void:
	if not badge:
		return
	var level: int = int(levels.get(weapon_id, 0))
	var wname := Loc.weapon_name(weapon_id)
	if ev.get(weapon_id, false):
		badge.text = "%s %s MAX" % [icon, Loc.t("evo.%s.name" % weapon_id, weapon_id)]
		badge.add_theme_color_override("font_color", evo_color)
		_style_badge_box(badge, evo_color, Color(0.20, 0.16, 0.05, 0.90))
	elif level > 0:
		var pips := ""
		for p in 5:
			pips += "●" if p < level else "○"
		badge.text = "%s %s %s" % [icon, wname, pips]
		badge.add_theme_color_override("font_color", Color.WHITE)
		_style_badge_box(badge, Color(0.35, 0.60, 0.85, 0.85), Color(0.08, 0.12, 0.18, 0.85))
	else:
		badge.text = "%s %s 🔒" % [icon, wname]
		badge.add_theme_color_override("font_color", Color(0.55, 0.60, 0.70, 0.65))
		_style_badge_box(badge, Color(0.20, 0.24, 0.30, 0.50), Color(0.06, 0.08, 0.10, 0.75))

func _style_badge_box(badge: Label, border_color: Color, bg_color: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(5)
	badge.add_theme_stylebox_override("normal", sb)

func _update_passives_display() -> void:
	if not passives_label:
		return
	var spd = int(player.move_speed) if player else 230
	var mag = int(player.magnet_radius) if player else 140
	# The whole bonus, read off the player, rather than the meta upgrade's single term.
	# _build_might_bonus() sums four sources -- meta, character, run-scoped, and the
	# equipped Ỷ Thiên Kiếm -- and this used to report only the first, so the player was
	# shown a smaller number than the damage they were actually dealing.
	# See Expansion 45.0 in the README.
	var might = int(roundf(player.meta_might_bonus * 100.0)) if player else int(GameManager.get_meta_stat("might") * 10)
	var armor = player.get_armor_bonus() if player else int(GameManager.get_meta_stat("armor"))
	
	var relic_str = ""
	if GameManager and not GameManager.collected_relics.is_empty():
		relic_str = " | RELIC:"
		for r_id in GameManager.collected_relics:
			var r_data = GameManager.RELICS.get(r_id, {})
			relic_str += " " + r_data.get("name", "")
			
	var scroll_str = ""
	if GameManager and not GameManager.collected_scrolls.is_empty():
		scroll_str = " | SCROLL:"
		for s_id in GameManager.collected_scrolls:
			var s_data = GameManager.MARTIAL_SCROLLS.get(s_id, {})
			scroll_str += " " + s_data.get("name", "")
			
	var gear_str = ""
	if GameManager and not GameManager.equipment_slots.is_empty():
		var has_any_gear = false
		for slot in GameManager.equipment_slots:
			var g_id = GameManager.equipment_slots[slot]
			if g_id != "" and GameManager.EQUIPMENT_CATALOG.has(g_id):
				if not has_any_gear:
					gear_str = " | GEAR:"
					has_any_gear = true
				var g_data = GameManager.EQUIPMENT_CATALOG[g_id]
				gear_str += " " + g_data.get("name", "")

	passives_label.text = "| ATK +%d%%  SPD %d  MAG %d  DEF %d%s%s%s" % [might, spd, mag, armor, relic_str, scroll_str, gear_str]

	
	if skill_button and GameManager:
		var cdata = GameManager.get_selected_character_data()
		var icon = cdata.get("skill_icon", "◈")
		if icon == "🛡️":
			icon = "◈"
		skill_button.text = "%s\nSPACE" % icon

func attach_boss_bar(boss_node: Node2D) -> void:
	if not boss_bar_container or not boss_node:
		return
	boss_bar_container.visible = true
	SoundManager.play_boss_bgm()
	var b_name = boss_node.get("boss_name")
	boss_name_label.text = str(b_name) if b_name != null else "Boss"
	var raw_max = boss_node.get("max_health")
	var raw_cur = boss_node.get("current_health")
	var max_hp = float(raw_max) if raw_max != null else 100.0
	var cur_hp = float(raw_cur) if raw_cur != null else max_hp
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = cur_hp
	if boss_hp_text:
		boss_hp_text.text = "%d / %d HP" % [int(cur_hp), int(max_hp)]
	
	if boss_node.has_signal("boss_health_changed"):
		boss_node.connect("boss_health_changed", func(cur, _max):
			boss_hp_bar.value = cur
			if boss_hp_text:
				boss_hp_text.text = "%d / %d HP" % [int(cur), int(_max)]
		)
	if boss_node.has_signal("boss_defeated"):
		boss_node.connect("boss_defeated", func():
			boss_bar_container.visible = false
			SoundManager.restore_normal_bgm()
		)

func _on_player_died() -> void:
	if danger_vignette:
		danger_vignette.visible = false
	if victory_panel:
		victory_panel.visible = false
	SoundManager.restore_normal_bgm()
	get_tree().paused = true
	game_over_panel.visible = true
	
	var rank = -1
	if LeaderboardManager and GameManager:
		var cdata = GameManager.get_selected_character_data()
		var char_id = cdata.get("id", "knight")
		rank = LeaderboardManager.submit_run(
			char_id,
			GameManager.run_time,
			GameManager.kills,
			GameManager.run_gold,
			GameManager.collected_scrolls
		)
	
	var mins = int(GameManager.run_time / 60.0)
	var secs = int(GameManager.run_time) % 60
	var rank_str = ""
	if rank > 0 and rank <= 10:
		rank_str = "\n🏆 VÕ LÂM: HẠNG #%d BẢNG VÀNG! 🏆" % rank
	final_stats_label.text = "Survived: %02d:%02d\nKills: %d\nGold Earned: %d 💰%s" % [
		mins, secs, GameManager.kills, GameManager.run_gold, rank_str
	]
	
	revive_button.visible = not GameManager.has_revived_this_run
	double_gold_button.visible = true
	# Derived from the claim rather than hardcoded false. This line used to re-enable
	# the button unconditionally, which is what undid the disabled = true the ad
	# callback had just set two lines into _on_double_gold_pressed() -- one ad view,
	# then a button that stayed live. The claim is closed in double_run_gold(); this
	# only reports it, and the two now agree because there is one of each.
	double_gold_button.disabled = GameManager.has_doubled_gold_this_run
	_render_dps_breakdown("game_over", game_over_panel)

func _on_victory_achieved(stats: Dictionary) -> void:
	if danger_vignette:
		danger_vignette.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	SoundManager.restore_normal_bgm()
	SoundManager.play("powerup")
	get_tree().paused = true
	
	if victory_panel:
		victory_panel.visible = true
		
	# Submit score to leaderboard as a completed victory run
	var rank = -1
	if LeaderboardManager and GameManager:
		var cdata = GameManager.get_selected_character_data()
		var char_id = cdata.get("id", "knight")
		rank = LeaderboardManager.submit_run(
			char_id,
			stats.get("time", GameManager.run_time),
			stats.get("kills", GameManager.kills),
			stats.get("gold", GameManager.run_gold),
			GameManager.collected_scrolls
		)
		
	var v_time = stats.get("time", GameManager.run_time)
	var mins = int(v_time / 60.0)
	var secs = int(v_time) % 60
	var v_kills = stats.get("kills", GameManager.kills)
	var v_gold = stats.get("gold", GameManager.run_gold)
	
	var title_text = "🎖️ Danh Hiệu: VÕ LÂM MINH CHỦ"
	if v_kills >= 600:
		title_text = "👑 Danh Hiệu: THIÊN HẠ ĐỆ NHẤT CAO THỦ"
	elif v_kills >= 350:
		title_text = "⚔️ Danh Hiệu: TUYỆT THẾ CAO THỦ"
		
	if victory_title_label:
		victory_title_label.text = title_text
		
	var rank_str = ""
	if rank > 0 and rank <= 10:
		rank_str = "\n🏆 VÕ LÂM: HẠNG #%d BẢNG VÀNG! 🏆" % rank
		
	if victory_stats_label:
		victory_stats_label.text = "Thời Gian: %02d:%02d\nTiêu Diệt: %d ma vật\nVàng Kiếm Được: %d 💰 (+1,000 Thưởng Thắng)%s" % [
			mins, secs, v_kills, v_gold, rank_str
		]

	_render_dps_breakdown("victory", victory_panel)

func _on_victory_endless_pressed() -> void:
	if victory_panel:
		victory_panel.visible = false
	if GameManager:
		GameManager.enter_endless_mode()

## Rewarded Ad: Revive
func _on_revive_pressed() -> void:
	AdManager.show_rewarded_ad("revive", func():
		GameManager.has_revived_this_run = true
		game_over_panel.visible = false
		if player and player.has_method("revive"):
			player.revive(0.6) # 60% HP
		get_tree().paused = false
	)

## Rewarded Ad: Double Gold
func _on_double_gold_pressed() -> void:
	AdManager.show_rewarded_ad("double_gold", func():
		# double_run_gold() owns the claim, so a second press on this run costs the
		# player another ad view and pays nothing. Nothing here decides whether the
		# claim was already spent -- _on_player_died() below re-derives the button from
		# the flag, which is why the explicit disabled = true it used to set had to go.
		GameManager.double_run_gold()
		if GameManager.has_doubled_gold_this_run:
			double_gold_button.text = "Gold Doubled! (x2)"
		_on_player_died() # Refresh stats label
	)

# Meta Shop
func _open_shop(from_pause: bool = false, source: String = "") -> void:
	shop_opened_from_pause = from_pause
	shop_opened_from_title = (source == "title")
	if from_pause:
		if pause_panel: pause_panel.visible = false
	elif shop_opened_from_title:
		pass
	else:
		if game_over_panel: game_over_panel.visible = false
	if shop_backdrop:
		shop_backdrop.visible = true
	if shop_panel:
		shop_panel.visible = true
	get_tree().paused = true
	if close_shop_button:
		if from_pause:
			close_shop_button.text = "✓ HOÀN TẤT / TRỞ LẠI TẠM DỪNG (ESC)"
		elif shop_opened_from_title:
			close_shop_button.text = "✓ HOÀN TẤT / TRỞ LẠI SẢNH CHỜ (ESC)"
		else:
			close_shop_button.text = "✓ HOÀN TẤT / TRỞ LẠI KẾT THÚC TRẬN (ESC)"
	render_shop_items()

func _close_shop() -> void:
	if shop_backdrop:
		shop_backdrop.visible = false
	if shop_panel:
		shop_panel.visible = false
	if shop_opened_from_pause:
		if pause_panel:
			pause_panel.visible = true
			_refresh_pause_stats()
		get_tree().paused = true
	elif shop_opened_from_title:
		if title_screen:
			title_screen.refresh_all()
		get_tree().paused = false
	else:
		if game_over_panel:
			game_over_panel.visible = true
		get_tree().paused = true
	shop_opened_from_title = false
	if player and player.has_method("refresh_meta_stats"):
		player.refresh_meta_stats()
	_update_passives_display()

func render_shop_items() -> void:
	if not shop_items_container:
		return
		
	shop_gold_label.text = "Tổng Vàng: %d 💰" % GameManager.total_gold
	
	for child in shop_items_container.get_children():
		child.queue_free()
		
	var stats = [
		{"id": "might", "name": "⚔️ Cường Lực", "desc": "+10% Sát Thương Vũ Khí"},
		{"id": "vitality", "name": "💖 Sinh Lực", "desc": "+25 Máu Tối Đa"},
		{"id": "swiftness", "name": "👢 Nhanh Nhẹn", "desc": "+20 Tốc Độ Di Chuyển"},
		{"id": "magnetism", "name": "🧲 Hút Nam Châm", "desc": "+30 Bán Kính Hút Ngọc"},
		{"id": "pyro", "name": "🔥 Uy Lực Hỏa", "desc": "+12% Bán Kính Nổ AoE"},
		{"id": "armor", "name": "🛡️ Giáp Bọc Thép", "desc": "-1 Sát Thương Phải Nhận"}
	]
	
	for s in stats:
		var stat_id = s["id"]
		var current_lvl = GameManager.get_meta_stat(stat_id)
		var cost = GameManager.get_upgrade_cost(stat_id)
		var is_max = current_lvl >= GameManager.MAX_META_LEVEL
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		
		var info = Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.text = "%s (Cấp %d/%d)\n%s" % [s["name"], current_lvl, GameManager.MAX_META_LEVEL, s["desc"]]
		row.add_child(info)
		
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(140, 42)
		if is_max:
			buy_btn.text = "ĐẠI THÀNH"
			buy_btn.disabled = true
		else:
			buy_btn.text = "Mua (%d 💰)" % cost
			buy_btn.disabled = GameManager.total_gold < cost
			buy_btn.pressed.connect(func():
				if GameManager.buy_meta_upgrade(stat_id):
					if player and player.has_method("refresh_meta_stats"):
						player.refresh_meta_stats()
					_update_passives_display()
					render_shop_items()
			)
		shop_items_container.add_child(row)
		
	# Section 2: Tu Luyện Kinh Mạch (Võ Lâm Bát Mạch)
	var m_sep = HSeparator.new()
	shop_items_container.add_child(m_sep)
	
	var m_header = Label.new()
	m_header.text = "🧘 TU LUYỆN KINH MẠCH (VÕ HỌC CHÂN KHÍ)"
	m_header.add_theme_font_size_override("font_size", 14)
	m_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	shop_items_container.add_child(m_header)
	
	for m_id in GameManager.MERIDIANS.keys():
		var m_data = GameManager.MERIDIANS[m_id]
		var cur_lvl = GameManager.get_meridian_stat(m_id)
		var cost = GameManager.get_meridian_cost(m_id)
		var is_max = cur_lvl >= GameManager.MAX_MERIDIAN_LEVEL
		
		var m_row = HBoxContainer.new()
		m_row.add_theme_constant_override("separation", 16)
		
		var m_info = Label.new()
		m_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m_info.text = "%s %s (Tầng %d/%d)\n%s" % [m_data["icon"], m_data["name"], cur_lvl, GameManager.MAX_MERIDIAN_LEVEL, m_data["desc"]]
		m_row.add_child(m_info)
		
		var m_btn = Button.new()
		m_btn.custom_minimum_size = Vector2(140, 42)
		if is_max:
			m_btn.text = "ĐẠI THÀNH"
			m_btn.disabled = true
		else:
			m_btn.text = "Đả Thông (%d 💰)" % cost
			m_btn.disabled = GameManager.total_gold < cost
			m_btn.pressed.connect(func():
				if GameManager.buy_meridian_upgrade(m_id):
					if player and player.has_method("refresh_meta_stats"):
						player.refresh_meta_stats()
					_update_passives_display()
					render_shop_items()
			)
		m_row.add_child(m_btn)
		shop_items_container.add_child(m_row)
		
	# Section 3: Linh Thú Đồng Hành (Martial Companions)
	var c_sep = HSeparator.new()
	shop_items_container.add_child(c_sep)
	
	var c_header = Label.new()
	c_header.text = "🐾 LINH THÚ ĐỒNG HÀNH (MARTIAL SPIRITS)"
	c_header.add_theme_font_size_override("font_size", 14)
	c_header.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	shop_items_container.add_child(c_header)
	
	for c_id in GameManager.COMPANIONS.keys():
		var c_data = GameManager.COMPANIONS[c_id]
		var is_active = GameManager.selected_companion == c_id
		
		var c_row = HBoxContainer.new()
		c_row.add_theme_constant_override("separation", 16)
		
		var c_info = Label.new()
		c_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c_info.text = "%s %s\n%s" % [c_data["icon"], c_data["name"], c_data["desc"]]
		c_row.add_child(c_info)
		
		var c_btn = Button.new()
		c_btn.custom_minimum_size = Vector2(140, 42)
		if is_active:
			c_btn.text = "✓ XUẤT TRẬN"
			c_btn.disabled = true
		else:
			c_btn.text = "Đổi Linh Thú"
			c_btn.pressed.connect(func():
				GameManager.select_companion(c_id)
				SoundManager.play("powerup", 0.15)
				render_shop_items()
			)
		c_row.add_child(c_btn)
		shop_items_container.add_child(c_row)

func _on_restart_pressed() -> void:
	if victory_panel:
		victory_panel.visible = false
	AdManager.show_interstitial_ad(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
		GameManager.start_new_run()
	)

func _setup_hero_skill_widget() -> void:
	var game_ui = get_node_or_null("GameUI")
	if not game_ui:
		return
		
	# Blood Moon vignette overlay
	blood_moon_overlay = ColorRect.new()
	blood_moon_overlay.name = "BloodMoonOverlay"
	blood_moon_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	blood_moon_overlay.color = Color(0.9, 0.05, 0.05, 0.16)
	blood_moon_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blood_moon_overlay.visible = false
	game_ui.add_child(blood_moon_overlay)
	
	# Blizzard icy overlay
	blizzard_overlay = ColorRect.new()
	blizzard_overlay.name = "BlizzardOverlay"
	blizzard_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	blizzard_overlay.color = Color(0.65, 0.85, 1.0, 0.20)
	blizzard_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blizzard_overlay.visible = false
	game_ui.add_child(blizzard_overlay)

	
	# Skill widget container at bottom right
	skill_widget = Control.new()
	skill_widget.name = "HeroSkillWidget"
	skill_widget.custom_minimum_size = Vector2(85, 85)
	skill_widget.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	skill_widget.anchor_left = 1.0
	skill_widget.anchor_right = 1.0
	skill_widget.anchor_top = 1.0
	skill_widget.anchor_bottom = 1.0
	skill_widget.offset_left = -115.0
	skill_widget.offset_top = -115.0
	skill_widget.offset_right = -30.0
	skill_widget.offset_bottom = -30.0
	game_ui.add_child(skill_widget)
	
	skill_button = Button.new()
	skill_button.name = "SkillButton"
	skill_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	var char_data = GameManager.get_selected_character_data() if GameManager else {}
	var icon = char_data.get("skill_icon", "◈")
	if icon == "🛡️":
		icon = "◈"
	skill_button.text = "%s\nSPACE" % icon
	skill_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var btn_sb = StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.1, 0.15, 0.25, 0.88)
	btn_sb.border_color = Color(0.3, 0.75, 1.0, 0.95)
	btn_sb.set_border_width_all(2)
	btn_sb.set_corner_radius_all(10)
	skill_button.add_theme_stylebox_override("normal", btn_sb)
	
	var btn_hover = btn_sb.duplicate()
	btn_hover.bg_color = Color(0.2, 0.3, 0.5, 0.95)
	btn_hover.border_color = Color(0.6, 0.95, 1.0, 1.0)
	skill_button.add_theme_stylebox_override("hover", btn_hover)
	
	skill_button.add_theme_font_size_override("font_size", 17)
	skill_button.pressed.connect(func():
		if player and player.has_method("activate_hero_skill"):
			player.activate_hero_skill()
	)
	skill_widget.add_child(skill_button)
	
	skill_cd_label = Label.new()
	skill_cd_label.name = "CDLabel"
	skill_cd_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	skill_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skill_cd_label.add_theme_font_size_override("font_size", 16)
	skill_cd_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	skill_cd_label.visible = false
	skill_widget.add_child(skill_cd_label)

func _on_player_skill_used(_skill_id: String, cooldown: float) -> void:
	if skill_button:
		skill_button.modulate = Color(0.5, 0.5, 0.6, 0.8)
	if skill_cd_label:
		skill_cd_label.visible = true
		skill_cd_label.text = "%.1fs" % cooldown

func _on_player_skill_cd_progress(current_cd: float, _max_cd: float) -> void:
	if skill_cd_label and skill_cd_label.visible:
		skill_cd_label.text = "%.1fs" % max(0.1, current_cd)

func _on_player_skill_ready() -> void:
	if skill_button:
		skill_button.modulate = Color.WHITE
		var tw = create_tween()
		tw.tween_property(skill_button, "scale", Vector2(1.15, 1.15), 0.1)
		tw.tween_property(skill_button, "scale", Vector2(1.0, 1.0), 0.1)
	if skill_cd_label:
		skill_cd_label.visible = false

func _on_blood_moon_started(_duration: float) -> void:
	SoundManager.play_boss_bgm()
	if blood_moon_overlay:
		blood_moon_overlay.visible = true
	_on_wave_event_announced("🩸 BLOOD MOON ECLIPSE! 2X XP & GOLD! 🩸", true)

func _on_blood_moon_ended() -> void:
	SoundManager.restore_normal_bgm()
	if blood_moon_overlay:
		blood_moon_overlay.visible = false
	_on_wave_event_announced("✨ Blood Moon Eclipse has faded.", false)

func _on_wave_started(wave_num: int, duration: float) -> void:
	if wave_label:
		wave_label.text = "HIỆP: %d/20  ⏳ %s" % [wave_num, _fmt_wave_clock(duration)]

func _on_wave_timer_updated(time_left: float, _duration: float) -> void:
	if wave_label:
		wave_label.text = "HIỆP: %d/20  ⏳ %s" % [wave_num_from_clock(), _fmt_wave_clock(time_left)]

func _on_wave_completed(wave_num: int) -> void:
	if wave_label:
		wave_label.text = "HIỆP %d — KẾT THÚC!" % wave_num

func _fmt_wave_clock(seconds: float) -> String:
	var total := int(ceil(maxf(0.0, seconds)))
	return "%02d:%02d" % [total / 60, total % 60]

func wave_num_from_clock() -> int:
	var wave_dir = get_tree().get_first_node_in_group("wave_director") if get_tree() else null
	return wave_dir.current_wave if is_instance_valid(wave_dir) else 1

func _process(_delta: float) -> void:
	if is_dragon_active_ui and player and is_instance_valid(player) and "dragon_duration_timer" in player:
		if dragon_button:
			dragon_button.text = "🔥\n%.1fs" % max(0.1, player.dragon_duration_timer)

	if GameManager and GameManager.is_run_active and not get_tree().paused and GameManager.selected_stage == "mount_hua":
		blizzard_timer += _delta
		if blizzard_active_timer > 0.0:
			blizzard_active_timer -= _delta
			if blizzard_overlay:
				blizzard_overlay.visible = true
				blizzard_overlay.color = Color(0.65, 0.85, 1.0, 0.18 + 0.08 * sin(blizzard_timer * 6.0))
			if blizzard_active_timer <= 0.0 and blizzard_overlay:
				blizzard_overlay.visible = false
		elif blizzard_timer >= 28.0:
			blizzard_timer = 0.0
			blizzard_active_timer = 5.0
			SoundManager.play("snow_wind", 0.15)
			_on_wave_event_announced("❄️ BÃO TUYẾT HOA SƠN QUÉT QUA! ❄️", false)
			if player and is_instance_valid(player) and player.has_method("apply_blizzard_slow"):
				player.apply_blizzard_slow(4.5)


func _setup_dragon_awakening_widget() -> void:
	var game_ui = get_node_or_null("GameUI")
	if not game_ui:
		return
		
	# Dragon Soul Widget container (to the left of HeroSkillWidget)
	dragon_widget = Control.new()
	dragon_widget.name = "DragonAwakeningWidget"
	dragon_widget.custom_minimum_size = Vector2(85, 85)
	dragon_widget.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	dragon_widget.anchor_left = 1.0
	dragon_widget.anchor_right = 1.0
	dragon_widget.anchor_top = 1.0
	dragon_widget.anchor_bottom = 1.0
	dragon_widget.offset_left = -215.0
	dragon_widget.offset_top = -115.0
	dragon_widget.offset_right = -130.0
	dragon_widget.offset_bottom = -30.0
	game_ui.add_child(dragon_widget)
	
	dragon_button = Button.new()
	dragon_button.name = "DragonButton"
	dragon_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	dragon_button.text = "🐉\n[R] 0%"
	dragon_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var btn_sb = StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.18, 0.13, 0.05, 0.90)
	btn_sb.border_color = Color(0.85, 0.65, 0.2, 0.95)
	btn_sb.set_border_width_all(2)
	btn_sb.set_corner_radius_all(10)
	dragon_button.add_theme_stylebox_override("normal", btn_sb)
	
	var btn_hover = btn_sb.duplicate()
	btn_hover.bg_color = Color(0.32, 0.22, 0.08, 0.95)
	btn_hover.border_color = Color(1.0, 0.88, 0.35, 1.0)
	dragon_button.add_theme_stylebox_override("hover", btn_hover)
	
	dragon_button.add_theme_font_size_override("font_size", 16)
	dragon_button.pressed.connect(func():
		if player and player.has_method("activate_dragon_awakening"):
			player.activate_dragon_awakening()
	)
	dragon_widget.add_child(dragon_button)
	
	# Mini Soul Meter at bottom of button
	dragon_bar = ProgressBar.new()
	dragon_bar.name = "DragonSoulBar"
	dragon_bar.show_percentage = false
	dragon_bar.max_value = 100.0
	dragon_bar.value = 0.0
	dragon_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dragon_bar.anchor_left = 0.0
	dragon_bar.anchor_right = 1.0
	dragon_bar.anchor_top = 1.0
	dragon_bar.anchor_bottom = 1.0
	dragon_bar.offset_left = 8.0
	dragon_bar.offset_right = -8.0
	dragon_bar.offset_top = -12.0
	dragon_bar.offset_bottom = -6.0
	dragon_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.08, 0.08, 0.1, 0.8)
	bar_bg.set_corner_radius_all(2)
	dragon_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(1.0, 0.85, 0.2, 1.0)
	bar_fill.set_corner_radius_all(2)
	dragon_bar.add_theme_stylebox_override("fill", bar_fill)
	
	dragon_widget.add_child(dragon_bar)

func _on_player_dragon_soul_changed(current: float, max_val: float) -> void:
	if not dragon_bar or not dragon_button:
		return
	var pct = (current / max(1.0, max_val)) * 100.0
	dragon_bar.value = pct
	
	if is_dragon_active_ui:
		return
		
	if pct >= 100.0:
		dragon_button.text = "🐉\nREADY!\n[R]"
		dragon_button.modulate = Color(1.3, 1.2, 0.6)
		var btn_sb = dragon_button.get_theme_stylebox("normal")
		if btn_sb is StyleBoxFlat:
			btn_sb.border_color = Color(1.0, 0.9, 0.3)
	else:
		dragon_button.text = "🐉\n[R] %d%%" % int(pct)
		dragon_button.modulate = Color(0.7, 0.7, 0.75) if pct < 10.0 else Color.WHITE

func _on_player_dragon_awakened(_duration: float) -> void:
	is_dragon_active_ui = true
	if dragon_button:
		dragon_button.modulate = Color(1.5, 1.3, 0.4)
	_on_wave_event_announced("🐉 LONG HỒN THÁNH GIÁNG! (Kim Long Thần Giáng) 🐉", true)

func _on_player_dragon_ended() -> void:
	is_dragon_active_ui = false
	if dragon_button:
		dragon_button.text = "🐉\n[R] 0%"
		dragon_button.modulate = Color.WHITE
	if dragon_bar:
		dragon_bar.value = 0.0
	_on_wave_event_announced("✨ Long Hồn quy nguyên, trở lại phàm thân.", false)

func _setup_dragon_pearl_tray() -> void:
	var topbar = get_node_or_null("GameUI/TopBar")
	if not topbar:
		return
	
	pearl_tray = HBoxContainer.new()
	pearl_tray.name = "DragonPearlTray"
	pearl_tray.alignment = BoxContainer.ALIGNMENT_CENTER
	pearl_tray.add_theme_constant_override("separation", 4)
	
	var t_lbl = Label.new()
	t_lbl.text = "🐉 Long Châu:"
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	pearl_tray.add_child(t_lbl)
	
	pearl_labels.clear()
	for i in range(7):
		var p_lbl = Label.new()
		p_lbl.text = "⚪"
		p_lbl.add_theme_font_size_override("font_size", 11)
		p_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.6))
		pearl_tray.add_child(p_lbl)
		pearl_labels.append(p_lbl)
		
	topbar.add_child(pearl_tray)
	topbar.move_child(pearl_tray, min(topbar.get_child_count() - 2, 5))
	
	if GameManager:
		GameManager.dragon_pearl_collected.connect(_on_dragon_pearl_collected)
		GameManager.run_started.connect(_reset_pearl_tray)

func _on_dragon_pearl_collected(pearl_index: int, _total: int) -> void:
	for i in range(pearl_labels.size()):
		if i < pearl_index:
			pearl_labels[i].text = "⭐"
			pearl_labels[i].add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			pearl_labels[i].text = "⚪"
			pearl_labels[i].add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.6))
	if pearl_index > 0 and pearl_index <= pearl_labels.size():
		var target_lbl = pearl_labels[pearl_index - 1]
		var tw = create_tween()
		tw.tween_property(target_lbl, "scale", Vector2(1.4, 1.4), 0.15)
		tw.tween_property(target_lbl, "scale", Vector2.ONE, 0.15)
	
	if pearl_index == 7:
		SoundManager.play("dragon_roar", 0.05)
		_trigger_celestial_flash()

func _reset_pearl_tray() -> void:
	for lbl in pearl_labels:
		lbl.text = "⚪"
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.6))

# --- Expansion 21.0: Bảo Rương Kim Quy (Cinematic Jackpot Chest) -------------

const CHEST_ANNOUNCEMENTS: Dictionary = {
	1: "🎁 BẢO RƯƠNG KIM QUY (%d VÕ HỌC) +%d VÀNG!",
	2: "🎰 ĐẠI PHÁT TÀI: TRIPLE JACKPOT (%d VÕ HỌC) +%d VÀNG!",
	3: "👑 CHÍ TÔN BẢO RƯƠNG: SUPREME JACKPOT (%d VÕ HỌC) +%d VÀNG!"
}

func _setup_chest_modal() -> void:
	chest_modal = PanelContainer.new()
	chest_modal.name = "ChestOpeningModal"
	chest_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	chest_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	chest_modal.visible = false
	add_child(chest_modal)

	var overlay_sb = StyleBoxFlat.new()
	overlay_sb.bg_color = Color(0.04, 0.03, 0.01, 0.92)
	chest_modal.add_theme_stylebox_override("panel", overlay_sb)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	chest_modal.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(680, 400)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var icon = Label.new()
	icon.name = "ChestIcon"
	icon.text = "🧰"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 64)
	icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vbox.add_child(icon)

	chest_modal_title = Label.new()
	chest_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest_modal_title.add_theme_font_size_override("font_size", 22)
	chest_modal_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	vbox.add_child(chest_modal_title)

	chest_modal_list = VBoxContainer.new()
	chest_modal_list.alignment = BoxContainer.ALIGNMENT_CENTER
	chest_modal_list.add_theme_constant_override("separation", 6)
	vbox.add_child(chest_modal_list)

	var claim = Button.new()
	claim.name = "ClaimButton"
	claim.text = "[ NHẬN THƯỞNG & TIẾP TỤC (ENTER/SPACE) ]"
	claim.custom_minimum_size = Vector2(420, 46)
	claim.add_theme_font_size_override("font_size", 14)
	var claim_sb = StyleBoxFlat.new()
	claim_sb.bg_color = Color(0.30, 0.20, 0.03, 0.98)
	claim_sb.border_color = Color(1.0, 0.8, 0.2, 1.0)
	claim_sb.set_border_width_all(3)
	claim_sb.set_corner_radius_all(8)
	claim_sb.set_content_margin_all(6)
	claim.add_theme_stylebox_override("normal", claim_sb)
	claim.add_theme_color_override("font_color", Color(1.0, 0.93, 0.55))
	claim.pressed.connect(_close_chest_modal)
	vbox.add_child(claim)

	if GameManager:
		GameManager.chest_opened.connect(_on_chest_opened)

func _on_chest_opened(jackpot_tier: int, upgrades: Array, gold_awarded: int) -> void:
	if not chest_modal:
		return
	get_tree().paused = true
	chest_modal.visible = true

	var template: String = CHEST_ANNOUNCEMENTS.get(jackpot_tier, "🎁 BẢO RƯƠNG KIM QUY (%d VÕ HỌC) +%d VÀNG!")
	if chest_modal_title:
		chest_modal_title.text = template % [upgrades.size(), gold_awarded]

	for child in chest_modal_list.get_children():
		child.queue_free()

	if upgrades.is_empty():
		var none_lbl = Label.new()
		none_lbl.text = "(Rương rỗng — không còn võ học nào để ban!)"
		none_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		none_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chest_modal_list.add_child(none_lbl)
	else:
		for item in upgrades:
			var lbl = Label.new()
			lbl.text = "✨ %s" % item.get("title", str(item.get("id", "?")))
			lbl.add_theme_font_size_override("font_size", 15)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
			lbl.add_theme_color_override("font_shadow_color", Color(1.0, 0.6, 0.0, 0.9))
			lbl.add_theme_constant_override("shadow_offset_x", 2)
			lbl.add_theme_constant_override("shadow_offset_y", 2)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			chest_modal_list.add_child(lbl)

	# Golden pulse on the chest icon for the reveal
	var icon = chest_modal.get_node_or_null("CenterContainer/VBox/ChestIcon")
	if icon == null:
		for n in chest_modal.find_children("*", "Label", true, false):
			if n.text == "🧰":
				icon = n
				break
	if icon:
		icon.pivot_offset = icon.size / 2.0
		icon.scale = Vector2(0.4, 0.4)
		var tw = create_tween()
		tw.tween_property(icon, "scale", Vector2(1.25, 1.25), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.15)
		tw.tween_property(icon, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE).set_loops()

	SoundManager.play("powerup", 0.3)

func _close_chest_modal() -> void:
	if chest_modal:
		chest_modal.visible = false
	get_tree().paused = false

# --- Expansion 21.0: Vạn Nhân Trảm (Kill Streak Announcer Banner) ------------

func _on_kill_milestone_reached(_milestone: int, title: String) -> void:
	_show_kill_milestone_banner(title)

func _show_kill_milestone_banner(title: String) -> void:
	if not is_inside_tree() or title == "":
		return
	if milestone_banner and is_instance_valid(milestone_banner):
		milestone_banner.queue_free()

	milestone_banner = PanelContainer.new()
	milestone_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.03, 0.02, 0.95)
	sb.border_color = Color(1.0, 0.55, 0.15, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	milestone_banner.add_theme_stylebox_override("panel", sb)

	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	lbl.add_theme_color_override("font_shadow_color", Color(1.0, 0.3, 0.0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 3)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	milestone_banner.add_child(lbl)

	milestone_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	milestone_banner.offset_left = -310
	milestone_banner.offset_right = 310
	milestone_banner.offset_top = 120
	milestone_banner.offset_bottom = 178
	add_child(milestone_banner)

	milestone_banner.scale = Vector2(0.7, 0.7)
	milestone_banner.pivot_offset = Vector2(310, 29)
	var tw = create_tween()
	tw.tween_property(milestone_banner, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(milestone_banner, "scale", Vector2(1.0, 1.0), 0.12)
	tw.tween_interval(2.5)
	tw.tween_property(milestone_banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		if is_instance_valid(milestone_banner):
			milestone_banner.queue_free()
	)

	SoundManager.play("powerup")

# --- Expansion 21.0: Chiến Tích Bảng (DPS Breakdown Report) ------------------

const COMBAT_RANK_COLORS: Dictionary = {
	"S": Color(1.0, 0.85, 0.2),
	"A": Color(1.0, 0.55, 0.25),
	"B": Color(0.45, 0.95, 0.6),
	"C": Color(0.78, 0.80, 0.86)
}

func _dps_labels_for(key: String, panel: PanelContainer) -> Dictionary:
	if dps_labels.has(key):
		return dps_labels[key]
	var vbox = panel.get_node_or_null("VBox") if panel else null
	if not vbox:
		return {}

	var rank_lbl = Label.new()
	rank_lbl.name = "CombatRankLabel"
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_size_override("font_size", 22)

	var table_lbl = Label.new()
	table_lbl.name = "DpsBreakdownLabel"
	table_lbl.add_theme_font_size_override("font_size", 12)
	table_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	table_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	vbox.add_child(rank_lbl)
	vbox.add_child(table_lbl)
	# Sit the report right under the run stats, above the button row.
	var stats = vbox.get_node_or_null("StatsLabel")
	if stats:
		vbox.move_child(table_lbl, stats.get_index() + 1)
		vbox.move_child(rank_lbl, stats.get_index() + 1)

	dps_labels[key] = {"rank": rank_lbl, "table": table_lbl}
	return dps_labels[key]

func _render_dps_breakdown(key: String, panel: PanelContainer) -> void:
	if not GameManager:
		return
	var labels := _dps_labels_for(key, panel)
	if labels.is_empty():
		return

	var rank: String = GameManager.get_combat_rank()
	labels["rank"].text = "⚔️ CHIẾN TÍCH BẢNG — ĐẲNG CẤP %s" % rank
	labels["rank"].add_theme_color_override("font_color", COMBAT_RANK_COLORS.get(rank, Color.WHITE))

	var rows: Array[Dictionary] = GameManager.get_weapon_dps_breakdown()
	var lines: Array[String] = []
	if rows.is_empty():
		lines.append("Chưa ghi nhận sát thương võ học nào.")
	else:
		for row in rows:
			lines.append("%s   %d ST   (%.1f%%)   ·   %.1f DPS" % [
				row["name"], int(row["damage"]), float(row["percent"]), float(row["dps"])
			])
		lines.append("── TỔNG CỘNG: %d sát thương ──" % int(GameManager.get_total_weapon_damage()))
	labels["table"].text = "\n".join(lines)

func _setup_shenron_modal() -> void:
	shenron_modal = PanelContainer.new()
	shenron_modal.name = "ShenronWishModal"
	shenron_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	shenron_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	shenron_modal.visible = false
	add_child(shenron_modal)
	
	var overlay_sb = StyleBoxFlat.new()
	overlay_sb.bg_color = Color(0.03, 0.04, 0.08, 0.95)
	shenron_modal.add_theme_stylebox_override("panel", overlay_sb)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shenron_modal.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(720, 420)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "🐉 THẦN LONG GIÁNG THẾ 🐉"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Ngươi đã tập hợp đủ 7 viên Thất Long Châu!\nHãy chọn một ước nguyện tối thượng của Thần Long:"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.88, 1.0))
	vbox.add_child(subtitle)
	
	shenron_cards_container = HBoxContainer.new()
	shenron_cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	shenron_cards_container.add_theme_constant_override("separation", 18)
	vbox.add_child(shenron_cards_container)
	
	var close_wish_btn = Button.new()
	close_wish_btn.text = "✖ ĐỂ SAU / ĐÓNG (ESC)"
	close_wish_btn.custom_minimum_size = Vector2(200, 36)
	close_wish_btn.add_theme_font_size_override("font_size", 13)
	close_wish_btn.pressed.connect(_close_shenron_modal)
	vbox.add_child(close_wish_btn)
	
	if GameManager:
		GameManager.shenron_summon_ready.connect(_open_shenron_modal)

func _close_shenron_modal() -> void:
	if shenron_modal:
		shenron_modal.visible = false
	get_tree().paused = false

func _open_shenron_modal() -> void:
	if not shenron_modal or not shenron_cards_container:
		return
	get_tree().paused = true
	shenron_modal.visible = true
	
	for child in shenron_cards_container.get_children():
		child.queue_free()
		
	for w_id in GameManager.SHENRON_WISHES.keys():
		var w_data = GameManager.SHENRON_WISHES[w_id]
		var card = _create_shenron_wish_card(w_data)
		shenron_cards_container.add_child(card)

func _create_shenron_wish_card(w_data: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(210, 240)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.95)
	sb.border_color = w_data.get("color", Color(1.0, 0.85, 0.2))
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	
	var cvbox = VBoxContainer.new()
	cvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cvbox.add_theme_constant_override("separation", 10)
	panel.add_child(cvbox)
	
	var icon = Label.new()
	icon.text = w_data.get("icon", "✨")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 42)
	cvbox.add_child(icon)
	
	var ctitle = Label.new()
	ctitle.text = w_data.get("title", "Ước Nguyện")
	ctitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctitle.add_theme_font_size_override("font_size", 16)
	ctitle.add_theme_color_override("font_color", w_data.get("color", Color.WHITE))
	cvbox.add_child(ctitle)
	
	var cdesc = Label.new()
	cdesc.text = w_data.get("desc", "")
	cdesc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cdesc.custom_minimum_size = Vector2(180, 60)
	cdesc.add_theme_font_size_override("font_size", 11)
	cdesc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	cvbox.add_child(cdesc)
	
	var btn = Button.new()
	btn.text = "CHỌN ƯỚC NGUYỆN"
	btn.add_theme_font_size_override("font_size", 12)
	var w_id = w_data.get("id", "")
	btn.pressed.connect(func():
		_choose_shenron_wish(w_id)
	)
	cvbox.add_child(btn)
	return panel

func _choose_shenron_wish(wish_id: String) -> void:
	if shenron_modal:
		shenron_modal.visible = false
	get_tree().paused = false
	if GameManager:
		GameManager.select_shenron_wish(wish_id)

func _setup_danger_vignette() -> void:
	danger_vignette = ColorRect.new()
	danger_vignette.name = "DangerVignette"
	danger_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	danger_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_vignette.color = Color(0.85, 0.05, 0.05, 0.22)
	danger_vignette.visible = false
	add_child(danger_vignette)
	move_child(danger_vignette, 0)

func _setup_celestial_flash() -> void:
	celestial_flash = ColorRect.new()
	celestial_flash.name = "CelestialFlash"
	celestial_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	celestial_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celestial_flash.color = Color(1.0, 0.95, 0.65, 0.0)
	celestial_flash.visible = false
	add_child(celestial_flash)

func _trigger_celestial_flash() -> void:
	if not celestial_flash:
		return
	celestial_flash.visible = true
	celestial_flash.color = Color(1.0, 0.95, 0.65, 0.85)
	var tw = create_tween()
	tw.tween_property(celestial_flash, "color:a", 0.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if celestial_flash:
			celestial_flash.visible = false
	)

func _setup_ftue_banner() -> void:
	if not GameManager or not GameManager.is_first_run:
		return
		
	ftue_banner = PanelContainer.new()
	ftue_banner.name = "FTUEBanner"
	ftue_banner.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.94)
	sb.border_color = Color(1.0, 0.82, 0.25, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	ftue_banner.add_theme_stylebox_override("panel", sb)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	
	var label = Label.new()
	label.text = "📜 TÂN THỦ NHẬP MÔN: Di chuyển [WASD / Kéo cảm ứng] né quái & tự kích hoạt võ công | Thu thập 7 Viên Ngọc Rồng ⭐!"
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	hbox.add_child(label)
	
	var close_btn = Button.new()
	close_btn.text = "✓ Đã Hiểu"
	close_btn.add_theme_font_size_override("font_size", 11)
	close_btn.pressed.connect(_dismiss_ftue_banner)
	hbox.add_child(close_btn)
	
	ftue_banner.add_child(hbox)
	
	ftue_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ftue_banner.offset_left = -380
	ftue_banner.offset_right = 380
	ftue_banner.offset_top = 52
	ftue_banner.offset_bottom = 96
	
	add_child(ftue_banner)

func _dismiss_ftue_banner() -> void:
	if not ftue_banner or not ftue_banner.visible:
		return
	if GameManager:
		GameManager.mark_first_run_completed()
	var tw = create_tween()
	tw.tween_property(ftue_banner, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		if ftue_banner:
			ftue_banner.visible = false
	)

func _setup_cinematic_vignette() -> void:
	if cinematic_vignette:
		return
	cinematic_vignette = TextureRect.new()
	cinematic_vignette.name = "CinematicVignette"
	cinematic_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	cinematic_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinematic_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# High-performance radial gradient texture for smooth vignette without shader
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.08),
		Color(0.01, 0.02, 0.04, 0.62)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.0, 0.0)
	grad_tex.width = 512
	grad_tex.height = 512
	
	cinematic_vignette.texture = grad_tex
	add_child(cinematic_vignette)
	move_child(cinematic_vignette, 0)

func _setup_ambient_weather() -> void:
	if ambient_weather:
		return
	ambient_weather = CPUParticles2D.new()
	ambient_weather.name = "AmbientWeather"
	ambient_weather.z_index = 5
	ambient_weather.position = Vector2(640, 360)
	ambient_weather.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ambient_weather.emission_rect_extents = Vector2(700, 400)
	ambient_weather.preprocess = 4.0
	add_child(ambient_weather)
	move_child(ambient_weather, 1)
	_update_ambient_weather()

func _update_ambient_weather() -> void:
	if not ambient_weather or not GameManager:
		return
	var stage_id = GameManager.selected_stage
	if stage_id == "mount_hua":
		# Mount Hua: Swirling mountain snowflakes
		ambient_weather.amount = 65
		ambient_weather.lifetime = 4.0
		ambient_weather.direction = Vector2(-0.8, 1.0)
		ambient_weather.spread = 25.0
		ambient_weather.gravity = Vector2(-40.0, 75.0)
		ambient_weather.initial_velocity_min = 40.0
		ambient_weather.initial_velocity_max = 90.0
		ambient_weather.scale_amount_min = 1.5
		ambient_weather.scale_amount_max = 3.5
		ambient_weather.color = Color(0.88, 0.95, 1.0, 0.70)
	else:
		# Ba Lăng Huyện (Plains): Gentle drifting golden wind motes & leaves
		ambient_weather.amount = 35
		ambient_weather.lifetime = 5.5
		ambient_weather.direction = Vector2(0.8, 0.5)
		ambient_weather.spread = 30.0
		ambient_weather.gravity = Vector2(15.0, 20.0)
		ambient_weather.initial_velocity_min = 20.0
		ambient_weather.initial_velocity_max = 50.0
		ambient_weather.scale_amount_min = 2.0
		ambient_weather.scale_amount_max = 4.0
		ambient_weather.color = Color(0.95, 0.85, 0.45, 0.45)

func _setup_title_screen() -> void:
	if not title_screen:
		title_screen = get_node_or_null("TitleScreen")
	if title_screen:
		if not title_screen.start_run_pressed.is_connected(_on_title_start_run):
			title_screen.start_run_pressed.connect(_on_title_start_run)
		if not title_screen.hero_select_pressed.is_connected(func(): open_character_select("title")):
			title_screen.hero_select_pressed.connect(func(): open_character_select("title"))
		if not title_screen.world_map_pressed.is_connected(func(): open_world_map("title")):
			title_screen.world_map_pressed.connect(func(): open_world_map("title"))
		if not title_screen.shop_pressed.is_connected(func(): _open_shop(false, "title")):
			title_screen.shop_pressed.connect(func(): _open_shop(false, "title"))
		if not title_screen.leaderboard_pressed.is_connected(func(): open_leaderboard("title")):
			title_screen.leaderboard_pressed.connect(func(): open_leaderboard("title"))
		if not title_screen.codex_pressed.is_connected(func(): open_codex("title")):
			title_screen.codex_pressed.connect(func(): open_codex("title"))

func _on_title_start_run() -> void:
	GameManager.start_new_run()
	_update_ambient_weather()
	SoundManager.play("powerup", 0.15)

func return_to_title_screen() -> void:
	get_tree().paused = false
	if pause_panel:
		pause_panel.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if shop_backdrop:
		shop_backdrop.visible = false
	if shop_panel:
		shop_panel.visible = false
	if char_select_modal and char_select_modal.visible:
		char_select_modal.close_ui()
	if world_map_modal and world_map_modal.visible:
		world_map_modal.close_map()
	if leaderboard_modal and leaderboard_modal.visible:
		leaderboard_modal.close_ui()
	if codex_modal and codex_modal.visible:
		codex_modal.close_ui()
	if altar_modal and altar_modal.visible:
		altar_modal.close_ui()
	if hermit_modal and hermit_modal.visible:
		hermit_modal.close_ui()
		
	# Clear active entities
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()
	for p in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(p):
			p.queue_free()
	for g in get_tree().get_nodes_in_group("gems"):
		if is_instance_valid(g):
			g.queue_free()
	for c in get_tree().get_nodes_in_group("coins"):
		if is_instance_valid(c):
			c.queue_free()
			
	# Reset player state
	if player:
		player.global_position = Vector2.ZERO
		player.current_health = player.max_health
		if player.sprite:
			player.sprite.rotation = 0.0
			player.sprite.modulate = Color.WHITE
		if player.has_method("refresh_meta_stats"):
			player.refresh_meta_stats()
			
	GameManager.is_run_active = false
	if title_screen:
		title_screen.open_screen()

