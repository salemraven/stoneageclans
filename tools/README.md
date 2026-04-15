# Dev tools

The player uses **2D spritesheets** (`scripts/player.gd`, `WalkAnimation`, assets under `assets/sprites/`).

## Movement play test (windowed)

```bash
godot --path . res://scenes/MovementVisualTest.tscn
```

WASD / arrows; mouse wheel or **+** / **-** zooms. Root export **`equip_wood_club_for_test`** toggles wood club equipment for 2D club walk frames.

## Headless smoke + logs

From repo root:

```bash
bash tools/run_instrumented_playtest.sh
```

Runs **`Main.tscn`** headless (`--quit-after 4` = **4 main-loop iterations**, not seconds — see `godot --help`) and **`tee`**s output to **`Tests/logs/instrumented_playtest_<timestamp>.log`**. Set **`GODOT=/path/to/Godot`** if not using the default macOS app path. Uses **`SKIP_SINGLE_INSTANCE=1`**.

## Boot / load audit (autoload `RuntimeFaultSink`)

Each run writes **`user://runtime_boot_audit.log`** (Editor → open user data folder) with script-load checks for **`PartyCommandUtils`**, **`FormationUtils`**, **`FSM`**, **`Main.tscn`**, **`EntityRegistry`**. Append **`--runtime-boot-audit`** for extra path probes. Disable: **`SKIP_RUNTIME_FAULT_SINK=1`**.

## Player move trace

```bash
godot --path . --player-move-trace
```

Hold A/D to see `[PlayerMoveTrace]` in the console.

## Early-game verification (CI-style bundle)

Runs smoke, **ChunkUtils** invariants, **territory + ClanBrain JSONL** checks, and optionally the longer **ClanBrain** Main session.

```bash
bash tools/run_earlygame_verify.sh
```

- **`SKIP_CLAN_BRAIN_TEST=1`** — skip step 4 (~15s `Main` + JSONL assertions); steps 1–3 stay.
- Individual steps: `run_instrumented_playtest.sh`, `run_territory_brain_integration_verify.sh`, `run_clan_brain_test.sh`, or `godot --headless --path . --script res://tools/chunk_utils_verify.gd`.

**Note:** In **Godot 4.x**, `--quit-after` is **iterations** of the main loop, not wall-clock seconds (see `godot --help`). Older docs may say “seconds”; treat as wrong for 4.x.

## Exhaustive early-game gate (recommended before milestone)

Runs the base bundle, **TerritoryJobService** headless checks, a **long Main** session with **`--playtest-2min`** (or **`--playtest-4min`**) + **`--playtest-capture`** (~120s / ~240s **wall** time — Main’s timer quits; do not rely on **`--quit-after`** for “seconds”: in Godot 4.x it is **main-loop iterations**, see `godot --help`), then **`scripts/logging/analyze_playtest.py --strict`** on the JSONL, and scans logs for compile/load **hard errors**.

```bash
bash tools/run_exhaustive_earlygame_verify.sh
```

- **`EXHAUSTIVE_PLAYTEST_4MIN=1`** — use **`--playtest-4min`** instead of **`--playtest-2min`**.
- **`MIN_HERD_WILDNPC_ENTERS`** (default **`1`**) — passed to **`analyze_playtest.py --strict`**; set **`0`** to disable minimum `herd_wildnpc_enter` count.
- **`MIN_SESSION_SEC_FOR_ANALYZE`** (default **`90`**) — require **`max(t)`** in JSONL ≥ this (wall-clock session length from instrumentor); set **`0`** to disable.
- **`SKIP_LONG_MAIN=1`** — skip long Main + strict analyzer (still runs base + TerritoryJobService).
- **`python3 scripts/logging/analyze_playtest.py --strict [--min-herd-wildnpc-enters N] [--min-session-sec SEC] path/to/playtest_session.jsonl`** — herd flicker, `herd_count_change`, and optional **coverage** thresholds; exits `1` on violation.

## 2-minute NPC playtest + JSONL strict analysis (~2 min)

Runs **`Main`** headless with **`--playtest-2min`** and **`--playtest-capture`** (no `--quit-after` — combining quit-after with timed playtest can end the run in ~1s). Writes JSONL + `godot.log`, **`git` commit** in `commit.txt`, then **`analyze_playtest.py --strict`**.

```bash
bash tools/run_playtest_2min_analyze.sh
```

Optional: **`OUT_DIR=/abs/path/to/folder`** to control output location. **`MIN_HERD_WILDNPC_ENTERS`** (default **`3`**) and **`MIN_SESSION_SEC_FOR_ANALYZE`** (default **`90`**) tighten **`--strict`** so a ~2 min capture is not vacuous; set to **`0`** to disable either check.
