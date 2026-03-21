# Blender / CharMorph / SpriteForge Archive

This folder is for **archiving** deprecated Blender pipeline files — not deleting them.

## What Was Removed (March 2025)

The following were deleted before this archive existed. They were **not in git** and cannot be restored.

### Tools (were in `tools/`)
- `render_mixamo_sprite.py` — Blender script: Mixamo FBX → 8-direction renders
- `run_charmorph_pipeline.py` — CharMorph + SpriteForge pipeline runner
- `import_spriteforge_output.py` — Copy SpriteForge output to assets
- `charmorph_inspect_model.py` — Inspect CharMorph model
- `charmorph_spriteforge_render.py` — Blender render for SpriteForge
- `stitch_sprite_sheet.py` — Stitch frames into sprite sheet
- `run_full_pipeline.ps1` — Full pipeline: Blender → stitch → assets
- `charmorph_inspect.blend.import` — Godot import for Blender file
- `spriteforge_export/` — Rendered frames (dir_01, dir_02, etc.) + sprite_sheet.png
- `spriteforge_jobs/` — charmorph_idle.json, charmorph_walk.json
- `animations/` — walk.fbx (Mixamo)

### Assets (were in `assets/sprites/`)
- `charmorph_walk.png`, `charmorph_walk.json`
- `spriteforge_test_idle.png`, `spriteforge_test_idle.json`

### Docs
- `CHARMORPH_SETUP.md`
- `docs/CHARMORPH_SPRITEFORGE_EXPORT.md`

## Going Forward

**Archive, don't delete.** When deprecating tools or assets:
1. Move them here (or to `3d/` for 3D-related content)
2. Add a note in this README
3. Update any code that referenced them
