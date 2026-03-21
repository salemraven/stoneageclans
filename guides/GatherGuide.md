# Gather & Deposit System Guide
**Version**: 5.1 (Event-Driven, Lease-Based)  
**Last Updated**: February 18, 2026  
**Status**: ✅ Production Ready  
**See also**: `guides/Phase4/gather4.md` (canonical definitions)

**v5.1 changes**: Pre-claim block, move cancel 32px (configurable), lease 90s, gather priority 6 (productivity mode), deposit priority 12 when moving, wander uses config threshold.

---

## Overview

The Gather & Deposit system is the core resource collection and management loop for **cavemen and clansmen**. NPCs gather resources from the environment and automatically deposit them into their land claim's inventory.

**Core Principle**: NPCs must always be productive. They gather resources until their inventory reaches the deposit threshold (40% of slots, min 3), then move to their land claim to deposit items automatically (keeping 1 food item total for personal use).

**Architecture**: **Job-only, event-driven**. Land claim (authority) issues gather jobs when workers request them. NPCs execute leases only—no resource scanning. ResourceIndex provides centralized, spatially-indexed resource lookup.

---

## System Architecture

### Components

1. **Gather State** (`scripts/npc/states/gather_state.gd`) - Requests jobs; no resource scanning
2. **Land Claim** (`scripts/land_claim.gd`) - Authority: generates gather jobs via `ResourceIndex.query_near()`
3. **ResourceIndex** (`scripts/systems/resource_index.gd`) - Centralized, spatially-indexed resource lookup (autoload)
4. **GatherJob** (`scripts/ai/jobs/gather_job.gd`) - Lease: MoveTo(resource) → GatherTask → MoveTo(claim)
5. **TaskRunner** (`scripts/ai/task_runner.gd`) - Runs jobs; releases resource on job end/cancel/expiry
6. **Auto-Deposit** (`scripts/npc/npc_base.gd`) - Automatic deposit when near land claim
7. **Wander State** (`scripts/npc/states/wander_state.gd`) - Handles deposit movement when inventory full

### Flow

```
NPC idle → Request job (throttled 0.5s) → Land claim queries ResourceIndex → Issues job (lease) →
  MoveTo(resource) → GatherTask (same-node 80%) → MoveTo(claim) → Auto-deposit on arrival →
  Job complete → Release resource → Request next job
```

---

## How It Works

### Phase 1: Gathering Resources (Job-Only)

**Entry Conditions**:
- Caveman or clansman type (`npc_type == "caveman"` or `"clansman"`)
- **Land claim required** (claim generates jobs) — `clan_name != ""` blocks gather when no claim (pre-claim fix)
- Inventory must be below threshold (40% of slots, min 3)
- Not recently failed (3s cooldown after no-job to prevent spam)
- FSM evaluates state priorities; gather has priority 6.0 (productivity mode) or 5.6 (base from config); both beat herd-search (5.5) when no herd targets

**Gathering Process** (GatherTask via TaskRunner):
1. **Request Job**: Gather state calls `_try_pull_gather_job()` (throttled 0.5s)
2. **Land Claim Authority**: Uses `ResourceIndex.query_near()` to find resources; soft-cost clan spread; reserves slot
3. **MoveTo(resource)**: NPC moves within 48–56px of resource
4. **GatherTask**: Harvest with progress bar; stay until 80% or node depleted
5. **Stay in place**: Moving >32px cancels gather (`NPCConfig.gather_move_cancel_threshold`) — increased from 20px to reduce bump cancellations
6. **Collect**: Harvest → add to inventory; release resource when done
7. **MoveTo(claim)**: If `skip_deposit == false`, move to claim; auto-deposit on arrival

**No Resource Scanning**: NPCs never scan resources. Authority (land claim) queries ResourceIndex and issues jobs.

**ResourceIndex** (`scripts/systems/resource_index.gd`):
- **Spatial grid**: cell_size=200px; only cells overlapping query circle are checked
- **Registration**: GatherableResource and GroundItem call `register(self)` / `unregister(self)`
- **Query**: `query_near(position, radius, filters)` → resources sorted by distance
- **Filters**: `exclude_cooldown`, `exclude_no_capacity`, `exclude_empty`, `exclude_position_enemy_claim`, `resource_type`

### Phase 2: Inventory Management

**Inventory Size**: 10 slots (varies by NPC; default 10)

**Threshold**: 40% of max slots, minimum 3
- **Formula**: `max(3, ceil(max_slots * 0.4))` → for 10 slots = 4 slots
- **Why 40%?**: More frequent deposit trips, more total gathers per run
- **Triggers**: Deposit movement when `used_slots >= threshold`

**Food Item Handling**:
- **Keep 1 food item TOTAL** (across all food types, not per type)
- Deposit all other items (including excess food beyond 1)
- Food types: Berries, Grain, Fiber

**Inventory Check Locations**:
1. **`can_enter()`**: Prevents entering gather state if inventory already at threshold (fixes immediate exit bug)
2. **`update()`**: Checks every frame, exits to deposit if `used_slots >= threshold`
3. **`get_priority()`**: Lowers priority to 5.0 when at threshold (allows deposit movement to take precedence)

**Same-node rule** (GatherTask): Collect from same resource until inventory ≥ 80% (`NPCConfig.gather_same_node_until_pct`) or node depleted; then `release()` and job completes.

### Phase 3: Moving to Deposit

**Trigger**: Inventory reaches threshold (40%, min 3 slots)

**Process**:
1. **Check Land Claim**: Does `clan_name` exist?
   - If NO: Continue gathering (can't deposit without land claim)
   - If YES: Continue to step 2
2. **Check Distance**: Is NPC within deposit range of land claim center?
   - **Deposit range**: 100px (NPCConfig.deposit_range)
   - If within range: Auto-deposit handles
   - If NO: Exit gather state → Enter wander state (deposit movement)
3. **Set Flags**: `npc.set_meta("moving_to_deposit", true)`, `npc.set_meta("is_depositing", true)`
4. **Wander State**: Moves NPC directly to land claim center
5. **Arrival**: Once within deposit range (100px), flags cleared, auto-deposit runs

**Movement Details**:
- Uses steering agent: `steering_agent.set_arrive_target(claim_pos)`
- Direct path to land claim center

### Phase 4: Auto-Deposit

**Trigger**: NPC within **100px** of land claim center AND has items in inventory

**Frequency**: 
- **Default**: Check every 0.5 seconds
- **Faster (0.1s)**: When inventory ≥ 4 slots used, OR herding 2+ NPCs

**Cooldown**: 1 second after each deposit (prevents multiple rapid deposits)

**Conditions**:
- Land claim inventory must have space (`claim_inventory.has_space()`)
- Skipped during **craft** state (NPC keeps stones for knapping)

**Process** (Two-Pass System):

**Pass 1: Collect Items to Deposit**:
```
For each inventory slot:
  1. Get item_type and item_count
  2. If food item:
     - Count total food items across all slots
     - Keep 1 food item TOTAL (not per type)
     - Deposit all excess food
  3. If non-food item:
     - Deposit all items
  4. Add to items_to_deposit dictionary (grouped by type)
```

**Pass 2: Deposit All Items**:
```
For each item type in items_to_deposit:
  1. Get total amount to deposit
  2. Add to land claim inventory: claim_inventory.add_item(item_type, amount)
  3. If successful:
     - Remove from NPC inventory: inventory.remove_item(item_type, amount)
     - Count total items deposited
  4. If removal fails:
     - Rollback: Remove from land claim inventory
```

**After Deposit**:
- Set cooldown: `set_meta("last_deposit_time", current_time)`
- Clear deposit flags: `remove_meta("moving_to_deposit")`, `remove_meta("is_depositing")`
- Force FSM evaluation: Returns to herd_wildnpc state (high priority)
- Log deposit: `✅ AUTO-DEPOSIT: [name] deposited [count] items to land claim '[clan]'`

**Result**: Entire inventory (except 1 food item total) deposited in single transaction

**Edge case**: Land claim inventory full → skip deposit, log every 5s; NPC continues gathering

### Instrumentation (Clan Deposits)

**CompetitionTracker** (autoload) tracks deposits per NPC and per clan:
- `record_deposit(npc_name, clan_name, item_type, amount)` - Called by auto-deposit
- `get_clan_deposits()` - Returns `{clan_name: {total_items, resources: {ResourceType: count}}}`
- `print_clan_deposits()` - Logs per-clan totals to console (called on game exit)

### Phase 5: Continuous Cycle

**After Deposit Completes**:
- Inventory drops below threshold (items removed during deposit)
- Gather state check: `used_slots >= threshold` now returns FALSE
- NPC automatically resumes gathering
- Cycle repeats indefinitely

**The Loop** (10 slots, threshold 4):
```
Gather (1-3 items) → Gather (4 items = threshold) → Move to Deposit → Deposit (3 items, keep 1 food) → 
Inventory (1/10 slots) → Gather (2 items) → Gather (4 items) → ...
```

**Why It Works Indefinitely**:
1. **Resources respawn**: After 3 gathers, resource enters cooldown (120s default), then respawns
2. **Land claim inventory**: Must have space (`has_space()`); if full, NPC continues gathering (log every 5s)
3. **Auto-deposit reliable**: Checks 0.5s (or 0.1s when busy), runs when within 100px
4. **No state conflicts**: Gather and deposit don't conflict (deposit is automatic)
5. **Proper state transitions**: Gather exits cleanly, wander handles movement, gather resumes
6. **Priority handling**: Defend, combat, following (herd) take precedence over gathering
7. **Herd vs gather**: When no herd target in range, `priority_herd_wildnpc_searching` (5.5) < gather (5.6 base or 6.0 productivity), so cavemen prefer gathering

---

## Key Mechanics

### Resource Spawning

**Distribution**: Random across game map (2000px radius around player position)

**Count**: 40 resources spawned at game start

**Respawn**: Resources enter cooldown after 3 gathers, regenerate after cooldown

**Cooldown System**:
- Resource can be gathered 3 times before entering cooldown
- Cooldown duration: `BalanceConfig.resource_cooldown_seconds` (default 120s)
- During cooldown: Resource appears darker (bush swaps to bushoff texture)
- After cooldown: Resource resets and can be gathered again

**Code Location**: `scripts/gatherable_resource.gd`

**Cooldown**: `BalanceConfig.resource_cooldown_seconds` (default 120s in playtest; was 90s in older builds)

### Gatherable Resource Types

| Type | Name | max_workers |
|------|------|-------------|
| WOOD | Wood | 3 |
| STONE | Stone | 2 |
| BERRIES | Berries | 1 |
| WHEAT | Wheat (→ GRAIN) | 1 |
| FIBER | Fiber | 1 |

WHEAT is converted to GRAIN on harvest (same as legacy). Berries, Grain, Fiber are food for `ResourceData.is_food()`.

### Detection Range

**Perception Calculation**:
```
detection_range = perception_stat × perception_range_multiplier
detection_range = 50.0 × 200.0 = 10,000px (theoretical)
Effective range: ~1600px (capped for performance)
```

**Perception Multiplier**: 200.0 (from `NPCConfig.perception_range_multiplier`)

**Gather Distance**: 48px (must be within 48px to gather)

### Deposit Range

**Range**: **100px** from land claim center (`NPCConfig.deposit_range`)

**Unified**: All deposit checks use the same config value.

**Deposit Check**: 0.5s normally; 0.1s when inventory ≥ 4 slots or herding 2+

**Cooldown**: 1 second after deposit (prevents multiple calls)

### Inventory Thresholds

**40% of max slots, min 3**: Trigger deposit movement
- Formula: `max(3, ceil(max_slots * 0.4))`
- For 10 slots → threshold = 4
- More frequent trips → more total gathers per run

**Deposit Amount**: Entire inventory except 1 food item total
- Non-food items: Deposit all
- Food items: Keep 1 total (across all types), deposit rest
- Land claim inventory must have space (`has_space()`)

---

## State Machine Integration

### Gather State

**Priority**: 6.0 (productivity mode) or 5.6 (base from config) when inventory < threshold; 5.0 when at threshold; 1.0 if no clan

**Conditions**:
- **can_enter()**: 
  - Must be caveman or clansman (not wild NPC, not baby)
  - **Pre-claim block**: `clan_name != ""` — blocks gather when no land claim
  - Cannot be defending, in combat, or following
  - Inventory must be < threshold (prevents immediate exit bug)
  - Not within 3s of last no-job failure (prevents spam)
- **get_priority()**: 
  - 6.0 if `caveman_productivity_test >= 1.0` and inventory < threshold (beats herd-search 5.5)
  - 5.6 from config (`priority_gather_other`) if inventory < threshold — always beats herd-search (5.5) for productive cavemen
  - 5.0 if at threshold (lower priority, allows deposit movement)
  - 1.0 if no land claim (low priority; job-only requires claim)

**State Transitions**:
- **Enter**: When jobs available and inventory < threshold
- **Exit**: Defend/combat/follow take precedence; or no job (after 3s retry cooldown) → Wander
- **Stay**: When TaskRunner has active job

**Job-only flow**: `_try_pull_gather_job()` → TaskRunner runs job; no job → `_no_job_retry_time` (3s), FSM eval (wander/idle/eat)

**Code Location**: `scripts/npc/states/gather_state.gd`

---

## Job-Only Gather System (Phase 5–6)

Gather state **only** pulls jobs from the land claim. No legacy perception-based fallback. NPCs are "zero-intelligence workers": they execute leases only.

### GatherJob (Lease) Structure

```
MoveTo(resource, 48px) → GatherTask → [optional] MoveTo(land_claim, 100px)
```

**Tasks** (in order):
1. **MoveToTask** - Move to resource within 48px (or 56px for GatherTask lock-on)
2. **GatherTask** - Harvest from resource; stays until inventory 80% or node depleted; uses `release()` when done
3. **MoveToTask** - Move to land claim within 100px (only if `skip_deposit == false`). **No DropOff**—auto-deposit handles transfer on arrival.

**Lease fields**: `expire_time`, `gather_until_pct`, `deposit_at_pct`. TaskRunner cancels job if `expire_time` exceeded (`BalanceConfig.lease_expire_seconds`, default **90s** — extended for distant resources).

**skip_deposit**: When inventory < 80% of slots, job skips MoveTo(claim) (NPC gathers more first).

### Land Claim Job Generation

**Function**: `land_claim.generate_gather_job(worker)` → returns `GatherJob` or `null`

**Logic** (`_find_nearest_available_resource`):
- **ResourceIndex**: `ResourceIndex.query_near(claim_pos, search_range, filters)`—no `get_nodes_in_group`
- **Search range**: 3× land claim radius (e.g. 1200px for 400px radius)
- **First pass**: Resource worker is already at (within 60px) or current job target → use it
- **Second pass**: **Soft-cost clan spread**: `score = distance + (nearby_clan_mates × clan_spread_penalty)`. Pick lowest score. No hard skip—always returns best option.
- **Reservation**: Calls `resource.reserve(worker)` before creating job; fails if resource full

### Resource Capacity & Reservation

**GatherableResource** (`scripts/gatherable_resource.gd`):
- **max_workers** per resource type: Wood 3, Stone 2, Berries 1, Wheat 1, Fiber 1
- **reserve(worker)** - Reserve slot when job created; returns false if full
- **release(worker)** - Called by GatherTask/TaskRunner when job ends (complete, fail, cancel)
- **has_capacity()** - `reserved_workers.size() < max_workers`

**TaskRunner** releases resource when job completes, fails, or is cancelled.

**Job interruption**: Tasks check `npc.should_abort_work()` (defend target, combat target, or follow ordered) → FAILED → TaskRunner cancels job, releases resource. **Defend decoupling**: `defend_target` is set only when NPC actually enters defend state (not when chosen), so jobs are not cancelled prematurely.

### GatherTask Details

- **Gather distance**: 56px (slightly larger than 48px for earlier lock-on)
- **Move cancel**: Moving >32px during gather cancels (`NPCConfig.gather_move_cancel_threshold`) — was 20px
- **Alternative resource**: Uses `ResourceIndex.query_near(npc_pos, 800px, {resource_type})` when current node invalid/depleted
- **Same-node rule**: Collect until inventory 80% or node depleted; then `release()` and SUCCESS

### Wander State

**Primary Purpose**: Brief reset after task completion; wander behavior

**Secondary Purpose**: Move to deposit when inventory at threshold

**Deposit Movement**:
1. Threshold from config: `NPCConfig.gather_deposit_threshold` (40%) — same as gather state
2. Check for `moving_to_deposit` flag or `used_slots >= threshold`
3. If triggered: Set flags, move to land claim center
4. **Priority 12.0** when `moving_to_deposit` — above herd_wildnpc (11.5) so deposit completes
5. Once within 100px: Clear flag, auto-deposit handles items

**Code Location**: `scripts/npc/states/wander_state.gd`

### Auto-Deposit Function

**Location**: `scripts/npc/npc_base.gd` - `_check_and_deposit_items()`

**Called**: Every frame in `_physics_process()`, checks every 0.5s (or 0.1s when inventory ≥ 4 or herding 2+)

**Requirements**:
- NPC type: caveman or clansman
- Has inventory with items
- Has land claim (`clan_name` exists)
- Within 100px of land claim center
- Land claim inventory has space
- Not in craft state
- Cooldown expired (1 second since last deposit)

**Process**:
1. Find land claim matching `clan_name`
2. Check distance (must be ≤ 100px)
3. Group all items by type (first pass)
4. Keep 1 food item total (across all food types)
5. Deposit all other items (second pass)
6. Log success and set cooldown

**After Deposit**: Forces FSM evaluation to return to herd_wildnpc state (high priority)

---

## Constants & Configuration

### NPC Config Values (Centralized)

```gdscript
# scripts/config/npc_config.gd
deposit_range = 100.0               # Deposit range from claim center (pixels)
gather_deposit_threshold = 0.4      # 40% = move to deposit
gather_same_node_until_pct = 0.8    # 80% = leave current node
gather_move_cancel_threshold = 32.0 # Pixels - moving beyond this during gather cancels (was 20)
clan_spread_penalty = 50.0          # Soft-cost: add per clan mate near resource
gather_duration = 0.5               # Time to gather one item (seconds)
gather_distance = 48.0              # Distance to resource (pixels)
perception_range_multiplier = 200.0 # Resource detection range multiplier
priority_gather_other = 5.6         # Gather state priority (must beat herd_wildnpc_searching 5.5); productivity mode overrides to 6.0
priority_herd_wildnpc_searching = 5.5  # Herd priority when no target — gather (5.6+) beats this
```

### Balance Config

```gdscript
# scripts/config/balance_config.gd
lease_expire_seconds = 90.0         # Job expires after 90s; releases resource (extended for distant resources)
```

### Auto-Deposit (npc_base.gd)

- Check interval: 0.5s default; 0.1s when inv ≥ 4 or herding 2+
- Cooldown: 1s after deposit
- Keep 1 food item total

### Resource Config Values

```gdscript
# scripts/gatherable_resource.gd
COOLDOWN_DURATION = BalanceConfig.resource_cooldown_seconds  # Default 120s (playtest)
MAX_GATHERS_BEFORE_COOLDOWN = 3    # Gather 3 times before cooldown
# Move cancel: NPCConfig.gather_move_cancel_threshold (32px) — used by GatherTask
```

---

## Critical Fixes Applied

### Fix #0: Pre-Claim Block & Defend Decoupling (Feb 2026) ✅ FIXED

**Pre-claim block**: Gather `can_enter()` returns false when `clan_name == ""` for cavemen/clansmen. Prevents wasted FSM cycles when no job source exists.

**Defend decoupling**: `defend_target` is set in defend state `enter()`, not `can_enter()`. Jobs are only cancelled when NPC actually enters defend, not when merely selected.

### Fix #1: Immediate Exit Bug ✅ FIXED

**Problem**: Gather state was entering then immediately exiting (0.1-0.5 seconds)

**Root Cause**: `can_enter()` didn't check inventory, so caveman with 7+ slots could enter, then `update()` would immediately exit

**Fix**: Added inventory check to `can_enter()`:
```gdscript
func can_enter() -> bool:
    # ... other checks ...
    var used_slots: int = _get_used_slots()
    if used_slots >= INVENTORY_THRESHOLD:
        return false  # Inventory full - can't gather, need to deposit first
    return true
```

**Result**: Gather state no longer enters if inventory already full, preventing immediate exit

### Fix #2: Deposit Range Increased ✅ FIXED

**Problem**: Cavemen had to be very close (200px) to deposit

**Fix**: Deposit range 100px (NPCs must approach land claim building)

**Result**: Cavemen must approach land claim building (100px), visible deposit behavior

### Fix #3: Food Keeping Logic ✅ FIXED

**Problem**: Was keeping 1 food item per slot instead of 1 food item total

**Fix**: Modified to track total food items across all slots, keep only 1 total

**Result**: All excess food items are now properly deposited

### Fix #4: After Deposit State Transition ✅ FIXED

**Problem**: After deposit, caveman might not return to productive state immediately

**Fix**: Added FSM evaluation after deposit to force return to herd_wildnpc state (high priority)

**Result**: Cavemen immediately return to productive activities after depositing

---

## Edge Cases Handled

### Edge Case 1: No Resources Found
- **Handling**: `generate_gather_job` returns null → set `_no_job_retry_time` (3s) → FSM eval (wander/idle/eat)
- **Recovery**: `can_enter()` blocks gather for 3s; then NPC can retry. Resources respawn after cooldown.

### Edge Case 2: Resource Enters Cooldown During Gather
- **Handling**: GatherTask tries `_find_alternative_resource()` via ResourceIndex; switches if found
- **Recovery**: If no alternative, job FAILED → resource released, NPC requests new job

### Edge Case 3: Land Claim Destroyed
- **Handling**: Continue gathering (can't deposit without land claim)
- **Recovery**: Place new land claim when ready, deposit resumes
- **Code**: `if clan_name == "": continue_gathering()` (graceful degradation)

### Edge Case 4: Inventory Exactly at Threshold
- **Handling**: Consistent check (`used_slots >= threshold`), deposit triggered
- **Recovery**: Deposit removes items, inventory below threshold, gathering resumes
- **Result**: Consistent behavior, always deposits

### Edge Case 5: Multiple NPCs at Same Resource
- **Handling**: Resource has `max_workers` (1–3); `reserve()`/`has_capacity()` prevent over-saturation
- **Soft-cost spread**: Land claim uses `score = distance + nearby_clan_mates * clan_spread_penalty`—prefers less crowded resources
- **Result**: Max 1–3 workers per resource; natural distribution across resources

### Edge Case 6: Deposit While Gathering New Item
- **Handling**: Check happens before collection, deposit triggered at threshold
- **Recovery**: Deposit happens, new item collected, inventory below threshold (after deposit)
- **Result**: Smooth transition, no blocking

### Edge Case 7: Only 1 Food Item Remaining
- **Handling**: Deposit function called but nothing to deposit (expected - we keep 1 food)
- **Recovery**: Warning suppressed, this is expected behavior
- **Result**: No noisy warnings for expected behavior

---

## Productivity Rules

### Always Productive - Indefinite Operation

**Core Rule**: Cavemen must always be productive. Not doing anything is not an option. Standing in one spot or wandering for more than 1 second is not an option. They must be doing something.

**How Indefinite Operation is Guaranteed**:

1. **Productivity from Spawn**:
   - Cavemen place land claim (build state) or join existing clan
   - Gather state requires land claim (job-only)
   - Once claim exists, jobs flow immediately
   - **Result**: Productive as soon as claim is placed

2. **Continuous Gather/Deposit Loop**:
   - Resources always available (40 initial + respawn every 90s)
   - Inventory always has room (40% threshold ensures frequent deposits)
   - Deposit always works (two-pass system, cooldown prevents multiple calls)
   - State transitions always work (explicit conditions, clear exits)
   - **Result**: Loop never breaks

3. **No Blocking Conditions**:
   - No "waiting for deposit to complete" (auto-deposit is automatic)
   - No "inventory full, can't gather" (threshold prevents this)
   - No "no resources available" (resources respawn continuously)
   - No "stuck in state" (wander max 1 second, then forced to find productive state)
   - **Result**: Never blocked, always productive

4. **Self-Healing System**:
   - No resources found → Wait gracefully, resources respawn
   - Resource in cooldown → Target cleared, new target found
   - Land claim destroyed → Continue gathering, place new claim when ready
   - Moving to deposit interrupted → Flag persists, eventually reaches deposit location
   - **Result**: Recovers from any issue automatically

---

## Code Architecture

### File Structure

```
scripts/
├── npc/
│   ├── states/
│   │   ├── gather_state.gd          # Job request only; no resource scanning
│   │   └── wander_state.gd          # Deposit movement
│   └── npc_base.gd                  # Auto-deposit function
├── ai/
│   ├── jobs/
│   │   └── gather_job.gd            # MoveTo → GatherTask → MoveTo (lease, expire_time)
│   ├── tasks/
│   │   ├── gather_task.gd            # Harvest, same-node 80%, ResourceIndex for alternatives
│   │   └── move_to_task.gd           # Steering to position
│   └── task_runner.gd                # Runs jobs; lease expiry; releases resource on end
├── systems/
│   └── resource_index.gd            # Spatial grid; query_near; register/unregister (autoload)
├── land_claim.gd                     # generate_gather_job; ResourceIndex + soft-cost spread
├── config/
│   ├── npc_config.gd                # deposit_range, gather_*, clan_spread_penalty
│   └── balance_config.gd            # lease_expire_seconds
└── gatherable_resource.gd           # reserve/release, has_capacity; registers with ResourceIndex
```

### Key Functions

**Gather State** (`gather_state.gd`):
- `can_enter()` - Inventory < threshold, not wild, not defend/combat/follow, not within 3s of no-job failure
- `update()` - If no job: throttle, `_try_pull_gather_job()`; on fail set `_no_job_retry_time`, force eval
- `_try_pull_gather_job()` - Pull job from land claim

**ResourceIndex** (`resource_index.gd`):
- `register(resource)` / `unregister(resource)` - Called by GatherableResource, GroundItem
- `query_near(position, radius, filters)` - Returns resources in range, sorted by distance
- `is_position_in_enemy_claim(tree, pos, clan)` - Static territory helper

**Land Claim** (`land_claim.gd`):
- `generate_gather_job(worker)` - Query ResourceIndex, soft-cost clan spread, reserve, create GatherJob

**Auto-Deposit** (`npc_base.gd`):
- `_check_and_deposit_items()` - Main deposit function
  - Checks every 0.5 seconds
  - 1-second cooldown after deposit
  - Two-pass deposit system (collect then deposit)
  - Deposits entire inventory except 1 food item total
  - Forces FSM evaluation after deposit

**Wander State** (`wander_state.gd`):
- `update()` - Deposit movement logic
  - Uses `gather_deposit_threshold` (40%) for consistency with gather state
  - Checks for `moving_to_deposit` flag or `used_slots >= threshold`
  - Moves to land claim when inventory at threshold
  - Handles deposit movement when gather state exits
- `get_priority()` - Returns 12.0 when `moving_to_deposit` (beats herd_wildnpc 11.5)

---

## Testing & Verification

### Expected Metrics

**Time to First Productive Action**: < 2 seconds
- Immediate gathering possible (before land claim)
- Build cooldown: 10 seconds (reduced from 15s)

**Deposit Success Rate**: 100%
- Entire inventory deposits at once
- Cooldown prevents multiple calls
- Proper state transitions

**Gather/Deposit Cycles**: 10+ cycles per 3 minutes
- Continuous operation
- No interruptions
- Efficient movement

**Time Wasted**: < 1 second (0.5% of test duration)
- No idle states
- No unproductive wandering
- Immediate productive actions

### Test Commands

```bash
# Run 2-minute AI clan test (headless)
./Tests/run.sh ai-clan 120

# Re-analyze existing run
./Tests/run.sh analyze Tests/results/ai_clan_<timestamp>
```

### What to Monitor

**Console Logs**:
- `GATHER_TASK:` - GatherTask completions
- `GATHER_JOB:` - Job pulled from land claim
- `📊 Competition:` - Per-deposit logging (npc, clan, type, count)
- `✅ AUTO-DEPOSIT:` - Successful deposits
- `📦 DEPOSITS PER CLAN:` - Per-clan totals (on game exit; CompetitionTracker.print_clan_deposits())

**Metrics to Check**:
- Total gathers per caveman
- Total deposits per caveman
- Max inventory reached (should stay near threshold)
- Idle entries (should be 0)
- Parse/runtime errors (should be 0)

---

## Troubleshooting

### Common Issues

**Issue**: NPC not gathering
- **Check**: Does gather state `can_enter()` return true?
- **Check**: Is inventory < threshold (40%, min 3)?
- **Check**: Has land claim? Does `generate_gather_job` return a job? (ResourceIndex has resources?)
- **Check**: Within 3s of last no-job failure? (`_no_job_retry_time`)

**Issue**: Deposits not happening
- **Check**: Is NPC within 100px of land claim center?
- **Check**: Does land claim inventory have space (`has_space()`)?
- **Check**: Is deposit cooldown expired (1 second)?
- **Check**: NPC not in craft state?
- **Fix**: Verify land claim exists and `clan_name` matches

**Issue**: Gather state exits immediately
- **Check**: Is inventory already at threshold when entering?
- **Fix**: Verify `can_enter()` inventory check is working (should prevent entry)

**Issue**: Multiple partial deposits
- **Check**: Is deposit cooldown working?
- **Check**: Is two-pass deposit system collecting all items?
- **Fix**: Verify `last_deposit_time` meta is being set correctly

**Issue**: Stuck in "moving to deposit" loop
- **Check**: Is gather state exiting properly?
- **Check**: Is wander state handling deposit movement?
- **Fix**: Verify `moving_to_deposit` flag is set/cleared correctly

**Issue**: Food items not being deposited
- **Check**: Is food keeping logic working correctly?
- **Check**: Are there multiple food items in inventory?
- **Fix**: Verify food keeping tracks total food (not per slot)

**Issue**: Land claim full, can't deposit
- **Check**: `claim_inventory.has_space()` returns false
- **Result**: NPC continues gathering; log every 5s. Player must make room or upgrade claim.

---

## Design Principles

### Simplicity First

1. **Single Responsibility**: Each component does one thing
2. **Avoid Premature Optimization**: Simple is better than complex
3. **Explicit Over Implicit**: Clear logic, no hidden behavior
4. **Minimize State Transitions**: Fewer transitions, fewer failure points
5. **Fail Gracefully**: Always has fallback
6. **Code Clarity Over Cleverness**: Easy to understand
7. **Remove Duplication**: Single source of truth

### What Was Removed (Old System)

- ❌ Distance-based deposit thresholds
- ❌ Search mode with increased AOP
- ❌ Resource clustering bonuses
- ❌ Balanced gathering (land claim inventory balance)
- ❌ Complex priority calculations
- ❌ Multiple gather target finding functions
- ❌ Duplicate deposit logic
- ❌ Deposit state machine
- ❌ Complex clan_name matching fallbacks

### What We Have Now (Current System)

- ✅ Simple nearest-resource search
- ✅ Single detection range (1600px)
- ✅ Single gather distance (48px)
- ✅ 40% inventory threshold (min 3)
- ✅ 100px deposit range
- ✅ Auto-deposit in background (no state needed)
- ✅ Simple state transitions (gather ↔ wander)
- ✅ Clean, linear flow

---

## Summary

The Gather & Deposit system is a **clean, simplified, reliable** implementation that ensures **indefinite operation** through simple design principles and robust edge case handling.

### Key Features

✅ **40% inventory threshold** (min 3 slots) - more frequent deposit trips  
✅ **100px deposit range** - NPCs must approach land claim building  
✅ **1 food item total kept** - proper food management  
✅ **Job-only** - land claim issues leases; NPCs execute only  
✅ **ResourceIndex** - spatially-indexed, O(cells) queries  
✅ **Lease expiry** - stuck jobs release after 90s (extended for distant resources)  
✅ **Soft-cost clan spread** - natural distribution across resources  
✅ **Two-pass deposit system** - reliable atomic deposits  
✅ **Clan deposit instrumentation** - CompetitionTracker.get_clan_deposits(), print_clan_deposits()  

### The Simple Loop

1. **Request** job from land claim (throttled 0.5s)
2. **Execute** lease: MoveTo(resource) → GatherTask → MoveTo(claim)
3. **Deposit** on arrival (auto-deposit within 100px)
4. **Request** next job
5. **Repeat** indefinitely

The system is **production-ready** (Phase 5–6). Event-driven, lease-based architecture scales to hundreds of NPCs and multiplayer.

---

## References

- **Code Files**: 
  - `scripts/npc/states/gather_state.gd` (job request)
  - `scripts/systems/resource_index.gd` (centralized resource lookup)
  - `scripts/land_claim.gd` (job generation, ResourceIndex query)
  - `scripts/npc/npc_base.gd` (auto-deposit)
  - `scripts/npc/states/wander_state.gd` (deposit movement)
- **Configuration**: `scripts/config/npc_config.gd`, `scripts/config/balance_config.gd`
- **Resources**: `scripts/gatherable_resource.gd`
- **Phase 4 definitions**: `guides/Phase4/gather4.md`
