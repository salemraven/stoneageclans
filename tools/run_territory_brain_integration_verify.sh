#!/usr/bin/env bash
# Headless: ClanBrain neighbor list includes enemy Campfires + JSONL has extended clan_brain_eval keys.
# Usage: from repo root: bash tools/run_territory_brain_integration_verify.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p Tests/logs

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=/path/to/Godot" >&2
	exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="Tests/logs/territory_brain_integration_${STAMP}"
mkdir -p "$LOG_DIR"
OUT="$LOG_DIR/godot.log"
JSONL="$LOG_DIR/playtest_session.jsonl"

export SKIP_SINGLE_INSTANCE=1
export GODOT_TEST_LOG_DIR="$ROOT/$LOG_DIR"

echo "=============================================="
echo "territory_brain_integration_verify ${STAMP}"
echo "log dir: $LOG_DIR"
echo "=============================================="

set +e
"$GODOT" --path "$ROOT" --headless \
	--script res://tools/territory_brain_integration_verify.gd \
	-- --playtest-capture --playtest-log-dir "$ROOT/$LOG_DIR" 2>&1 | tee "$OUT"
EXIT="${PIPESTATUS[0]}"
set -e

if [[ "$EXIT" -ne 0 ]]; then
	echo "FAIL: Godot exit $EXIT (see $OUT)" >&2
	exit "$EXIT"
fi

if [[ ! -f "$JSONL" ]]; then
	echo "FAIL: expected JSONL at $JSONL" >&2
	exit 1
fi

# At least one clan_brain_eval line must include new integration fields.
if ! grep -q '"evt":"clan_brain_eval"' "$JSONL"; then
	echo "FAIL: no clan_brain_eval events in $JSONL" >&2
	exit 1
fi

for key in territory_class nearby_enemy_campfires brain_mode defender_quota_freeze_reason player_defend_ratio; do
	if ! grep -q "\"$key\":" "$JSONL"; then
		echo "FAIL: JSONL missing field: $key" >&2
		exit 1
	fi
done

echo "OK: JSONL contains extended clan_brain_eval fields"
echo "Done: $LOG_DIR"
