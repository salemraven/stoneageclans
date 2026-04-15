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

Runs **`Main.tscn`** headless (`--quit-after 4`) and **`tee`**s output to **`Tests/logs/instrumented_playtest_<timestamp>.log`**. Set **`GODOT=/path/to/Godot`** if not using the default macOS app path. Uses **`SKIP_SINGLE_INSTANCE=1`**.

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

**Note:** `--quit-after` is **seconds**, not frames (`TESTING_FRAMEWORK.md`).
