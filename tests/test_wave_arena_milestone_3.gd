extends Node

## Automated Test Suite for Milestone 3: "Võ Lâm Cộng Hưởng & Đấu Trường Hoàn Thiện"
## The two passive martial synergies and the intermission shop's sound feedback.
##
## The interesting part of Milestone 3 is not the two damage effects, it is the
## handoff: a weapon bought at the shop has to reach the player and flip the
## synergy there. So the suite drives the real UpgradeManager and the real
## WaveShopUI rather than poking the flags directly.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const SHOP_SCENE: PackedScene = preload("res://scenes/wave_shop_ui.tscn")

## Godot's assert() only logs a SCRIPT ERROR and keeps running -- the process
## still exits 0, so a suite built on it can never fail a regression run. This
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## add_gold() persists to user://save_data.cfg immediately, so a suite that spends
## gold at the shop would write into the developer's real save. Backed up verbatim
## before the suite and restored after.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.m3bak"
var _had_save: bool = false

## Cues fired since the last clear_cues(), read off SoundManager's sfx_played signal.
var _cues: Array[String] = []

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

func _ready() -> void:
	_backup_save()
	print("=== RUNNING MILESTONE 3: VÕ LÂM CỘNG HƯỞNG & ĐẤU TRƯỜNG HOÀN THIỆN TEST SUITE ===")
	# The director and the shop both react to run_started; keep the tree inert so
	# the suite, not the autoload, decides when a wave begins.
	GameManager.is_run_active = false
	SoundManager.connect("sfx_played", func(cue): _cues.append(String(cue)))

	_test_synergy_unlock()
	_test_starting_loadouts()
	_test_thunderfire_burst()
	_test_sword_qi()
	_test_sword_qi_homing()
	_test_shop_feedback()
	_test_shop_purchase_unlocks_synergy()

	get_tree().paused = false
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL MILESTONE 3 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

func _any(arr: Array, pred: Callable) -> bool:
	for item in arr:
		if pred.call(item):
			return true
	return false

## queue_free() is deferred, so a "freed" node keeps answering group lookups for the
## rest of the run. enemy.gd binds its lifesteal, burn and crit riders to
## get_first_node_in_group("player") in _ready(), and the shop resolves
## wave_director / upgrade_manager the same way -- a stale node silently starves the
## next case. Leave the groups first, then free.
func _drop(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for g in ["player", "wave_director", "enemy_spawner", "enemies", "elite_champions", "bosses", "upgrade_manager", "projectiles"]:
		if node.is_in_group(g):
			node.remove_from_group(g)
	node.queue_free()

func _clear_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("elite_champions"):
		_drop(e)

func _clear_projectiles() -> void:
	for s in get_tree().get_nodes_in_group("projectiles"):
		_drop(s)

func _spawn_as(char_id: String) -> Player:
	GameManager.select_character(char_id)
	var p := PLAYER_SCENE.instantiate() as Player
	add_child(p)
	return p

func _spawn_enemy(at: Vector2) -> Node2D:
	var e := ENEMY_SCENE.instantiate() as Node2D
	e.global_position = at
	add_child(e)
	return e

func clear_cues() -> void:
	_cues.clear()

func _heard(cue: String) -> bool:
	return _cues.has(cue)

# --- 1. The pairings unlock on exactly the right half-set ---------------------

func _test_synergy_unlock() -> void:
	# Tiêu Dao's ranger starts with a bare dagger: one half of each pairing, so
	# neither passive may be live at spawn.
	var p := _spawn_as("ranger")
	check(not p.has_thunderfire, "A lone dagger unlocks neither synergy")
	check(not p.has_thousand_swords, "A lone dagger does not unlock Vạn Kiếm Quy Tông")

	# Fireball alone is still half a pairing.
	p.activate_weapon("fireball")
	check(not p.has_thunderfire, "Fireball without lightning does not unlock Lôi Hỏa Liên Hoàn")

	# ...and lightning is the half that completes it.
	p.activate_weapon("lightning")
	check(p.has_thunderfire, "Fireball + lightning unlocks Lôi Hỏa Liên Hoàn")
	check(is_equal_approx(p.thunderfire_cd, 0.0), "The thunderfire cooldown starts clear")

	# Dagger is already in hand, so the blade is the only missing half.
	check(not p.has_thousand_swords, "Dagger without the blade has no Vạn Kiếm Quy Tông")
	p.activate_weapon("slash")
	check(p.has_thousand_swords, "Dagger + slash unlocks Vạn Kiếm Quy Tông")

	_drop(p)

func _test_starting_loadouts() -> void:
	# A starting loadout is the same handoff as a purchase: Ignis is handed
	# fireball + lightning at spawn, Sir Kaelen a dagger + blade.
	var pyro := _spawn_as("pyro")
	check(pyro.has_thunderfire, "Ignis spawns with Lôi Hỏa Liên Hoàn already live")
	check(not pyro.has_thousand_swords, "Ignis has no blade, so no Vạn Kiếm Quy Tông")
	_drop(pyro)

	var knight := _spawn_as("knight")
	check(knight.has_thousand_swords, "Sir Kaelen spawns with Vạn Kiếm Quy Tông already live")
	check(not knight.has_thunderfire, "Sir Kaelen has no elements, so no Lôi Hỏa Liên Hoàn")
	_drop(knight)

# --- 2. Lôi Hỏa Liên Hoàn: crits detonate -------------------------------------

func _test_thunderfire_burst() -> void:
	# Ranger holds the dagger only -- half a pairing, so the burst must stay inert
	# even though trigger_thunderfire_burst() is called directly.
	var p := _spawn_as("ranger")
	var victim := _spawn_enemy(Vector2(200, 0))
	var bystander := _spawn_enemy(Vector2(240, 0)) # 40px away, well inside the blast

	bystander.max_health = 9999.0
	bystander.current_health = 9999.0
	var bystander_hp: float = bystander.current_health
	p.trigger_thunderfire_burst(victim.global_position)
	check(is_equal_approx(bystander.current_health, bystander_hp),
		"A crit detonates nothing without both elements (%.1f -> %.1f)" % [bystander_hp, bystander.current_health])

	# Complete the pairing and the very same call now reaches the bystander.
	p.activate_weapon("fireball")
	p.activate_weapon("lightning")
	bystander_hp = bystander.current_health
	p.trigger_thunderfire_burst(victim.global_position)
	check(bystander.current_health < bystander_hp,
		"Lôi Hỏa Liên Hoàn detonates on crit (%.1f -> %.1f)" % [bystander_hp, bystander.current_health])

	# The blast is capped, or a crit-heavy build would clear a screen per swing.
	check(p.thunderfire_cd > 0.0, "A spent burst goes on cooldown")
	var hp_after_first: float = bystander.current_health
	p.trigger_thunderfire_burst(victim.global_position)
	check(is_equal_approx(bystander.current_health, hp_after_first),
		"The cooldown stops a second burst inside the same swing")

	# enemy.crit is the real entry point; drive it through take_damage() with a
	# crit chance of 1.0 so the roll is deterministic. The suite runs inside a
	# single frame, so no tick will ever clear the cooldown the checks above spent.
	_clear_enemies()
	var hit := _spawn_enemy(Vector2(200, 0))
	var near := _spawn_enemy(Vector2(230, 0))
	p.crit_chance_bonus = 1.0
	p.thunderfire_cd = 0.0
	near.max_health = 9999.0
	near.current_health = 9999.0
	var near_hp: float = near.current_health
	hit.take_damage(10.0, p.global_position)
	check(near.current_health < near_hp,
		"A crit routed through enemy.take_damage() detonates (%.1f -> %.1f)" % [near_hp, near.current_health])

	_clear_enemies()
	_drop(p)

# --- 3. Vạn Kiếm Quy Tông: slashes call the swarm -----------------------------

func _sword_qi_in_flight() -> int:
	return get_tree().get_nodes_in_group("projectiles").size()

func _test_sword_qi() -> void:
	# Ranger has a dagger but no blade, so a connecting sweep sends nothing.
	_clear_projectiles()
	var p := _spawn_as("ranger")
	p.activate_weapon("slash")
	var target := _spawn_enemy(Vector2(90, 0)) # inside slash_range (110)

	var before := _sword_qi_in_flight()
	var hits := p.perform_slash(Vector2.RIGHT)
	check(hits.size() == 1, "The connecting sweep hit its target (got %d)" % hits.size())
	check(_sword_qi_in_flight() > before, "Dagger + slash releases the swarm")
	# Two blades per connecting sweep, no more.
	check(_sword_qi_in_flight() - before == Player.SWORD_QI_PER_SLASH,
		"A sweep releases exactly %d blades, got %d" % [Player.SWORD_QI_PER_SLASH, _sword_qi_in_flight() - before])

	_clear_projectiles()
	_clear_enemies()
	_drop(p)
	_drop(target)

	# A whiffed slash is not a hit, so it must not pay out either.
	_clear_projectiles()
	var knight := _spawn_as("knight")
	before = _sword_qi_in_flight()
	check(knight.perform_slash(Vector2.RIGHT).is_empty(), "Slashing empty air connects with nothing")
	check(_sword_qi_in_flight() == before, "A whiffed slash releases no sword qi")
	_drop(knight)
	_clear_projectiles()

## The blades are only half the feature -- they have to actually steer. Driven
## through _physics_process rather than _steer() so the homing flag is the thing
## under test, not just the maths behind it.
func _test_sword_qi_homing() -> void:
	_clear_projectiles()
	_clear_enemies()
	var p := _spawn_as("knight")
	_spawn_enemy(Vector2(300, 300)) # well off the blade's line -- only steering finds it

	var sword := SpiritSwordProjectile.new()
	sword.global_position = Vector2.ZERO
	sword.direction = Vector2.RIGHT
	sword.homing = true
	add_child(sword)

	sword._physics_process(0.2)
	check(sword.direction.angle() > 0.0,
		"A homing blade turns off its launch line toward the target (%.3f rad)" % sword.direction.angle())
	check(sword.direction.angle() < Vector2(300, 300).angle() + 0.01,
		"It turns toward the target rather than away from it (%.3f rad)" % sword.direction.angle())

	# The two pre-existing callers (Lục Mạch, Shenron) never set homing, and their
	# straight-line flight has to survive this milestone untouched.
	var plain := SpiritSwordProjectile.new()
	plain.global_position = Vector2.ZERO
	plain.direction = Vector2.RIGHT
	add_child(plain)
	plain._physics_process(0.2)
	check(plain.direction.is_equal_approx(Vector2.RIGHT),
		"A blade without homing keeps its straight line, got %s" % str(plain.direction))

	_drop(plain)
	_drop(sword)
	_clear_projectiles()
	_clear_enemies()
	_drop(p)

# --- 4. The intermission HUD's sound feedback ---------------------------------

func _test_shop_feedback() -> void:
	# A wave that paid out savings interest announces the payout with a coin.
	var dir := WaveDirector.new()
	dir.max_waves = 20
	add_child(dir)
	dir.current_wave = 9
	dir.last_clear_gold = 42
	dir.last_interest_earned = 7

	var shop := SHOP_SCENE.instantiate() as WaveShopUI
	add_child(shop)
	clear_cues()
	shop.open_for_wave(10)
	check(shop.payout_interest == 7, "The shop read the interest off the director, got %d" % shop.payout_interest)
	check(_heard("coin"), "An interest payout plays a cue, got %s" % str(_cues))

	# A wave that paid no interest must stay silent -- otherwise every open rings.
	dir.last_clear_gold = 40
	dir.last_interest_earned = 0
	clear_cues()
	shop.open_for_wave(10)
	check(shop.payout_interest == 0, "A wave with no savings reports no interest")
	check(not _heard("coin"), "A wave with no interest plays no payout cue, got %s" % str(_cues))

	# Buying is its own cue, and it is not the coin the payout uses.
	clear_cues()
	GameManager.run_gold = 500
	shop.cards[0]["data"] = WaveShopUI.SCROLL_POOL[0]
	shop.cards[0]["locked"] = false
	var gold_before := GameManager.run_gold
	check(shop.purchase_card(0), "The card is affordable and buys")
	check(GameManager.run_gold < gold_before,
		"The purchase actually spent gold (%d -> %d)" % [gold_before, GameManager.run_gold])
	check(_heard("powerup"), "A purchase plays a cue, got %s" % str(_cues))
	check(not _heard("coin"), "A purchase does not reuse the payout's coin cue, got %s" % str(_cues))

	# A rejected purchase stays silent.
	GameManager.run_gold = 0
	shop.cards[1]["data"] = WaveShopUI.SCROLL_POOL[0]
	shop.cards[1]["locked"] = false
	clear_cues()
	check(not shop.purchase_card(1), "An unaffordable card is refused")
	check(_cues.is_empty(), "A refused purchase plays nothing, got %s" % str(_cues))

	shop.close_shop()
	_drop(shop)
	_drop(dir)

# --- 5. The handoff the whole milestone rests on -------------------------------

## The shop grants a weapon, UpgradeManager forwards it to the player, and the
## pairing lights up. Driving the three real nodes in sequence is the only way to
## catch a break in that chain -- flipping has_thunderfire by hand proves nothing.
func _test_shop_purchase_unlocks_synergy() -> void:
	var p := _spawn_as("ranger")
	var up := UpgradeManager.new()
	add_child(up)
	up.player = p

	var shop := SHOP_SCENE.instantiate() as WaveShopUI
	add_child(shop)
	shop.roll_items() # _ready() hides an empty shop; the four slots need filling.
	GameManager.run_gold = 1000

	check(not p.has_thunderfire, "The pairing starts dark")
	for w_id in ["fireball", "lightning"]:
		clear_cues()
		shop.cards[0]["data"] = _weapon_card(w_id)
		shop.cards[0]["locked"] = false
		check(shop.purchase_card(0), "The shop sells %s" % w_id)
		check(_heard("powerup"), "Buying %s plays a cue, got %s" % [w_id, str(_cues)])

	check(p.has_thunderfire, "Buying both elements at the shop unlocked Lôi Hỏa Liên Hoàn")
	check(up.arsenal.size() == 2, "Both weapons reached the arsenal, got %d" % up.arsenal.size())

	shop.close_shop()
	_drop(shop)
	_drop(up)
	_drop(p)

func _weapon_card(w_id: String) -> Dictionary:
	for item in WaveShopUI.WEAPON_POOL:
		if item["id"] == w_id:
			return item
	return {}
