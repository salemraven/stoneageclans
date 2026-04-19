#!/usr/bin/env bash
# Full pipeline: instrumentation + session quickstart (reproduction) + timed quit + log copy + optional analysis.
#
# 1) Instrumentation: --session-instrument --log-console (MOVEMENT + SESSION categories, file → user://game_logs.txt)
# 2) Test env: --session-quickstart (player in claim, 2 Living Huts, 2 women, babies when timers fire)
# 3–4) Run SESSION_QUIT_AFTER_SEC seconds then auto-quit (or 0 = manual close)
# 5) Analyze: ANALYZE=1 runs tools/analyze_session_log.sh on the copied log
#
# Usage:
#   SESSION_QUIT_AFTER_SEC=120 ./run_session_instrument.sh -- --headless    # 2 min headless
#   SESSION_MINUTES=5 ./run_session_instrument.sh                           # 5 min (sets SESSION_QUIT_AFTER_SEC)
#   TRUNCATE_SESSION_LOG=0 ./run_session_instrument.sh                      # keep append-only history in game_logs.txt
#
# Extra Godot args after --
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="${SESSION_LOG_OUT:-$ROOT/session_capture_${STAMP}.log}"

if [[ -n "${SESSION_MINUTES:-}" ]] && [[ "${SESSION_MINUTES}" =~ ^[0-9]+$ ]]; then
  export SESSION_QUIT_AFTER_SEC=$((SESSION_MINUTES * 60))
fi

if [[ ! -x "$GODOT" ]] && [[ -f "$GODOT" ]]; then
  chmod +x "$GODOT" 2>/dev/null || true
fi
if [[ ! -f "$GODOT" ]]; then
  echo "Godot not found at: $GODOT"
  echo "Set GODOT to your Godot 4.x binary and retry."
  exit 1
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
	USER_DATA_LOG="${HOME}/Library/Application Support/Godot/app_userdata/StoneAgeClans/game_logs.txt"
else
	USER_DATA_LOG="${HOME}/.local/share/godot/app_userdata/StoneAgeClans/game_logs.txt"
fi

echo "Project: $ROOT"
echo "UnifiedLogger file: $USER_DATA_LOG"
echo "This terminal copy: $OUT"
echo "Quickstart: 1 claim + 2 Living Huts + 2 women (clan TEST); pregnancy starts immediately; preg/baby/cooldown sped up in BalanceConfig for this run"
SQ_SHOW="${SESSION_QUIT_AFTER_SEC:-45}"
if [[ "${SQ_SHOW}" == "0" ]]; then
  echo "Auto-quit: OFF (close window manually)"
else
  # Bash arithmetic only (no awk — avoids rare hangs in sandboxed/CI shells)
  _mins_int=$((SQ_SHOW / 60))
  _secs_rem=$((SQ_SHOW % 60))
  echo "Auto-quit: ${SQ_SHOW}s (~${_mins_int}m ${_secs_rem}s wall time before quit)"
fi
echo "TRUNCATE_SESSION_LOG: ${TRUNCATE_SESSION_LOG:-1} (set 0 to append to existing game_logs.txt)"
echo "SKIP_SINGLE_INSTANCE: set SKIP_SINGLE_INSTANCE=1 if another instance may be running"
echo "ASSERT_ECONOMY: set ASSERT_ECONOMY=1 to run tools/assert_session_economy.sh (MIN_WORK_GATHER_BUILT=0 default; raise for worker playtests)"
echo ""
echo "Instrumentation (always with this script):"
echo "  --session-instrument  → SESSION + MOVEMENT, file log, movement filter (quickstart: woman,clansman)"
echo "  --log-console         → mirror to terminal + session_capture log"
echo "  DebugConfig: file batch flush + NPC_PRODUCTIVITY_SNAPSHOT + agro SESSION lines (FSM_AGRO_TRANSITION, AGRO_STATE_ENTER/EXIT) when session instrumentation is on"
echo ""

# --session-instrument: SESSION + MOVEMENT, enables file logging to user://game_logs.txt
# --session-quickstart: skip default cavemen; start with claim + women + huts
# --log-console: mirror structured lines to stdout so tee captures them
# Build argv in one array so SESSION_QUIT_AFTER_SEC=0 never leaves an empty "${QUIT_ARGS[@]}" (set -u safe).
SQ="${SESSION_QUIT_AFTER_SEC:-45}"
RUN_GODOT=( "$GODOT" --path "$ROOT" --session-instrument --session-quickstart --log-console )
if [[ "$SQ" != "0" ]]; then
	RUN_GODOT+=( --session-quit-after "$SQ" )
fi

GAME_LOG_COPY="${SESSION_GAME_LOG_OUT:-$ROOT/session_game_logs_${STAMP}.txt}"

# One clean capture per run (default): empty user log before Godot so analysis is not mixed with old sessions.
TRUNCATE_SESSION_LOG="${TRUNCATE_SESSION_LOG:-1}"
if [[ "$TRUNCATE_SESSION_LOG" != "0" ]]; then
	mkdir -p "$(dirname "$USER_DATA_LOG")"
	: >"$USER_DATA_LOG"
	echo "Truncated: $USER_DATA_LOG (this run only; TRUNCATE_SESSION_LOG=0 to disable)"
	echo ""
fi

"${RUN_GODOT[@]}" "$@" 2>&1 | tee "$OUT"

# Copy persisted UnifiedLogger file into the project folder for analysis (Godot flushes each line now).
if [[ -f "$USER_DATA_LOG" ]]; then
	cp "$USER_DATA_LOG" "$GAME_LOG_COPY"
	echo ""
	echo "Copied user://game_logs.txt → $GAME_LOG_COPY"
fi

ANALYZE="${ANALYZE:-1}"
if [[ "$ANALYZE" != "0" ]] && [[ -f "$GAME_LOG_COPY" ]] && [[ -x "$ROOT/tools/analyze_session_log.sh" ]]; then
	echo ""
	bash "$ROOT/tools/analyze_session_log.sh" "$GAME_LOG_COPY"
fi

ASSERT_ECONOMY="${ASSERT_ECONOMY:-0}"
if [[ "$ASSERT_ECONOMY" != "0" ]] && [[ -f "$GAME_LOG_COPY" ]] && [[ -x "$ROOT/tools/assert_session_economy.sh" ]]; then
	echo ""
	bash "$ROOT/tools/assert_session_economy.sh" "$GAME_LOG_COPY"
fi
