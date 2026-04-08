# Fails if Godot/Cursor workspace config is likely broken. Run from repo root or any cwd.
# Usage: powershell -NoProfile -File tools/verify_vscode_godot_setup.ps1
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$failed = $false

function Fail([string]$msg) {
    Write-Host "FAIL: $msg" -ForegroundColor Red
    $script:failed = $true
}

$settingsPath = Join-Path $Root ".vscode/settings.json"
if (-not (Test-Path -LiteralPath $settingsPath)) {
    Write-Host "FAIL: Missing $settingsPath" -ForegroundColor Red
    exit 1
}

$raw = Get-Content -LiteralPath $settingsPath -Raw

# godot-tools editorPath must not contain ${workspaceFolder} (extension double-joins workspace root).
if ($raw -match 'godotTools\.editorPath[^\s\x22]+\s*:\s*\x22[^\r\n]*\$\{workspaceFolder\}') {
    Fail 'godotTools.editorPath.* must not contain ${workspaceFolder} - use a path relative to the project root (see .cursor/rules/godot-vscode-integration.mdc).'
}

if ($raw -notmatch '(?s)\x22godotTools\.editorPath\.godot4\x22\s*:\s*\x22([^\x22]+)\x22') {
    Fail "Missing godotTools.editorPath.godot4 string value in .vscode/settings.json"
}
$editorRel = $Matches[1]

if ([System.IO.Path]::IsPathRooted($editorRel)) {
    Write-Host 'WARN: godotTools.editorPath.godot4 is absolute - other machines will break. Prefer tools/godot/...' -ForegroundColor Yellow
}

$exePath = Join-Path $Root ($editorRel -replace "/", [char][System.IO.Path]::DirectorySeparatorChar)
if (-not (Test-Path -LiteralPath $exePath)) {
    Write-Host "WARN: Godot exe not found (install per tools/godot/README.txt): $exePath" -ForegroundColor Yellow
}

$cmdPath = Join-Path $Root "tools/godot/godot.cmd"
$cmdRaw = Get-Content -LiteralPath $cmdPath -Raw
if ($cmdRaw.IndexOf('c:\users', [StringComparison]::OrdinalIgnoreCase) -ge 0) {
    Fail 'tools/godot/godot.cmd contains a hardcoded C:\Users\... path - use %~dp0 and bundled exe names only.'
}

Push-Location $Root
try {
    & $cmdPath --version
    if ($LASTEXITCODE -ne 0) {
        Fail "tools/godot/godot.cmd --version exited with code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

if ($failed) { exit 1 }
Write-Host 'OK: VS Code / Godot workspace checks passed.' -ForegroundColor Green
exit 0
