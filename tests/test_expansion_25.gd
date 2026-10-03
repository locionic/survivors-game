extends Node

## Automated Test Suite for Expansion 25.0:
## "Giờ Dừng" -- the two one-frame-lifetime things a dash used to pause.
##
## `_physics_process` splits into `if is_dashing: ... else: ...`, and two things that
## have nothing to do with dashing were living in the else branch:
##
##   * blizzard_slow_timer decayed there, beside the speed maths that *consumes* it.
##     A dash stopped the clock, so every dash handed the debuff its own duration back
##     as free time -- 4.5s of Hàn Khí that lasted 4.5s plus the whole dash in it.
##   * input_direction is a one-frame latch, cleared in the else branch so the poll
##     above it could refill it. Skip the clear and the poll cannot run again for the
##     length of the dash: the stick reading freezes at whatever it was when the dash
##     started, and the frame after the dash ends the player drifts once in a
##     direction they had already let go of.
##
## The glacial_slow_timer lease added in Expansion 23.0 has the identical shape, which
## is why its decay already sat up in the top-of-frame timer block. Same class of bug,
## same place the fix belongs.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

## assert() ABORTS the calling function when it fails: the rest of it never runs, the
## scene never reaches get_tree().quit(), and the suite hangs until the CI timeout
## kills it. Measured 2026-09-30 -- a single failed assert() on a passing suite
## prints the PASS banner and still exits 0. This records each broken expectation
## and drives the exit code from the failure count instead.
var _failures: Array[String] = []

var _player: Player = null

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 25.0 TEST SUITE ===")
	GameManager.is_run_active = false

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.current_health = _player.max_health

	await _test_blizzard_clock_runs_during_a_dash()
	await _test_the_stick_is_polled_again_while_dashing()

	_drop(_player)

	if _failures.is_empty():
		print("=== ALL EXPANSION 25.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

# --- 1. the blizzard's clock -------------------------------------------------

func _test_blizzard_clock_runs_during_a_dash() -> void:
	# Set directly rather than through apply_blizzard_slow() on purpose: that call
	# early-returns when the player has Van Hạc Hai equipped (the blizzard immunity),
	# and the test must measure the clock, not the immunity.
	_player.blizzard_slow_timer = 1.0
	_player.is_dashing = true
	# Longer than the whole observation window, so the dash cannot lapse partway
	# through and quietly start decaying the timer on the dash's behalf. A real 0.30s
	# dash would only freeze the clock for the first 18 of these 40 frames, which
	# still trips the check below but muddies what is being measured.
	_player.dash_timer = 5.0

	const FRAMES: int = 40
	await _physics_frames(FRAMES)

	check(_player.is_dashing, "Precondition: the dash is still running")
	# Read the real tick rate rather than assuming 60 -- at 120Hz forty frames is only
	# a third of a second, and a hardcoded 0.5 ceiling would fail a correct build.
	var expected: float = maxf(0.0, 1.0 - float(FRAMES) / float(Engine.physics_ticks_per_second))
	check(absf(_player.blizzard_slow_timer - expected) < 0.05,
		"A dash does not stop the blizzard's clock (expected ~%.3f left after %d frames, got %.3f)"
			% [expected, FRAMES, _player.blizzard_slow_timer])

	# And the debuff still bites for exactly as long as it says it does, which is the
	# only reason the number above matters.
	_player.is_dashing = false
	_player.blizzard_slow_timer = 1.0
	await _physics_frames(FRAMES)
	check(_player.blizzard_slow_timer < 1.0,
		"Precondition sanity: the timer does run down when not dashing either")

# --- 2. and the stick --------------------------------------------------------

## Synthesised through the Input singleton rather than by assigning the latch, so the
## poll under test is the one that actually runs.
##
## Asserted on last_move_dir and not on input_direction itself: SceneTree.physics_frame
## is emitted *before* nodes process, so reading the latch after an await samples
## whatever the frame last wrote to it. That is a different moment in each build -- the
## fixed one fills the latch last, the broken one clears it last -- so a check on the
## latch passes or fails on intra-frame ordering rather than on behaviour. last_move_dir
## is persistent and only ever written when the reading is non-zero, so it says what the
## player actually last asked for.
func _test_the_stick_is_polled_again_while_dashing() -> void:
	Input.action_press("move_right")
	await _physics_frames(4)
	check(is_equal_approx(_player.last_move_dir.x, 1.0),
		"Precondition: the poll read the held key (got %s)" % _player.last_move_dir)

	# Start the dash and let it run for a few frames FIRST, then swing the stick.
	# The order matters: a broken latch starves the poll only once it is already
	# holding a reading, and a latch cleared at the end of every non-dashing frame
	# starts the dash empty. So flipping the stick on the same frame the dash begins
	# reads as a fix even when the poll is genuinely dead -- which is exactly what a
	# test that flips it too early would report. A real dash lasts 15+ frames, so the
	# stick change lands on a frame where the latch is long since full.
	_player.is_dashing = true
	_player.dash_timer = 5.0
	await _physics_frames(4)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await _physics_frames(4)

	check(is_equal_approx(_player.last_move_dir.x, -1.0),
		"The stick is polled again during a dash -- last_move_dir is still %s, the reading frozen at dash start" % _player.last_move_dir)

	# The one-frame drift at the end of a dash is the same bug's other half, and it is
	# deliberately NOT asserted here: it plays out inside the movement maths, and the
	# stale direction it drifts toward is the same one the dash was already going, so
	# nothing observable from outside a frame separates it. last_move_dir above is the
	# part that can be watched.
	Input.action_release("move_left")
	_player.is_dashing = false
	await _physics_frames(2)

# --- helpers ----------------------------------------------------------------

func _physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func _drop(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()
