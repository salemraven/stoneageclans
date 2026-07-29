#!/usr/bin/env bash
# Character Animation Tuner — local GUI, headless verify/bake, or web share for cloud agents.
#
# Usage (repo root):
#   bash tools/run_limb_tuner.sh verify              # headless tests (cloud-safe)
#   bash tools/run_limb_tuner.sh smoke               # load tuner scene headless
#   bash tools/run_limb_tuner.sh bake --weapon none --clip idle
#   bash tools/run_limb_tuner.sh gui                 # windowed Godot tuner (needs display)
#   bash tools/run_limb_tuner.sh share-web           # browser preview + optional public link
#
# Env: GODOT=/path/to/Godot  SKIP_SINGLE_INSTANCE=1 (default)

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

resolve_godot() {
	if [[ -n "${GODOT:-}" ]]; then
		if [[ -x "$GODOT" ]]; then
			echo "$GODOT"
			return 0
		fi
		echo "ERROR: GODOT is set but not executable: $GODOT" >&2
		return 1
	fi
	if command -v godot4 >/dev/null 2>&1; then
		command -v godot4
		return 0
	fi
	if command -v godot >/dev/null 2>&1; then
		command -v godot
		return 0
	fi
	local mac="/Applications/Godot.app/Contents/MacOS/Godot"
	if [[ -x "$mac" ]]; then
		echo "$mac"
		return 0
	fi
	echo "ERROR: Godot not found. Set GODOT=/path/to/Godot or install godot4 on PATH." >&2
	echo "  Cloud agents: download Godot 4.x Linux headless/server build and export GODOT." >&2
	return 1
}

GODOT_BIN="$(resolve_godot)"
export SKIP_SINGLE_INSTANCE="${SKIP_SINGLE_INSTANCE:-1}"

MODE="${1:-verify}"
shift || true

STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$ROOT/Tests/logs"
mkdir -p "$LOG_DIR"

run_headless_script() {
	local script_path="$1"
	shift
	local log_label="$1"
	shift
	local log_file="$LOG_DIR/${log_label}_${STAMP}.log"
	echo ">>> $log_label"
	"$GODOT_BIN" --path "$ROOT" --headless --script "$script_path" -- "$@" 2>&1 | tee "$log_file"
	echo "Log: $log_file"
}

case "$MODE" in
	verify)
		echo "=============================================="
		echo "run_limb_tuner verify ${STAMP}"
		echo "godot: ${GODOT_BIN}"
		echo "=============================================="
		run_headless_script "res://tools/test_limb_tuner.gd" "limb_tuner_test"
		run_headless_script "res://tools/test_limb_bake.gd" "limb_bake_test"
		run_headless_script "res://tools/limb_tuner_cli.gd" "limb_tuner_cli_smoke" smoke
		echo ""
		echo "LIMB_TUNER_VERIFY_OK"
		;;
	smoke)
		run_headless_script "res://tools/limb_tuner_cli.gd" "limb_tuner_smoke" smoke "$@"
		;;
	bake)
		run_headless_script "res://tools/limb_tuner_cli.gd" "limb_tuner_bake" bake "$@"
		;;
	gui)
		if [[ -z "${DISPLAY:-}" ]] && [[ "$(uname -s)" != "Darwin" ]]; then
			echo "No DISPLAY — cloud agents cannot open the Godot window." >&2
			echo "Use: bash tools/run_limb_tuner.sh verify|bake|smoke" >&2
			echo "Or:  bash tools/run_limb_tuner.sh share-web  (browser preview)" >&2
			exit 1
		fi
		exec "$GODOT_BIN" --path "$ROOT" "res://scenes/tools/LimbTuner.tscn" "$@"
		;;
	share-web)
		exec bash "$ROOT/tools/card_tuner_web/share.sh"
		;;
	help|-h|--help)
		sed -n '2,12p' "$0"
		"$GODOT_BIN" --path "$ROOT" --headless --script res://tools/limb_tuner_cli.gd -- --help
		;;
	*)
		echo "Unknown mode: $MODE (verify|smoke|bake|gui|share-web|help)" >&2
		exit 1
		;;
esac
