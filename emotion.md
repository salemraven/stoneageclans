# NPC emoji face — build spec

**Status:** Design lock **2026-11-04**. **Not implemented.**  
**Purpose:** Stone-age **body language** on pawns — shared emoji-style **eyes + mouth** on the face, with a cheap **above-head icon** fallback when full face animation is off. Mood comes from the memory/moodle sim; the face **shows** it, it does not pick jobs.

**See also:** [bible/story_data.md](bible/story_data.md) §11 (moodles), [guides/character_layers.md](guides/character_layers.md) (LOD + layer stack), [guides/lag.md](guides/lag.md) (hero caps), [bible/genetics.md](bible/genetics.md) (face genes), [bible/fight_or_flight.md](bible/fight_or_flight.md) (Fight / Flight HUD — separate from face presets).

**Code today:** Procedural eyes in `scripts/tools/tuner_body_visual.gd`. Genes → `scripts/genetics/phenotype.gd`, written at birth in `scripts/genetics/birth_engine.gd` (`eye_scale_mul`, `eye_aspect`, nose, brow). **No mouth layer yet.**

---

## Why this exists

Language is proto — calls, horn, showings, floating two-letter words. **Faces** are the always-on channel: everyone in every clan reads the **same** laugh, scowl, or fear. That matches “communication was basic” without giving each clan a private emoji set.

Nose and brow stay **genetic PNGs** (family look). Eyes and mouth stay **one shared painter** (universal read).

---

## Presentation: face first, icon fallback

| Band | Who | What the player sees |
|------|-----|----------------------|
| **Hero (LOD 0)** | Player, party, selected, nearby leaders — within hero cap | **Animated emoji face** on the head: procedural eyes + mouth; strongest moodle drives emotion preset; otherwise **genetic idle** mouth |
| **Near (LOD 1)** | Visible, not hero — e.g. camera distance **&lt; ~900 px** | **Fallback:** one **shared-atlas emoji** floating **above the head** (static or 2–3 frame loop). Same art language as the face presets |
| **Mid / far (LOD 2–3)** | e.g. **900–1400 px** and beyond | **No mouth animation, no floater** — body + head (+ weapon). Sim still has moodles; **Info tab** when opened |
| **Sleep / off-chunk** | Dormant NPC | **Zero** face nodes |

Automatic downgrade (no player setting):

```text
if hero_lod and under face_anim_budget:
    draw procedural face (emotion or idle)
elif near_lod and under icon_budget:
    draw one atlas icon above head (strongest moodle or neutral)
else:
    identity layers only (nose/brow/eyes optional per LOD table)
```

If the machine is over budget, **drop to icon** even for some heroes — same symbols, worse slot.

**Starting caps (tune in play):** ≤ **15–25** heroes at full face; ≤ **80** pawns with any cosmetic face/icon; align distance bands with `NPC_ARM_CULL_DISTANCE_PX` (~1400) and [character_layers.md](guides/character_layers.md) § Visual LOD.

---

## One language, genetics on baseline only

| | Shared (all clans) | Genetic (per person / family) |
|--|-------------------|------------------------------|
| Emotion presets | Laugh, smile, angry, scared (+ later scream) | Same shapes; **scale** with mouth size genes |
| Idle mouths | **6** reusable neutral presets (pool below) | **Which idle is default** + **mouth size** from genome |
| Eyes | Same oval painter + blink | `eye_scale_mul`, `eye_aspect`, pupil (shipped) |
| Nose / brow | Same file set | Which PNG (shipped) |

Genes **bias rest face and size**. They do **not** unlock private angry mouths or rival-only icons.

**Runtime nudge (later, optional):** Social or perks may **slightly** shift idle weights — small additive tweak on top of genome, not a second mouth art set.

---

## Eyes (keep as shipped)

- Soft white oval, reused pixels; genes stretch size and aspect.
- Pupil + optional glance; blink = **scale Y** + skin tint (no full repaint every frame).
- Emotion presets may narrow/widen eyes via parameters (angry narrow, scared wide) on **hero LOD only**.

Nose and brow: unchanged PNG stack on `HeadPivot`. Angry **brow** art can stay genetic; **angry eyes** are painter params.

**Z-order:** mouth sits in the face stack with eyes (see [character_layers.md](guides/character_layers.md) — ears, eyes, brows, **mouth**, beard).

---

## Mouth (procedural, all NPCs)

One painted mouth on the head, same technique as the eye oval.

| Parameter | Meaning | Update cost |
|-----------|---------|-------------|
| **Width** | Line width | Scale; cheap |
| **Openness** | Shut line → open gap | Scale animate (idle breathe, talk); cheap |
| **Curve** | Smile / flat / frown | **Repaint when preset changes** — not every frame |
| **Scream / teeth** | Open oval + inner marks | Repaint on enter/leave preset |

**Color:** lip tint from skin; dark interior when open.

**Every clansman has a mouth** at LOD 0. At lower LOD, mouth draw follows the face/icon rules above.

---

## Idle mouths (rest face)

When **no moodle owns the face** (or strongest moodle is below the face threshold — see Open items), show **idle**, not a blank line.

### Shared pool (v1 — six presets)

Fixed shapes in the same painter (IDs for data / atlas fallback):

| ID | Name (dev) | Read |
|----|------------|------|
| `idle_neutral` | Neutral | Flat closed line |
| `idle_soft_smile` | Soft smile | Closed upward curve, low openness |
| `idle_tight` | Tight | Thin closed line, slightly downturned |
| `idle_parted` | Parted | Small open oval, no teeth |
| `idle_pout` | Pout | Closed curve, pushed lower lip feel |
| `idle_relaxed_open` | Relaxed | Medium openness, soft curve |

More presets can be added later; keep the pool **small** and shared.

### Genetics: size

**Planned** (not in catalog yet) — mirror **eye size**:

- Loci: `mouth_size_a` … `mouth_size_d` (additive `M` / `m`).
- Phenotype: `mouth_scale_mul` **0.85–1.15** (and optional `mouth_width_mul` if width needs to diverge from height).
- Written once at birth → `genetics_profile` / appearance blob.
- Applied to **idle and emotion** presets so family mouths look related.

### Genetics: which idle is “theirs”

**Planned** loci: `mouth_rest_a` … `mouth_rest_d` (additive `R` / `r`) → score **0–1** “expressive rest tendency.”

At birth (deterministic from genome + entity id):

1. Map score to **weights** over the six idle IDs (low → tight/neutral; high → soft smile / relaxed open).
2. Pick **`idle_mouth_default_id`** once (weighted roll, seeded from genome hash).
3. Store on profile; **same person always returns to the same idle** when mood clears.

Siblings correlate; they are not clones unless weights and roll match.

### Idle animation (hero LOD only)

Optional slow **openness** pulse on the **same** idle preset (like blink). **No** curve repaint in idle loop. Mid/far: frozen idle or no draw.

---

## Emotion mouths (moodle / combat read)

**Starter set (v1)** — templates are **our** emoji-style art, not stock packs. **Art paths: TBD** in repo.

| Preset | Eyes | Mouth | Notes |
|--------|------|-------|-------|
| **Laughing** | Squeezed shut curves | Wide open smile, teeth | Tears arc **outward** from eye corners (not down cheek) |
| **Smiling** | Soft open | Closed upward curve | Low openness |
| **Angry** | Narrow | Closed downward tight curve | Brow PNG may reinforce V |
| **Scared** | Wide | Small open oval | Not full scream |

All use the **same painter**; only parameters + optional 2–4 frame tear atlas on heroes.

**Fight / Flight:** Combat HUD uses `!!!` / `!!` ([fight_or_flight.md](bible/fight_or_flight.md)). Face may map **Fight** → angry (or angrier variant) and **Flight** → scared when those states win the moodle stack — exact mapping in the moodle table (Open items).

Future: full **scream** preset with teeth (heavier repaint).

---

## Moodles → face (sim rules)

From [story_data.md](bible/story_data.md) §11 and RimWorld / DF practice (locked here):

1. **Stack cap:** Info tab shows ≤ **12** moodles, strongest first; repeats weaken.
2. **Strongest per category** for memories; face uses **one strongest moodle overall** for the face slot.
3. **Face = strongest only.** Weaker moodles stay on Info tab icons only — no mouth flicker for minor hunger if a stronger fear is active.

**Update rule:** Recompute face when moodle stack changes (event-driven), not every sim tick. Blink / idle breathe may still tick on heroes.

**Threshold (Open):** Minimum strength for a moodle to **replace idle** on the face vs icon-only — set when the moodle catalog is locked.

### Moodle → face preset table (to fill)

| Moodle (placeholder) | Face preset | Fallback atlas icon |
|----------------------|-------------|---------------------|
| … | … | … |

Build this row when §11 moodle list is finalized. Until then, implement **pipeline + four emotion presets + idle** with a stub mapper.

---

## Animation summary

| Effect | Method | LOD |
|--------|--------|-----|
| Blink | Eye scale Y | Hero |
| Idle breathe | Mouth openness scale | Hero |
| Emotion enter | Repaint mouth curve / eye params | Hero |
| Laugh tears | 2–4 frames, shared atlas | Hero |
| Talk / bark | Brief openness pulse | Hero |
| Above-head icon | 1 sprite or 3-frame loop | Near |

**Never:** per-NPC VideoPlayer; unique textures per mood; repainting every mouth every frame for the whole camp.

---

## Atlas and fallback icons

- **One small atlas** (or atlas region set): emotion icons + idle neutrals for above-head fallback.
- Face painter and floater **share icon IDs** so downgrade is visually consistent.
- Pool floating icon nodes; cap simultaneous **animated** icons (starting guess: same order of magnitude as near LOD pawn cap).

---

## Multiplayer

- **Server authoritative:** moodle stack / strongest moodle id (or compact bitmask + strengths) — same as memory doc policy (pull detail on Info open; broadcast **deltas** when strongest face driver changes).
- **Clients:** local LOD picks face vs icon vs nothing; **no** per-frame mouth texture sync.
- **Appearance:** mouth size + `idle_mouth_default_id` from genome at spawn — same as other face genes.

---

## Performance checklist

- Sim moodles for all relevant NPCs; **draw** face only for LOD 0 (+ icons LOD 1).
- Repaint mouth on **preset change** only.
- Chunk **sleep** = no face work ([character_layers.md](guides/character_layers.md)).
- Hard **face_anim_budget** and **icon_budget**; overflow → next cheaper band.

---

## Implementation checklist

| Step | Target |
|------|--------|
| Mouth painter | Extend `tuner_body_visual.gd` (or sibling node) — width, openness, curve presets |
| Preset tables | Resource or const map: idle IDs + emotion IDs → painter params |
| Profile fields | `mouth_scale_mul`, `idle_mouth_default_id`, optional width mul |
| Genetics | Add loci to `locus_catalog.gd`; `phenotype.gd` + `birth_engine._write_face` |
| Moodle hook | When strongest moodle changes → set face preset or clear to idle |
| LOD controller | With `CharacterVisualLOD`: hero face, near icon, else hide |
| Atlas | `assets/characters/FaceIcons/` (TBD) + registry |
| Info tab | Moodle icons unchanged; face independent |
| Tests | Headless smoke: spawn pawn, apply preset, no errors; optional golden hash for one preset |

**Layer doc:** [character_layers.md](guides/character_layers.md) § Emoji face LOD (added 2026-11-04).

---

## Open items (before art lock)

- Pixel anchor for mouth on `head1.png` (measure in tuner — no guessed offsets in code).
- Final **moodle → preset** table and face **strength threshold**.
- Whether **showings / bark** force a one-shot talk animation on all LOD 0 in range.
- Exact **face_anim_budget** / **icon_budget** numbers after 30–60 NPC stress test.
- Scream preset + teeth art pass.

---

## Not in v1

- Stock emoji textures as shipped faces.
- Per-clan emoji dialects.
- Face driving AI jobs (tallies and brain win over moodles).
