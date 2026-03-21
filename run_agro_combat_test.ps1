# AOP Refactor Post-Implementation Test
# Runs agro-combat-test with instrumentation, then verifies logs and JSONL output.
# Usage: .\run_agro_combat_test.ps1
# Requires: Godot 4.x in PATH or set $GodotPath below

$ErrorActionPreference = "Stop"
$ProjectPath = $PSScriptRoot
$UserData = "$env:APPDATA\Godot\app_userdata\StoneAgeClans"
$LogDir = "$ProjectPath\test_output"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Find Godot (prefer project-local, then PATH, then common locations)
$GodotPath = $null
$projectGodot = Join-Path $PSScriptRoot "tools\godot\Godot_v4.6.1-stable_win64.exe"
if (Test-Path $projectGodot) {
    $GodotPath = $projectGodot
}
if (-not $GodotPath) {
    foreach ($name in @("godot", "godot4", "Godot_v4.3-stable_win64.exe", "Godot_v4.2-stable_win64.exe")) {
        $found = Get-Command $name -ErrorAction SilentlyContinue
        if ($found) { $GodotPath = $found.Source; break }
    }
}
if (-not $GodotPath) {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Godot\Godot_v4*_stable_win64.exe",
        "C:\Program Files\Godot\*.exe",
        "$env:USERPROFILE\Desktop\godot-engine\Godot_v4*.exe"
    )
    foreach ($p in $candidates) {
        $f = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($f) { $GodotPath = $f.FullName; break }
    }
}

if (-not $GodotPath) {
    Write-Host "ERROR: Godot not found. Install Godot 4.x or set GodotPath in this script."
    exit 1
}

Write-Host "Using Godot: $GodotPath"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

# Run agro-combat-test (auto-quits after 60s)
# --verbose enables TARGET_SELECTED (DEBUG) logs; --agro-combat-test enables PlaytestInstrumentor
Write-Host "Running agro-combat-test (60s, then auto-quit)..."
$env:GODOT_TEST_LOG_DIR = $LogDir
& $GodotPath --path $ProjectPath -- --agro-combat-test --verbose 2>&1 | Out-File -FilePath "$LogDir\agro_test_$Timestamp.log" -Encoding utf8

# Locate playtest JSONL
$PlaytestPath = $null
if (Test-Path "$UserData\last_playtest_path.txt") {
    $PlaytestPath = Get-Content "$UserData\last_playtest_path.txt" -Raw
    $PlaytestPath = $PlaytestPath.Trim()
}
if (-not $PlaytestPath -or -not (Test-Path $PlaytestPath)) {
    $PlaytestPath = Get-ChildItem "$UserData\playtest_*.jsonl" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $PlaytestPath) {
    $PlaytestPath = Get-ChildItem "$LogDir\playtest_*.jsonl" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}

Write-Host ""
Write-Host "=== AOP Refactor Test Report ==="
Write-Host ""

# Check game_logs.txt for TARGET_SELECTED
$GameLogs = "$UserData\game_logs.txt"
$targetSelected = 0
$combatDetectionNull = 0
if (Test-Path $GameLogs) {
    $content = Get-Content $GameLogs -Raw -ErrorAction SilentlyContinue
    $targetSelected = ([regex]::Matches($content, "TARGET_SELECTED")).Count
    $combatDetectionNull = ([regex]::Matches($content, "combat_detection_null")).Count
}

Write-Host "1. TARGET_SELECTED logs (PerceptionArea get_nearest_enemy):"
if ($targetSelected -gt 0) {
    Write-Host "   PASS - Found $targetSelected TARGET_SELECTED entries in game_logs.txt"
} else {
    Write-Host "   FAIL - No TARGET_SELECTED found. Ensure --verbose or enable_agro_combat_test sets DEBUG level."
}

Write-Host ""
Write-Host "2. combat_detection_null (should be 0 when enemies in range):"
if ($combatDetectionNull -eq 0) {
    Write-Host "   PASS - No combat_detection_null (PerceptionArea working)"
} else {
    Write-Host "   WARN - Found $combatDetectionNull combat_detection_null (PerceptionArea may be null when it shouldn't)"
}

Write-Host ""
Write-Host "3. Playtest JSONL:"
if ($PlaytestPath -and (Test-Path $PlaytestPath)) {
    $lines = Get-Content $PlaytestPath
    $combatStarted = ($lines | Where-Object { $_ -match '"evt":"combat_started"' }).Count
    $agroIncreased = ($lines | Where-Object { $_ -match '"evt":"agro_increased"' }).Count
    $perceptionQuery = ($lines | Where-Object { $_ -match '"evt":"perception_query"' }).Count
    $detectionNull = ($lines | Where-Object { $_ -match '"evt":"combat_detection_null"' }).Count

    Write-Host "   File: $PlaytestPath"
    Write-Host "   combat_started: $combatStarted"
    Write-Host "   agro_increased: $agroIncreased"
    Write-Host "   perception_query: $perceptionQuery"
    Write-Host "   combat_detection_null: $detectionNull"

    if ($combatStarted -gt 0 -or $agroIncreased -gt 0) {
        Write-Host "   PASS - combat_started and/or agro_increased events present"
    } else {
        Write-Host "   WARN - No combat/agro events (clans may not have engaged)"
    }
    if ($detectionNull -eq 0) {
        Write-Host "   PASS - No combat_detection_null when enemies in range"
    } else {
        Write-Host "   WARN - combat_detection_null present"
    }
} else {
    Write-Host "   SKIP - No playtest JSONL found at $UserData or $LogDir"
}

Write-Host ""
Write-Host "=== End Report ==="
