#!/bin/bash
# Double-click in Finder to play Stone Age Clans (Main.tscn).
cd "$(dirname "$0")/.." || exit 1
bash tools/launch_game_mac.sh --start-club --hair2
read -n 1 -s -r -p "Press any key to close…"
