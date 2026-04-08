# Launch Stone Age Clans with playtest capture and stream NPC snapshot lines to this terminal.
# Usage (from project root): .\Tests\run_and_monitor.ps1
# Requires: close any other running instance (SingleInstance lock).

$ErrorActionPreference = "Stop"
$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# Prefer bundled exe; else PATH (same resolution as run_playtest.ps1)
$GodotPath = $null
$projectGodot = Join-Path $ProjectPath "tools\godot\Godot_v4.6.1-stable_win64.exe"
if (Test-Path $projectGodot) { $GodotPath = $projectGodot }
if (-not $GodotPath) {
    $found = Get-Command godot -ErrorAction SilentlyContinue
    if ($found) { $GodotPath = $found.Source }
}
if (-not $GodotPath) {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Godot\Godot_v4*_stable_win64.exe"
    )
    foreach ($p in $candidates) {
        $f = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($f) { $GodotPath = $f.FullName; break }
    }
}
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) {
    Write-Host "ERROR: Godot not found. Install Godot 4.x, add godot to PATH, or place Godot_v4*.exe under tools\godot"
    exit 1
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogDir = Join-Path $ProjectPath "Tests\playtest_$Timestamp"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$PlaytestFile = Join-Path $LogDir "playtest_session.jsonl"
$env:GODOT_TEST_LOG_DIR = $LogDir

# Single ArgumentList string with embedded quotes — required on Windows when the project path
# contains spaces (e.g. "Stone Age Clans"). An array like @("--path", $path) is mangled by
# Start-Process and Godot sees only ...\stoneageclans\Stone and aborts.
$argLine = "--path `"$ProjectPath`" -- --playtest-capture --playtest-log-dir `"$LogDir`""

Write-Host "=== Stone Age Clans - playtest + live log ===" -ForegroundColor Cyan
Write-Host "Godot:   $GodotPath"
Write-Host "Session: $PlaytestFile"
Write-Host ""
Write-Host 'Starting game window... snapshots every ~5s; watch for: snapshot, ai_clans, state_counts'
Write-Host ""

Start-Process -FilePath $GodotPath -ArgumentList $argLine

# Wait until JSONL exists (engine init + SingleInstance)
$deadline = (Get-Date).AddSeconds(45)
while (-not (Test-Path $PlaytestFile)) {
    if ((Get-Date) -gt $deadline) {
        Write-Host 'ERROR: No log file after 45s. Is another game instance still running? Close it and retry.'
        exit 1
    }
    Start-Sleep -Milliseconds 400
}

Write-Host 'Streaming: Ctrl+C stops this terminal only; game keeps running' -ForegroundColor Yellow
Write-Host ""

# Live tail; user sees snapshot lines with state_counts + ai_clans
Get-Content -LiteralPath $PlaytestFile -Wait -Tail 12
