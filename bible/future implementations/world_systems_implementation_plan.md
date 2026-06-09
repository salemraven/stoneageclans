# World Systems Implementation Plan

## Overview
This plan integrates the world systems described in `newworld.md` into the existing StoneAgeClans game. The implementation will use Godot 4 resources (shaders, particles, curves) where possible to minimize hand-drawn art while maintaining the pixel art style and color scheme.

## Current State Analysis

### Existing Systems
- ✅ Basic TileMap world system (`scripts/world.gd`)
- ✅ Chunk-based generation (32×32 tiles per chunk)
- ✅ Y-sorting utilities (`scripts/systems/y_sort_utils.gd`)
- ✅ Pixel art rendering (texture_filter=0)
- ✅ Scene structure: Main → World, Player, Resources, LandClaims, UI
- ✅ Assets: grass tiles (grass1-4.png), tree sprite (tree1.png)

### What Needs to Be Added
- Grass system with wind animation and NPC interaction
- Tree scenes with wind animation and shadows
- Day-night cycle with moving shadows
- Proper layer hierarchy for rendering order
- Interaction manager for world-NPC communication
- Enhanced chunk system for grass/tree placement

## Implementation Strategy

### Phase 1: Foundation & Configuration

#### 1.1 Pixel-Perfect Configuration
**File:** `project.godot`
- ✅ Already has `texture_filter=0` (nearest filtering)
- Add pixel snapping settings:
  - `rendering/2d/snap/snap_2d_transforms_to_pixel=true`
  - `rendering/2d/snap/snap_2d_vertices_to_pixel=true`
- Ensure window stretch mode supports pixel art (already configured)

#### 1.2 World Scene Restructure
**File:** `scenes/Main.tscn`
**Current structure:**
```
Main (Node2D)
├── World (TileMap)
├── Player
├── Resources
├── LandClaims
├── WorldArea
└── UI (CanvasLayer)
```

**New structure:**
```
Main (Node2D)
├── GroundTileMap (TileMap) - existing World, renamed
├── GrassLayer (Node2D) - NEW: contains grass patches
├── PropsLayer (Node2D) - NEW: trees, static props
├── UnitsLayer (Node2D) - NEW: Player, NPCs (moved from root)
├── EffectsLayer (Node2D) - NEW: particles, visual effects
├── ChunkManager (Node) - NEW: manages grass/tree placement
├── InteractionManager (Node) - NEW: routes NPC signals
├── TimeOfDayManager (Node) - NEW: day-night cycle
├── Resources (Node2D) - keep existing
├── LandClaims (Node2D) - keep existing
├── WorldArea (Area2D) - keep existing
└── UI (CanvasLayer) - keep existing
```

**Z-index layers:**
- GroundTileMap: z_index = 0 (base)
- GrassLayer: z_index = 100 (below units)
- PropsLayer: z_index = 200 (trees, sorted by Y)
- UnitsLayer: z_index = 1000+ (Y-sorted via YSortUtils)
- EffectsLayer: z_index = 3000+ (above all)

### Phase 2: Grass System

#### 2.1 GrassType Resource
**File:** `scripts/world/grass_type.gd`
```gdscript
extends Resource
class_name GrassType

@export var texture: Texture2D
@export var sway_strength: float = 2.0
@export var bend_strength: float = 1.5
@export var recovery_time: float = 0.5
@export var density: float = 0.7  # 0.0-1.0, affects placement frequency
```

**Usage:** Create `.tres` resource files for different grass types. Can use existing grass textures or generate simple pixel art variants.

#### 2.2 GrassPatch Scene
**File:** `scenes/world/GrassPatch.tscn`
**Structure:**
```
GrassPatch (Node2D)
├── Sprite2D (texture from GrassType - represents 3-7 blade cluster)
├── Area2D
│   └── CollisionShape2D
└── (ShaderMaterial for wind animation)
```

**File:** `scripts/world/grass_patch.gd`
- Wind offset (from global wind shader uniform)
- Impulse offset (from NPC interaction)
- Impulse decay logic
- Event-driven interaction (no per-frame polling)

**Important:** GrassPatch represents a small cluster (3-7 blades), not a single blade. Density controls spacing between patches, not total blades. This keeps node count down and interaction costs sane.

#### 2.3 Grass Wind Shader
**File:** `shaders/grass_wind.gdshader`
- Pixel-safe horizontal sine movement
- Anchored at bottom pixels
- Quantized movement for pixel snapping
- Global uniforms: `wind_strength`, `wind_direction`, `wind_time`
- Reusable across all grass instances

**Godot Resource:** Uses built-in shader system, no hand-drawn animation needed.

#### 2.4 Grass Placement System
**Integration:** Extend `scripts/world.gd` or create `scripts/world/grass_placer.gd`
- Use existing chunk system
- Place grass patches based on GrassType density
- Use seeded RNG for deterministic placement
- Store grass patches in ChunkManager

### Phase 3: Tree System

#### 3.1 Tree Scene
**File:** `scenes/world/Tree.tscn`
**Structure:**
```
Tree (Node2D)
├── TrunkSprite (Sprite2D) - static
├── CanopySprite (Sprite2D) - animated
├── ShadowSprite (Sprite2D) - for day-night shadows
└── Area2D
    └── CollisionShape2D (trunk only)
```

**File:** `scripts/world/tree.gd`
- Subtle wind sway (shader or transform-based)
- Short gust animation loop
- On interaction: shake canopy, emit leaf particles
- Shadow position updates based on TimeOfDay

**Art:** Use existing `tree1.png` or create simple pixel art variants. Can use Godot's Sprite2D with modulate for color variations.

#### 3.2 Tree Animation
- Wind sway: **Transform-based** (not shader) - simpler debugging, trunk stability
- Gust animation: Use AnimationPlayer with 2-3 frame loop
- Leaf particles: Use Godot's GPUParticles2D with simple pixel sprites

**Rationale:** Transform-based sway is easier to debug, keeps trunk stable, and avoids shader mistakes on tall sprites. Can unify to shader later if needed.

### Phase 4: Chunk & Interaction Systems

#### 4.1 Enhanced ChunkManager
**File:** `scripts/world/chunk_manager.gd`
**Extends existing chunk system:**
- Track grass patches per chunk
- Track trees per chunk
- Only process interactions for chunks near camera
- Distant chunks: visual-only (shader wind only)

**Important:** 
- **Tile chunk is the authority** - all chunk math derives from tile chunks
- Derive world AABBs from tile bounds: `world_rect = tile_pos * TILE_SIZE`
- Grass and props register with chunks by world position
- Chunk handles spatial filtering using world-space AABBs

**Integration:** Extends existing `world.gd` chunk system. Converts tile chunk coords to world rects for grass/tree placement. No parallel chunk system.

#### 4.2 InteractionManager
**File:** `scripts/world/interaction_manager.gd`
- Routes NPC signals to nearby grass/trees
- Uses chunk data for spatial filtering
- Event-driven only (no global searches)
- Listens for `grass_impulse(world_position, strength)` signals

### Phase 5: Day-Night Cycle

#### 5.1 TimeOfDayManager
**File:** `scripts/world/time_of_day_manager.gd`
**Autoload:** Add to `project.godot` autoloads

**Features:**
- Time value: 0.0 (midnight) to 1.0 (next midnight)
- 0.25 = Morning, 0.50 = Noon, 0.75 = Evening
- Sun direction: `lerp(Vector2(1, 0), Vector2(-1, 0), time_of_day)`
- Shadow length: Uses Curve resource (long in morning/evening, short at noon)
- **Strict signal-driven:** Emits `time_changed(time_value)`, `sun_changed(direction, length)`, `ambient_changed(brightness)`
- **Consumers cache values** - no per-frame queries allowed

**Time progression:**
- **Base mode:** Automatic advancement at fixed rate (tied to game speed)
- **Modifiers:**
  - Pause on menus
  - Slow during combat
  - Accelerate during travel
  - Hard stop during certain events
- **Player influence:** Rest/sleep → fast-forward, camps → skip night
- **System remains automatic** - player influences speed, doesn't control directly

**Godot Resources:**
- Curve resource for shadow length
- Curve resource for ambient brightness
- Curve resource for color grading

**Time quantization:** Updates occur at discrete ticks (96 ticks per day = shadow updates every 15 in-game minutes). This avoids micro-jitter and maintains pixel stability.

#### 5.2 Shadow System
**File:** `scripts/world/shadow_component.gd`
**Reusable component for units, trees, buildings**

**Implementation:**
- Shadow sprite: Same texture with `modulate = Color(0, 0, 0, 0.4)`
- Position: `sun_direction * shadow_length` (from TimeOfDayManager)
- Quantized to pixel grid
- Alpha reduces at noon
- Z-index: **Always** Z_GROUND_DECAL_BASE (shadows NEVER participate in Y-sort)
- Updates only on TimeOfDayManager signals (quantized time ticks)

**Critical:** Shadows must NEVER participate in Y-sorting. They always sit in the ground-decal band. Otherwise tall units will cast shadows over things they shouldn't.

---

## Key Implementation Decisions ✅

### Chunk Coordinate System
- **Tile chunk is the authority** - derive world AABBs from tile bounds
- Formula: `world_rect = tile_pos * TILE_SIZE`
- Grass/trees register by world position, chunk handles spatial filtering
- **No parallel chunk systems** - prevents desync

### Grass Density System
- **Biome-based × per-chunk modifier** (NOT global, NOT purely per-chunk)
- Hierarchy: Biome base → Chunk modifier → Local randomness
- Maintains biome identity and consistency

### Time Progression
- **Automatic + event-driven modifiers** (NOT player-controlled)
- Base: Fixed rate tied to game speed
- Modifiers: Pause on menus, slow during combat, accelerate during travel
- Player can influence (rest/sleep fast-forward) but system remains automatic

### Grass Clusters
- **Single sprite with multiple blades** (3-7 blades per GrassPatch)
- Density controls spacing between patches, not total blades
- Keeps node count down and interaction costs sane

### Shadow Updates
- **96 ticks per day** = updates every 15 in-game minutes
- Quantized to avoid micro-jitter and maintain pixel stability

### Tree Animation
- **Transform-based sway** (not shader) - simpler debugging, trunk stability

---

## Questions for Clarification

Before implementation, need to confirm:

### 1. Grass Cluster Implementation ✅ DECIDED
**Answer:** Single sprite with multiple blades (3-7 blades per GrassPatch)

**Implementation:**
- Create cluster textures programmatically or use existing grass tiles as base
- One sprite per cluster, not MultiMeshInstance2D
- Simpler and better performance

### 2. Shadow Update Frequency ✅ DECIDED
**Answer:** Fixed 96 ticks/day (configurable constant)

**Implementation:**
- Start with fixed 96 ticks/day
- Can make configurable later if needed
- Each tick = 15 in-game minutes

### 3. Tree Transform Sway ✅ DECIDED
**Answer:** Small rotation around base (pivot at trunk bottom)

**Implementation:**
- Rotate around base point (pivot at bottom)
- Looks natural, easy to debug
- Trunk remains stable

### 4. Chunk Coordinate System ✅ DECIDED
**Answer:** Convert existing tile chunks to world space. **Do NOT create a parallel system.**

**Implementation:**
- **Tile chunk is the authority** (32×32 tiles = 2048×2048 pixels)
- Derive world AABBs from tile bounds: `world_rect = tile_pos * TILE_SIZE`
- Grass, trees, NPCs register with chunk by world position
- Chunk handles spatial filtering

**Why:** Parallel chunk systems always desync. This keeps save/load simple, debugging sane, and worldgen deterministic.

**Code example:**
```gdscript
# In ChunkManager
# Tile chunk is authority - derive world rects from tile chunks
func get_world_rect_from_tile_chunk(tile_chunk_coord: Vector2i) -> Rect2:
    var tile_pos = tile_chunk_coord * CHUNK_SIZE
    var world_pos = Vector2(tile_pos.x * TILE_SIZE, tile_pos.y * TILE_SIZE)
    var world_size = Vector2(CHUNK_SIZE * TILE_SIZE, CHUNK_SIZE * TILE_SIZE)
    return Rect2(world_pos, world_size)

# Register grass/tree by world position - chunk handles spatial filtering
func get_tile_chunk_from_world_pos(world_pos: Vector2) -> Vector2i:
    var tile_pos = Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))
    return Vector2i(
        int(floor(float(tile_pos.x) / float(CHUNK_SIZE))),
        int(floor(float(tile_pos.y) / float(CHUNK_SIZE)))
    )
```

### 5. Grass Density Placement ✅ DECIDED
**Answer:** Biome-based × per-chunk modifier (NOT global, NOT purely per-chunk)

**Correct hierarchy:**
1. **Biome base density** (forest > plains > tundra) - sets the baseline
2. **Chunk modifier** (roads, camps, ruins reduce density) - tweaks per chunk
3. **Local randomness** (seeded) - final variation

**Why NOT global:** Global density kills biome identity and tactical readability.

**Why NOT purely per-chunk:** You'll lose consistency across large areas.

**Implementation:**
- Biome system defines base density per biome type
- Chunk modifier applied based on chunk features (buildings, paths, etc.)
- Seeded RNG for final placement variation within chunk

### 6. Time Progression ✅ DECIDED
**Answer:** Automatic + event-driven modifiers (NOT player-driven by default)

**Base mode:**
- Time advances automatically
- Fixed rate tied to game speed

**Modifiers:**
- Pause on menus
- Slow during combat
- Accelerate during travel
- Hard stop during certain events

**Why NOT player-controlled:**
- Breaks simulation assumptions
- Complicates AI schedules
- Weakens day/night meaning

**Allowed player actions:**
- Rest / sleep → fast-forward
- Camps → skip night

**But the system remains automatic** - player can influence speed, not control it directly.

**Integration:**
- Add ShadowSprite2D child to Player, NPCs, Trees, Buildings
- Update shadow position only when `sun_changed` signal fires (not in _process)

#### 5.3 Night Lighting
**File:** `scenes/world/NightOverlay.tscn`
- CanvasLayer with ColorRect
- Dark blue/purple with multiply blend
- Alpha controlled by TimeOfDayManager curve
- Full-screen overlay

### Phase 6: Deterministic World Generation

#### 6.1 Enhanced World Generation
**File:** `scripts/world/world_generator.gd`
**Pipeline:**
1. Seed initialization (from game seed)
2. Biome map (using FastNoiseLite)
3. Ground tile placement (existing system)
4. Grass placement (using GrassType resources + biome density system)
5. Tree placement (using density rules)
6. NPC spawning (existing system)

**Grass density system:**
- **Biome base density:** Forest > plains > tundra (sets baseline)
- **Chunk modifier:** Roads, camps, ruins reduce density (tweaks per chunk)
- **Local randomness:** Seeded RNG for final variation within chunk
- **NOT global** - maintains biome identity and tactical readability
- **NOT purely per-chunk** - maintains consistency across large areas

**All randomness from single seeded RNG** for roguelike replayability.

### Phase 7: NPC Integration

#### 7.1 NPC Grass Interactor
**File:** `scripts/npc/grass_interactor.gd` (component)
**Add to NPC scenes:**
- Area2D named `GrassInteractor`
- Emits `grass_impulse(world_position, strength)` on movement
- Adjustable impulse strength
- NPCs have no knowledge of grass internals (decoupled)

## Godot Resources to Use

### Shaders (No Art Needed)
- ✅ Grass wind shader (`shaders/grass_wind.gdshader`)
- ✅ Tree wind shader (`shaders/tree_wind.gdshader`)
- ✅ Simple pixel-safe effects

### Particles (Minimal Art)
- ✅ Leaf particles: Use simple pixel sprites (2-3 frames)
- ✅ Can generate programmatically or use Godot's built-in particle shapes

### Curves (No Art)
- ✅ Shadow length curve
- ✅ Ambient brightness curve
- ✅ Color grading curve

### Sprites (Use Existing + Simple Variants)
- ✅ Grass: Use existing grass tiles or create simple variants
- ✅ Trees: Use existing `tree1.png` or create variants with modulate
- ✅ Shadows: Generate from existing sprites (modulate + position)

## Color Scheme & Pixel Art Style

### Current Style
- Pixel art with nearest filtering
- 64×64 tile size
- Existing grass tiles: green variants
- Existing sprites: stone age theme

### Guidelines for New Assets
1. **Grass variants:** Use existing grass tile colors, create simple swaying grass sprites
2. **Tree variants:** Use modulate to create color variations from base tree sprite
3. **Shadows:** Black/dark blue with alpha, no new art needed
4. **Particles:** Simple 2-3 pixel sprites, can be programmatically generated

## Implementation Order

### Week 1: Foundation
1. ✅ Pixel-perfect configuration
2. ✅ World scene restructure
3. ✅ GrassType resource
4. ✅ Basic GrassPatch scene (no shader yet)

### Week 2: Grass System
5. ✅ Grass wind shader
6. ✅ Grass interaction system
7. ✅ Grass placement in chunks
8. ✅ NPC grass interactor

### Week 3: Trees & Shadows
9. ✅ Tree scene with animation
10. ✅ TimeOfDayManager
11. ✅ Shadow system component
12. ✅ Shadow integration (Player, NPCs, Trees)

### Week 4: Polish & Integration
13. ✅ ChunkManager enhancement
14. ✅ InteractionManager
15. ✅ Deterministic world generation
16. ✅ Night lighting overlay
17. ✅ Testing & optimization

## Performance Considerations

### RTS-Scale Optimizations
- ✅ No per-frame overlap scanning (event-driven only)
- ✅ No per-grass update outside active chunks
- ✅ Shader-driven wind for distant grass (no CPU updates)
- ✅ Shadow updates only on time change (signal-driven)
- ✅ Chunk-based culling for interactions

### Expected Performance
- 100+ NPCs: Should run smoothly with chunk-based culling
- 1000+ grass patches: Shader-only updates for distant patches
- Day-night cycle: Minimal overhead (signal-driven updates)

## Testing Checklist

- [ ] Grass sways with wind shader
- [ ] Grass bends when NPC walks through
- [ ] Trees animate with wind
- [ ] Shadows move with sun direction
- [ ] Shadows are correct length at different times
- [ ] Night overlay appears at night
- [ ] World generation is deterministic (same seed = same world)
- [ ] Chunk system loads/unloads correctly
- [ ] Performance is acceptable with many NPCs
- [ ] Pixel art remains crisp (no blur)
- [ ] Y-sorting works with new layers
- [ ] No z-fighting or rendering issues

## Files to Create

### Scripts
- `scripts/world/grass_type.gd`
- `scripts/world/grass_patch.gd`
- `scripts/world/tree.gd`
- `scripts/world/chunk_manager.gd`
- `scripts/world/interaction_manager.gd`
- `scripts/world/time_of_day_manager.gd`
- `scripts/world/shadow_component.gd`
- `scripts/world/world_generator.gd`
- `scripts/npc/grass_interactor.gd`

### Scenes
- `scenes/world/GrassPatch.tscn`
- `scenes/world/Tree.tscn`
- `scenes/world/NightOverlay.tscn`

### Shaders
- `shaders/grass_wind.gdshader`
- `shaders/tree_wind.gdshader`

### Resources
- `resources/grass_types/grass_common.tres`
- `resources/grass_types/grass_dense.tres`
- `resources/curves/shadow_length_curve.tres`
- `resources/curves/ambient_brightness_curve.tres`

## Integration Points

### Existing Systems to Extend
- `scripts/world.gd`: Add grass/tree placement
- `scripts/main.gd`: Initialize new managers
- `scenes/Main.tscn`: Restructure with new layers
- `scripts/systems/y_sort_utils.gd`: Add shadow z-index constants
- NPC scripts: Add grass interactor component

### New Autoloads
- `TimeOfDayManager` (for global time access, read-only state)

### System Ownership & Dependencies
**Clear separation of concerns (prevents circular dependencies):**
- **WorldGenerator** → builds data (one-time generation)
- **ChunkManager** → spatial authority (tracks what's where)
- **InteractionManager** → routing only (no state, just signal routing)
- **TimeOfDayManager** → read-only state (emits signals, no queries)

**Rule:** Write ownership into comments early. No circular dependencies.

## Notes

- All shaders will be pixel-safe (quantized movement)
- All art will use existing color schemes or simple variants
- Godot resources minimize hand-drawn art requirements
- System is designed to scale to RTS-level NPC counts
- Deterministic generation supports roguelike replayability

Where I would adjust or clarify ⚠️

These aren’t deal-breakers — they’re refinements that will save you pain.

1. GrassPatch count vs density (important)

Right now, the plan implies:

many GrassPatch nodes per chunk

This is fine up to a point, but you should explicitly cap or cluster.

Suggestion:

Treat GrassPatch as a cluster, not a single blade

One GrassPatch = 3–7 blades in one sprite or multimesh

Density controls spacing between patches, not total blades

This keeps:

Node count down

Interaction cost sane

Add a note:

“GrassPatch represents a small cluster, not a single blade.”

2. Shadow updates should be quantized in time

You say:

“Shadow updates only on time change (signal-driven)”

Make this explicit:

Update shadows every N in-game minutes

Not continuously with process()

Example:

96 ticks per day → shadows update every 15 in-game minutes

This avoids micro-jitter and keeps pixel stability.

3. Tree wind shader vs transform

You allow:

shader or transform-based sway

I’d pick one early:

Shader for grass (correct)

Transform-based for trees (simpler debugging)

Why:

Tree trunks must remain stable

Shader mistakes are harder to spot on tall sprites

You can always unify later.

4. Tile size assumption (64×64)

You mention:

64×64 tile size

That’s fine, but:

Grass and props likely won’t align to tile centers

Make sure chunk math is tile-size agnostic

I’d add a note:

“All chunk math operates in world coordinates, not tile indices.”

5. TimeOfDayManager as Autoload — good, but…

Autoload is fine, but:

Don’t let everything query it every frame

You already lean signal-driven — lean harder:

Emit sun_changed, ambient_changed

Consumers cache values

You mostly do this already — just be strict about it.

Hidden risks to watch for 🚨

These aren’t mistakes, just things that tend to bite later:

1. Overlapping systems complexity

You have:

ChunkManager

InteractionManager

TimeOfDayManager

WorldGenerator

This is fine, but:

Keep ownership clear

No circular dependencies

Rule of thumb:

WorldGenerator → builds data

ChunkManager → spatial authority

InteractionManager → routing only

TimeOfDayManager → read-only state

Write that into comments early.

2. Y-sort + shadow Z-index edge cases

You already reference YSortUtils — good.

Just make sure:

Shadows NEVER participate in Y-sort

They always sit in a ground-decal band

Otherwise tall units will cast shadows over things they shouldn’t.