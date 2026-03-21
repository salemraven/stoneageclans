# StoneAgeClans – Testing environment

One entry point, configurable paths, and all results in one place.

## Quick start

```bash
# 1. Point tests at your Godot binary (once)
cp Tests/config.env.example Tests/config.env
# Edit Tests/config.env: set GODOT_PATH for your OS

# 2. Sanity check (15s run, logs must appear)
./Tests/run.sh smoke

# 3. Single AI clan run (default 2 min), then analysis
./Tests/run.sh ai-clan

# 4. Single run with custom duration (e.g. 5 min)
./Tests/run.sh ai-clan 300

# 5. Automated loop: run → analyze → optional fixes → repeat (max 5 runs)
./Tests/run.sh automate 120 5 --apply-fixes
```

## Commands

| Command | What it does |
|--------|----------------|
| `./Tests/run.sh smoke` | 15s headless run. Pass if `npc_activity_tracker.log` or `game_console.log` exists. Use for CI or “did the game and tracker start?”. |
| `./Tests/run.sh ai-clan [SEC]` | One headless run for SEC seconds (default from config, else 120), then run the analyzer. Output in `Tests/results/ai_clan_<timestamp>/`. |
| `./Tests/run.sh automate [SEC] [N] [--apply-fixes]` | Up to N iterations (default 5). Each iteration = full run + analyze. If `--apply-fixes` and issues found, one predefined fix is applied and the loop continues. Output in `Tests/results/automate_<timestamp>/iter_1`, `iter_2`, … |
| `./Tests/run.sh analyze <DIR>` | Re-run the NPC efficiency analyzer on an existing run directory. |
| `./Tests/run.sh unified [SEC]` | **Unified test: clansmen efficiency.** Run SEC seconds (default 240), then unified analyzer. Goal: active search, herding success, gathering, depositing. Output: `unified_report.md`, `unified_result.env`. |
| `./Tests/run.sh analyze-unified <DIR>` | Re-run the unified (efficiency) analyzer on an existing run directory. |

## Config

Copy `Tests/config.env.example` to `Tests/config.env` (gitignored). Options:

- **GODOT_PATH** – Path to Godot executable (required for smoke / ai-clan / automate).
- **DEFAULT_DURATION** – Default seconds for `ai-clan` and `automate` when you don’t pass a number (e.g. `120`).
- **RESULTS_DIR** – Directory for all run outputs. Relative to `Tests/` or absolute. Default: `results` → `Tests/results/`.

Example (macOS):

```bash
export GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
export DEFAULT_DURATION=120
export RESULTS_DIR="results"
```

## Where output goes

- **Smoke:** `Tests/results/smoke_<timestamp>/`
- **AI clan:** `Tests/results/ai_clan_<timestamp>/`
- **Unified:** `Tests/results/unified_<timestamp>/`
- **Automate:** `Tests/results/automate_<timestamp>/iter_1`, `iter_2`, …

Each run directory contains:

- `game_console.log` – Godot stdout/stderr
- `npc_activity_tracker.log` – NPC activity (gather, deposit, state changes) when `GODOT_TEST_LOG_DIR` is set
- `npc_metrics.log` / `npc_metrics.csv` – State distribution and metrics
- `playtest_session.jsonl` – Playtest events (herding, combat, npc_joined_clan, etc.) when Godot writes to `GODOT_TEST_LOG_DIR`
- `analysis_report.md` – Human-readable summary (from NPC efficiency analyzer)
- `analysis_result.env` – Machine-readable (GATHER_COUNT, DEPOSIT_COUNT, ISSUES, etc.) for automation

**Unified runs** also contain:

- `unified_report.md` – Efficiency summary first (herding success, search activity, gathers, deposits), then pass/fail
- `unified_result.env` – HERD_JOINED_COUNT, GATHER_COUNT, DEPOSIT_COUNT, SEARCH_ACTIVITY_OK, EFFICIENCY_PASS, etc.

## How it works

1. **run.sh** sources `Tests/config.env`, sets `GODOT_PATH` and `RESULTS_DIR`, then delegates to:
   - **RUN_AI_CLAN_TEST.sh** – Starts Godot headless with `GODOT_TEST_LOG_DIR` set so the game writes logs into the run directory, waits for the given duration, stops Godot, runs the analyzer.
   - **ANALYZE_NPC_EFFICIENCY.sh** – Parses logs, computes gathers/deposits/state distribution, writes `analysis_report.md` and `analysis_result.env`, exits 0/1 by issues.
   - **AUTOMATE_AI_CLAN_TEST.sh** – Loop of run + analyze; optionally applies one fix per iteration and re-runs.

2. **NPCActivityTracker** (in-game) writes `npc_activity_tracker.log` and `npc_metrics.log` into `GODOT_TEST_LOG_DIR` when that env is set (so no reliance on `user://` path).

## Direct script usage

You can still call scripts directly:

```bash
./Tests/RUN_AI_CLAN_TEST.sh 60                          # 60s, output to Tests/ai_clan_test_<ts>
./Tests/RUN_AI_CLAN_TEST.sh 120 /path/to/my_run          # 120s, output to /path/to/my_run
./Tests/ANALYZE_NPC_EFFICIENCY.sh /path/to/my_run        # Re-analyze (NPC efficiency)
./Tests/ANALYZE_UNIFIED.sh /path/to/my_run                # Re-analyze (unified / clansmen efficiency)
./Tests/AUTOMATE_AI_CLAN_TEST.sh 120 5 /path/to/base --apply-fixes  # Automate into /path/to/base/iter_N
```

## Ideal use

- **Before committing:** `./Tests/run.sh smoke` or `./Tests/run.sh ai-clan 120`
- **Clansmen efficiency (search, herding, gather, deposit):** `./Tests/run.sh unified` or `./Tests/run.sh unified 300`, then open `Tests/results/unified_<ts>/unified_report.md` — efficiency summary is at the top.
- **Debugging NPC behavior:** `./Tests/run.sh ai-clan 300`, then open `Tests/results/ai_clan_<ts>/analysis_report.md` and the logs
- **Regression / tuning:** `./Tests/run.sh automate 120 5` (no fixes) to see how many runs pass; use `--apply-fixes` only when you want the script to apply the built-in fixes
