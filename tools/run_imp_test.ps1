# IMP Test — Instrumented Manual Playtest
# Launches Godot in a new window (non-blocking) with PlaytestInstrumentor.
# Usage: .\tools\run_imp_test.ps1
#
# Windows note: SKIP_SINGLE_INSTANCE must apply to the Godot process. PowerShell Start-Process
# env inheritance is unreliable on some setups; we spawn via a generated .cmd so `set` + `start`
# puts Godot in a process tree that always sees SKIP_SINGLE_INSTANCE=1.

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = Join-Path $projectRoot "test_output\sessions\IMP_$stamp"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$pointerFile = Join-Path $projectRoot "test_output\LATEST_SESSION.txt"
@"
IMP Test session
$logDir
playtest_session.jsonl
"@ | Set-Content -Path $pointerFile -Encoding UTF8

$godotGui = Join-Path $projectRoot "tools\godot\Godot_v4.6.1-stable_win64.exe"
$godotConsole = Join-Path $projectRoot "tools\godot\Godot_v4.6.1-stable_win64_console.exe"
$godotExe = if (Test-Path $godotGui) { $godotGui } elseif (Test-Path $godotConsole) { $godotConsole } else { $null }
if (-not $godotExe) {
    Write-Error "Godot not found. Expected one of:`n  $godotGui`n  $godotConsole"
}

$metaFile = Join-Path $projectRoot "test_output\IMP_LAUNCH_META.txt"
$batchFile = Join-Path $projectRoot "test_output\_imp_last_launch.cmd"
$consoleLogHint = Join-Path $projectRoot "test_output\IMP_DIAGNOSE.log"

# Batch: set env in cmd, then start Godot (child inherits SKIP_SINGLE_INSTANCE)
$batchBody = @"
@echo off
set SKIP_SINGLE_INSTANCE=1
cd /d "$projectRoot"
start "Stone Age Clans IMP" "$godotExe" --path "$projectRoot" -- --playtest-capture --playtest-log-dir "$logDir"
"@
Set-Content -Path $batchFile -Value $batchBody -Encoding ASCII

$when = Get-Date -Format "o"
@"
IMP launch
Time (local): $when
Session dir: $logDir
Godot: $godotExe
Launcher batch: $batchFile
If the game window never appears, run:
  .\tools\run_imp_diagnose.ps1
Then open: $consoleLogHint
"@ | Set-Content -Path $metaFile -Encoding UTF8

Write-Host "=== IMP Test (Instrumented Manual Playtest) ===" -ForegroundColor Cyan
Write-Host "Log dir: $logDir"
Write-Host "JSONL:   $(Join-Path $logDir 'playtest_session.jsonl')"
Write-Host "Pointer: $pointerFile"
Write-Host "Meta:    $metaFile"
Write-Host ""
Write-Host "Starting Godot via batch (SKIP_SINGLE_INSTANCE for child process)."
Write-Host "No window? Run: .\tools\run_imp_diagnose.ps1  ->  test_output\IMP_DIAGNOSE.log"
Write-Host ""

Start-Process -FilePath $batchFile -WorkingDirectory $projectRoot
