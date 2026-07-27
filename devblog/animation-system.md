# Bringing Clans to Life: Our New Animation System

**Stone Age Clans: The Dawn of Aggro-Culture** — devblog, July 2026

---

For a long time, our characters looked like what they were: flat cards sliding across the map. Fine for prototyping. Not fine for a game where a bad hunt, a rival raid, or grabbing a stick at the wrong moment should *feel* physical.

We’ve been rebuilding how characters move — not with giant sprite sheets, but with a **modular animation system** that makes clansmen bob, sway, grip, and strike while staying cheap to extend to new body types.

This post explains what changed, why it matters for gameplay, and how we can eventually support dozens of different silhouettes without redrawing walk cycles for every weapon combo.

---

## The old problem: animation doesn’t scale

Classic 2D games often animate like this:

```
idle_01.png, idle_02.png
walk_left_01.png, walk_left_02.png
club_attack_01.png, club_attack_02.png
spear_thrust_01.png …
```

Multiply that by **facing direction**, **weapon type**, and **body variant** (tall clansman, stocky hunter, child, elder) and you’re drowning in art before you’ve shipped one raid.

Stone Age Clans is built on **systems that interact** — drought, rival clans, predators, improvised weapons. Our animation pipeline had to match that philosophy: **one body, many poses, driven by data**, not by hundreds of hand-drawn frames.

---

## The new approach: card body + living limbs

Think of each character as a **puppet**:

| Layer | What it is | What moves |
|-------|------------|------------|
| **Body card** | Portrait-style torso art | Walk bounce, facing flip |
| **Weapon overlay** | Club, spear, axe — separate image | Aim, windup, strike, slight lag behind the body |
| **Procedural arms** | Math-drawn limbs (IK) | Shoulder → elbow → hand, bent toward grip points |

The body stays a single image. Arms are **solved every frame** with inverse kinematics (IK) — the same idea used in 3D games: you place where the hand should go, and the elbow bends naturally to reach it.

**Presets** (small data files) store where shoulders sit, where hands grip the weapon, and how the elbow should fold. The game reads those presets at runtime. No per-frame arm animation to sync.

```
Character walks
  → body bobs (sin wave)
  → weapon overlay lags slightly (weight)
  → arms swing on opposite phases (left forward, right back)
  → IK keeps hands on grip points
```

That’s why a clansman with a club no longer looks like a postage stamp on ice.

---

## What you’ll actually see in-game

### Walk cycle without walk sprites

We don’t have “walk frame 1 / walk frame 2” PNGs. Movement **feels** alive because of layered motion:

- **Body bounce** — subtle vertical bob while moving (~2.5px amplitude)
- **Arm sway** — arms swing forward and back on alternating beats (~24° arc), pivoted from the shoulder so they don’t “clap” inward
- **Weapon lag** — the club or spear trails the torso slightly, selling weight without full physics

All of this is **procedural** — same code, any body preset.

### Idle vs ready vs attack

Three pose families, stored per weapon + body:

| Mode | Feel |
|------|------|
| **Idle** | Relaxed carry — weapon low, off-hand on the body |
| **Walk** | Optional hand offsets; motion mostly from sway + bounce |
| **Ready / attack** | Shift-held stance, windup, thrust or swing |

Hold **Shift** and the grip shifts. Click and the weapon overlay plays a strike tween — **thrust** for spears, **swing down** for clubs. The support arm follows on spear thrusts (slight shoulder counter-motion) so two-handed grips read as coordinated, not glued on.

### Emergent stone-age moments

From our design bible: meeting another hominid can be life-or-death. An NPC might **pick up a stick and raise it**. With this system, that’s a **weapon overlay swap + preset load** — not a new character sprite. Equipment changes stay cheap and readable in isometric clutter.

---

## Why this scales to many body styles

Here’s the production win: **one preset file per body × weapon pair**.

```
assets/limb_presets/club_clansmen_1.tres
assets/limb_presets/spear_clansmen_1.tres
assets/limb_presets/none_clansmen_1.tres   ← empty hands
```

When we add `clansmen_2`, a shorter hunter, or a different silhouette:

1. Drop in new body/head art (layered blanks — body PNG + head PNG, neck socket on the body)
2. Open the **Character Animation Tuner**, drag handles to match the new proportions
3. Save — game loads the new `.tres` automatically

**Shoulders and arm lengths** are tuned once per body. **Hands and weapon position** can differ per mode (idle / walk / ready) without redrawing the torso.

We already have **18 clansmen card variants** in the registry. The path forward is preset files, not preset *animations*.

### Layered art = swap parts, not whole characters

For tuning we use a **layered mannequin**:

- `body1.png` + `head1.png` stacked at a neck socket
- Head bobs and tilts independently during walk preview
- Same limb math whether you’re previewing blanks or the real clansmen card

Different body build? New body texture + new shoulder offsets. Same arm code.

---

## The Character Animation Tuner

We built an in-editor tool so designers don’t guess coordinates in JSON:

**Godot:** `scenes/tools/LimbTuner.tscn` (Character Animation Tuner)

- Drag handles: **H** (neck), **1/1h/1e** (weapon arm), **2/2h/2e** (off arm), **3** (weapon overlay)
- Modes: **Assemble**, **Lock**, **Test** (Shift = ready, click = strike)
- Saves presets + body/head layout to disk
- Undo, mirror shoulder, copy idle → walk/attack, reach warnings

**Web preview:** `tools/card_tuner_web/` — browser tuner for quick shares and idle tuning. Godot remains source of truth for full walk/attack fields and combat testing.

Workflow: **tune → Save → commit → push**. Both tuners read the same `assets/limb_presets/*.tres` files. The game and the tools stay in sync.

---

## Multiplayer-friendly by design

Arms aren’t animated frame-by-frame over the network. Clients derive arm pose from **replicated state**:

- weapon equipped
- moving or idle
- facing / aim direction
- combat windup

Shared presets on disk mean everyone solves the same IK locally. Less bandwidth, fewer desyncs — important as we pivot to **multiplayer** (server-authoritative combat, client-side visual polish).

---

## Where this is heading

Today’s shipped step is intentional:

- **Static card body** in-game (readable silhouette)
- **Line2D procedural arms** (fast to iterate)
- **Weapon overlay combat** (thrust vs swing profiles)

Our longer-term vision (`bible/Phase4/rig.md`) is a full **transform-based modular rig** — chest, arm pivots, leg pivots, textured limb parts. The preset + IK work we’re doing now is the foundation: anchor points, mode separation, and tuning pipeline already exist.

Next horizons:

- Textured arm sprites instead of lines
- Genetics-driven arm thickness (`width_genetics_mult` is already in the config)
- More body cards → more preset files, not more sprite sheets
- Ritual animations, drums, shamans — the bible calls for a heavily animated, auditory world; this system is how we get there without exploding art scope

---

## Try it yourself

```bash
# Godot tuner (F6 on LimbTuner.tscn)
godot --path . res://scenes/tools/LimbTuner.tscn

# Web preview
python3 tools/card_tuner_web/server.py
# → http://localhost:8765/
```

Pull `main` for the latest club + none idle baselines.

---

## Bottom line

We’re not trying to make stone-age fighters look like a polished fighting game. We want them to look **alive, awkward, and physical** — carrying weight, shifting grip before a strike, swinging arms that actually connect to shoulders.

The new animation system is how we get that **without painting ourselves into a corner**. One body style down. Many more to come. Same tools, same math, new presets.

*The wilderness is harsh. At least our clansmen finally look like they’re struggling through it.*

---

**Further reading (repo):**

- `scenes/tools/README.md` — tuner usage and saved baselines
- `bible/Phase4/rig.md` — modular rig architecture vision
- `assets/limb_presets/README.md` — preset file format
