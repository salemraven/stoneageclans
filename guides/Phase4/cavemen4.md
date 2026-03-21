# Cavemen & Clansmen – Definitions

**Version**: 4  
**Purpose**: Canonical definitions of how cavemen and clansmen work in the codebase.

---

## Overview

Cavemen and clansmen are male worker NPCs that gather, herd, deposit, and fight. Both share nearly all behaviors; the main difference is **origin and role**:

- **Caveman**: AI clan leader; spawns without clan; can place land claim; flees from player when not agro
- **Clansman**: Player's clan member; spawns in clan; cannot place claim; can follow player (ordered follow)

There is **no conversion** between types—they are set at spawn.

---

## Cavemen

**What it is**: `npc_type == "caveman"`. AI clan leaders that compete with the player.

### Spawn

- Spawned without clan (`clan_name == ""`)
- Start with LANDCLAIM in inventory (can place claim when ready)
- Spawn position used as world boundary center until claim is placed
- Build cooldown: 10s after spawn before can place land claim
- **Never wild** (`is_wild()` always returns false for cavemen)

### What Cavemen Do

| State | Priority | Condition |
|-------|----------|-----------|
| **Herd wild NPC** | 10.6–10.9 | Wild women/sheep/goats in range |
| **Deposit** | 11.0 | Inventory full, near claim |
| **Gather** | 3.0–6.0 | Resources in range |
| **Craft** | (craft state) | Stones in inventory |
| **Eat** | (eat state) | Hungry |
| **Defend / Combat** | 12.0 | Intruder or combat |
| **Wander** | 0.5–3.0 | Fallback |

### Caveman-Specific Behavior

- **Place land claim**: Has LANDCLAIM item; places when ready; claim is NPC-owned
- **Flee from player**: When not in agro/combat, flees if player within 80px (`caveman_flee_player_distance`)
- **Agro**: When another caveman enters their land claim → agro state (territory defense)
- **Land claim entry**: Cavemen can enter any land claim (not evicted—they "visit")
- **Boundary**: Before placing claim, confined near spawn via `_apply_world_boundary`

### What Cavemen Cannot Do

- Cannot be herded (they herd others)
- Cannot reproduce (males; women reproduce with them)
- Cannot occupy/work at buildings (women only)

### Code

- `scripts/npc/npc_base.gd`: `_check_caveman_aggression`, flee logic, `is_wild` (caveman exception)
- `scripts/main.gd`: `_place_land_claim_for_npc`, caveman spawn

---

## Clansmen

**What it is**: `npc_type == "clansman"`. Members of the player's clan.

### Spawn

- Spawned with clan (`clan_name` set, e.g. when player creates clan)
- Typically inside player's land claim
- No LANDCLAIM in inventory (player places claim)
- **Never wild**

### What Clansmen Do

Same state set as cavemen: herd, deposit, gather, craft, eat, defend, combat, wander.

### Clansman-Specific Behavior

- **Follow player**: Player can drag clansman → ordered follow (`herd` state, priority 11.0)
- **Defend mode**: Player can set defend; clansman defends territory
- **Mirror hostility**: When `player_hostile`, clansmen mirror `is_hostile`
- **Land claim**: Cannot place claim (player does)
- **No flee from player**: Clansmen do not flee the player

### What Clansmen Cannot Do

- Cannot place land claim
- Cannot be herded
- Cannot reproduce (males)
- Cannot occupy/work at buildings (women only)

### Code

- `scripts/main.gd`: clansman spawn, drag logic
- `scripts/npc/states/herd_state.gd`: ordered follow

---

## Shared Behaviors (Cavemen & Clansmen)

### Gather

- Job-based (land claim generates jobs) or legacy (direct gather loop)
- Threshold: 40% of slots (min 3) → exit to deposit
- See `guides/Phase4/gather4.md`

### Deposit

- Auto-deposit when within 100px of land claim center
- Keep 1 food total; deposit rest
- See `guides/Phase4/gather4.md`

### Herd Wild NPCs

- Target: wild women, sheep, goats (`clan_name == ""`, outside claims)
- Detection: ~1500px; herding range 150px
- Cavemen must have clan (land claim) to enter herd state; clansmen always have clan
- Max distance from claim: 2000px
- Delivery cooldown: 28s after successful delivery

### Craft

- Can enter craft state (knap stones, etc.)
- Need stones in inventory; deposit skipped during craft

### Combat & Defend

- Both can enter agro, combat, defend states
- Cavemen: agro when another caveman enters their claim
- Clansmen: follow player hostility and defend commands

### Land Claim Movement

- Both can leave land claim to herd and gather
- Not restricted to stay inside (unlike women who are not caveman/clansman)

---

## Constants Summary

| Constant | Value | Location |
|----------|-------|----------|
| Flee from player (caveman) | 80px | NPCConfig.caveman_flee_player_distance |
| Build cooldown after spawn | 10s | NPCConfig.caveman_build_cooldown_after_spawn |
| Herd detection range | 1500px | herd_wildnpc_state, NPCConfig |
| Herd max distance from claim | 2000px | NPCConfig.herd_max_distance_from_claim |
| Herd delivery cooldown | 28s | herd_wildnpc_state DELIVERY_COOLDOWN_SEC |
| Herd NPC type priority (woman) | 1.2 | NPCConfig.herd_npc_type_priority_woman |

---

## Flow Overview

```
CAVEMAN:
  Spawn (no clan) → Wander near spawn → Place land claim (clan_name set) →
  Herd / Gather / Deposit (same as clansman)
  Flee player when <80px (non-agro)

CLANSMAN:
  Spawn (in clan) → Herd / Gather / Deposit / Craft / Eat
  Follow player when ordered (drag)
  Defend when set
```
