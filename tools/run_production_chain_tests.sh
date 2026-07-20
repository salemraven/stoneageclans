#!/usr/bin/env bash
# Isolated production + milestone chain harnesses (find real failures — no ClanBrain cheat spawn).
# Usage (repo root): bash tools/run_production_chain_tests.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p Tests/logs

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=/path/to/Godot" >&2
	exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$ROOT/Tests/logs/chain_tests_${STAMP}"
mkdir -p "$LOG_DIR"
export SKIP_SINGLE_INSTANCE=1

run_one() {
	local flag="$1"
	local name="$2"
	local subdir="$LOG_DIR/$name"
	mkdir -p "$subdir"
	local log="$subdir/console.log"
	echo ""
	echo "=== $name ($flag) ==="
	set +e
	"$GODOT" --path "$ROOT" --headless \
		--playtest-capture \
		--playtest-log-dir "$subdir" \
		"$flag" \
		2>&1 | tee "$log"
	local ec=${PIPESTATUS[0]}
	set -e
	if [[ $ec -ne 0 ]]; then
		echo "FAIL: $name exit=$ec (see $log)"
		return $ec
	fi
	echo "PASS: $name exit=0"
	return 0
}

FAIL=0
run_one "--production-chain-test" "production_chain" || FAIL=1
run_one "--milestone-chain-test" "milestone_chain" || FAIL=1

echo ""
if [[ -f "$LOG_DIR/production_chain/playtest_session.jsonl" ]]; then
	python3 "$ROOT/scripts/logging/verify_chain_tests.py" "$LOG_DIR/production_chain/playtest_session.jsonl" --expect production || FAIL=1
fi
if [[ -f "$LOG_DIR/milestone_chain/playtest_session.jsonl" ]]; then
	python3 "$ROOT/scripts/logging/verify_chain_tests.py" "$LOG_DIR/milestone_chain/playtest_session.jsonl" --expect milestone || FAIL=1
fi

echo ""
echo "Logs: $LOG_DIR"
if [[ $FAIL -ne 0 ]]; then
	echo "CHAIN TESTS: FAILED"
	exit 1
fi
echo "CHAIN TESTS: OK"
exit 0
