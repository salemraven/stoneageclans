#!/usr/bin/env bash
# Launch Character Animation Tuner as a detached GUI process.
# macOS: uses `open -n` so the window survives after the agent/shell exits.
#
# Usage (repo root):
#   bash tools/launch_tuner_mac.sh                    # spear preview (default)
#   bash tools/launch_tuner_mac.sh --spear-windup-edit
#   bash tools/launch_tuner_mac.sh --club-windup-edit

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

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

ARGS=("$@")
if [[ ${#ARGS[@]} -eq 0 ]]; then
	ARGS=(--spear-preview)
fi
if [[ "${ARGS[0]:-}" == "gui" ]]; then
	ARGS=("${ARGS[@]:1}")
fi
if [[ ${#ARGS[@]} -eq 0 ]]; then
	ARGS=(--spear-preview)
fi

LOG_DIR="$ROOT/Tests/logs"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/tuner_gui_${STAMP}.log"

# Tuner-only instances (leave editor LSP alone).
pkill -f "Godot.*LimbTuner.tscn" 2>/dev/null || true
sleep 0.5

if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/Applications/Godot.app" ]]; then
	# -n = new instance even if Godot editor is open; survives Cursor agent shell exit.
	open -n -a Godot --args --path "$ROOT" "res://scenes/tools/LimbTuner.tscn" "${ARGS[@]}"
	sleep 2
	PID="$(pgrep -f "LimbTuner.tscn" | head -1 || true)"
	if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
		echo "Tuner running (pid $PID)"
		echo "Args: ${ARGS[*]}"
		echo "Tip: if window vanishes, run this script from Terminal.app (not only via agent)."
	else
		echo "WARN: Tuner process not found after launch — check Dock for Godot." >&2
	fi
	exit 0
fi

export SKIP_SINGLE_INSTANCE=1
GODOT_BIN="$(resolve_godot)"
if [[ -z "$GODOT_BIN" ]]; then
	echo "ERROR: Godot not found. Set GODOT=/path/to/Godot" >&2
	exit 1
fi

nohup "$GODOT_BIN" --path "$ROOT" "res://scenes/tools/LimbTuner.tscn" "${ARGS[@]}" >"$LOG_FILE" 2>&1 &
PID=$!
disown "$PID" 2>/dev/null || true
sleep 2
if kill -0 "$PID" 2>/dev/null; then
	echo "Tuner running (pid $PID)"
	echo "Log: $LOG_FILE"
	echo "Args: ${ARGS[*]}"
else
	echo "ERROR: Tuner exited immediately. Last log lines:" >&2
	tail -20 "$LOG_FILE" >&2 || true
	exit 1
fi
