# Living Hut husband assignment (future)

**Status:** **Planned — not implemented.**  
**Last updated:** 2026-08-30  

**See also:** [female_baby.md](female_baby.md) · [reproduction_guide.md](../reproduction_guide.md) · [Phase4/women4.md](../Phase4/women4.md) · [settlement_sim.md](../settlement_sim.md)

---

## Goal

Let the player (and later ClanBrain) **explicitly assign a male to a Living Hut** as the woman’s **husband / designated father**, instead of only inferring it from whoever herded her in.

This matches the stone-age “household” model: one woman per hut, one primary mate tied to that hut.

---

## Player-facing behavior (planned)

1. **Drag-and-drop** a clansman (or player) onto a **Living Hut** that already has a woman assigned.
2. Hut UI shows **husband name** (e.g. “Husband: KAI”).
3. That male becomes the woman’s **`designated_father`** for reproduction (on-screen and off-screen roster).
4. If the assigned husband **dies** or stays **absent** too long (off-screen: see `father_absent_ticks` in settlement sim), a **new male** can be assigned automatically or the hut shows “no husband” until the player assigns one.

---

## Integration points

| System | Hook |
|--------|------|
| **Living Hut / building UI** | Drop target for male NPC; display husband label |
| **OccupationSystem** | Link woman slot + optional `assigned_husband_id` meta on hut |
| **ReproductionComponent** | `set_designated_father_from_herder()` already exists — extend to `set_designated_father(husband)` from hut assignment |
| **Settlement roster** | `designated_father_id` on woman members; off-screen `_pick_father_id()` wait/reassign logic |
| **PlaytestInstrumentor** | `settlement_husband_reassigned` when sim picks a new mate; future `hut_husband_assigned` for manual assigns |

---

## Off-screen sim (shipped baseline for absent husband)

While this doc’s **drag-drop UI** is future work, dormant claims already use:

- **`father_absent_ticks`** on roster women — wait **one tick** when designated father is not in roster (e.g. player walked away), then pick first available clansman and log **`settlement_husband_reassigned`**.

Future hut assignment should **write the same `designated_father_id`** so on-screen and off-screen stay one source of truth.

---

## Open questions

1. Can one man be husband to **multiple** huts, or strictly one hut per man?
2. On husband death, **auto-assign** oldest son / random clansman, or leave hut empty until player assigns?
3. Show husband on **map icon** or only in hut inventory panel?

---

## Non-goals (v1 of this feature)

- Female babies / daughter promotion ([female_baby.md](female_baby.md))
- Genetics / inbreeding traits
- Divorce or voluntary partner swap without death/absence
