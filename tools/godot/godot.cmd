@echo off
REM Run bundled Godot from repo root. Prefer console build for headless/CI (stdout).
setlocal
set "HERE=%~dp0"
set "CONSOLE=%HERE%Godot_v4.6.1-stable_win64_console.exe"
set "GUI=%HERE%Godot_v4.6.1-stable_win64.exe"
if exist "%CONSOLE%" (
  "%CONSOLE%" %*
) else if exist "%GUI%" (
  "%GUI%" %*
) else (
  echo ERROR: No Godot exe in "%HERE%" — see tools\godot\README.txt 1>&2
  exit /b 1
)
