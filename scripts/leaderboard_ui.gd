class_name LeaderboardUI
extends Control

## LeaderboardUI: Modal dialog for Đại Hội Võ Lâm (Hall of Fame Tournament)
## and Thử Thách Hằng Ngày (Daily Seeded Celestial Trials).

signal closed

@onready var close_button: Button = find_child("CloseButton", true, false)
@onready var header_close_button: Button = find_child("HeaderCloseButton", true, false)
@onready var backdrop: Control = find_child("Backdrop", true, false)
@onready var tab_tournament_btn: Button = find_child("TabTournamentBtn", true, false)
@onready var tab_daily_btn: Button = find_child("TabDailyBtn", true, false)
@onready var tournament_view: Control = find_child("TournamentView", true, false)
@onready var daily_view: Control = find_child("DailyView", true, false)
@onready var entries_container: VBoxContainer = find_child("EntriesContainer", true, false)
@onready var nickname_edit: LineEdit = find_child("NicknameEdit", true, false)
@onready var save_name_btn: Button = find_child("SaveNameBtn", true, false)

# Daily view elements
@onready var daily_title_lbl: Label = find_child("DailyTitleLbl", true, false)
@onready var daily_desc_lbl: Label = find_child("DailyDescLbl", true, false)
@onready var daily_date_lbl: Label = find_child("DailyDateLbl", true, false)
@onready var daily_reward_lbl: Label = find_child("DailyRewardLbl", true, false)
@onready var daily_status_lbl: Label = find_child("DailyStatusLbl", true, false)

var was_paused_before_open: bool = false
var current_tab: String = "tournament"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if close_button:
		close_button.pressed.connect(close_ui)
	if header_close_button:
		header_close_button.pressed.connect(close_ui)
	if backdrop:
		backdrop.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				close_ui()
		)
	if tab_tournament_btn:
		tab_tournament_btn.pressed.connect(func(): _switch_tab("tournament"))
	if tab_daily_btn:
		tab_daily_btn.pressed.connect(func(): _switch_tab("daily"))
	if save_name_btn and nickname_edit:
		save_name_btn.pressed.connect(_on_save_nickname)
	if nickname_edit:
		nickname_edit.text_submitted.connect(func(_t): _on_save_nickname())
		
	if LeaderboardManager:
		LeaderboardManager.leaderboard_updated.connect(refresh_ui)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L):
		close_ui()
		get_viewport().set_input_as_handled()

func open_ui(tab: String = "tournament") -> void:
	was_paused_before_open = get_tree().paused
	visible = true
	get_tree().paused = true
	if nickname_edit and LeaderboardManager:
		nickname_edit.text = LeaderboardManager.player_nickname
	_switch_tab(tab)

func close_ui() -> void:
	if not visible:
		return
	visible = false
	if not was_paused_before_open:
		get_tree().paused = false
	emit_signal("closed")

func _switch_tab(tab: String) -> void:
	current_tab = tab
	if tournament_view:
		tournament_view.visible = (tab == "tournament")
	if daily_view:
		daily_view.visible = (tab == "daily")
	if tab_tournament_btn:
		tab_tournament_btn.modulate = Color(1.2, 1.2, 1.0) if tab == "tournament" else Color(0.7, 0.7, 0.7)
	if tab_daily_btn:
		tab_daily_btn.modulate = Color(1.2, 1.2, 1.0) if tab == "daily" else Color(0.7, 0.7, 0.7)
	refresh_ui()

func _on_save_nickname() -> void:
	if nickname_edit and LeaderboardManager:
		LeaderboardManager.set_player_nickname(nickname_edit.text)
		SoundManager.play("powerup", 0.1)

func refresh_ui() -> void:
	if not LeaderboardManager:
		return
	if current_tab == "tournament":
		_render_tournament_list()
	else:
		_render_daily_view()

func _render_tournament_list() -> void:
	if not entries_container:
		return
	for child in entries_container.get_children():
		child.queue_free()
		
	var entries = LeaderboardManager.get_top_entries()
	for i in range(entries.size()):
		var e = entries[i]
		var rank = i + 1
		var is_player = e.get("is_player", false)
		
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 36)
		
		var sb = StyleBoxFlat.new()
		if is_player:
			sb.bg_color = Color(0.12, 0.28, 0.35, 0.95)
			sb.border_color = Color(0.2, 0.9, 1.0, 0.9)
			sb.set_border_width_all(2)
		else:
			sb.bg_color = Color(0.08, 0.10, 0.16, 0.85) if rank % 2 == 0 else Color(0.05, 0.07, 0.12, 0.85)
			sb.border_color = Color(0.2, 0.25, 0.35, 0.6)
			sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 12.0
		sb.content_margin_right = 12.0
		sb.content_margin_top = 4.0
		sb.content_margin_bottom = 4.0
		row.add_theme_stylebox_override("panel", sb)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		
		# Rank badge
		var rank_lbl = Label.new()
		var rank_icon = "🥇" if rank == 1 else ("🥈" if rank == 2 else ("🥉" if rank == 3 else "#%d" % rank))
		rank_lbl.text = rank_icon
		rank_lbl.custom_minimum_size = Vector2(36, 0)
		rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_lbl.add_theme_font_size_override("font_size", 14)
		if rank <= 3:
			rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		hbox.add_child(rank_lbl)
		
		# Hero icon
		var hero_id = e.get("hero", "knight")
		var hero_icon = "🎋" if hero_id == "beggar" else ("🔥" if hero_id == "pyro" else ("💨" if hero_id == "ranger" else ("⚡" if hero_id == "mage" else ("☯️" if hero_id == "monk" else "🛡️"))))
		var hero_lbl = Label.new()
		hero_lbl.text = hero_icon
		hero_lbl.custom_minimum_size = Vector2(24, 0)
		hbox.add_child(hero_lbl)
		
		# Name & Sect
		var name_lbl = Label.new()
		name_lbl.text = "%s (%s)" % [e.get("name", "Vô Danh"), e.get("sect", "Giang Hồ")]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 13)
		if is_player:
			name_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.8))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		hbox.add_child(name_lbl)
		
		# Survival Time
		var time_sec = float(e.get("time", 0.0))
		var mins = int(time_sec / 60.0)
		var secs = int(time_sec) % 60
		var time_lbl = Label.new()
		time_lbl.text = "⏱️ %02d:%02d" % [mins, secs]
		time_lbl.custom_minimum_size = Vector2(90, 0)
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		time_lbl.add_theme_font_size_override("font_size", 12)
		time_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
		hbox.add_child(time_lbl)
		
		# Kills
		var kills_lbl = Label.new()
		kills_lbl.text = "💀 %d" % int(e.get("kills", 0))
		kills_lbl.custom_minimum_size = Vector2(80, 0)
		kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		kills_lbl.add_theme_font_size_override("font_size", 12)
		kills_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		hbox.add_child(kills_lbl)
		
		# Score
		var score_lbl = Label.new()
		score_lbl.text = "⭐ %d pts" % int(e.get("score", 0))
		score_lbl.custom_minimum_size = Vector2(110, 0)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_lbl.add_theme_font_size_override("font_size", 13)
		score_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		hbox.add_child(score_lbl)
		
		row.add_child(hbox)
		entries_container.add_child(row)

func _render_daily_view() -> void:
	if not LeaderboardManager:
		return
	var trial = LeaderboardManager.get_daily_trial_info()
	if daily_date_lbl:
		daily_date_lbl.text = "📅 Ngày Thi Đấu: %s (Mỗi ngày xoay tua thử thách)" % trial.get("date", "")
	if daily_title_lbl:
		daily_title_lbl.text = "⚡ %s ⚡" % trial.get("title", "Thử Thách Hằng Ngày")
	if daily_desc_lbl:
		daily_desc_lbl.text = trial.get("desc", "")
	if daily_reward_lbl:
		daily_reward_lbl.text = "💰 Phần Thưởng Hoàn Thành: +%d Vàng" % trial.get("reward_gold", 500)
	if daily_status_lbl:
		var comp = trial.get("completed", false)
		var h_score = trial.get("high_score", 0)
		if comp:
			daily_status_lbl.text = "✅ ĐÃ THAM GIA HÔM NAY | Kỷ lục: %d điểm" % h_score
			daily_status_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
		else:
			daily_status_lbl.text = "⏳ CHƯA THAM GIA | Hãy bắt đầu trận chiến để ghi danh bảng vàng!"
			daily_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
