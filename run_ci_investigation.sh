#!/usr/bin/env bash
# Script to run CI multiple times and record failures

RESULTS_FILE="$HOME/ci_flake_investigation_results.txt"
> "$RESULTS_FILE"

MAX_RUNS="${MAX_RUNS:-25}"
GODOT="${GODOT:-godot}"

echo "Starting CI flake investigation - $MAX_RUNS runs" | tee -a "$RESULTS_FILE"
echo "Results will be saved to: $RESULTS_FILE" | tee -a "$RESULTS_FILE"

failed_count=0
total_count=0

for run in $(seq 1 $MAX_RUNS); do
    echo "=== RUN $run ===" | tee -a "$RESULTS_FILE"

    GODOT="$GODOT" ./scripts/ci.sh 2>&1 | tee -a "$RESULTS_FILE"

    if [ $? -ne 0 ]; then
        failed_count=$((failed_count + 1))
        echo "FAILURE DETECTED in run $run" >> "$RESULTS_FILE"
    else
        echo "RUN $run PASSED" | tee -a "$RESULTS_FILE"
    fi
    total_count=$((total_count + 1))
    echo "" >> "$RESULTS_FILE"
done

echo "=== SUMMARY ===" | tee -a "$RESULTS_FILE"
echo "Total runs: $total_count" | tee -a "$RESULTS_FILE"
echo "Failed runs: $failed_count" | tee -a "$RESULTS_FILE"
echo "Pass rate: $(( (total_count - failed_count) * 100 / total_count ))%" | tee -a "$RESULTS_FILE"