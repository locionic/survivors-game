extends Node

## Automated Test Suite for Expansion 35.0:
## "Boss Của Hiệp 20 Cũng Chỉ Mạnh Bằng Boss Hiệp 1" -- four boss spawns, the treasure
## goblin and the opening ambush that never touch the difficulty curve or the danger
## tier.
##
## EnemySpawner._scale_for_wave() is the one place the hiệp HP curve and the danger
## tier are applied, and its own comment claimed "Every spawn path routes through
## here." Three did. Eleven instantiate an enemy; these call the shared helper:
##
##     spawn_enemy_wave()  :343      trigger_swarm()  :420
##     spawn_specific_enemy() :391
##
## and these six did not:
##
##     spawn_intro_ambush()      :103   9 bats, frame one of every run
##     spawn_boss_1()            :438   DREADLORD MALAKOR
##     spawn_boss_2()            :459   INFERNAL BEHEMOTH
##     spawn_boss_3()            :480   SONG THỦ MA TƯỚNG
##     spawn_demon_emperor()     :505   TRÙM CUỐI, the one wired to trigger_victory()
##     spawn_treasure_goblin()   :542
##
## So a boss's HP was whatever its scene was authored with, on every wave of the run.
## The final boss, demon_emperor.tscn at 2400 base, was meant to reach
## (2400 + floor(480 * 0.22)) * 3.0 = 7515 on wave 20 at Hắc Ám. It spawned at 2400 --
## 32% of the fight the player had earned, and the fight that decides the run.
##
## spawn_boss_3() compounds on top of this: it read max_health and wrote cur_hp * 1.8,
## so its 80% bonus was 80% of a *flat* number. The suite checks that ordering too --
## scaling first, the boss's own multiplier second -- so a fix that put the call after
## the 1.8 would still be caught, just at a different number.
##
## spawn_hermit() is deliberately not in this list. The Lão Ngọan Đồng is the pact NPC,
## not a wave combatant, and giving a non-combat NPC the combat HP curve would be a new
## bug rather than a fixed one.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/boss.tscn")
const BEHEMOTH_SCENE: PackedScene = preload("res://scenes/behemoth.tscn")
const DEMON_SCENE: PackedScene = preload("res://scenes/demon_emperor.tscn")
const GOBLIN_SCENE: PackedScene = preload("res://scenes/goblin.tscn")
const BAT_SCENE: PackedScene = preload("res://scenes/bat.tscn")
const SKELETON_SCENE: PackedScene = preload("res://scenes/skeleton.tscn")

## WAVE_DIFFICULTY_SECONDS, stated rather than imported: the suite's whole point is the
## shape of the curve, so it says what the top of the run looks like.
const WAVE_SECONDS: float = 24.0
const FIRST_WAVE: float = WAVE_SECONDS
const LAST_WAVE: float = WAVE_SECONDS * 20.0
## spawn_boss_3()'s own multiplier over the scene it was handed.
const SONG_THU_MULT: float = 1.8

## Every boss spawn under test, with the scene it draws from and that scene's own extra
## multiplier. Each is spawned and then found in the arena by identity.
const BOSS_CASES: Array[Dictionary] = [
	{"fn": "spawn_boss_1", "scene": BOSS_SCENE, "extra": 1.0, "what": "Dreadlord Malakor"},
	{"fn": "spawn_boss_2", "scene": BEHEMOTH_SCENE, "extra": 1.0, "what": "Infernal Behemoth"},
	{"fn": "spawn_boss_3", "scene": BEHEMOTH_SCENE, "extra": SONG_THU_MULT, "what": "Sòng Thủ Ma Tướng"},
	{"fn": "spawn_demon_emperor", "scene": DEMON_SCENE, "extra": 1.0, "what": "Demon Emperor"},
]

var _failures: Array[String] = []
var _player: Player = null
var _spawner: EnemySpawner = null
var _danger_backup: int = 0
var _runtime_backup: float = 0.0

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 35.0 TEST SUITE ===")
	GameManager.is_run_active = false
	_danger_backup = GameManager.danger_level
	_runtime_backup = GameManager.run_time

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)

	_spawner = EnemySpawner.new()
	_spawner.bat_scene = BAT_SCENE
	_spawner.skeleton_scene = SKELETON_SCENE
	_spawner.boss_scene = BOSS_SCENE
	_spawner.behemoth_scene = BEHEMOTH_SCENE
	add_child(_spawner)
	_spawner.player = _player
	_spawner.set_process(false)   # the suite decides when a wave happens
	await get_tree().process_frame

	if not check(_spawner.is_in_group("enemy_spawner"), "Precondition: the spawner registered"):
		_finish()
		return

	_test_every_boss_carries_the_curve_and_the_tier()
	_test_a_boss_gets_tougher_as_the_run_goes_on()
	_test_the_tier_multiplies_the_boss_too()
	_test_song_thus_own_bonus_sits_on_top_of_the_curve()
	await _test_the_opening_ambush_and_the_treasure_goblin()
	_test_the_elite_champion_gets_the_curve_without_the_tier_twice()

	_finish()

# --- 1. the four bosses --------------------------------------------------------

## The defect in one assertion: the boss that spawns on hiệp 20 is the same size as the
## one that spawns on hiệp 1. Against the code before the fix every one of these
## reported the scene's authored number -- 360, 750, 750 * 1.8, 2400 -- whatever the
## hiệp and whatever tier the player had chosen.
func _test_every_boss_carries_the_curve_and_the_tier() -> void:
	_at(LAST_WAVE, 0)
	for case in BOSS_CASES:
		var boss := _spawn_boss(str(case["fn"]))
		if not check(boss != null, "%s spawned something" % case["what"]):
			continue
		var want := _expected(case["scene"], float(case["extra"]))
		check(is_equal_approx(float(boss.get("max_health")), want),
			"The %s on hiệp 20 carries the HP curve and the tier: %s where the formula says %s"
				% [case["what"], boss.get("max_health"), want])
		_drop(boss)

# --- 2. the headline -----------------------------------------------------------

## Stated as a comparison rather than a number, because it is the thing a player would
## actually notice: the run's last fight and its first fight were the same size.
func _test_a_boss_gets_tougher_as_the_run_goes_on() -> void:
	_at(FIRST_WAVE, 0)
	var early := _spawn_boss("spawn_boss_1")
	_at(LAST_WAVE, 0)
	var late := _spawn_boss("spawn_boss_1")
	if check(early != null and late != null, "Both Dreadlords spawned"):
		check(float(late.get("max_health")) > float(early.get("max_health")),
			"A hiệp-20 Dreadlord is tougher than a hiệp-1 one: %s vs %s"
				% [late.get("max_health"), early.get("max_health")])
	_drop(early)
	_drop(late)

# --- 3. the tier, which is a separate multiplier -------------------------------

## Hắc Ám is a difficulty the player chose at character select. It scaling every bat in
## the arena but none of the four bosses is the gap that made the top tier easier to
## finish than the one below it.
func _test_the_tier_multiplies_the_boss_too() -> void:
	_at(LAST_WAVE, 5)
	var boss := _spawn_boss("spawn_demon_emperor")
	if check(boss != null, "The final boss spawned on Hắc Ám"):
		var want := _expected(DEMON_SCENE, 1.0)
		check(is_equal_approx(float(boss.get("max_health")), want),
			"The final boss on hiệp 20 at tier 5 is %s, the formula says %s"
				% [boss.get("max_health"), want])
	_drop(boss)

# --- 4. the boss's own multiplier, and the order ------------------------------

## Sòng Thủ is a 1.8x boss. Whether that 1.8 lands on a flat number or on a scaled
## one changes the fight by more than the entire HP curve, so the order is pinned: the
## shared curve first, the boss's own bonus second.
func _test_song_thus_own_bonus_sits_on_top_of_the_curve() -> void:
	_at(LAST_WAVE, 0)
	var song_thu := _spawn_boss("spawn_boss_3")
	_at(LAST_WAVE, 0)
	var plain := _spawn_boss("spawn_boss_2")
	if check(song_thu != null and plain != null, "Both Behemoth-based bosses spawned"):
		check(is_equal_approx(
				float(song_thu.get("max_health")),
				float(plain.get("max_health")) * SONG_THU_MULT),
			"Sòng Thủ is 1.8x the Behemoth on the same hiệp: %s where %s x 1.8 is expected"
				% [song_thu.get("max_health"), plain.get("max_health")])
		# ...and the curve is inside that 1.8, not flattened out by it. Pre-fix the
		# plain behemoth scaled and Sòng Thủ did not, so this is the ordering stated
		# as a second number rather than a comment.
		check(float(plain.get("max_health")) > _base_max_health(BEHEMOTH_SCENE),
			"The Behemoth underneath Sòng Thủ carries the curve: %s where the scene is authored at %s"
				% [plain.get("max_health"), _base_max_health(BEHEMOTH_SCENE)])
	_drop(song_thu)
	_drop(plain)

# --- 5. the two non-boss spawns that also skipped it ---------------------------

## The opening ambush is the first thing the player sees, and it is nine bats in a ring
## 300px out -- the tier the player picked at character select applied to nothing else on
## frame one. The treasure goblin is a real fight with real HP and no curve.
func _test_the_opening_ambush_and_the_treasure_goblin() -> void:
	_at(LAST_WAVE, 3)
	# _ready() defers a ring of its own and the one-shot guard it sets would make this
	# call a silent no-op -- the ring would already be standing in the snapshot, so the
	# case would measure zero bats and pass for the wrong reason if it only counted
	# loosely. Re-armed explicitly, so the bats measured here are this call's.
	_spawner._intro_ring_spawned = false
	var before := get_tree().get_nodes_in_group("enemies")
	_spawner.spawn_intro_ambush()
	await get_tree().process_frame
	await get_tree().process_frame
	var bats := _fresh(before)
	if check(bats.size() == 9, "The ambush still rings nine bats, got %d" % bats.size()):
		var want := _expected(BAT_SCENE, 1.0)
		var wrong := 0
		for b in bats:
			if not is_equal_approx(float(b.get("max_health")), want):
				wrong += 1
		check(wrong == 0, "Every ambush bat carries the curve and the tier (want %s, %d of 9 did not)"
			% [want, wrong])
		for b in bats:
			_drop(b)

	_at(LAST_WAVE, 3)
	var before_goblin := get_tree().get_nodes_in_group("enemies")
	_spawner.spawn_treasure_goblin()
	await get_tree().process_frame
	await get_tree().process_frame
	var goblins := _fresh(before_goblin)
	if check(goblins.size() == 1, "The treasure goblin spawned, %d appeared" % goblins.size()):
		var want := _expected(GOBLIN_SCENE, 1.0)
		check(is_equal_approx(float(goblins[0].get("max_health")), want),
			"The treasure goblin carries the curve and the tier: %s where the formula says %s"
				% [goblins[0].get("max_health"), want])
		_drop(goblins[0])

# --- 6. the elite, where the careless fix doubles the tier ---------------------

## spawn_elite_champion() already called _apply_danger(). Adding _scale_for_wave() next
## to it instead of replacing it would apply the tier twice and hand the player a tier-5
## elite at 9x HP -- a worse bug than the missing curve. So the elite is pinned against
## both numbers: once, with the curve, and explicitly not squared.
##
## The 3.5x on top is Enemy.ELITE_HEALTH_MULT, applied by make_elite_champion() from the
## enemy's own _ready() once it enters the tree -- so it lands after the wave scaling by
## construction, and it is read off the class rather than hardcoded here.
func _test_the_elite_champion_gets_the_curve_without_the_tier_twice() -> void:
	# Only one scene in the pool, so the expectation is about a known base.
	_spawner.necromancer_scene = null
	_spawner.bat_scene = null
	_at(LAST_WAVE, 5)

	var elite := _spawner.spawn_elite_champion(Vector2(500, 0))
	if not check(elite != null, "The elite champion spawned"):
		return
	var scaled := (_base_max_health(SKELETON_SCENE) + floorf(LAST_WAVE * 0.22)) * 3.0
	var elite_mult: float = Enemy.ELITE_HEALTH_MULT
	check(is_equal_approx(float(elite.get("max_health")), scaled * elite_mult),
		"A tier-5 elite on hiệp 20 is %s: the curve, the tier once, then its own 3.5x. Not %s (tier applied twice)"
			% [elite.get("max_health"), scaled * 3.0 * elite_mult])
	_drop(elite)

# --- helpers -------------------------------------------------------------------

## Put the run at a given difficulty and tier. The spawner reads its curve off
## get_difficulty_seconds(), which falls back to GameManager.run_time when no director
## is in the tree -- which is the case here, and makes the fixture one assignment
## instead of a stub scene.
func _at(seconds: float, danger: int) -> void:
	GameManager.run_time = seconds
	GameManager.danger_level = danger

## (authored HP + the hiệp curve) x the tier x the spawn's own multiplier. This is
## _scale_for_wave() restated as a number, read from the scene rather than hardcoded, so
## a balance change to boss.tscn does not need a second edit here.
func _expected(scene: PackedScene, extra: float) -> float:
	var d := GameManager.get_danger_data()
	return (_base_max_health(scene) + floorf(GameManager.run_time * 0.22)) \
		* float(d["hp"]) * extra

## max_health as authored, read off an instance that has not entered the tree.
func _base_max_health(scene: PackedScene) -> float:
	var probe = scene.instantiate()
	var hp := float(probe.get("max_health"))
	probe.free()
	return hp

## Call one of the boss spawners and find what it put in the arena. By identity, not by
## position: this suite leaves standing enemies between its cases and Godot does not
## promise the group is in insertion order.
func _spawn_boss(fn: String) -> Node2D:
	var before := get_tree().get_nodes_in_group("enemies")
	_spawner.call(fn)
	var fresh := _fresh(before)
	return fresh[0] if fresh.size() == 1 else null

func _fresh(snapshot: Array) -> Array[Node]:
	var out: Array[Node] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not snapshot.has(e):
			out.append(e)
	return out

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()

func _finish() -> void:
	GameManager.danger_level = _danger_backup
	GameManager.run_time = _runtime_backup
	_drop(_spawner)
	_drop(_player)

	if _failures.is_empty():
		print("=== ALL EXPANSION 35.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)
