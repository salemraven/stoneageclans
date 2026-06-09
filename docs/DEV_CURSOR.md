# Cursor + Godot (StoneAgeClans)

## “Play test” vs automated tests

- **Play test** — Run the **game in a window** (WASD, UI). Main scene: `godot --path .` — or movement-only: `godot --path . res://scenes/MovementVisualTest.tscn`.
- **Headless smoke** — `bash tools/run_instrumented_playtest.sh` (boots `Main.tscn` briefly; see `tools/README.md`).

## macOS Godot path

Use the binary + `--path` to the **stoneageclans** folder (with `--editor` for the editor). Example:

`/Applications/Godot.app/Contents/MacOS/Godot --path "/path/to/stoneageclans"`
