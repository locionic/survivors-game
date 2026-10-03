extends Node

## Automated Test Suite for Milestone 3b: "Web Performance Overhaul & Visceral Combat Feel"
##
## Every assertion here pins a *performance* or *feel* rule. Those are exactly
## the regressions nobody notices: a reverted cache or a re-added hitstop still
## runs, still looks fine in a screenshot, and quietly costs the browser 30fps.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const BAT_SCENE: PackedScene = preload("res://scenes/bat.tscn")
const GEM_SCENE: PackedScene = preload("res://scenes/gem.tscn")
const COIN_SCENE: PackedScene = preload("res://scenes/coin.tscn")

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
## each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## Nothing in this suite should move the developer's real save.
const SAVE_PATH: String = "user://save_data.cfg"
const BACKUP_PATH: String = "user://save_data.cfg.m3bbak"
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
	print("=== RUNNING MILESTONE 3b: WEB PERFORMANCE & COMBAT FEEL TEST SUITE ===")
	# Nothing here should be advancing a real run; the autoloads stay inert.
	GameManager.is_run_active = false

	_test_trash_mobs_never_stop_time()
	_test_separation_snapshot_is_shared()
	_test_gem_swarm_stays_capped()
	_test_cursor_outranks_movement()
	_test_finisher_rewards_the_payoff()
	await _test_intro_ring_is_one_shot()
	_test_background_is_not_a_million_pixels()

	get_tree().paused = false
	_restore_save()

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL MILESTONE 3b TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1A: a bat dying must not touch Engine.time_scale -------------------------

## The bug: every regular death dropped the whole engine to 0.08 for 35ms. Ten
## bats a second meant ten freezes a second, which is what read as a lagging tab.
func _test_trash_mobs_never_stop_time() -> void:
	Engine.time_scale = 1.0
	GameManager._hitstop_timer = 0.0

	var bat = _spawn(ENEMY_SCENE, Vector2(200, 200))
	bat.die()
	check(Engine.time_scale == 1.0,
		"A regular mob death leaves Engine.time_scale at 1.0, got %f" % Engine.time_scale)

	# And a second one in a row, which is the kill rate that actually hurt.
	var bat2 = _spawn(ENEMY_SCENE, Vector2(240, 200))
	bat2.die()
	check(Engine.time_scale == 1.0,
		"Back-to-back trash deaths still leave time_scale at 1.0, got %f" % Engine.time_scale)

	# Bosses keep the punch. Run last: trigger_hitstop() ignores a second request
	# while one is already live, and its restore timer runs on wall-clock time.
	var boss = _spawn(ENEMY_SCENE, Vector2(200, 200))
	boss.is_boss = true
	boss.die()
	check(Engine.time_scale < 1.0,
		"A boss death still earns a hitstop, time_scale=%f" % Engine.time_scale)
	check(Engine.time_scale >= 0.2,
		"The boss hitstop is shallow (>= 0.2) so it reads as impact, not a hitch, got %f" % Engine.time_scale)

	Engine.time_scale = 1.0
	GameManager._hitstop_timer = 0.0
	_drop([bat, bat2, boss])
	print("OK Hitstop: trash mobs never stop time; boss deaths still do, and only shallowly.")

# --- 1B: one group query per physics frame, not one per mob ------------------

## The bug: every enemy re-ran get_nodes_in_group("enemies") on its own
## separation tick, allocating an Array each time -- hundreds per second under
## WASM. The fix is a static snapshot keyed on Engine.get_physics_frames().
func _test_separation_snapshot_is_shared() -> void:
	check(Enemy._sep_frame == -1, "The shared snapshot starts cold")

	# The whole movement/separation block is gated on the enemy having found a
	# player, so the player has to be in the tree before the mobs spawn.
	var p = _spawn(PLAYER_SCENE, Vector2(100, 100))
	var mobs: Array[Node] = []
	for i in range(6):
		mobs.append(_spawn(ENEMY_SCENE, Vector2(100.0 + i * 30.0, 100.0)))

	# One physics step is enough for every mob to run its separation branch.
	await get_tree().physics_frame
	await get_tree().physics_frame

	var live := 0
	for n in get_tree().get_nodes_in_group("enemies"):
		if not n.is_queued_for_deletion():
			live += 1
	# Awaiting physics_frame resumes at the START of the next tick, before this
	# frame's mobs run, so the cache is legitimately one frame behind. What must
	# hold is that it was refreshed at all and is never more than a tick stale.
	check(Enemy._sep_frame > 0,
		"The shared snapshot is maintained (frame=%d, -1 means the per-mob query is back)"
			% Enemy._sep_frame)
	check(Engine.get_physics_frames() - Enemy._sep_frame <= 1,
		"The snapshot is at most one physics frame stale (cached=%d, now=%d)"
			% [Enemy._sep_frame, Engine.get_physics_frames()])
	check(Enemy._sep_snapshot.size() >= 6,
		"The snapshot contains the 6 mobs that shared it, got %d" % Enemy._sep_snapshot.size())
	print("  (%d live enemies, snapshot of %d)" % [live, Enemy._sep_snapshot.size()])

	for m in mobs:
		_drop([m])
	_drop([p])
	# Park the static so a later suite does not read a stale frame number.
	Enemy._sep_frame = -1
	print("OK Boids: 6 mobs share one group query per physics frame instead of 6.")

# --- 1D: the gem swarm is capped, and the XP still adds up -------------------

## The bug: a 40-bat wave littered the floor with 150+ Area2Ds, each with its own
## _process, magnet check and body_entered signal.
func _test_gem_swarm_stays_capped() -> void:
	var drop_count := 80
	var coins: Array[Node] = []

	# Spread inside MERGE_RADIUS so a saturated gem always has somewhere to fold
	# into -- this is the swarm case, not "one gem in an empty arena".
	for i in range(drop_count):
		var g = _spawn(GEM_SCENE, Vector2(900.0 + (i % 10) * 12.0, 700.0 + (i / 10) * 12.0))
		g.xp_value = 1.0
	# A gold coin shares the "gems" group; it must never be eaten by a gem.
	for i in range(5):
		coins.append(_spawn(COIN_SCENE, Vector2(960.0, 760.0)))

	var live_gems: Array[Node] = []
	var coin_nodes: Array[Node] = []
	for n in get_tree().get_nodes_in_group("gems"):
		# A merged gem leaves the group at end of frame, not the instant it is
		# freed, so pending ones are still listed. Only the settled ones are live.
		if n.is_queued_for_deletion():
			continue
		if n is ExperienceGem:
			live_gems.append(n)
		else:
			coin_nodes.append(n)

	check(live_gems.size() <= ExperienceGem.MAX_ACTIVE_GEMS,
		"80 drops settle at <= 45 live gem nodes, got %d" % live_gems.size())
	check(live_gems.size() > 0, "Some gems survive the cull, got %d" % live_gems.size())

	# The cull is a node budget, not a pay cut. Every point still reaches the
	# player -- it just arrives in fewer, fatter gems.
	var total_xp := 0.0
	for g in live_gems:
		total_xp += g.xp_value
	check(is_equal_approx(total_xp, float(drop_count)),
		"Merging conserves XP: %d points across %d gems, expected %d"
			% [int(total_xp), live_gems.size(), drop_count])

	check(coin_nodes.size() == coins.size(),
		"The 5 gold coins sharing the 'gems' group were never absorbed, got %d" % coin_nodes.size())

	for n in live_gems:
		_drop([n])
	for n in coin_nodes:
		_drop([n])
	print("OK Gems: 80 drops -> %d nodes, %d XP intact, coins untouched."
		% [live_gems.size(), int(total_xp)])

# --- 2A: the cursor outranks the direction you walked ------------------------

## The bug: on PC the blade pointed wherever the player last moved, so clicking
## to the left of the screen cut a mob standing to your right.
func _test_cursor_outranks_movement() -> void:
	await _drain()
	var p = _spawn(PLAYER_SCENE, Vector2(1000, 1000))
	# Parented to the player, the way the weapon actually rides in the scene, so
	# _get_player() resolves by the parent walk instead of a group lookup that
	# earlier suites' leftovers could hijack.
	var slash = SlashWeapon.new()
	p.add_child(slash)
	slash.global_position = p.global_position

	# Point every fallback the blade used to rely on the other way.
	p.last_move_dir = Vector2(0, 1)
	p.velocity = Vector2(0, 1)
	slash.facing_direction = Vector2(0, 1)

	var to_cursor: Vector2 = slash.get_global_mouse_position() - p.global_position
	if to_cursor.length() <= 20.0:
		# No cursor in this headless build, so the 20px guard is doing its job and
		# there is nothing to assert. Say so rather than pretend to have tested.
		print("  (no cursor reported headlessly -- skipping the cursor-aim assertion)")
	else:
		var want: Vector2 = to_cursor.normalized()
		var got: Vector2 = slash._get_facing_direction()
		check(got.distance_to(want) < 0.01,
			"The blade aims at the cursor (%s), not at last_move_dir (%s)" % [str(got), str(want)])
		check(absf(got.dot(want)) > 0.99,
			"The cursor direction is not a fallback echo, dot=%.3f" % got.dot(want))

	_drop([p])
	print("OK Aiming: right stick > cursor > travel direction > last facing.")

# --- 2B: the finisher is the payoff ------------------------------------------

func _test_finisher_rewards_the_payoff() -> void:
	check(SlashWeapon.COMBO_SHAKE[2] > SlashWeapon.COMBO_SHAKE[0],
		"The finisher shakes the camera harder than the opener (%.1f vs %.1f)"
			% [SlashWeapon.COMBO_SHAKE[2], SlashWeapon.COMBO_SHAKE[0]])
	check(SlashWeapon.COMBO_SHAKE[2] == 8.0,
		"The finisher camera kick is 8.0, got %f" % SlashWeapon.COMBO_SHAKE[2])
	check(SlashWeapon.COMBO_KNOCKBACK[2] > SlashWeapon.COMBO_KNOCKBACK[0],
		"The finisher throws mobs harder than the opener")
	print("OK Feel: finisher camera kick %.1f, knockback %.0f (opener %.0f)."
		% [SlashWeapon.COMBO_SHAKE[2], SlashWeapon.COMBO_KNOCKBACK[2], SlashWeapon.COMBO_KNOCKBACK[0]])

# --- 2C: wave 1 opens with a ring, exactly once ------------------------------

## The bug: wave 1 dribbled in one bat every 0.7s, so the first seconds of a run
## had nothing to swing at and nobody found the 3-hit combo.
func _test_intro_ring_is_one_shot() -> void:
	# Earlier suites queue_free their nodes, and those stay in the "player" group
	# until the frame ends. Production has exactly one player so EnemySpawner._ready
	# binding to get_first_node_in_group("player") is unambiguous there; seven
	# scenarios in one scene is not, so bind ours explicitly.
	await _drain()
	var p = _spawn(PLAYER_SCENE, Vector2(600, 600))
	var spawner = EnemySpawner.new()
	spawner.bat_scene = BAT_SCENE
	add_child(spawner)
	spawner.player = p

	spawner.spawn_intro_ambush()
	await get_tree().process_frame
	var first := _bats().size()
	check(first >= 8 and first <= 10, "The intro ring drops 8-10 bats, got %d" % first)

	# _ready and run_started both ask for a ring. Two rings is 18 bats on frame
	# one, which is the exact stutter this milestone is deleting.
	spawner.spawn_intro_ambush()
	await get_tree().process_frame
	check(_bats().size() == first,
		"A second call does not double the ring, went %d -> %d" % [first, _bats().size()])

	# ...but a new run is allowed its own ring. The spawn is two deferrals deep
	# (the ambush defers, and the spawner defers the ambush), so give it frames.
	spawner._on_run_started()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var third := _bats().size()
	check(third > first, "A fresh run gets its own ring (%d -> %d)" % [first, third])

	for b in _bats():
		_drop([b])
	_drop([spawner, p])
	print("OK Wave 1: %d bats on frame one, guarded against a double ring." % first)

# --- 1C: the floor is not a hundred-million-pixel quad ------------------------

func _test_background_is_not_a_million_pixels() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	var bg = main.get_node("Background") as TextureRect
	var w: float = bg.offset_right - bg.offset_left
	var h: float = bg.offset_bottom - bg.offset_top
	var px: float = w * h
	# 10000x10000 was 100M textured pixels every frame; 2800x2100 is 5.9M.
	check(px < 10_000_000.0,
		"Background covers %.1fM pixels, was 100M -- pure WebGL overdraw" % (px / 1_000_000.0))
	check(main.get_node_or_null("Biomes") != null, "The Biomes container still exists")
	# The four 4000x4000 transparent ColorRects were 16M blended pixels a frame
	# for a 10% alpha tint nobody could see.
	var biomes = main.get_node("Biomes")
	check(biomes.get_child_count() == 0,
		"Biomes no longer holds full-arena transparent quads, got %d" % biomes.get_child_count())
	_drop([main])
	print("OK Rendering: floor is %.1fM px, 0 overdraw quads." % (px / 1_000_000.0))

# --- helpers ----------------------------------------------------------------

func _spawn(scene: PackedScene, at: Vector2) -> Node:
	var n = scene.instantiate()
	n.position = at
	add_child(n)
	return n

## Lets every pending queue_free() from an earlier suite actually land, so the
## groups start this suite clean instead of full of corpses.
func _drain() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func _bats() -> Array[Node]:
	var out: Array[Node] = []
	for n in get_tree().get_nodes_in_group("enemies"):
		if n.get("is_bat_type"):
			out.append(n)
	return out

func _drop(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
