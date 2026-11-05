#!/usr/bin/env bash
# Player camp, one AI clan just past the wake line, one AI clan farther east.
# All three start with the same stock, one woman, one hut, and the same herd ring.
exec bash "$(cd "$(dirname "$0")" && pwd)/launch_game_mac.sh" --pace-arena "$@"
