# Playtest Runner - Run game with data capture and monitoring
# Only one game instance can run (see autoload SingleInstance). Close any running playtest first.
# Live tail in same terminal: .\Tests\run_and_monitor.ps1
# Usage: .\Tests\run_playtest.ps1
#        .\Tests\run_playtest.ps1 -Timed 2    # 2-min timed test (auto-quit)
#        .\Tests\run_playtest.ps1 -Timed 4    # 4-min timed test
#        .\Tests\run_playtest.ps1 -AllowSecondInstance   # if editor/game already running (bypass TCP lock)
# Play in the game window. Data written to Tests/playtest_YYYYMMDD_HHMMSS/
# After quit: playtest_report.txt summary

param(
    [int]$Timed = 0,   # 0=manual quit, 2=2min, 4=4min
    [switch]$AllowSecondInstance = $false  # set when editor/game already running; sets SKIP_SINGLE_INSTANCE=1
)

$ErrorActionPreference = "Stop"
$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$UserData = "$env:APPDATA\Godot\app_userdata\StoneAgeClans"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogDir = Join-Path $ProjectPath "Tests\playtest_$Timestamp"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

# Find Godot
$GodotPath = $null
$projectGodot = Join-Path $ProjectPath "tools\godot\Godot_v4.6.1-stable_win64.exe"
if (Test-Path $projectGodot) { $GodotPath = $projectGodot }
if (-not $GodotPath) {
    $found = Get-Command godot -ErrorAction SilentlyContinue
    if ($found) { $GodotPath = $found.Source }
}
if (-not $GodotPath) {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Godot\Godot_v4*_stable_win64.exe",
        "C:\Program Files\Godot\*.exe"
    )
    foreach ($p in $candidates) {
        $f = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($f) { $GodotPath = $f.FullName; break }
    }
}
if (-not $GodotPath) {
    Write-Host "ERROR: Godot not found. Install Godot 4.x or set GodotPath."
    exit 1
}

Write-Host "=== Stone Age Clans Playtest ==="
Write-Host "Project: $ProjectPath"
Write-Host "Log dir: $LogDir"
Write-Host "Godot: $GodotPath"
Write-Host ""

# Single ArgumentList string so paths with spaces (e.g. "Stone Age Clans") are not split (Godot would see "...\Stone" only).
$argLine = "--path `"$ProjectPath`" -- --playtest-capture --playtest-log-dir `"$LogDir`""
if ($Timed -eq 2) { $argLine += " --playtest-2min"; Write-Host "Mode: 2-min timed (auto-quit)" }
elseif ($Timed -eq 4) { $argLine += " --playtest-4min"; Write-Host "Mode: 4-min timed (auto-quit)" }
else { Write-Host "Mode: Manual quit (play, then close game)" }
Write-Host ""

$env:GODOT_TEST_LOG_DIR = $LogDir
if ($AllowSecondInstance) { $env:SKIP_SINGLE_INSTANCE = "1" }
$PlaytestFile = Join-Path $LogDir "playtest_session.jsonl"
Write-Host "Starting game... (playtest data -> $PlaytestFile)"
Write-Host "To monitor live in another terminal: Get-Content '$PlaytestFile' -Wait"
Write-Host ""

# Run Godot (foreground - user plays). Start-Process -Wait ensures we don't run reporter until exit.
Start-Process -FilePath $GodotPath -ArgumentList $argLine -Wait
Start-Sleep -Milliseconds 500  # release file handle before reporter reads JSONL

# Session file for this run (always this path — do not fall back to user:// for reporter)
$PlaytestPath = Join-Path $LogDir "playtest_session.jsonl"
if (-not (Test-Path -LiteralPath $PlaytestPath)) {
    $alt = Get-ChildItem "$LogDir\playtest_*.jsonl" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    if ($alt) { $PlaytestPath = $alt }
}
$ReporterSentinel = Join-Path $ProjectPath "Tests\.playtest_reporter_path.txt"
$absSession = $PlaytestPath
if (Test-Path -LiteralPath $PlaytestPath) {
    $absSession = (Resolve-Path -LiteralPath $PlaytestPath).Path
}
# Line count / fallback display only
$LineCountPath = $PlaytestPath
if (-not (Test-Path -LiteralPath $LineCountPath)) {
    $fallback = Get-ChildItem "$UserData\playtest_*.jsonl" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    if ($fallback) { $LineCountPath = $fallback }
}

Write-Host ""
Write-Host "=== Playtest Data ==="
$sessionExists = Test-Path -LiteralPath $PlaytestPath
if ($sessionExists) {
    $lineCount = (Get-Content -LiteralPath $PlaytestPath | Measure-Object -Line).Lines
    Write-Host "Events captured: $lineCount"
    Write-Host "File: $PlaytestPath"
} elseif (Test-Path -LiteralPath $LineCountPath) {
    $lineCount = (Get-Content -LiteralPath $LineCountPath | Measure-Object -Line).Lines
    Write-Host "Events captured (fallback user://): $lineCount"
    Write-Host "File: $LineCountPath"
} else {
    Write-Host "No session JSONL at: $PlaytestPath"
}
Write-Host ""
Write-Host "Running reporter..."
$reportTarget = if ($sessionExists) { (Resolve-Path -LiteralPath $PlaytestPath).Path } else { $absSession }
$env:GODOT_REPORT_JSONL = $reportTarget
Set-Content -Path $ReporterSentinel -Value $reportTarget -Encoding utf8
& $GodotPath --path $ProjectPath --headless -s scripts/logging/playtest_reporter.gd -- $reportTarget 2>&1 | Out-File -FilePath (Join-Path $LogDir "playtest_report.txt") -Encoding utf8
Remove-Item Env:GODOT_REPORT_JSONL -ErrorAction SilentlyContinue
Remove-Item $ReporterSentinel -ErrorAction SilentlyContinue
Write-Host "Report: $LogDir\playtest_report.txt"
Get-Content (Join-Path $LogDir "playtest_report.txt")
Write-Host ""
Write-Host "Logs: $LogDir"
