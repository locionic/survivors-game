extends Node

## Automated Test Suite for Expansion 47.0:
## "Đổi tướng hai lần, tốc đánh nhân đôi" -- the character bonus stacked every time
## the hero was re-selected, because the line that adds it never records what it added.
##
## player.gd:238-243, in apply_character_data():
##
##     var main_wpn = get_node_or_null("Weapons/MainWeapon")
##     if main_wpn:
##         main_wpn.set("pierce_bonus", pierce_bonus)
##         if data.has("attack_speed_bonus"):
##             main_wpn.speed_multiplier += data["attack_speed_bonus"]
##
## Two bonuses, one block, two different forms. `pierce_bonus` is set absolutely and
## is therefore idempotent. `attack_speed_bonus` is added with `+=` and is not --
## nothing in the block remembers the last value, and nothing anywhere resets the
## field, because weapon.gd:17 initialises it to 1.0 and every other writer only
## accumulates (upgrade_fire_rate's `+=`, the wave shop's `*=`).
##
## That block was only ever meant to run once per player, from _ready(). It stopped
## being the only caller when the pause menu gained a hero button:
##
##     hud.gd:245   pause_hero_button.pressed.connect(func(): open_character_select("pause"))
##
## which opens this screen mid-run, with a live player in the "player" group that
## character_select_ui.gd:325 then re-applies. Ranger's card advertises "+35% Tốc
## Đánh" ("🗡️ Thiên phú: Phi Đao xuyên thêm 1 mục tiêu, +35% Tốc Đánh"). Pause,
## switch to Ignis, switch back, and the dagger is firing at +70%. Cycle again for
## +105%. The only button that is disabled is the active hero's (character_select_ui
## .gd:309), so leaving and returning is exactly the path that is left open.
##
## The claim under test: a character's own bonus is a property of the character, not
## a count of how many times the player looked at the menu. Everything expected here
## is read out of the live weapon and out of GameManager.CHARACTERS, so no number in
## this file restates a constant that lives in the game.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const CHAR_SELECT: PackedScene = preload("res://scenes/character_select_ui.tscn")

const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.e47bak"
var _had_save: bool = false

var _failures: Array[String] = []

var _player: Player = null
var _select: Node = null

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

## The bonus the character table advertises, read from the table itself.
func _advertised_bonus(char_id: String) -> float:
	return float(GameManager.CHARACTERS.get(char_id, {}).get("attack_speed_bonus", 0.0))

## weapon.gd:17 starts the field at 1.0 and every other writer only accumulates, so
## "base plus exactly the character's advertised bonus" is the one honest value.
func _expected(char_id: String) -> float:
	return 1.0 + _advertised_bonus(char_id)

func _weapon() -> Node:
	return _player.get_node_or_null("Weapons/MainWeapon")

func _rate() -> float:
	var w = _weapon()
	return w.speed_multiplier if w else -1.0

func _select_char(_char_id: String) -> void:
	_player.apply_character_data()

func _ready() -> void:
	_backup_save()
	await _bootstrap()
	if not _failures.is_empty():
		_finish()
		return

	await _test_a_fresh_ranger_gets_exactly_the_advertised_bonus()
	await _test_reapplying_the_same_character_changes_nothing()
	await _test_cycling_away_and_back_does_not_stack()
	await _test_reapplying_does_not_erase_bought_attack_rate_cards()
	await _test_the_pause_menu_hero_button_cannot_stack_it_either()

	_finish()

func _bootstrap() -> void:
	GameManager.select_character("ranger")
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	# No extra apply_character_data() here: add_child already ran _ready(), which
	# calls it (player.gd:192). Calling it a second time is the very bug under test
	# -- the first run of this suite read 1.7 on a "fresh" ranger, 1.0 + 0.35 twice.
	_select = CHAR_SELECT.instantiate()
	add_child(_select)
	await get_tree().process_frame
	if not check(_player.is_in_group("player"), "player is in the 'player' group for the UI path"):
		return
	check(_weapon() != null, "the player owns a MainWeapon node")

## Control: the ordinary, correct first application.
func _test_a_fresh_ranger_gets_exactly_the_advertised_bonus() -> void:
	var expected := _expected("ranger")
	var actual := _rate()
	check(is_equal_approx(actual, expected),
		"a fresh ranger's dagger fires at the advertised rate (got %s, expected %s)" % [actual, expected])

## The same character selected again. Idempotence is the whole claim.
func _test_reapplying_the_same_character_changes_nothing() -> void:
	_select_char("ranger")
	var after_one := _rate()
	_select_char("ranger")
	var after_two := _rate()
	check(is_equal_approx(after_two, after_one),
		"re-applying the same character leaves the fire rate alone (was %s, now %s)" % [after_one, after_two])

## The reachable ratchet: leave the character and come back, as the pause menu allows.
func _test_cycling_away_and_back_does_not_stack() -> void:
	GameManager.select_character("pyro")
	_select_char("pyro")
	# Ignis advertises no attack-speed bonus, so the old guard -- `if data.has(...)` --
	# used to leave the incoming character's bonus sitting on the weapon untouched.
	var as_pyro := _rate()
	check(is_equal_approx(as_pyro, _expected("pyro")),
		"switching to a hero without the bonus drops the previous hero's (got %s, expected %s)" % [as_pyro, _expected("pyro")])
	GameManager.select_character("ranger")
	_select_char("ranger")
	var actual := _rate()
	var expected := _expected("ranger")
	check(is_equal_approx(actual, expected),
		"switching hero and coming back does not stack the attack-speed bonus (got %s, expected %s)" % [actual, expected])

## The guard against fixing this the wrong way. A bare `speed_multiplier = base +
## bonus` would also make cases 1-4 pass, and would silently refund every Tốc Đánh
## card the player bought, because upgrade_fire_rate accumulates into this same field.
func _test_reapplying_does_not_erase_bought_attack_rate_cards() -> void:
	var w = _weapon()
	w.speed_multiplier += 0.5
	var after_card := _rate()
	GameManager.select_character("pyro")
	_select_char("pyro")
	GameManager.select_character("ranger")
	_select_char("ranger")
	var actual := _rate()
	check(is_equal_approx(actual, after_card),
		"re-selecting a hero keeps the Tốc Đánh cards already bought (got %s, expected %s)" % [actual, after_card])

## The user path itself, not just the method: the pause menu's hero button, which is
## what hud.gd:245 wires up, going through character_select_ui's own handler.
func _test_the_pause_menu_hero_button_cannot_stack_it_either() -> void:
	if not check(_select.has_method("_on_hero_selected"), "character select exposes its hero handler"):
		return
	# The rate on entry is whatever the run has accumulated -- the Tốc Đánh card the
	# previous case bought is still on the weapon and must still be there. So the
	# invariant is that the round trip is a no-op, not that it lands on the base.
	var before := _rate()
	_select._on_hero_selected("pyro")
	var as_pyro := _rate()
	_select._on_hero_selected("ranger")
	var after := _rate()
	check(is_equal_approx(after, before),
		"the pause-menu hero button does not stack the attack-speed bonus (was %s, now %s)" % [before, after])
	check(is_equal_approx(as_pyro, before - _advertised_bonus("ranger")),
		"...and the UI path really did re-apply the character mid-round (got %s as Ignis, expected %s)" % [as_pyro, before - _advertised_bonus("ranger")])

func _finish() -> void:
	_restore_save()
	if _failures.is_empty():
		print("=== EXPANSION 47.0: ALL CHECKS PASSED ===")
		get_tree().quit(0)
	else:
		print("=== EXPANSION 47.0: %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAILED: %s" % f)
		get_tree().quit(1)
