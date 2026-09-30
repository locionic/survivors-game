extends Node

## Milestone 4 Part 2: impact hit-stop.
##
## The feature is one line of risk taken very seriously: `Engine.time_scale` is
## global engine state. Dip it and the whole game slows; fail to put it back and
## the rest of the session runs in slow motion with no way out -- on the HTML5
## export, not even a reload fixes it without a page refresh.
##
## Every check here is about the *release*, not the dip. A freeze that feels
## wrong is a tuning problem. A freeze that never ends is a bricked game.

const GAMEMANAGER_SCRIPT: Script = preload("res://scripts/game_manager.gd")

## Godot's assert() only logs a SCRIPT ERROR and keeps running -- the process
## still exits 0, so a suite built on it can never fail a regression run. This
## records each broken expectation and drives the exit code from the failure count.
var _failures: Array[String] = []

## Wall-clock wait, deliberately NOT scaled. The freeze is still live while we
## wait, so a scaled timer here would sit still at 0.2x and the suite would
## appear to hang. ignore_time_scale=true makes this a real-time wait, which is
## exactly the discipline the production release path is built on.
## Wall-clock wait. Deliberately NOT a SceneTreeTimer: create_timer() counts
## down on scaled delta, so while the engine is sitting at 0.2 it would either
## crawl or -- as measured here -- return on the same tick. The suite measures
## real elapsed time against the same clock the production release path uses, so
## what the test observes is exactly what a player experiences.
func _wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame

## Between checks: let any live freeze run its course, then force a known-clean
## engine so one test's leftover can never be misread as the next test's result.
func _settle() -> void:
	for i in 120:
		if GameManager._hitstop_timer <= 0.0:
			break
		await get_tree().process_frame
	GameManager._hitstop_timer = 0.0
	GameManager._hitstop_until_msec = 0
	Engine.time_scale = 1.0

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING MILESTONE 4: IMPACT HIT-STOP TEST SUITE ===")
	# Keep the tree inert so the suite, not the autoload, decides when a run runs.
	GameManager.is_run_active = false

	await _test_dips_and_returns_to_exactly_one()
	await _test_second_impact_does_not_compound()
	await _test_owner_freed_mid_freeze_restores()
	await _test_caller_freed_mid_freeze_still_restores()
	await _test_impacts_are_actually_wired()

	# Whatever happened above, the next suite starts at full speed.
	Engine.time_scale = 1.0
	GameManager._hitstop_timer = 0.0
	get_tree().paused = false

	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)

	if unique.is_empty():
		print("=== ALL IMPACT HIT-STOP TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
		for f in unique:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. The dip, and the way back -------------------------------------------

func _test_dips_and_returns_to_exactly_one() -> void:
	await _settle()

	GameManager.trigger_hitstop(0.075)
	check(Engine.time_scale < 1.0,
		"An impact dips Engine.time_scale, got %f" % Engine.time_scale)
	check(GameManager._hitstop_timer > 0.0, "The owner records that a freeze is live")

	# The dip must be a punch, not a stall. Milestone 3b found that below ~0.2
	# the HTML5 build reads as a tab freeze rather than as impact.
	check(Engine.time_scale >= 0.2,
		"The dip stays at or above 0.2 so it reads as impact, got %f" % Engine.time_scale)

	# Let the wall clock pass the deadline. 0.075s of freeze gets 0.25s of slack
	# so a loaded CI box cannot make this flaky.
	await _wait_real(0.25)

	# Exactly 1.0, not "close to" and not "at least". 0.2000001 is still a
	# permanently slowed game, and is_equal_approx would wave it through.
	check(Engine.time_scale == 1.0,
		"The freeze returns time_scale to exactly 1.0, got %f" % Engine.time_scale)
	check(GameManager._hitstop_timer <= 0.0, "The owner clears its freeze flag on release")
	print("OK A freeze dips the engine and returns it to exactly 1.0.")

# --- 2. Re-entrancy ---------------------------------------------------------

## The swarm case. Ten mobs die in the same frame, or a boss dies while the
## player is already being hit: every one of them asks for a freeze. Stacking
## them would either bury the engine at 0.02 or slide the release out forever.
func _test_second_impact_does_not_compound() -> void:
	await _settle()

	GameManager.trigger_hitstop(0.075)
	var first_scale: float = Engine.time_scale
	var first_deadline: int = GameManager._hitstop_until_msec

	# A second impact that would be far worse if it were allowed to land:
	# deeper, and four times longer.
	GameManager.trigger_hitstop(0.30, 0.02)

	check(is_equal_approx(Engine.time_scale, first_scale),
		"A second impact does not deepen the dip (%f -> %f)" % [first_scale, Engine.time_scale])
	check(Engine.time_scale >= 0.2,
		"A second impact cannot push the engine below the 0.2 impact floor, got %f" % Engine.time_scale)
	check(GameManager._hitstop_until_msec == first_deadline,
		"A second impact does not push the release out (deadline %d -> %d)"
		% [first_deadline, GameManager._hitstop_until_msec])

	# The freeze must still end on the ORIGINAL schedule, not 300ms later.
	await _wait_real(0.25)
	check(Engine.time_scale == 1.0,
		"The original schedule still releases, got %f" % Engine.time_scale)
	print("OK A second impact mid-freeze neither deepens nor extends the freeze.")

# --- 3. The owner is freed mid-freeze ---------------------------------------

## The classic brick. The freeze is live, and the node that owns it is torn
## down before it ever gets to restore the scale. Nothing in the scene is left
## holding a reference to the restore, so the engine runs at 0.2 forever.
func _test_owner_freed_mid_freeze_restores() -> void:
	await _settle()

	# A disposable owner: same script, never added to the tree, so its _process
	# never runs. If the release only ever happened in _process, this node could
	# not possibly restore the scale and the check below would fail.
	var ghost: Node = GAMEMANAGER_SCRIPT.new()
	ghost.trigger_hitstop(0.30, 0.15)
	check(is_equal_approx(Engine.time_scale, 0.15),
		"The disposable owner dips the engine, got %f" % Engine.time_scale)

	# Tearing the owner down mid-freeze, exactly like a scene change or a quit.
	ghost.free()

	check(Engine.time_scale == 1.0,
		"Freeing the owner mid-freeze still leaves time_scale at 1.0, got %f"
		% Engine.time_scale)
	check(GameManager._hitstop_timer <= 0.0,
		"The autoload owner was not left holding a phantom freeze")
	print("OK Freeing the owner mid-freeze restores the engine immediately.")

# --- 4. The caller is freed mid-freeze --------------------------------------

## The other half of the same bug, and the one that actually happens in play:
## the enemy that earned the freeze dies and frees itself a frame later. The
## scale has to come back even though the requester no longer exists.
func _test_caller_freed_mid_freeze_still_restores() -> void:
	await _settle()

	var victim := Node2D.new()
	add_child(victim)

	GameManager.trigger_hitstop(0.075)
	check(Engine.time_scale < 1.0, "The freeze is live before the requester is freed")

	# The requester is destroyed mid-freeze. It holds no freeze state of its own,
	# which is the whole point of routing through a single central owner.
	victim.free()
	check(not is_instance_valid(victim), "The requesting node really was freed")

	await _wait_real(0.25)
	check(Engine.time_scale == 1.0,
		"A freeze survives its requesting node being freed, got %f" % Engine.time_scale)
	print("OK The freeze outlives the node that requested it.")

# --- 5. The impacts are actually wired up -----------------------------------

## A hit-stop that nothing calls is not a feature, it is a helper. Each of the
## three qualifying impacts has to dip the engine through its own real code
## path, not through a direct trigger_hitstop() call from this suite.
func _test_impacts_are_actually_wired() -> void:
	await _settle()

	# Synergy proc: the Lotus Storm / Frost Sovereign fusions.
	var dagger = load("res://scenes/weapon.tscn").instantiate()
	add_child(dagger)
	dagger.global_position = Vector2.ZERO
	dagger.is_active = false # keep _process from auto-firing mid-test
	dagger.evolve_to_lotus_storm()
	check(Engine.time_scale < 1.0,
		"A synergy fusion (Lotus Storm) earns a hit-stop, got %f" % Engine.time_scale)
	dagger.free()
	await _settle()

	var slash = load("res://scenes/slash_weapon.tscn").instantiate()
	add_child(slash)
	slash.global_position = Vector2.ZERO
	slash.is_active = false
	slash.evolve_to_frost_sovereign()
	check(Engine.time_scale < 1.0,
		"A synergy fusion (Frost Sovereign) earns a hit-stop, got %f" % Engine.time_scale)
	slash.free()
	await _settle()

	# Player taking damage. Dodge is randomised, so pin it to zero -- a lucky
	# roll must not be able to make this check fail.
	var player = load("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.global_position = Vector2.ZERO
	player.char_dodge_bonus = 0.0
	player.drunken_buff_timer = 0.0
	player.is_invulnerable = false
	player.current_health = 9999.0
	player.take_damage(20.0)
	check(Engine.time_scale < 1.0,
		"The player taking damage earns a hit-stop, got %f" % Engine.time_scale)
	player.free()
	await _settle()

	# Enemy death stays gated to boss/elite by Milestone 3b (a bat swarm must
	# never stop the engine), and that gate is asserted by test_web_perf_milestone_3b.
	# Here we only pin the depth floor that gate and the other two sites share.
	check(is_equal_approx(GameManager.HITSTOP_SCALE, 0.2),
		"The shared hit-stop depth is 0.2, got %f" % GameManager.HITSTOP_SCALE)
	print("OK Player damage and both synergy fusions dip the engine for real.")
