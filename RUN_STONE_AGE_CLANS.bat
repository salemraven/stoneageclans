@echo off
REM Run Stone Age Clans - tries common Godot paths, then opens project
set "PROJECT_DIR=%~dp0"
set "GODOT_PATH="

REM Try common locations
if exist "%USERPROFILE%\Desktop\godot-engine\Godot_v4.6.1-stable_win64.exe" set "GODOT_PATH=%USERPROFILE%\Desktop\godot-engine\Godot_v4.6.1-stable_win64.exe"
if exist "%USERPROFILE%\Desktop\GodotPortable\Godot_v4.6.1-stable_win64.exe" set "GODOT_PATH=%USERPROFILE%\Desktop\GodotPortable\Godot_v4.6.1-stable_win64.exe"
if exist "C:\Program Files\Godot\Godot_v4.6-stable_win64.exe" set "GODOT_PATH=C:\Program Files\Godot\Godot_v4.6-stable_win64.exe"

if defined GODOT_PATH (
    echo Launching Stone Age Clans...
    start "" "%GODOT_PATH%" --path "%PROJECT_DIR%" --run
) else (
    echo Godot not found. Opening project for manual launch...
    start "" "%PROJECT_DIR%project.godot"
    echo.
    echo If Godot opens: press F5 to run the game.
    echo If not: Open Godot manually, load this project, press F5.
    pause
)
