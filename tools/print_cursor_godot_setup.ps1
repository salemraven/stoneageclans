# One-time hints: point Godot at Cursor as external editor + verify paths.
# Run: .\tools\print_cursor_godot_setup.ps1

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Godot = Join-Path $ProjectRoot "tools\godot\Godot_v4.6.1-stable_win64.exe"

$Cursor = $null
foreach ($p in @(
    "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe",
    "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe"
)) {
    if (Test-Path -LiteralPath $p) { $Cursor = $p; break }
}

Write-Host "=== Cursor + Godot (Stone Age Clans) ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1) In Cursor: install extension 'godot-tools' (geequlim) — or accept workspace recommendation."
Write-Host "2) Workspace already sets godotTools.editorPath.godot4 -> bundled Godot 4.6.1."
Write-Host ""

if (Test-Path -LiteralPath $Godot) {
    Write-Host "Bundled Godot OK: $Godot" -ForegroundColor Green
} else {
    Write-Host "WARNING: Bundled Godot not found at: $Godot" -ForegroundColor Yellow
}

Write-Host ""
if ($Cursor) {
    Write-Host "3) In Godot Editor: Editor -> Editor Settings -> Text Editor -> External" -ForegroundColor Yellow
    Write-Host "   Enable: Use External Editor"
    Write-Host "   Executable: $Cursor"
    Write-Host "   Exec Flags: {project} --goto {file}:{line}:{col}"
    Write-Host ""
    Write-Host "4) Optional: Editor Settings -> Network -> Language Server: Editor -> Enable (default on)"
} else {
    Write-Host "Could not find Cursor.exe under LocalAppData\Programs. Install Cursor or set External Editor path manually."
}
