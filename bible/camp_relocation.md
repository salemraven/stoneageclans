# Camp relocation (nomadic hearth)

Design guide for **moving the Tier 1 campfire** without disbanding the clan. Same logical base family as [earlygame.md](earlygame.md) (campfire vs flag).

**Related:** [nomad.md](nomad.md), [earlygame.md](earlygame.md) (territory tiers), [leader_hut.md](leader_hut.md) (clan structure at the new camp).

---

## Principle

**The clan is not the fire.** `clan_name`, roster, bloodline, and persistent clan state stay when the physical campfire node is removed or replaced. Only the **anchor** (world position, inventory in that node) changes unless you migrate goods deliberately.

---

## When to relocate

- Local resources exhausted; you want a new foraging/hunting ring.
- Seasonal pressure (e.g. winter prep) — move toward stockpiles or better ground.
- Threat — flee and re-anchor elsewhere (nomadic fantasy).
- **Abandonment** — old hearth can despawn under existing campfire rules (fire off + far for a timer, or empty/stone rules); treat relocation as **intentional** so you do not lose loot by surprise.

---

## Target flow (player fantasy)

1. **Prepare** — Move stored goods into **travois**, player inventory, or clansmen (when transport jobs exist). Dismantle or pack huts per [nomad.md](nomad.md) / earlygame travois concepts.
2. **Leave the old site** — Extinguish or walk away; know abandonment timers so the old campfire does not vanish while you still need its inventory.
3. **Travel** — Lead the group; herd/follow behavior stays tied to `clan_name`.
4. **Plant a new campfire** — Same clan name; systems should treat it as the same clan’s Tier 1 claim (see **Clan identity without a hearth** and **Placing a new campfire** below).
5. **Rebuild** — Huts, assignments, and production resume at the new anchor.

---

## Pack Up — recommended implementation (single entry point)

Use **one** authoritative routine (e.g. `Main._begin_pack_up_camp()` or a small service called from Main). **Phased order** matters; do not despawn the claim before occupations and inventories are handled.

| Phase | What to do |
|-------|------------|
| **A — Freeze** | Set `migration_in_progress` (or equivalent) so `occupy_building`, auto slot requests, and similar **do not** re-seat people into huts until the new camp exists. |
| **B — Clear roles** | Clear **defend**, **search**, hostile stance, and anything that conflicts with marching (reuse patterns from BREAK / `_break_and_dismiss_all` in `main.gd`, scoped to **your clan**). |
| **C — Release huts** | **`OccupationSystem.unassign`** every woman (and workers) assigned to **player-clan** buildings; reason e.g. `"pack_up"`. Alternatively destroy huts in order and rely on **`notify_building_destroyed`** (see `occupation_system.gd`) — doing **explicit unassign first** keeps behavior obvious. |
| **D — Territory + buildings** | Choose one model (see **Orphan huts** in edge cases): teardown huts with the pack, or leave ruins with extra flags. |
| **E — Campfire inventory** | **Decide explicitly** — merge to player, drop near site, or other — **before** `queue_free` on the campfire. |
| **F — Despawn claim** | `queue_free` campfire (and invalidate `land_claims` cache / horn wiring as elsewhere in `main.gd`). |
| **G — March** | Put followers on **ordered follow** → **`party`** (`_set_ordered_follow` in `main.gd`): `is_herded`, `herder` = player, `follow_is_ordered`. **Simplest MVP:** everyone uses the same path; **women follow clansmen who follow player** is optional extra behavior (not default code today). |
| **H — New camp** | Player places new campfire; clear `migration_in_progress` after the new anchor exists. |

**Placement order:** Avoid **two** player-owned claims in the same frame — either remove old fire before placing new, or block placement until pack completes.

---

## Pack Up + land claim circle / occupancy

- **Occupation** is on **buildings** (`BuildingBase` + `OccupationSystem`), not on the radius graphic. Hiding only the circle does **not** free women.
- If **Pack Up removes the territory node** (campfire `queue_free`):
  - **Destroy huts with the pack** → `notify_building_destroyed` before each hut’s `queue_free` → automatic **`unassign(..., "building_destroyed")`** for occupants.
  - **Leave huts as ruins** → you must still **`unassign`** everyone and mark huts **invalid for occupation** until a new claim exists; otherwise women can stay in an invalid state.
- Design rule: **without a valid player territory node, Living Huts (and Leader’s Hut) should not accept occupation** — enforce in `request_slot` / building validity or by removing huts.

---

## March: women, clansmen, followers

- **`OccupationSystem.unassign`** frees women from hut slots; FSM should not immediately re-enter **occupy_building** during migration (the `migration_in_progress` flag helps).
- **Clansmen “follow mode”** today = **`_set_ordered_follow`** → **`party`** state, same `herder` / `follow_is_ordered` pipeline as other marchers.
- **Women following clansmen who follow the player** is a **design choice**; current code tends to set **`herder` = player** for ordered followers. A **chain** (woman → male → player) needs **new** steering or target rules.
- **Defenders** on the old claim must be **cleared** or they will try to hold a dead territory.

---

## Caravan with no campfire — is it possible?

**Yes**, for **identity** and **followers**, if you preserve clan on the player (or heir):

- **`Player.get_clan_name()`** is intended to work **off-claim** via `player_name` / `player_clan_name` meta (see `player.gd`).
- **`_get_player_clan_name()`** in `main.gd` checks the player first, then scans `land_claims` — if the player still has a non-empty clan string, the **clan exists** even with **zero** nodes in `land_claims`.
- **Followers** attach to the **player** (`herder`, `follow_is_ordered`, party) — they do **not** require a campfire in the tree.

**Requirement:** **Pack Up / claim loss must not clear** `set_player_name` / `player_clan_name` unless you intend a full bloodline wipe / new game.

Some systems **noop** until a new hearth exists (e.g. horn / emergency defend that look for territory) — that is acceptable **caravan gap** behavior.

---

## Placing a new campfire — same clan, no duplicate name dialog

Today **`_place_campfire`** always opens **`ClanNameDialog`**. For **re-anchoring** an existing clan:

- If **`_get_player_clan_name() != ""`** (or a dedicated **re-anchor** flag), **skip** the dialog and call the same confirm handler with the **existing** string so the new `Campfire` gets **`clan_name`** matching the player / bloodline.

This covers:

- Pack Up → march → new fire.
- Leader death + succession → heir already has **`clan_name`** → place fire without renaming the clan.

---

## Leadership and death (not relocation)

If the **player character** dies, **relocation is not implied**. Leadership can pass to an heir; the **hearth may stay** or you may be in **caravan** state. The heir must keep the same **`clan_name`**; succession rules live under [leader_hut.md](leader_hut.md) (planned). **Camp relocation** and **succession** are separate problems.

---

## Voluntary Pack vs claim destruction

| Situation | Intent |
|-----------|--------|
| **Pack Up (player)** | Move camp; **clan persists**; evacuate NPCs; optional teardown; **do not** wipe bloodline or `player_name`. |
| **Land claim destroyed / raid / decay** | May use **`claim_destroyed`**, revert women, fast decay on buildings — **different** outcome than Pack; may or may not match Pack code path. **Do not** accidentally trigger **clan wipe** on voluntary Pack. |

---

## Edge cases and loose ends (checklist)

Use this as a **design + QA** list when implementing and playtesting.

### Territory and buildings

1. **Orphan huts** — Pack removes claim but leaves huts: occupation, jobs, decay, and “inside claim radius” checks need an explicit rule (destroy with pack vs ruins vs `invalid_for_occupation`).
2. **Campfire vs flag** — Is Pack Up **Tier 1 (campfire) only**? If so, document and enforce; flag “pack” may be undefined or a different flow.
3. **Upgrade collision** — Campfire → Land Claim upgrade (drag flag item) while Pack runs: mutually exclusive or ordered cancel.
4. **Placement validation** — New campfire must respect **min distance** to other claims; caravan may stand on invalid tiles when placing.
5. **ClaimBuildingIndex / crowding** — Hut counts and nomadic crowding meta must attach to the **new** anchor after move.

### Inventory and economy

6. **Campfire inventory** — Merge to player, ground drop, or loss? Partial stacks?
7. **Land claim inventory** — Only if Pack ever touches a flag; same question.
8. **Building inventories** — If buildings despawn: drop, migrate, or destroy contents?
9. **Travois / ground items** — Deferred in v1; order of operations if combined later.
10. **Land claim item reservations** — Jobs reserving items on claim: **release** on pack or leak.

### NPCs: assignment and behavior

11. **OccupationSystem** — RESERVED vs OCCUPIED; woman mid-walk to hut; **`unassign` before** `queue_free` building when order matters.
12. **Defend / search** — `defend_target` / `search_home_claim` pointing at removed claim: clear before march.
13. **Ordered follow** — Who is in the march? Defenders must leave the old ring.
14. **Women follow clansmen** — If implemented: chain follow, break distance, death of middle link.
15. **Clansmen herding animals** — Detach vs bring herd; `herded_count`; deposit tasks mid-route.
16. **AI tasks** — Jobs targeting old claim inventory: abort cleanly.
17. **Wander / occupy race** — **`migration_in_progress`** must block **occupy_building** re-entry until new camp (+ optional huts) exist.

### Life cycle: babies, pregnancy, age

18. **Pregnant women** — Still march? Reproduction may require claim + hut; define invalid state during migration.
19. **Babies / children** — Bound to mother or hut context; if hut despawns, where do they go?
20. **Promotion timers** — Baby → clansman with no hut at new site yet.

### Clan identity and leadership

21. **Player `player_name` / `player_clan_name`** — Survives Pack; only clear on new game / wipe bloodline (by design).
22. **Campfire placement** — Skip name dialog when clan already known (see **Placing a new campfire**).
23. **Succession** — Heir keeps same `clan_name`; same skip-dialog and placement rules as caravan re-anchor.
24. **No eligible heir** — Game over, wild cavemen, or other: decide explicitly.

### UI and feedback

25. **Building menu / craft** — Disabled or consistent messaging while `migration_in_progress` or no territory.
26. **Horn / emergency defend** — No territory: message vs silent; after new fire, **reconnect** signals (`land_claims_changed`).
27. **RTS / follower cache** — Stale IDs after Pack; verify `EntityRegistry` / `_follower_cache` after claim despawn.

### World and persistence

28. **Save / load** — Caravan state: no claim in tree but `player_name` + followers + migration flag must round-trip.
29. **Multiplayer** (if used) — Server authority for Pack, inventory, and claim spawn.

### Ordering and bugs

30. **Frame order** — Never `queue_free` claim **before** unassign / inventory migration.
31. **Duplicate claims** — Block placing new fire before old removed if both would be `player_owned`.
32. **Cache** — **`invalidate_land_claims_cache`** whenever claims add or remove.

---

## Implementation notes (engineering summary)

| Topic | Intent |
|--------|--------|
| **Single active Tier 1 hearth** | Placing a new player campfire while one exists should **retire** the old node safely or **block** placement — avoid duplicate `player_owned` nomadic bases. |
| **Inventory** | Merge or drop rules must be explicit so migration does not delete stock silently. |
| **Land claim cache** | Invalidate when claims add/remove; new campfire **`register_land_claim`**. |
| **NPCs** | `defend_target` / `search_home_claim` / `owner_npc` must not reference freed nodes; campfire teardown already has herd release paths — Pack should reuse or mirror. |
| **Upgrade path** | Campfire → flag (Tier 2) is separate from **move**; relocation is Tier 1 anchor **position** change. |

---

## Summary

- **Relocate** = move the **nomadic anchor** and logistics; **clan identity** stays on the player (and NPCs’ `clan_name`) if you do not wipe it.
- **Pack Up** = one **phased** pipeline: freeze → clear roles → unassign / teardown → inventory → free claim → march → new fire.
- **Caravan with no hearth** = valid for **followers + name**; some systems wait until a new fire exists.
- **Succession** = separate from Pack; use **same** clan string and **skip** rename dialog when re-anchoring.
- Pair implementation with **travois**, hut teardown, explicit **inventory** rules, and the **edge-case checklist** above.
