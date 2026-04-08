# Archived macOS shell scripts

These `.sh` scripts were written on macOS with hardcoded `/Users/macbook/...` and `/Applications/Godot.app/...` paths. They do not run on Windows 11.

Windows equivalents live in:
- `Tests/run_playtest.ps1`, `Tests/run_and_monitor.ps1`, `Tests/run_live_verify.ps1`
- `tools/run_playtest_session.ps1`, `tools/run_imp_test.ps1`, `tools/run_imp_diagnose.ps1`
- `run_agro_combat_test.ps1`
- `tools/godot/godot.cmd`, `tools/godot/LaunchEditor.cmd`

If you return to macOS, these scripts need updating to use `$SCRIPT_DIR` instead of hardcoded paths.
