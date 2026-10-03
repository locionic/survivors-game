extends Node

## The check() harness, in one place, for the suites that used to call assert().
##
## Fifteen suites -- 638 asserts -- were written on the belief that a failed
## assert() "only logs a SCRIPT ERROR and keeps running". That belief is the
## exact inverse of what the engine does, and it is the reason none of them were
## ever converted. Measured 2026-09-30 with a throwaway probe:
##
##   assert(false, "X") followed by get_tree().quit(0)  ->  quit is never
##   reached, the scene never exits, and the run hangs until killed (exit 124).
##
## So a suite built on assert() fails by hanging for the full 120s, and -- worse
## -- the abort kills the rest of the calling function, which masks every later
## expectation in the same _ready(). One stale title assert in
## test_expansion_20.gd was hiding a second equally stale one. scripts/ci.sh's
## `SCRIPT ERROR:` grep is what made those suites fail at all; the exit code
## never moved.
##
## check() returns its condition instead of aborting, so every expectation in the
## suite still runs, every failure is printed once, and the exit code comes from
## the failure count. A suite's teardown is one line:
##
##     get_tree().quit(_exit_code())
##
## which is the whole reason this lives here rather than being copied 15 times.

var _failures: Array[String] = []

## Record an expectation without aborting the rest of the suite. The `push_error`
## is not decoration: ci.sh greps for "CHECK FAILED:" and that grep is what turns
## a soft failure into a hard gate failure, so a check() without it would pass.
func check(cond: bool, msg: String) -> bool:
	if not cond:
		_failures.append(msg)
		push_error("CHECK FAILED: %s" % msg)
	return cond

## Dedupes, prints, and returns the process exit code. Call it from quit() -- a
## suite that prints its own PASS banner should guard that on
## `_failures.is_empty()` first, or it will claim success on a failed run, which
## is the one behaviour the assert()-based suites could not get wrong by
## accident and this harness can.
func _exit_code() -> int:
	get_tree().paused = false
	var unique: Array[String] = []
	for f in _failures:
		if not unique.has(f):
			unique.append(f)
	if unique.is_empty():
		return 0
	print("=== %d CHECK(S) FAILED (first %d unique) ===" % [_failures.size(), unique.size()])
	for f in unique:
		print("  FAIL: %s" % f)
	return 1
