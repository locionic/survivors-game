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
LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT

failed=0
total=0

for suite in "$PROJECT_DIR"/tests/*.tscn; do
	name="$(basename "$suite" .tscn)"
	total=$((total + 1))
	log="$LOG_DIR/$name.log"

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
