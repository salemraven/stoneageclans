@echo off
REM Bypass single-instance lock so the window opens even if another Godot was left running.
setlocal
set SKIP_SINGLE_INSTANCE=1
cd /d "%~dp0..\.."
start "" "%~dp0Godot_v4.6.1-stable_win64.exe" --path "%CD%" -- --playtest-capture --rts-playtest-spawn
