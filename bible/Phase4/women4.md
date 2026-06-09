# Wild Women & Clanswomen – Definitions

**Version**: 4  
**Purpose**: Canonical definitions of how wild women and clanswomen work in the codebase.

---

## Overview

Women are NPCs with `npc_type == "woman"`. They exist in two forms:
- **Wild women**: No clan, outside land claims; can be herded by player/cavemen.
- **Clanswomen**: In a clan; reproduce, occupy buildings, work at buildings.

---

## Wild Women

**What it is**: A woman with no clan (`clan_name == ""`) and outside all land claims.

### Who Is Wild

`is_wild()` returns true when:
- `npc_type` is "woman", "sheep", or "goat" (cavemen are never wild)
- `clan_name == ""`
- Outside every land claim (distance to claim center > claim radius, default 400px)

### What Wild Women Do

- **Wander**: Only state they can enter (alongside herd when being herded)
- **Be herded**: Cavemen/player approach within 150px and roll chance to "capture"
- **Follow herder**: When `is_herded == true`, follow `herder` (player or caveman) toward land claim

### Herding Mechanics (`_try_herd_chance`)

- **Range**: 150px from leader
- **Chance**: 10% at max range, 80% at very close (<50px); proximity-based
- **Stealing**: Another clan can steal if closer than current herder; steal chance is 25% of normal, plus protection if herder is close
- **Same-clan**: Cannot steal from a clan mate
- **Ordered follow**: If `follow_is_ordered`, cannot be stolen
- **Cooldown**: 1s between steals

### Joining Clan

1. **Herded into claim**: Caveman/player herds wild woman into their land claim (radius 400px)
2. **Land claim placed on them**: Player places land claim while wild woman is inside
3. **Auto-join**: On player-owned claim, wild women inside auto-join; `set_clan_name(clan_name)` called; released from herd

### What Wild Women Cannot Do

- No gather (cavemen/clansmen only)
- No deposit (no clan)
- No reproduction (must be in clan)
- No occupy/work at building (must be in clan)
- No combat (women don’t enter agro/combat as primary; flee/defend if attacked)

### Code

- `scripts/npc/npc_base.gd`: `is_wild()`, `_try_herd_chance()`, `has_trait("herd")`, `can_join_clan()`
- `scripts/npc/states/herd_wildnpc_state.gd`: `_find_woman_to_herd()`, herding logic (cavemen herd women)
- `scripts/main.gd`: `_handle_npcs_in_new_land_claim` – auto-join when claim placed

---

## Clanswomen

**What it is**: A woman with `clan_name != ""` (in a clan).

### What Clanswomen Do

| State | Priority | Condition |
|-------|----------|-----------|
| **Reproduction** | 8.0 | In clan, inside land claim, reproduction component |
| **Occupy building** | 7.5 | Unoccupied building in clan |
| **Work at building** | 7.0–10.0 | Job from occupied building; 10.0 when actively working |
| **Wander** | 1.0 | Fallback; women in clan can wander inside claim |
| **Eat** | (eat state) | When hungry |
| **Defend / Combat** | (higher) | When attacked |

### Reproduction

- **Who**: Clanswomen only (wild women cannot reproduce)
- **Where**: Inside land claim (distance ≤ claim radius, default 400px)
- **Mate**: Player or caveman in same clan, inside land claim
- **Flow**: `reproduction_component.update()` → if not pregnant and cooldown expired → `_try_find_mate()` → find candidate → `_start_pregnancy()` → birth timer → baby spawned
- **Birth cooldown**: `ReproductionConfig.birth_cooldown`
- **State**: Reproduction state (priority 8.0) ensures woman can be in reproduction mode; logic lives in component

### Occupy Building

- **Who**: Clanswomen only; `is_wild() == false`
- **What**: Move to unoccupied building in clan, occupy it
- **Range**: 500px to find building; 64px to occupy
- **Priority**: 7.5

### Work at Building

- **Who**: Clanswomen only
- **What**: Pull jobs from occupied building (production, transport); TaskRunner executes
- **Priority**: 9.0 when job available; 10.0 when actively working (blocks reproduction interrupt)
- **Work range**: 128px from building

### What Clanswomen Cannot Do

- No gather (cavemen/clansmen only)
- No deposit (cavemen/clansmen only)
- No herd (they are herded; cavemen do the herding)

### Land Claim Restriction

- Women in clan are **not** restricted to stay inside land claim (unlike non-caveman/non-clansman NPCs)
- They can leave to be herded back, etc. (no hard boundary)

### Code

- `scripts/npc/components/reproduction_component.gd`
- `scripts/npc/states/reproduction_state.gd`
- `scripts/npc/states/occupy_building_state.gd`
- `scripts/npc/states/work_at_building_state.gd`
- `scripts/npc/npc_base.gd`: reproduction_component init for women

---

## Constants Summary

| Constant | Value | Location |
|----------|-------|----------|
| Herding range | 150px | npc_base `_try_herd_chance` max_range |
| Steal close range | 100px | npc_base (must be within 100px to steal effectively) |
| Protection distance | 150px | npc_base (herder close = harder to steal) |
| Stealing cooldown | 1s | npc_base |
| Herd NPC type priority (woman) | 1.2 | NPCConfig.herd_npc_type_priority_woman |
| Land claim radius | 400px | Default for reproduction, herding |
| Occupy arrive distance | 64px | occupy_building_state |
| Work range at building | 128px | work_at_building_state |

---

## Flow Overview

```
WILD WOMAN:
  Wander → (caveman/player approaches) → _try_herd_chance succeeds → is_herded=true, herder=leader →
  Follow herder → Enter land claim → Auto-join clan (set_clan_name) → CLANSWOMAN

CLANSWOMAN:
  Reproduction (8.0) OR Occupy (7.5) OR Work at building (7–10) OR Wander (1.0) OR Eat
  Reproduction: Inside claim → find mate (player/caveman) → pregnancy → birth → baby
```
