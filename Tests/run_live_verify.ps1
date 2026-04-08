# Manual play + instrumentation at a FIXED log path (for you + Cursor).
# - Windowed game (not headless). --playtest-capture writes JSONL continuously (flushed per line).
# - Log file is always:  <project>\Tests\live_verify\playtest_session.jsonl
# - Key events: snapshot, npc_world_probe (positions/velocity/state every ~5s), npc_fsm_transition (each AI state change),
#   herd_*, combat_*, gather_*, ordered_follow_*, etc.
#
# Usage (PowerShell):
#   .\Tests\run_live_verify.ps1                    # start game + tail last lines in this terminal
#   .\Tests\run_live_verify.ps1 -NoMonitor         # start game only (e.g. Cursor agent / background)
#
# Before run: close any other Stone Age Clans instance (SingleInstance lock).

param(
    [switch]$NoMonitor = $false
)

$ErrorActionPreference = "Stop"
$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$LogDir = Join-Path $ProjectPath "Tests\live_verify"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$PlaytestFile = Join-Path $LogDir "playtest_session.jsonl"

$GodotPath = $null
$projectGodot = Join-Path $ProjectPath "tools\godot\Godot_v4.6.1-stable_win64.exe"
if (Test-Path $projectGodot) { $GodotPath = $projectGodot }
if (-not $GodotPath) {
    $found = Get-Command godot -ErrorAction SilentlyContinue
    if ($found) { $GodotPath = $found.Source }
}
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) {
    Write-Host "ERROR: Godot not found. Put Godot_v4*.exe under tools\godot\ or add godot to PATH."
    exit 1
}

$env:GODOT_TEST_LOG_DIR = $LogDir
$argLine = "--path `"$ProjectPath`" -- --playtest-capture --playtest-log-dir `"$LogDir`""

Write-Host ""
Write-Host "=== Live verify (instrumentation on) ===" -ForegroundColor Cyan
Write-Host "Log file (tell Cursor to read this path when debugging):" -ForegroundColor Yellow
Write-Host "  $PlaytestFile"
Write-Host ""
Write-Host "Starting game..."
Start-Process -FilePath $GodotPath -ArgumentList $argLine

$deadline = (Get-Date).AddSeconds(60)
while (-not (Test-Path $PlaytestFile)) {
    if ((Get-Date) -gt $deadline) {
        Write-Host "ERROR: No JSONL after 60s. Close duplicate instances and retry."
        exit 1
    }
    Start-Sleep -Milliseconds 400
}

Write-Host "Capture active. Play, reproduce bugs, then message Cursor with ~when it happened." -ForegroundColor Green
Write-Host ""

if (-not $NoMonitor) {
    Write-Host "Streaming JSONL tail (Ctrl+C stops THIS terminal only; game keeps running):" -ForegroundColor DarkGray
    Get-Content -LiteralPath $PlaytestFile -Wait -Tail 15
}
