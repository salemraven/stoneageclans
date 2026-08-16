#!/bin/bash
# Double-click in Finder to open the Character Animation Tuner (spear idle pose edit).
cd "$(dirname "$0")/.." || exit 1
bash tools/launch_tuner_mac.sh --spear-preview
read -n 1 -s -r -p "Press any key to close…"
