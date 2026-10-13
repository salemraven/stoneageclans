# AGENTS.md

## Cursor Cloud specific instructions

This is a **Godot 4.6.1** game (`StoneAgeClans`), top-down 2D survival/colony sim. Main scene is `res://scenes/Main.tscn` (`run/main_scene` in `project.godot`). GDScript only — there is no compile/build step; scripts are parsed at runtime, and `RuntimeFaultSink` prints a `boot audit` listing each autoload/script as `ok` or failing on startup.

### Engine / how the binary is provided
- The repo only bundles the **Windows** Godot exe under `tools/godot/` (gitignored). On the Linux cloud VM the engine is installed to `/usr/local/bin/godot` by the startup update script (downloads `Godot_v4.6.1-stable_linux.x86_64`). Just run `godot`.
- The bundled Windows launchers (`RUN_STONE_AGE_CLANS.bat`, `tools/godot/godot.cmd`) and the many `.ps1` scripts are Windows-only — ignore them on Linux. Most `Tests/run.sh`-style entry points referenced in `Tests/README.md` no longer exist; use the commands below instead.

### Required first step after pulling assets
- The import cache (`.godot/imported/`) is gitignored, so assets must be imported before the game can load, otherwise `Main.tscn` fails with "Failed loading resource". The update script runs `godot --headless --path /workspace --import` for this. If you add/change image/asset files, re-run that import once.

### Running headless (smoke test / NPC sim — no display needed)
- `SKIP_SINGLE_INSTANCE=1 godot --headless --path /workspace --quit-after 300` boots Main, runs the sim for N main-loop iterations, and exits 0. Watch for `SCRIPT ERROR` / `boot audit ... fail` in stdout — clean run = environment healthy.
- `--quit-after` counts **main-loop iterations, not seconds** (Godot 4.x). Always set `SKIP_SINGLE_INSTANCE=1` (the `SingleInstance` autoload otherwise refuses a second instance).
- `bash tools/run_instrumented_playtest.sh` wraps a short headless boot + log capture into `Tests/logs/` (set `GODOT=/usr/local/bin/godot` since the script defaults to the macOS path).

### Running the GUI game (windowed)
- A virtual X display is available at `DISPLAY=:1` (VNC, 1920x1200). There is **no GPU**: the VM uses Mesa **llvmpipe** software rendering. The active `project.godot` has no `rendering_method` set (defaults to Vulkan/forward_plus), which does not work on llvmpipe, so you **must** force the GL Compatibility renderer:
  - `DISPLAY=:1 SKIP_SINGLE_INSTANCE=1 LIBGL_ALWAYS_SOFTWARE=1 godot --path /workspace --rendering-method gl_compatibility`
- Audio always falls back to the dummy driver ("All audio drivers failed") — this is expected on the VM, not an error.
- Player controls: `WASD` move, `I` toggle inventory, `Space` gather. Player starts with a campfire (inventory) + spear (hotbar slot 1).

### Useful runtime flags (defined in `main.gd` / playtest tooling)
- `--session-quickstart` start with a claim + huts + women instead of default cavemen; `--session-instrument` + `--log-console` for structured SESSION/MOVEMENT logging. See `run_session_instrument.sh` (defaults `GODOT` to macOS path; override `GODOT=/usr/local/bin/godot`).
