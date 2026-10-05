extends "res://tests/suite_base.gd"

## Expansion 63.0 (plan Task 4): the Emscripten web save-sync guard.
##
## save_game_data() flushed the IDBFS mount with a fire-and-forget sync:
##
##     JavaScriptBridge.eval("... FS.syncfs(false, function(err){}); ...")
##
## The callback took no notice of being a callback. Nothing recorded that a sync was
## outstanding, so the very next save issued a second one, and Emscripten answers the
## overlap exactly as expected:
##
##     warning: 2 FS.syncfs operations in flight at once
##
## Measured on the itch.io web build, 2026-10-05. A grep of scripts/ and tests/ for
## `is_syncing|syncfs|_pending_save|save_queue|coalesc` returned exactly one hit: the
## call itself. No flag, no queue, no coalescing. One run reaches save_game_data()
## from a dozen writers -- every add_gold(), every purchase, every stage pick
## (game_manager.gd:475/481/493/537/942/959/976/981/1001/1011/1029/1080 plus
## hermit_shop_ui.gd:152) -- so the overlap is routine, not an edge case.
##
## WHAT IS TESTED, AND WHERE. Headless native Godot has no FS and no
## JavaScriptBridge, so the sync itself is unobservable here. The guard, though, is
## not JS: it is the two-field state machine in game_manager.gd, and everything
## below drives it through the same two functions _request_web_filesystem_sync()
## and _on_filesystem_sync_done() call in production. Only the JavaScriptBridge.eval()
## that emits the sync is skipped, which is the part that cannot be reached from here.
##
## WHAT THIS DOES NOT CLAIM. The callback -> follower wiring and the JavaScript text
## are not executed on native. The source half at the end reads game_manager.gd back
## and pins them, because a behavioural test of the state machine alone would still
## go green if someone deleted the _request_web_filesystem_sync() call from
## save_game_data() and left the helper orphaned -- a correct guard, reached by
## nobody. That is the failure the source half exists to catch.

## Reset to the state a fresh boot has, so no test in this file inherits a held slot
## from the one before it. Also the teardown: the guard is a GameManager member and
## GameManager is an autoload, so anything left held outlives this file.
func _reset() -> void:
	GameManager.is_syncing_filesystem = false
	GameManager._pending_filesystem_sync = false
	GameManager.filesystem_syncs_issued = 0

## What one web save costs, minus the JavaScriptBridge.eval() that emits the sync.
## True when this caller took the slot, i.e. a sync really was issued on its behalf.
## This is _request_web_filesystem_sync()'s guard clause verbatim -- the same
## function, called the same way, not a re-implementation of it.
func _web_save() -> bool:
	return GameManager._claim_filesystem_sync_slot()

## What the JS callback does: release the slot, then issue the one follower that
## release says is owed. _on_filesystem_sync_done()'s body, with the request call
## routed back through _web_save() so no JavaScriptBridge is touched on native.
func _sync_completed() -> void:
	if GameManager._release_filesystem_sync_slot():
		_web_save()

# --- 1. a burst of saves costs one sync, not one each -------------------------

func _test_a_burst_of_saves_issues_exactly_one_sync() -> void:
	_reset()
	if not check(_web_save(), "the first save must own the sync slot"):
		return
	var issued := GameManager.filesystem_syncs_issued
	# Nine more while that one is in flight. This is the measured itch.io burst:
	# a shop purchase, a gold pickup, a stage pick, all inside one sync's lifetime.
	for i in range(9):
		check(not _web_save(), "save %d was granted a second concurrent sync" % (i + 2))
		check(GameManager.is_syncing_filesystem,
			"save %d let go of the in-flight slot" % (i + 2))
	check(GameManager.filesystem_syncs_issued == issued,
		"ten overlapping saves issued %d syncs, want 1" % GameManager.filesystem_syncs_issued)
	check(GameManager._pending_filesystem_sync,
		"nine refused saves left nothing recorded, so the last one would be lost")

# --- 2. and the refused save is not simply dropped ---------------------------

func _test_a_save_requested_mid_sync_is_not_lost() -> void:
	# The failure mode of the wrong guard. "Skip the sync while one is in flight"
	# stops the overlap and also loses the save: the bytes written after the running
	# sync snapshot never reach IndexedDB, and the player returns to a tab that
	# restored the state from before the purchase. Both halves are asserted -- one
	# follower is issued, and exactly one, so the guard cannot become a second
	# source of overlap.
	_reset()
	_web_save()
	_web_save()  # arrives while the first sync is still running
	_sync_completed()
	check(GameManager.filesystem_syncs_issued == 2,
		"a save that arrived mid-sync was dropped; %d syncs issued, want 2"
		% GameManager.filesystem_syncs_issued)
	check(GameManager.is_syncing_filesystem,
		"the follower must hold the slot, or the two overlap after all")
	# The follower's own completion, with nothing saved since, must go quiet -- an
	# unconditional re-issue here is an infinite sync loop, and it is the other way
	# this guard gets written wrong.
	_sync_completed()
	check(GameManager.filesystem_syncs_issued == 2,
		"an idle save stream must stop syncing; %d syncs issued, want 2"
		% GameManager.filesystem_syncs_issued)
	check(not GameManager.is_syncing_filesystem,
		"the guard is still holding a slot after the last completion")
	check(not GameManager._pending_filesystem_sync,
		"a consumed pending flag must not linger")

# --- 3. the invariant over a long interleaved stream -------------------------

func _test_an_interleaved_stream_converges_and_never_overlaps() -> void:
	# The property rather than the two cases: saves and browser completions arriving
	# in every order still end idle, never overlap, and never strand a sync. The
	# pattern is fixed rather than random so a gate failure is reproducible, and it
	# mixes long bursts (8) with quiet stretches (0) so the follower path is taken
	# and abandoned in the same run.
	_reset()
	var pattern: Array[int] = [1, 1, 3, 0, 2, 5, 0, 1, 8, 0, 0, 4]
	var saves := 0
	var completions := 0
	var overlaps := 0
	for _lap in range(17):
		for burst in pattern:
			for _i in range(burst):
				saves += 1
				# A sync may be issued exactly when the slot was free beforehand.
				# Counted rather than checked inline: ~1000 iterations of a failing
				# check would bury the rest of the suite's output.
				var was_idle := not GameManager.is_syncing_filesystem
				var issued := _web_save()
				if issued != was_idle:
					overlaps += 1
			# Drain the way the browser delivers completions: one at a time, each
			# one possibly waking a follower.
			while GameManager.is_syncing_filesystem:
				completions += 1
				if not check(completions < 500,
						"the guard never released the slot (%d completions and counting)"
						% completions):
					return
				_sync_completed()
	check(overlaps == 0,
		"%d save(s) were issued while another sync was still in flight" % overlaps)
	check(not GameManager.is_syncing_filesystem,
		"the guard is still holding a slot after the save stream stopped")
	check(not GameManager._pending_filesystem_sync,
		"a pending sync is still queued after the save stream stopped")
	# Every sync that went out reported back, and every save that arrived during one
	# was paid for: issued == completions is the "nothing stranded, nothing owed" sum.
	check(GameManager.filesystem_syncs_issued == completions,
		"%d syncs issued but only %d completions seen -- one is stranded in flight"
		% [GameManager.filesystem_syncs_issued, completions])
	# A guard that never issued anything would satisfy every check above. This is the
	# canary that the stream actually exercised it.
	check(GameManager.filesystem_syncs_issued > 1,
		"the pattern only produced %d sync(s) -- it never reached the burst path"
		% GameManager.filesystem_syncs_issued)
	print("  [63] %d saves -> %d syncs issued, %d completions, 0 overlaps"
		% [saves, GameManager.filesystem_syncs_issued, completions])

# --- 4. the desktop path is untouched ----------------------------------------

func _test_the_desktop_save_path_never_touches_the_guard() -> void:
	# save_game_data() must keep the guard behind OS.has_feature("web"). Hoisting
	# the request out of that branch looks harmless -- the native half still writes
	# its ConfigFile -- and on a platform with no FS to report completion the slot
	# is then claimed on the first save and never released, so every later sync is
	# refused. The save file keeps working; IndexedDB quietly stops, and only on the
	# build where the player cannot see the symptom.
	if not check(not OS.has_feature("web"),
			"this suite asserts the non-web path; on a web export it is meaningless"):
		return
	_reset()
	var gold_backup := GameManager.total_gold
	for i in range(5):
		GameManager.total_gold = 100 + i
		GameManager.save_game_data()
	check(GameManager.filesystem_syncs_issued == 0,
		"five desktop saves issued %d web syncs, want 0" % GameManager.filesystem_syncs_issued)
	check(not GameManager.is_syncing_filesystem,
		"a desktop save claimed the web sync slot and never released it")
	check(not GameManager._pending_filesystem_sync,
		"a desktop save queued a web sync that can never be flushed")
	# The ConfigFile half is what desktop actually depends on, so assert it survived:
	# a guard that broke the native save would trade a console warning for real data
	# loss, which is a worse bug than the one this suite exists for.
	GameManager.total_gold = 12345
	GameManager.save_game_data()
	var cfg := ConfigFile.new()
	if check(cfg.load(GameManager.SAVE_PATH) == OK, "the desktop save file did not load"):
		check(int(cfg.get_value("player", "total_gold", -1)) == 12345,
			"the desktop ConfigFile save is broken by the guard; got %s"
			% str(cfg.get_value("player", "total_gold", null)))
	GameManager.total_gold = gold_backup
	GameManager.save_game_data()  # leave the scratch save as we found it

# --- 5. the guard is wired, and there is only one way in ---------------------

static func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return "" if f == null else f.get_as_text()

## `func_name` and its body. GDScript delimits blocks by indentation, so the first
## line back at column 0 after the declaration ends the function. Doc comments above
## the declaration are not part of it, which is what lets these checks look at code
## and not prose.
static func _body(src: String, func_name: String) -> String:
	var out: Array[String] = []
	var inside := false
	for line in src.split("\n"):
		if not inside:
			if line.begins_with("func %s(" % func_name):
				inside = true
				out.append(line)
		elif line.begins_with("\t") or line.is_empty():
			out.append(line)
		else:
			break
	return "\n".join(out)

func _test_the_only_syncfs_call_is_guarded() -> void:
	var src := _read("res://scripts/game_manager.gd")
	if not check(src != "", "could not read res://scripts/game_manager.gd"):
		return
	var save_body := _body(src, "save_game_data")
	var guard_body := _body(src, "_request_web_filesystem_sync")
	var cb_body := _body(src, "_on_filesystem_sync_done")
	if not check(save_body != "", "save_game_data() is not in game_manager.gd"):
		return
	if not check(guard_body != "", "_request_web_filesystem_sync() is not in game_manager.gd"):
		return
	if not check(cb_body != "", "_on_filesystem_sync_done() is not in game_manager.gd"):
		return

	# One call site in the whole autoload. A second one is a second way back to the
	# overlap, and grep is how the pre-fix version was found.
	check(src.count("FS.syncfs(false") == 1,
		"game_manager.gd has %d FS.syncfs(false) call sites, want exactly 1"
		% src.count("FS.syncfs(false"))
	check(not save_body.contains("FS.syncfs"),
		"save_game_data() issues a raw sync again instead of going through the guard")
	check(save_body.contains("_request_web_filesystem_sync()"),
		"save_game_data() never calls the guard, so the state machine is dead code")
	# The guard has to consult the in-flight flag BEFORE it emits, or the move is
	# cosmetic and the first overlap still happens.
	var claim_at := guard_body.find("_claim_filesystem_sync_slot()")
	check(claim_at >= 0, "_request_web_filesystem_sync() never claims the sync slot")
	check(claim_at < guard_body.find("FS.syncfs(false"),
		"the slot is claimed after the sync is issued, which is one overlap late")
	# The missing-FS wrapper is load-bearing. A portal or desktop web-shell run with
	# no FS must not throw, and the fallback call is what stops the swallowed error
	# from stranding the slot and disabling every sync that follows.
	check(guard_body.contains("typeof FS !== 'undefined'"),
		"the missing-FS guard is gone from the sync path")
	check(guard_body.contains("catch (e) {}"),
		"the try/catch that keeps a missing FS from throwing is gone")
	check(guard_body.contains("window.SurvivorQuest_syncfs_done();"),
		"the no-FS path never calls the completion callback, so the slot is stranded")
	# The callback must release and re-issue, or every mid-sync save is dropped.
	check(cb_body.contains("_release_filesystem_sync_slot()"),
		"the sync callback never releases the in-flight slot")
	check(cb_body.contains("_request_web_filesystem_sync()"),
		"the sync callback never re-issues the owed follow-up sync")
	# A JavaScriptBridge callback is always invoked with its JS arguments collected
	# into a single Array; a callable of any other arity is silently never called,
	# which would strand the slot on the very first web save.
	check(cb_body.contains("_args: Array"),
		"_on_filesystem_sync_done() must take exactly one Array argument")
	# The pre-fix literal: a callback invoked and never listened to.
	check(not src.contains("function(err){}"),
		"the fire-and-forget sync is back in game_manager.gd")

# --- 6. and the guard boots idle, with the two entry points intact -----------

func _test_the_guard_boots_idle() -> void:
	# Renaming or deleting either state function turns every behavioural test above
	# into a runtime error instead of a failed check, and a suite that dies on the
	# first line reports nothing about the guard. Assert the shape first.
	for m in ["_claim_filesystem_sync_slot", "_release_filesystem_sync_slot",
			"_on_filesystem_sync_done", "_request_web_filesystem_sync"]:
		check(GameManager.has_method(m), "GameManager.%s() is gone" % m)
	_reset()
	check(not GameManager.is_syncing_filesystem, "the guard must not boot holding a slot")
	check(not GameManager._pending_filesystem_sync,
		"the guard must not boot with a sync already queued")
	check(GameManager.filesystem_syncs_issued == 0, "the issued counter must boot at 0")

func _ready() -> void:
	print("=== RUNNING EXPANSION 63.0: WEB SAVE-SYNC COALESCING GUARD ===")
	GameManager.is_run_active = false

	_test_the_guard_boots_idle()
	_test_a_burst_of_saves_issues_exactly_one_sync()
	_test_a_save_requested_mid_sync_is_not_lost()
	_test_an_interleaved_stream_converges_and_never_overlaps()
	_test_the_desktop_save_path_never_touches_the_guard()
	_test_the_only_syncfs_call_is_guarded()

	_reset()
	if _failures.is_empty():
		print("=== ALL EXPANSION 63.0 TESTS PASSED 100% CLEANLY! ===")
	get_tree().quit(_exit_code())
