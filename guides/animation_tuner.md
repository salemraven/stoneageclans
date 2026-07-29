# Character Animation Tuner — purpose, goals, UX, and plans

**Scene:** `scenes/tools/LimbTuner.tscn`  
**Window title:** Character Animation Tuner · **Character Tuner** (left panel)  
**Animation catalog:** `scripts/config/character_animation_catalog.gd`  
**Pawn vision (north star):** [pawn_goal.md](pawn_goal.md) — layered pivots, genetics, RimWorld readability  
**Canonical preset example:** `assets/limb_presets/none_clansmen_1.tres`  
**Last updated:** July 2026 (pawn pipeline + single-panel growth model)

---

## North star

The Character Tuner is the **authoring studio** for hominid pawns: motion, proportions, grips, and (soon) layered appearance — all measurable before anything ships in Main.

| Role | What it means |
|------|----------------|
| **Primary** | **You ↔ agent communication** — visual spec + preview + saved numbers + “Copy for chat” |
| **Pawn vision** | [pawn_goal.md](pawn_goal.md) — modular layers on pivots, genetics-driven morphology, large populations |
| **Game runtime (today)** | Layered body + head + floating weapon overlay (**no arm lines** in Main) |
| **Game runtime (planned)** | **Procedural pawns in Main** (preferred if feasible) · **baked strips** as bridge until then · runtime cosmetic layers |

If something looks right in the tuner and is **Saved**, that is the contract. I read the `.tres`, run `tools/test_limb_tuner.gd`, and change **shared code** — not one-off tweaks from screenshots alone.

### Target pipeline (author → bake → layer)

This is how the tuner grows toward `pawn_goal.md` without fighting genetics or performance:

```text
Character Tuner (one panel)
  ├── Animation  — holdable, category, variant, pins, Play, Bake
  └── Morphology — arm length/thickness, head↔body, body/head scale (same panel, not a separate tab)
         ↓
  Save pose presets (WeaponLimbPreset)     Save morphology (CharacterAppearance / DNA build)
         ↓                                           ↓
  Bake clip → PNG sprite sheets              genetics_profile at spawn
  (idle, walk, attack… per holdable)                ↓
         ↓                                  Layer eyes, hair, skin tint, clothes
  Main: BakedPawnPlayer advances frames     on HeadPivot / BodyPivot (not in the bake)
```

**Motion** is baked once at **reference morphology** (DNA 1.0). **Identity** stays layered at runtime so every clansman can look different without combinatorial sprite sheets.

**Note on `pawn_goal` wording:** Characters are *authored* with procedural pivots in the tuner; the game may *play* baked strips for scale. Baking is the performance path described in pawn_goal § Performance Strategy — not a rejection of procedural authoring.

---

## Tuner vs in-game (important split)

| | **Character Tuner** | **Main gameplay** |
|--|---------------------|-------------------|
| Body + head | ✅ layered mannequin | ✅ same stack |
| Weapon overlay | ✅ spear, club, axe, … | ✅ floating overlay (hand chain planned) |
| Procedural arm lines | ✅ Line2D IK for **authoring** | ❌ **off** (`PROCEDURAL_MANNEQUIN_ENABLED_IN_GAME = false`) |
| Combat preview | Shift ready · Shift+click strike/thrust | Overlay tween on weapon sprite |
| Morphology preview | Spinboxes + **H** pin (more scales planned) | From `genetics_profile` → appearance (planned) |

**Why:** RimWorld-style readability — body + held item reads clearly at zoom. The tuner keeps full rig detail so you can tune grips, proportions, and bake; Main stays cheap at population scale.

---

## Bakes + procedural (you can do both)

**Bakes for the game now; procedural stays alive in the tuner.** That is the intended split — not a conflict. [pawn_goal.md](pawn_goal.md) describes procedural pivots and layered identity; this doc adds **baked motion strips** for population scale. Authoring stays procedural; shipping stays cheap.

**Long-term preference:** If we find a way to run **procedural character animation in Main** at acceptable cost (performance, multiplayer determinism, readability at zoom), **that is the preferred end state** — genetics-driven morphology and motion from the same pivot rig, no re-bake per size or clip. Bakes are the **practical bridge today**, not the forever answer. We **continue to explore** procedural pawns in-game (shared motion code with the tuner, dormancy, LOD, optional bake fallback only where needed).

### Mental model: same rig, two outputs

```text
Character Tuner (procedural rig — always on)
  ├── Live Play       → pivots + IK arms + weapon tween  (fast iteration)
  ├── Morphology sweep → small / ref / large preview     (size exploration)
  └── Bake clip       → sample the same rig → PNG strip → Main
```

| Lane | Role |
|------|------|
| **Procedural (tuner)** | How you **author and experiment** — pins, Play, morphology, combat preview |
| **Bake (Main)** | How you **ship motion** to hundreds of NPCs — one strip, many instances |

The bake is a **recording** of procedural motion (`prepare_bake_sample()` → frame capture), not a second animation system. **One motion source** — preset pins + shared motion code. Do not maintain a parallel hand-tuned timeline.

### Keep procedural in the tuner for

| Use | Why |
|-----|-----|
| Grip / pin tuning | Instant feedback — no re-bake every tweak |
| Play / scrub | Feel walk cycles before committing to a strip |
| Morphology sliders | See clipping and reach at different body/head scales |
| Size bands | Preview Small / Ref / Large on the same motion code |
| Combat preview | Tune arc and lunge; then bake or apply reach multipliers at runtime |
| Compare mode *(planned)* | Live rig vs last baked strip — parity check |

### Bakes handle (for now)

- Walk / idle / gather at population scale in Main **until procedural runtime is proven**
- Fixed pixel look at **reference morphology**
- Optional **Small / Ref / Large** bands — still **sampled from procedural**, not hand-drawn per size

Runtime cosmetics (face, hair, clothes) stay **layered on pivots** either way — procedural north star for **identity** and, when ready, for **locomotion** too.

### Exploration phases

| Phase | Tuner | Main |
|-------|-------|------|
| **Now** | Full procedural preview + **Bake clip** | Baked strips *(when `BakedPawnPlayer` lands)* — bridge path |
| **Next** | Morphology scrub while Play; preview-band dropdown; bake from current morphology | Still baked; **spike procedural playback** on one pawn / test scene |
| **Goal** | Same motion code as game would use | **Procedural pawns at scale** if perf + MP + look pass — **preferred** over permanent baking |
| **Fallback** | Bake still available for export / low-end / parity checks | Baked strips only where procedural cannot meet the bar |

**In-game procedural exploration** (ongoing): reuse tuner rig + preset motion in Main behind a flag; measure frame cost and network determinism; compare to baked parity; graduate genetics-driven scale (body_size, arm length) without new sprite sheets. Bakes remain valid output until that bar is cleared.

Use the procedural tuner to prove clothing on `BodyPivot` scales with morphology, weapons on hand pivot + grip pins work at ~0.85×–1.15×, and swing reach / arc multipliers feel fair **before** baking or hard-coding combat. If scaling breaks at extremes → clothing variant or size-band bake — not five full procedural runtimes.

### Do not

- Build **two unrelated** motion systems (procedural walk vs separate bake keyframes)
- Drop procedural in the tuner because Main uses bakes — the tuner **is** the procedural lab
- Bake per-NPC genetics — bake **bands + reference**, layer face/hair at spawn

---

## Tuner vs in-game size (1:1 contract)

The tuner preview **must** match Main pixel-for-pixel at default camera zoom. Both use the same code path:

- `TunerMannequinLayout.from_registry()` → card scale **128 ÷ body texture height** (~0.272 for `body1.png`)
- `TunerBodyVisual.apply_layout()` — same body/head layers as in-game
- `PlaceholderCardService` layered mannequin path on player/caveman

| Check | Expected |
|-------|----------|
| **Stage scale** | **`stage_scale = 1.0`** — character is not magnified by stage |
| **View zoom** | **`view_zoom`** (default ~3) — scroll wheel; UI-only, does not change saved numbers |
| **Body height** | ~**128 px** on screen at default zoom |
| **Drag pins** | Bigger via **`handle_ui_scale = 4`** — UI only |
| **Verify** | `godot --headless -s res://tools/compare_mannequin_parity.gd` → `PASS` |

Saved preset numbers live in **128 px display space** (card foot at origin).

---

## Character Tuner UI (Holdable → Category → Variant)

The old **single pose dropdown** is gone. Selection is three steps:

```
1. HOLDABLE   — grid: None · Club · Spear · Axe · Pick · Oldowan
2. CATEGORY   — Idle · Walk · Attack · Gather · Taunt · Ranged
3. VARIANT    — e.g. Idle / Idle 1, Walk / Walk 1 (hidden when only one)
```

**Source of truth:** `CharacterAnimationCatalog.HOLDABLES`. Disabled categories = not supported for that holdable yet (Taunt, Ranged are placeholders).

### Idle default (avoid jumbled arms)

| Action | What happens |
|--------|----------------|
| **Switch holdable** | Always resets to **Idle** (first idle variant) |
| **Switch category** | Jumps to **first variant** in that category |
| **Switch variant** | Loads that pose snapshot only |

### Per-holdable catalog (today)

| Holdable | Idle | Walk | Attack | Gather | Taunt / Ranged |
|----------|------|------|--------|--------|----------------|
| **None** | Idle, Idle 1 | Walk, Walk 1 | — | Gather | — |
| **Club** | Idle, Club grip | — | Windup | — | — |
| **Spear** | Idle | Walk, Walk 1 | Windup | — | — |
| **Axe / Pick / Oldowan** | Idle, Idle 1 | Walk, Walk 1 | Attack | Gather | — |

**Adding a clip:** extend `CharacterAnimationCatalog.HOLDABLES` — do not grow a flat dropdown again.

---

## One panel, growing sections (not separate tabs)

The tuner stays **one scrollable left panel**. New capabilities add **sections** or **controls**, not hidden tabs.

| Section | Today | Growing toward |
|---------|-------|----------------|
| **Animation** | Holdable · Category · Variant · Play · Bake | Taunt, Ranged, bow/sling |
| **Morphology** | Arm length · arm thickness · **H** head pin | Body scale · head scale · neck offset spinboxes |
| **Cosmetic layers** *(planned, same panel)* | — | Eyes, hair, nose, clothing preview slots |
| **Save / reset** | Save all · Bake · Copy · Reload | **Save DNA** (morphology file) alongside pose save |

**UI = one panel. Disk = two save types** (see below). Morphology must not be duplicated into every `spear_clansmen_1.tres` — genetics needs one place to read/write shape.

---

## Morphology & DNA (main panel, separate files)

Controls live on the **main tuner panel** (Arm length/thickness row today; body/head scale and neck distance coming on the same panel).

| Control | Tuner (today / planned) | Saves to |
|---------|-------------------------|----------|
| Upper / lower arm length | ✅ spinboxes | **Transition:** preset today → **DNA build** (one value for all holdables) |
| Arm thickness | ✅ spinbox | same |
| Head ↔ body (neck) | ✅ **H** pin + `CharacterCardLayerLayout` | layout + DNA build |
| Body scale (X/Y) | planned spinboxes | `CharacterAppearance.body_proportion_scale` |
| Head scale | planned spinboxes | DNA build / appearance |

| Save type | Example file | Stores | Does **not** store |
|-----------|--------------|--------|---------------------|
| **Pose preset** | `spear_clansmen_1.tres` | Idle / Walk 1 / Attack **pins & grips** for that holdable | Global body height, face variants |
| **Morphology / DNA build** | `assets/character_builds/reference.tres` | Arm length, thickness, body/head scale, neck | Walk swing phase, spear windup timing |
| **Layout** | `layered_blank_1.tres` | Default neck socket, body/head texture paths | Per-NPC genetics |

**Rule:** Tune **motion** at reference morphology (1.0). **Genetics** at spawn adjusts morphology + cosmetic layers; same baked walk plays on all builds unless you add optional **size buckets** (Small / Ref / Large) for extreme species blends.

Stub: `scripts/character/character_appearance.gd`. **Save DNA** button planned; morphology preview is always live in the viewer.

Cross-ref: [pawn_goal.md](pawn_goal.md) (genetics, hierarchy), `bible/future implementations/genetics.md`.

---

## Runtime pawn (goal): bake motion, layer identity

What players see in a large clan:

```text
CharacterRoot
├── Shadow, dust (cheap procedural)
├── BodyPivot  ← plays baked strip OR live bob (clip from tuner)
│   ├── Torso (+ future chest hair, clothes, armor layers)
│   ├── HeadPivot  ← baked bob or counter-balance from same clip
│   │   └── Face layers (eyes, nose, hair, beard — from genotype, NOT baked)
│   └── Weapon / hand chain (from bake or overlay tween)
└── Status FX
```

| Layer type | Source | Why |
|------------|--------|-----|
| **Walk / idle / gather / attack motion** | Tuner **Bake clip** → `assets/baked/…` | Same clip for hundreds of NPCs |
| **Face, hair, skin tint, clothing** | Layered sprites at spawn | Genetics — no re-bake per individual |
| **Body/head scale, arm length** | Morphology from DNA + genetics | Neanderthal hybrid vs tall build without new art |

Bake **reference body + head motion + weapon** (arms optional in composite until sprite arms land). Do **not** bake per-individual faces into the strip.

---

## Pose snapshot isolation (do not cross-contaminate)

Each **variant** owns its fields in the pose `.tres`. The tuner **read/save active row only**.

**Rules (enforced in code + tests):**

1. Never redirect because another snapshot “exists” (e.g. `idle_club1` ≠ idle standing overlay).
2. **Save** uses `WeaponLimbPreset.tuner_commit_storage_mode` for the active variant.
3. **`tools/test_limb_tuner.gd`** includes `_test_pose_snapshot_isolation`.

Tests use `_apply_pose_catalog_entry(weapon, mode)` — same path as the UI.

---

## Story so far (why this tool exists)

1. Weapon-driven Line2D arms — IK authoring for spear/club.
2. Limb Tuner side app → **Character Animation Tuner** with mannequin body/head.
3. Pose map per holdable: Idle 1, Walk 1, Gather 1, Attack windups.
4. Main simplified: **no arm lines in gameplay**; floating weapon RimWorld-style.
5. **Character Tuner UI** — holdable + category + variant; idle default on holdable change.
6. **Bake v1** — export sprite sheets + review popup.
7. **Direction locked** — [pawn_goal.md](pawn_goal.md): bake motion from tuner, layer genetics/cosmetics at runtime; morphology on **same panel**.

---

## Bake pipeline (v1 shipped · playback planned)

**Tuner authors → Bake clip → sprite sheet + JSON → Main plays frames.**

### v1 — shipped in tuner

| Piece | Path |
|-------|------|
| **Bake clip** button | Actions section |
| Baker | `scripts/tools/limb_animation_baker.gd` |
| Capture | `scripts/tools/limb_bake_frame_capture.gd` (body + head + weapon) |
| Review | `scenes/tools/LimbBakeReviewWindow.tscn` |
| Output | `assets/baked/clansmen_1/<holdable>/<clip>.png` + `.json` |
| Clips | `idle`, `idle1`, `walk`, `gather1` — east, 128×128 |
| Test | `godot --headless -s res://tools/test_limb_bake.gd` |

**Workflow:**

1. Set morphology (reference build).
2. Pick holdable + category + variant → tune pins → **Save all**.
3. **Bake clip** → review popup → files under `assets/baked/`.

**Not yet:** attack/thrust strips, 8 directions, `BakedPawnPlayer` in Main, batch bake all catalog clips.

### Optional size buckets (later)

If extreme genetics stretch bakes badly: bake **Small / Reference / Large** from named DNA builds in the tuner — still not one sheet per NPC.

---

## Smooth UI / UX — principles

### One happy path

```
Set morphology (reference) → pick holdable / category / variant
→ Play or ←→ or Shift+click → drag pins → Save all → Bake clip (when ready)
```

### Panel layout (left **Character Tuner**, ~340px, single panel)

| Section | Purpose |
|---------|---------|
| **Animation** | Holdable grid · Category · Variant |
| **Preview** | **▶ Play / ⏸ Pause** (idle & gather) |
| **Morphology** | Arm length · thickness · **H** head · *(planned)* body/head scale |
| **Cosmetics** *(planned)* | Face/hair/clothing pickers — same panel, below morphology |
| **Save & reset** | Save all · **Save DNA** *(planned)* · Bake clip · Reload · Reset |
| **Copy for chat** | Pose + morphology handoff |
| **Summary / Status** | Active variant, elbow labels, reach warnings |

### Canvas / pins

| Pin | Label | Action |
|-----|-------|--------|
| Dominant shoulder | **1** | Drag |
| Dominant hand | **1h** | Drag |
| Support shoulder | **2** | Drag |
| Support hand | **2h** | Drag |
| Weapon | **3** | Drag |
| Head / neck | **H** | Drag (head↔body distance) |
| Elbow bend | **1e / 2e** | **Click** to flip ± |

**Draw order (tuner):** arm1 → body → head → arm2.

### Preview controls

| Variant | Preview |
|---------|---------|
| Idle / Idle 1 / Gather | **▶ Play** / **⏸ Pause** |
| Walk / Walk 1 | **← / →** arrow keys |
| Attack windup | **Shift** ready · **Shift + click** strike/thrust |

---

## Agent workflow

### Your side

1. Open tuner (`LimbTuner.tscn`).
2. Adjust morphology + pick animation variant.
3. Tune pins; **Save all**; **Bake clip** when loop is ready.
4. Handoff example:

```
Morphology: reference (arm 120/120, thickness 14)
Preset: spear_clansmen_1 · Walk 1
Baked: assets/baked/clansmen_1/spear/walk.png
Intent: support arm swings wider than weapon arm
```

### Agent side

1. Read pose `.tres` + layout + baked manifest if relevant.
2. Run tuner verify (cloud-safe):

```bash
bash tools/run_limb_tuner.sh verify
```

After bake changes, also run a targeted bake:

```bash
bash tools/run_limb_tuner.sh bake --weapon none --clip idle
```

3. Wire Main playback when implementing `BakedPawnPlayer`.

**Cloud agents (no Godot window):** use `verify`, `bake`, or `share-web` — not `gui`. See `.cursor/rules/cloud-agent-limb-tuner.mdc`.

**Local GUI:**

```bash
bash tools/run_limb_tuner.sh gui
# or:
SKIP_SINGLE_INSTANCE=1 godot --path . res://scenes/tools/LimbTuner.tscn
```

---

## Saved data (source of truth)

| File | Resource | Contents |
|------|----------|----------|
| `assets/limb_presets/<weapon>_clansmen_1.tres` | `WeaponLimbPreset` | Per-variant pins, grips, elbows (motion) |
| `assets/character_cards/layered_blank_1.tres` | `CharacterCardLayerLayout` | Neck socket, texture paths |
| `assets/character_builds/<name>.tres` *(planned)* | `CharacterAppearance` | Morphology: scales, arm length, thickness |
| `assets/baked/clansmen_1/<holdable>/` | PNG + JSON | Baked motion strips |

**Coordinate space:** 128 px display height reference. **Export:** `to_chat_handoff()` · **Copy for chat**.

---

## Technical map

| Piece | Path |
|-------|------|
| Scene | `scenes/tools/LimbTuner.tscn` |
| App / UI | `scripts/tools/limb_tuner.gd` |
| Animation catalog | `scripts/config/character_animation_catalog.gd` |
| Pawn vision | [guides/pawn_goal.md](pawn_goal.md) |
| Rig + preview | `scripts/tools/limb_tuner_rig.gd` |
| Mannequin | `scripts/tools/tuner_body_visual.gd` |
| Bake | `scripts/tools/limb_animation_baker.gd` |
| Appearance stub | `scripts/character/character_appearance.gd` |
| Preset schema | `scripts/config/weapon_limb_preset.gd` |
| In-game mannequin | `scripts/systems/placeholder_card_service.gd` |
| Tests | `tools/test_limb_tuner.gd`, `tools/test_limb_bake.gd` |

---

## Future plans

### A — Tuner panel (same screen)

- [x] Holdable + category + variant picker
- [x] Idle default on holdable switch
- [ ] **Morphology row** — body scale, head scale, neck offset spinboxes (main panel)
- [ ] **Save DNA** — morphology file separate from pose Save all
- [ ] Cosmetic layer pickers (eyes, hair, …) — **same panel**, not a new tab
- [ ] ▶ Play walk button
- [ ] Unsaved indicator (pose vs morphology vs disk)

### B — Data model

- [x] `CharacterAnimationCatalog`
- [ ] Move global arm length/thickness from preset → DNA build (single source for genetics)
- [ ] `genetics_profile` → appearance layers + morphology at spawn
- [ ] Bow, sling, taunt, ranged in catalog

### B2 — Bake + Main playback

- [x] Bake clip + review popup
- [ ] Combat strips + 8-dir spear
- [ ] `BakedPawnPlayer` in Main
- [ ] Batch bake entire catalog
- [ ] Optional DNA size buckets for bakes

### C — Game parity

- [x] Main: layered body + weapon, no arm lines
- [ ] Runtime face/hair/skin layers on HeadPivot
- [ ] Hand → weapon attach chain (pawn_goal hierarchy)

### D — Procedural exploration (tuner + Main)

- [ ] Preview-band dropdown (Small / Ref / Large) while Play runs
- [ ] Morphology scrub during live preview
- [ ] Live rig vs last baked strip compare overlay
- [ ] Bake from current morphology (band-specific export)
- [ ] **In-game procedural spike** — shared motion code with tuner; perf + MP determinism tests
- [ ] Graduated path: debug flag → player pawn → population if bar is met; bakes as fallback only

---

## Design rules

1. **No guessing** — measure in tuner; save; bake or code.
2. **One panel** — animation, morphology, and cosmetics grow as sections, not tabs.
3. **Two save types** — pose preset (motion) vs DNA/morphology (shape); never mix genetics into six weapon files.
4. **Bake motion, layer identity** — strips for walk/idle/attack; genetics for face/hair/skin/clothes.
5. **Author at reference morphology** — genetics and optional buckets handle extremes.
6. **Tuner has arms; Main does not** — bake bridges authoring to population scale.
7. **Bakes + procedural** — one motion source in the tuner; bake records it; do not fork into two timelines. **Procedural in Main is the preferred end state** if we can make it work at scale.
8. **pawn_goal is the pawn target** — this doc is how the tuner feeds it.

---

## Related docs

| Doc | Topic |
|-----|--------|
| **[pawn_goal.md](pawn_goal.md)** | Character hierarchy, genetics, layered appearance — **pawn north star** |
| [assets/baked/README.md](../assets/baked/README.md) | Bake output layout |
| [scenes/tools/README.md](../scenes/tools/README.md) | Run commands |
| `bible/future implementations/genetics.md` | Simulation traits |

---

## Quick reference

**Do:** One panel — morphology + animation · Save pose · Save DNA (when wired) · Bake clip · layer cosmetics in game, not in bake · keep procedural preview in tuner · **keep exploring procedural pawns in Main** (preferred long-term).

**Don’t:** Treat bakes as the permanent ceiling · separate tabs for morphology · duplicate arm length in every weapon `.tres` · bake individual faces into walk strips · expect arm lines in Main today · maintain two unrelated motion systems (procedural vs bake).

**Task types for chat:**

1. **New animation variant** — catalog + preset pins + bake.
2. **Morphology** — arm length, head/body scale, neck — DNA build.
3. **Cosmetic layer** — eyes/hair/clothing — layer on HeadPivot, genotype-driven.
4. **Feel tweak** — shared motion code until baked; then re-bake.
