#!/usr/bin/env bash
# Character Animation Tuner — local GUI, headless verify/bake, or web share for cloud agents.
#
# Usage (repo root):
#   bash tools/run_limb_tuner.sh verify              # headless tests (cloud-safe)
#   bash tools/run_limb_tuner.sh smoke               # load tuner scene headless
#   bash tools/run_limb_tuner.sh bake --weapon none --clip idle
#   bash tools/run_limb_tuner.sh evaluate            # audit + tests, then GUI w/ instrumentation
#   bash tools/run_limb_tuner.sh lockin              # save club_clansmen_1 idle/windup/strike preset
#   bash tools/run_limb_tuner.sh spear-prep          # validate + save spear_clansmen_1 for tuning
#   bash tools/run_limb_tuner.sh spear-evaluate      # audit + tests, then GUI spear preview
#   bash tools/run_limb_tuner.sh gui                 # windowed Godot tuner (needs display)
#   bash tools/run_limb_tuner.sh gui --tuner-instrument
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
		run_headless_script "res://tools/test_tuner_startup_no_clobber.gd" "tuner_startup_no_clobber"
		run_headless_script "res://tools/test_tuner_save_playback_guard.gd" "tuner_save_playback_guard"
		run_headless_script "res://tools/lockin_walk_clansmen_1.gd" "lockin_walk_clansmen_1"
		run_headless_script "res://tools/test_tuner_pin_snap.gd" "tuner_pin_snap"
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
	evaluate)
		echo "=============================================="
		echo "Club tuner evaluation prep ${STAMP}"
		echo "godot: ${GODOT_BIN}"
		echo "=============================================="
		run_headless_script "res://tools/test_limb_tuner.gd" "limb_tuner_test"
		run_headless_script "res://tools/audit_club_lockin.gd" "club_lockin_audit"
		echo ""
		echo "Headless gates passed — opening Character Animation Tuner (instrumentation on)."
		echo "Preset: assets/limb_presets/club_clansmen_1.tres"
		echo "Session: Club · Idle standing (default startup)"
		echo "  1. A/D — walk carry"
		echo "  2. Shift (hold) — windup loop rest→A→B→rest"
		echo "  3. Shift+click — keyframed strike to peak → recover to windup B"
		echo "  Yellow pin 3 must stay on club grip; green 1h + arms follow."
		echo "  Log: Tests/logs/tuner_preview_instrument.jsonl"
		echo ""
		if [[ -z "${DISPLAY:-}" ]] && [[ "$(uname -s)" != "Darwin" ]]; then
			echo "No DISPLAY — run locally: bash tools/run_limb_tuner.sh gui --tuner-instrument" >&2
			exit 0
		fi
		exec "$GODOT_BIN" --path "$ROOT" "res://scenes/tools/LimbTuner.tscn" --tuner-instrument "$@"
		;;
	lockin)
		echo "=============================================="
		echo "Club clansmen_1 lock-in ${STAMP}"
		echo "godot: ${GODOT_BIN}"
		echo "=============================================="
		run_headless_script "res://tools/lockin_club_clansmen_1.gd" "club_lockin_save"
		run_headless_script "res://tools/audit_club_lockin.gd" "club_lockin_audit"
		echo ""
		echo "CLUB_LOCKIN_OK"
		;;
	spear-prep)
		echo "=============================================="
		echo "Spear clansmen_1 tuning prep ${STAMP}"
		echo "godot: ${GODOT_BIN}"
		echo "=============================================="
		run_headless_script "res://tools/prep_spear_clansmen_1.gd" "spear_prep"
		run_headless_script "res://tools/audit_spear_tuning_ready.gd" "spear_tuning_audit"
		echo ""
		echo "SPEAR_PREP_OK"
		;;
	spear-lockin)
		echo "=============================================="
		echo "Spear clansmen_1 windup lock-in ${STAMP}"
		echo "godot: ${GODOT_BIN}"
		echo "=============================================="
		run_headless_script "res://tools/lockin_spear_clansmen_1.gd" "spear_lockin_save"
		run_headless_script "res://tools/audit_spear_tuning_ready.gd" "spear_tuning_audit"
		echo ""
		echo "SPEAR_LOCKIN_OK"
		;;
	gather-lockin)
		echo "=============================================="
		echo "Gather clansmen_1 lock-in ${STAMP}"
		echo "godot: ${GODOT_BIN}"
		echo "=============================================="
		run_headless_script "res://tools/lockin_gather_clansmen_1.gd" "gather_lockin_save"
		run_headless_script "res://tools/audit_gather_tuning_ready.gd" "gather_tuning_audit"
		echo ""
		echo "GATHER_LOCKIN_OK"
		;;
	gather-evaluate)
		echo "=============================================="
		echo "Gather tuner evaluation prep ${STAMP}"
		echo "godot: ${GODOT_BIN}"
		echo "=============================================="
		run_headless_script "res://tools/test_limb_tuner.gd" "limb_tuner_test"
		run_headless_script "res://tools/audit_gather_tuning_ready.gd" "gather_tuning_audit"
		echo ""
		echo "Headless gates passed — opening Character Animation Tuner (gather preview)."
		echo "Preset: assets/limb_presets/none_clansmen_1.tres"
		echo "Session: None · Gather 1 (--gather1-preview)"
		echo "  ▶ Play — idle → bend → pick → stand loop"
		echo "  Key 1 — reach pose (bent, hands down)"
		echo "  Key 2 — pull pose (hands to body)"
		echo ""
		if [[ -z "${DISPLAY:-}" ]] && [[ "$(uname -s)" != "Darwin" ]]; then
			echo "No DISPLAY — run locally: bash tools/run_limb_tuner.sh gui --gather1-preview" >&2
			exit 0
		fi
		exec "$GODOT_BIN" --path "$ROOT" "res://scenes/tools/LimbTuner.tscn" --gather1-preview "$@"
		;;
	spear-evaluate)
		echo "=============================================="
		echo "Spear tuner evaluation prep ${STAMP}"
		echo "godot: ${GODOT_BIN}"
		echo "=============================================="
		run_headless_script "res://tools/test_limb_tuner.gd" "limb_tuner_test"
		run_headless_script "res://tools/audit_spear_tuning_ready.gd" "spear_tuning_audit"
		echo ""
		echo "Headless gates passed — opening Character Animation Tuner (spear preview)."
		echo "Preset: assets/limb_presets/spear_clansmen_1.tres"
		echo "Session: Spear · Idle standing (--spear-preview)"
		echo "  1. A/D — walk carry (shaft grip pinned)"
		echo "  2. Shift (hold) — two-hand windup on shaft (Y1 + Y2)"
		echo "  3. Shift+click — thrust to strike_offset_px peak"
		echo "  Yellow pin 3 on shaft art; green 1h stacked on yellow."
		echo "  Re-edit windup: bash tools/run_limb_tuner.sh gui --spear-windup-edit"
		echo ""
		if [[ -z "${DISPLAY:-}" ]] && [[ "$(uname -s)" != "Darwin" ]]; then
			echo "No DISPLAY — run locally: bash tools/run_limb_tuner.sh gui --spear-preview" >&2
			exit 0
		fi
		exec "$GODOT_BIN" --path "$ROOT" "res://scenes/tools/LimbTuner.tscn" --spear-preview "$@"
		;;
	gui)
		if [[ -z "${DISPLAY:-}" ]] && [[ "$(uname -s)" != "Darwin" ]]; then
			echo "No DISPLAY — cloud agents cannot open the Godot window." >&2
			echo "Use: bash tools/run_limb_tuner.sh verify|bake|smoke|evaluate" >&2
			echo "Or:  bash tools/run_limb_tuner.sh share-web  (browser preview)" >&2
			exit 1
		fi
		if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/Applications/Godot.app" ]]; then
			exec bash "$ROOT/tools/launch_tuner_mac.sh" "$@"
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
		echo "Unknown mode: $MODE (verify|smoke|bake|evaluate|lockin|gather-lockin|gather-evaluate|spear-prep|spear-lockin|spear-evaluate|gui|share-web|help)" >&2
		exit 1
		;;
esac
