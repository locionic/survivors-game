#!/usr/bin/env bash
# Quality gate for the autonomous agent loop. The fcc-task worker looks for
# exactly this path (worker.py:146); without it the harness logs "no
# verification gate detected" and passes every task whether or not it works.
#
# Headless Godot does not fail on its own, so a suite fails on either signal:
#   * non-zero exit or timeout -- a failed assert() aborts _ready() before the
#     scene reaches get_tree().quit(), so a broken suite HANGS until killed;
#   * "SCRIPT ERROR:" or "CHECK FAILED:" in the output -- covers assert()
#     failures, GDScript parse errors, and the Milestone 4 check() helper.
# A bare "ERROR:" is deliberately ignored: passing suites leak RID/Shape2D
# objects at shutdown and print those regardless.
#
# `set -e` is intentionally absent so one bad suite does not hide the rest.
set -uo pipefail

GODOT="${GODOT:-godot}"
SUITE_TIMEOUT="${SUITE_TIMEOUT:-120}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Keep every write Godot makes inside this repository. On Linux user:// resolves to
# $XDG_DATA_HOME/godot/app_userdata/<project>, so pointing XDG_DATA_HOME at a scratch
# directory here means a suite run cannot touch the save Godot keeps outside this
# repo, and does not even read it: the gate is seeded from nothing, so every run
# starts from the same blank save rather than from whatever the developer last
# played. That makes results reproducible by anyone, on any machine.
#
# The comment this replaces claimed Godot "ignores XDG_DATA_HOME" for user://. It
# does not -- measured 2026-10-02 by running a suite with XDG_DATA_HOME set to a
# repo-local directory and finding save_data.cfg written there.
CI_USERDATA="${CI_USERDATA:-$PROJECT_DIR/.ci_userdata}"
export XDG_DATA_HOME="$CI_USERDATA"
mkdir -p "$XDG_DATA_HOME/godot/app_userdata"

LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT

# Every suite shares one save file -- user://. Ten of them write to it and one
# (test_expansion_16) spends gold, so a suite inherits whatever the previous one left
# behind. That effect makes the gate order-dependent: a suite passes alone and fails
# after its neighbours have run, which is indistinguishable from a flake and is how
# the one-off failures in this repo's history should be read.
#
# This used to snapshot the developer's real save and restore it before each suite.
# That is gone: the real save lives outside this repository, and a gate that neither
# writes nor reads outside the directory it owns is the whole point. Deleting the
# scratch save between suites is the better version of the same guarantee -- every
# suite starts from Godot's defaults rather than from a copy, and those defaults are
# exactly what the old snapshot faked:
#
#   selected_character = "knight"  (game_manager.gd:57, the default)
#   total_gold         = 0         (game_manager.gd:56, the default)
#
# The knight default is the load-bearing one, and it is why the old sed pin is no
# longer needed. A suite that inherited the developer's hero inherited that hero's
# stats, and take_damage() rolls against them: Tiêu Lãng carries dodge_bonus 0.30, so
# every suite asserting an exact HP delta was a 30% coin flip on whoever was last
# played -- measured, not guessed. test_expansion_11 hung on 6 of 20 runs that way,
# dying on "Qi Shield depleted appropriately accounting for armor" and then burning
# the full 120s timeout, because a failed assert aborts _ready() before quit().
# Starting every suite from the default hero removes the coin flip rather than
# pinning it to a value that has to be re-checked when the roster changes. Suites
# that want a specific hero still call select_character() themselves.
reset_save() {
	find "$XDG_DATA_HOME/godot/app_userdata" -maxdepth 2 -name save_data.cfg \
		-delete 2>/dev/null
	return 0
}
trap 'rm -rf "$LOG_DIR"; reset_save' EXIT


failed=0
total=0

for suite in "$PROJECT_DIR"/tests/*.tscn; do
	name="$(basename "$suite" .tscn)"
	total=$((total + 1))
	log="$LOG_DIR/$name.log"

	reset_save   # this suite starts from defaults, not its predecessor's leftovers
	timeout "$SUITE_TIMEOUT" "$GODOT" --headless --path "$PROJECT_DIR" "tests/$name.tscn" >"$log" 2>&1
	code=$?

	if [ "$code" -eq 124 ] || [ "$code" -eq 137 ]; then
		printf 'HANG  %-40s no quit() within %ss\n' "$name" "$SUITE_TIMEOUT"
		failed=$((failed + 1))
	elif [ "$code" -ne 0 ]; then
		printf 'FAIL  %-40s exit %s\n' "$name" "$code"
		failed=$((failed + 1))
	elif grep -qE 'SCRIPT ERROR:|CHECK FAILED:' "$log"; then
		printf 'FAIL  %-40s\n' "$name"
		grep -E 'SCRIPT ERROR:|CHECK FAILED:' "$log" | head -3 | sed 's/^/        /'
		failed=$((failed + 1))
	else
		printf 'ok    %-40s\n' "$name"
	fi
done

echo
if [ "$failed" -gt 0 ]; then
	echo "GATE FAILED: $failed of $total suites failed."
	exit 1
fi
echo "GATE PASSED: $total/$total suites clean."
