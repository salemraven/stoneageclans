#!/usr/bin/env bash
# Launch Character Animation Tuner as a detached GUI process.
# macOS: uses `open -n` so the window survives after the agent/shell exits.
#
# Usage (repo root):
#   bash tools/launch_tuner_mac.sh                    # spear preview (default)
#   bash tools/launch_tuner_mac.sh --spear-windup-edit
#   bash tools/launch_tuner_mac.sh --spear-preview --spear-pose-b
#   bash tools/launch_tuner_mac.sh --gather1-preview
#   bash tools/launch_tuner_mac.sh --gather1-preview --gather-pose-pull
#   bash tools/launch_tuner_mac.sh --walk1-preview
#   bash tools/launch_tuner_mac.sh --walk1-edit
#   bash tools/launch_tuner_mac.sh --club-walk-preview
#   bash tools/launch_tuner_mac.sh --club-walk-edit
#   bash tools/launch_tuner_mac.sh --idle-club1-edit
#   bash tools/launch_tuner_mac.sh --none-idle-play
#   bash tools/launch_tuner_mac.sh --hair-edit
#   bash tools/launch_tuner_mac.sh --walk1-edit --tuner-elbow-instrument

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
	GODOT_APP="/Applications/Godot.app"
	OPEN_ARGS=(--path "$ROOT" "res://scenes/tools/LimbTuner.tscn" --skip-single-instance "${ARGS[@]}")
	# `open -na` launches in the user's GUI session (agent shells often can't show windows).
	open -na "$GODOT_APP" --args "${OPEN_ARGS[@]}"
	sleep 2
	echo "Tuner launch requested via open -na Godot.app"
	echo "Args: ${ARGS[*]}"
	echo "If no window: double-click tools/Open_Limb_Tuner.command"
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
