@echo off
REM Double-click this file to open THIS folder as the Godot project (fixes stale Project Manager paths).
cd /d "%~dp0"
if not exist "project.godot" (
  echo ERROR: project.godot not found in:
  echo   %CD%
  echo Move this .cmd next to project.godot or open the correct StoneAgeClans folder.
  pause
  exit /b 1
)
set "GODOT=%~dp0tools\godot\Godot_v4.6.1-stable_win64.exe"
if not exist "%GODOT%" (
  echo ERROR: Missing bundled Godot. Download to tools\godot\ — see tools\godot\README.txt
  pause
  exit /b 1
)
start "" "%GODOT%" --editor --path "%CD%"
