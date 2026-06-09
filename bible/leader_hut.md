# Leader’s Hut (building guide)

Design guide for a **Leader’s Hut**: a cheap, early **clan government + housing** building available from the **campfire (Tier 1)** and **flag land claim (Tier 2)** onward. It parallels **Living Hut** behavior for occupation and reproduction hooks, with **multiple woman slots** and room for future **succession**, **relics**, and **clan info** UI.

**Related:** [earlygame.md](earlygame.md) (territory tiers), [game_dictionary.md](game_dictionary.md) (Living Hut, occupation), [camp_relocation.md](camp_relocation.md) (moving camp without losing clan identity), [reproduction_guide.md](reproduction_guide.md).

---

## Purpose

| Role | Description |
|------|-------------|
| **Clan seat** | Anchor for **succession law** (e.g. oldest son vs seniority among clansmen) when that system is implemented — UI and saves keyed off this building. |
| **Women’s quarters (leader line)** | Up to **3 occupation slots** for **breeding women** (same rules family as Living Hut: assignment, claim radius, reproduction gates). |
| **Future** | **Relics / trophies** slots or meta for buffs; **clan roster / lineage** summary. |

---

## Availability

| Territory | Buildable? |
|-----------|------------|
| **Campfire (Tier 1)** | **Yes** — from the start of the nomadic phase, subject to placement rules for that tier. |
| **Flag / Land claim (Tier 2+)** | **Yes** — same building, full settled base. |

The Leader’s Hut is **not** locked behind mid-game tech; it is a **foundational** building for clan identity and (later) law.

---

## Construction cost (design)

| Resource | Amount |
|----------|--------|
| **Hide / leather** | 1 — use `ResourceData.ResourceType.HIDE` (player-facing: leather) |
| **Wood** | 1 |
| **Cordage** | 1 |

Use `ResourceData` / `BuildingRegistry` when implementing so costs stay data-driven and balance can change without rewriting scenes.

---

## Parity with Living Hut

The Leader’s Hut should **behave like a Living Hut** for systems that care about housing and reproduction:

- **BuildingBase**-style placement inside the **player-owned territory** (campfire or land claim radius), same clan `clan_name`.
- **Occupation** — women can be assigned to slots via the same **OccupationSystem** patterns as Living Hut (`request_slot` / `confirm_arrival` / primary occupant), unless a dedicated multi-slot component is added.
- **Reproduction** — women in Leader’s Hut slots count as **in valid housing** for pregnancy/birth flow, matching Living Hut gates (inside claim radius, mate eligibility, etc.). Exact capacity numbers can mirror Living Hut tuning unless design specifies a different baby-pool contribution.

**Difference vs standard Living Hut:**

| Aspect | Living Hut (reference) | Leader’s Hut (design) |
|--------|------------------------|------------------------|
| Woman slots | Typically **1** primary occupant (+ children context) | **Up to 3** slots for **breeding women** |
| Fantasy | Family shelter | Chief’s household / clan seat |
| Extra UI (later) | — | Succession, relics, clan info |

---

## Occupation: three breeding women

- **Slots:** **3** max — three women can be assigned for **breeding** context (same eligibility as Living Hut: species, claim, leader/mate rules per `reproduction_component` / configs).
- **Children / babies:** Follow the same growth and pool rules as other housing unless a separate spec says otherwise (e.g. babies still tie to mother’s hut context).
- **UI:** Building panel should list up to three occupants clearly so players do not confuse this with three separate one-woman huts.

---

## Future systems (not required for first placement)

These are **planned** extensions; the first implementation can be **placement + 3 woman slots + inventory shell** if needed.

| System | Intent |
|--------|--------|
| **Succession mode** | Set **primogeniture (sons)** vs **seniority (oldest clansman)**; stored per clan; preview **heir** under current law. |
| **Relics / trophies** | Deposit items for **display** and **buffs** (narrow modifiers, data-driven). |
| **Clan info** | Read-only roster, lineage summary, optional alerts. |

---

## Implementation checklist (code)

1. Add `ResourceData.ResourceType` (or reuse a hut type with metadata) and **BuildingRegistry** entry: cost **1 Hide, 1 Wood, 1 Cordage**.
2. Scene/script extending **BuildingBase** (or shared hut scene) with `building_type` set; **3** occupant slots for women — mirror Living Hut patterns in `building_base.gd` / occupation.
3. Allow in **campfire** placement lists (Tier 1) and **land claim** lists (Tier 2+) alongside existing buildings; respect `ClaimBuildingIndex` / placement validation in `main.gd`.
4. Reproduction: ensure `reproduction_component` (or equivalent) treats this building type like **Living Hut** for **in-hut** checks, with **slot count** = 3.
5. Optional: single **Leader’s Hut per clan** flag to avoid spamming law UIs.

---

## Summary

- **Cost:** 1 Hide (leather), 1 Wood, 1 Cordage.  
- **Where:** Campfire **and** flag land claim from early progression.  
- **Core:** Same **Living Hut–style** behavior with **up to 3 breeding women**; succession, relics, and buffs layered on later.
