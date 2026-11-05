# Party UI

**Status:** Not built. Locked November 2026. **Do the formation fixes below before building the circle.**

**Today’s game** still uses `CombatHUD` (**PEACE / AGRO / HUNT** + stance row), **H** rally ~**1500 px**, and **H in HUNT = abort hunt**. See [rts.md](rts.md). That bar stays until the fixes are in and this menu is built.

The dock, the shared pile, the short horn, and the I/X sheet are **scrap**. They are kept below so the old writeup is not lost. Do not build them.

---

## The horn

Press **H**. The leader blows the horn. You see that animation on him, and you hear the horn around him.

**H** still calls the clansmen in. The call is not a blank rally. The circle opens with it, and you choose what party is being created.

The rally distance stays today’s ~**1500 px** until that number is changed on purpose. This menu does not shorten the horn, and it does not make **H** cancel a hunt. Cancelling a hunt is **Break**.

## First circle

Three choices: **Follow**, **Raid**, **Hunt**. Click one. The clansmen move into that party’s formation.

The shapes already exist. They are the stance shapes in [rts.md](rts.md) §4.1 and §11a. Do not draw new ones. **Follow** is the arc behind the leader. **Raid** uses Attack’s line, Guard’s ring, and Ambush. **Hunt** uses Stalk’s wider arc, Arc’s half-moon, and Ambush.

## Second menu

After they form up, a second menu opens for how that party behaves. Every second menu includes **Break**.

| Party | Choices |
|-------|---------|
| **Follow** | Follow, Guard, Hide, **Break** |
| **Raid** | Attack, Guard, Ambush, **Break** |
| **Hunt** | Ambush, Stalk, Arc, **Break** |

These are the stance sets already used under **PEACE / AGRO / HUNT**. The first circle replaces that mode strip. The second menu is the stance row, with **Break** on every one.

**Break** sends that party home and ends the call. The **B** key still does the same thing.

---

## Before the circle — formation fixes

Do these with the bottom-left bar. Do not build the horn menu until a walk-through of Follow, Guard, Attack, Stalk, Arc, Hide, and Ambush holds.

1. **Standing speed.** While the leader stands still, Stalk and Guard are pushed back to full speed on most frames (`party_state.gd` sets the multiplier to 1.0 whenever the slot target is not refreshed). They should keep **0.5×** and **0.75×** while they hold the shape.
2. **Hide and Ambush face the wrong way.** `hide_state.gd` treats the leader as the threat, so the man stands on the far side of the nearest bush from the leader. Cover should sit between him and the prey or the enemy, not between him and the leader.

Later, not this pass:

- The Attack line has no width cap, so a big party becomes a very long line.
- An NPC-led Guard party builds a second ring instead of using `FormationUtils`.
- A man whose type is still `caveman` can be cleared out of Hide or Ambush from inside `party_state.can_enter`. Grown sons are `clansman` and do not hit that.
- The leader’s slowdown is only refreshed when the stance changes, someone joins, or Break is pressed. If the slowest man leaves, the leader can stay slow.
- `party_state.gd` keeps its own copy of the leash and the lookahead. Those numbers also live in `rts_formation_config.gd`.

---

## Scrap — dock, pile, short horn, I/X

Old plan, September 2026. Horn wheel (hold H) was added 2026-10-31. Scrapped November 2026. The circle menu replaces this whole section.

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
- **B** still works as a key even if there is no Break button on the bar

At ease, Spook, and Taunt are not a button on this bar. They live on the **hold-H** horn wheel (§3).  

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
| **Tap H** | **Come here.** Short range. Rally. **Not** hunt-abort. |
| **Hold H** | **Horn wheel.** Come, At ease, Spook, Taunt. Replaces the old separate mode-shout button. |
| **B** | **Break** anytime: split pile → pockets → walk to **your** claim → unload. |
| **I** | Open every inventory that **applies now** (see §7). Expands the party dock if you have a party. |
| **ESC** | Close **all** open sheets (bag, building, expanded party), and cancel an open wheel. Bar stays if you still have a party. |

### Horn wheel (hold H)

**Tap H** is only Come. The wheel is a different gesture, so one tap still does not mean spook and taunt.

Look: [UI.md](UI.md) §6b. Release on a slice. Release in the middle, or Esc, cancels.

| Slice | Effect |
|-------|--------|
| **Come** | Same rally as a tap. |
| **At ease** | Weapons down. Not a war band. No spook, no agro spike. |
| **Spook** | Loud. The hunt breaks off and the prey bolts. (What **H** does in Hunt **today**.) |
| **Taunt** | Pull attention onto you and the front of the band. |

A horn call becomes a story line only when a life beat follows. A normal Come is not a story. [story_data.md](story_data.md) §7.

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
| `CombatHUD` PEACE/AGRO/HUNT + 3 stances + Break | Dock bar: Walk/Hunt/Fight. At ease / Spook / Taunt are the **hold-H** wheel, not a bar button |
| H 1500 px; H in Hunt = abort | **Tap H** ~400 px always rally. **Hold H** picks Come, At ease, Spook, or Taunt. Spook is the hunt shout |
| No party pile | Pile + 5×N cap + B split |

Likely hooks: `main.gd` (`CombatHUD`, `_handle_war_horn`, `_handle_inventory_toggle`), `rts_formation_config.gd`, new party inventory + dock UI, corpse fill on party death, Break then existing `returning_from_break` + auto-deposit.
