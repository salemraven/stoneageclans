# Character layers — design & performance plan

**Status:** Design lock (Aug 2026) — **not fully implemented**  
**Purpose:** Single plan for **layered PNG identity** (hair, face, body, clothing, hats, weapons) on many NPCs, with **chunk sleep** and **visual LOD** so crowds stay unique without melting FPS.

**See also:** [pawn_goal.md](pawn_goal.md) (vision), [animation_tuner.md](animation_tuner.md) (tuner + bake motion), [lag.md](lag.md) (perf baseline), [visual_vs_sim_layers.md](../bible/visual_vs_sim_layers.md) (chunk sim tiers), [settlement_sim.md](../bible/settlement_sim.md) (off-screen villages), [multiplayer.md](../bible/multiplayer.md) (authority)

---

## TL;DR

- Each character is **up to ~10–12 optional PNG layers** pinned on pivots — not one baked sheet per person.
- **Motion is shared** (walk/idle/attack bake or mannequin bob). **Identity is layered** at spawn from a small **appearance blob**.
- **Never draw what you don’t need:** chunk **sleep** removes off-screen nodes; **visual LOD** drops cosmetic layers by camera distance.
- **Server owns appearance + sim state;** clients **rebuild layers once** on spawn/wake — no per-frame cosmetic sync.
- Art: **`head1.png` stays 307×350**; **hair (and similar) export at 500×700** with a fixed head guide anchor; ears/clothing follow the same pivot rules.

---

## Goals

| Goal | How |
|------|-----|
| **Many unique looks** | Mix & match layer IDs (hair, hat, cloth, paint) + skin tint + morphology scale |
| **Large populations** | Sleep/despawn off-chunk; sim dormancy; visual LOD; optional runtime bake for stable outfits |
| **Genetics / birth** | Appearance blob from parents + mutation; same blob for editor, spawn, MP receive |
| **Multiplayer safe** | Authoritative appearance on server; deterministic rebuild on clients |
| **Artist-friendly** | Individual PNGs in folders → packer builds atlas + registry; tuner nudges offsets |

---

## What ships today vs target

| Piece | Today | Target |
|-------|--------|--------|
| Body + head | `TunerBodyVisual` + `head1.png` / `body1.png` | Same + morphology scale on pivots |
| Skin tint | `skin_tone` / `genetics_profile.skin_modulate` | Same tint on head, body, ear layers |
| Weapon | `WeaponOverlay` on `Sprite` | Same (combat poses separate from face stack) |
| Hair / ears / clothing / hats | **Not wired** | Layer sprites on `HeadPivot` / `BodyVisual` |
| Appearance resource | `CharacterAppearance` stub (`hair_id`, …) | Full blob + registry |
| Sleep serialize | `skin_tone`, `card_index`, traits, HP, … | **+ appearance IDs** (hair, hat, cloth, …) |
| Visual LOD | **Not built** | Distance tiers (see below) |
| Runtime bake | Tuner bake for **motion** only | Optional bake for **stable cosmetic stacks** (crowd LOD) |

Code touchpoints today: `PlaceholderCardService`, `TunerBodyVisual`, `npc_base.serialize_to_sleep_data()`, `main.spawn_npc_from_sleep_data()`.

---

## Layer model (runtime)

### Scene graph (layered mannequin path)

Aligns with in-game mannequin + planned cosmetics:

```text
CharacterRoot (NPC / Player)
└── Sprite                          ← Y-sort foot; logical flip_h
    ├── BodyVisual
    │   ├── BodySprite              ← body1.png
    │   ├── ClothTorso              ← optional
    │   ├── ClothCloak              ← optional
    │   └── BodyPaint               ← optional
    ├── HeadPivot                   ← neck socket; head_scale applied here
    │   ├── HairBack                ← optional (behind head)
    │   ├── HeadSprite              ← head1.png (face/skull, no baked hair)
    │   ├── EarSprite               ← optional; same skin modulate
    │   ├── Eyes / Brow / Beard     ← optional
    │   ├── HairFront               ← optional (bangs)
    │   └── Hat / Helmet            ← optional (usually top z on head stack)
    └── WeaponOverlay               ← club/spear/tools (combat system)
```

**Max layers:** budget **~12 cosmetic sprites** per pawn at **full LOD**; typical pawn **4–8** (not every slot filled).

### Z-order (back → front, do not swap on flip)

Fixed stack (see [animation_tuner.md § Draw order](animation_tuner.md)):

1. Hair back  
2. Body / cloak back  
3. Head base  
4. Ears, eyes, brows, nose, mouth, beard  
5. Hair front  
6. Hat / helmet  
7. Weapon overlay (when in front; huge shields may bump z later)

**Rule:** `Sprite.flip_h` is the only facing flag; layers mirror via position + `flip_h` on sprites — not `scale.x = -1` on children independently.

---

## Art pipeline

### Canvas sizes (locked for v1)

| Asset | Size | Notes |
|-------|------|--------|
| **`head1.png`** | **307 × 350** | Tight head crop; **do not resize** — neck pivots in `layered_blank_1.tres` stay valid |
| **Hair sheets** | **500 × 700** | Room for wild hair; transparent padding |
| **Ears, hats, face parts** | **500 × 700** recommended | Same **head guide anchor** as hair for one-time alignment |
| **Body clothing** | Match **body texture space** or torso overlay with registry offset | Can use `body1`-aligned workspace later |

### Photoshop / source workflow

1. **500 × 700** transparent doc.  
2. Place **`head1.png`** on locked **`HEAD GUIDE`** layer (same X/Y every file).  
3. Draw hair / ears / hat on separate layers.  
4. Export **PNG, transparency on, do not trim** transparent pixels on export.  
5. Drop sources in:

```text
assets/character_cards/cosmetics_source/
  hair/
  ear/
  hat/
  eyes/
  torso/
  ...
```

6. **Packer script** (planned under `tools/`) produces:
   - `assets/character_cards/cosmetics_atlas.png`
   - `cosmetics_atlas.json` or `cosmetics_registry.gd` — id → `{ layer, region, attach_offset_px, z }`

**Naming:** folder or prefix = layer type (`hair_`, `beard_`, `hat_`) — the game does not infer type from pixels.

### Atlas & batching

- One or few atlases (cosmetics, clothing) — shared textures across **all** NPCs.  
- Each layer = `AtlasTexture` region (same pattern as combat sprite sheets).  
- **Filter: Nearest**, mipmaps off.

### Morphology scale

- **`head_scale`** on `HeadPivot` — head, hair, ears, hat, face features inherit (one uniform scale).  
- **`body_scale`** on `BodyVisual` / body pivot — torso, cloak, body paint.  
- Tune offsets **once at reference scale 1.0**; genetics only multiplies pivot scale.  
- Extreme sizes (>1.15 or <0.85): optional **size bands** (Small / Ref / Large) — not per-NPC art.

---

## Data model

### `CharacterAppearance` (Resource)

Single serializable blob per individual (extend existing stub):

```gdscript
# Identity slots (string ids into cosmetics_registry)
hair_id: String
hair_back_id: String      # optional second layer
ear_id: String
eyes_id: String
beard_id: String
hat_id: String
torso_cloth_id: String
body_paint_id: String

# Morphology
head_scale: float = 1.0
body_scale: float = 1.0

# Tint
skin_modulate: Color
# optional: hair_modulate, paint_modulate
```

### Genetics mapping

- Birth / editor: genome → `CharacterAppearance` (discrete enums + continuous scale + skin tint).  
- **One function:** `AppearanceService.build_from_genetics(genome) -> CharacterAppearance`  
- **One apply path:** `AppearanceService.apply_to_entity(entity, appearance)` — spawn, wake, MP receive, tuner preview.

### Sleep / chunk persistence

Extend `serialize_to_sleep_data()` / `spawn_npc_from_sleep_data()` to include appearance fields (or embedded `CharacterAppearance` resource path / dictionary).

**Invariant:** Chunk unload → NPC node destroyed → data in `NPCSleepManager` → chunk load → respawn → **`apply_to_entity` rebuilds all layers**. No reliance on stale nodes.

If appearance changes while chunk unloaded (future: barber, equip hat), **server updates sleep record / entity state** before next wake.

---

## Multiplayer

| Data | Authority | When synced |
|------|-----------|-------------|
| Appearance blob | **Server** | Spawn, wake, equip/unequ cosmetic, genetics event |
| Layer transforms | **Derived locally** | Never stream per-frame |
| Weapon / combat overlay | **Server** combat state | Existing combat replication |

Client receives: `{ network_id, appearance: { hair_id, …, skin_modulate, head_scale } }` → `apply_to_entity`.

**Degrade order** (if bandwidth pressure): lower replication rate for far entities → skip cosmetic **updates** → never skip combat/inventory/herd commits ([multiplayer.md](../bible/multiplayer.md)).

---

## Performance: three tiers (sim vs render)

Do not confuse **sim tier** with **visual LOD** — they are independent.

### A. Simulation tiers (already in repo)

From [visual_vs_sim_layers.md](../bible/visual_vs_sim_layers.md):

| Tier | Node exists? | AI / physics |
|------|----------------|--------------|
| **Awake** | Yes | Full |
| **Dormant** | Yes | Off (`SimDormancyController`) |
| **Sleeping** | **No** | Data only (`NPCSleepManager`) |

Chunk unload → `sleep_npcs_in_chunk`; load → `wake_npcs_in_chunk`.

### B. Visual LOD tiers (to implement)

Based on **camera distance** (and optional story flags: player party, selected, clan leader).

| LOD | Distance (starting guess) | Layers drawn | Draw calls / pawn (approx) |
|-----|---------------------------|--------------|----------------------------|
| **0 — Hero** | Party, player, selected, nearby leaders | Full stack (~8–12) | 8–12 |
| **1 — Near** | e.g. < 900 px | Body, head, hair, hat, weapon | 4–6 |
| **2 — Mid** | e.g. 900–1400 px | Body, head, weapon (no hair/ears/hat) | 2–3 |
| **3 — Far** | e.g. > 1400 px | Body + head **or** single baked portrait | 1–2 |
| **Sleep** | Off-chunk | **Zero** | 0 |

**Reference:** procedural arm cull already at **1400 px** (`NPC_ARM_CULL_DISTANCE_PX`) — cosmetic LOD should use the **same distance bands** for consistency.

**Hero cap (starting target):** ≤ **15–25** pawns at LOD 0 on screen; ≤ **80** total visible pawns at LOD ≤ 2 ([lag.md](lag.md)).

### C. Optional runtime bake (crowd path)

When outfit is **stable** (clansman uniform, frozen corpse):

- Combine body + head + hair + cloth → **one `Texture2D`** (viewport or offline bake).  
- Swap to single sprite at LOD 2–3 or for background crowd.  
- Tooling direction: extend tuner bake pipeline — **not** one bake per genetics combo at authoring time.

---

## System flow

```text
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ Genetics / DNA  │────▶│ CharacterAppearance│────▶│ apply_to_entity │
│ Equipment / Hat │     │ (ids + scales)    │     │ (once per spawn)│
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                        ┌─────────────────────────────────┼─────────────────────────────────┐
                        ▼                                 ▼                                 ▼
                 HeadPivot layers                  BodyVisual layers              WeaponOverlay
                 (atlas regions)                   (atlas regions)                (existing combat)
```

Each frame (only for **visible, awake** pawns):

1. Motion: mannequin bob / baked clip / weapon overlay combat (existing).  
2. **Visual LOD controller:** set layer `.visible` or swap baked portrait — **no texture reload**.  
3. Flip: card `flip_h` → mirror overlay positions (layered pawn rules).

---

## Implementation phases

### Phase 0 — Doc + registry (this file)

- [x] Design lock: canvas sizes, LOD tiers, data model  
- [ ] `cosmetics_registry.gd` + packer script  
- [ ] Placeholder atlas (colored rects) for pipeline test  

### Phase 1 — Minimal identity (prove one NPC)

- [ ] `AppearanceService.apply_to_entity`  
- [ ] One hair layer (500×700) + `head1` on mannequin  
- [ ] Tuner offset pin for hair attach  
- [ ] Head scale on `HeadPivot`  

### Phase 2 — Sleep + MP safe

- [ ] Appearance in `serialize_to_sleep_data` / wake spawn  
- [ ] Server appearance blob stub for MP  

### Phase 3 — More slots

- [ ] Ears (skin modulate), hat, torso cloth, body paint  
- [ ] `hair_back` / `hair_front` split  

### Phase 4 — Visual LOD

- [ ] `CharacterVisualLOD` — distance bands, hero list  
- [ ] Hide cosmetic layers at LOD ≥ 2  
- [ ] Profile gate in `lag.md` baseline  

### Phase 5 — Crowd optimization (if profiling demands)

- [ ] Runtime bake for stable outfits  
- [ ] Size bands for extreme morphology  

---

## Invariants (do not break)

1. **Bake motion, layer identity** — never bake per-individual hair into walk strips.  
2. **One apply path** — spawn, wake, editor, MP all call `apply_to_entity`.  
3. **Unflipped east authoring** — west = `flip_h` + mirrored offsets (weapon overlay rules).  
4. **Shared atlases** — no unique PNG per NPC stored on disk.  
5. **Sleep record includes appearance** — chunk return must not reset hair randomly.  
6. **Cosmetic registry ≠ weapon preset** — do not store hair offsets in `club_clansmen_1.tres`.  
7. **Measure before optimize** — `--lag-profile` + draw call count after each phase ([lag.md](lag.md)).

---

## Verification checklist

- [ ] Walk away from chunk → NPC sleeps → return → **same hair/hat/skin**  
- [ ] 20+ unique appearances in one scene — distinguishable silhouettes  
- [ ] Flip left/right — hair/hat stay on correct side (no double-mirror)  
- [ ] Head scale 0.9 / 1.1 — hair and ears scale with head, no manual re-offset  
- [ ] LOD 2 — distant crowd drops hair; near party keeps full stack  
- [ ] FPS / draw calls documented vs Aug 2026 baseline  

---

## Open questions

| Question | Default until proven wrong |
|----------|----------------------------|
| One atlas or hair + clothing atlases? | Start **one cosmetics atlas**; split if import size hurts |
| Women / babies on baked cards? | Migrate to layered path when identity needed; until then legacy card + tint |
| Hat removes hair slot? | Registry `hat_id` can set `hide_layers: ["hair_front"]` |
| Asymmetric hair under mirror? | East-only art first; per-layer `no_mirror` flag later if needed |

---

## Related files (implementation map)

| Area | Path |
|------|------|
| Body/head runtime | `scripts/tools/tuner_body_visual.gd` |
| Mannequin apply | `scripts/systems/placeholder_card_service.gd` |
| Appearance stub | `scripts/character/character_appearance.gd` |
| Sleep | `scripts/systems/npc_sleep_manager.gd`, `npc_base.serialize_to_sleep_data()` |
| Perf | `guides/lag.md`, `scripts/systems/sim_dormancy_controller.gd` |
| Tuner | `scenes/tools/LimbTuner.tscn`, `guides/animation_tuner.md` |
