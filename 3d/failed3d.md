# Failed 3D Attempt — Post-Mortem

**Date:** March 2025  
**Status:** Abandoned. Reverted to 2D sprites.  
**Hardware:** NVIDIA RTX 5070, Godot 4.6.1

---

## 1. What We Tried to Do

We attempted to create a **Test3D** scene: a minimal 3D environment where a character could move and render correctly. The goal was to validate real-time 3D rendering in Godot before attempting a larger 3D character refactor.

**Scope:** Ground plane, directional light, orthographic camera, CharacterBody3D with a placeholder cube (later: YBot/Mixamo model), WASD movement.

---

## 2. What Happened (Timeline)

### Phase 1: Black Screen
- **Symptom:** Test3D showed a black screen. Main (2D) worked.
- **Actions:** Added instrumentation, logging, render diagnostics (green bar, "Test3D OK" label).
- **Findings:** Logs showed camera, ground, player, light all valid. Overlap checks passed. Scene logic was correct.

### Phase 2: Grey Screen
- **Symptom:** Switched to Compatibility renderer. Screen turned grey — background visible, 3D meshes not.
- **Actions:** Brightened clear color, Environment background, added StandardMaterial3D (unshaded, double-sided), yellow marker cube, stronger lights.
- **Findings:** Green bar visible → viewport renders. Grey = Environment background only. 3D meshes (ground, cube, player) did not render on Compatibility.

### Phase 3: Vulkan
- **Symptom:** With Forward+ (Vulkan), Test3D showed black screen with a brown bar at the bottom.
- **Findings:** Brown bar = ground plane (partially visible). Rest = black. Environment background not showing.

### Phase 4: SubViewport + Transparent
- **Symptom:** Restructured Test3D: Control root, ColorRect background, SubViewport for 3D.
- **Actions:** Ensured light grey background always visible. 3D in SubViewport with transparent render target.
- **Findings:** Partial success — background visible. 3D still unreliable.

### Phase 5: Scene Missing
- **Symptom:** `ERROR: Cannot open file 'res://scenes/Test3D.tscn'`
- **Cause:** Test3D.tscn had been deleted or never committed.
- **Actions:** Recreated Test3D from scratch (minimal scene: ground, cube, player, camera, light).

### Phase 6: Controls Backwards
- **Symptom:** WASD movement felt inverted.
- **Actions:** Swapped get_axis arguments to reverse directions.

### Phase 7: Abandonment
- **Decision:** 3D is a total failure. Revert to 2D. Organize 3D artifacts into `3d/` and disable.

---

## 3. Root Causes (Best Guess)

1. **Driver / Renderer Incompatibility**
   - RTX 5070 is very new. Godot 4.6 Compatibility (OpenGL) and Forward+ (Vulkan) both had issues.
   - Compatibility: 3D meshes not visible (grey screen).
   - Vulkan: black background, only ground strip visible.
   - ANGLE (DirectX-backed OpenGL) was suggested but not fully validated.

2. **Environment / Clear Color Override**
   - Project `default_clear_color` is dark (0.06, 0.08, 0.09).
   - WorldEnvironment in scene had bright background_color, but it may not have overridden correctly.
   - Possible Godot bug or misconfiguration.

3. **Scope Creep**
   - We spent effort on logging, diagnostics, renderer switching, SubViewport hacks.
   - Never reached the actual goal: a visible, controllable 3D character.

---

## 4. What We Built (Artifacts — now in 3d/)

| File | Purpose |
|------|---------|
| `3d/Test3D.tscn` | Root: Control + ColorRect + SubViewportContainer |
| `3d/test3d_world.tscn` | 3D content: Ground, MarkerCube, TestPlayer, Camera, Light |
| `3d/test_player_3d.gd` | WASD movement for CharacterBody3D |
| `3d/run_test3d_vulkan.ps1` | Run Test3D with Forward+ |
| `3d/run_test3d_angle.ps1` | Run Test3D with ANGLE driver |
| `3d/run_renderer_diagnostic.ps1` | Interactive renderer comparison |
| `3d/test3d_run.log` | Old run output (YBot=false, Placeholder=true) |

**project.godot:** `renderer/rendering_method` removed — using Godot default.

---

## 5. The 3D Character Refactor Plan (Never Started)

We never got past step 1. Here is the intended plan:

### Step 1: Basic 3D Scene Renders ✅ (Attempted) / ❌ (Failed)
- [ ] Test3D scene loads
- [ ] Ground, light, camera visible
- [ ] CharacterBody3D with placeholder cube visible
- [ ] WASD movement works

### Step 2: Replace Placeholder with YBot/Mixamo
- [ ] Use `assets/characters/walk.fbx` (Mixamo walk animation, already imported)
- [ ] Or `assets/characters/idle.fbx`, `bayonet_stab.fbx` for other actions
- [ ] Add as child of CharacterModel, replace Placeholder
- [ ] Verify mesh renders with correct scale/orientation

### Step 3: Animations
- [ ] Import walk animation from FBX
- [ ] AnimationPlayer or AnimationTree for walk/idle
- [ ] Sync direction with velocity (face movement direction)

### Step 4: Integration with Main Game (Optional)
- [ ] Decide: 3D view for main game, or Test3D only for dev/test
- [ ] If main: SubViewport or scene switch for 3D mode
- [ ] NPCs: same CharacterModel + AnimationPlayer pattern

### Step 5: Sprite Fallback
- [ ] Keep 2D sprite pipeline (CharMorph → SpriteForge → 2D) as primary
- [ ] 3D as optional / future / experimental

---

## 6. Lessons Learned

1. **Validate rendering first.** Don't assume 3D will work. A minimal test scene (ground + cube) should render before any character work.
2. **New GPU drivers.** RTX 50 series may have compatibility issues with Godot. Test on multiple machines or wait for driver updates.
3. **Stick to what works.** The project's 2D sprite pipeline works. 3D real-time was a distraction.
4. **Incremental scope.** We tried to fix rendering with logging, diagnostics, SubViewports. The core issue (driver/renderer) was never resolved.

---

## 7. If We Return to 3D

1. **Try ANGLE.** `--rendering-driver opengl3_angle` may work better on RTX 50 series.
2. **Try older Godot.** 4.4 or 4.3 might have different driver behavior.
3. **Try different GPU.** Test on integrated or older NVIDIA.
4. **Pre-rendered 3D.** A 3D→2D pipeline (render frames in external tool → 2D sprites) could work. Real-time 3D in Godot is optional.

---

## 8. References

- [bible.md](../bible.md) — Art direction: 64×64 pixel art, top-down isometric
- [rig.md](../guides/Phase4/rig.md) — Transform-based modular rig (2D, not 3D)
- Godot issues: #95804 (3D black screen), #96943 (Compatibility glitches)
