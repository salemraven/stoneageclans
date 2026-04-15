#!/usr/bin/env bash
# Exhaustive early-game gate: base bundle + TerritoryJobService invariants + long Main capture + JSONL strict analysis + hard-error log scan.
# Usage (repo root): bash tools/run_exhaustive_earlygame_verify.sh
# Long Main: uses --playtest-2min (or --playtest-4min) + --playtest-capture — real ~120s/240s wall time. Do NOT use --quit-after for duration:
# Godot 4.x --quit-after is *main-loop iterations*, not seconds (see `godot --help`).
# Env: GODOT, SKIP_LONG_MAIN=1 to skip capture+analyze, SKIP_CLAN_BRAIN_TEST passed to base bundle.
# EXHAUSTIVE_PLAYTEST_4MIN=1 — use --playtest-4min instead of --playtest-2min.
# Herd coverage (strict analyzer): MIN_HERD_WILDNPC_ENTERS (default 1), MIN_SESSION_SEC_FOR_ANALYZE (default 90). Set to 0 to disable that threshold.

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$GODOT" ]]; then
	echo "ERROR: Godot not found at $GODOT — set GODOT=/path/to/Godot" >&2
	exit 1
fi

export SKIP_SINGLE_INSTANCE=1

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="Tests/logs/exhaustive_earlygame_${STAMP}"
mkdir -p "$OUT_DIR"
MASTER_LOG="$OUT_DIR/master.log"
MIN_HERD="${MIN_HERD_WILDNPC_ENTERS:-1}"
MIN_SESS="${MIN_SESSION_SEC_FOR_ANALYZE:-90}"

FAILURES=0
note_fail() {
	echo "$1" >&2
	FAILURES=$((FAILURES + 1))
}

scan_log_hard_errors() {
	local f="$1"
	if [[ ! -f "$f" ]]; then
		note_fail "scan_log_hard_errors: missing file $f"
		return 1
	fi
	if grep -E "SCRIPT ERROR:|Parse Error|Compile Error|Failed to load script" "$f" 2>/dev/null; then
		note_fail "Hard errors detected in $f (see lines above)"
		return 1
	fi
	return 0
}

{
	echo "=============================================="
	echo "exhaustive_earlygame_verify ${STAMP}"
	echo "repo: ${ROOT}"
	echo "long_main: playtest-$([[ "${EXHAUSTIVE_PLAYTEST_4MIN:-}" == "1" ]] && echo 4min || echo 2min) (~120s or ~240s wall)"
	echo "analyze min_herd_wildnpc_enters: ${MIN_HERD} min_session_sec: ${MIN_SESS}"
	echo "=============================================="

	echo ""
	echo ">>> [A] Base earlygame_verify (smoke + chunk + territory + clan brain JSONL)"
	if ! bash "$ROOT/tools/run_earlygame_verify.sh" 2>&1; then
		note_fail "run_earlygame_verify.sh failed"
	fi

	echo ""
	echo ">>> [B] TerritoryJobService headless invariants (E3)"
	TJS_LOG="$OUT_DIR/territory_job_service_verify.log"
	set +e
	"$GODOT" --path "$ROOT" --headless --script res://tools/territory_job_service_verify.gd 2>&1 | tee "$TJS_LOG"
	TJS_EX="${PIPESTATUS[0]}"
	set -e
	if [[ "$TJS_EX" -ne 0 ]]; then
		note_fail "territory_job_service_verify.gd exit $TJS_EX"
	fi
	scan_log_hard_errors "$TJS_LOG" || true

	echo ""
	echo ">>> [C] Long Main + playtest JSONL (herd/gather snapshots for analyze_playtest.py)"
	if [[ "${SKIP_LONG_MAIN:-}" == "1" ]]; then
		echo "SKIP_LONG_MAIN=1 — skipping long Main session"
	else
		export GODOT_TEST_LOG_DIR="$ROOT/$OUT_DIR/long_main"
		mkdir -p "$GODOT_TEST_LOG_DIR"
		LONG_LOG="$OUT_DIR/long_main_godot.log"
		PT_ARGS=(--playtest-capture --playtest-log-dir "$GODOT_TEST_LOG_DIR")
		if [[ "${EXHAUSTIVE_PLAYTEST_4MIN:-}" == "1" ]]; then
			PT_ARGS=(--playtest-4min "${PT_ARGS[@]}")
		else
			PT_ARGS=(--playtest-2min "${PT_ARGS[@]}")
		fi
		set +e
		"$GODOT" --path "$ROOT" --headless -- "${PT_ARGS[@]}" 2>&1 | tee "$LONG_LOG"
		LONG_EXIT="${PIPESTATUS[0]}"
		set -e
		if [[ "$LONG_EXIT" -ne 0 ]]; then
			note_fail "Long Main Godot exit $LONG_EXIT"
		fi
		scan_log_hard_errors "$LONG_LOG" || true
		JSONL="$OUT_DIR/long_main/playtest_session.jsonl"
		if [[ -f "$JSONL" ]]; then
			echo ""
			echo ">>> [D] analyze_playtest.py --strict + herd coverage on long Main JSONL"
			AN_ARGS=(--strict)
			if [[ "${MIN_HERD}" =~ ^[0-9]+$ ]] && [[ "${MIN_HERD}" -gt 0 ]]; then
				AN_ARGS+=(--min-herd-wildnpc-enters "${MIN_HERD}")
			fi
			# MIN_SESSION_SEC_FOR_ANALYZE=0 disables session-length check
			if [[ "${MIN_SESS}" =~ ^[0-9]+$ ]] && [[ "${MIN_SESS}" -gt 0 ]]; then
				AN_ARGS+=(--min-session-sec "${MIN_SESS}")
			fi
			if ! python3 "$ROOT/scripts/logging/analyze_playtest.py" "${AN_ARGS[@]}" "$JSONL"; then
				note_fail "analyze_playtest.py reported herd invariant or coverage failures"
			fi
		else
			note_fail "No JSONL at $JSONL (instrumentation off?)"
		fi
	fi

	echo ""
	echo "=============================================="
	if [[ "$FAILURES" -eq 0 ]]; then
		echo "exhaustive_earlygame_verify OK — ${STAMP}"
	else
		echo "exhaustive_earlygame_verify FAILED — ${FAILURES} issue(s) — ${STAMP}"
	fi
	echo "Artifacts: $OUT_DIR"
	echo "=============================================="
} 2>&1 | tee "$MASTER_LOG"

if [[ "$FAILURES" -ne 0 ]]; then
	exit 1
fi
exit 0
