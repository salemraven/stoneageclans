# Character Animation Tuner — purpose, goals, UX, and plans

**Scene:** `scenes/tools/LimbTuner.tscn`  
**Window title:** Character Animation Tuner · **Character Tuner** (left panel)  
**Animation catalog:** `scripts/config/character_animation_catalog.gd`  
**Pawn vision (north star):** [pawn_goal.md](pawn_goal.md) — layered pivots, genetics, RimWorld readability  
**Canonical preset example:** `assets/limb_presets/none_clansmen_1.tres`  
**Last updated:** August 15, 2026 (quick-start tutorial + lock-in architecture)

---

## Quick start — how to use the tuner

The **Character Animation Tuner** is where you pose clansmen: hand positions, elbows, weapon grip, and walk cycles. What you save here becomes the numbers the game uses.

### 1. Open the tuner

From the game repo root:

```bash
bash tools/launch_tuner_mac.sh --walk1-preview
```

Other useful launches:

| Command | Opens |
|---------|--------|
| `bash tools/launch_tuner_mac.sh --walk1-preview` | Empty hands · Walk 1 loop preview |
| `bash tools/launch_tuner_mac.sh --none-idle-play` | Empty hands · idle breathe / look-around |
| `bash tools/launch_tuner_mac.sh --spear-idle-play` | Spear · sun-shield idle loop |
| `bash tools/launch_tuner_mac.sh --gather1-preview` | Empty hands · gather reach/pull |
| `bash tools/launch_tuner_mac.sh --spear-preview` | Spear · frozen pose editing (default) |

Windows: run Godot on `scenes/tools/LimbTuner.tscn` with the same flags after `--`.

### 2. Two tabs (left panel)

| Tab | When to use it |
|-----|----------------|
| **Animation Reviewer** | Watch a clip loop (walk, idle raise, gather…). Good for “does this look right?” |
| **Pose Tuner** | Freeze the character and drag pins. Good for editing hand/elbow positions. |

CLI flags like `--walk1-preview` open **Reviewer** already playing the right clip. Click **Edit in Pose Tuner** when you need to move pins.

### 3. Left panel controls (Pose Tuner)

1. **Holdable** — `none` (empty hands), `spear`, `club`, etc. Each holdable has its own save file.
2. **Category + variant** — e.g. Walk → Walk 1, Idle → idle / idle1.
3. **Drag pins on the mannequin:**
   - **Yellow** — weapon hand / grip
   - **Green** — off-hand
   - **Blue** — elbow pole (which way the arm bends)
   - **Right-click** an elbow pin (1e / 2e) — flip bend direction
4. **Pose 1 / Pose 2** (Walk 1) — switch between the two walk snapshots. Pose 2 does **not** overwrite Pose 1.
5. **▶ Play** (Walk 1) — preview the pendulum between Pose 1 and Pose 2 without leaving the tuner.
6. **Save all** — write everything to disk. **This is the only button that actually saves.**
   - Green **✓** = saved
   - Red **●** = unsaved changes (you moved pins but haven’t saved yet)

**Important:** Switching tabs, holdables, or variants can update in-memory pins but **not** the file on disk until you click **Save all**. When in doubt: save, then use **Reload** to confirm pins came back the same.

### 4. Typical workflow (example: Walk 1)

1. Launch: `bash tools/launch_tuner_mac.sh --walk1-preview`
2. Confirm holdable = **none**, variant = **Walk 1**
3. Click **Edit in Pose Tuner** (or switch to Pose Tuner tab)
4. Click **Pose 1** → drag yellow/green hands and blue elbows until it looks like “right foot forward”
5. Click **Pose 2** → pose “left foot forward” (separate row — won’t touch Pose 1)
6. Click **▶ Play** — check the swing looks smooth; elbows stay bent the right way
7. Click **Save all** (button turns green ✓)
8. Click **Copy for chat** — full animation receipt (both poses, motion samples, morphology). Paste in chat and say **lock in this animation**

### 5. After you’re happy — lock it in

Lock-in scripts snapshot your saved poses so they can’t drift silently later. Run from repo root:

```bash
godot --headless -s res://tools/lockin_none_clansmen_1.gd   # idle + walk
godot --headless -s res://tools/lockin_spear_clansmen_1.gd  # spear idle
```

You should see `PASS` in the terminal. If not, don’t merge — something changed on disk.

### 6. Rules of thumb

- **One animation row at a time** — finish Walk Pose 1, save, then Pose 2. Don’t hop between spear and walk without saving.
- **Locked animations** (idle + walk on `none`) shouldn’t change when you work on spear or gather — that’s the isolation architecture. If they do, tell the agent.
- **Tests:** `godot --headless -s res://tools/test_limb_tuner.gd` — run before big IK/motion changes.

More detail below: pose rows, reviewer contract, lock-in log (`ANIMATION_LOCKINS.md`), and per-clip notes.

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

### Inspect every clip

Two tabs at the top of the left panel:

| Tab | Purpose |
|-----|---------|
| **Pose Tuner** | Frozen character — pick holdable + variant, drag pins, Save all |
| **Animation Reviewer** | Full clip list — click to play on loop, Prev/Next, **Edit in Pose Tuner** |

Preview CLI flags (`--walk1-preview`, `--none-idle-play`, etc.) open the **Reviewer** tab automatically.

Full reliability spec: **[Tuner & Animation Reviewer — reliability contract](#tuner--animation-reviewer--how-they-should-work-reliability-contract)** below.

### Pose rows stay separate

Each animation owns its own saved pins in the `.tres` file — **walk elbows do not overwrite spear idle**, and **Walk Pose 2 does not overwrite Pose 1**.

| Row | Saved fields (examples) |
|-----|-------------------------|
| Idle | `hand_grip_offset_px`, `weapon_elbow_pole_idle_px` |
| Walk 1 Pose 1 | `walk1_hand_grip_offset_px`, `walk1_weapon_elbow_pole_px` |
| Walk 1 Pose 2 | `walk1_pull_*` (hands + elbows) |
| Gather reach / pull | `gather1_*` vs `gather1_pull_*` |
| Spear idle | separate file: `spear_clansmen_1.tres` |

After you Save, `*_saved` flags block seed/copy helpers from clobbering that row.

### Animation isolation architecture

**Design principle:** Locked animations are immutable. Working on Walk 1 must not break Spear idle.

Each animation owns its motion logic in separate files under `scripts/systems/`. Shared math lives in pure static functions only.

| File | Owns |
|------|------|
| `ik_utils.gd` | Pole IK, bend-sign IK, reach clamp — **no preset access, no side effects** |
| `idle_motion.gd` | None idle breathe / sway |
| `walk_arm_motion.gd` | Walk 1 pendulum between Pose A and B |
| `gather_arm_motion.gd` | Gather reach / pull cycle |
| `spear_idle_motion.gd` | Spear sun-shield raise / lower / scan |
| `club_windup_motion.gd` | Club rest → A → B windup loop |
| `motion_golden.gd` | Load + diff against `Tests/golden/*.json` |

**Rules**

1. Motion files never import each other.
2. Shared code must be pure functions in `ik_utils.gd` (or tiny helpers like `motion_golden.gd`).
3. Lock-in scripts validate **motion trajectories**, not just static pins.
4. Run `godot --headless -s res://tools/test_limb_tuner.gd` before merging any IK or motion change.

**Lock-in scripts**

| Script | What it locks |
|--------|----------------|
| `tools/lockin_none_clansmen_1.gd` | Idle rest + Walk 1 Pose A/B + golden motion |
| `tools/lockin_spear_clansmen_1.gd` | Spear default idle grip / overlay |
| `tools/lockin_club_clansmen_1.gd` | Club windup loop baseline |
| `tools/lockin_gather_clansmen_1.gd` | Skips until gather is visually signed off |

**Adding a new animation**

1. Create a new motion file (e.g. `axe_chop_motion.gd`).
2. Use `IKUtils` for elbow math — do not add IK to `limb_tuner_rig.gd`.
3. Add a motion test in `tools/test_limb_tuner.gd`.
4. Capture golden samples to `Tests/golden/<name>_motion.json`.
5. Add a lock-in script that replays and diffs against golden (±2 px tolerance).

`limb_tuner_rig.gd` is a thin coordinator: preset row lookup + delegate to motion files.

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
| **Club** | Idle, Club grip | Walk, Walk 1 | Windup | — | — |
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
| **Weapon angle** | Angle spin (0–360°) | Compass rotation around grip pivot for the active pose row (club swing tuning on Attack) |

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

## Tuner & Animation Reviewer — how they should work (reliability contract)

This section is the **target behavior** for save/load and day-to-day use. The code is moving here; where today differs, treat this as the spec to implement — not optional UX polish.

### Why reliability matters here

Small mistakes (wrong pose row, elbow flip, unsaved RAM) are invisible until Main or a bake looks wrong. The tuner must behave like a **small database editor**: every pin write goes to a **named row**, every save is **explicit**, reload must **match disk**.

**Today’s pain points (honest audit):**

| Issue | What goes wrong |
|-------|-----------------|
| Two elbow mechanisms | Saved **pole** and **bend sign** can disagree; IK sometimes used bend when pole existed → elbow “flipped” while paused |
| UI state drives storage | Which row gets written depends on `_walk_pose_edit_b`, gather pull flag, etc. — easy to desync from what you think you’re editing |
| Hands vs elbows on sub-rows | Drag on Walk Pose 2 / gather pull writes `*_pull_*` fields; **Save all** commit path still routes some hands to Pose 1 fields |
| Silent commit | Switching variant, tab, or holdable commits active row to **RAM only** — feels saved but is not on disk until **Save all** |
| Incomplete export | **Copy for chat** JSON omits some pull-row bend fields and `*_saved` flags |
| Seed vs saved flags | Auto-fill can still touch rows that look “empty” unless `*_saved` was set by a prior Save |

The fixes are not “more careful clicking.” They are **one row → one save function → one test**.

---

### Two workspaces — split read and write

```text
┌─────────────────────────────────────────────────────────────┐
│  Animation Reviewer          │  Pose Tuner                    │
│  (inspect only)              │  (author pins)                 │
├──────────────────────────────┼────────────────────────────────┤
│  • Full clip list            │  • Holdable + category + variant│
│  • Click → loop play         │  • Character paused by default  │
│  • Pins hidden / not draggable│ • Drag 1, 1h, 2, 2h, 1e, 2e, 3, H│
│  • No writes to preset       │  • Save all → disk              │
│  • “Edit in Pose Tuner”      │  • Reload → discard RAM         │
│    jumps to same clip frozen │  • Copy for chat → JSON handoff │
└──────────────────────────────┴────────────────────────────────┘
```

| Rule | Reviewer | Pose Tuner |
|------|----------|------------|
| **Purpose** | “Does this clip look right?” | “Change the numbers.” |
| **Playback** | Auto-play on clip select; loop | Paused unless you press ▶ (or A/D walk preview) |
| **Pins** | Hidden or read-only ghosts | Full drag + right-click elbow flip |
| **Preset** | Read from disk/cache only | Read + write staged preset |
| **Save** | Never saves | **Save all** is the only disk write (plus planned auto-save *off* by default) |

**Reviewer must never mutate** `WeaponLimbPreset` fields. If inspect mode needs overlays, it samples the same read path as Main (`resolve_*_for_mode`), not live handle positions.

**Handoff:** Reviewer → **Edit in Pose Tuner** sets holdable + variant + pose row, pauses playback, shows pins at **saved** positions (not last RAM edit from another session).

---

### Pose rows — one row, one bundle, one commit function

A **pose row** is the smallest unit that saves independently. Not “Walk 1” as a whole — **Walk 1 Pose 1** and **Walk 1 Pose 2** are separate rows.

| Row ID | Hands (1h / 2h) | Elbows (1e / 2e pole) | Elbow bend (fallback) | Overlay | Saved flag |
|--------|-----------------|------------------------|------------------------|---------|------------|
| `idle` | `hand_grip_*`, `support_hand_idle_*` | `*_elbow_pole_idle_px` | `*_elbow_bend_sign_override` | `overlay_offset_idle_px` | — |
| `walk1_a` | `walk1_*_hand_*` | `walk1_*_elbow_pole_px` | `walk1_*_elbow_bend_sign_override` | `walk1_overlay_*` | `walk1_pose_a_saved` |
| `walk1_b` | `walk1_pull_*_hand_*` | `walk1_pull_*_elbow_pole_px` | `walk1_pull_*_elbow_bend_sign_override` | *(inherits walk1 overlay)* | `walk1_pose_b_saved` |
| `gather_reach` | `gather1_*_hand_*` | `gather1_*_elbow_pole_px` | `gather1_*_elbow_bend_sign_override` | `gather1_overlay_*` | `gather1_reach_saved` |
| `gather_pull` | `gather1_pull_*_hand_*` | `gather1_pull_*_elbow_pole_px` | `gather1_pull_*_elbow_bend_sign_override` | *(inherits gather overlay)* | `gather1_pull_saved` |
| `attack_windup` | `hand_grip_ready_*`, `support_hand_offset_px` | `*_elbow_pole_ready_px` | `*_elbow_bend_sign_ready_override` | `ready_offset_px` | `*_attack_pose_saved` |
| … | per variant in schema | | | | |

**Target commit API (one function per concern, row id in args):**

```text
commit_row_pins(preset, row_id, snapshot_from_handles) → void
```

Today this logic is split across `_commit_anim_mode`, drag handlers, and pose-edit flags. **Reliability goal:** row id is explicit (`walk1_b`, not “walk1 + bool”); hands, elbows, and overlay for that row always go through the same function on Save and on drag-end.

**Holdable isolation:** `none_clansmen_1.tres` ≠ `spear_clansmen_1.tres`. Editing walk on empty hands never writes spear idle.

---

### Save / load — explicit contract

```text
  DISK (.tres)  ←—— Save all ——  STAGED (registry cache)  ←—— commit_row ——  HANDLES (live)
       ↑                                    ↑
       └———— Reload (discard RAM) —————————┘
```

| Event | Should happen | Should NOT happen |
|-------|---------------|-------------------|
| **Drag pin** | Update handles + optional live preset field for preview | Write disk |
| **Release drag** | `commit_row_pins` for **active row only** → staged preset | Commit a different row |
| **Switch variant / row key (1/2)** | Commit **previous** active row to staged preset | Auto-save disk |
| **Switch holdable** | Commit current holdable’s active row; stage that preset | Lose other holdables’ staged edits |
| **Save all** | Write **all staged** holdables + neck layout; set `*_saved` flags; reload from disk | Partial write without error |
| **Reload** | Re-read `.tres`; reset handles from disk | Merge RAM over disk |
| **Copy for chat** | Same commit as Save all, then export **full** row dict | Substitute for Save all |

**Planned UX (not optional for reliability):**

- **Unsaved indicator** — “Pose row dirty” / “Morphology dirty” / “Saved ✓” in status bar
- **Save all** disabled when nothing dirty (optional)
- **Reload** confirms if staged ≠ disk
- **No silent seed** after `*_saved == true` for that row

**Round-trip test (required per row):** load `.tres` → place pins → Save all → reload → pin globals match within ε. Headless: extend `tools/test_limb_tuner.gd`.

---

### Elbows — one authority (pole), bend as synced metadata

**Target model (simple rule for humans and code):**

1. **Pole px** (`*_elbow_pole_*`) = **authoritative** elbow side. IK always pole-picks when pole ≠ zero.
2. **Bend sign override** = cached hint for fallback, facing mirror, and legacy paths — **derived from pole on every Save**, not edited independently except right-click flip (which moves pole to the other IK branch).
3. **No mid-motion flip** — bend sign never toggled during raise/lower/walk swing; pole arc or locked pick handles motion.

| Action | Target behavior |
|--------|-----------------|
| Drag **1e / 2e** | Moves elbow; Save writes **pole** for active row; bend synced from pole |
| **Right-click 1e / 2e** | Flip to other IK branch; save **new pole**; sync bend |
| Plain click **1e / 2e** | No-op + status hint (accident prevention) |
| Facing flip (A/D) | Mirror read path only; stored overrides remain **east-facing** |

**Anti-patterns (do not use to “fix” an elbow):**

- Clearing pole and re-seeding from bend sign
- Different IK path when paused vs playing the same row
- Storing bend in one row while pole lives in another

---

### Animation Reviewer — clip list behavior

**Catalog source:** `CharacterAnimationCatalog.all_clips()` — same ids Main and bake will use.

| Behavior | Spec |
|----------|------|
| Select clip | Start loop playback immediately |
| Prev / Next | Cycle catalog order; playback continues |
| Edit in Pose Tuner | Switch tab; map clip → holdable + variant + pose row; **pause**; load pins from preset |
| CLI preview flags | Open Reviewer tab on startup with same clip selected |

Reviewer playback uses **saved preset only**. If a clip looks wrong here but pins look right in Pose Tuner, the bug is in **motion code** (`walk_arm_motion.gd`, `gather_arm_motion.gd`, idle phases) — not pin storage.

---

### Pose Tuner — editing behavior

| Behavior | Spec |
|----------|------|
| Default | Paused, Pose Tuner tab, idle for selected holdable |
| Row keys **1 / 2** | Switch active pose row; **commit previous row** before switch |
| ▶ Play | Preview motion for **current variant**; does not change saved row |
| Walk **A / D** | Travel facing + walk preview (Reviewer uses clip loop instead) |
| **Save all** | Commit active row + shared anchors (shoulders, head, arm lengths) → disk |
| **Reset pose** | Reset **active variant row only** to defaults; requires Save all to persist |

**Status bar must always show:** holdable · variant · **active pose row** (e.g. `Walk 1 · Pose 2 · pull`) · saved/dirty.

---

### What we are moving away from

| Old pattern | Reliable replacement |
|-------------|---------------------|
| Bend sign drives IK when pole exists | Pole always wins when non-zero |
| `mode + bool` scatters commit routing | Explicit `row_id` + `commit_row_pins` |
| Drag writes pull fields, Save writes pose A fields | Same row id for drag and Save |
| “Feels saved” after tab switch | Dirty flag until **Save all** |
| JSON export as partial mirror of `.tres` | Export ≡ disk schema per row |
| Seed copies idle → walk silently | Seed only if row unset **and** `*_saved == false` |

---

### Implementation checklist (agents)

When touching save/load or elbows, verify or implement:

- [x] `commit_row_hand_display_px` — single save path for hands per pose row
- [ ] Save all uses row id from UI, not inferred side effects *(hands fixed; verify in tuner)*
- [x] `to_export_dict()` includes all pull-row fields + `*_saved` flags
- [ ] Headless round-trip test per row (`walk1_a`, `walk1_b`, `gather_reach`, `gather_pull`)
- [ ] Reviewer code path has zero `preset.set_*` calls
- [ ] Unsaved indicator in status bar
- [ ] `lockin_*` scripts validate row bundles, not single fields

Until checklist is done, **workflow for humans:** edit one pose row → **Save all** immediately → **Reload** to confirm pins match disk before moving on.

---

## Procedural arm motion standards (authoring contract)

These rules apply to **any** holdable that uses procedural Line2D arms in the tuner (spear sun-shield idle today; club windup uses keyframes + Shift preview). Follow them for new idle variants, lookaround loops, and two-hand motion so animations stay **consistent**, **testable**, and **multiplayer-safe** (deterministic motion code + saved pins — not per-frame guessing).

### Core idea: authored poses, code-driven motion

| Layer | Who owns it | Where it lives |
|-------|-------------|----------------|
| **Rest + key poses** | You (drag pins) | `WeaponLimbPreset` fields in `<weapon>_clansmen_1.tres` |
| **Timing + phases** | Code | `scripts/tools/tuner_idle_preview.gd` (tuner) · `placeholder_card_service.gd` (in-game) |
| **Elbow arcs / no-flip** | Code + pole fields | `weapon_limb_preset.gd` · `procedural_arm_controller.gd` · `procedural_arm.gd` |
| **Verification** | Agent + CI | `tools/test_limb_tuner.gd` · holdable `audit_*` · `lockin_*` scripts |

**Do not** tune raise/lower by roulette — drag pins for **poses**, adjust **phase durations** in code if the loop feels slow/fast, adjust **sweep pole** if the forearm path is wrong.

### Two-pose scan authoring (sun-shield pattern)

Use when a loop needs **hand up + head scan** (forward → back → forward):

| Pose | Head | Off-hand (pin **2h**) | Shoulder (pin **2**) |
|------|------|------------------------|----------------------|
| **A** | Forward | `support_hand_idle_raise_offset_px` | `support_shoulder_idle_raise_offset_px` |
| **B** | Back | `support_hand_idle_raise_lookback_offset_px` | same raised shoulder |

**Tuner keys (spear Idle + `--spear-preview`):**

| Key | Mode |
|-----|------|
| **1** | Pose A — hand up, head forward (drag **2h**, **2**) |
| **2** | Pose B — hand up, head back (drag **2h**) |
| **▶ Play** or `--spear-idle-play` | Full loop (raise → scan → lower → rest) |

After each pose: **Save all** → optional **Copy for chat** for handoff.

**Scan loop phases (code — do not duplicate in bake yet):**

```text
REST (~3.5s) → RAISE (~0.9s) → HOLD + SCAN (A → B → A, ~3s per look)
→ brief hold at A (~1.1s) → LOWER (~1.05s, elbow-led) → REST
```

### Two-pose gather authoring (reach / pull pattern)

Use for **bend down + pick** loops (None / Axe / Pick / Oldowan · **Gather 1**):

| Pose | Body | Dominant hand **1h** | Support hand **2h** |
|------|------|----------------------|------------------------|
| **A — reach** | Bent (edit hold) | `gather1_hand_grip_offset_px` | `gather1_support_hand_offset_px` |
| **B — pull** | Bent (same) | `gather1_pull_hand_grip_offset_px` | `gather1_pull_support_hand_offset_px` |

**Tuner keys (None · Gather + `--gather1-preview`):**

| Key | Mode |
|-----|------|
| **1** | Pose A — reach down (drag **1h**, **2h**) |
| **2** | Pose B — pull toward body |
| **▶ Play** | Full loop: stand → bend → pick oscillation → stand |

Elbow poles: `gather1_weapon_elbow_pole_px`, `gather1_support_elbow_pole_px` (saved per pose row).

**Gather loop (code — `gather_arm_motion.gd`):**

```text
STAND → BEND IN (~20% cycle) → PICK (reach↔pull sine while bent, ~60%)
→ BEND OUT → STAND
```

Canonical preset: **`none_clansmen_1.tres`** — copied to axe/pick/oldowan via `lockin_gather_clansmen_1.gd`.

### Elbow rules (mandatory for raise/lower loops)

| Phase | Rule | Why |
|-------|------|-----|
| **Raise** | Forced elbow follows **rest → front waypoint → raised** bezier; sweep pole pushed **toward body center** (+X for east-facing support arm) | Forearm **passes in front** — no IK flip mid-raise |
| **Scan hold** | Pole pick **locked** to mid-raise side; bend sign stays **rest** (`support_elbow_bend_sign_override`) | Head/hand slide must not flip elbow |
| **Lower** | **Elbow leads**, hand **lags** (`IDLE_LOWER_ELBOW_LEAD` / `IDLE_LOWER_HAND_LAG` in preset code) | Natural fold-down, not “dance hand” |
| **Rest after lower** | Elbow **pinned** to rest IK until next raise | **No post-lower flip** when phase ends |

**Pole fields (support / off-hand):**

| Field | Role |
|-------|------|
| `support_elbow_pole_idle_px` | Rest idle elbow hint |
| `support_elbow_pole_idle_raise_px` | Full raise elbow hint |
| `support_elbow_pole_idle_raise_sweep_px` | Mid-raise **in-front** hint (zero = auto from shoulder/hand midpoints) |

**Never** flip `support_elbow_bend_sign_raise_override` mid-raise/lower to “fix” the elbow — use sweep pole + forced arc instead.

### Measurement checklist (before lock-in)

1. **Play full loop** — `--spear-idle-play` or ▶ Play on spear Idle.
2. **Raise** — forearm crosses in front; no elbow pop at ~50% raise.
3. **Scan** — hand slides A↔B; head flips; elbow stable.
4. **Lower** — elbow drops first; hand follows; **no snap at rest**.
5. **West** — **A/D** to flip; mirror still reads; no double-flip.
6. **Headless** — `test_limb_tuner.gd` + holdable audit + lockin script all **PASS**.

### Adding a similar animation (checklist)

1. Add preset fields in `weapon_limb_preset.gd` if new pose rows are needed.
2. Author rest + Pose A + Pose B in tuner; **Save all**.
3. Wire variant in `tuner_idle_preview.gd` / `placeholder_card_service.gd` if new timing.
4. Add `_test_*` cases in `tools/test_limb_tuner.gd` (rest/raise/lower endpoints, no flip invariants).
5. Add `audit_*` + `lockin_*` constants for the holdable.
6. Document locked values in this guide (copy club/spear session format).

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

| Weapon | **3** (yellow) | **1h** (green) | **Angle spin** |
|--------|----------------|----------------|----------------|
| **Club — Club grip** category | **Draggable** — sets grip on shaft art | Body hand (when visible) | Saves `idle_club1_rotation_deg` |
| **Club — carry / walk** | **Follow-only** — locked to saved grip px on weapon art; moves only with overlay + body bounce | **Draggable** — moves carry pose (overlay aligns on drag only) | Saves per active row (`walk1_rotation_deg`, etc.) |
| **Spear — Attack windup** | **Y1** + **Y2** on shaft art | **1h** / **2h** stack on yellow while editing | Saves `attack_rotation_deg` |

**Copy for chat** includes `grip_on_art_px`, `club_carry_body_hand_px` (club), `hand_1_role`, and `rotation_deg` per pose row. **Save all** and **Copy for chat** both commit the active row first.

### Canvas / pins

| Pin | Label | Action |
|-----|-------|--------|
| Dominant shoulder | **1** | Drag |
| Dominant hand | **1h** | Drag |
| Support shoulder | **2** | Drag |
| Support hand | **2h** | Drag |
| Weapon | **3** | Drag |
| Head / neck | **H** | Drag (head↔body distance) |
| Elbow bend | **1e / 2e** | **Right-click** to flip ± (plain click does nothing — avoids accidents) |

**Draw order (tuner):** arm1 → body → head → arm2.

### Preview controls

| Variant | Preview |
|---------|---------|
| Idle / Idle 1 / Gather | **▶ Play** / **⏸ Pause** |
| Walk / Walk 1 | **A / D** or **← / →** |
| Attack windup | **Shift** ready · **Shift + click** strike/thrust |

### Practical combo (club strike test)

Default tuner startup opens **Club · Idle standing** for windup/strike testing:

1. **A / D** or **← / →** on **Idle** — walk bounce (like in-game; club carry: weapon arm idle, off-arm swings)
2. **Shift (hold)** — **windup loop** plays (rest → A → B → rest from saved keyframes)
3. **Shift + click** — attack swing (from current loop frame)

Use **Idle standing** or **Club grip** — not Attack pin-edit (that mode is for dragging pins; test swings here on Idle). Attack category: **W/S/Q/E** pans the canvas; **A/D** still turns.

**Notes:** Windup idle loop (Attack category **▶ Play**) is separate — it does not run on Shift during Idle/Walk, so strike testing stays stable. WASD pans the canvas in Attack category only; it is not walk.

### Instrumentation (verify walk + strike)

Run with **`--tuner-instrument`** to print a live HUD line and append JSONL to `Tests/logs/tuner_preview_instrument.jsonl`:

```bash
godot --path . res://scenes/tools/LimbTuner.tscn --tuner-instrument
```

| Check | Pass signal |
|-------|-------------|
| Walk | `walk=on`, `body_y` changes, no `walk_moving_but_sprite_y_flat` |
| Shift ready | `combat=READY`, `handΔ` ≤ ~3 px, overlay near saved `ready_offset_px` |
| Shift+click | `overlay=STRIKING`, hand tracks overlay during arc |

Headless: `godot --headless -s res://tools/test_limb_tuner.gd` includes walk bounce + combat arm pin tests.

---

## Club evaluation session (ready now)

**One command (tests + GUI + instrumentation):**

```bash
bash tools/run_limb_tuner.sh evaluate
```

**Preset under test:** `assets/limb_presets/club_clansmen_1.tres`  
**Startup:** Club · **Idle standing** (not Attack pin-edit).

### What to verify (visual sign-off)

| Step | Control | Pass if |
|------|---------|---------|
| 1 | **A / D** walk | Club carry bounces; off-arm swings; yellow **3** stays on club grip art (locked to overlay; bounces with body, no extra weapon lag) |
| 2 | **Shift** hold | Windup loop (rest → A → B → rest, ~5s); yellow **3** on grip art; green **1h** at body hand (not stacked on yellow); both arms track |
| 3 | **Shift + click** | Strike tweens to saved peak (~73° club angle); yellow **3** never leaves grip; arms follow through peak |
| 4 | Release **Shift** after swing | Returns to idle carry (not stuck in ready) |
| 5 | **A/D** while facing west | Mirror flip; green **1h** at body hand; yellow **3** on grip art; club angle spin works |

### Headless gates (agent / CI)

```bash
bash tools/run_limb_tuner.sh verify          # full limb tuner + bake + CLI smoke
bash tools/run_limb_tuner.sh evaluate        # verify subset + club audit + GUI
godot --headless -s res://tools/audit_club_lockin.gd
```

| Gate | Pass signal |
|------|-------------|
| `test_limb_tuner.gd` | prints `test_limb_tuner: PASS` |
| `audit_club_lockin.gd` | `club_lockin_audit: PASS` or `PASS_WITH_WARNINGS` |
| `--tuner-instrument` | JSONL at `Tests/logs/tuner_preview_instrument.jsonl`; `handΔ` ≤ ~3 px during strike |
| `--tuner-pin-instrument` | JSONL at `Tests/logs/tuner_pin_sync_instrument.jsonl`; logs drag start/end + any **green 1h** sync overwrite (Δ > 2 px = violation) |
| `test_tuner_pin_snap.gd` | Headless drag → commit → sync; must print `test_tuner_pin_snap: PASS` (club walk1, club idle, none walk1) |
| `test_tuner_startup_no_clobber.gd` | Relaunch seeds must **not** overwrite saved pose rows (club walk, walk1, gather1) |
| `test_tuner_save_playback_guard.gd` | Commit/Save while Walk 1 ▶ Play must **not** change locked Pose A; Save writes **only dirty** holdables |
| `lockin_walk_clansmen_1.gd` | Restores Walk 1 Pose A+B on `none_clansmen_1.tres`; run after drift or before sign-off |

### Startup seed guard (relaunch safety)

**Problem we fixed:** Opening `--club-walk-edit` / `--club-walk-preview` used to copy **empty-hands** hand coords over your saved club carry.

**Contract (all animations):**

1. **`seed_*` functions** only fill **blank** fields when the pose row is **not** marked saved (`walk1_pose_a_saved`, `gather1_reach_saved`, etc.).
2. **Never import** from another preset (e.g. `none_clansmen_1`) when the target row is already saved on disk.
3. **`sync_*` on the same preset** may repair drift (e.g. club Walk 1 dominant ← idle carry) but only when values actually differ.
4. **Save all** commits the active row only when you **edited pins** (`Save all ●`); pauses playback first; writes **only holdables you changed** — use **Reload** to discard RAM edits without saving.

### Save / playback guard (Pose row safety)

**Problem we fixed:** Walk 1 **Pose A** was overwritten when **Save all** or drag-commit read pin positions **during ▶ Play** or **A/D travel** (animation frames, not Pose 1 rest pins). Saving **Club** could also flush an unedited **None** preset from RAM.

**Contract:**

1. **Pause first** — any commit or Save pauses ▶ Play and A/D walk, then snaps pins to the current pose-edit row.
2. **No commit without edits** — if you did not drag pins (`Save all ✓`), commit is skipped; locked rows stay as on disk.
3. **Dirty-only disk write** — Save all writes only holdables marked dirty this session, not every preset loaded into memory.
4. **Restore locked walk** — `godot --headless -s res://tools/lockin_walk_clansmen_1.gd`

Regression: `godot --headless -s res://tools/test_tuner_save_playback_guard.gd`

Guard helper: `scripts/tools/tuner_pose_seed_guard.gd` · relaunch regression: `godot --headless -s res://tools/test_tuner_startup_no_clobber.gd`

**Pin snap fix (2026-08):** After you drag **green 1h** while paused, the handle stays authoritative until **Play** or you switch pose/weapon. Per-frame sync skips repositioning the dominant hand so it does not snap back. Yellow **3** still follows club grip art during green drags (expected, not logged as a violation).

Launch with pin logging:

```bash
bash tools/launch_tuner_mac.sh --club-walk-edit --tuner-pin-instrument
godot --headless -s res://tools/test_tuner_pin_snap.gd
```

### Known warnings (non-blocking)

- Attack row `support_hand_offset` may differ from windup loop key A — Shift-ready uses attack row; loop uses A/B keys.
- Walk row may borrow idle carry until Walk category is tuned separately.

### After evaluation

- **Looks good** → note in chat; optional **Save all** if you moved pins; agent can wire in-game parity check.
- **Grip drifts** → say which phase (walk / windup / strike / recover); do not tweak numbers blind — use pin drag + Save all.
- **Re-edit windup keys** → launch with `--club-windup-edit` (Attack category, pin editing).

### Locked in (clansmen_1 club)

**Preset:** `assets/limb_presets/club_clansmen_1.tres`  
**Headless save:** `godot --headless -s res://tools/lockin_club_clansmen_1.gd`

| Phase | What was saved | Key fields |
|-------|----------------|------------|
| **Idle carry** | Standing club at side | `overlay_offset_idle_px`, `hand_grip_offset_px`, `support_hand_idle_offset_px`, `idle_club1_*` grip row |
| **Windup loop** | Shift hold — rest → A → B → rest (~5s) | `club_windup_idle_key_a/b_*`, `ready_offset_px`, `hand_grip_ready_offset_px` |
| **Strike** | Shift+click keyframed peak | `strike_offset_px`, `attack_rotation_deg` (73°), windup seam = key B |

Off-hand at strike peak uses idle rest (minimal motion) until re-authored on pin **2h** in Attack row.

---

## Spear tuning session (locked — Aug 2026)

**Preset:** `assets/limb_presets/spear_clansmen_1.tres`  
**Headless save:** `godot --headless -s res://tools/lockin_spear_clansmen_1.gd`  
**Audit:** `godot --headless -s res://tools/audit_spear_tuning_ready.gd`

### One command (tests + GUI)

```bash
bash tools/run_limb_tuner.sh spear-evaluate
# macOS GUI + idle loop:
bash tools/launch_tuner_mac.sh --spear-preview --spear-idle-play
```

### CLI entry points

| Flag / mode | Use |
|-------------|-----|
| `--spear-preview` | Spear · Idle — pin edit + Shift ready/thrust |
| `--spear-idle-play` | ▶ Play **Idle1** sun-shield loop (raise → scan → lower) |
| `--spear-pose-b` | Jump to **Pose B** edit (key **2** — hand up + head back) |
| `--spear-windup-edit` | Attack row — drag Y1/Y2 on shaft |
| `spear-prep` | Headless: seed walk/windup defaults, save `.tres` |
| `lockin_spear_clansmen_1.gd` | Headless: persist **all** locked spear rows (idle + attack) |

**Note:** Spear catalog shows **Idle** (one variant). Lookaround + sun-shield uses **idle1** motion internally when Play / `--spear-idle-play` is active — same pins, livelier loop.

### What to verify (visual sign-off)

| Step | Control | Pass if |
|------|---------|---------|
| 1 | **▶ Play** or `--spear-idle-play` | Full sun-shield cycle; raise sweeps **in front**; lower elbow-led; **no flip at rest** |
| 2 | Key **1** / **2** | Pose A/B hand positions save independently; Save all persists both |
| 3 | **A / D** walk | Spear carry bounces; yellow **3** on shaft; green **1h** stacked |
| 4 | **Shift** hold | Two-hand ready; Y1 + Y2 on shaft |
| 5 | **Shift + click** | Thrust to `strike_offset_px`; grip pins glued |
| 6 | **A/D** west | Mirror OK; pin stack reads |

### Headless gates

```bash
bash tools/run_limb_tuner.sh verify
godot --headless -s res://tools/lockin_spear_clansmen_1.gd
godot --headless -s res://tools/audit_spear_tuning_ready.gd
```

| Gate | Pass signal |
|------|-------------|
| `lockin_spear_clansmen_1.gd` | `lockin_spear_clansmen_1: PASS` |
| `audit_spear_tuning_ready.gd` | `spear_tuning_audit: PASS` |
| `test_limb_tuner.gd` | `_test_idle_arm2_raise_preview` + spear pin tests |

### Locked in (clansmen_1 spear)

| Phase | What was saved | Key fields |
|-------|----------------|------------|
| **Idle carry** | Standing spear at side | `overlay (63.5, -116)`, shaft grip `(4.97, 101.06)`, off-hand rest `(-11.6, 41.8)`, `support_elbow_pole_idle (-111.3, -176.5)` |
| **Idle sun-shield rest→raise** | Off-hand + shoulder raised | `support_shoulder_idle_raise (-126.7, -154.1)`, `support_hand_idle_raise (-21.4, -374.5)` |
| **Idle sun-shield Pose B** | Hand up + head back | `support_hand_idle_raise_lookback (-143.8, -369.6)` |
| **Elbow arc (raise)** | In-front sweep | `support_elbow_pole_idle_raise (-187.3, -257.7)`, `support_elbow_pole_idle_raise_sweep (40, -128)` |
| **Walk / Walk1** | Carry seeded from idle | walk overlay/grip rows |
| **Windup (Shift)** | Two-hand ready | `ready (113.5, -17)`, `hand_grip_ready`, `support_hand (7.5, 205.6)` |
| **Thrust** | Keyframed peak | `strike (173.8, -47.0)`, `attack_rotation_deg 81°` |

Motion code (shared tuner + in-game): `tuner_idle_preview.gd`, `procedural_arm_controller.gd`, `weapon_limb_preset.gd` (`resolve_support_elbow_display_for_idle_raise/lower/rest`).

---

## Walk 1 tuning session (locked — Aug 15 2026)

**Status: LOCKED.** Empty-hands Walk 1 on `none_clansmen_1` only. **Ask the user before changing poses, elbows, or walk timing.** Club/spear/axe/pick use their own preset files (see Club Walk 1 below).

**Canonical preset:** `assets/limb_presets/none_clansmen_1.tres`  
**Headless save:** `godot --headless -s res://tools/lockin_walk_clansmen_1.gd`  
**Motion:** `scripts/systems/walk_arm_motion.gd`

### Timing (do not change without asking)

| Rule | Value |
|------|--------|
| Clock | Body `bounce_time` (same as card bob) |
| Arm cycle | **2** body bounces per Pose 1 → Pose 2 → Pose 1 (`BOUNCE_CYCLES_PER_ARM_CYCLE`) |
| Blend | Cosine pendulum `(1 - cos) / 2` — no smootherstep |
| Alternation | In the two poses (same phase for both arms) |

### Preview

```bash
bash tools/launch_tuner_mac.sh --walk1-preview
bash tools/launch_tuner_mac.sh --walk1-edit              # Pose 1
bash tools/launch_tuner_mac.sh --walk1-edit --walk1-pose-2  # Pose 2
```

### Locked poses (none / clansmen_1)

| Pose | 1h | 2h | 1e pole | 2e pole |
|------|----|----|---------|---------|
| **1** | (228.27, 78.41) | (-170.74, 83.31) | (164.22, -46.08) | (-164.11, -56.54) |
| **2** | (76.93, 97.59) | (5.51, 71.07) | (88.00, -41.98) | (-81.92, -38.28) |

Overlay: `(22, -34)` · elbows outward + · shoulders unchanged from idle.

---

## Club Walk 1 tuning session (Aug 2026)

**Preset:** `assets/limb_presets/club_clansmen_1.tres`  
**Design:** Weapon arm = **idle carry** (same as standing with club). Off-arm = **empty-hands Walk 1 Pose 1↔2 keyframe loop** during playback. Yellow **3** = saved grip on club art (follow-only). Green **1h** = body-card carry hand (draggable).

| Pin | Role |
|-----|------|
| **Green 1h** | Body-card dominant hand — drag to move whole club carry pose |
| **Yellow 3** | Grip on club shaft art — **locked** when grip is saved; follows club; arm IK endpoint |
| **Green 2h** | Off-arm swing tuning (Walk 1 row) |
| **1e / 2e** | Elbow poles (right-click to flip) |

Dominant hand body coords live in `hand_grip_offset_px`. Grip-on-art lives in `idle_club1_hand_grip_offset_px` only (set in **Idle Club 1** / `--idle-club1-edit`). Never mix them.

### Launch

```bash
bash tools/launch_tuner_mac.sh --club-walk-edit              # Pose 1
bash tools/launch_tuner_mac.sh --club-walk-edit --club-walk-pose-2  # Pose 2
bash tools/launch_tuner_mac.sh --club-walk-preview           # loop
```

### Workflow

1. **Pause** walk (⏸) before dragging pins — drag on a playing walk auto-pauses.
2. **Pose 1** — drag **green 1h** (carry), **2h** (off-arm), **1e/2e**. Use **angle spin** when facing left to tilt the club.
3. Key **2** → **Pose 2** — tune **2h** and elbows again (dominant stays idle carry).
4. **▶ Play** — weapon arm holds carry; off-arm loops Walk 1 Pose 1↔2 like empty-hands walk; yellow **3** stays on shaft art.
5. **Save all** → **Copy for chat** → lock in.

**Note:** Club **Idle + A/D** still uses carry-at-side (legacy Walk row). **Walk 1** category uses off-arm keyframes + idle carry dominant arm. Set yellow grip in `--idle-club1-edit` if it drifts.

---

## Empty-hands idle (in progress — Aug 15 2026)

Same loop as spear sun-shield: off-hand raises, head scans, then lowers. **Dominant arm stays on normal idle rest.** Walk 1 is locked — do not change walk fields while tuning this.

**Preset:** `assets/limb_presets/none_clansmen_1.tres`  
**Preview:** `bash tools/launch_tuner_mac.sh --none-idle-play`  
**Edit:** `--none-idle-edit` (key **1** / **2** for raise forward vs look-back)

Not locked yet — tune **2h** / elbows, then lock-in when it looks right.

---

## Gather tuning session (locked — Aug 2026)

**Canonical preset:** `assets/limb_presets/none_clansmen_1.tres`  
**Also copied to:** `axe_clansmen_1.tres`, `pick_clansmen_1.tres`, `oldowan_clansmen_1.tres`  
**Headless save:** `godot --headless -s res://tools/lockin_gather_clansmen_1.gd`

### One command (tests + GUI)

```bash
bash tools/run_limb_tuner.sh gather-evaluate
# macOS:
bash tools/launch_tuner_mac.sh --gather1-preview
```

### CLI entry points

| Flag | Use |
|------|-----|
| `--gather1-preview` | None · Gather 1 — ▶ Play full pick loop |
| `--gather1-edit` | Gather paused at bent reach pose |
| `--gather-pose-pull` | Start on Pose B (pull) edit |
| `gather-lockin` | Headless save none + tool holdables |

### What to verify (visual sign-off)

| Step | Control | Pass if |
|------|---------|---------|
| 1 | **▶ Play** | Stand → bend → hands pick reach↔pull → stand; body/head bend smooth |
| 2 | Key **1** / **2** | Reach vs pull hand positions save separately |
| 3 | **Pause** + drag **1h/2h** | Pose updates at bent hold; Save all persists |
| 4 | **A/D** | Facing flip; gather bend preserved |

### Headless gates

```bash
bash tools/run_limb_tuner.sh verify
godot --headless -s res://tools/lockin_gather_clansmen_1.gd
godot --headless -s res://tools/audit_gather_tuning_ready.gd
```

| Gate | Pass signal |
|------|-------------|
| `lockin_gather_clansmen_1.gd` | `lockin_gather_clansmen_1: PASS` |
| `audit_gather_tuning_ready.gd` | `gather_tuning_audit: PASS` |
| `test_limb_tuner.gd` | `_test_gather_motion_smooth`, `_test_gather_preset_lockin` |

### Locked in (clansmen_1 gather)

| Pose | Key fields |
|------|------------|
| **Reach (A)** | `gather1_hand_grip (219.6, 66.5)`, `gather1_support_hand (-95.9, 59.9)` |
| **Pull (B)** | `gather1_pull_hand_grip (123.0, -52.9)`, `gather1_pull_support (-11.0, 33.4)` |
| **Elbows** | `gather1_weapon_elbow_pole (150.7, -185.9)`, `gather1_support_elbow_pole (-111.3, -176.5)` |

Motion code: `gather_arm_motion.gd`, `tuner_gather_preview.gd`, `limb_tuner_rig.gd` (`_apply_gather_hand_motion`).

---

## Facing & mirror standards (canonical)

**Goal:** one clear rule set so nobody double-flips a layer, stores coords in the wrong space, or expects draw order to swap when turning around.

### Direction model

| Rule | Value |
|------|--------|
| Facing count | **2** — East (right) and West (left) only |
| Authoring direction | **Always East** — pins, `.tres` coords, baked clips |
| West in-game / preview | **Mirror** via `Sprite.flip_h` on the card root — not separate west art (unless noted below) |

This matches RimWorld / Stoneshard-style side view: one east-facing pose set, horizontal flip for the other side. **No 4/8-direction bakes** in v1.

### Single facing authority

```
Card Sprite (root)
  flip_h = false  →  facing East (stored pose reads as authored)
  flip_h = true   →  facing West (mirror entire rig subtree)
```

**Only the card root `Sprite.flip_h` decides left/right.** Child layers must not independently `flip_h` or `scale.x = -1` when the parent is already flipped.

| Layer | On facing change |
|-------|------------------|
| Card `Sprite` | **`flip_h`** toggles — **logical facing flag** (card texture is null on mannequin) |
| Body texture (`BodySprite`) | **`flip_h = card Sprite.flip_h`** — sprite mirrors itself (parent flip does not affect children) |
| Head texture (`HeadSprite`) | **`flip_h`** from travel facing + idle look-around (see `TunerBodyVisual._resolve_head_sprite_flip_h`) |
| Head pivot position | Neck socket **X negated** when facing west so head stays on mirrored body |
| Shoulder / hand / weapon pin positions | Stored in **east display space**; runtime applies `LimbPresetCoords.flip_display_x()` when `flip_h` |
| Weapon overlay offset | Stored **unflipped**; `sync_weapon_overlay_flip()` mirrors on facing change |
| Elbow bend sign (`1e` / `2e`) | Stored as east-facing override; **`resolve_elbow_bend_sign()` mirrors the sign** when `flip_h` |
| Walk bounce / torso sway | **Sign inverts** with direction (`tilt_sign`, travel direction) — not a texture flip |
| Pin labels **1 / 1h / 2 / 2h / 3** | **Fixed** — dominant arm is always “1”, support is “2”, weapon is “3”; labels do **not** swap when facing changes |

### Draw order — fixed stack (recommended)

```
back arm (arm1) → body → head → front arm (arm2)
```

**Do not swap z-order when `flip_h` changes.**

Why: industry default for 2-way flip sprites (RimWorld-style pawns, many pixel RPGs). Mirroring already moves each arm to the correct screen side; swapping layers adds flicker, complicates bake capture, and fights IK pin numbering. Tune poses so the crossing reads acceptably **both** ways — support arm in front (`arm2`) is intentional for club/spear grips.

**Exception (future):** if a holdable must always draw in front (e.g. huge shield), bump **weapon overlay** z-index — not arm layer swap.

### What gets mirrored vs what gets sign-flipped

| Kind | Mirror (`flip_h` / flip X coord) | Sign flip only |
|------|----------------------------------|----------------|
| Body / head **silhouette** (symmetric blank) | Yes | — |
| Pin positions (shoulders, hands, weapon) | Yes (via coord helper) | — |
| Weapon overlay position | Yes | — |
| Elbow bend direction | Yes (stored override mirrors) | Auto default from facing |
| Walk sway, head bob phase | — | Yes (direction ±1) |
| **Asymmetric** cosmetics (hair part, scar, one-shoulder cloak, text) | **No** — separate east-only art or runtime attach rules | — |

### Asymmetric art policy (recommended)

**Mirror is OK for most layers.** Add **separate east-authored** (or attach-side rules) only when mirror looks wrong: hair part, face markings, readable text, one-sided gear. Genetics/cosmetics stack on top per [pawn_goal.md](pawn_goal.md) — they inherit the same root `flip_h`; asymmetric pieces opt out of mirror individually later.

### Facing during preview / gameplay (tuner = in-game rules)

The tuner must mirror **CombatComponent** / **WeaponOverlayCombat** — not a separate “editor only” facing model.

| State | What sets facing | In-game same? |
|-------|------------------|---------------|
| Idle / idle club | **A/D** — walk while held; release → idle bob | Yes |
| Walk / Walk 1 (pin edit row) | **A/D** — same walk preview | Yes |
| Gather (`Gather 1`) | **A/D** — turn facing; gather bend preserved | Yes |
| Attack — **editing pins** (no Shift) | **A/D** — flip to verify windup pose east **and** west | Yes (manual aim left/right) |
| Attack — **Shift ready** | **Cursor aim** updates `flip_h` + overlay ready pose | Yes (`enter_ready` / `update_ready_aim`) |
| Attack — **mid swing / thrust / recovery** | **Locked** to strike aim for that swing | Yes (`commit_strike` locks direction) |
| Idle/walk — **Shift ready** | **Cursor aim** (or velocity if moving) | Yes |

**Not in-game:** WASD during Attack category moves the **mannequin on the canvas** for framing only — it does not change pawn facing in Main.

Process order: rig updates `flip_h` first (`process_priority -1`); tuner syncs handles after (`0`).

### Storage & bake contract

1. All pin offsets in `WeaponLimbPreset` / pose snapshots = **east-facing display pixels** (unmirrored).
2. Baked clips = **east only**, 128×128 (see Bake pipeline above).
3. Never save world/global positions into `.tres` — always display-local east space.
4. Elbow **1e/2e**: **Right-click** to flip; saved **pole px** is authoritative for each pose row (walk Pose 1 vs Pose 2, gather reach vs pull). Bend sign stays synced as fallback only.

### Common mistakes (avoid)

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Expecting parent `Sprite.flip_h` to mirror `BodyVisual` | Body/head never turn — arms still flip | Set **`BodySprite.flip_h`** / **`HeadSprite.flip_h`** from card facing |
| Head `scale.x = -1` **and** sprite `flip_h` | Head double-flips | Head pivot scale stays `(1, 1)`; use **`HeadSprite.flip_h`** only |
| Storing west coords in `.tres` | Pins jump when facing changes | Save east space only |
| Expecting pin **1** to become support arm when west | Confusion in UI | Labels are role-based, not screen-left/right |
| Swapping arm z-index on flip | Flicker, bake mismatch | Keep fixed arm1 → body → head → arm2 |

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

See **[reliability contract](#tuner--animation-reviewer--how-they-should-work-reliability-contract)** for how rows should commit and round-trip. Today: disk is truth only after **Save all** + successful reload.

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
| Idle loop phases | `scripts/tools/tuner_idle_preview.gd` |
| Elbow IK + arcs | `scripts/systems/procedural_arm_controller.gd`, `procedural_arm.gd` |
| Spear lock-in | `tools/lockin_spear_clansmen_1.gd` |
| Gather lock-in | `tools/lockin_gather_clansmen_1.gd` |
| Gather motion | `scripts/systems/gather_arm_motion.gd` |
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
- [x] `commit_row_hand_display_px` / `commit_row_hand_pins_from_global` — hands save to pull rows on Save all
- [ ] `commit_row_pins` — elbows + overlay in same row bundle (hands done; full row helper optional)
- [ ] Round-trip headless tests for `walk1_a`, `walk1_b`, gather reach/pull
- [x] Full `to_export_dict()` parity with `.tres` pull rows + `*_saved` flags
- [ ] Reload confirms when staged ≠ disk

### A2 — UI/UX improvements (intuitive tuning workflow)

**High priority (prevent mistakes):**

- [ ] **Status bar active row display** — always show: `Holdable · Category · Variant · Pose row · ● Unsaved` (e.g. `Club · Walk 1 · Pose 2 (pull) · ● Unsaved`)
- [ ] **Reload confirmation** — "Reload will discard staged changes. Continue?" when dirty
- [ ] **Dim/disable irrelevant controls** — Save all disabled when nothing dirty; row keys (1/2) hidden when variant has single pose; Play hidden on Attack category
- [ ] **Reviewer pins read-only** — hide or ghost pins (50% opacity, no drag) in Animation Reviewer tab to prevent confusion
- [ ] **Keyboard shortcut overlay** — toggle with `?` or F1 showing: row keys (1/2), facing (A/D), play (Space), combat (Shift / Shift+click), zoom (scroll)

**Medium priority (reduce confusion):**

- [ ] **Elbow drag feedback** — "Right-click to flip elbow" tooltip on 1e/2e hover; pole position updates visible
- [ ] **Copy for chat confirmation** — brief status: "✓ Committed active row + copied JSON to clipboard"
- [ ] **Morphology section organization** — group spinboxes: Arm length (upper/lower), thickness, body scale X/Y, head scale; **Save DNA** button below

**Lower priority (polish):**

- [ ] **Undo/redo** — Ctrl+Z / Ctrl+Shift+Z for pin changes (store recent snapshots per row)
- [ ] **Visual diff overlay** — "Show changes since last save" — ghost pins at disk positions while editing
- [ ] **Better error messages** — when Save all fails, show specific reason (file locked, parse error, etc.)

**Anti-patterns (do not implement):**

- ❌ Auto-save without opt-out (breaks reliability contract)
- ❌ Multiple windows or floating panels (keep one panel)
- ❌ Editable Reviewer tab (read-only inspect is intentional)

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
9. **Authored poses, code-driven loops** — save key poses in `.tres`; phases, elbow arcs, and scan timing live in shared motion code (see **Procedural arm motion standards**).
10. **Elbow stability** — no bend-sign flips mid-raise/lower; use sweep poles + forced arcs; pin rest elbow after lower.
11. **Reliability contract** — Reviewer read-only; Pose Tuner writes via explicit row id; **Save all** = disk; pole authoritative for elbows (see dedicated section).

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

Split motion from shape/look, then grow character creation on top of that split.

That’s what animation_tuner.md is asking for. The code is halfway there.

How the tuner actually works
Think of it as three layers:

1. You drag poses.
Pins (1, 1h, 2, 2h, 3, H, 1e/2e) write numbers into a WeaponLimbPreset file like none_clansmen_1.tres. Those numbers are east-facing display pixels in a 128px-tall card space.

2. Code plays the loop.
Play does not store every frame. It lerps between saved poses on a timer:

Loop	Poses you save	Code that plays them
Walk 1
Pose 1 + Pose 2
walk_arm_motion.gd
Gather
Reach + pull
gather_arm_motion.gd
Spear idle
Rest / raise / look-back
tuner_idle_preview.gd
Club windup
Rest → A → B
tuner_windup_idle_preview.gd
3. Save / bake / game.
Save all writes the .tres + neck layout. Bake clip records the same live rig into a PNG strip. Main today uses the layered body+head + floating weapon, not the tuner’s arm lines.

The UI is one panel: Holdable → Category → Variant → Play → drag → Save. Catalog lives in character_animation_catalog.gd. That’s the character-creator shell already.

You (pins) → WeaponLimbPreset (.tres)
                ↓
         LimbTunerRig (live preview + IK arms)
                ↓
         Bake PNG  OR  Main mannequin (no arm lines yet)
What’s already solid vs what’s missing for DNA
Solid (keep this contract):

One pose row per variant. Don’t leak Walk into Idle.
East-only authoring. West = flip.
Lock-in scripts + test_limb_tuner.gd as the “it really saved” gate.
Gather / spear idle already prove the two-pose workflow.
Not DNA-ready yet:

Arm length and thickness still live inside every weapon .tres. Genetics needs one shape file for all holdables.
CharacterAppearance is a stub (preset_id, a scale vector, hair/weapon ids). No character_builds/ folder. No Save DNA button.
bible/.../genetics.md is a sim draft (body size, cold resistance). It is not wired to the tuner.
Bake exists. Main does not play baked strips yet (BakedPawnPlayer is planned).
limb_tuner.gd is huge (~4k lines). That’s the reliability risk, not the idea.
pawn_goal.md wants: modular layers on pivots + genetics for look + motion from one rig. The tuner guide agrees: author motion at reference size (1.0). Genetics changes shape and face at spawn. Don’t bake a unique walk per person.

How this becomes a character creator (DNA backbone)
Treat two save types as law. Everything else hangs off that.

File	Owns	Example
Pose preset
How they move / hold a tool
spear_clansmen_1.tres — grips, walk poses, elbows
DNA / build
How they’re shaped
assets/character_builds/reference.tres — arm length, body/head scale, neck
Layout
Default art sockets
layered_blank_1.tres — neck on body1.png
Genotype (later)
Born numbers
body_size, brow, hair_id → builds the appearance, doesn’t store walk pins
Character creator = tuner panel + DNA file. Same window. New section: sliders for body/head scale, then later eyes/hair/skin. Not a second app.

At spawn:

species means + parents
        ↓
  genetics_profile  (numbers)
        ↓
  CharacterAppearance  (scale, layer ids, tints)
        ↓
  same walk/idle poses  (reference motion)
  + layered face/hair on HeadPivot
Hybrids need no extra walk art. A Neanderthal is a stockier build + brow/hair layers on the same Walk 1 clip.

How to proceed (efficient + reliable)
Do this in order. Don’t skip ahead to “full genetics sim” or “100 face parts.”

Phase 0 — Finish the motion lab (now)
You’re already here: empty-hands Walk 1 as the template.

One clock for body bounce and arm swing (bounce_time).
Pose 1 / Pose 2 are full-body snapshots (alternation in the poses, not a second arm-phase hack).
Lock-in + test before the next holdable.
Until walk feels natural, don’t add DNA sliders. Shape on a broken walk wastes time.

Phase 1 — Split shape from motion (this is the DNA backbone)
Smallest real character-creator step:

Grow CharacterAppearance into a real build: arm lengths, thickness, body scale, head scale, neck offset.
Save DNA writes assets/character_builds/reference.tres only.
Stop writing arm length into none_*.tres / spear_*.tres.
Tuner morphology row reads the build, not the weapon file.
That’s the reliability win: genetics later has one place to read shape.

Phase 2 — Live morphology in the same panel
Body/head scale spinboxes. Play walk at 0.85 / 1.0 / 1.15. See if hands still reach.

If 0.85 clips clothes later → size bands (Small / Ref / Large), not a unique bake per NPC.

Phase 3 — Cosmetics (the “creator” people see)
On HeadPivot: eyes, hair, skin tint. Grayscale art + color.
Do not bake faces into walk strips.
Pickers on the same left panel.

Phase 4 — Spawn from genes (thin slice)
One genetics_profile → appearance. Species means (Sapiens vs Neanderthal) for body_size + 2–3 face slots.
Do not implement ice-age selection yet. That’s a different system.

Phase 5 — One pawn in Main
Either play a baked walk or run the tuner motion code on one player pawn behind a flag. Measure FPS. Then decide bake vs live procedural. Don’t ship hundreds of IK arms first.

Rules that keep this from rotting
Poses in .tres. Timing in code. If the walk feels fast, fix the clock — don’t guess pin numbers.
One motion source. Bake is a recording of the tuner, not a second animation system.
Author at reference morphology. Genetics scales it.
East coords only. West is flip.
Lock-in + test for every locked pose. Chat JSON is a handoff, not the save.
Stop growing limb_tuner.gd. New loops go in small files (walk_arm_motion, gather_arm_motion). The app should only pick, drag, save.
Don’t copy walk from empty hands onto club/spear until empty-hands is signed off.
What I would not do next
A separate “character creator” scene (duplicates the tuner).
Baking one sheet per clansman.
Full evolution sim before appearance files exist.
8-direction art (docs say 2-way flip).
Putting DNA fields into six weapon presets.