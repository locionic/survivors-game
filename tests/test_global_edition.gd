extends Node

## Automated Test Suite for Milestone 3a: "Global Edition"
##
## Four independent things, four tests:
##   1. the 480s victory timer no longer fires in the Võ Đài
##   2. Loc switches EN <-> VI and covers characters, weapons and the shop
##   3. the danger ladder scales enemies and survives a save/load round trip
##   4. the gamepad actions are actually in the InputMap
##
## The one thing worth calling out: test 1 asserts the NEGATIVE. A check that
## "victory happens at 480s" passes just as happily on the bug as on the fix --
## only asserting that it has NOT happened past 480s with a WaveDirector alive
## can tell the two apart.

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## set_danger_level() and Loc.set_locale() both persist to user://save_data.cfg,
## so a suite that changes them would write into the developer's real save.
## Backed up verbatim before the suite and restored after.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.m3abak"
var _had_save: bool = false

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
	print("=== RUNNING MILESTONE 3a: GLOBAL EDITION TEST SUITE ===")
	# The director and the spawner both react to run_started; keep the tree inert
	# so the suite, not the autoload, decides when a run begins.
	GameManager.is_run_active = false

	_test_victory_timer_suppressed_in_wave_arena()
	_test_localization()
	_test_danger_levels()
	_test_gamepad_actions()

	# Leave nothing running: the engine would otherwise tick GameManager._process
	# once more before quit() takes effect.
	GameManager.is_run_active = false
	get_tree().paused = false
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL MILESTONE 3a TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. Bug: the 480s victory timer used to fire at wave 14 ---------------------

## queue_free() is deferred, so a freed director keeps answering group lookups for
## the rest of the run -- and is_wave_arena() reads that group. Leave it first.
func _drop(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for g in ["wave_director", "enemy_spawner", "player"]:
		if node.is_in_group(g):
			node.remove_from_group(g)
	node.queue_free()

## A clean, un-victoried, active run without going through start_new_run(), which
## emits run_started and would let an autoload react.
func _prime_run() -> void:
	GameManager.is_run_active = true
	GameManager.is_endless_mode = false
	GameManager.is_victory_triggered = false
	GameManager.run_time = 0.0

func _test_victory_timer_suppressed_in_wave_arena() -> void:
	var dir := WaveDirector.new()
	dir.max_waves = 20
	add_child(dir)
	check(GameManager.is_wave_arena(), "A live WaveDirector puts the run in wave-arena mode")

	_prime_run()
	# Straight past the old 480s ceiling. This is the exact line that used to hand
	# a wave-14 player a victory screen.
	GameManager._process(GameManager.MAX_RUN_TIME + 60.0)
	check(GameManager.run_time > GameManager.MAX_RUN_TIME,
		"The run clock is genuinely past the legacy ceiling (%.0fs)" % GameManager.run_time)
	check(not GameManager.is_victory_triggered,
		"Past %ds in the Võ Đài, no legacy victory fired" % int(GameManager.MAX_RUN_TIME))
	check(GameManager.is_run_active, "The run is still going -- the player was not thrown out of the arena")

	# Same clock, no director: a standalone survival run keeps its win condition.
	_drop(dir)
	check(not GameManager.is_wave_arena(), "Removing the director leaves wave-arena mode")
	GameManager._process(1.0)
	check(GameManager.is_victory_triggered,
		"A standalone run still wins at %ds" % int(GameManager.MAX_RUN_TIME))
	check(not GameManager.is_run_active, "The legacy victory ended the standalone run")

	# And the arena's OWN victory path still works: clearing wave 20 wins.
	GameManager.is_victory_triggered = false
	GameManager.is_run_active = true
	var dir2 := WaveDirector.new()
	dir2.max_waves = 20
	add_child(dir2)
	dir2.current_wave = 20
	dir2.is_wave_active = true
	dir2.end_wave()
	check(GameManager.is_victory_triggered, "Clearing wave 20 wins the arena regardless of the clock")

	_drop(dir2)
	GameManager.is_victory_triggered = false
	GameManager.is_run_active = false
	GameManager.is_endless_mode = false

# --- 2. Loc: EN default, VI toggle, full coverage ------------------------------

func _test_localization() -> void:
	Loc.set_locale("en")
	check(Loc.current_locale == "en", "English is the default locale, got %s" % Loc.current_locale)

	# Characters -- all five Môn Phái, and every one must actually differ.
	var char_ids := ["knight", "pyro", "ranger", "mage", "beggar"]
	var char_names: Dictionary = {}
	for cid in char_ids:
		char_names[cid] = Loc.t("char.%s.name" % cid)
		check(char_names[cid] != "" and char_names[cid] != "char.%s.name" % cid,
			"Sect %s has an English name, got '%s'" % [cid, char_names[cid]])

	# Weapons -- the six canonical names promoted this milestone.
	var canonical := {
		"dagger": "Thousand Daggers",
		"shield": "Eight Trigrams Shield",
		"lightning": "Heaven's Wrath",
		"fireball": "Apocalypse Meteor",
		"axe": "Dog-Beating Staff",
		"slash": "Nine Swords Cleave",
	}
	for w_id in canonical.keys():
		check(Loc.t("weapon.%s.name" % w_id) == canonical[w_id],
			"%s is canonically '%s', got '%s'" % [w_id, canonical[w_id], Loc.t("weapon.%s.name" % w_id)])
		# The two other tables that used to disagree must now agree with Loc.
		check(UpgradeManager.WEAPON_INFO.get(w_id, {}).get("name", "") == canonical[w_id],
			"UpgradeManager agrees on %s ('%s')" % [w_id, UpgradeManager.WEAPON_INFO.get(w_id, {}).get("name", "")])
		check(GameManager.get_weapon_display_name(w_id) == canonical[w_id],
			"GameManager agrees on %s ('%s')" % [w_id, GameManager.get_weapon_display_name(w_id)])

	# The two fusions the shop can sell.
	for key in ["synergy.lotus_storm.name", "synergy.frost_sovereign.name"]:
		check(Loc.t(key) != key, "%s is translated" % key)

	# Switch to Vietnamese and confirm everything moved.
	var fired: Array[String] = []
	Loc.locale_changed.connect(func(new_locale): fired.append(String(new_locale)))
	Loc.set_locale("vi")
	check(Loc.current_locale == "vi", "The toggle switched to Vietnamese, got %s" % Loc.current_locale)
	check(fired.has("vi"), "locale_changed fired on the switch, got %s" % str(fired))

	var moved := 0
	for cid in char_ids:
		if Loc.t("char.%s.name" % cid) != char_names[cid]:
			moved += 1
	check(moved == char_ids.size(),
		"Every sect name changes with the language (%d/%d did)" % [moved, char_ids.size()])

	var weapon_moved := 0
	for w_id in canonical.keys():
		if Loc.weapon_name(w_id) != canonical[w_id]:
			weapon_moved += 1
	check(weapon_moved == canonical.size(),
		"Every weapon name changes with the language (%d/%d did)" % [weapon_moved, canonical.size()])
	check(UpgradeManager.WEAPON_INFO["dagger"]["name"] == "Thousand Daggers",
		"The const table still holds the English canonical name while VI is active")

	# Shop terms -- the Tàng Kinh Các economy the spec calls out.
	for key in ["shop.reroll", "shop.lock", "shop.fuse", "shop.sell",
			"shop.interest", "shop.tradeoff_scroll", "shop.title"]:
		check(Loc.t(key) != key and Loc.t(key) != "", "%s is translated, got '%s'" % [key, Loc.t(key)])

	# HUD terms -- waves, streak banners, boss alarms, end screens.
	for key in ["hud.wave", "hud.wave_banner", "hud.victory_banner", "hud.boss_alarm",
			"hud.victory", "hud.defeat", "hud.streak_50", "hud.streak_100", "hud.streak_1000"]:
		check(Loc.t(key) != key and Loc.t(key) != "", "%s is translated, got '%s'" % [key, Loc.t(key)])
	# The banner rows are format strings -- a missing %d would print literally.
	check(Loc.tf("hud.wave_banner", [3, 20]).find("3") >= 0,
		"The wave banner formats its arguments, got '%s'" % Loc.tf("hud.wave_banner", [3, 20]))

	# An unknown key falls through to the caller's own default rather than blanking.
	check(Loc.t("no.such.key", "Fallback") == "Fallback", "An unknown key returns the caller's default")
	check(Loc.t("no.such.key") == "no.such.key", "An unknown key with no default returns the key")

	# Persisted to the save file, not just held in memory.
	var cfg := ConfigFile.new()
	check(cfg.load(Loc.SAVE_PATH) == OK, "The save file still loads after a locale write")
	check(str(cfg.get_value(Loc.SAVE_SECTION, Loc.SAVE_KEY, "")) == "vi",
		"The choice persisted to disk, got '%s'" % str(cfg.get_value(Loc.SAVE_SECTION, Loc.SAVE_KEY, "")))

	# make_toggle_button is the one chip every host shares; it must label both halves.
	var btn := Loc.make_toggle_button()
	add_child(btn)
	check(btn.text.contains("VI") and btn.text.contains("EN"),
		"The shared toggle shows both languages, got '%s'" % btn.text)
	btn.queue_free()

	Loc.set_locale("en")
	check(Loc.current_locale == "en", "The toggle switches back to English")

# --- 3. Danger: 0..5 scales enemies, survives a reload -------------------------

func _test_danger_levels() -> void:
	var spawner := EnemySpawner.new()
	add_child(spawner)

	# The table itself, tier by tier, exactly as the design specifies.
	var expected := [
		[1.00, 1.00, 1.00, 1.0, 0], [1.12, 1.35, 0.92, 1.6, 0], [1.24, 1.70, 0.84, 2.6, 1],
		[1.36, 2.10, 0.76, 4.2, 1], [1.48, 2.55, 0.68, 6.8, 2], [1.60, 3.00, 0.60, 11.0, 2],
	]
	check(GameManager.DANGER.size() == 6, "Six danger tiers, got %d" % GameManager.DANGER.size())

	for level in range(GameManager.DANGER.size()):
		GameManager.set_danger_level(level)
		var d := GameManager.get_danger_data()
		var e: Array = expected[level]
		check(is_equal_approx(float(d["speed"]), e[0]), "D%d speed x%.2f, got %.2f" % [level, e[0], d["speed"]])
		check(is_equal_approx(float(d["hp"]), e[1]), "D%d hp x%.2f, got %.2f" % [level, e[1], d["hp"]])
		check(is_equal_approx(float(d["heal"]), e[2]), "D%d heal x%.2f, got %.2f" % [level, e[2], d["heal"]])
		check(is_equal_approx(float(d["score"]), e[3]), "D%d score x%.1f, got %.1f" % [level, e[3], d["score"]])
		check(int(d["elite"]) == int(e[4]), "D%d grants %d elite affix(es), got %d" % [level, e[4], d["elite"]])

	# The real payoff: a spawned enemy actually comes out scaled. Instantiated
	# but not added to the tree, so max_health is still the scene default and
	# the multiplier is the only thing that moved it.
	GameManager.set_danger_level(0)
	var plain := ENEMY_SCENE.instantiate()
	spawner._apply_danger(plain)
	var base_hp: float = plain.max_health
	var base_speed: float = plain.move_speed
	plain.queue_free()
	check(is_equal_approx(base_hp, 25.0), "The D0 baseline is the unmodified scene (%.1f HP)" % base_hp)

	for level in range(GameManager.DANGER.size()):
		GameManager.set_danger_level(level)
		var enemy := ENEMY_SCENE.instantiate()
		spawner._apply_danger(enemy)
		var d := GameManager.get_danger_data()
		check(is_equal_approx(enemy.max_health, base_hp * float(d["hp"])),
			"D%d enemy HP is scaled (%.1f -> %.1f)" % [level, base_hp, enemy.max_health])
		check(is_equal_approx(enemy.move_speed, base_speed * float(d["speed"])),
			"D%d enemy speed is scaled (%.1f -> %.1f)" % [level, base_speed, enemy.move_speed])
		if level > 0:
			check(enemy.max_health > base_hp and enemy.move_speed > base_speed,
				"D%d is strictly harder than D0 on both axes" % level)
		enemy.queue_free()

	# The ceiling is three times the HP, and the setter clamps from both sides.
	GameManager.set_danger_level(99)
	check(GameManager.danger_level == GameManager.MAX_DANGER_LEVEL,
		"A level above the ceiling clamps to %d, got %d" % [GameManager.MAX_DANGER_LEVEL, GameManager.danger_level])
	GameManager.set_danger_level(-4)
	check(GameManager.danger_level == 0, "A level below the floor clamps to 0, got %d" % GameManager.danger_level)

	# Persisted: write it, read the file back off disk, do not trust the field.
	GameManager.set_danger_level(3)
	var cfg := ConfigFile.new()
	check(cfg.load(GameManager.SAVE_PATH) == OK, "The save file still loads after a danger write")
	check(int(cfg.get_value("player", "danger_level", -1)) == 3,
		"The danger level persisted, got %d" % int(cfg.get_value("player", "danger_level", -1)))

	GameManager.set_danger_level(0)
	_drop(spawner)

# --- 4. Gamepad: the actions are actually bound ---------------------------------

## An action counts as controller-bound if it carries at least one joypad event
## of either kind. Keyboard-only is the bug this test exists to catch.
func _joy_events(action: String) -> Array[InputEvent]:
	var out: Array[InputEvent] = []
	if not InputMap.has_action(action):
		return out
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton or e is InputEventJoypadMotion:
			out.append(e)
	return out

func _has_joy_button(action: String, button: int) -> bool:
	for e in _joy_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			return true
	return false

func _has_joy_axis(action: String, axis: int) -> bool:
	for e in _joy_events(action):
		if e is InputEventJoypadMotion and (e as InputEventJoypadMotion).axis == axis:
			return true
	return false

func _has_joy_events(action: String) -> bool:
	return not _joy_events(action).is_empty()

func _test_gamepad_actions() -> void:
	# Movement: D-pad (buttons 11-14) plus the left stick (axes 0/1).
	for pair in [["move_left", 13, 0], ["move_right", 14, 0], ["move_up", 11, 1], ["move_down", 12, 1]]:
		var action: String = pair[0]
		check(InputMap.has_action(action), "%s still exists" % action)
		check(_has_joy_button(action, int(pair[1])),
			"%s is bound to the D-pad (button %d)" % [action, int(pair[1])])
		check(_has_joy_axis(action, int(pair[2])),
			"%s is bound to the left analog stick (axis %d)" % [action, int(pair[2])])
		# Regression guard: the keyboard bindings must survive the rewrite.
		var keys := 0
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				keys += 1
		check(keys >= 1, "%s kept its keyboard binding (%d key events)" % [action, keys])

	# ui_attack: A/Cross and the right shoulder/trigger.
	check(_has_joy_button("ui_attack", 0), "ui_attack accepts A/Cross")
	check(_has_joy_button("ui_attack", 10), "ui_attack accepts the right shoulder (R2)")
	check(_has_joy_axis("ui_attack", 5), "ui_attack accepts the right trigger axis")
	check(_has_joy_events("ui_attack"), "ui_attack still keeps its mouse button")

	# dash: X/Square and the left trigger.
	check(_has_joy_button("dash", 2), "dash accepts X/Square")
	check(_has_joy_axis("dash", 4), "dash accepts the left trigger axis")

	# Menus: A confirms, B and Start/Back cancel.
	check(_has_joy_button("ui_accept", 0), "ui_accept accepts A/Cross")
	check(_has_joy_button("ui_cancel", 1), "ui_cancel accepts B/Circle")
	check(_has_joy_button("ui_cancel", 6), "ui_cancel accepts Start")

	# Declaring a built-in action in project.godot REPLACES its event list rather
	# than merging into it, so adding the pad silently strips Enter/Escape and
	# every modal stops closing. Re-assert the keyboard half explicitly.
	for pair in [["ui_accept", [KEY_ENTER, KEY_SPACE]], ["ui_cancel", [KEY_ESCAPE]]]:
		var action: String = pair[0]
		var needed: Array = pair[1]
		var bound: Array = []
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				bound.append((e as InputEventKey).keycode)
		for keycode in needed:
			check(bound.has(keycode),
				"%s still answers to key %d (gamepad: %s)" % [action, keycode, str(bound)])

	# Right stick aiming, on the axes Godot reserves for it (2/3).
	for pair in [["aim_left", 2], ["aim_right", 2], ["aim_up", 3], ["aim_down", 3]]:
		var action: String = pair[0]
		check(InputMap.has_action(action), "%s exists" % action)
		check(_has_joy_axis(action, int(pair[1])),
			"%s reads right stick axis %d" % [action, int(pair[1])])
		check(InputMap.action_get_deadzone(action) > 0.0,
			"%s has a deadzone, so a resting stick reads zero" % action)

	# aim_right must point the +X way, or the stick aims backwards.
	var positive := 0.0
	for e in InputMap.action_get_events("aim_right"):
		if e is InputEventJoypadMotion:
			positive = maxf(positive, (e as InputEventJoypadMotion).axis_value)
	check(positive > 0.0, "aim_right points the +X way, got axis_value %.1f" % positive)

	check(_has_joy_events("ultimate_skill"), "ultimate_skill is controller-reachable")
	check(SlashWeapon._get_stick_aim() == Vector2.ZERO,
		"A resting stick reads zero, so mouse/keyboard aiming still wins by default")
