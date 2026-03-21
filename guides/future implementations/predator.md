# Predators — Enemy Wild NPCs

Plan for hostile wildlife that hunt prey, eat, and attack cavemen. First predator: **Wolf** (asset: `wolf1.png` in `assets/sprites/`).

---

## Design Goals

- Predators are **wild NPCs** (no clan, not herdable) that use the same NPCBase/CombatComponent/DetectionArea stack where it fits.
- They **eat** (prey kills, carrion) to stay alive or to drive behavior (e.g. hunger → hunt).
- They **attack other wild NPCs** (sheep, goats, etc.) as prey.
- They **attack cavemen** (player + clan NPCs) when hungry, territorial, or provoked.
- Stats and behavior should be easy to tune per species and to extend (bear, big cat, etc.).

---

## Assets

| Predator | Sprite | Notes |
|----------|--------|--------|
| Wolf     | `assets/sprites/wolf1.png` | First; pack-optional later |
| (future) | —      | Bear, big cat, etc. |

---

## Core Stats (per predator type)

Proposed fields — can live on a `PredatorType` resource or on the NPC.

| Stat | Wolf (example) | Description |
|------|----------------|--------------|
| **max_health** | 40–60 | Same as HealthComponent; wolves squishier than cavemen. |
| **damage** | 8–12 | Base damage per hit (no weapon; “bite”). |
| **attack_speed** | ~0.35s windup, ~0.6s recovery | Slightly faster than unarmed caveman. |
| **move_speed** | 1.1–1.3× base | Enough to catch sheep, not trivial to kite. |
| **detection_range** | 250–350 px | When to consider prey/cavemen (DetectionArea radius). |
| **attack_range** | 70–90 px | Melee bite; reuse CombatComponent. |
| **hunger** | 0–100, decay per second | Optional: drives “hunt” vs “wander” vs “eat”. |
| **fear_health_threshold** | e.g. 25% | Below this, may flee instead of fight (optional). |

We can add: armor penetration, bleed, pack bonus, etc. later.

---

## Behavior Overview

1. **Idle / Wander** — No target; maybe patrol or stand still.
2. **Hunt (prey)** — Target = wild animal (sheep, goat). Chase, attack, kill.
3. **Eat** — On prey/corpse: play eat animation, restore hunger, remove/corpse decay.
4. **Attack cavemen** — Target = player or clan NPC. Enter combat like any hostile; DetectionArea + combat state.
5. **(Optional) Flee** — Low HP or outnumbered; run away, drop target.

How they **choose** target (prey vs caveman) can be: nearest, or “prefer prey unless caveman is closer / provoked”, or hunger-based (hungry → prefer prey).

---

## How They Eat

- **Trigger:** Prey or caveman dies in range, or wolf walks to corpse.
- **Mechanic options:**
  - **A)** “Eat” = stand on corpse for N seconds → gain hunger, then corpse removed or decayed.
  - **B)** Corpse has “remaining meat”; each eat action consumes X meat, reduces remaining; when 0, corpse gone.
- **Loot:** If we want player to get less from a corpse that was eaten, we can reduce corpse loot by amount eaten.

Prey (sheep/goat) already become corpses on death; predator just needs an **Eat** state/action that targets a corpse and runs a timer or resource drain.

---

## How They Attack Other Wild NPCs (Prey)

- Predators use same **DetectionArea** (or a “prey” layer/mask) to see sheep, goats.
- **Target selection:** Closest prey in range, or closest that’s not inside a land claim (so they don’t rush into base first).
- **Combat:** Same **CombatComponent**: move in, `request_attack(prey)`, hit frame applies damage to prey’s HealthComponent. Prey can flee (if we add flee) or fight back (goat headbutt?).
- **Kill:** On prey death, predator can auto-switch to **Eat** (target = corpse) or re-evaluate (next prey / caveman).

---

## How They Attack Cavemen

- **Detection:** Same DetectionArea; cavemen = player + clan NPCs. Predator doesn’t have “clan”; everyone is either prey or threat.
- **Aggro:** Option A: predator always hostile to cavemen in range. Option B: only aggro if hungry or if caveman attacked it. Option C: “territorial” zone where entering = aggro.
- **Combat:** Identical to NPC-vs-NPC: predator has CombatComponent, sets combat_target to player or clan NPC, FSM goes to combat state, move in and `request_attack()`. Cavemen fight back with weapons; predator uses “unarmed” profile (bite) with its own damage/speed.
- **Death:** Predator dies like any NPC; drops loot (hide, meat, etc.) and/or leaves corpse.

---

## Implementation Hooks (existing systems)

- **NPCBase** — Predator is an NPC with `npc_type = "predator"` (or "wolf"); no clan, not herdable.
- **CombatComponent** — Reuse; give predator a “bite” weapon profile (damage, windup, recovery, range).
- **HealthComponent** — Same; predator has HP, can die, emit death/corpse.
- **DetectionArea** — Same scene node; configure layers/masks so predator sees “prey” and “cavemen” (and maybe “corpse”).
- **FSM** — New states: e.g. `Wander`, `Hunt`, `Eat`, `Combat` (reuse combat_state.gd if target is set), optionally `Flee`.
- **Spawn** — Spawn manager (phase2: “Spawn manager”) places wolves in world or in chunks; avoid spawning on top of player.

---

## Wolf (First Pass) — Summary

| Item | Proposal |
|------|----------|
| Sprite | `wolf1.png` |
| Health | 50 |
| Damage | 10 (bite) |
| Speed | 1.2× base |
| Detection | 300 px |
| Attack range | 80 px |
| Behavior | Wander → see prey or caveman → Hunt/Combat → on prey kill → Eat (timer) → repeat. |
| Loot on death | Hide + meat (TBD item ids). |

---

## Open Questions / TBD

- **Hunger:** Do we implement hunger from day one, or “always hostile / always hunt” first?
- **Pack behavior:** Wolves in group get bonus damage or only “hunt together” (same target)?
- **Prey fleeing:** Do sheep/goats run when they see a predator? (Might need a “fear” or “predator_nearby” signal.)
- **Land claims:** Do predators avoid entering claims unless chasing prey / in combat?
- **Corpse eating:** One-shot timer vs “remaining meat” on corpse?
- **More predators:** Bear (slower, heavier hit), big cat (ambush?), etc. — same doc, new rows in stats table.

---

## Next Steps

1. Add `npc_type = "predator"` (or "wolf") and Wolf scene using `wolf1.png`.
2. Add “bite” weapon profile and wire predator to CombatComponent.
3. Add FSM states: Wander, Hunt, Eat; wire Hunt to prey detection and combat.
4. Implement Eat (corpse interaction + timer).
5. Spawn manager: place wolves in world.
6. Tune stats and add loot table.

You can keep editing this file as we lock in stats and behaviors.
