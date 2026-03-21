# Renderer diagnostic. DISABLED - 3d folder archived.

$ProjectRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$GodotExe = Join-Path $ProjectRoot "tools\godot\Godot_v4.6.1-stable_win64_console.exe"
if (-not (Test-Path $GodotExe)) { $GodotExe = (Get-Command godot -ErrorAction SilentlyContinue).Source }

$ScenePath = "res://3d/Test3D.tscn"
# ... rest of diagnostic logic, scene path updated
