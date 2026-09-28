#!/usr/bin/env bash
# Launch Main.tscn, monitor until exit (or MONITOR_SEC), print GAME_EXIT trace lines.
#
# Usage:
#   bash tools/run_game_with_exit_trace.sh
#   bash tools/run_game_with_exit_trace.sh --start-club
#   MONITOR_SEC=60 bash tools/run_game_with_exit_trace.sh --start-club

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MONITOR_SEC="${MONITOR_SEC:-90}"
STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$ROOT/Tests/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/game_exit_${STAMP}.log"
AUDIT_FILE="$HOME/Library/Application Support/Godot/app_userdata/StoneAgeClans/runtime_boot_audit.log"
LATEST_EXIT="$ROOT/Tests/logs/game_exit_latest.log"

resolve_godot() {
	if [[ -n "${GODOT:-}" && -x "${GODOT}" ]]; then
		echo "${GODOT}"
		return 0
	fi
	local mac="/Applications/Godot.app/Contents/MacOS/Godot"
	if [[ -x "$mac" ]]; then
		echo "$mac"
		return 0
	fi
	command -v godot4 2>/dev/null || command -v godot 2>/dev/null || true
}

GODOT_BIN="$(resolve_godot)"
if [[ -z "$GODOT_BIN" ]]; then
	echo "ERROR: Godot not found" >&2
	exit 1
fi

RUN_ARGS=(--path "$ROOT" res://scenes/Main.tscn --skip-single-instance)
if (($# > 0)); then
	RUN_ARGS+=("$@")
fi

export SKIP_SINGLE_INSTANCE=1
: >"$LATEST_EXIT" || true

echo "=== exit trace run $STAMP ===" | tee "$LOG_FILE"
echo "godot: $GODOT_BIN" | tee -a "$LOG_FILE"
echo "args: ${RUN_ARGS[*]}" | tee -a "$LOG_FILE"
echo "monitor_sec: $MONITOR_SEC" | tee -a "$LOG_FILE"

"$GODOT_BIN" "${RUN_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE" &
PID=$!
echo "pid=$PID" | tee -a "$LOG_FILE"

ELAPSED=0
while kill -0 "$PID" 2>/dev/null; do
	if (( ELAPSED >= MONITOR_SEC )); then
		echo "STILL_RUNNING after ${MONITOR_SEC}s (pid $PID) — game did not exit on its own" | tee -a "$LOG_FILE"
		echo "Close the game window manually, or: kill $PID" | tee -a "$LOG_FILE"
		exit 0
	fi
	sleep 2
	ELAPSED=$((ELAPSED + 2))
done

wait "$PID" || EXIT=$?
EXIT="${EXIT:-0}"
echo "PROCESS_EXIT code=$EXIT elapsed=${ELAPSED}s" | tee -a "$LOG_FILE"

echo "--- GAME_EXIT in session log ---" | tee -a "$LOG_FILE"
grep "GAME_EXIT" "$LOG_FILE" || echo "(none in session log)" | tee -a "$LOG_FILE"

echo "--- GAME_EXIT in repo latest ---" | tee -a "$LOG_FILE"
if [[ -f "$LATEST_EXIT" ]]; then
	cat "$LATEST_EXIT" | tee -a "$LOG_FILE"
else
	echo "(no $LATEST_EXIT)" | tee -a "$LOG_FILE"
fi

echo "--- runtime_boot_audit tail ---" | tee -a "$LOG_FILE"
if [[ -f "$AUDIT_FILE" ]]; then
	tail -15 "$AUDIT_FILE" | tee -a "$LOG_FILE"
else
	echo "(no audit file)" | tee -a "$LOG_FILE"
fi

echo "Full log: $LOG_FILE"
