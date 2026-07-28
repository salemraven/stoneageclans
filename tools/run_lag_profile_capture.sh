#!/usr/bin/env bash
# Capture ~60s of lag profile while Main runs, then print analysis summary.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
SEC="${LAG_PROFILE_SECONDS:-60}"
export SKIP_SINGLE_INSTANCE=1
echo "Lag profile capture (${SEC}s)..."
"$GODOT" --path "$ROOT" res://scenes/Main.tscn --lag-profile --session-quit-after "$SEC" "$@" || true
echo ""
echo "Analyzing latest lag_profile JSONL..."
"$GODOT" --path "$ROOT" --headless -s res://tools/analyze_lag_profile.gd
