extends Node

## Automated Test Suite for Expansion 22.0:
## "Võ Lâm Tín Cận" -- stats the player paid for stop disappearing, and the two
## Codex relics that were described to the player and never implemented.
##
## Both halves are regression tests over bugs that were live and silent, not over
## new tuning, so the assertions are deliberately strict:
##   * refresh_meta_stats() is reachable MID-RUN from the pause-menu meta shop, and
##     it rebuilds four headline stats. Anything a run-scoped source wrote straight
##     onto the live stat was refunded to zero on the next Vitality purchase.
##   * skill_cooldown_max was derived from its own previous value, so every meta
##     purchase -- including ones that touch no cooldown at all -- compounded it.
##   * Tà Ma Lệnh Bài and Huyết Ma Kiếm were registered in the Codex with full
##     descriptions and had no effect anywhere in the codebase.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## buy_meridian_upgrade() persists to user://save_data.cfg immediately, so this
## suite would spend the developer's real meta gold. Backed up and restored.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.m22bak"
var _had_save: bool = false

var _relics_backup: Array = []
var _meridians_backup: Dictionary = {}
var _meta_backup: Dictionary = {}
var _slots_backup: Dictionary = {}
var _player: Player = null

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

## enemy.take_damage() carries two other riders that fire on the SAME hit: the
## Storm Amulet's 25% lightning proc and Lôi Hỏa Liên Hoàn's crit burst. Both are
## real, both are correct, and both would make this suite measure the save file of
## whoever ran the sweep before it -- a prior suite persists collected_relics to
## user://save_data.cfg, so the reload hands a fresh process a Storm Amulet and
## every crit test starts failing for a reason that has nothing to do with them.
func _pin_damage_side_procs() -> void:
	GameManager.collected_relics.erase("storm_amulet")

func _ready() -> void:
	_backup_save()
	print("=== RUNNING EXPANSION 22.0 TEST SUITE ===")
	# Keep the tree inert so the suite, not the autoload, decides when a run runs.
	GameManager.is_run_active = false

	_relics_backup = GameManager.collected_relics.duplicate()
	_meridians_backup = GameManager.meridian_upgrades.duplicate()
	_meta_backup = GameManager.meta_upgrades.duplicate()
	_slots_backup = GameManager.equipment_slots.duplicate()
	_pin_damage_side_procs()

	await _test_run_bought_max_hp_survives_a_meta_refresh()
	await _test_hermit_percentage_max_hp_survives_too()
	await _test_shop_scrolls_survive_a_meta_refresh()
	await _test_skill_cooldown_does_not_compound()
	await _test_equipped_sword_might_is_not_deleted()
	await _test_demonic_token_rages_below_half_hp()
	await _test_blood_blade_lifesteals()
	await _test_relics_are_inert_when_not_collected()

	_drop(_player)
	GameManager.collected_relics = _relics_backup
	GameManager.meridian_upgrades = _meridians_backup
	GameManager.meta_upgrades = _meta_backup
	GameManager.equipment_slots = _slots_backup
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 22.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the Shenron's +100 HP is still there after a meta purchase ------------

## The original bug in one shape. The player spends a Shenron wish, then opens the
## pause-menu meta shop and buys a single Vitality level. refresh_meta_stats()
## rebuilt max_health from 100 + char + vitality, and the +100 was gone -- refunded
## as though the wish had never been made.
func _test_run_bought_max_hp_survives_a_meta_refresh() -> void:
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	GameManager.meta_upgrades.erase("vitality")
	GameManager.meridian_upgrades.erase("vitality")
	_player.refresh_meta_stats()
	_player.current_health = _player.max_health

	var base_max := _player.max_health
	_player.add_run_max_hp(100.0)
	check(is_equal_approx(_player.max_health, base_max + 100.0),
		"A +100 run bonus lifts max HP immediately (%s -> %s)" % [base_max, _player.max_health])

	# Buy a Vitality level for free -- this is the recompute that used to erase it.
	GameManager.meta_upgrades["vitality"] = int(GameManager.meta_upgrades.get("vitality", 0)) + 1
	_player.refresh_meta_stats()
	var expected := base_max + 125.0
	check(is_equal_approx(_player.max_health, expected),
		"The +100 survives a meta refresh (expected %s, got %s)" % [expected, _player.max_health])

	GameManager.meta_upgrades.erase("vitality")
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.max_health, base_max + 100.0),
		"...and survives the refresh that drops the Vitality back down, got %s" % _player.max_health)

	_player.add_run_max_hp(-100.0)
	check(is_equal_approx(_player.max_health, base_max),
		"Removing the run bonus returns the stat to its base, got %s" % _player.max_health)

## The hermit's +15% is the multiplicative one, and it is the shape that hides:
## a run bonus expressed as a *share* of the current max cannot be stored as a
## percentage of anything the recompute does not know about.
func _test_hermit_percentage_max_hp_survives_too() -> void:
	var base_max := _player.max_health
	_player.apply_hermit_item("cuu_chuyen_dan")
	var blessed := _player.max_health
	check(is_equal_approx(blessed, base_max * 1.15),
		"Cửu Chuyển Hoàn Hồn is +15%% of the max it had (%s -> %s)" % [base_max, blessed])

	GameManager.meta_upgrades["vitality"] = 3
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.max_health, blessed + 75.0),
		"The hermit's +15%% is still counted after a meta refresh (expected %s, got %s)" % [blessed + 75.0, _player.max_health])
	GameManager.meta_upgrades.erase("vitality")
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.max_health, blessed),
		"...and is unchanged when the Vitality levels are taken back, got %s" % _player.max_health)

# --- 2. the wave shop's scrolls are run-scoped, not meta-scoped --------------

## Every Tàng Kinh Các scroll writes to one of the four recomputed stats. The shop
## is opened by the director between waves and the meta shop by the pause menu, so
## one run touches both. The scroll must not refund itself.
func _test_shop_scrolls_survive_a_meta_refresh() -> void:
	_player.apply_shenron_wish("wish_immortality")
	var blessing := _player.max_health
	_player.add_run_crit(0.35)
	var crit := _player.crit_chance_bonus
	var speed := _player.move_speed

	# Three different triggers of the same recompute: a speed scroll, a meridian
	# purchase, and a plain refresh. One guarantee across all of them.
	_player.multiply_run_speed(0.90)
	check(_player.move_speed < speed, "A -10%% speed scroll slows the player, got %s" % _player.move_speed)
	GameManager.meridian_upgrades["doc_mach"] = 4
	_player.refresh_meta_stats()

	check(is_equal_approx(_player.max_health, blessing),
		"A +100 Max HP blessing survives a refresh, got %s" % _player.max_health)
	check(is_equal_approx(_player.crit_chance_bonus, crit + 0.28),
		"A +35%% crit scroll stacks on top of Đốc Mạch (expected %s, got %s)" % [crit + 0.28, _player.crit_chance_bonus])
	GameManager.meridian_upgrades.erase("doc_mach")
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.crit_chance_bonus, crit),
		"...and keeps its value when Đốc Mạch is dropped (expected %s, got %s)" % [crit, _player.crit_chance_bonus])
	check(_player.move_speed < speed, "...and the speed penalty is still applied, got %s" % _player.move_speed)
	_player.add_run_crit(-0.35)

# --- 3. the skill cooldown used to compound ---------------------------------

## buy_meridian_upgrade() calls refresh_meta_stats() for EVERY meridian, including
## Đốc Mạch and Đan Điền, which have nothing to do with the skill. The old line read
## `skill_cooldown_max * (1 - xung * 0.08)` -- its own output -- so ten unrelated
## purchases at 0.92 each left the player with a 2.4s timer off a 5.5s base.
##
## The 0.5 below is Expansion 39.0, and it used to be 0.6. That is not a second bug
## fix in this suite -- it is this suite having been the other half of one. The
## meridian row says "-10% Cooldown"; the line applied 0.08; and the assertion here
## was written from the line rather than from the row, so it agreed with the code
## and the two of them were wrong together. The compounding checks below it compare
## against `bought`, which is read back from the player, so they were always
## rate-agnostic and are unchanged -- only the number this one pins moved.
func _test_skill_cooldown_does_not_compound() -> void:
	GameManager.meridian_upgrades.erase("xung_mach")
	_player.refresh_meta_stats()
	var base := _player.skill_cooldown_base
	check(is_equal_approx(_player.skill_cooldown_max, base),
		"Precondition: no Xung Mạch means the timer is the character's own, got %s" % _player.skill_cooldown_max)

	GameManager.meridian_upgrades["xung_mach"] = 5
	_player.refresh_meta_stats()
	var bought := _player.skill_cooldown_max
	check(is_equal_approx(bought, base * 0.5),
		"5 ranks of Xung Mạch cut the timer by 50%% once, as its row advertises (expected %s, got %s)" % [base * 0.5, bought])

	for i in 20:
		_player.refresh_meta_stats()
	check(is_equal_approx(_player.skill_cooldown_max, bought),
		"20 unrelated refreshes leave the timer where it was bought (expected %s, got %s)" % [bought, _player.skill_cooldown_max])

	# The real purchase path, not just the recompute.
	var before := _player.skill_cooldown_max
	GameManager.total_gold = 999999
	GameManager.buy_meridian_upgrade("dan_dien")
	check(is_equal_approx(_player.skill_cooldown_max, before),
		"Buying Đan Điền (an unrelated meridian) does not discount the skill, got %s" % _player.skill_cooldown_max)

	GameManager.meridian_upgrades.erase("xung_mach")
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.skill_cooldown_max, base),
		"Dropping Xung Mạch restores the base timer, got %s" % _player.skill_cooldown_max)

# --- 4. the equipped sword's +15% might used to be erased too ----------------

## Ỷ Thiên Kiếm's bonus used to be added at the tail of refresh_meta_stats(), so any
## helper that rebuilt the stat without that tail silently deleted an equipped weapon.
func _test_equipped_sword_might_is_not_deleted() -> void:
	GameManager.equipment_slots.erase("weapon")
	_player.refresh_meta_stats()
	var bare := _player.meta_might_bonus
	GameManager.equipment_slots["weapon"] = "y_thien_kiem"
	_player.refresh_meta_stats()
	var with_sword := _player.meta_might_bonus
	check(is_equal_approx(with_sword, bare + 0.15),
		"Ỷ Thiên Kiếm is worth +15%% might (expected %s, got %s)" % [bare + 0.15, with_sword])

	_player.add_run_might(0.30)
	check(is_equal_approx(_player.meta_might_bonus, with_sword + 0.30),
		"A +30%% might scroll lands on top of the sword (expected %s, got %s)" % [with_sword + 0.30, _player.meta_might_bonus])
	_player.add_run_might(-0.30)
	check(is_equal_approx(_player.meta_might_bonus, with_sword),
		"...and undoing the scroll leaves the sword's bonus intact (expected %s, got %s)" % [with_sword, _player.meta_might_bonus])

# --- 5. Tà Ma Lệnh Bài: +25% crit damage, +15% attack speed under 50% HP ----

## The relic was registered in codex_manager._register_codex_relic() with this exact
## description and a Codex quest behind it, and had no effect anywhere: the crit
## multiplier was the bare literal 2.2 in enemy.take_damage() with no term for it.
func _test_demonic_token_rages_below_half_hp() -> void:
	GameManager.collected_relics.erase("demonic_token")
	_player.current_health = _player.max_health
	_player.refresh_meta_stats()
	check(_player.get_crit_damage_multiplier() == 1.0,
		"Without the relic, crit damage is the engine's 2.2, got %f" % _player.get_crit_damage_multiplier())
	check(_player.get_attack_speed_multiplier() == 1.0,
		"Without the relic, attack speed is unmodified, got %f" % _player.get_attack_speed_multiplier())

	GameManager.collected_relics.append("demonic_token")
	_player.current_health = _player.max_health
	check(not _player.is_demonic_rage_active(), "At full HP the relic is dormant")
	check(_player.get_crit_damage_multiplier() == 1.0,
		"At full HP the relic grants no crit damage, got %f" % _player.get_crit_damage_multiplier())
	check(_player.get_attack_speed_multiplier() == 1.0,
		"At full HP the relic grants no attack speed, got %f" % _player.get_attack_speed_multiplier())

	# Exactly half. "Below 50%" has to mean what it says.
	_player.current_health = _player.max_health * 0.50
	check(_player.is_demonic_rage_active(), "At exactly 50%% HP the relic is awake")
	check(is_equal_approx(_player.get_crit_damage_multiplier(), 1.25),
		"The relic is worth +25%% crit damage, got %f" % _player.get_crit_damage_multiplier())
	check(is_equal_approx(_player.get_attack_speed_multiplier(), 1.15),
		"The relic is worth +15%% attack speed, got %f" % _player.get_attack_speed_multiplier())

	# A getter, not a latch: sitting under the threshold must not compound it.
	for i in 60:
		_player.get_attack_speed_multiplier()
		_player.get_crit_damage_multiplier()
	check(is_equal_approx(_player.get_attack_speed_multiplier(), 1.15),
		"60 reads while raging do not compound the haste, got %f" % _player.get_attack_speed_multiplier())
	check(is_equal_approx(_player.get_crit_damage_multiplier(), 1.25),
		"...nor the crit damage, got %f" % _player.get_crit_damage_multiplier())

	_player.current_health = _player.max_health * 0.80
	check(not _player.is_demonic_rage_active(), "Recovering past the threshold puts the relic back to sleep")
	check(_player.get_crit_damage_multiplier() == 1.0 and _player.get_attack_speed_multiplier() == 1.0,
		"...and the bonuses go with it, got %f / %f" % [_player.get_crit_damage_multiplier(), _player.get_attack_speed_multiplier()])

	# The relic has to reach the one crit roll in the game, so drive a real one:
	# 100% crit, 200 incoming, and read the HP the victim actually lost.
	_player.current_health = _player.max_health
	_player.crit_chance_bonus = 10.0
	var calm := _spawn_enemy(Vector2(200, 0), 2000.0)
	calm.take_damage(200.0, Vector2.ZERO)
	var calm_lost := 2000.0 - float(calm.current_health)
	calm.queue_free()

	_player.current_health = _player.max_health * 0.25
	var raging := _spawn_enemy(Vector2(220, 0), 2000.0)
	raging.take_damage(200.0, Vector2.ZERO)
	var rage_lost := 2000.0 - float(raging.current_health)
	raging.queue_free()

	check(is_equal_approx(calm_lost, 200.0 * 2.2),
		"A calm 200-damage crit for 440 (2.2x), got %s" % calm_lost)
	check(is_equal_approx(rage_lost, 200.0 * 2.2 * 1.25),
		"The same crit while raging for 550 (2.2 x 1.25), got %s" % rage_lost)

# --- 6. Huyết Ma Kiếm: 4% lifesteal ----------------------------------------

## Also registered with a description ("4% Life-Steal on hit") and a Codex quest,
## and enemy.take_damage() -- the only place lifesteal is read -- never looked at it.
func _test_blood_blade_lifesteals() -> void:
	GameManager.collected_relics.erase("blood_blade")
	GameManager.collected_relics.erase("demonic_token")
	_player.shop_lifesteal = 0.0
	_player.char_lifesteal_bonus = 0.0
	# Crits are forced ON and the expectation below is computed from the crit's real
	# damage. This used to leave crit_chance_bonus at 0, which leaves the 12% base crit
	# chance live in enemy.take_damage() -- so roughly one hit in eight came out as a
	# 2.2x crit, the lifesteal correctly paid 4% of THAT, and the assertion, which
	# assumed a plain 100-damage hit, failed about one gate run in ten. The product was
	# right; the expectation was not.
	_player.crit_chance_bonus = 10.0
	_player.current_health = _player.max_health * 0.5

	var victim := _spawn_enemy(Vector2(200, 0), 2000.0)
	var before := _player.current_health
	victim.take_damage(100.0, Vector2.ZERO)
	check(is_equal_approx(_player.current_health, before),
		"Without the relic a 100-damage hit heals nothing, got %s" % (_player.current_health - before))
	victim.queue_free()

	GameManager.collected_relics.append("blood_blade")
	var blade := _spawn_enemy(Vector2(200, 0), 2000.0)
	before = _player.current_health
	blade.take_damage(100.0, Vector2.ZERO)
	var healed := _player.current_health - before
	# 4% of the damage actually dealt -- which here is a guaranteed crit, so the 2.2x
	# crit multiplier and any Đốc Mạch crit bonus both belong in the expectation.
	# Read the crit multiplier off the player rather than assuming 1.0, or a save with
	# meridian ranks in it fails a build that is behaving correctly.
	var dealt: float = 100.0 * 2.2 * _player.get_crit_damage_multiplier()
	check(is_equal_approx(healed, dealt * Player.RELIC_LIFESTEAL),
		"Huyết Ma Kiếm returns exactly 4%% of the damage dealt (expected %s, got %s)" % [dealt * Player.RELIC_LIFESTEAL, healed])
	blade.queue_free()

# --- 7. and neither of them fires when the player does not own them ----------

## The mirror of 5 and 6, because a relic that is always-on is worse than one that
## is never-on: it would make the Codex quests meaningless.
func _test_relics_are_inert_when_not_collected() -> void:
	GameManager.collected_relics.erase("demonic_token")
	GameManager.collected_relics.erase("blood_blade")
	_player.current_health = _player.max_health * 0.05
	check(_player.get_crit_damage_multiplier() == 1.0,
		"Uncollected Tà Ma Lệnh Bài grants no crit damage at 5%% HP, got %f" % _player.get_crit_damage_multiplier())
	check(_player.get_attack_speed_multiplier() == 1.0,
		"Uncollected Tà Ma Lệnh Bài grants no haste at 5%% HP, got %f" % _player.get_attack_speed_multiplier())
	_player.current_health = _player.max_health

# --- helpers ----------------------------------------------------------------

func _spawn_enemy(at: Vector2, hp: float) -> Node2D:
	_pin_damage_side_procs()
	_player.has_thunderfire = false
	var e := ENEMY_SCENE.instantiate() as Node2D
	e.player = _player
	add_child(e)
	e.global_position = at
	e.current_health = hp
	e.set_physics_process(false)
	return e

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()
