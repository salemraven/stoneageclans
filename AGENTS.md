# AGENTS.md

## Cursor Cloud specific instructions

### Environment overview

This is a pure **Godot 4.6.x GDScript** project — no npm, pip, Docker, or external services required. The only dependency is the Godot engine binary.

### Godot binary location

- **Path:** `/opt/godot/godot`  
- **Env var:** `export GODOT=/opt/godot/godot`  
- Always set `export SKIP_SINGLE_INSTANCE=1` before running headless or multiple instances.

### First-time import cache

After a fresh clone or when assets change, you must build the import cache before running scenes:

```bash
$GODOT --path /workspace --headless --import
```

This takes ~30s and creates `.godot/imported/`. Without it, scene loads fail with "Unable to open file" errors on `.ctex` files.

### Running the game

```bash
# Headless smoke test (4 iterations)
export GODOT=/opt/godot/godot SKIP_SINGLE_INSTANCE=1
bash tools/run_instrumented_playtest.sh

# GUI mode (needs DISPLAY)
DISPLAY=:1 SKIP_SINGLE_INSTANCE=1 $GODOT --path /workspace

# Early-game verification suite
bash tools/run_earlygame_verify.sh
```

### Known pre-existing issues (as of main branch)

- `project.godot` references two autoloads that don't exist in the repo: `scripts/logging/npc_productivity_instrument.gd` and `scripts/logging/runtime_fault_sink.gd`. These cause non-fatal ERROR logs but don't block gameplay or headless testing.
- The territory brain integration test (`tools/run_territory_brain_integration_verify.sh`) fails with `TERRITORY_BRAIN_INTEGRATION_FAIL`. This is a pre-existing test issue, not caused by environment setup.

### Lint / format

No dedicated GDScript linter is configured. The closest equivalent is running `$GODOT --path /workspace --headless --import` which triggers Godot's parser and catches syntax errors. The Godot editor LSP provides live diagnostics when using the godot-tools VS Code extension.

### Testing

- **Smoke test:** `bash tools/run_instrumented_playtest.sh` — boots Main.tscn headless for 4 iterations
- **Full suite:** `bash tools/run_earlygame_verify.sh` — 5-step verification (smoke, ChunkUtils, territory, repro, ClanBrain)
- **Python analyzer:** `python3 scripts/logging/analyze_playtest.py [--strict] path/to/session.jsonl`
- Test scripts are in `tools/`; test docs and logs in `Tests/`

### Display for GUI testing

The VM has `DISPLAY=:1` available (Xvfb). Use it for windowed Godot runs and screenshot/video capture.
