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

## Wild NPC movement verify (profiles + migration despawn)

```bash
SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/wild_npc_movement_verify.gd
```

Checks **`NPCConfig`** wild profiles, instantiates **`NPC.tscn`** as deer with a west corridor, applies **`_apply_wild_profile`**, asserts migratory activation, crosses exit **+margin**, and asserts **`queue_free`** from **`_check_migration_despawn`**. Exit **0** prints `WILD_NPC_MOVEMENT_VERIFY_OK`.

## Hunt butcher pipeline (loot / TaskRunner meta)

Manual **`ButcherTask`** ticks plus **`TaskRunner.assign_job`** with **`hunt_butchering`** (ordered-follow exemption) and cancellation when forbidden. Exit **0** prints **`TEST_HUNT_BUTCHER_OK`**.

```bash
SKIP_SINGLE_INSTANCE=1 godot --headless --path . --script res://tools/test_hunt_butcher.gd
```

You may see a **short burst** of benign “Identifier not found: UnifiedLogger / NPCConfig” during the initial script parse — the project completes boot (`RuntimeFaultSink` audit). Increase **`--quit-after`** only if needed for slow machines (`SceneTree --script` uses the main-loop budget).

## Wild NPC JSONL trace (`--wild-npc-trace`)

Session log for debugging **migration spawns, chunk wildlife batches, and throttled flee positions**:

```bash
SKIP_SINGLE_INSTANCE=1 godot --path . --wild-npc-trace
```

Writes **`user://wild_npc_trace_*.jsonl`**. Toggle in editor: **`DebugConfig.enable_wild_npc_trace`**; tick spacing: **`wild_npc_trace_interval_sec`**.

**Related guide:** **`guides/wildlife_movement.md`** (Debugging section). **`--playtest-capture`** also records **`migration_complete`** and richer **`npc_world_probe`** rows (deer/mammoth + **`mig_*`** fields).

## Boot / load audit (autoload `RuntimeFaultSink`)

Each run writes **`user://runtime_boot_audit.log`** (Editor → open user data folder) with script-load checks for **`PartyCommandUtils`**, **`FormationUtils`**, **`FSM`**, **`Main.tscn`**, **`EntityRegistry`**. Append **`--runtime-boot-audit`** for extra path probes. Disable: **`SKIP_RUNTIME_FAULT_SINK=1`**.

## Player move trace

```bash
godot --path . --player-move-trace
```

Hold A/D to see `[PlayerMoveTrace]` in the console.

## Ultimate NPC & ClanBrain test (recommended gate)

Smoke + **`run_instrumented_playtest`** + **`run_territory_brain_integration_verify`** + short ClanBrain **`Main`** capture + **`analyze_playtest.py --strict-clanbrain`**, plus **NPC-only ~120 s `Main`** (`--npc-only-world`) + **`--strict-npc-sim`** (gather/hunt/growth JSONL thresholds). Details: **`guides/Ultimate_npc_clanbrain_test.md`**.

```bash
bash tools/run_ultimate_npc_clanbrain_test.sh
```

Optional: **`SKIP_NPC_ONLY_2MIN=1`** skips the bundled NPC-only capture. **`ULTIMATE_LONG_2MIN=1`** also runs **`run_playtest_2min_analyze.sh`** (~2 min **`Main`**) with herd **`--strict`** plus **`ANALYZER_EXTRA_ARGS`** including **`--strict-clanbrain`**. Tunables: **`ULTIMATE_MIN_CLAN_BRAIN_EVALS`**, **`ULTIMATE_MIN_QUOTA_UPDATES`**, **`ULTIMATE_NPC_SIM_*`**, **`MIN_NPC_SESSION_SEC_FOR_ANALYZE`** (see guide).

Standalone: **`bash tools/run_playtest_npc_only_2min_analyze.sh`**.

Cli: **`analyze_playtest.py --strict-clanbrain`**, **`--strict-npc-sim`**, **`--require-npc-only-session`**, **`--min-npc-*`**, **`--allowed-ai-hunt-prey`**, **`--min-clanbrain-eval-events`**, **`--min-clanbrain-quota-updates`**.

## Early-game verification (CI-style bundle)

Runs smoke, **ChunkUtils** invariants, **territory + ClanBrain JSONL** checks, **reproduction harness** (Player designated-father / two births), and optionally the longer **ClanBrain** Main session.

```bash
bash tools/run_earlygame_verify.sh
```

- **`SKIP_CLAN_BRAIN_TEST=1`** — skip step 5 (~15s `Main` + JSONL assertions); steps 1–4 stay.
- **`SKIP_REPRO_HARNESS=1`** — skip step 4 (`--repro-harness` ~12–15s).
- Individual steps: `run_instrumented_playtest.sh`, `run_territory_brain_integration_verify.sh`, `run_repro_harness.sh`, `run_clan_brain_test.sh`, `run_ultimate_npc_clanbrain_test.sh`, or `godot --headless --path . --script res://tools/chunk_utils_verify.gd`.

## Reproduction regression (Player + two births)

Isolated claim + woman + Living Hut; exits **0** after two births. Catches regressions where the **Player** mate uses the wrong “in claim” check (`get_clan_name()` vs missing `clan_name` property).

```bash
SKIP_SINGLE_INSTANCE=1 bash tools/run_repro_harness.sh
# or: godot --path . --headless -- --repro-harness
```

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

**Combat / agro stability (same script):**

- Runs **after every analysis** — prints summaries from `npc_fsm_transition`, `agro_threshold_crossed`, and enhanced `npc_world_probe` combat rows (`ctl_d`, `agro`, `c_lock`, `fsm_thr` on cavemen/clansmen).
- **`--strict-stability`** exits `1` if any threshold trips (all tunable via CLI flags):
  - **Combat churn:** too many FSM transitions touching `combat` / `flee_combat` in a sliding window (default 14 transitions / 14s per fighter).
  - **Agro ping-pong:** too many directional flips on `agro_threshold_crossed` per NPC per window (default 14 flips / 30s).
  - **Frozen combat probes:** successive snapshot streak in combat with **target in range** but **near-zero velocity**, excluding `combat_locked` windup/recovery (default 6 snapshots at capture interval).

Example:

```bash
python3 scripts/logging/analyze_playtest.py ~/path/playtest_session.jsonl --strict --strict-stability
```

## 2-minute NPC playtest + JSONL strict analysis (~2 min)

Runs **`Main`** headless with **`--playtest-2min`** and **`--playtest-capture`** (no `--quit-after` — combining quit-after with timed playtest can end the run in ~1s). Writes JSONL + `godot.log`, **`git` commit** in `commit.txt`, then **`analyze_playtest.py --strict`**.

```bash
bash tools/run_playtest_2min_analyze.sh
```

Optional: **`OUT_DIR=/abs/path/to/folder`** to control output location. **`MIN_HERD_WILDNPC_ENTERS`** (default **`3`**) and **`MIN_SESSION_SEC_FOR_ANALYZE`** (default **`90`**) tighten **`--strict`** so a ~2 min capture is not vacuous; set to **`0`** to disable either check.

## GitHub Pages (browser build = newest exported Web preset)

GitHub Pages on **`salemraven/stoneageclans`** serves the **`gh-pages`** branch (usually `/` root). That branch is **not** auto-updated from `main`; it only changes when someone runs a **Web export** and pushes those files.

From repo root (Godot 4.x + Web export templates installed):

```bash
bash tools/deploy_github_pages.sh
```

Set **`GODOT=/path/to/Godot`** if the macOS default path is wrong.

The script:

1. Runs **`--export-release "Web"`** (see **`export_presets.cfg`** → **`build/web/index.html`**).
2. Writes **`build/web/BUILD.txt`** with UTC time + current **`main`** short SHA (so you can confirm what was exported).
3. **`rsync`** into a temporary **`gh-pages`** worktree and **`git push origin gh-pages`**.

After push, wait ~1–2 minutes, then **hard-refresh** the game URL (or DevTools → Disable cache). Open **`…/BUILD.txt`** on the same Pages site to verify the stamp matches your machine.

**Repo Settings → Pages:** Source should be **Deploy from a branch** → **`gh-pages`** → **`/ (root)`**.
