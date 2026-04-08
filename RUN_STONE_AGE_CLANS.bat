@echo off
REM Run StoneAgeClans — uses bundled Godot under tools\godot, falls back to PATH
set "PROJECT_DIR=%~dp0"
set "GODOT_PATH="

REM Prefer bundled exe
if exist "%PROJECT_DIR%tools\godot\Godot_v4.6.1-stable_win64.exe" set "GODOT_PATH=%PROJECT_DIR%tools\godot\Godot_v4.6.1-stable_win64.exe"

if defined GODOT_PATH (
    echo Launching StoneAgeClans...
    start "" "%GODOT_PATH%" --path "%PROJECT_DIR%"
) else (
    echo Godot not found under tools\godot\. Opening project.godot for manual launch...
    start "" "%PROJECT_DIR%project.godot"
    echo.
    echo If Godot opens: press F5 to run the game.
    pause
)
