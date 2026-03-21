# Run Test3D with ANGLE. DISABLED - 3d folder archived.

$ProjectRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$GodotExe = Join-Path $ProjectRoot "tools\godot\Godot_v4.6.1-stable_win64_console.exe"
if (-not (Test-Path $GodotExe)) { $GodotExe = (Get-Command godot -ErrorAction SilentlyContinue).Source }

Set-Location $ProjectRoot
& $GodotExe --path "." "res://3d/Test3D.tscn" --rendering-driver opengl3_angle -- --test3d
