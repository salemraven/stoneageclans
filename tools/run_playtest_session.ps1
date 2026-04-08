# Launch Stone Age Clans with PlaytestInstrumentor writing to test_output/sessions/<timestamp>/
# Usage: .\tools\run_playtest_session.ps1
# Godot user args must come after -- so instrumentor sees --playtest-capture and --playtest-log-dir

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = Join-Path $projectRoot "test_output\sessions\$stamp"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$pointerFile = Join-Path $projectRoot "test_output\LATEST_SESSION.txt"
@"
$logDir
playtest_session.jsonl
"@ | Set-Content -Path $pointerFile -Encoding UTF8

$godotGui = Join-Path $projectRoot "tools\godot\Godot_v4.6.1-stable_win64.exe"
$godotConsole = Join-Path $projectRoot "tools\godot\Godot_v4.6.1-stable_win64_console.exe"
$godot = Join-Path $projectRoot "tools\godot\godot.cmd"
$useExe = $null
if (Test-Path $godotGui) { $useExe = $godotGui }
elseif (Test-Path $godotConsole) { $useExe = $godotConsole }
elseif (-not (Test-Path $godot)) {
    Write-Error "Godot not found (exe or godot.cmd) under tools\godot\"
}

Write-Host "Session log dir: $logDir"
Write-Host "Pointer written: $pointerFile"
Write-Host "Starting game (close window when done; keep this path for bug reports)."
Write-Host ""

# User args after -- (required for PlaytestInstrumentor._ready user-args parsing)
# Bypass single-instance lock so this can run alongside editor Play / another IMP.
$prevSkip = $env:SKIP_SINGLE_INSTANCE
$env:SKIP_SINGLE_INSTANCE = "1"
try {
    if ($useExe) {
        & $useExe --path $projectRoot -- --playtest-capture --playtest-log-dir $logDir
    } else {
        & $godot --path $projectRoot -- --playtest-capture --playtest-log-dir $logDir
    }
} finally {
    if ($null -eq $prevSkip) { Remove-Item Env:\SKIP_SINGLE_INSTANCE -ErrorAction SilentlyContinue }
    else { $env:SKIP_SINGLE_INSTANCE = $prevSkip }
}
