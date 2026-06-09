# Gather & Deposit – Definitions

**Version**: 4  
**Purpose**: Canonical definitions of how gather and deposit work in the codebase.

---

## Gather

**What it is**: Clansmen/cavemen collect resources from the environment and add them to their inventory.

### Who Can Gather

- **Clansmen** and **cavemen** only
- Not wild NPCs, not babies
- Must be in clan (land claim) for job-based gather; legacy can gather before claim

### Two Modes

| Mode | Trigger | How it works |
|------|---------|--------------|
| **Job-based** | `USE_GATHER_JOBS = true` (default) | Land claim generates gather jobs via `generate_gather_job()`. NPC pulls job with `_try_pull_gather_job()`. TaskRunner runs the job. No job → FSM evaluates (wander/idle/eat). |
| **Legacy** | `USE_GATHER_JOBS = false` | Direct gather loop in gather state: find target → move → gather → collect. |

### Legacy Gather Flow

1. **Find target** (`_find_target()`):
   - Detection range: `perception × 200`
   - Skip: cooldown, empty, enemy claim, `has_capacity() == false`, same-clan NPC within 100px
   - Pick nearest valid resource

2. **Move**: Steering to within **48px** of resource (NPCConfig.gather_distance)

3. **Gather**: 1s progress bar (NPCConfig.gather_duration). Moving >20px cancels.

4. **Collect** (`_collect_resource()`):
   - `resource.harvest()` → yields items
   - WHEAT → GRAIN
   - `inventory.add_item(resource_type, yield_amount)`

5. **Same-node rule**: Keep gathering from same node until inventory ≥ **80%** or node empty, then pick new target

6. **Exit to deposit**: When `used_slots >= threshold` (40% of max slots, min 3), call `_exit_to_deposit()`

### Inventory Threshold

- **Legacy**: `threshold = max(3, ceil(max_slots * 0.4))` → 40% of slots, min 3
- **`can_enter()`**: Must have `used_slots < threshold` (blocks entry if already full)

### Code

- `scripts/npc/states/gather_state.gd`

---

## Deposit

**What it is**: Clansmen/cavemen transfer items from their inventory into their land claim's inventory when near the claim.

### Who Can Deposit

- **Clansmen** and **cavemen** only
- Skipped during **craft** state (keeps stones for knapping)
- Must have clan (`get_clan_name()` non-empty)

### When Deposit Runs

- From `npc_base._check_and_deposit_items()` in `_physics_process`
- **Interval**: 0.5s normally; **0.1s** when inventory ≥ 4 slots used, or herding 2+ NPCs
- **Cooldown**: 1s after each successful deposit

### Conditions to Deposit

1. NPC within **100px** of land claim center (`_find_land_claim_for_deposit`)
2. Land claim inventory has space (`claim_inventory.has_space()`)
3. NPC inventory has items

### What Gets Deposited

- **Non-food**: All
- **Food**: Keep **1 food item total** (across all types); deposit the rest  
  Food types: Berries, Grain, Fiber, etc. (from `ResourceData.is_food()`)

### Process (Two-Pass)

**Pass 1 – Group items**

```
For each inventory slot:
  If food: keep 1 total, add rest to items_to_deposit
  If non-food: add all to items_to_deposit
  Group by item type (sum amounts)
```

**Pass 2 – Transfer**

```
For each item type in items_to_deposit:
  claim_inventory.add_item(type, amount)
  inventory.remove_item(type, amount)  # rollback claim on failure
```

### After Deposit

- Set `last_deposit_time` (cooldown)
- Clear `moving_to_deposit`, `is_depositing`
- Force FSM evaluation (e.g. herd_wildnpc)

### Edge Cases

- Land claim full → skip, log every 5s
- Claim fills mid-deposit → stop loop, don't rollback already-deposited items
- 1 food only → no deposit, no warning
- Craft state → no deposit

### Code

- `scripts/npc/npc_base.gd` → `_check_and_deposit_items()`, `_find_land_claim_for_deposit()`
- Deposit movement / "moving to deposit": wander state + `moving_to_deposit` meta

---

## Constants Summary

| Constant | Value | Location |
|----------|-------|----------|
| Gather distance | 48px | NPCConfig.gather_distance |
| Deposit range | 100px | npc_base `_find_land_claim_for_deposit` |
| Gather duration | 1s | NPCConfig.gather_duration |
| Inventory threshold (legacy) | 40%, min 3 | gather_state `_get_inventory_threshold()` |
| Same-node stop | 80% | INVENTORY_FULL_FOR_NODE |
| Food to keep | 1 total | npc_base `FOOD_TO_KEEP` |
| Deposit cooldown | 1s | npc_base |
| Deposit check interval | 0.5s / 0.1s | npc_base |

---

## Flow Overview

```
Gather (job or legacy) → inventory reaches threshold → _exit_to_deposit() →
  near claim? auto-deposit handles
  not near? set moving_to_deposit → wander moves to claim → auto-deposit when in range →
  deposit done → FSM eval → herd or gather
```
