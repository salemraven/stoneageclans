# Cursor Task Prompts — Pixel Art RTS Roguelike World (Godot 4)

> Engine: Godot 4.x  
> Rendering: 2D Pixel Art  
> Scope: World systems, environment interaction, performance-safe RTS scaling  
> Instruction Style: Technical, implementation-focused, no design discussion

---

## TASK 01 — Project Pixel Configuration

**Prompt:**
Configure a Godot 4 project for pixel-perfect 2D rendering.
- Set texture filtering to Nearest
- Enable pixel snapping for 2D transforms and vertices
- Configure window stretch mode for pixel art
- Document required ProjectSettings changes in comments

Output: Checklist + confirmation comments in code where applicable.

---

## TASK 02 — World Scene Architecture

**Prompt:**
Create a Godot 4 `World.tscn` scene using Node2D with the following hierarchy:

World (Node2D)
- GroundTileMap
- GrassLayer (Node2D)
- PropsLayer (Node2D)
- UnitsLayer (Node2D)
- EffectsLayer (Node2D)
- ChunkManager
- InteractionManager

Ensure rendering order matches node order.
Do not include gameplay logic yet.

---

## TASK 03 — Ground TileMap Setup

**Prompt:**
Configure a TileMap node for static ground tiles only.
- No animation
- No interaction
- No state per tile
- Assume tiles are assigned procedurally

Include comments explaining what must NOT be placed in TileMap.

---

## TASK 04 — Grass Resource Definition

**Prompt:**
Create a Godot 4 Resource script named `GrassType.gd` with:
- Texture2D reference
- Sway strength
- Bend strength
- Recovery time
- Density value

Use exported variables.
Include documentation comments explaining how this resource is used in world generation.

---

## TASK 05 — GrassPatch Scene

**Prompt:**
Create a `GrassPatch.tscn` scene with:
- Node2D root
- Sprite2D for visuals
- Area2D for interaction
- CollisionShape2D sized to sprite

Add a script `GrassPatch.gd` with:
- Wind offset
- Impulse offset
- Impulse decay logic
- No per-frame collision polling

Do not implement shader yet.

---

## TASK 06 — Grass Wind Shader (Pixel-Safe)

**Prompt:**
Write a Godot 4 CanvasItem shader for grass sway:
- Horizontal sine-based movement
- Anchored at bottom pixels
- Quantized movement for pixel snapping
- Global uniforms for wind strength, direction, and time

Shader must be reusable across all grass instances.

---

## TASK 07 — Grass Interaction System

**Prompt:**
Implement an event-driven grass interaction system:
- NPCs emit a `grass_impulse(world_position, strength)` signal
- Grass patches respond only when overlapping
- Impulse temporarily overrides wind sway
- Impulse smoothly decays back to wind motion

Do NOT use per-frame overlap checks.

---

## TASK 08 — NPC Grass Interactor

**Prompt:**
Extend NPC scenes with:
- Area2D named `GrassInteractor`
- Signal emission on movement
- Adjustable impulse strength

NPCs should have no knowledge of grass internals.

---

## TASK 09 — Tree Scene Structure

**Prompt:**
Create a `Tree.tscn` scene with:
- Static trunk Sprite2D
- Animated canopy Sprite2D
- Area2D for interaction
- CollisionShape2D for trunk only

Ensure canopy renders above units.

---

## TASK 10 — Tree Animation Logic

**Prompt:**
Implement tree animation:
- Subtle wind sway (shader or transform-based)
- Short gust animation loop
- On interaction:
  - Shake canopy
  - Emit leaf particles (placeholder)

No physics simulation.

---

## TASK 11 — Chunk System

**Prompt:**
Design a chunk-based world system:
- Chunk size: 16×16 tiles
- Chunk tracks grass patches and trees
- Only chunks near camera process interactions
- Distant chunks remain visual-only

Implement `ChunkManager.gd`.

---

## TASK 12 — Interaction Manager

**Prompt:**
Create an `InteractionManager` that:
- Routes NPC signals to nearby grass and trees
- Uses chunk data for spatial filtering
- Avoids global searches

Event-driven only.

---

## TASK 13 — Deterministic World Generation

**Prompt:**
Implement a deterministic world generation pipeline:
1. Seed initialization
2. Biome map
3. Ground tile placement
4. Grass placement using GrassType
5. Tree placement
6. NPC spawning

All randomness must come from a single seeded RNG.

---

## TASK 14 — Rendering Order & Y-Sorting

**Prompt:**
Configure rendering rules:
- Grass renders below units
- Units Y-sort against props
- Tree canopies render above units
- Effects render above all

Document layer rules in comments.

---

## TASK 15 — RTS Scale Performance Pass

**Prompt:**
Refactor systems to support high NPC counts:
- No per-frame overlap scanning
- No per-grass update outside active chunks
- Shader-driven wind only for distant grass

Add comments explaining performance assumptions.

---

## TASK 16 — Minimal Viable World Test

**Prompt:**
Assemble a minimal test scene:
- Flat grass TileMap
- Wind-animated grass
- One NPC walking through grass
- One animated tree

Verify:
- Pixel stability
- Grass bends correctly
- No jitter or blur

---

## END GOAL

A flat pixel-art world with:
- Reactive grass
- Animated trees
- Deterministic generation
- RTS-scale performance
- Roguelike replayability

DAY NIGHT CYCLE

You DO want:
✅ A global sun direction
✅ A time-driven shadow offset
✅ Pre-authored shadow sprites
✅ Batched rendering

This is how pixel games ship.

1. Day–Night Cycle (time system)

Create a global TimeOfDay system:

Time ∈ [0.0, 1.0]
0.25 = Morning
0.50 = Noon
0.75 = Evening


Sun movement:

Morning → sun from RIGHT

Noon → overhead (short shadows)

Evening → sun from LEFT

This value drives:

Shadow direction

Shadow length

Color grading

Ambient darkness

2. Sun direction (screen-space, not world-space)

Because the world is flat, the sun is conceptual, not physical.

Define:

sun_direction = lerp(Vector2(1, 0), Vector2(-1, 0), time_of_day)


Also define:

shadow_length = curve.sample(time_of_day)


Use a Curve resource so shadows are:

Long in morning/evening

Short at noon

3. Shadow sprites (THIS is the key trick)

Every sprite that can cast a shadow gets:

A shadow version of its sprite

Usually solid black or dark blue

Slightly squashed vertically

Example:

Unit (Node2D)
├── Sprite2D
├── ShadowSprite2D


Shadow sprite:

Same texture OR pre-flattened version

modulate = Color(0,0,0,0.4)

Z-index below the unit

This is exactly how classic pixel games do it.

4. Moving shadows with the sun

Every frame (or on time tick):

shadow_sprite.position =
    sun_direction * shadow_length


Optional:

Quantize to pixel grid

Clamp max distance

Reduce alpha at noon

This gives:
🌅 Long shadows in morning
☀️ Short shadows at noon
🌇 Long shadows reversed in evening

5. Trees and tall objects (extra polish)

Trees benefit the most from this.

Tree setup:

Tree (Node2D)
├── TrunkSprite
├── CanopySprite
├── ShadowSprite (based on canopy)


Shadow:

Uses canopy shape

Offset more than units

Slightly blurred (or dithered pixels)

Optional:

Animate shadow wobble slightly in wind

6. Grass shadows (cheap version)

Do NOT give every grass blade a shadow.

Instead:

Darken the ground texture slightly based on sun angle

Or add a directional gradient overlay

This avoids millions of shadow sprites.

7. Night lighting (pixel-safe)

At night:

Lower ambient light

Apply a full-screen color rect:

Dark blue / purple

Multiply blend

Increase shadow softness

You can also:

Slightly reduce contrast

Shift palette cooler

No dynamic lights required.

8. RTS performance considerations

This approach scales because:

Shadow sprites are just Sprite2D

No lighting calculations

No raycasting

No shadow maps

For many NPCs:

Update shadows only when time changes

Or quantize updates to time steps (every few seconds)

9. Godot 4 implementation details

Use:

CanvasLayer for night overlay

Curve resources for shadow length & brightness

Shared script for shadow logic

Avoid:

Light2D + shadow mode

Normal maps

Per-pixel lighting

10. What this will look like (realistic expectation)

Visually:

Very close to Stoneshard / classic tactics RPGs

Clean pixel silhouettes

Strong sense of time passing

Zero lighting artifacts

Players will read it as real sunlight, even though it’s fake.

Summary (direct answer)

✅ Yes, you can have a day–night cycle
✅ Yes, the sun can move right → left
✅ Yes, sprites can cast moving shadows
✅ It works in pixel art
✅ It scales to RTS NPC counts

You fake the sun.
You fake the shadows.
And it looks right.

If you want next, I can: