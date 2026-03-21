# Launch Stone Age Clans with playtest capture and stream NPC snapshot lines to this terminal.
# Usage (from project root): .\Tests\run_and_monitor.ps1
# Requires: close any other running instance (SingleInstance lock).

$ErrorActionPreference = "Stop"
$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$GodotPath = Join-Path $ProjectPath "tools\godot\Godot_v4.6.1-stable_win64.exe"
if (-not (Test-Path $GodotPath)) {
    $c = Get-Command godot -ErrorAction SilentlyContinue
    if ($c) { $GodotPath = $c.Source }
}
if (-not (Test-Path $GodotPath)) {
    Write-Host "ERROR: Godot not found. Install Godot 4.x or place exe under tools\godot\"
    exit 1
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogDir = Join-Path $ProjectPath "Tests\playtest_$Timestamp"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$PlaytestFile = Join-Path $LogDir "playtest_session.jsonl"
$env:GODOT_TEST_LOG_DIR = $LogDir

$argLine = "--path `"$ProjectPath`" -- --playtest-capture --playtest-log-dir `"$LogDir`""

Write-Host "=== Stone Age Clans — playtest + live log ===" -ForegroundColor Cyan
Write-Host "Godot:   $GodotPath"
Write-Host "Session: $PlaytestFile"
Write-Host ""
Write-Host "Starting game window... (snapshots every ~5s; filter: snapshot / ai_clans / state_counts)"
Write-Host ""

Start-Process -FilePath $GodotPath -ArgumentList $argLine

# Wait until JSONL exists (engine init + SingleInstance)
$deadline = (Get-Date).AddSeconds(45)
while (-not (Test-Path $PlaytestFile)) {
    if ((Get-Date) -gt $deadline) {
        Write-Host "ERROR: No log file after 45s. Is another game instance still running? Close it and retry."
        exit 1
    }
    Start-Sleep -Milliseconds 400
}

Write-Host "Streaming (Ctrl+C stops this terminal only — game keeps running):" -ForegroundColor Yellow
Write-Host ""

# Live tail; user sees snapshot lines with state_counts + ai_clans
Get-Content -LiteralPath $PlaytestFile -Wait -Tail 12
