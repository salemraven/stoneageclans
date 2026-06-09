

## 🔴 The Biggest Architectural Issue (Important)

### You’re treating “Building Item” and “Placed Building” as the same commitment

Right now the flow is:

```
Click card
→ consume materials
→ add building item
→ player places it later
```

### Problem

If the player:

* Closes inventory
* Never places the building
* Drops the item somewhere weird
* Dies / disconnects later

You’ve already **spent the resources** but haven’t committed the building to the world.

This is the **building equivalent of getting stuck in wind-up**.

---

## ✅ Recommended Fix: Two-Phase Commit (Like Combat Windup → Impact)

### Phase 1 — Intent (UI)

* Player selects building
* UI enters **PLACEMENT MODE**
* Show ghost building
* NO materials consumed yet

### Phase 2 — Commit (Placement success)

* Player confirms valid placement
* THEN:

  * Consume materials
  * Instantiate building
  * Apply effects

### If canceled:

* Exit placement mode
* No cost, no side effects

### This mirrors combat perfectly:

| Combat        | Building           |
| ------------- | ------------------ |
| Attack intent | Build intent       |
| Wind-up       | Ghost placement    |
| Hit frame     | Placement confirm  |
| Recovery      | Post-build effects |

---

## 🔴 Second Issue: Too Many Things Trigger Effects

Right now:

* UI
* Registry
* BuildingBase
* BabyPoolManager

…can all cause effects if you’re not careful.

### Rule (same as combat):

> **Effects should only fire from ONE place.**

---

## ✅ Single Source of Truth for Effects

### Recommended:

* **Effects trigger ONLY when building enters the world**

Not when:

* Card clicked
* Item added
* Inventory updated

### Example (Living Hut):

```gdscript
func on_placed(land_claim):
    BabyPoolManager.increase_capacity(land_claim, 5)
```

And on destruction:

```gdscript
func on_removed(land_claim):
    BabyPoolManager.decrease_capacity(land_claim, 5)
```

This prevents:

* Double application
* Missing application
* Save/load bugs later

---

## 🟡 UI Flow Is Good, But One Small UX Trap

This part is good:

* Integrated inventory
* Right-side build menu
* Cards auto-refresh

### But:

> Clicking a card immediately consuming resources is **harsh UX**

Players expect:

* Click → preview
* Place → confirm

Even Stoneshard-style games follow this pattern.

So I strongly recommend:

* Clicking card = **enter placement mode**
* Placement = **actual build**

---

## 🧠 The “Placement Mode” State (Very Important)

Just like combat state, you should formalize this:

```gdscript
enum BuildState {
    NONE,
    PLACING
}
```

While in `PLACING`:

* Ghost building follows cursor
* Valid/invalid color
* ESC / right-click cancels
* Left-click confirms

This prevents:

* Double placement
* UI desync
* Accidental builds

---

## 🟡 Occupation & Production: Mostly Excellent

Your oven / woman system is **well thought out**.

One small guardrail:

### ProductionComponent should NEVER start itself

It should only react to:

* `on_occupied`
* `on_unoccupied`
* `on_inventory_changed`

Not tick independently.

This avoids “ghost crafting” bugs.

---

## Quick Checklist (Like Last Time)

If you do **only these**, you’re safe:

✔ Add a formal **PLACEMENT MODE state**
✔ Consume materials **only on successful placement**
✔ Apply building effects **only on world placement**
✔ Add a **cancel path** (ESC / right-click)
✔ Never let UI directly apply gameplay effects

---

## Final One-Line Rule (Same Style as Combat)

> **Selecting a building is intent — placing it is commitment.**

If you follow that rule, your building system will be as robust as your combat system is becoming.

---

If you want, next we can:

* Refactor your current flow into placement-mode pseudocode
* Design the **ghost building validation logic**
* Align building placement with your tile system
* Or do a **“what will break in save/load” review**

Just tell me which one 👍
