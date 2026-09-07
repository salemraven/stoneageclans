#!/usr/bin/env bash
# Launch WorldMapEditor as a visible GUI window on macOS.
# Uses `open -na` so the window appears on your desktop (not hidden in agent shell).
#
# Usage: bash tools/launch_map_editor_mac.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bring_godot_to_front() {
	osascript >/dev/null 2>&1 <<'APPLESCRIPT' || true
tell application "Godot" to activate
delay 0.4
tell application "System Events"
	if exists process "Godot" then
		set frontmost of process "Godot" to true
	end if
end tell
APPLESCRIPT
}

pkill -f "Godot.*stoneageclans.*WorldMapEditor" 2>/dev/null || true
sleep 0.5

export SKIP_SINGLE_INSTANCE=1
RUN_ARGS=(--path "$ROOT" "res://scenes/WorldMapEditor.tscn" --skip-single-instance)
echo "Launching Island Map Editor…"
open -na "/Applications/Godot.app" --args "${RUN_ARGS[@]}"
sleep 4
bring_godot_to_front

if pgrep -f "Godot.*WorldMapEditor" >/dev/null 2>&1; then
	echo "Map editor running — opens at island center. Home = full island, C = re-center."
	echo "If hidden: Cmd+Tab to Godot."
	exit 0
fi

echo "ERROR: WorldMapEditor did not stay running." >&2
exit 1
