# Nomadic Playstyle & Clan Migration

**Last updated:** June 2026 · **Implemented Nomad Mode:** [camp_relocation.md](camp_relocation.md) · **Tier 1 loop:** [earlygame.md](earlygame.md) · **Index:** [README.md](README.md)

Design for **Tier 1 campfire** play: survival, mobility, and **Nomad Mode** relocation without disbanding the clan.

**Related:** [earlygame.md](earlygame.md), [ai_clan_brain.md](ai_clan_brain.md), [leader_hut.md](leader_hut.md), [future implementations/village.md](future%20implementations/village.md).

---

## Design principle

**Campfire = survival and mobility.**  
**Land claim = production and territory.**

- **Nomadic:** Gather, herd, reproduce, **move the camp** (Nomad Mode). Lower footprint, fewer buildings.
- **Stationary:** Build, produce, defend, raid. Higher footprint, full production chains.

**Terminology:** **Nomad Mode** = clan relocation (player **ABANDON CAMP** or AI low-resources). **Migration** = wild animal corridor movement only — not used for clans.

---

## Campfire (Tier 1 — implemented today)

| Dimension | Campfire | Land Claim |
|----------|----------|------------|
| Identity | Mobile Tier 1 claim | Settled home |
| Inventory | 20 slots | 12+ slots (claim) |
| Radius | 250px | 400px |
| Buildings | Living Huts only (**max 3**) | Oven, dairy, farm, huts, etc. |
| ClanBrain | **Yes** — `brain_mode = "nomadic"` (higher herd/gather, lower defense) | **Yes** — settled tuning |
| Area of Hunt | No AoH ring | Yes (`AreaOfHunt`) |
| Fire | Auto-lit when wood present; **1 wood / 60s**; no manual off | N/A |
| Relocation | **Nomad Mode** — [camp_relocation.md](camp_relocation.md) | Fixed; upgrade chain |

**Campfire does:** Deposit, reproduction, clan join (herd into radius), warmth, basic home, defender/searcher quotas (nomadic brain), **ABANDON CAMP** relocation.

**Campfire does not (yet):** Production chains (oven/farm), NPC-initiated raids from player camp, travois pack-up flow (see backlog below).

---

## Nomad Mode (implemented)

Full step-by-step: **[camp_relocation.md](camp_relocation.md)**.

**Player:** Right-click campfire → **ABANDON CAMP** → all clan members march → place new campfire (clan name skipped) → old fire + orphan building loot **lost**.

**AI Stage 1:** `campfire.gd` tracks wood/food; when low for **60s**, leader walks **800–1500px** and spawns a new fire. ClanBrain **nomadic** pressures still run during camp life; relocation trigger lives on the **campfire**, not a separate ClanBrain migration impulse.

**During march:** pregnancies **frozen**, babies as **icons** on mother, **BREAK** and **upgrade blocked**, wood burn **paused**, combat stragglers **auto rejoin**.

**Tests:** `bash tools/run_nomad_mode_test.sh` (11 headless checks). Bundled in `run_earlygame_verify.sh` and `run_ultimate_npc_clanbrain_test.sh`.

---

## ClanBrain on campfire (nomadic mode)

Same `scripts/ai/clan_brain.gd` as land claims. On `Campfire`, `initialize()` sets `brain_mode = "nomadic"`:

- Higher **herd** and **gather** economic weights; lower **build** weight.
- Lower **defend** pressure; higher **search** / **gather** pressure vs settled clans.
- Player-owned campfires: brain runs for quotas/alerts; player drives raids/hunts via RTS (same as flag).

See **[ai_clan_brain.md](ai_clan_brain.md)** § Campfire.

---

## Future / backlog (not shipped)

### Seasonal pressure

Around Day 6, winter hint → stockpile or **migrate**. Not wired to Nomad Mode yet; use manual **ABANDON CAMP** or AI low-resource nomad today.

### ClanBrain “migration impulse” (phase3 concept)

Voluntary strike-out when clan is stable — separate from **implemented** AI low-resource Nomad Mode in `campfire.gd`.

### Travois & pack hut

- Clansmen carry travois (`PickUpTravoisTask`, `PlaceTravoisTask`) — designed, not full nomad pack-up UI.
- Dismantle hut → travois inventory — see earlygame § travois.

### Decay for abandoned structures

Orphan buildings: **60s grace** then despawn (inventories lost). Broader `DecayManager` batch decay — designed in earlygame, partial via `building_base.gd` grace.

### Open questions

- Animal migration follow (herd corridors vs human-driven nomad).
- Environment forcing migration (drought, winter) vs player/AI resource triggers.
- Full travois-led migration flow (steps 1–6 in old design doc) vs current **ABANDON CAMP** + place new fire.

---

## Summary checklist

| Concept | Status | Doc |
|---------|--------|-----|
| Campfire vs land claim split | **Shipped** | earlygame, bible |
| ClanBrain nomadic mode | **Shipped** | ai_clan_brain |
| Nomad Mode relocation | **Shipped** | camp_relocation |
| Auto wood burn / no manual fire off | **Shipped** | camp_relocation |
| Headless nomad tests in CI gates | **Shipped** | Ultimate_npc_clanbrain_test |
| Pack hut → travois | Designed | earlygame |
| Seasonal migration pressure | Concept | earlygame |
| ClanBrain migration impulse | Concept | phase3 |
| Full travois migration UX | Backlog | — |
