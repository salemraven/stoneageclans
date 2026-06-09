# Shelter & Warmth

Design for night survival: Living Hut as shelter, fire warmth radius.

**Related:** [earlygame.md](earlygame.md) (Night & Exposure), [nomad.md](nomad.md) (Campfire vs Land Claim)

---

## Shelter = Living Hut

The **Living Hut** is the basic shelter. It replaces the old "Lean-to" concept.

- Provides wind and cold protection
- Houses 1 woman + her children
- Required for pregnancy
- NPCs inside or near a Living Hut are sheltered from night cold

---

## Fire Warmth Radius

**Campfire** and **Land Claim** (with fire/hearth) provide warmth in a radius.

| Source | Warmth Radius | Notes |
|--------|---------------|-------|
| Campfire (fire on) | TBD (e.g. 250px) | Same as claim radius or slightly larger |
| Land Claim | TBD (e.g. 400px) | Hearth/campfire at center |

**Rule:** NPCs within the warmth radius of an active fire do not take night cold damage.

- Fire must be **on** (campfire: `is_fire_on`; land claim: has active hearth/campfire)
- NPCs outside warmth radius + outside Living Hut → night cold drains health

---

## Night Cold

- Without shelter **or** fire warmth → health drains steadily at night
- Living Hut = shelter (blocks cold)
- Fire warmth radius = warmth (blocks cold)
- NPC needs either: (a) inside/near Living Hut, or (b) within fire warmth radius

---

## Implementation Notes

- Add `warmth_radius: float` to Campfire (when `is_fire_on`)
- Land claim: warmth from central fire/hearth when present
- Night cold system: check each NPC — if not in warmth radius AND not sheltered → apply cold damage over time
- Living Hut: count as "sheltered" when NPC is inside claim radius and assigned to that hut, or within hut proximity

---

## Summary

| Need | Solution |
|------|----------|
| Shelter | Living Hut |
| Warmth | Fire (campfire or land claim) — warmth radius |
| Night cold | Drains health when outside both shelter and warmth |
