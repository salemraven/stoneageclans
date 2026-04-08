# Renames this Godot project directory from "Stone Age Clans" -> "StoneAgeClans" (no spaces in path).
#
# Close Cursor/VS Code and Godot first (they lock the folder).
#
# Run (example):
#   powershell -NoProfile -ExecutionPolicy Bypass -File "...\Stone Age Clans\tools\rename_this_folder_to_StoneAgeClans.ps1"
#
# Then reopen Cursor with the new folder path ending in \StoneAgeClans

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ParentDir = Split-Path -Parent $ProjectRoot
$Leaf = Split-Path -Leaf $ProjectRoot

if ($Leaf -eq "StoneAgeClans") {
    Write-Host "Already named StoneAgeClans: $ProjectRoot" -ForegroundColor Green
    exit 0
}

if ($Leaf -ne "Stone Age Clans") {
    Write-Error "This script expects the project folder to be named exactly 'Stone Age Clans'. Current: '$Leaf'"
    exit 1
}

if (Get-Process -Name "Godot*" -ErrorAction SilentlyContinue) {
    Write-Error "Close Godot first."
    exit 1
}

$dest = Join-Path $ParentDir "StoneAgeClans"
if (Test-Path -LiteralPath $dest) {
    Write-Error "Target already exists: $dest"
    exit 1
}

Rename-Item -LiteralPath $ProjectRoot -NewName "StoneAgeClans"
Write-Host ""
Write-Host "Done. Reopen Cursor -> Open Folder ->" -ForegroundColor Cyan
Write-Host "  $dest" -ForegroundColor White
Write-Host ""
