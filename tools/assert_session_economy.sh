#!/usr/bin/env bash
# Optional regression checks on a session log (gather activity, errors).
# Usage: ./tools/assert_session_economy.sh path/to/session_game_logs.txt
# Env: MIN_WORK_GATHER_BUILT (default 0 — woman-only quickstart has no gather), MAX_ERROR_LINES (default 0)
set -euo pipefail
LOG="${1:?Usage: $0 <session_log.txt>}"
MIN_WORK_GATHER_BUILT="${MIN_WORK_GATHER_BUILT:-0}"
MAX_ERROR_LINES="${MAX_ERROR_LINES:-0}"

if [[ ! -f "$LOG" ]]; then
	echo "assert_session_economy: file not found: $LOG"
	exit 1
fi

gather_built=$(grep -c "WORK_GATHER_BUILT" "$LOG" 2>/dev/null || true)
errors=$(grep -c "\[ERROR\]" "$LOG" 2>/dev/null || true)

ok=1
if [[ "${gather_built:-0}" -lt "${MIN_WORK_GATHER_BUILT}" ]]; then
	echo "ASSERT FAIL: WORK_GATHER_BUILT count (${gather_built:-0}) < MIN_WORK_GATHER_BUILT (${MIN_WORK_GATHER_BUILT})"
	ok=0
else
	echo "ASSERT OK: WORK_GATHER_BUILT=${gather_built:-0} (min ${MIN_WORK_GATHER_BUILT})"
fi

if [[ "${errors:-0}" -gt "${MAX_ERROR_LINES}" ]]; then
	echo "ASSERT FAIL: [ERROR] count (${errors}) > MAX_ERROR_LINES (${MAX_ERROR_LINES})"
	ok=0
else
	echo "ASSERT OK: [ERROR] lines=${errors} (max allowed ${MAX_ERROR_LINES})"
fi

exit $((1 - ok))
