#!/bin/bash
# Double-click in Finder to open the Island Map Editor.
cd "$(dirname "$0")/.." || exit 1
bash tools/launch_map_editor_mac.sh
read -n 1 -s -r -p "Press any key to close…"
