extends Node

## Automated Test Suite for Expansion 37.0:
## "Thắp Nút Vàng Thêm Một Lần Nữa" -- the rewarded-ad gold doubling, claimable as
## many times as the player likes.
##
## The run ends, the game-over panel opens, and it offers two things the player did
## not earn by playing well: a revive and a doubled purse, each behind a rewarded ad.
## The revive is guarded. has_revived_this_run is set the moment the ad pays out, and
## hud.gd:1057 reads it straight back as the button's visibility, so a second click
## has nothing left to press.
##
## The doubling has no such flag anywhere in the codebase. double_run_gold() opens
## with two lines and no question asked:
##
##     total_gold += run_gold
##     run_gold  *= 2
##
## ...and the button meant to stop a second press is re-enabled by the very callback
## that disables it. hud.gd:1130-1136, in order:
##
##     double_gold_button.disabled = true      <- claim spent, button greyed out
##     double_gold_button.text = "Gold Doubled! (x2)"
##     _on_player_died()                       <- refresh the stats label
##
## ...and _on_player_died() ends with, at hud.gd:1057-1059:
##
##     revive_button.visible      = not GameManager.has_revived_this_run
##     double_gold_button.visible = true
##     double_gold_button.disabled = false     <- the guard, undone
##
## So one ad view buys a button that stays live. And because the payout reads the
## already-doubled run_gold, the repeats are not additive, they are compounding:
##
##     press 1:  purse += R      run_gold = 2R
##     press 2:  purse += 2R     run_gold = 4R
##     press 3:  purse += 4R     run_gold = 8R
##     press 5:  purse += 31R    run_gold = 32R
##
## R(2^n - 1) for n presses. The first ad view is the only one the game charged for.
##
## Every read of the new flag goes through .get() rather than a typed property, on
## purpose: a direct `GameManager.has_doubled_gold_this_run` is a *parse* error until
## the flag exists, and a suite that cannot parse never calls quit(), so the gate sees
## a hang (exit 124) instead of a failure and no red is ever recorded. Through get()
## this file compiles against both builds, so the pre-fix run is a real red.
##
## The guard goes in the function rather than in the HUD, for the same reason the
## revive flag is worth having: the flag and the gold have to move together, and
## splitting them is what produced the bug. hud.gd:1122 sets has_revived_this_run
## from the button handler while the reward itself lives somewhere else entirely --
## for this one there was no reward function to put it near.

const RUN_GOLD: int = 100
## Enough presses that the difference is not a rounding argument. Five is 32x the
## single payout under the old code and 1x under the new, so no tolerance is needed
## on either side and the comparison can be exact.
const PRESSES: int = 5

var _failures: Array[String] = []
var _save: Dictionary = {}

func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

func _ready() -> void:
	print("=== RUNNING EXPANSION 37.0 TEST SUITE ===")
	# double_run_gold() is the one call under test that persists, and the developer's
	# save is the one thing in this repo that is not ours to rewrite.
	_save = _grab()

	_test_the_doubling_is_claimable_once()
	_test_one_claim_is_still_worth_taking()
	_test_a_new_run_can_claim_it_again()
	_test_the_flag_is_what_the_button_reads()
	_test_the_revoke_reward_is_unaffected()

	_finish()

# --- 1. the compounding ---------------------------------------------------------

## The bug, as arithmetic. The old code pays R, 2R, 4R, 8R, 16R across five presses;
## the new code pays R once and refuses the rest. Both halves are asserted, because
## "refuses" on its own would also be satisfied by a button that does nothing.
func _test_the_doubling_is_claimable_once() -> void:
	GameManager.start_new_run()
	var purse_before := GameManager.total_gold
	GameManager.run_gold = RUN_GOLD

	for i in PRESSES:
		GameManager.double_run_gold()

	var paid := GameManager.total_gold - purse_before
	check(paid == RUN_GOLD,
		"%d presses pay out %d where the single claim is %d: the repeat is compounding"
			% [PRESSES, paid, RUN_GOLD])
	check(GameManager.run_gold == RUN_GOLD * 2,
		"%d presses leave run_gold at %d where one doubling makes it %d"
			% [PRESSES, GameManager.run_gold, RUN_GOLD * 2])

# --- 2. the first claim still pays ----------------------------------------------

## The over-correction guard. Every other assertion in this suite is satisfied by
## deleting double_run_gold()'s body and returning early from the first call -- the ad
## would never pay, the button would grey out, and cases 1, 3 and 4 would all still
## pass. This is the case that says the reward is still a reward.
func _test_one_claim_is_still_worth_taking() -> void:
	GameManager.start_new_run()
	var purse_before := GameManager.total_gold
	GameManager.run_gold = RUN_GOLD

	GameManager.double_run_gold()

	check(GameManager.total_gold - purse_before == RUN_GOLD,
		"The first press pays the run's gold: purse +%d, expected +%d"
			% [GameManager.total_gold - purse_before, RUN_GOLD])
	check(GameManager.run_gold == RUN_GOLD * 2,
		"The first press doubles the run's gold for the results screen: %d, expected %d"
			% [GameManager.run_gold, RUN_GOLD * 2])

	# And a refused second press costs nothing at all, rather than quietly paying a
	# little. Set run_gold to something new so a stale doubled value cannot pass for
	# "refused" -- the old code would leave it at 1000 and pay 200.
	GameManager.run_gold = 500
	GameManager.double_run_gold()
	check(GameManager.run_gold == 500, "A refused press leaves run_gold alone: %d" % GameManager.run_gold)

# --- 3. the claim is per run ----------------------------------------------------

## The failure mode of the obvious alternative. Guarding on "has this run doubled" is
## only correct if the flag is cleared, and start_new_run() is where every other piece
## of per-run state is reset -- has_revived_this_run at :657, run_gold at :654. Miss
## this one line and the feature silently dies after the player's first run, which is
## every player who plays more than one.
func _test_a_new_run_can_claim_it_again() -> void:
	GameManager.start_new_run()
	GameManager.run_gold = 7
	GameManager.double_run_gold()
	check(GameManager.run_gold == 14, "The fresh run's gold doubled: %d" % GameManager.run_gold)

# --- 4. the flag the button reads -----------------------------------------------

## hud.gd:1059 sets double_gold_button.disabled straight off this flag, the same way
## :1057 reads has_revived_this_run. Pinned here because the two together are the
## entire UI contract: the button is enabled exactly when the claim is unspent, and
## nothing else decides. Note the HUD is a node inside main.tscn rather than its own
## scene, so this asserts the value the button is derived from rather than booting the
## game to read a Button.disabled back -- the claim itself is closed in the function,
## so a live button can no longer pay a second time regardless of how it is drawn.
func _test_the_flag_is_what_the_button_reads() -> void:
	GameManager.start_new_run()
	check(not _claimed(),
		"A new run leaves the doubling unclaimed, so the button starts live")
	GameManager.run_gold = RUN_GOLD
	GameManager.double_run_gold()
	check(_claimed(),
		"A paid claim sets the flag the button greys itself out on")
	GameManager.start_new_run()
	check(not _claimed(),
		"The next run releases the button again")

# --- 5. the sibling reward is independent ---------------------------------------

## Two rewarded offers sit on the same panel. Spending the doubling must not consume
## the revive, and vice versa -- a shared flag would be the lazy way to close this and
## it would quietly remove the other button from the panel.
func _test_the_revoke_reward_is_unaffected() -> void:
	GameManager.start_new_run()
	GameManager.run_gold = RUN_GOLD
	GameManager.double_run_gold()

	check(_claimed(), "The doubling is claimed")
	check(not _revived(),
		"Claiming the doubling did not spend the revive: hud.gd:1057 would hide the button")

	GameManager.has_revived_this_run = true
	check(_claimed(),
		"Spending the revive did not un-spend the doubling")

# --- helpers -------------------------------------------------------------------

## has_doubled_gold_this_run, read dynamically. null before the fix, so the "claimed"
## checks fail and the "unclaimed" ones pass -- which is the honest pre-fix result.
func _claimed() -> bool:
	return GameManager.get("has_doubled_gold_this_run") == true

func _revived() -> bool:
	return GameManager.get("has_revived_this_run") == true

## {"bytes": <contents>, "existed": <bool>}. A missing file is restored by removal
## rather than by writing an empty stub.
func _grab() -> Dictionary:
	var f := FileAccess.open("user://save_data.cfg", FileAccess.READ)
	if f == null:
		return {"bytes": PackedByteArray(), "existed": false}
	var bytes := f.get_buffer(f.get_length())
	f.close()
	return {"bytes": bytes, "existed": true}

func _finish() -> void:
	if not _put_back():
		check(false, "The developer's save was restored byte for byte")

	if _failures.is_empty():
		print("=== ALL EXPANSION 37.0 TESTS PASSED 100% CLEANLY! ===")
		get_tree().quit(0)
	else:
		print("=== %d CHECK(S) FAILED ===" % _failures.size())
		for f in _failures:
			print("  FAIL: %s" % f)
		get_tree().quit(1)

func _put_back() -> bool:
	if not bool(_save.get("existed", false)):
		if FileAccess.file_exists("user://save_data.cfg"):
			return DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save_data.cfg")) == OK
		return true
	var f := FileAccess.open("user://save_data.cfg", FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(_save["bytes"])
	f.close()
	return true
