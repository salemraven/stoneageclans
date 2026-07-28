# Animation Tuner — purpose, goals, UX, and plans

**Scene:** `scenes/tools/LimbTuner.tscn`  
**Window title:** Character Animation Tuner · **Pose Map** (left panel)  
**Canonical preset example:** `assets/limb_presets/none_clansmen_1.tres`  
**Last updated:** July 2026 (bake + DNA builds section added)

---

## North star

The Animation Tuner exists so **you can show me exactly what you want** — poses, timing feel, overlay placement, walk swing, attack sanity — without us guessing numbers in chat.

| Role | What it means |
|------|----------------|
| **Primary** | **You ↔ agent communication** — visual spec + preview + saved numbers + “Copy for chat” |
| **Secondary (today)** | **Game runtime** — presets + procedural motion code load in Main for player/NPCs |
| **Secondary (planned)** | **Game runtime** — **baked clips only**; tuner remains the authoring studio |

If something looks right in the tuner and is **Saved**, that is the contract. I read the `.tres`, run `tools/test_limb_tuner.gd`, and change **shared code** (`WalkArmSwing`, `WeaponOverlayCombat`, layer stack, etc.) — not one-off tweaks from screenshots alone.

**Not yet:** full bake pipeline — procedural arms still run in Main until bake + playback land (see [Planned: bake pipeline](#planned-bake-pipeline-tuner--game-no-runtime-ik)).

---

## Tuner vs in-game size (1:1 contract)

The tuner preview **must** match Main pixel-for-pixel at default camera zoom. Both use the same code path:

- `TunerMannequinLayout.from_registry()` → card scale **128 ÷ body texture height** (~0.272 for `body1.png`)
- `TunerBodyVisual.apply_layout()` — same body/head layers as in-game
- `PlaceholderCardService._apply_procedural_mannequin()` — same rig on player/caveman

| Check | Expected |
|-------|----------|
| **Stage scale** | **`stage_scale = 1.0`** — no preview magnifier on the character |
| **Body height** | ~**128 px** on screen |
| **Head height** | ~**95 px** on screen |
| **Drag pins** | Bigger via **`handle_ui_scale = 4`** — UI only, does not change saved numbers |
| **Verify** | `godot --headless -s res://tools/compare_mannequin_parity.gd` → `PASS` |

Saved preset numbers live in **128 px display space** (card foot at origin). What you see in the tuner is what spawns in-game.

**Past bugs fixed:** head was scaled twice (`sync_head_draw_transform`); tuner used `stage_scale = 4` so the character looked 4× bigger than in Main.

---

## Pose snapshot isolation (do not cross-contaminate)

Each **Pose** dropdown row owns its own fields in the `.tres`. The tuner must **read and save the active row only**.

| Pose row | Preset fields (examples) |
|----------|---------------------------|
| Club · Idle standing | `overlay_offset_idle_px`, shoulders, elbow poles, authoritative grip on art |
| Club · Attack windup | Position only — test swing on **Club · Idle standing** (Shift+click) |
| Spear · Idle standing | `overlay_offset_idle_px`, both hand grips (weapon + support idle on body) |
| Spear · Attack windup | Horizontal max extension — **Y1** positions spear; **Y2** + **2h** pinned. Saves `strike_offset_px`. Windup hold = `ready_offset_px`. Test thrust on **Idle standing** (Shift+click) |

**Rules (enforced in code + tests):**

1. **Never** redirect because another snapshot “exists” (e.g. `idle_club1` tuned ≠ use it for idle standing overlay).
2. **Club grip on art** (`Club grip / in-hand` row): when saved, `idle_club1_grip_authoritative = true` — **user work is law**. No snap-to-texture-anchor, no treating pose-row `(0,0)` as “unset.”
3. **Save** always writes the pose row you are editing (`WeaponLimbPreset.tuner_commit_storage_mode`).
4. **Read** routing lives in one place: `WeaponLimbPreset.tuner_overlay_storage_mode` / `resolve_club_overlay_grip_px`.
5. **Debug builds** log an error if live overlay ≠ expected row (`verify_tuner_overlay_matches`).
6. **`tools/test_limb_tuner.gd`** includes `_test_pose_snapshot_isolation` — run after any tuner routing change.

**Past bug:** idle standing showed wrong overlay or yellow grip at club bottom because code treated `(0,0)` on the idle row as “no grip” and overwrote user-tuned `idle_club1` data. **Forbidden:** any heuristic that overrides `idle_club1_grip_authoritative`.

---

## Story so far (why this tool exists)

This grew out of the **procedural arms** effort:

1. **Weapon-driven Line2D arms** — spear/club overlay tracks cursor; arms IK to grip; genetics-friendly thickness (`width_genetics_mult`).
2. **Positioning had to be easy** — exported preset fields, drag pins, save to disk, reload in game.
3. **Side app** — load character + weapon like the game; assemble placement; test attacks (Shift ready, Shift+click strike).
4. **Mannequin pivot** — layered **blank body + head** (`body1.png`, `head1.png`) instead of baked `clansmen_card*.png` arms, so procedural limbs are the arms.
5. **Full animation surface** — not just idle: **Idle 1** (look-around), **Walk / Walk 1**, **Attack**, per-weapon holdables.
6. **Walk polish** (this chat arc) — humanoid swing, travel-aligned (+X default), support arm wider arc, rounded line caps, **slow smooth rhythm** synced with **body bounce + head bob**; **Walk 1** locked as first named walk snapshot.
7. **Elbow rule** — **click `1e` / `2e` to flip bend**; saved in preset; **no auto-flip during walk** (you rejected that).
8. **UX simplification** — **Pose Map** workflow: pick pose + holdable → drag pins → preview → **Save all**; Lock/Test de-emphasized in favor of always-editable assemble mode.

---

## What you are building toward

A single place to **preview almost everything on a character** across animations:

| Layer | Today | Planned |
|-------|--------|---------|
| Procedural arms | ✅ Line2D IK, length/thickness | DNA-scaled length/thickness at runtime |
| Body + head mannequin | ✅ neck socket, walk/idle motion | Same stack in-game |
| Weapon overlay | ✅ spear, club, none, … | Every new holdable gets a preset file |
| Walk / idle motion | ✅ bounce + swing + Idle 1 | More named walks, attack variants |
| Hair, eyes, clothing | — | Overlay slots + per-pose offsets |
| DNA body/head/arm size | — | **Save DNA** named builds + preview in tuner; genetics in sim later |
| Baked animation playback | — | Main plays PNG sheets; **no** runtime IK |

**Genetics note (today):** Author **pose** presets at **DNA 1.0 (reference)**. Full genetics sim is in `bible/future implementations/genetics.md` — mostly **not wired** yet (skin modulate works; `body_size` / arm thickness are planned). See [Planned: DNA character builds](#planned-dna-character-builds-save-dna).

---

## Planned: bake pipeline (tuner → game, no runtime IK)

**Goal:** You tune in the tuner; the game **plays frames**, not live arm math. The tuner stays procedural while editing — only **Main** switches to baked playback.

### One-sentence model

**Tuner authors → Bake step exports sprite sheets → Main advances frame index and picks facing.**

### Why (perf + workflow)

| Today | Planned |
|-------|---------|
| `ProceduralArmController` IK every frame on player + armed cavemen | `BakedMannequinPlayer` (or `DirectionalSpriteSheet`) — cheap atlas swap |
| Same motion code in tuner and Main | Tuner preview code **samples** clips at bake time; Main only **plays** |
| Lag when many NPCs carry weapons | NPCs use same baked sheets; optional distance throttling |

Procedural arms are **not wrong** — they are **expensive at scale**. Baking is the long-term fix, not an abandonment of the tuner.

### What gets baked (per holdable + body card)

| Clip | Source in tuner | Output (example) |
|------|-----------------|------------------|
| Idle loop | `TunerIdlePreview` + idle standing pins | `baked/clansmen_1/spear_idle.png` + JSON |
| Walk cycle | `WalkArmSwing` + **Walk 1** rest pins, L/R facing | `spear_walk.png` |
| Gather | Gather 1 reach → pull keyframes | `spear_gather.png` |
| Club swing | `WeaponOverlayCombat` swing tween | `club_strike.png` |
| Spear thrust | Ready → strike → recover; **8 aim directions** (not infinite) | `spear_thrust_E.png`, … |

Existing loader pattern: `DirectionalSpriteSheet` + `WalkAnimation` (paths empty today because procedural mannequin took over). Legacy `walk.png` / `clubwalk.png` are the older baked style.

### Bake tool (not built yet)

- **Trigger:** Tuner button **Bake animations** and/or headless `tools/bake_limb_animations.gd`.
- **Input:** Saved `WeaponLimbPreset` + active weapon + `CharacterCardLayerLayout` (+ optional [DNA build](#planned-dna-character-builds-save-dna) for non-reference sizes).
- **Process:** Step preview clock frame-by-frame; rasterize body + head + arms + overlay; pack grid PNG + manifest (fps, frame ranges, facing).
- **Output dir (example):** `assets/baked/clansmen_1/<weapon>/`.

### Runtime playback (Main)

| State | Game behavior |
|-------|----------------|
| Walk | Advance walk frame; pick left/right row or sheet |
| Idle | Loop idle clip |
| Gather | Play gather clip once |
| Spear ready / strike | Snap cursor aim to **nearest baked direction**; play that clip (same idea as `thrust_min_horizontal_frac`) |
| Club | Play baked windup / hit / recover |

**Tuner unchanged:** Shift+click combat test, pin drag, Save all — still the sign-off path.

### Agent workflow (after bake exists)

1. You tune pins → **Save all**.
2. You say “bake spear walk + thrust” (or click Bake).
3. Agent runs bake, wires manifest, disables procedural path in Main for that weapon.
4. If walk feels stiff → tweak **WalkArmSwing** or Walk 1 pins in tuner → **re-bake** (not guess numbers in chat).

### Phased rollout (when we implement)

1. **Walk + idle** bake for spear/club/none — biggest win.
2. **Gather** bake.
3. **Combat** bake (club swing; spear thrust 8-dir).
4. Turn off procedural mannequin in `PlaceholderCardService` for Main; tuner still procedural.
5. Genetics: reference bake + [layer scale or size buckets](#genetics-with-baked-animation) (see below).

### Non-goals for v1 bake

- Baking every NPC individually by hand.
- Infinite spear aim angles (use direction buckets).
- Replacing tuner procedural preview (authoring stays live).

---

## Planned: DNA character builds (Save DNA)

**Goal:** Save and **name different character builds** (body proportions, arm length/thickness) separately from **pose** presets — so you can preview “stocky hunter” vs “lanky gatherer” without mixing that into `spear_clansmen_1.tres` walk pins.

### Two save types (do not mix)

| Save type | Example name | Stores | Does **not** store |
|-----------|--------------|--------|---------------------|
| **Pose preset** | `spear_clansmen_1.tres` | Idle / Walk 1 / Attack pin rows, overlay offsets, elbow poles | Body height, genetics sim values |
| **DNA build** | `"Stocky hunter"`, `"Reference"`, `"Tall thin"` | Body scale, arm length/thickness multipliers, optional body/head texture ids | Walk swing phase, strike timing |

**Rule:** Pose `.tres` = **what the animation looks like at reference body**. DNA build = **which body** that animation is authored or displayed on.

### Planned UI: **Save DNA**

- Dropdown or list of named builds (like Pose Map, but for **character**, not animation).
- **Save DNA** / **Save DNA as…** — name the build; write to disk (format TBD, e.g. `assets/character_builds/<slug>.tres` wrapping `CharacterAppearance` or a new `CharacterDnaBuild` resource).
- **Load DNA** — preview mannequin at that size; **does not overwrite** the active pose preset unless you explicitly “Apply to preset reference” (avoided by default).
- Preview sliders (Small / Reference / Large) for quick look — **preview only** until you Save DNA.

Stub today: `scripts/character/character_appearance.gd` (`body_proportion_scale`); tuner guide previously listed “DNA preview row” as planned.

### Genetics with baked animation

When bake lands, genetics attach to **playback**, not live IK:

| Approach | When | How |
|----------|------|-----|
| **Reference + layer scale** (v1) | First bake ship | Bake at DNA 1.0; at spawn multiply body / head / arm layer scale from build or `genetics_profile` (tight caps, e.g. 0.9–1.1) |
| **Size buckets** (v2) | Genetics sim matters visually | Bake Small / Reference / Large per clip from **Save DNA** builds; spawn picks nearest bucket |
| **Uniform whole-character scale** | Simplest fallback | One scale on entire sprite — fast, mushy for “long arms, short torso” |

**Author once at reference** — never hand-tune 100 NPCs. Optional: **Bake all DNA variants** from named builds when you click Bake (outputs `baked/stocky_hunter/spear_walk.png`, etc.).

Cross-ref: `bible/future implementations/genetics.md` (`body_size`, continuous loci). Runtime wiring (`genetics_profile` → appearance) is [Future plans](#future-plans-priority--communication-value) section C.

### Status

**Too soon to implement** bake + Save DNA in code (July 2026) — document only. Procedural mannequin remains in Main until bake playback is ready.

---

## Smooth UI / UX — principles

These come from your feedback (locked handles, cluttered modes, wanting a clear flow):

### One happy path

```
Pick pose → Play to preview (or ←→ / Shift+click) → Pause → Drag pins → Save all
```

No hidden “you must Lock first” step for normal pose work. **Assemble mode is the default.**

### Panel layout (left **Pose Map**, ~300px)

| Section | Purpose |
|---------|---------|
| **Pose + preview** | **Pose** dropdown (weapon + snapshot). **▶ Play / ⏸ Pause** for idle & gather loops. |
| **Save & reset** | Save all · **Save DNA** (planned) · Reset pose · Reload file · Reset anchors |
| **Copy for chat** | Full handoff for agent sessions |
| **Arm length & thickness** | Shared upper/lower/thickness spinboxes |
| **Summary** | Live pose row, elbow labels, reach warnings |
| **Status** | Last action (saved, copied, editing which pose) |

**Zoom:** character scale is **fixed** (body-centered at 4× stage scale) — switching pose rows does not shrink/grow the mannequin.

### Canvas / pins

| Pin | Label | Action |
|-----|-------|--------|
| Dominant shoulder | **1** | Drag |
| Dominant hand | **1h** | Drag (priority pick target) |
| Support shoulder | **2** | Drag |
| Support hand | **2h** | Drag |
| Weapon / holdable | **3** | Drag when holdable has overlay |
| Head / neck | **H** | Drag |
| Dominant elbow bend | **1e** | **Click** to flip outward ± (not drag) |
| Support elbow bend | **2e** | **Click** to flip |

**Draw order (tuner):** arm1 → body → head → arm2 (arms split at elbow for depth).

### Preview controls

| Pose row | Preview |
|----------|---------|
| **Idle / Idle 1 / Gather 1** | **▶ Play** / **⏸ Pause** — subtle breathe only; drag a pin auto-pauses |
| **Walk / Walk 1** | **← / →** arrow keys — **club arm stays in idle carry pose**; free arm swings |
| **Attack ready** | **Shift** = ready · **Shift + click** = swing |

Dragging a pin **pauses** idle preview so the pose doesn’t fight your edit.

### Feedback that should always feel instant

- **Summary** updates: holdable, pose name, hand/overlay coords, 1e/2e bend, arm px, idle play state.
- **Reach warnings** when a hand is outside IK range (⚠ in summary).
- **Status line** after Save / Copy / Reset — one plain English sentence.
- **Handles track pan/zoom** via `HandleStage` mirroring `Stage`.

### UX we are still improving

- ~~Walk preview discoverability~~ → **Play walk button + arrows** (planned).
- **Eyes overlay slot** — first cosmetic on mannequin (planned).
- DNA preview sliders not in UI yet; **Save DNA** named builds not in UI yet (see [Planned: DNA character builds](#planned-dna-character-builds-save-dna)).
- Attack mode copy could mention “optional sanity check only” for None holdable.
- **Remove Lock/Test modes** from code when doing UX cleanup pass.

---

## Agent workflow (how we use this together)

### Your side

1. Open tuner (or ask agent to launch `LimbTuner.tscn`).
2. Select **pose** + **holdable**.
3. Tune pins + spinboxes; preview until it feels right.
4. **Save all**.
5. In chat, short handoff:

```
Preset: none_clansmen_1
Animation: Walk 1
Saved: yes
Intent: arms slower, synced with body; support arm swings wider
```

Or press **Copy for chat** and paste.

### Agent side

1. Read `assets/limb_presets/<weapon>_clansmen_1.tres` (+ layout if head moved).
2. Run `SKIP_SINGLE_INSTANCE=1 godot --path . --headless -s res://tools/test_limb_tuner.gd`.
3. Change **shared motion/IK code** when you asked for feel tweaks (not duplicate magic numbers).
4. Re-launch tuner for you to sign off.

### Rest pose vs procedural motion (don’t mix these up)

| Type | Where it lives | Examples |
|------|----------------|----------|
| **Rest pose** | Preset fields per anim mode | `walk1_hand_grip_offset_px`, elbow poles, bend overrides |
| **Procedural motion** | Code modules | `WalkArmSwing`, `TunerIdlePreview`, `WeaponOverlayCombat` strike |

**Walk 1** = your saved **rest** + shared **swing** + shared **body/head rhythm** (`WALK_RHYTHM_SPEED_SCALE` in `PlaceholderCardRegistry`).

---

## Saved data (source of truth)

| File | Resource | Contents |
|------|----------|----------|
| `assets/limb_presets/<weapon>_clansmen_1.tres` | `WeaponLimbPreset` | Shoulders, hands, walk/walk1/attack snapshots, elbow poles/bends, arm length/thickness |
| `assets/character_cards/layered_blank_1.tres` | `CharacterCardLayerLayout` | Body/head texture paths, neck socket, offsets |
| `assets/character_builds/<name>.tres` *(planned)* | `CharacterAppearance` or `CharacterDnaBuild` | Named DNA build: body/head/arm scale multipliers, texture ids |

**Named animations today:**

| UI label | Enum | Storage |
|----------|------|---------|
| Idle (standing) | `IDLE` | `hand_grip_offset_px`, idle poles, … |
| Idle 1 (look around) | `IDLE1` | Same idle storage + `TunerIdlePreview` motion |
| Walk | `WALK` | `walk_*` fields |
| **Walk 1** | `WALK1` | `walk1_*` fields (**canonical saved walk** for none/clansmen_1) |
| Attack (windup) | `ATTACK` | ready grip, `ready_offset_px`, … |

**Coordinate space:** display pixels at **128px card height**; mannequin textures in `assets/character_cards/`.

**Export API:** `WeaponLimbPreset.to_chat_handoff()` · `to_export_dict()` · UI **Copy for chat**.

---

## Walk animation decisions (locked in)

Documented so we don’t re-debate:

- **Travel direction:** walking **right** = **+X** in rig space (arrow keys).
- **Arm swing:** opposite-phase humanoid pump; **support arm wider** than weapon arm.
- **Motion model:** travel-aligned push + shoulder arc; softened wave; **shared clock** with body bounce and head bob.
- **IK during walk:** relaxed min-reach so arms don’t feel “choked”.
- **Elbows:** preset bend only; **no automatic flip while walking**.
- **Walk 1:** first **named** walk snapshot — use this when you say “the walk we tuned”.

Key code: `scripts/systems/walk_arm_swing.gd`, `scripts/config/placeholder_card_registry.gd` (`effective_walk_bounce_speed()`).

---

## Club swing animation (locked intent)

**Pivot:** handle knob on club art (`CLUB_HANDLE_TEXTURE_NX/NY` in `placeholder_card_registry.gd`). The overlay rotates around the grip, not the PNG center.

**Facing right (default):**

| Phase | Rotation | Position | Feel |
|-------|----------|----------|------|
| **Ready** (Shift) | ~−50° (10 o'clock) | `ready_offset_px` from limb preset | Club raised in windup stance |
| **Windup** (start of strike) | **Counter-clockwise** more (−42° from ready) | Pull **back + up** | Tip goes **behind the head** |
| **Downswing** | **Clockwise** sweep (+110° arc from ready) | Lunge **forward + down** | Heavy smash |
| **Recover** | Back to ready | Back to ready pose | Short follow-through |

**Facing left:** same motion mirrored (`_swing_facing_sign` flips rotation and X lunge).

**Tuning knobs** (club block in `WEAPON_COMBAT_PROFILES` → `ResourceData.ResourceType.WOOD`):

- `ready_rotation_offset_deg` — how high the ready pose sits
- `swing_windup_deg` + `swing_pull_back_px` / `swing_pull_up_px` — CCW cock behind head
- `swing_arc_deg` + `swing_lunge_forward_px` / `swing_lunge_down_px` — CW downswing (club uses lower `swing_lunge_down_px` + smooth cubic easing)
- `swing_windup_frac` / `swing_strike_frac` / `strike_duration` — timing
- Optional: `swing_strike_trans` / `swing_strike_ease` — club = smooth cubic in-out; axe inherits old snappy club chop defaults

**In Limb Tuner:** **Club · Attack windup** — drag pins to position the raised stance → **Save all**. **Club · Idle standing** — **Shift** = live windup → **Shift + click** = test strike (same as in-game). Swing arc/timing lives in `placeholder_card_registry.gd` until we expose it in UI.

### Spear thrust (two-hand)

Same tuner pattern as club:

- **Spear · Idle standing** — carry pose; **Shift** = windup preview; **Shift + click** = test thrust.
- **Spear · Attack windup** — horizontal **max extension** pose (thrust peak). **Y1** moves spear; **Y2** + **2h** pinned. Saves to `strike_offset_px`. Shift-ready windup uses `ready_offset_px`. Test thrust from **Idle standing**.

Thrust arc/timing: spear block in `WEAPON_COMBAT_PROFILES` → `ResourceData.ResourceType.SPEAR`.

Key code: `scripts/systems/weapon_overlay_combat.gd` (`compute_swing_strike_targets`, `_play_swing_strike`).

---

## New weapon workflow

When you add spear, club, axe, etc.:

1. Open tuner → select holdable.
2. Tune **Idle**, **Walk 1**, **Attack** (at minimum).
3. Save → creates/updates `assets/limb_presets/<weapon>_clansmen_1.tres`.
4. Tell agent which file + any “feels like X” notes.

Same pipeline later for **hair/clothing** overlays: new slot → tune on mannequin → save offsets → handoff.

---

## Technical map

| Piece | Path |
|-------|------|
| Scene | `scenes/tools/LimbTuner.tscn` |
| App / UI | `scripts/tools/limb_tuner.gd` |
| Rig + preview | `scripts/tools/limb_tuner_rig.gd` |
| Mannequin | `scripts/tools/tuner_body_visual.gd` |
| Walk preview | `scripts/tools/tuner_walk_preview.gd` |
| Idle 1 | `scripts/tools/tuner_idle_preview.gd` |
| Preset schema | `scripts/config/weapon_limb_preset.gd` |
| Preset I/O | `scripts/systems/limb_preset_registry.gd` |
| In-game arms | `scripts/systems/procedural_arm_controller.gd` |
| Headless smoke | `tools/test_limb_tuner.gd` |

Run: [scenes/tools/README.md](../scenes/tools/README.md).

---

## Future plans (priority = communication value)

### A — Tuner UX (smooth preview for you + me)

- [ ] **▶ Play walk** button — auto left-right loop **plus** existing arrow keys (confirmed).
- [ ] **Remove Lock / Test modes** — Pose Map only (confirmed).
- [ ] **Eyes overlay slot** — first cosmetic: texture pick + head-anchored offset pins (confirmed).
- [ ] **Pose strip** — quick buttons: Idle · Idle 1 · Walk 1 · Attack for active holdable.
- [ ] **On-screen pin legend** (optional toggle) for beginners.
- [ ] **DNA preview row** — Small / Reference / Large sliders; **does not save** to preset.
- [ ] **Hair / clothing slots** — after eyes pattern is proven.
- [ ] **Scrub bar** for walk phase (debug swing at 0%, 25%, 50%, …) when tuning with agent.
- [ ] **Unsaved indicator** when pins differ from disk.

### B — Data model

- [ ] **`CharacterDnaBuild` / Save DNA** — named builds on disk; separate from `WeaponLimbPreset`.
- [ ] Per-pose cosmetic offsets in preset or layout.
- [ ] `to_chat_handoff()` lines for cosmetics + active DNA build name + preview scale.
- [ ] Migrate to **pose dictionary** (`poses["walk1"]`) when field count gets painful.
- [ ] Attack variants: `attack1`, `attack2` same pattern as Walk 1.

### B2 — Bake pipeline *(after pose + DNA build schema stable)*

- [ ] `tools/bake_limb_animations.gd` — sample tuner preview → PNG sheets + JSON manifest.
- [ ] Tuner **Bake animations** button (weapon + optional DNA build).
- [ ] `BakedMannequinPlayer` (or extend `WalkAnimation`) — Main playback, no `ProceduralArmController` in game.
- [ ] Spear thrust **8-direction** baked clips + aim snap (reuse thrust aim clamp rules).
- [ ] Re-bake checklist in agent workflow when Walk 1 or combat timing changes.

### C — Game parity

- [ ] Runtime layer stack = tuner draw order.
- [ ] Walk 1 rest + shared swing for placeholder-card NPCs/player *(today: procedural)*.
- [ ] `genetics_profile` → `CharacterAppearance` scale multipliers.
- [ ] Optional DNA **size buckets** for baked clips (Small / Ref / Large per build).

### Non-goals

- Full genetics sim UI inside tuner.
- Replacing bible lineage docs.
- Skeleton2D cutout rig **unless** you explicitly pivot art pipeline (`bible/future implementations/characergenerator.md` is a different track).

---

## Design rules (agent + future features)

1. **No guessing** — measure in tuner; save; then code (or re-bake).
2. **One source of truth** — preset beats chat approximations; **DNA build** beats ad-hoc scale in Main.
3. **Author poses at DNA 1.0 reference** — genetics / named builds multiply or pick baked variant later.
4. **Named animations** — `walk1`, not “the walk we did Tuesday”.
5. **Named DNA builds** — `"Stocky hunter"`, not “the short one we tried once”.
6. **Every new tunable field** → shows up in Copy for chat.
7. **Agent runs the tuner** — headless test + launch; you don’t carry CLI alone.
8. **Same clocks in preview and game** for walk/idle rhythm (until bake; then manifest fps must match preview sample rate).

---

## UX decisions (confirmed)

| Topic | Decision |
|-------|----------|
| **Walk preview** | **Both** — add ▶ Play walk (auto loop) **and** keep ← / → arrow keys |
| **Lock / Test modes** | **Remove** — Pose Map + Attack preview is enough |
| **First cosmetic slot** | **Eyes** on head (before hair/clothing) |

These drive the next tuner UI pass. See [Future plans](#future-plans-priority--communication-value) section A.

---

## Open decisions

| Topic | Notes |
|-------|--------|
| **DNA build resource** | Extend `CharacterAppearance` vs new `CharacterDnaBuild` — decide when implementing Save DNA. |
| **Bake raster** | Viewport capture vs layered composite from mannequin nodes — decide in bake spike. |
| **Genetics v1 with bake** | Layer scale vs size buckets — start reference + tight scale; buckets when sim ships. |

---

## Related docs

| Doc | Topic |
|-----|--------|
| [scenes/tools/README.md](../scenes/tools/README.md) | Commands + file table |
| [docs/clothing.md](../docs/clothing.md) | Runtime tint / clan color rules |
| `bible/future implementations/genetics.md` | DNA traits (simulation) |
| `scripts/character/character_appearance.gd` | Runtime appearance stub |

---

## Quick reference card

**Do:** Save all · name pose (Walk 1) · **Save DNA** when UI exists · one intent sentence · Copy for chat optional.  
**Don’t:** screenshot-only handoff · tune feel only in Main · expect auto elbow flip on walk · mix DNA scale into pose `.tres` rows.

**Four task types for chat:**

1. **New named pose** — drag pins, save, new dropdown entry / preset fields.  
2. **Procedural feel** — “slower”, “looser”, “more sync” → code in `WalkArmSwing` / idle / combat (until baked; then re-bake).  
3. **New overlay slot** — hair/clothing/eyes → layer + pins + handoff line.  
4. **DNA build** *(planned)* — name + save body/arm proportions; preview in tuner; later bake per build.
