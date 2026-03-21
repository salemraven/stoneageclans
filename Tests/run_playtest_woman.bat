@echo off
REM Run 2-min playtest with woman test + occupation diag
REM Data: Tests\playtest_YYYYMMDD_HHMMSS\playtest_session.jsonl
REM Game auto-quits at 120s. For Living Hut test: place campfire, herd 2 women, build 1 Living Hut.

set "PROJECT_DIR=%~dp0.."
set "GODOT_PATH=%USERPROFILE%\Desktop\godot-engine\Godot_v4.6.1-stable_win64.exe"
if not exist "%GODOT_PATH%" set "GODOT_PATH=C:\Program Files\Godot\Godot_v4.6-stable_win64.exe"

for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value 2^>nul') do set "dt=%%a"
set "ts=%dt:~0,8%_%dt:~8,6%"
set "LOG_DIR=%PROJECT_DIR%\Tests\playtest_%ts%"
mkdir "%LOG_DIR%" 2>nul

set "GODOT_TEST_LOG_DIR=%LOG_DIR%"

echo === 2-min Playtest (woman + Living Hut) ===
echo Data: %LOG_DIR%\playtest_session.jsonl
echo Game auto-quit at 120s. Place campfire, herd 2 women, build 1 Living Hut.
echo.

"%GODOT_PATH%" --path "%PROJECT_DIR%" -- --playtest-2min --woman-test --occupation-diag
echo.
echo Done. Data: %LOG_DIR%
pause
