#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
export SKIP_SINGLE_INSTANCE=1
exec "$GODOT" --path "$ROOT" --headless --session-quickstart -s res://tools/test_session_quickstart_huts.gd
