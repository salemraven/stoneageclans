#!/bin/bash
# Run Stone Age Clans for playtest from command line
# Usage: ./run_playtest.sh [-- args...]
#   ./run_playtest.sh                    # normal play
#   ./run_playtest.sh -- --playtest-2min # 2-min timed capture
#   ./run_playtest.sh -- --playtest-capture
# Reporter: godot --path . -s scripts/logging/playtest_reporter.gd
cd "$(dirname "$0")"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
"$GODOT" --path . "$@"
