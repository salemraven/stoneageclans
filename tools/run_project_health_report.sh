#!/usr/bin/env bash
# Full project health report — static scan + Godot compile/load audit.
#
# Usage (repo root):
#   bash tools/run_project_health_report.sh
#   bash tools/run_project_health_report.sh --no-godot   # Python scan only (fast)
#
# Output:
#   Tests/logs/project_health_<timestamp>.txt   — human-readable merged report
#   Tests/logs/project_health_<timestamp>.json  — machine-readable merged report
#   Tests/logs/project_health_godot_<stamp>.json — Godot-only detail
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p Tests/logs

STAMP="$(date +%Y%m%d_%H%M%S)"
MERGED_TXT="Tests/logs/project_health_${STAMP}.txt"
MERGED_JSON="Tests/logs/project_health_${STAMP}.json"
STATIC_JSON="/tmp/project_health_static_${STAMP}.json"
GODOT_LOG="/tmp/project_health_godot_${STAMP}.log"

RUN_GODOT=1
if [[ "${1:-}" == "--no-godot" ]]; then
	RUN_GODOT=0
fi

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
export SKIP_SINGLE_INSTANCE=1

{
	echo "=============================================="
	echo "project_health_report ${STAMP}"
	echo "repo: ${ROOT}"
	echo "=============================================="
	echo ""
	echo ">>> Phase 1: static scan (Python)"
	echo "----------------------------------------------"
} | tee "$MERGED_TXT"

STATIC_EXIT=0
python3 tools/project_health_scan.py --json > "$STATIC_JSON" || STATIC_EXIT=$?
python3 tools/project_health_scan.py | tee -a "$MERGED_TXT" || true

GODOT_EXIT=0
if [[ "$RUN_GODOT" -eq 1 ]]; then
	if [[ ! -x "$GODOT" ]]; then
		echo "" | tee -a "$MERGED_TXT"
		echo "WARN: Godot not found at $GODOT — skipping Phase 2" | tee -a "$MERGED_TXT"
		GODOT_EXIT=2
	else
		{
			echo ""
			echo ">>> Phase 2: Godot compile + scene smoke"
			echo "----------------------------------------------"
		} | tee -a "$MERGED_TXT"
		set +e
		"$GODOT" --path "$ROOT" --headless -s res://tools/project_health_report.gd 2>&1 | tee "$GODOT_LOG"
		GODOT_EXIT=${PIPESTATUS[0]}
		set -e
		echo "" | tee -a "$MERGED_TXT"
		echo ">>> Godot stderr highlights (SCRIPT ERROR / ERROR / SHADER)" | tee -a "$MERGED_TXT"
		grep -E '^(SCRIPT ERROR|ERROR:|SHADER ERROR|WARNING:.*Failed)' "$GODOT_LOG" 2>/dev/null | head -40 | tee -a "$MERGED_TXT" || echo "(none captured)" | tee -a "$MERGED_TXT"
	fi
fi

# Merge JSON reports
python3 - "$STATIC_JSON" "$MERGED_JSON" "$STAMP" "$GODOT_EXIT" "$ROOT" <<'PY'
import json, sys, glob
from pathlib import Path

static_path, merged_path, stamp, godot_exit, repo_root = sys.argv[1:6]
repo = Path(repo_root)

static = json.loads(open(static_path).read())
godot_reports = sorted(glob.glob(str(repo / "Tests/logs/project_health_godot_*.json")))
godot = {}
if godot_reports:
    godot = json.loads(open(godot_reports[-1]).read())

merged = {
    "timestamp": stamp,
    "static_scan": static,
    "godot_scan": godot,
    "summary": {
        "static_errors": static.get("summary", {}).get("error", 0),
        "static_warnings": static.get("summary", {}).get("warning", 0),
        "godot_errors": godot.get("summary", {}).get("error", 0) if godot else None,
        "godot_exit_code": int(godot_exit),
    },
}
open(merged_path, "w").write(json.dumps(merged, indent=2) + "\n")
print(f"Merged JSON: {merged_path}")
PY

{
	echo ""
	echo "=============================================="
	echo "SUMMARY"
	echo "  static scan exit: ${STATIC_EXIT}"
	echo "  godot scan exit:  ${GODOT_EXIT}"
	echo "  merged txt:  ${ROOT}/${MERGED_TXT}"
	echo "  merged json: ${ROOT}/${MERGED_JSON}"
	echo "=============================================="
} | tee -a "$MERGED_TXT"

FINAL=0
if [[ "$STATIC_EXIT" -ne 0 ]]; then FINAL=1; fi
if [[ "$GODOT_EXIT" -ne 0 && "$GODOT_EXIT" -ne 2 ]]; then FINAL=1; fi
exit "$FINAL"
