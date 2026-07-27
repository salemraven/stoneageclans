#!/usr/bin/env bash
# Run the Stone Age Clans Discord lore bot (devblog + bible Q&A).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TOKEN="${DISCORD_LORE_BOT_TOKEN:-${DISCORD_BOT_TOKEN:-}}"
if [[ -z "$TOKEN" ]]; then
  echo ""
  echo "Missing bot token."
  echo "Follow tools/DISCORD_BOT_SETUP.md (about 3 minutes), then run this again."
  echo ""
  exit 1
fi

python3 -m pip install -q -r tools/requirements-discord-bot.txt
export DISCORD_LORE_BOT_TOKEN="$TOKEN"
exec python3 tools/discord_lore_bot.py
