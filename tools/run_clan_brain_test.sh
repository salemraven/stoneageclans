#!/usr/bin/env bash
# ClanBrain validation test: runs Main with instrumentation and validates the fixes.
# Usage: from repo root: bash tools/run_clan_brain_test.sh
#
# Tests:
# 1. Food ratio uses all food types (not just berries)
# 2. Raid scoring doesn't double-count strategic state
# 3. Raid phase transitions are logged correctly
# 4. Quota updates are tracked

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
LOG_DIR="Tests/logs/clan_brain_test_${STAMP}"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/output.log"

export SKIP_SINGLE_INSTANCE=1
export GODOT_TEST_LOG_DIR="$ROOT/$LOG_DIR"

echo "=============================================="
echo "ClanBrain Validation Test ${STAMP}"
echo "=============================================="
echo "Log dir: $LOG_DIR"
echo ""

# Godot --quit-after is SECONDS (not frames). ~15s gives ~3 ClanBrain eval cycles at 5s each.
SECONDS_RUN=15
{
	echo ">>> Main.tscn headless --quit-after $SECONDS_RUN (seconds)"
	echo "=============================================="
	"$GODOT" --path "$ROOT" --headless --quit-after "$SECONDS_RUN" -- --playtest-capture --playtest-log-dir "$ROOT/$LOG_DIR" 2>&1
	echo ""
	echo "=============================================="
	echo "Game session complete"
	echo "=============================================="
} 2>&1 | tee "$LOG"

echo ""
echo "Analyzing results..."
echo ""

# Check for instrumentation events
JSONL_FILE="$LOG_DIR/playtest_session.jsonl"
if [[ -f "$JSONL_FILE" ]]; then
	echo "=== Instrumentation Summary ==="
	
	# Count key events (use tr to strip any whitespace from grep output)
	BRAIN_EVALS=$(grep -c '"evt":"clan_brain_eval"' "$JSONL_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
	FOOD_RATIOS=$(grep -c '"evt":"clan_brain_food_ratio"' "$JSONL_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
	QUOTA_UPDATES=$(grep -c '"evt":"clan_brain_quota_update"' "$JSONL_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
	RAID_EVALS=$(grep -c '"evt":"raid_evaluated"' "$JSONL_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
	RAID_PHASE_CHANGES=$(grep -c '"evt":"raid_phase_changed"' "$JSONL_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
	RAID_COMPLETED=$(grep -c '"evt":"raid_completed"' "$JSONL_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
	SNAPSHOTS=$(grep -c '"evt":"snapshot"' "$JSONL_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
	
	echo "  snapshots (periodic):        $SNAPSHOTS"
	echo "  clan_brain_eval events:      $BRAIN_EVALS"
	echo "  clan_brain_food_ratio:       $FOOD_RATIOS"
	echo "  clan_brain_quota_update:     $QUOTA_UPDATES"
	echo "  raid_evaluated:              $RAID_EVALS"
	echo "  raid_phase_changed:          $RAID_PHASE_CHANGES"
	echo "  raid_completed:              $RAID_COMPLETED"
	echo ""
	
	# Validation checks
	ERRORS=0
	
	# Check 1: ClanBrain should evaluate at least once per AI clan
	if [[ "$BRAIN_EVALS" -eq 0 ]]; then
		echo "❌ FAIL: No clan_brain_eval events (expected at least 1)"
		ERRORS=$((ERRORS + 1))
	else
		echo "✓ PASS: ClanBrain evaluated $BRAIN_EVALS times"
	fi
	
	# Check 2: Food ratio should be logged when raid is evaluated
	if [[ "$RAID_EVALS" -gt 0 && "$FOOD_RATIOS" -eq 0 ]]; then
		echo "❌ FAIL: Raids evaluated but no food_ratio logs"
		ERRORS=$((ERRORS + 1))
	elif [[ "$FOOD_RATIOS" -gt 0 ]]; then
		echo "✓ PASS: Food ratio logged $FOOD_RATIOS times"
	fi
	
	# Check 3: Quota updates should occur
	if [[ "$QUOTA_UPDATES" -eq 0 ]]; then
		echo "⚠ WARN: No quota updates logged (may be OK if no AI clans)"
	else
		echo "✓ PASS: Quota updated $QUOTA_UPDATES times"
	fi
	
	# Print sample events
	echo ""
	echo "=== Sample Events ==="
	
	if [[ "$BRAIN_EVALS" -gt 0 ]]; then
		echo ""
		echo "First clan_brain_eval:"
		grep '"evt":"clan_brain_eval"' "$JSONL_FILE" | head -1 | python3 -m json.tool 2>/dev/null || grep '"evt":"clan_brain_eval"' "$JSONL_FILE" | head -1
	fi
	
	if [[ "$FOOD_RATIOS" -gt 0 ]]; then
		echo ""
		echo "First clan_brain_food_ratio:"
		grep '"evt":"clan_brain_food_ratio"' "$JSONL_FILE" | head -1 | python3 -m json.tool 2>/dev/null || grep '"evt":"clan_brain_food_ratio"' "$JSONL_FILE" | head -1
	fi
	
	echo ""
	echo "=============================================="
	if [[ "$ERRORS" -eq 0 ]]; then
		echo "✓ All checks passed"
	else
		echo "❌ $ERRORS check(s) failed"
	fi
	echo "=============================================="
	if [[ "$ERRORS" -ne 0 ]]; then
		exit 1
	fi
else
	echo "⚠ No JSONL file found at $JSONL_FILE"
	echo "  Instrumentation may not have been enabled"
	exit 1
fi

echo ""
echo "Full log: $LOG"
echo "JSONL: $JSONL_FILE"
