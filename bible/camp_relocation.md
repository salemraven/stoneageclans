# Camp relocation — Nomad Mode

Design guide for **moving the Tier 1 campfire** without disbanding the clan.

**Terminology:** **Nomad Mode** = clan relocation (player or AI). **Migration** = wild animal corridor movement only — not used for clans.

**Related:** [nomad.md](nomad.md), [earlygame.md](earlygame.md), [leader_hut.md](leader_hut.md)

---

## Principle

**The clan is not the fire.** `clan_name`, roster, bloodline, and persistent clan state stay when the physical campfire node is removed. Only the **anchor** (world position, old campfire inventory) changes.

---

## Nomad Mode flow (player)

1. Right-click your campfire → **ABANDON CAMP** (confirm dialog).
2. **Nomad Mode** starts: all clan members on the map join the march.
3. Women leave huts (`OccupationSystem.unassign`); pregnancies **freeze**; babies become **icons** on the mother.
4. Clansmen drop any animals they were herding (animals go wild).
5. Old buildings enter a **60s grace period**, then despawn (inventories **lost**).
6. Old campfire inventory is **lost** (nomads travel light).
7. Walk to a new spot and place a **new campfire** — clan name dialog is **skipped** if you already have a clan.
8. Old campfire despawns; pregnancies **resume**; nomad meta clears.

**BREAK** and **campfire upgrade** are **blocked** during Nomad Mode.

---

## Nomad Mode flow (AI Stage 1)

AI campfires always run wood/food decay (even off-screen). When wood ≤ threshold or food ≤ threshold for **60 seconds**, ClanBrain territory triggers **Nomad Mode**:

- Leader (`owner_npc` or oldest fighter) walks to a new site (800–1500 px away).
- Clan follows; same baby/pregnancy/hut rules as player.
- New campfire spawns at destination; old one completes Nomad Mode.

---

## Fire & fuel (automatic)

- Fire **auto-lights** when the campfire inventory has wood; **manual fire-off is disabled** (no UI toggle).
- While lit, wood burns on a **timer**: **1 wood every 60 seconds** (`BalanceConfig.campfire_wood_burn_interval`).
- When wood hits **0**, fire goes out and `_fire_off_from_depletion` is set (triggers panic / nomad rules below).
- Adding wood to a depleted fire **re-lights** it automatically.
- Wood burn is **paused** during **Nomad Mode** (`nomad_state != NONE`).

---

## Panic (women)

When campfire **wood = 0** OR **total edible food = 0** (after fire went out from depletion, or food truly empty):

- Women inside radius enter **`panic_state`** — erratic movement, no jobs.
- Panic ends when resources restored, Nomad Mode starts, or woman leaves radius.

Wood burns every **60 seconds** per wood (BalanceConfig). See **Fire & fuel** above.

---

## Reliability

- **NomadState** on campfire + **player meta** (`nomad_state`, `nomad_clan_name`) for persistence.
- **Stone requirement removed** — campfire no longer despawns when stone = 0.
- Combat stragglers **auto re-join** the nomad group when their fight ends.
- Leader death: **full possess** oldest clansman heir (camera, followers, nomad meta).

---

## Edge cases (confirmed)

| Situation | Behavior |
|-----------|----------|
| Stuck in Nomad forever | Stay until new fire placed or clan wiped |
| Who joins | **All** clan members on map |
| Old campfire inventory | **Lost** |
| Orphan building inventory | **Lost** |
| Max Living Huts at campfire | **3** |
| Upgrade during Nomad | **Blocked** |

---

## Code map

| Piece | File |
|-------|------|
| Nomad handler | `scripts/campfire.gd` |
| Context menu | `scripts/main.gd` (`abandon_camp`) |
| Panic state | `scripts/npc/states/panic_state.gd` |
| Building grace | `scripts/buildings/building_base.gd` |
| Player succession | `scripts/systems/player_succession.gd` |
| Tunables | `scripts/config/balance_config.gd` |
| Tests | `tools/test_nomad_mode.gd`, `bash tools/run_nomad_mode_test.sh` |

---

## Leadership and death (not relocation)

See [leader_hut.md](leader_hut.md). Death triggers succession — **not** automatic camp despawn. Relocation is always **Nomad Mode** or placing a new fire after pack-up.
