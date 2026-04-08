@echo off
REM Opens the Godot editor with this project (uses bundled exe next to this script).
cd /d "%~dp0..\.."
start "" "%~dp0Godot_v4.6.1-stable_win64.exe" --editor --path "%CD%"
