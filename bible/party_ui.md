# Party UI & kit — agreed next (not shipped)

**Status:** Design lock, **September 2026**. Not in code yet.  
**Today’s game** still uses `CombatHUD` (**PEACE / AGRO / HUNT** + stance row), **H** rally ~**1500 px**, and **H in HUNT = abort hunt**. See [rts.md](rts.md).

**Look / drag:** [UI.md](UI.md). This file owns **party dock, horn, break-haul, pile, slider, I/X**.

If this file and old HUD text disagree, **this file wins for the next implementation**.

---

## 1. One party, three jobs

You command **one band**, not per-person kits.

| Player name | Job | Formation (reuse today’s slots) |
|-------------|-----|----------------------------------|
| **Walk** | Travel / escort | Behind you (today’s FOLLOW) |
| **Hunt** | Prey | Quiet hunt shapes (stalk default; extra orders later) |
| **Fight** | People / raid | Line ahead (today’s ATTACK) when close; march in **Walk** |

Raid is **Fight + you’re away from home**, not a fourth mode.

---

## 2. Party dock (one window, two sizes)

While **at least one fighter** is in ordered follow, a **party dock** exists. It is **not** a second inventory window.

### Bar (collapsed) — always up when you have a party

- Faces / count  
- **Walk | Hunt | Fight**  
- **Mode shout** (one button; label changes)  
- **B** still works as a key even if there is no Break button on the bar  

No slider. No item rows. Park **bottom-left of the hotbar** (replace today’s wide combat HUD).

### Sheet (expanded)

**I** **expands this same dock** (slider, pile, extra orders later).

**X on the party sheet** = **collapse to the bar**. Does **not** disband. Pile stays.

**B** = **Break** (see §5). Never use X for break.

No party → no dock.

---

## 3. Keys

| Key | Meaning |
|-----|---------|
| **H** | **Always shout / rally.** Short range. “Come here.” **Not** hunt-abort. |
| **B** | **Break** anytime: split pile → pockets → walk to **your** claim → unload. |
| **I** | Open every inventory that **applies now** (see §7). Expands the party dock if you have a party. |
| **ESC** | Close **all** open sheets (bag, building, expanded party). Bar stays if you still have a party. |
| Mode shout | One extra control on the bar/sheet (key TBD, e.g. **V**). |

### Mode shout (same slot, three labels)

| Mode | Label | Effect |
|------|--------|--------|
| **Walk** | **At ease** | Weapons down, not a war band. No spook, no agro spike. |
| **Hunt** | **Spook** | Loud: call off hunt, prey bolts. (What **H** does in Hunt **today**.) |
| **Fight** | **Taunt** | Pull attention onto you / the front of the band. |

Do **not** make **H** mean shout *and* spook *and* taunt.

---

## 4. Horn radius

**H** is a **pulse**, not “call the whole map.”

- **Today:** `RTS_CONFIG.rally_radius` = **1500 px** (too large).  
- **Agreed:** shout ≈ **hearing / one claim** — target **~400 px** (same order as flag radius / AOP). Show a **brief ground ring**.  
- Same clan **fighters only** (player’s **clansmen / cavemen**). **Not** women, **not** herdables.  
- In range + not already following → join. Already in party → stay. Out of range → ignore. Walk the camp and tap **H** again.  
- Searchers with an active herd: keep the **planned** “ignore Horn” rule from [earlygame_vision.md](earlygame_vision.md) / [rts.md](rts.md).

---

## 5. Break (**B**) and loot

Works at home and **on an enemy claim**.

1. **Split** the party pile into followers’ **empty pockets**, **one item per slot** (same as stockpile → player bag). Round-robin.  
2. Clear ordered follow. They path to **your** campfire/flag — **never** auto-deposit into an **enemy** stockpile.  
3. Existing **auto-deposit** at **your** claim (~100 px) unloads pockets (keep-one-food rule can stay).  
4. Leftover that does not fit (death, over-cap): **drop as ground piles**. Do not delete.

**B mid-fight** is allowed — they pocket and run.

---

## 6. Party pile (kit + loot)

**One bag:** loot **and** spare weapons/ammo. Compact stockpile rows (one type, big count) like the claim.

**In-hand gear** (club/spear/stones they’re using) **does not** count toward the cap.

**Cap = 5 × (fighters in the party).**  
Clansman pockets today: **5 slots, no stacking**. Player bag is **not** in the cap.

Slider = **how they fight**, not who owns which item:

- Left: melee (club / spear close).  
- Right: ranged (stones, arrows, thrown spear).  
- Middle: ~half *prefer* range **if ammo exists**. Ammo is the hard cap.

**Current code (do not “fix” this by blocking throws):** a spear in hand does **not** stop a stone throw. Followers keep the spear equipped. They throw a stone when they have one and the enemy is outside melee reach, as long as the ranged slider is above about 1%. See **Thrown stone** in `bible/game_dictionary.md`.

No per-person loadout. Drag in/out from **player bag** or a **building** pile (yours or loot).

**Source of truth:** while they follow, **the pile is the inventory**. People only *show* a weapon from it. Do not keep a fake total plus real NPC stacks.

---

## 7. Death

Dying follower:

- Keeps **hotbar kit**.  
- Takes up to **5 items** from the pile onto the **corpse** (fair slice of types, not “all the meat”).  
- Party cap drops by 5. Remainder stays in the pile.  
- Corpse UI unchanged: loot the body.

---

## 8. **I** and **X** (all inventories)

**I opens every panel that applies.** It does not lock them together forever.

| Situation | I opens |
|-----------|---------|
| Alone, nothing nearby | Player bag |
| Party, nothing nearby | Bag + **expand party dock** |
| Next to a building (yours **or** enemy) / corpse / travois | Bag + **that stockpile** |
| Party + next to a building | **Bag + party sheet + building** |

Each panel has **X**:

- Bag / building **X** = hide that panel only.  
- Party sheet **X** = **collapse to bar** (party remains).  

**I again** **re-opens** whichever panels still apply (including ones you X’d). It does **not** mean “toggle everything off.” **ESC** closes sheets.

Friendly oven/flag and **enemy** hut use the same rule: in range → I can show it; X what you don’t want.

Title-bar **drag + remember** still applies to bag and building. Expanded party sheet may remember position; the **bar** stays docked by the hotbar.

---

## 9. Extra orders later

Add new calls on the **sheet** first. Promote to the **bar** only if you use it every fight. Keep the bar to about **four** controls.

Out of scope here: control groups 1–9, waypoints, per-person weapon menus.

---

## 10. Code today (do not confuse)

| Now | Agreed |
|-----|--------|
| `CombatHUD` PEACE/AGRO/HUNT + 3 stances + Break | Dock bar: Walk/Hunt/Fight + mode shout |
| H 1500 px; H in Hunt = abort | H ~400 px always rally; **Spook** is the hunt shout |
| No party pile | Pile + 5×N cap + B split |

Likely hooks: `main.gd` (`CombatHUD`, `_handle_war_horn`, `_handle_inventory_toggle`), `rts_formation_config.gd`, new party inventory + dock UI, corpse fill on party death, Break then existing `returning_from_break` + auto-deposit.
