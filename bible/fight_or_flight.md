# Fight or flight

**Status:** Locked **2026-11-04**. Player-facing vocabulary and code mapping. **Attributes:** [future implementations/character_attributes.md](future%20implementations/character_attributes.md) § Bravery. **Flight bar:** [future implementations/morale_bar_flight.md](future%20implementations/morale_bar_flight.md).

---

## Player words (three)

| Word | Meaning |
|------|--------|
| **Fight or flight** | The whole system: **Bravery** core and perks, **morale bar**, **`agro_meter`**, standoff, combat FSM, orders. |
| **Fight** | Committed attack: **`agro_meter` at max**, NPC is **attacking**, **red `!!!`** above the head. |
| **Flight** | Nerve broke: **morale bar** below personal flight line, **yellow `!!`**, flee / break off. |

Do not use **anger** in design or UI. Formation breaks when **`agro_meter`** crosses the stance limit ([rts.md](rts.md) §4.3).

**Under pressure** on the character sheet summarizes **fight or flight**, not the eight cores.

---

## Technical **agro** (keep these names in code)

These are **not** the player word **Fight**. They build toward it.

| Term | Role |
|------|------|
| **`agro_meter`** | 0–100 fill toward fight. Events raise it; `CombatTick` decays it. Cap = max (usually 100). |
| **`push_agro_event`**, enter/exit thresholds | Plumbing. Today combat often engages around **70** enter / **60** exit; **red `!!!` as player Fight** should align with **max + attacking** when attributes ship (code may differ until then). |
| **`agro_state`** | FSM for claim defend / herd recover — not “in Fight” by itself. |
| **AOA** (Area of Agro) | Inner perception zone where hostiles pump **`agro_meter`**. |
| **`is_agro`** | Internal: meter has tension (> 0). **Not** the same as player **Fight**. |
| **RTS Agro mode** | Peace / **Agro** / Hunt HUD group — stance and formations for closing on contact. Not the **`!!!` Fight** state. |

---

## How pieces connect

```
Bravery core + perks (fear resistance, aggression threshold, …)
        ↓
Fight or flight in the moment
        ├─ agro_meter fills → at max + attacking → Fight + red !!!
        └─ morale bar drops below flight line → Flight + yellow !!
```

- **Attack / Guard** orders add courage; they do not remove **flight**.
- **`Stats.aggression`** and legacy brain **`raid_aggression`** floats retire into **Bravery** + perks ([traits.md](traits.md)).
- **Clan** screen uses average **Bravery core**, not **`agro_meter`**.

---

## Formation break (party)

In **`party_state.gd`**, ordered clansmen hold a slot while **`agro_meter`** stays below a **stance cap** (40 / 70 / 95 / 100 by mode). Above the cap they leave the shape and move with the leader until **fight or flight** takes over.

---

## Code pointers

| File | Role |
|------|------|
| `scripts/systems/combat_tick.gd` | **`agro_meter`** tick, thresholds |
| `scripts/combat/morale_bar.gd` | **Flight** |
| `scripts/combat/fight_flight.gd` | FoF nudges to morale |
| `scripts/npc/npc_base.gd` | **`agro_meter`**, red **`!!!`**, yellow **`!!`** |
| `scripts/npc/states/combat_state.gd` | Attack while in combat |
| `scripts/npc/states/party_state.gd` | Formation vs **`agro_meter`** cap |
