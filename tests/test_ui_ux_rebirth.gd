extends Node

## Milestone 4 Part 1: "UI/UX Visual Rebirth" -- fonts & tokens, combat HUD
## declutter, tactile UI audio, and the modal flows that had to survive the move.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TITLE_SCENE: PackedScene = preload("res://scenes/title_screen.tscn")

## The four TopBar buttons Milestone 4 moved into the PausePanel. If one of these
## ever reappears on the combat bar, the declutter has been undone.
const RETIRED_TOPBAR_BUTTONS: Array[String] = [
	"MapButton", "HeroButton", "LeaderboardButton", "CodexButton",
]
## What must survive on the combat bar: vitals, clock, wallet, run readouts and
## the two toggles. Kills and the dragon-pearl tray are run state, not navigation.
const COMBAT_ESSENTIALS: Array[String] = [
	"LevelBadge", "HPContainer", "XPContainer", "WaveLabel", "TimerLabel",
	"GoldLabel", "KillsLabel", "DragonPearlTray", "AudioButton", "PauseButton",
]
const PAUSE_NAV_BUTTONS: Array[String] = [
	"PauseMapButton", "PauseShopButton", "PauseHeroButton",
	"PauseLeaderboardButton", "PauseCodexButton",
]
const UI_CUES: Array[String] = ["ui_hover", "ui_click", "ui_buy", "ui_deny"]

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## add_gold()/trigger_victory() persist to user://save_data.cfg immediately, so a
## suite that spends gold would write into the developer's real save. Backed up
## byte-for-byte before the suite and restored after.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.uibak"
var _had_save: bool = false

var _cues: Array[String] = []
var _main: Node = null
var _hud: CanvasLayer = null

func _backup_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		_had_save = true
		var src := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var dst := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		dst.store_buffer(src.get_buffer(src.get_length()))
		src.close()
		dst.close()

func _restore_save() -> void:
	if not _had_save:
		return
	var src := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	var dst := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	dst.store_buffer(src.get_buffer(src.get_length()))
	src.close()
	dst.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_PATH))

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	_backup_save()
	print("=== RUNNING MILESTONE 4: UI/UX VISUAL REBIRTH TEST SUITE ===")
	# Keep the tree inert so the suite, not the autoload, decides when a run runs.
	GameManager.is_run_active = false
	SoundManager.sfx_played.connect(func(cue): _cues.append(String(cue)))

	_test_fonts_resolve()
	_test_hud_declutter()
	_test_ui_audio()
	_test_modal_regression()

	get_tree().paused = false
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL UI/UX VISUAL REBIRTH TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

func clear_cues() -> void:
	_cues.clear()

func _heard(cue: String) -> bool:
	return _cues.has(cue)

# --- 1. Fonts -------------------------------------------------------------

## The project-wide font is the cheapest possible win: set it once in
## project.godot and every Control in the game inherits it. Assert on the
## resolved theme rather than the setting string, so a typo'd path can't pass.
func _test_fonts_resolve() -> void:
	var project_font_path: String = str(
		ProjectSettings.get_setting("gui/theme/custom_font", ""))
	check(project_font_path == UITheme.BODY_FONT_PATH,
		"project.godot points its custom font at Be Vietnam Pro, got %s" % project_font_path)

	var default_font: Font = ThemeDB.get_default_theme().default_font
	check(default_font != null, "The project theme resolves a default font")
	if default_font:
		check(default_font.resource_path.ends_with("BeVietnamPro-Regular.ttf"),
			"The resolved default font is BeVietnamPro-Regular, got %s" % default_font.resource_path)

	var display_font := UITheme.get_display_font()
	check(display_font != null, "UITheme.get_display_font() loads")
	if display_font:
		check(display_font.resource_path.ends_with("Cinzel-Bold.ttf"),
			"The display font is Cinzel Bold, got %s" % display_font.resource_path)
		# A font that loaded but has no glyphs renders every title as tofu.
		check(display_font.get_string_size("SURVIVOR QUEST", 0, -1, 52).x > 0.0,
			"The display font measures a real glyph run for the title")

	var body_font := UITheme.get_body_font()
	var body_bold := UITheme.get_body_bold_font()
	check(body_font != null, "UITheme.get_body_font() loads")
	check(body_bold != null, "UITheme.get_body_bold_font() loads")
	check(body_font != body_bold, "The two body faces are genuinely different resources")
	# Be Vietnam Pro is the diacritic face; if it silently lost the Vietnamese
	# range, every "Vàng Tích Lũy" in the game renders as fallback boxes.
	if body_font:
		check(body_font.has_char("ầ".unicode_at(0)),
			"The body font carries Vietnamese diacritics")

	# Cinzel is the display face and is ASCII-only. It is safe on MainTitle
	# ("SURVIVOR QUEST") but must never reach a Vietnamese label -- these two
	# checks are what stop someone applying it to the wave/timer labels later.
	if display_font:
		var missing := ""
		for cp in range(65, 91):
			if not display_font.has_char(cp):
				missing += char(cp)
		check(missing == "", "The display face covers A-Z for the title, missing '%s'" % missing)
		check(not display_font.has_char("ầ".unicode_at(0)),
			"The display face is still ASCII-only (no Vietnamese diacritics)")

	# Cached statics must return the identical instance, not reload per node.
	check(UITheme.get_display_font() == display_font, "get_display_font() is cached")
	check(UITheme.get_body_font() == body_font, "get_body_font() is cached")

	# The palette is the other half of the rebirth -- pin the spec's hexes.
	check(UITheme.INK == Color("#0D0F14"), "INK token")
	check(UITheme.LACQUER == Color("#161922"), "LACQUER token")
	check(UITheme.GOLD == Color("#F5C542"), "GOLD token")
	check(UITheme.JADE == Color("#2EC4B6"), "JADE token")
	check(UITheme.VERMILION == Color("#E63946"), "VERMILION token")
	check(UITheme.MUTED == Color("#8A8F9A"), "MUTED token")
	check(UITheme.BORDER == Color("#2F3747"), "BORDER token")

	var card := UITheme.make_card_panel()
	check(card != null and card.bg_color == UITheme.LACQUER,
		"make_card_panel() defaults to the lacquer surface")
	var cta := UITheme.make_cta_button_style()
	check(cta != null and cta.bg_color == UITheme.GOLD,
		"make_cta_button_style() fills with gold")
	print("✔ Fonts resolve, cache, carry diacritics; palette matches the spec hexes.")

# --- 2. HUD declutter -----------------------------------------------------

func _boot_main() -> void:
	if _main:
		return
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_hud = _main.get_node("HUD")

func _drop_main() -> void:
	if _main:
		_main.free()
		_main = null
		_hud = null

func _test_hud_declutter() -> void:
	_boot_main()
	var top_bar: Control = _hud.get_node_or_null("GameUI/TopBar")
	check(top_bar != null, "The combat TopBar still exists")
	if not top_bar:
		return

	for retired in RETIRED_TOPBAR_BUTTONS:
		check(top_bar.get_node_or_null(retired) == null,
			"%s is gone from the combat TopBar" % retired)

	for essential in COMBAT_ESSENTIALS:
		check(top_bar.get_node_or_null(essential) != null,
			"%s is still on the combat TopBar" % essential)

	# Nothing but vitals, clock, wallet and the two toggles may remain.
	var allowed := COMBAT_ESSENTIALS.duplicate()
	allowed.append_array(["HPBar", "HPLabel", "XPBar", "XPLabel"])
	for child in top_bar.get_children():
		check(allowed.has(String(child.name)),
			"TopBar holds only combat essentials, found %s" % child.name)

	# Health reads as danger, progress reads as growth. Both used to be the wrong
	# colour (green HP, blue XP), so assert the resolved stylebox, not the token.
	var hp_fill := (top_bar.get_node("HPContainer/HPBar") as ProgressBar).get_theme_stylebox("fill")
	var xp_fill := (top_bar.get_node("XPContainer/XPBar") as ProgressBar).get_theme_stylebox("fill")
	check(hp_fill is StyleBoxFlat and (hp_fill as StyleBoxFlat).bg_color == UITheme.VERMILION,
		"The HP bar fills with VERMILION")
	check(xp_fill is StyleBoxFlat and (xp_fill as StyleBoxFlat).bg_color == UITheme.JADE,
		"The XP bar fills with JADE")

	var gold_label := top_bar.get_node("GoldLabel") as Label
	check(gold_label.get_theme_color("font_color") == UITheme.GOLD,
		"GoldLabel is tinted with the gold token")

	# Every feature the declutter moved must be reachable from the pause menu.
	var pause_panel := _hud.get_node_or_null("PausePanel")
	check(pause_panel != null, "The PausePanel still exists")
	for nav in PAUSE_NAV_BUTTONS:
		check(pause_panel.get_node_or_null("VBox/" + nav) != null,
			"%s exists in PausePanel" % nav)

	# The pause menu is now the only route in, so the handles must be wired --
	# a null @onready here would silently drop the button on the floor.
	for handle in ["pause_map_button", "pause_hero_button", "pause_leaderboard_button",
			"pause_codex_button", "pause_shop_button"]:
		var btn: Button = _hud.get(handle)
		check(btn != null, "hud.%s is wired" % handle)
		if btn:
			check(btn.pressed.get_connections().size() > 0,
				"hud.%s has a live pressed connection" % handle)
	print("✔ TopBar holds only combat essentials; navigation lives in the PausePanel.")

# --- 3. Tactile UI audio --------------------------------------------------

func _test_ui_audio() -> void:
	for cue in UI_CUES:
		check(SoundManager.sounds.has(cue), "SoundManager registered %s" % cue)
		if SoundManager.sounds.has(cue):
			check(SoundManager.sounds[cue] is AudioStream,
				"%s loaded as an AudioStream" % cue)

	# The helpers must actually reach the mixer, which under the dummy audio
	# driver is only observable through the sfx_played signal.
	var helpers := {
		"play_ui_hover": "ui_hover",
		"play_ui_click": "ui_click",
		"play_ui_buy": "ui_buy",
		"play_ui_deny": "ui_deny",
	}
	for method in helpers:
		clear_cues()
		check(SoundManager.has_method(method), "SoundManager exposes %s()" % method)
		SoundManager.call(method)
		check(_heard(helpers[method]), "%s() plays the %s cue, got %s"
			% [method, helpers[method], str(_cues)])

	# Hover fires on every pointer move, so it has to sit well under the click.
	SoundManager.play_ui_hover()
	var hover_db := _pooled_volume_for(SoundManager.sounds["ui_hover"])
	SoundManager.play_ui_click()
	var click_db := _pooled_volume_for(SoundManager.sounds["ui_click"])
	check(hover_db < click_db,
		"ui_hover is quieter than ui_click (%s dB vs %s dB)" % [hover_db, click_db])

	# A pooled player reused by a combat cue must not inherit the UI attenuation.
	SoundManager.play_ui_hover()
	SoundManager.play("coin", 0.0)
	var coin_db := _pooled_volume_for(SoundManager.sounds["coin"])
	check(is_equal_approx(coin_db, 0.0),
		"A combat cue plays at 0 dB after a quiet UI cue borrowed the player, got %s" % coin_db)
	print("✔ Four UI cues registered and played; mixing levels are correct.")

## Volume of whichever pool player currently holds `stream`, or NAN if none does.
func _pooled_volume_for(stream: AudioStream) -> float:
	for asp in SoundManager.player_pool:
		if asp.stream == stream:
			return asp.volume_db
	return NAN

# --- 4. Modal regression --------------------------------------------------

## The declutter rerouted Map / Hero / Leaderboard / Codex through the pause
## menu. Each must hide the pause panel on open and put it back on close, or the
## player is stranded on a dead screen.
func _test_modal_regression() -> void:
	_boot_main()
	var pause_panel := _hud.get_node("PausePanel") as Control

	# World map: newly reachable from pause, and the one path that had no
	# pause-mode handling before this milestone.
	pause_panel.visible = true
	_hud.pause_map_button.emit_signal("pressed")
	check(_hud.world_map_modal.visible, "PauseMapButton opens the WorldMapModal")
	check(not pause_panel.visible, "The pause panel steps aside for the map")
	_hud.world_map_modal.close_map()
	check(not _hud.world_map_modal.visible, "The world map closes")
	check(pause_panel.visible, "The pause panel returns after the map closes")

	# The three that already had pause entry points must still round-trip.
	# The hero modal's handle is char_select_modal, so pair each label with the
	# handle that actually exists rather than deriving the name.
	for pair in [["leaderboard", "leaderboard_modal"], ["codex", "codex_modal"],
			["hero", "char_select_modal"]]:
		var label: String = pair[0]
		pause_panel.visible = true
		var modal: Control = _hud.get(pair[1])
		check(modal != null, "The %s modal exists under the HUD" % label)
		if not modal:
			continue
		match label:
			"leaderboard":
				_hud.open_leaderboard("pause")
			"codex":
				_hud.open_codex("pause")
			"hero":
				_hud.open_character_select("pause")
		check(modal.visible, "The %s modal opens from the pause menu" % label)
		check(not pause_panel.visible, "The pause panel steps aside for the %s modal" % label)
		if modal.has_method("close_ui"):
			modal.close_ui()
		elif modal.has_method("close"):
			modal.close()
		check(not modal.visible, "The %s modal closes" % label)
		check(pause_panel.visible, "The pause panel returns after the %s modal closes" % label)

	# A combat-escape flow that used to run through the TopBar buttons.
	pause_panel.visible = false
	_hud.toggle_pause()
	check(pause_panel.visible, "The combat pause button still opens the pause menu")
	_hud.toggle_pause()
	check(not pause_panel.visible, "And still closes it")

	# Title screen: Cinzel on the title, gold CTA, and no phone-colour emoji.
	var title := TITLE_SCENE.instantiate()
	add_child(title)
	await get_tree().process_frame
	var main_title := title.find_child("MainTitle", true, false) as Label
	check(main_title != null, "The title screen has a MainTitle")
	if main_title:
		check(main_title.get_theme_font("font") == UITheme.get_display_font(),
			"MainTitle is set in the Cinzel display face")
		check(main_title.get_theme_font_size("font_size") == 52, "MainTitle is 52pt")
		check(main_title.get_theme_color("font_color") == UITheme.GOLD,
			"MainTitle is painted in gold")
	var start_button := title.find_child("StartButton", true, false) as Button
	check(start_button != null, "The title screen has a StartButton")
	if start_button:
		var cta := start_button.get_theme_stylebox("normal") as StyleBoxFlat
		check(cta != null and cta.bg_color == UITheme.GOLD,
			"The StartButton wears the gold CTA style")
	for card_name in ["HeroCard", "StageCard"]:
		var card := title.find_child(card_name, true, false) as PanelContainer
		check(card != null, "%s exists on the title screen" % card_name)
		if card:
			var panel := card.get_theme_stylebox("panel") as StyleBoxFlat
			check(panel != null and panel.bg_color == UITheme.LACQUER,
				"%s wears the lacquer card style" % card_name)

	# U+FE0F is what forces the platform's colour-emoji font; none should remain.
	for label_node in _find_labels(title):
		check(not String(label_node.text).contains("️"),
			"No variation selector survives in \"%s\"" % label_node.text)

	# Clicking a nav button must ring the tactile click, not a combat cue.
	clear_cues()
	title._on_codex_clicked()
	check(_heard("ui_click"), "A title-screen button press plays ui_click, got %s" % str(_cues))
	title.free()

	_drop_main()
	print("✔ Every moved feature round-trips from the pause menu; title screen is themed.")

func _find_labels(node: Node) -> Array[Label]:
	var out: Array[Label] = []
	for child in node.get_children():
		if child is Label:
			out.append(child)
		out.append_array(_find_labels(child))
	return out
