# IMP diagnose — blocking run; captures Godot console output to test_output/IMP_DIAGNOSE.log
# Uses the CONSOLE build (stdout/stderr). Use when run_imp_test.ps1 shows no game window.
# Usage: .\tools\run_imp_diagnose.ps1

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logDir = Join-Path $projectRoot "test_output\sessions\IMP_DIAG_$stamp"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$godotConsole = Join-Path $projectRoot "tools\godot\Godot_v4.6.1-stable_win64_console.exe"
if (-not (Test-Path $godotConsole)) {
    Write-Error "Console Godot required for diagnose log: $godotConsole`nDownload Godot 4.6.x console win64 and place it there."
}

$outLog = Join-Path $projectRoot "test_output\IMP_DIAGNOSE.log"
$argList = @(
    "--path", $projectRoot,
    "--quit-after", "25",
    "--",
    "--playtest-capture",
    "--playtest-log-dir", $logDir
)

Write-Host "=== IMP diagnose (blocking ~25s) ===" -ForegroundColor Cyan
Write-Host "Console log: $outLog"
Write-Host "JSONL:       $(Join-Path $logDir 'playtest_session.jsonl')"
Write-Host ""

# Godot prints WARNINGs to stderr; PowerShell would treat them as errors if Stop is active
$prevEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$env:SKIP_SINGLE_INSTANCE = "1"
try {
    & $godotConsole @argList 2>&1 | Tee-Object -FilePath $outLog
} finally {
    $ErrorActionPreference = $prevEap
    Remove-Item Env:\SKIP_SINGLE_INSTANCE -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Done. Search $outLog for ERROR / WARNING / FAILED / another instance" -ForegroundColor Green
