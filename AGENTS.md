# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

Stone Age Clans is a Godot 4.6 GDScript game (tactical survival / colony management). No external services, databases, or package managers — the only runtime dependency is the **Godot 4.6.1 engine binary**.

### Engine binary

On the Cloud VM, Godot is installed at `/usr/local/bin/godot` (Linux x86_64, 4.6.1-stable). The repo's `tools/godot/` expects Windows exes which are gitignored; on Linux, use `godot` directly from PATH.

### Running the game

| Mode | Command |
|---|---|
| **GUI** | `DISPLAY=:1 godot --path /workspace` |
| **Headless (smoke)** | `godot --headless --path /workspace --quit-after 5` |
| **Headless (timed AI test)** | `timeout 120 godot --headless --path /workspace -- --playtest-capture --playtest-log-dir <output_dir>` |
| **Editor** | `DISPLAY=:1 godot --editor --path /workspace` |

### First run: import step

After a fresh clone or if `.godot/` is missing, run `godot --headless --path /workspace --import` to build the import cache. Without this step, autoloads may fail to resolve custom class types.

### Tests

The `Tests/README.md` references bash scripts (`run.sh`, `RUN_AI_CLAN_TEST.sh`, etc.) that **do not exist** in the repo — only PowerShell `.ps1` scripts remain. On Linux, run headless tests directly via the Godot CLI commands above.

- `Tests/config.env` (gitignored): set `GODOT_PATH=/usr/local/bin/godot` for any `.ps1` scripts adapted for Linux.
- Playtest output goes to `Tests/results/` (gitignored).
- Playtest events are logged to `playtest_session.jsonl` when `--playtest-capture --playtest-log-dir <dir>` flags are passed.

### Lint / static analysis

There is no GDScript linter configured in this repo. Godot's own parser errors surface when running or importing the project (`--import` or `--headless --path .`). Treat parser errors in console output as the equivalent of lint failures.

### Key caveats

- The project was developed on **Windows 11**; all `.ps1`/`.cmd`/`.bat` tooling is Windows-only. On Linux, invoke `godot` directly.
- The display server for GUI mode on Cloud VMs is `:1` (set `DISPLAY=:1`).
- `project.godot` sets `run/main_scene` to `res://scenes/Main.tscn`.
- Design docs and game bible live in `bible.md` and `guides/`.
