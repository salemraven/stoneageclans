#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
export SKIP_SINGLE_INSTANCE=1
export SKIP_RUNTIME_FAULT_SINK=1
cd "$ROOT"

echo "=== SimRng determinism test ==="
set +e
det_log="$("$GODOT" --path "$ROOT" --headless -s res://tools/test_sim_rng_determinism.gd 2>&1)"
det_status=$?
set -e
echo "$det_log"
if [[ $det_status -ne 0 ]] || ! grep -q "TEST_SIM_RNG_DETERMINISM: all checks passed" <<<"$det_log"; then
  echo "SimRng determinism test FAILED"
  exit 1
fi

echo "=== RNG usage audit ==="
set +e
audit_log="$("$GODOT" --path "$ROOT" --headless -s res://tools/rng_usage_audit.gd 2>&1)"
audit_status=$?
set -e
echo "$audit_log"
if [[ $audit_status -ne 0 ]] || ! grep -q "RNG_USAGE_AUDIT: OK" <<<"$audit_log"; then
  echo "RNG usage audit FAILED"
  exit 1
fi

echo "=== Instrumented playtest smoke ==="
bash "$ROOT/tools/run_instrumented_playtest.sh"

echo "SimRng pipeline: OK"
