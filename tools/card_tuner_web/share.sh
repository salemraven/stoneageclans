#!/usr/bin/env bash
# Start the web card tuner and print a public share link (cloudflared).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PORT="${CARD_TUNER_PORT:-8765}"
RUN_DIR="$ROOT/tools/card_tuner_web/.run"
mkdir -p "$RUN_DIR"

stop_pid() {
  local pid_file="$1"
  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file")"
    kill "$pid" 2>/dev/null || true
    rm -f "$pid_file"
  fi
}

stop_pid "$RUN_DIR/server.pid"
stop_pid "$RUN_DIR/tunnel.pid"
pkill -f "tools/card_tuner_web/server.py" 2>/dev/null || true
sleep 1

nohup python3 "$ROOT/tools/card_tuner_web/server.py" >"$RUN_DIR/server.log" 2>&1 &
echo $! >"$RUN_DIR/server.pid"

if ! curl -sf "http://127.0.0.1:${PORT}/api/version" >/dev/null; then
  for _ in $(seq 1 20); do
    sleep 0.5
    curl -sf "http://127.0.0.1:${PORT}/api/version" >/dev/null && break
  done
fi

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Server: http://localhost:${PORT}/"
  echo "cloudflared not installed — no public link."
  exit 0
fi

nohup cloudflared tunnel --url "http://127.0.0.1:${PORT}" >"$RUN_DIR/tunnel.log" 2>&1 &
echo $! >"$RUN_DIR/tunnel.pid"

PUBLIC_URL=""
for _ in $(seq 1 40); do
  PUBLIC_URL="$(rg -o 'https://[a-z0-9-]+\.trycloudflare\.com' "$RUN_DIR/tunnel.log" 2>/dev/null | head -1 || true)"
  if [[ -n "$PUBLIC_URL" ]]; then
    break
  fi
  sleep 1
done

SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

{
  echo "PUBLIC_URL=$PUBLIC_URL"
  echo "LOCAL_URL=http://localhost:${PORT}/"
  echo "SHA=$SHA"
  echo "BRANCH=$BRANCH"
  echo "STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >"$RUN_DIR/share.env"

echo ""
echo "=== Stone Age Clans — Web Card Tuner ==="
echo "Branch: $BRANCH"
echo "Build:  $SHA"
echo "Local:  http://localhost:${PORT}/"
if [[ -n "$PUBLIC_URL" ]]; then
  echo "Share:  $PUBLIC_URL"
  echo ""
  echo "(Share link expires when this machine stops the tunnel.)"
else
  echo "Share:  (still starting — see $RUN_DIR/tunnel.log)"
fi
echo ""
