# Run Test3D with Vulkan (Forward+). DISABLED - 3d folder archived.
# WARNING: Do NOT run this script — it modifies project.godot. Main game uses 2D only.
# Godot at tools/godot/

Write-Error "Do not run run_test3d_vulkan.ps1 — it modifies project.godot. Main game uses 2D only. See 3d/README.md."
exit 1

$ProjectRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$GodotExe = Join-Path $ProjectRoot "tools\godot\Godot_v4.6.1-stable_win64_console.exe"
if (-not (Test-Path $GodotExe)) { $GodotExe = (Get-Command godot -ErrorAction SilentlyContinue).Source }

$Backup = Join-Path $ProjectRoot "project.godot.vulkan_backup"
$Godot = Join-Path $ProjectRoot "project.godot"
if (Test-Path $Godot) {
    Copy-Item $Godot $Backup -Force
    (Get-Content $Godot -Raw) -replace 'renderer/rendering_method="[^"]*"', 'renderer/rendering_method="forward_plus"' | Set-Content $Godot -NoNewline
}
try {
    Set-Location $ProjectRoot
    & $GodotExe --path "." "res://3d/Test3D.tscn" -- --test3d
} finally {
    if (Test-Path $Backup) {
        Copy-Item $Backup $Godot -Force
        Remove-Item $Backup -Force
    }
}
