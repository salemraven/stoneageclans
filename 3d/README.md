# 3D (DISABLED)

**WARNING: Do not run `run_test3d_vulkan.ps1` — it modifies project.godot. Main game uses 2D only.**

This folder contains the abandoned Test3D attempt. **3D real-time rendering failed** on our setup (RTX 5070, Godot 4.6). The project runs **2D sprites only**.

**Main game:** `res://scenes/Main.tscn`

## Contents

- `Test3D.tscn`, `test3d_world.tscn`, `test_player_3d.gd` — Test3D scene (archived)
- `run_test3d_*.ps1`, `run_renderer_diagnostic.ps1` — Run scripts (archived)
- `failed3d.md` — Full post-mortem and 3D character refactor plan
- `test3d_run.log` — Old run output

## To re-enable (if rendering ever works)

1. Run `res://3d/Test3D.tscn` from Godot or:  
   `godot --path . res://3d/Test3D.tscn`
2. See `failed3d.md` for the full plan we never completed.
