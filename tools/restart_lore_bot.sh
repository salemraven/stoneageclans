#!/usr/bin/env bash
# Stop any old Zedu bot and start the current one.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Stopping old lore bot processes..."
pkill -f 'discord_lore_bot.py' 2>/dev/null || true
sleep 1

git pull

echo "Starting Zedu v2..."
exec bash tools/run_lore_bot.sh
