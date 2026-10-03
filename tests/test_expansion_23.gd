extends Node

## Automated Test Suite for Expansion 23.0:
## "Tách Kỹ Thuật" -- buffs that could be switched on but never off, and two
## mechanics the Codex and the hermit both promised.
##
## Every check here is a regression test over a bug that was live and silent:
##   * the glacial champion's aura wrote player.speed_multiplier with no writer
##     that could undo it, so one brush past a champion cost the player 35% of
##     their move speed for the rest of the run, and crushed any Wind Surge.
##   * might_multiplier had four writers and one reset, so the Blood Covenant and
##     the Berserker Brand deleted each other and a Might Surge deleted both.
##   * Đốc Mạch has advertised "+35% Crit Damage" in the meridian table since the
##     Codex shipped. It applied crit chance only.
##   * two pacts looked the spawner up in the group "spawner"; the spawner
##     registers as "enemy_spawner", and the one method they then called on it
##     did not exist. Both were no-ops that still printed their reward text.
##   * trigger_swarm() skipped the HP curve and danger tier that spawn_enemy_wave()
##     applied, so a wave-5 bat swarm spawned wave-0 bats.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const SKELETON_SCENE: PackedScene = preload("res://scenes/skeleton.tscn")
const BAT_SCENE: PackedScene = preload("res://scenes/bat.tscn")

## buy_meridian_upgrade() persists to user://save_data.cfg immediately, so this
## suite would spend the developer's real meta gold. Backed up and restored.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.m23bak"
var _had_save: bool = false

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

var _relics_backup: Array = []
var _meridians_backup: Dictionary = {}
var _player: Player = null
var _spawner: EnemySpawner = null

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
	print("=== RUNNING EXPANSION 23.0 TEST SUITE ===")
	# Keep the tree inert so the suite, not the autoload, decides when a run runs.
	GameManager.is_run_active = false

	_relics_backup = GameManager.collected_relics.duplicate()
	_meridians_backup = GameManager.meridian_upgrades.duplicate()

	await _test_glacial_aura_is_a_lease_not_a_latch()
	await _test_might_sources_do_not_delete_each_other()
	await _test_doc_mach_crit_damage_is_actually_applied()
	await _test_hermit_summons_reach_the_spawner()
	await _test_swarm_spawns_scale_like_every_other_spawn()

	_drop(_player)
	_drop(_spawner)
	GameManager.collected_relics = _relics_backup
	GameManager.meridian_upgrades = _meridians_backup
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL EXPANSION 23.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the glacial champion's aura ---------------------------------------

## The original bug in one shape. A champion in the "glacial" affix did
##     player.speed_multiplier = min(player.speed_multiplier, 0.65)
## every frame the player stood in its 170px aura. The only thing that ever set
## speed_multiplier back to 1.0 was the Wind Surge's own timer, which is 0.0
## unless the player had taken that landmark -- so for everyone else the aura
## was a one-way door. The min() also meant standing near a champion while a
## Wind Surge was running replaced 1.5 with 0.65 rather than composing with it.
func _test_glacial_aura_is_a_lease_not_a_latch() -> void:
	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.current_health = _player.max_health
	_player.speed_multiplier = 1.0
	_player.glacial_slow_timer = 0.0

	var champ := _spawn_enemy(_player.global_position + Vector2(100, 0), 9000.0, false)
	champ.is_champion = true
	champ.champion_affix = "glacial"
	await _physics_frames(3)

	check(_player.glacial_slow_timer > 0.0,
		"A glacial champion inside 170px takes a slow lease, got %s" % _player.glacial_slow_timer)
	check(is_equal_approx(_player.speed_multiplier, 1.0),
		"The aura must not write speed_multiplier at all -- it owns a lease, not the field (got %s)" % _player.speed_multiplier)

	# The Wind Surge regression: taken while the aura is live, it used to be
	# overwritten with 0.65 on the very next frame.
	_player.apply_speed_buff(20.0, 1.5)
	await _physics_frames(3)
	check(is_equal_approx(_player.speed_multiplier, 1.5),
		"A Wind Surge taken inside a glacial aura survives (expected 1.5, got %s)" % _player.speed_multiplier)

	# And the lease ends when the source does. Nothing has to tell the player to
	# give the speed back -- the champion simply stops renewing it.
	champ.queue_free()
	await _physics_frames(24)
	check(_player.glacial_slow_timer <= 0.0,
		"The lease expires on its own once the champion is gone, got %s" % _player.glacial_slow_timer)
	check(is_equal_approx(_player.speed_multiplier, 1.5),
		"...and the Wind Surge was still running, untouched (got %s)" % _player.speed_multiplier)

	_player.speed_buff_timer = 0.0
	_player.speed_multiplier = 1.0

# --- 2. four might writers, one reset --------------------------------------

## might_multiplier was written by apply_might_buff() (assign), the Blood
## Covenant (+= 0.45), Tẩy Tủy Hoán Cốt (+= 0.20) and the Berserker Brand
## (max(_, 1.50)) -- and reset to 1.0 by nothing except the Might Surge's own
## timer. So a surge landing on a covenant and expiring 25s later deleted the
## covenant, and max(1.45, 1.50) silently threw the covenant's 0.45 away.
func _test_might_sources_do_not_delete_each_other() -> void:
	GameManager.collected_relics.erase("berserker_brand")
	_player.meta_might_bonus = 0.0
	_player.might_multiplier = 1.0
	_player.might_flat_bonus = 1.0
	_player.char_damage_mult = 1.0
	_player.current_health = _player.max_health
	# No refresh_meta_stats() here: it rebuilds meta_might_bonus out of the
	# equipped gear and the persisted meta upgrades, and this test is about the
	# four writers of might_multiplier, not what the save happens to be wearing.
	_player.meta_might_bonus = 0.0

	_player.apply_demonic_pact("blood_covenant")
	check(is_equal_approx(_player.get_might_multiplier(), 1.45),
		"Huyết Khế is 1.45x on its own, got %s" % _player.get_might_multiplier())

	# A Might Surge on top, then its natural expiry -- the covenant has to outlive it.
	_player.apply_might_buff(0.05, 1.4)
	check(is_equal_approx(_player.get_might_multiplier(), 1.45 * 1.4),
		"A Might Surge multiplies the covenant (expected %s, got %s)" % [1.45 * 1.4, _player.get_might_multiplier()])
	await _physics_frames(20)
	check(_player.might_buff_timer <= 0.0 and is_equal_approx(_player.might_multiplier, 1.0),
		"The surge expired on its own (got timer %s, mult %s)" % [_player.might_buff_timer, _player.might_multiplier])
	check(is_equal_approx(_player.get_might_multiplier(), 1.45),
		"...and took its own bonus with it, leaving Huyết Khế standing (got %s)" % _player.get_might_multiplier())

	# The Berserker Brand half. Below 40% HP it must lift the player to at least
	# 1.5x on top of what they already had -- max()ing the shared field made it a
	# silent refund of the covenant, and it never gave the 1.50 back either.
	GameManager.collected_relics.append("berserker_brand")
	_player.current_health = _player.max_health * 0.30
	# Physics frames on purpose. The Brand used to write might_multiplier from
	# _physics_process, so a check that only reads the getter synchronously never
	# sees the old write and would pass against the bug it is meant to catch.
	await _physics_frames(2)
	check(_player.is_berserker_brand_active(), "The Berserker Brand is awake at 30%% HP")
	check(is_equal_approx(_player.get_might_multiplier(), 1.45 * 1.50),
		"The Brand stacks on Huyết Khế instead of max()-ing it away (expected %s, got %s)" % [1.45 * 1.50, _player.get_might_multiplier()])
	check(is_equal_approx(_player.might_multiplier, 1.0),
		"The Brand is a getter, not a field write -- might_multiplier is untouched (got %s)" % _player.might_multiplier)

	_player.current_health = _player.max_health * 0.41
	await _physics_frames(2)
	check(not _player.is_berserker_brand_active(), "It sleeps again above 40%% HP")
	check(is_equal_approx(_player.get_might_multiplier(), 1.45),
		"Healing past the threshold hands the Brand back on the spot (got %s)" % _player.get_might_multiplier())

	# And the pacts the player bought are the pacts they still have. The two are
	# additive off a 1.0 base -- 1.0 + 0.45 + 0.20 -- not a product of 1.45 and 1.2.
	_player.apply_hermit_item("tay_tuy_dan")
	check(is_equal_approx(_player.get_might_multiplier(), 1.0 + 0.45 + 0.20),
		"Tẩy Tủy Hoán Cốt stacks with Huyết Khế (expected %s, got %s)" % [1.0 + 0.45 + 0.20, _player.get_might_multiplier()])
	GameManager.collected_relics.erase("berserker_brand")

# --- 3. Đốc Mạch's advertised crit damage ---------------------------------

## game_manager.gd has read "+7% Crit Chance & +35% Crit Damage per level" in the
## MERIDIANS table since the Codex shipped. Only the first half was ever applied;
## the crit multiplier was the bare 2.2 literal in enemy.take_damage().
func _test_doc_mach_crit_damage_is_actually_applied() -> void:
	GameManager.meridian_upgrades.erase("doc_mach")
	GameManager.collected_relics.erase("demonic_token")
	_player.current_health = _player.max_health
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.get_crit_damage_multiplier(), 1.0),
		"0 ranks of Đốc Mạch grant no crit damage, got %f" % _player.get_crit_damage_multiplier())

	GameManager.meridian_upgrades["doc_mach"] = 5
	_player.refresh_meta_stats()
	check(is_equal_approx(_player.get_crit_damage_multiplier(), 1.0 + 5.0 * 0.35),
		"5 ranks are +175%% crit damage, got %f" % _player.get_crit_damage_multiplier())

	# The real purchase path, not just the recompute: buy_meridian_upgrade()
	# calls refresh_meta_stats() for every meridian, so this is the same line a
	# player in the pause menu would run.
	GameManager.meridian_upgrades.erase("doc_mach")
	_player.refresh_meta_stats()
	GameManager.total_gold = 999999
	GameManager.buy_meridian_upgrade("doc_mach")
	check(is_equal_approx(_player.get_crit_damage_multiplier(), 1.0 + 0.35),
		"Buying one rank grants exactly one +35%%, got %f" % _player.get_crit_damage_multiplier())

	# Stacks with the Tà Ma Lệnh Bài rage rather than replacing it.
	GameManager.collected_relics.append("demonic_token")
	_player.current_health = _player.max_health * 0.25
	check(is_equal_approx(_player.get_crit_damage_multiplier(), 1.0 + 0.35 + 0.25),
		"The relic's +25%% and the meridian's +35%% are both counted, got %f" % _player.get_crit_damage_multiplier())

	# It has to reach the one crit roll in the game, so drive a real one: 100%
	# crit, 200 incoming, and read the HP the victim actually lost.
	_player.current_health = _player.max_health
	_player.crit_chance_bonus = 10.0
	var victim := _spawn_enemy(Vector2(240, 0), 5000.0)
	victim.take_damage(200.0, Vector2.ZERO)
	var lost := 5000.0 - float(victim.current_health)
	victim.queue_free()
	check(is_equal_approx(lost, 200.0 * 2.2 * 1.35),
		"A 200-damage crit lands for 594 (2.2 x 1.35), got %s" % lost)

	GameManager.collected_relics.erase("demonic_token")
	GameManager.meridian_upgrades.erase("doc_mach")
	_player.refresh_meta_stats()

# --- 4. the hermit's summons had nowhere to land ---------------------------

## apply_demonic_pact() read get_first_node_in_group("spawner"). EnemySpawner
## registers as "enemy_spawner" (enemy_spawner.gd:_ready), so that was always
## null -- and the Van Mệnh Quẻ branch then guarded on spawn_specific_enemy(),
## a method no one had ever written. A 30% Hạ Hạ Quẻ roll announced two demons
## and spawned nothing, which is the worst possible outcome to roll.
func _test_hermit_summons_reach_the_spawner() -> void:
	GameManager.run_time = 100.0
	_spawner = EnemySpawner.new()
	_spawner.bat_scene = BAT_SCENE
	_spawner.skeleton_scene = SKELETON_SCENE
	add_child(_spawner)
	_spawner.player = _player
	_spawner.set_process(false)
	await get_tree().process_frame

	check(_spawner.is_in_group("enemy_spawner"),
		"The spawner registers under the name the pacts look up")

	var before := _count_enemies()
	var snapshot: Array = get_tree().get_nodes_in_group("enemies")
	var at := _player.global_position + Vector2(123, 45)
	_spawner.spawn_specific_enemy("skeleton_brute", at)

	# Read the placement back before the frame runs. add_child() puts the skeleton in
	# the "enemies" group inside its own _ready(), so the summon is already findable
	# here -- but it also starts chasing on its first physics step, and one frame at
	# its wave-scaled speed is about 1.5px, wider than the 1.0px tolerance below. The
	# claim under test is where the pact PUT the enemy, not that the enemy then stands
	# still, and measuring a frame later went red on roughly one run in ten for a
	# summon that had landed exactly where it was asked to.
	# By identity, not by position in the group array. This suite leaves enemies
	# standing between its cases, and Godot does not promise the group is in
	# insertion order -- so taking the last entry was reading whichever leftover
	# happened to sort last, and the offset check came up empty about a quarter of
	# the time. _enemies_not_in() is the helper that answers the real question.
	var fresh := _enemies_not_in(snapshot)
	check(fresh.size() == 1,
		"...and that enemy is the one this summon created, found %d candidates" % fresh.size())
	if fresh.size() == 1:
		var summoned := fresh[0]
		check(summoned.global_position.distance_to(at) < 1.0,
			"...at the offset the pact asked for, got %s" % summoned.global_position)
		# And it has to be scaled, or it is a tier-0 skeleton walking into wave 5.
		var expected: float = (_base_max_health(SKELETON_SCENE) + floorf(GameManager.run_time * 0.22)) * float(GameManager.get_danger_data()["hp"])
		check(is_equal_approx(float(summoned.get("max_health")), expected),
			"The summoned skeleton gets the hiệp HP curve and the danger tier (expected %s, got %s)" % [expected, summoned.get("max_health")])
	# Await afterwards rather than before: the group is already updated by add_child(),
	# so nothing above needed a frame -- and taking one is what let the summoned
	# skeleton walk off the offset this case had just measured.
	await get_tree().process_frame

	var after := _count_enemies()
	check(after == before + 1,
		"Hạ Hạ Quẻ's summon lands exactly one enemy in the arena, got %d" % (after - before))

	# An id nobody knows must be a no-op, not a crash mid-run.
	var quiet := _count_enemies()
	_spawner.spawn_specific_enemy("no_such_enemy", at)
	check(_count_enemies() == quiet, "An unknown id summons nothing rather than erroring")

	# The group name itself, end to end. Tà Khí is the deterministic half of this
	# bug -- it is the only pact that mutates the spawner, and it did it to null.
	var interval := _spawner.spawn_interval
	_player.apply_demonic_pact("abyssal_frenzy")
	check(is_equal_approx(_spawner.spawn_interval, interval * 0.70),
		"Tà Khí reaches the spawner and speeds up the waves (expected %s, got %s)" % [interval * 0.70, _spawner.spawn_interval])

# --- 5. and the wave swarms scale like every other spawn -------------------

## trigger_swarm() built its enemies straight from the scene, skipping both the
## +floor(difficulty * 0.22) curve and the danger tier that spawn_enemy_wave()
## applied two functions above it. A wave-5 bat swarm was a wave-0 bat swarm.
func _test_swarm_spawns_scale_like_every_other_spawn() -> void:
	var base_bat := _base_max_health(BAT_SCENE)
	var expected: float = (base_bat + floorf(GameManager.run_time * 0.22)) * float(GameManager.get_danger_data()["hp"])

	var before := get_tree().get_nodes_in_group("enemies")
	_spawner.trigger_swarm("test swarm", _spawner.bat_scene, 3)
	await get_tree().process_frame
	await get_tree().process_frame

	var fresh := _enemies_not_in(before)
	check(fresh.size() == 3, "The swarm still spawns 3, got %d" % fresh.size())
	if fresh.size() != 3:
		return
	var unscaled := 0
	for e in fresh:
		if is_equal_approx(float(e.get("max_health")), base_bat):
			unscaled += 1
	check(unscaled == 0,
		"Every swarm bat carries the danger tier and the HP curve (expected %s, %d of 3 were still %s)" % [expected, unscaled, base_bat])

# --- helpers ----------------------------------------------------------------

## max_health as authored, read off an instance that has not entered the tree.
func _base_max_health(scene: PackedScene) -> float:
	var probe = scene.instantiate()
	var hp := float(probe.get("max_health"))
	probe.free()
	return hp

func _count_enemies() -> int:
	return get_tree().get_nodes_in_group("enemies").size()

## The enemies that appeared since a snapshot -- by identity, not by value, so a
## leftover from an earlier test is never mistaken for one this one just spawned.
func _enemies_not_in(snapshot: Array) -> Array[Node]:
	var fresh: Array[Node] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not snapshot.has(e):
			fresh.append(e)
	return fresh

## frozen: enemies normally chase, which would move them off the offset the
## summon test just measured. The glacial test needs them moving.
func _spawn_enemy(at: Vector2, hp: float, frozen: bool = true) -> Node2D:
	# Storm Amulet and Lôi Hỏa Liên Hoàn ride the same hit as a crit, and a
	# prior suite persists collected_relics to user://save_data.cfg, so pin both.
	GameManager.collected_relics.erase("storm_amulet")
	_player.has_thunderfire = false
	var e := ENEMY_SCENE.instantiate() as Node2D
	e.player = _player
	add_child(e)
	e.global_position = at
	e.current_health = hp
	e.set_physics_process(not frozen)
	return e

func _physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()
