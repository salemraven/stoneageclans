#!/usr/bin/env bash
# Summarize a UnifiedLogger session file (session_game_logs_*.txt or user://game_logs.txt copy).
# Usage:
#   ./tools/analyze_session_log.sh path/to/session_game_logs_*.txt
#   ./tools/analyze_session_log.sh   # newest session_game_logs_*.txt in repo root
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${1:-}"
if [[ -z "$LOG" ]]; then
  LOG="$(ls -t "$ROOT"/session_game_logs_*.txt 2>/dev/null | head -1 || true)"
fi
if [[ -z "$LOG" || ! -f "$LOG" ]]; then
  echo "Usage: $0 <session_game_logs.txt>"
  echo "Or run from repo root after run_session_instrument.sh (finds newest session_game_logs_*.txt)."
  exit 1
fi

echo "=== Session log analysis ==="
echo "File: $LOG"
echo "Bytes: $(wc -c < "$LOG" | tr -d ' ')"

# Timestamps like [2026-04-16T23:38:49]
FIRST_TS="$(grep -oE '\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\]' "$LOG" | head -1 | tr -d '[]' || true)"
LAST_TS="$(grep -oE '\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\]' "$LOG" | tail -1 | tr -d '[]' || true)"
echo "First timestamp: ${FIRST_TS:-unknown}"
echo "Last timestamp:  ${LAST_TS:-unknown}"

echo ""
echo "--- Lines by UnifiedLogger category ---"
for cat in MOVEMENT SESSION SYSTEM NPC COMBAT HERDING WARNING ERROR DEBUG PERFORMANCE; do
  n=0
  n=$(grep -c "\[${cat}\]" "$LOG" 2>/dev/null) || n=0
  echo "  [$cat]  $n"
done

echo ""
echo "--- Reproduction / quickstart signals (grep) ---"
_c(){ grep -c "$1" "$LOG" 2>/dev/null || true; }
echo "  REPRODUCTION_MATE:      $(_c 'REPRODUCTION_MATE')"
echo "  REPRODUCTION_PREGNANCY: $(_c 'REPRODUCTION_PREGNANCY')"
echo "  started pregnancy:      $(_c 'started pregnancy')"
echo "  SPAWN_BABY (births):    $(_c 'SPAWN_BABY')"
echo "  REPRODUCTION_SPAWN:     $(_c 'REPRODUCTION_SPAWN')"
echo "  NPC_MOVE (movement):    $(_c 'NPC_MOVE')"

echo ""
echo "--- Gather / task instrumentation ---"
echo "  WORK_GATHER_NO_RESOURCE:  $(_c 'WORK_GATHER_NO_RESOURCE')"
echo "  WORK_GATHER_RESERVE_FAIL: $(_c 'WORK_GATHER_RESERVE_FAIL')"
echo "  WORK_GATHER_BUILT:        $(_c 'WORK_GATHER_BUILT')"
echo "  TASK_CANCEL:              $(_c 'TASK_CANCEL')"
echo "  WORK_TASK_FAILED:         $(_c 'WORK_TASK_FAILED')"

echo ""
echo "--- Agro (SESSION) ---"
echo "  FSM_AGRO_TRANSITION: $(_c 'FSM_AGRO_TRANSITION')"
echo "  AGRO_STATE_ENTER:    $(_c 'AGRO_STATE_ENTER')"
echo "  AGRO_STATE_EXIT:     $(_c 'AGRO_STATE_EXIT')"

echo ""
echo "--- NPC productivity (SESSION) ---"
echo "  NPC_PRODUCTIVITY_SNAPSHOT: $(_c 'NPC_PRODUCTIVITY_SNAPSHOT')"
_prod="$(grep 'NPC_PRODUCTIVITY_SNAPSHOT' "$LOG" 2>/dev/null | tail -1 || true)"
if [[ -n "$_prod" ]]; then
  echo "  Latest: $_prod"
else
  echo "  (none — need run ≥ npc_productivity_snapshot_interval_sec, default 30s)"
fi

echo ""
echo "--- SESSION category samples (first 5, if any) ---"
_sess="$(grep '\[SESSION\]' "$LOG" 2>/dev/null | head -5 || true)"
if [[ -z "$_sess" ]]; then
  echo "  (none — normal for idle quickstart; expect entries when tasks/combat/defend fire)"
else
  echo "$_sess"
fi

echo ""
echo "--- MOVEMENT sample (1 line) ---"
_m="$(grep '\[MOVEMENT\]' "$LOG" 2>/dev/null | head -1 || true)"
if [[ -z "$_m" ]]; then echo "  (none)"; else echo "$_m"; fi

echo "=== End ==="
