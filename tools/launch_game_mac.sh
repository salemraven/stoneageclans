#!/usr/bin/env bash
# Launch Main game as a detached GUI process on macOS.
# Uses `open -na Godot.app` so the window stays in your desktop session (not the agent shell).
#
# Usage (repo root):
#   bash tools/launch_game_mac.sh
#   bash tools/launch_game_mac.sh --start-club --hair2
#
# If the window vanishes: double-click tools/Play_Game.command in Finder.

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

bring_godot_to_front() {
	if [[ "$(uname -s)" != "Darwin" ]]; then
		return 0
	fi
	osascript >/dev/null 2>&1 <<'APPLESCRIPT' || true
tell application "Godot" to activate
delay 0.5
tell application "System Events"
	if exists process "Godot" then
		set frontmost of process "Godot" to true
	end if
end tell
APPLESCRIPT
}

stop_existing_game() {
	pkill -f "Godot.*stoneageclans.*Main.tscn" 2>/dev/null || true
	sleep 0.75
}

game_pgrep_pattern() {
	# Match play-mode Main.tscn; avoid headless editor LSP.
	echo "Godot.*${ROOT}.*Main.tscn"
}

wait_for_game_alive() {
	local min_sec="${1:-10}"
	local elapsed=0
	while (( elapsed < min_sec )); do
		if pgrep -f "$(game_pgrep_pattern)" >/dev/null 2>&1; then
			return 0
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	return 1
}

LOG_DIR="$ROOT/Tests/logs"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/game_gui_${STAMP}.log"

EXTRA_ARGS=("$@")
RUN_ARGS=(--path "$ROOT" res://scenes/Main.tscn --skip-single-instance "${EXTRA_ARGS[@]}")

export SKIP_SINGLE_INSTANCE=1
stop_existing_game

echo "Launching Stone Age Clans (Main.tscn)…"
echo "Args: ${RUN_ARGS[*]}"

if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/Applications/Godot.app" ]]; then
	open -na "/Applications/Godot.app" --args "${RUN_ARGS[@]}"
	if wait_for_game_alive 12; then
		PID="$(pgrep -f "$(game_pgrep_pattern)" | head -1 || true)"
		bring_godot_to_front
		echo "Game running (pid ${PID:-?}) — Godot window should be in front."
		echo "Cmd+Tab → Godot if you do not see it."
		echo "Exit trace: Tests/logs/game_exit_latest.log"
		exit 0
	fi
	echo "WARN: open -na did not keep Main.tscn alive 12s — trying direct binary…" >&2
fi

GODOT_BIN="$(resolve_godot)"
if [[ -z "$GODOT_BIN" ]]; then
	echo "ERROR: Godot not found. Set GODOT=/path/to/Godot" >&2
	exit 1
fi

nohup "$GODOT_BIN" "${RUN_ARGS[@]}" >"$LOG_FILE" 2>&1 &
PID=$!
disown "$PID" 2>/dev/null || true

if wait_for_game_alive 12; then
	bring_godot_to_front
	echo "Game running (pid $PID) — direct binary launch."
	echo "Log: $LOG_FILE"
	exit 0
fi

echo "ERROR: Game exited within ~12s. Log tail:" >&2
tail -50 "$LOG_FILE" >&2 || true
exit 1
