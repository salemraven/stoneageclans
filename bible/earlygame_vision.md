# Early game vision — first 10 minutes through settlement

**Status:** Design owner doc — mix of **shipped**, **partial**, and **planned**.  
**Last updated:** Sep 2026  
**Tier naming (locked):** **Tier 1 = Campfire** (nomadic land claim). **Tier 2 = Flag** (settled land claim). Campfire uses the same claim family as the flag — not a separate game mode.

**See also:** [earlygame.md](earlygame.md) · [nomad.md](nomad.md) · [future implementations/proto_farming.md](future%20implementations/proto_farming.md) · [future implementations/herdable_raiding.md](future%20implementations/herdable_raiding.md) · [future implementations/female_baby.md](future%20implementations/female_baby.md) · [future implementations/wounds.md](future%20implementations/wounds.md) · [multiplayer.md](multiplayer.md)

---

## 1. First 10 minutes

**Spawn with no land claim.** First home is a **campfire** (Nomad).

| Campfire (Tier 1) | Does | Does not (target) |
|-------------------|------|-------------------|
| Stash + small roster | Deposit, herd-into-radius, reproduce, warmth | **Proto farming Field** / crop ring ([proto_farming.md](future%20implementations/proto_farming.md)) |
| **ABANDON CAMP** | Relocate without disbanding clan ([camp_relocation.md](camp_relocation.md)) | Full **AI raid economy** (ClanBrain offensive raids from player nomad camp) |
| ClanBrain | Nomadic mode: search + gather pressure | Same raid scoring as settled flag (until player upgrades) |

**Tier 2 = Flag** (settled `LandClaim`). **Placing the flag is the tutorial beat** — the spend and placement teach “we stay put now.” What the **campfire refuses to build** (Field, full production set, AI raid loop) is the shape of the opening.

**Art:** Dedicated **campfire** sprite/read (distinct from flag pole) — see [nomad.md](nomad.md) § Art needs.

---

## 2. Food — three foods, one hunger bar

One **hunger / calorie bar** on the player; pantry uses **`food_days_buffer`** on the territory (canonical: `ClanFoodBuffer`).

| Food | Source | Role |
|------|--------|------|
| **Forage** | Berries, roots (future), hand gather | Stay alive on the walk |
| **Meat** | AoH hunt (deer/mammoth) or flock butcher | Hunt pressure, raid protein |
| **Grain / bread** | Wild wheat gather **or** settled **Field** + **Oven** on **flag** | Reason to settle |

**UI (target):** Claim shows one line: **`Food: N days.`**

**ClanBrain (target — replaces hunger-as-raid-pressure):**

| Pantry + situation | Brain picks |
|--------------------|-------------|
| Low food | **Searcher quota**, **hunt_intent** — not offensive raid |
| Enough food + few women | **STEAL** (cordage herd raid) |
| Enough food + fat enemy stockpile | **LOOT** |
| Weak neighbor + extract done | **WIPE** |

*Today:* `food_days_buffer` exists; multi-goal raid pick is **planned** ([herdable_raiding.md](future%20implementations/herdable_raiding.md)). Code still adds raid score when moderately hungry — change when goal scoring ships.

---

## 3. Women, babies, genetics

- A **woman** is **clan member**, not a clansman. Same **genetics / trait layer** as fighters — unique hybrids; **no founder-species labels** in UI ([genetics.md](genetics.md)).
- **Birth:** mother + father genes combine (CK2-style). Some woman traits are **dormant for her job** but **pass to children**.
- **Babies today:** all grow to **clansmen**. **Female babies planned** — sex at **birth**, promote to **woman** or **clansman** ([female_baby.md](future%20implementations/female_baby.md)). **`sex` field not in game yet.**
- **Living Hut** must **enforce baby cap** (`enforce_baby_cap` — hook exists, default off until enabled).
- **Player choice:** herd another **wild** woman, or build **Living Hut** so existing women keep producing.

**Wild women** remain important for outside bloodlines; **daughters** reduce map dependence over time.

---

## 4. Raid goals — cordage, four verbs

**STEAL ≠ combat on the flock.**

| Tool | Action |
|------|--------|
| **Cordage** | Equip → use on enemy **claimed** herdable → **bond** → same `herd` lead-out as wild attach |
| No cordage | Peace walk-up **cannot** take **claimed** herdables (influence is wild-only today) |

**Enemy land-claim menu (player target):**

| Verb | Goal | ClanBrain |
|------|------|-----------|
| **TAKE HERD** | STEAL | Searchers + cordage bond |
| **TAKE GOODS** | LOOT | Building / flag inventories |
| **ATTACK MEN** | KILL | Fight clansmen |
| **BURN FLAG** | WIPE | Destroy flag after loot/extract rules |

Full spec: [herdable_raiding.md](future%20implementations/herdable_raiding.md). **Loot before smash** — flag destroy deletes inventories.

---

## 5. War Horn vs herding

| Role | Meaning |
|------|---------|
| **War Horn (H)** | Rally **workers + defenders** into ordered follow; **detaches herd** on rallied clansmen today |
| **Searcher** | ClanBrain quota → `herd_wildnpc` |
| **Defender** | Quota on claim border (`defend_state`) |
| **Worker** | Clansman not on defend |
| **Guard (HUD)** | Party **stance** — not the defender job |

**Problem:** Horn mid-herd **drops herdables** (`_set_ordered_follow` clears `herded_count`) → STEAL raid dies at the button.

**Target fix:**

- Horn rallies **workers + defenders** only.
- Searcher with **`herded_count > 0`** (or active cordage bond) **ignores Horn**, keeps herd.
- **B (Break)** = drop herd, walk home toward claim.
- **STEAL:** raise searcher quota, issue cordage — **do not Horn** the bonding party.

Doc: [rts.md](rts.md) (planned behavior note).

---

## 6. Combat and the map

**Corpses, wipe, succession** — partially shipped. **Living wounds** — **planned** ([wounds.md](future%20implementations/wounds.md)), not in scripts today.

| Outcome | Map effect |
|---------|------------|
| Enemy dies | Corpse, loot |
| Wounds (future) | Fight worse until heal / medic |
| Flag destroyed | Territory wipe |
| Player dies | Leader succession on clansman; loot on corpse |
| Failed STEAL | Bond breaks; herdable unbonded on spot |
| Die carrying loot | Pile on corpse |

---

## 7. Island / multiplayer (future)

**Design target:** One **authored island** (contrast: today = infinite chunked plane — [game_map.md](game_map.md)).

**Map guide:** **[environment_goal.md](environment_goal.md)** (canonical) · [island_map.md](island_map.md) (map2 checklist) · art [`assets/island_map2.jpg`](assets/island_map2.jpg) · MP [future implementations/island_mp.md](future%20implementations/island_mp.md) · build [roadmap_2026.md](roadmap_2026.md).

- Separate **spawn locations** per player (spacing in `WorldGenConfig.player_spawn_zones`).
- Land claims **cannot overlap**.
- Herdables = world objects → steal is PvP.
- Disconnect → **ClanBrain runs claim** until reconnect ([multiplayer.md](multiplayer.md) roadmap).
- **Domination panel:** living sons, women, trait mix, claims held.

---

## 8. Genetics on-ramp

1. Every caveman and woman: trait/perk list (some dormant on women).
2. Baby stores parent mix; **INFO** shows **that child’s** traits.
3. Land-claim panel: totals — sons, women, **common clan traits**.

Founder species stay in data as trait pools; **not** the identity shown on characters.

---

## 9. Off-screen / “time parked”

When the player leaves a claim, **settlement sim** ticks dormant clans (gather, oven, pregnancy, baby growth) — [settlement_sim.md](settlement_sim.md). Same rules should apply to **Tier 1 campfire** and **Tier 2 flag** where brain mode allows.

---

## Build order (engineering)

1. **Docs** — this file + stamp [main.md](main.md), [earlygame.md](earlygame.md), [nomad.md](nomad.md).
2. **Cordage bond** on claimed herdables ([herdable_raiding.md](future%20implementations/herdable_raiding.md)).
3. **Enemy claim menu** — four raid verbs + `raid_intent.goal`.
4. **War Horn** — skip searchers with active herd/bond.
5. **Traits on women** + combine at birth; plan **`sex` at birth** (do not ship female promotion until ready).
6. **`enforce_baby_cap = true`** + Living Hut cap UX.
7. **Food: N days** HUD line on claim.
8. **Campfire** building gate — no Field / proto farming.
9. **Field + proto farming** on flag only.
10. **Wounds** spec + implementation.

---

## Doc stamp checklist

When editing guides, align:

- Proximity herd + context menu (not “right-click = instant herd” on all targets)
- Cordage bond for **claimed** herdables (planned)
- Tier 1 = **campfire** land claim; Tier 2 = **flag**
- Wipe = flag destroy; loot first
- Unique-hybrid genetics UI
- Off-screen settlement when claim dormant
- Wounds = planned
