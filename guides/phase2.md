# Stone Age Clans – Phase 2 Design Document

**Date**: January 17, 2026  
**Last Updated**: January 27, 2026  
**Status**: In Progress  
**Scope**: Reproduction, babies, Level 1 buildings, melee combat, enemy wild NPCs, NPC control/interaction systems, Task System, Resource Management, and Clan Systems.

---

## Phase 2 Status Report

### ✅ **What's Been Done**

**1. Reproduction System** ✅ **COMPLETE**
- `ReproductionComponent` - handles pregnancy, birth timers, mate detection
- `ReproductionState` - FSM state (priority 8.0)
- Women can reproduce with player/NPCs inside land claim
- Birth timer system (90s testing, variable later)
- Baby spawning at land claim center
- Baby NPCs created with `npc_type = "baby"`

**2. Baby Growth System** ✅ **COMPLETE**
- `BabyGrowthComponent` - handles baby → clansman promotion
- Babies grow to clansmen (1 min testing / 13 years normal)
- Growth timer system working
- Clansmen promotion working (verified in logs)

**3. Baby Pool Manager** ✅ **PARTIALLY COMPLETE**
- `BabyPoolManager` exists and tracks capacity per clan
- Capacity calculation: base (3) + Living Huts (5 each)
- Living Hut counting system implemented
- ⚠️ **Issue**: Baby cap is currently disabled (`can_add_baby()` always returns `true`)
- Capacity tracking works, but doesn't limit babies yet

**4. Build Menu UI** ✅ **COMPLETE**
- `BuildingInventoryUI` - integrated into land claim menu
- Opens via context menu: Right-click land claim → INFO → building inventory UI
- Building cards display (right panel)
- Land claim inventory display (center panel)
- Material cost validation
- Building selection flow (UI only - actual placement not implemented)

**5. Building Registry** ✅ **COMPLETE**
- `BuildingRegistry` - static registry of building types
- Building definitions with costs, descriptions
- Material checking/consumption helpers

**6. Melee Combat System** ✅ **COMPLETE**
- `CombatComponent` - event-driven attack logic with windup/recovery states
- `HealthComponent` - HP tracking, death handling, leader succession
- `CombatScheduler` - autoload singleton for precise event-driven timing (no per-frame polling)
- `DetectionArea` - event-driven spatial enemy detection (60x performance improvement)
- `CombatState` - FSM state (priority 12.0) for automatic combat
- Agro meter system - land claim intrusion detection (50/sec increase)
- Combat entry: `agro_meter >= 70.0` triggers combat state
- Attack arcs (90° cone validation) - positioning matters
- Stagger system - successful hits interrupt enemy windup attacks
- Weapon profiles - different timings for Axe, Pick, Unarmed
- Player combat integration - weapon requirement, responsive timings (0.1s windup, 0.3s recovery)
- Leader succession - oldest clansman becomes new leader when caveman dies
- Corpse system - dead NPCs become lootable corpses

### ⚠️ **What Needs Work**

**1. Building System** 🔶 **PARTIALLY COMPLETE**
- ✅ Building registry exists
- ✅ Build menu UI exists
- ❌ **Missing**: Actual building scenes (Living Hut, etc.)
- ❌ **Missing**: Building placement system (drag-drop or click-to-place)
- ❌ **Missing**: Building instantiation in world
- ❌ **Missing**: Building → BabyPoolManager integration (capacity updates)

**2. Baby Pool Capacity** 🔶 **PARTIALLY COMPLETE**
- ✅ Capacity calculation works
- ✅ Living Hut counting works
- ❌ **Issue**: Capacity check disabled - all babies allowed regardless of capacity
- ❌ **Missing**: Surplus baby handling (instant promotion when over capacity)
- ❌ **Missing**: Manual promotion UI (optional feature)

**3. Level 1 Buildings** ❌ **NOT STARTED**
- Farm (wheat/berries production)
- Storage Hut (extra storage)
- Armory (weapon production)
- Tailor (clothing production)
- Production component system
- Woman assignment to buildings

**4. Enemy Wild NPCs (Predators)** ❌ **NOT STARTED**
- Predator NPC type
- Hunt state
- Spawn manager
- Loot drops

**5. Flight System** ❌ **NOT STARTED**
- Flee state with hiding behavior
- Pathfinding to land claim via hiding spots
- Bravery system integration

**6. Advanced Combat Features** 🔶 **PARTIALLY COMPLETE**
- ✅ Core combat system complete (see above)
- ❌ **Missing**: Flight system (flee state with hiding)
- ❌ **Missing**: Bravery system (dynamic personality traits affecting agro)
- ❌ **Missing**: Weapon damage bonuses (Spear +5, Club +3)
- ❌ **Missing**: Armor damage reduction (Hide Armor -3)
- ❌ **Missing**: Strength-based damage calculations
- ❌ **Missing**: Wound system (temporary HP reduction)
- ❌ **Missing**: Medic Hut healing integration

### 📊 **Mechanics Status**

**Reproduction Mechanics:**
- ✅ Working: Women reproduce, babies spawn, babies grow to clansmen
- ✅ Working: Birth timers, cooldowns, mate detection
- ⚠️ Partial: Baby pool capacity exists but not enforced

**Building Mechanics:**
- ✅ Working: UI, registry, material validation
- ❌ Missing: Actual building placement and scenes
- ❌ Missing: Living Hut → capacity integration

**Baby Growth Mechanics:**
- ✅ Working: Babies grow to clansmen automatically
- ✅ Working: Growth timers, promotion system
- ✅ Working: Clansmen have full FSM (gather, herd, deposit)

**Combat Mechanics:**
- ✅ Working: Event-driven combat timing (CombatScheduler)
- ✅ Working: Spatial enemy detection (DetectionArea - 60x faster)
- ✅ Working: Agro meter system (land claim intrusion → combat)
- ✅ Working: Automatic combat entry/exit based on agro meter
- ✅ Working: Attack arcs, stagger system, weapon profiles
- ✅ Working: Player combat with weapon requirement
- ✅ Working: Death system with corpse creation and leader succession
- ✅ Working: Building attack damage (buildings can be destroyed)
- ⚠️ Partial: Flight system not implemented (flee state planned)
- ⚠️ Partial: Bravery system not implemented (planned for future)

**Task System Mechanics:**
- ✅ Working: Atomic task system (MoveTo, Gather, DropOff, PickUp, Occupy, Wait)
- ✅ Working: Job system chains tasks together
- ✅ Working: TaskRunner executes jobs on NPCs
- ✅ Working: Job generation from land claims and buildings
- ✅ Working: Task cancellation on critical states (defend, combat, following)
- ✅ Working: Resource capacity system prevents NPC flooding

**Clan & Building Mechanics:**
- ✅ Working: Clan death system (women/animals become wild)
- ✅ Working: Building health/decay system with health bars
- ✅ Working: Building attack damage and destruction
- ✅ Working: Building inventory raiding when clan dies
- ✅ Working: Herd stealing prevention (same clan check)
- ✅ Working: NPC enemy land claim avoidance

### 🎯 **What to Work on Next**

**Priority 1: AI Clan Brain System**
1. Implement dynamic defense ratio based on enemy proximity
2. Create raiding party organization system
3. Implement resource management and strategic decision-making
4. See `guides/future implementations/ai_clan_brain.md` for full plan

**Priority 2: Complete Building System**
1. Create Living Hut building scene
2. Implement building placement (click-to-place after selecting from menu)
3. Connect building placement to BabyPoolManager (capacity updates)
4. Test Living Hut → capacity increase flow

**Priority 3: Enable Baby Pool Capacity**
1. Re-enable capacity check in `BabyPoolManager.can_add_baby()`
2. Implement surplus baby handling (instant promotion when over capacity)
3. Test capacity limits with Living Huts

**Priority 4: Ratio-Based Auto-Assignment**
1. Implement auto-assignment logic using `defend_ratio` / `search_ratio`
2. Hook to idle WORKING NPCs
3. Test automatic role distribution

**Priority 5: Future Features**
- Enemy wild NPCs/predators
- Flight system
- Additional Level 1 buildings
- Advanced combat features (weapon bonuses, armor, wounds)
- Building inventory raiding UI (check `is_raidable` flag)

### 💡 **Current Status**

**Completed Systems:**
- ✅ Task System - Full implementation with job generation and execution
- ✅ Resource Capacity - Prevents NPC flooding at resources
- ✅ Clan Death System - Handles clan death, makes NPCs wild, decays buildings
- ✅ Building Health/Decay - Health bars, decay rates, attack damage
- ✅ Phase 2 Cleanup - All integration fixes and code consolidation complete

**Next Focus:**
1. **AI Clan Brain** - Dynamic defense ratios, raiding parties, resource management
2. **Building System** - Complete placement and scene creation
3. **Baby Pool Capacity** - Re-enable capacity limits

The task system, resource management, and clan systems are all working. The next major feature is the AI Clan Brain system to make NPC clans competitive with players.

**7. NPC Control & Interaction Systems** ✅ **COMPLETE**
- `DropdownMenuUI` - Mac/Windows style context menu (right-click open, hover highlight, left-click confirm)
- Context menu options: FOLLOW, DEFEND, SEARCH, WORK, INFO (all caps)
- NPC drag and drop: Drag to player (follow), drag to land claim (defend), drag outside (search)
- Ordered follow system - unbreakable follow with `follow_is_ordered` flag
- NPC role management: WORK (default), DEFEND, SEARCH, FOLLOW
- Hostile Mode - player toggle for "raid leader" mode, followers mirror `is_hostile` state
- Combat HUD - Hostile toggle and Break Follow buttons
- Land claim role pools: `assigned_defenders`, `assigned_searchers` arrays
- NPC freezing - NPCs freeze when context menu is open
- Dead NPC filtering - corpses excluded from context menu and drag interactions
- Speed adjustments: Player/Cavemen/Clansmen 320.0, Women 288.0 (agility 9.0)
- Combat improvements: Agro always decays (2/sec in combat, 5/sec out), raid path for Followers in Hostile Mode, player as combat target support
- Search state - ant-style exploration behavior (priority 5.5)
- Defend state - border patrol and engagement (priority 8.0, increased from 6.0)

**8. Task System** ✅ **COMPLETE**
- Atomic `Task` system (`MoveToTask`, `GatherTask`, `DropOffTask`, `PickUpTask`, `OccupyTask`, `WaitTask`)
- `Job` system chains tasks together (`GatherJob`, `ProductionJob`, `TransportJob`)
- `TaskRunner` component executes jobs on NPCs
- Job generation from land claims and buildings
- Task cancellation on critical states (defend, combat, following)
- Integration with FSM states (tasks pause during combat/defend/follow)
- See `guides/phase2/Task_system.md` for full documentation

**9. Resource Capacity System** ✅ **COMPLETE**
- **RULE 1**: Resources have worker capacity (`max_workers` per resource type)
  - Trees: 3 workers, Boulders: 2 workers, Berry bushes: 1 worker
- **RULE 2**: Jobs reserve resource slots (`reserve()`, `release()`)
  - Slots reserved when job created, released when job completes/cancels
- **RULE 3**: Job generator skips saturated resources (`has_capacity()` check)
  - Prevents NPC flooding at resources
- Prevents multiple NPCs from targeting same resource simultaneously

**10. Herd Stealing Prevention** ✅ **COMPLETE**
- Disabled herd stealing with members of the same clan
- Same-clan check prevents NPCs from stealing herdable NPCs from clan members
- Cross-clan stealing still allowed (competition between clans)

**11. Clan Death System** ✅ **COMPLETE**
- When last caveman dies with no babies, clan dies
- All women and animals (sheep, goats) become wild again (herdable)
- Land claim area circle disappears
- All clan buildings start decaying
- Building inventories become raidable (`is_raidable` flag)

**12. Building Health & Decay System** ✅ **COMPLETE**
- Health bar system for all buildings (visual above building)
- Health bars show green/yellow/red based on health percentage
- Decay system with different rates per building type:
  - Land claim: 0.5 health/second (slowest)
  - Living huts: 1.5 health/second
  - Ovens: 2.0 health/second
  - Other buildings: 2.0 health/second (default)
- Buildings darken visually as they decay
- Buildings drop inventory items as ground items when destroyed

**13. Building Attack Damage** ✅ **COMPLETE**
- Buildings can be damaged by player and NPC attacks
- Combat component checks for buildings and applies damage
- Health bars update on damage
- Buildings destroyed when health reaches 0

**14. NPC Enemy Land Claim Avoidance** ✅ **COMPLETE**
- NPCs avoid entering enemy land claims unless in combat/agro state
- Only intentional raiding allows entry (very dangerous otherwise)
- Prevents NPCs from accidentally wandering into enemy territory

---

## Phase 2 Overview

Phase 2 expands the core loop from Phase 1 by adding:
1. **Reproduction System** – Women can reproduce with male cavemen to create babies
2. **Baby Pool & Growth** – Babies stored in pool, grow into adults, surplus becomes clansmen
3. **Level 1 Buildings** – Functional structures (Living Hut, Farm, Storage Hut, Armory, Tailor)
4. **Melee Combat** – RimWorld-style auto-combat between NPCs
5. **Enemy Wild NPCs** – Hostile predators (wolves, etc.) that attack clans
6. **NPC Control & Interaction** – Context menu, drag-and-drop, role assignment, and Hostile Mode
7. **Task System** – Atomic task/job system for NPC work coordination
8. **Resource Management** – Capacity system prevents NPC flooding at resources
9. **Clan Systems** – Clan death, building decay, raiding mechanics
10. **Building Health** – Health bars, decay rates, attack damage for buildings

## 6. NPC Control & Interaction Systems

### Core Principles

**NPC Roles:**
- NPCs always have exactly ONE role: WORK (default), DEFEND, SEARCH, or FOLLOW
- FOLLOW is mutually exclusive with all village roles (WORK/DEFEND/SEARCH)
- WORK/DEFEND/SEARCH always break FOLLOW
- Player overrides are explicit and sticky
- Automation fills gaps, never overrides player intent

**NPC Modes:**
- **HOSTILE** - Aggressive intent for raids and hunts
- Used only with FOLLOW (Followers in Hostile Mode)
- Does not exist with WORK/SEARCH/DEFEND

### Context Menu System

**Input Model (Mac/Windows Style):**
- **Right-click** on NPC, building, or land claim → **opens** context menu at target
- **NPC freezes** when menu is open
- **Hover** over options → **highlights** option
- **Left-click** on highlighted option → **confirms** action, closes menu
- **ESC** or click outside → closes menu without action

**Menu Options:**
- **FOLLOW** - Sets NPC to unbreakable ordered follow (player as herder)
- **DEFEND** - Assigns NPC to defend a land claim (patrols border, engages intruders)
- **SEARCH** - Assigns NPC to search for resources (ant-style exploration)
- **WORK** - Clears role assignment and breaks follow (returns to default WORKING behavior)
- **INFO** - Opens character menu (for NPCs) or building inventory (for buildings/land claims)

**Context-Sensitive Options:**
- Clanswomen: Only FOLLOW and INFO (no DEFEND/SEARCH)
- Buildings/Land Claims: INFO (opens inventory/build menu)
- NPCs with assignments: WORK option appears to clear assignment

### Drag & Drop System

**Input:**
- **Left-click hold** (when context menu is **closed**) → initiates drag
- Hold threshold: 0.2 seconds before drag activates
- Visual preview shows dragged NPC

**Drop Targets:**
- **Drag NPC → Player** → Sets FOLLOW (ordered follow)
- **Drag NPC → Inside Land Claim** → Sets DEFEND (for that specific claim)
- **Drag NPC → Outside Land Claim** → Sets SEARCH (if player has ≥1 claim)

**Implementation:**
- `_resolve_npc_drop_target()` determines drop target
- `_handle_npc_drag_release()` processes drop and calls appropriate assignment function
- Drag state cleared if right-click opens context menu

### NPC Roles

#### WORKING (Default)
- Gather known resources
- Herd known animals
- Craft tools & weapons
- Idle only if nothing is possible
- Uses land claim resource intel
- Does not leave safe area

#### DEFENDING
- **Purpose:** Protect land claim
- **Behavior:** Patrols border area, engages intruders immediately, returns to patrol after combat
- **Priority:** 6.0 (FSM state)
- **Never leaves land claim**
- **Implementation:** `defend_state.gd` - patrols "guard band" around `defend_target`

#### SEARCHING
- **Purpose:** Discover resources and herds (ant-style exploration)
- **Behavior:**
  1. Pick outward direction from home claim
  2. Move to fixed search waypoint (radius × 2 from home)
  3. Scan area of perception (AOP) - avoid combat
  4. If resource/herd found: gather what can be carried, return to land claim
  5. If nothing found: repeat from step 1
  6. After 5 unsuccessful attempts: return home, transition to wander
- **Priority:** 5.5 (FSM state)
- **Implementation:** `search_state.gd` - ant-style loop with attempt counter

#### FOLLOW
- **Purpose:** Player-led actions
- **Behavior:** Stay near player, no work or village roles
- **Can become HOSTILE** when player toggles Hostile Mode
- **Ends only via:** Break Follow button or death
- **Implementation:** `follow_is_ordered` flag prevents distance-based herd breaking

### Hostile Mode

**Player Toggle:**
- Combat HUD has "Hostile" toggle button
- When enabled: `player_hostile = true`
- All ordered followers (`follow_is_ordered`) mirror `is_hostile` state

**Followers in Hostile Mode:**
- Auto-attack enemies in area of perception (AOP)
- Stay close to player (40-120px distance, 250px max break distance)
- Move 40% faster (speed_multiplier = 1.4)
- Proactively engage enemies without needing prior agro
- "Raid path" in combat state: if `is_hostile`, `herder == player`, `follow_is_ordered`, and enemies detected → enter combat

**Combat Behavior:**
- Followers in Hostile Mode attack any enemy (cavemen, clansmen) in land claims or wild
- Do not attack player or same-clan NPCs
- Stay in player's AOP (area of perception) and don't lag behind

### Land Claim Role Management

**Role Pools:**
- `assigned_defenders: Array` - Node references to NPCs defending this claim
- `assigned_searchers: Array` - Node references to NPCs searching from this claim
- Helper methods: `add_defender(npc)`, `remove_defender(npc)`, `add_searcher(npc)`, `remove_searcher(npc)`

**Ratios (Future Automation):**
- `defend_ratio: float = 0.2` (20% default)
- `search_ratio: float = 0.2` (20% default)
- Currently for display/future auto-assignment; not yet implemented

### Speed System

**Movement Speeds:**
- **Player:** 320.0 pixels/second
- **Cavemen/Clansmen:** 320.0 pixels/second (agility 10.0, multiplier 32.0)
- **Women:** 288.0 pixels/second (agility 9.0, multiplier 32.0)

**Dynamic Follow Speeds:**
- **Followers in Hostile Mode:** 1.4x multiplier (40% faster), tighter follow distances
- **Normal Followers:** 1.25x multiplier, standard follow distances

### Combat Improvements

**Agro System:**
- Agro **always decays** (no special cases)
- Decay rate: 2.0/sec in combat, 5.0/sec out of combat
- When `agro_meter < 70.0`: `combat_target` cleared, FSM re-evaluates states
- No cap at 100 - agro can exceed 100 but still decays

**Player as Combat Target:**
- Player (`CharacterBody2D`) can be assigned to `combat_target` (typed as `Node2D`)
- `_is_target_still_valid()` helper checks player vs NPC validity
- Prevents crashes from type mismatches

**Raid Path (Followers in Hostile Mode):**
- If `is_hostile`, `herder == player`, `follow_is_ordered`, and `DetectionArea` has enemies → enter combat
- Uses `get_nearest_enemy()` with fallback to `_find_nearest_enemy_legacy()`
- Detects "caveman" and "clansman" as enemies
- Skips player and same-clan NPCs

### Implementation Files

**UI Components:**
- `scripts/ui/dropdown_menu_ui.gd` - Context menu UI with hover highlight
- `scripts/main.gd` - Input handling, target resolution, role assignment

**FSM States:**
- `scripts/npc/states/defend_state.gd` - Border patrol and engagement
- `scripts/npc/states/search_state.gd` - Ant-style exploration

**NPC Extensions:**
- `scripts/npc/npc_base.gd` - Added `follow_is_ordered`, `defend_target`, `assigned_to_search`, `search_home_claim` flags
- `scripts/npc/states/herd_state.gd` - Dynamic follow parameters based on `is_hostile`
- `scripts/npc/states/combat_state.gd` - Raid path for Followers in Hostile Mode

**Land Claim:**
- `scripts/land_claim.gd` - Role pools (`assigned_defenders`, `assigned_searchers`)

### Testing

See `guides/phase2/TEST_STEP1_context_menu.md` for comprehensive test procedures covering:
- Context menu (right-click, hover, left-click confirm)
- Drag and drop (player, land claim, outside)
- Role assignments (FOLLOW, DEFEND, SEARCH, WORK)
- Hostile Mode toggle and follower behavior
- Combat HUD buttons

---

## 1. Reproduction System

### Core Mechanics

**Reproduction Requirements:**
- Woman must be in a clan (inside land claim radius)
- Woman must be assigned to a building OR idle within land claim
- Male caveman (player or NPC) must be within 200px of woman
- Birth timer only runs inside active land claim radius
- No cooldown between births (realistic fertility rates)

**Reproduction Process:**
1. Woman detects nearby male caveman (same clan) within 200px
2. If conditions met, birth timer starts (configurable: 60-120 seconds)
3. Timer counts down while woman is in land claim
4. On completion: Baby spawns at woman's location
5. Baby automatically added to baby pool
6. If baby pool at capacity: Baby becomes immediate clansman (surplus)

**Baby Pool System:**
- Maximum capacity starts at 0
- Each Living Hut adds +5 to maximum capacity
- Babies stored in pool don't age (frozen state)
- When pool reaches capacity, new babies become instant clansmen
- Player can manually "promote" babies from pool to clansmen (optional UI)

**Visual Feedback:**
- Woman shows "pregnant" visual indicator (sprite change or overlay)
- Birth timer visible in NPC debug UI
- Baby spawns with small sprite (50% scale of adult)

### Implementation Details

**New NPC States:**
- `reproduction_state.gd` – Woman actively seeking mate or gestating
- Priority: 8.0 (below herding, above gathering)

**New Components:**
- `reproduction_component.gd` – Handles birth timers, mate detection
- `baby_pool_manager.gd` – Tracks baby pool capacity and storage

**Configuration:**
```gdscript
# scripts/config/reproduction_config.gd
@export var reproduction_range: float = 200.0  # Detection range for mates
@export var birth_timer_base: float = 90.0  # Base birth timer (seconds)
@export var baby_pool_base_capacity: int = 0  # Starting capacity
@export var living_hut_capacity_bonus: int = 5  # Per Living Hut
```

## 2. Baby Pool & Growth

### Baby Pool Mechanics

**Storage:**
- Babies stored in pool are "frozen" (no aging, no movement)
- Pool displayed in Clan Menu (C key) or Stats Panel (Tab key)
- Format: "Babies: 3/10" (current/max capacity)

**Growth System:**
- Babies in pool can be manually "promoted" to clansmen
- Promoted babies spawn as adult NPCs (age 13+) at land claim
- Surplus babies (beyond capacity) automatically become clansmen
- Clansmen inherit 50/50 traits from parents (hybridization system)

**Trait Inheritance:**
- Each parent contributes 50% of traits
- Random selection: 50% chance per trait from each parent
- Max 6 traits per NPC (prevents trait bloat)
- Stat blending: Average parent base stats
- Quality tier overlay: Age-based multipliers (Flawed -20%, Legendary +60%)

### Baby Spawning

**When Baby Pool Has Space:**
- Baby spawns at woman's location
- Immediately added to pool (frozen state)
- No visual movement or aging

**When Baby Pool Full:**
- Baby spawns at woman's location
- Immediately becomes adult clansman (age 13+)
- Inherits parent traits/stats
- Enters normal FSM (wander, gather, etc.)

## 3. Task System

**Status**: ✅ **COMPLETE** - Full task/job system implemented with FSM integration.

### Task System Overview

**Architecture:**
- **Tasks**: Atomic units of work (`MoveToTask`, `GatherTask`, `DropOffTask`, `PickUpTask`, `OccupyTask`, `WaitTask`)
- **Jobs**: Sequences of tasks (`GatherJob`, `ProductionJob`, `TransportJob`)
- **TaskRunner**: NPC component that executes current job
- **Job Generation**: Land claims and buildings generate jobs for NPCs

**Key Features:**
- Tasks are interruptible (cancel on defend/combat/follow)
- Jobs chain multiple tasks together
- NPCs pull jobs from land claims/buildings
- Resource capacity system prevents NPC flooding
- Full integration with FSM states

**Implementation:**
- `scripts/ai/tasks/` - All task implementations
- `scripts/ai/jobs/` - Job classes
- `scripts/ai/task_runner.gd` - Job execution component
- `scripts/land_claim.gd` - Gather job generation
- `scripts/buildings/building_base.gd` - Production/transport job generation

**Documentation:**
- See `guides/phase2/Task_system.md` for complete task system documentation
- See `guides/phase2/phase2cleanup.md` for integration fixes and cleanup plan
- See `guides/phase2/STATE_PRIORITIES.md` for state priority hierarchy
- See `guides/phase2/STATE_BLOCKING_RULES.md` for state blocking rules
- See `guides/phase2/TASK_SYSTEM_REPORT.md` for task system audit and implementation details

### Resource Capacity System

**3 Rules to Fix NPC Flooding:**

1. **Resources have worker capacity**
   - Every gatherable resource declares `max_workers`
   - Trees: 3 workers, Boulders: 2 workers, Berry bushes: 1 worker

2. **Jobs reserve resource slots**
   - `reserve(worker)` - Reserves slot when job created
   - `release(worker)` - Releases slot when job completes/cancels
   - Prevents multiple NPCs from targeting same resource

3. **Job generator skips saturated resources**
   - `has_capacity()` - Checks if resource has available slots
   - Only resources with capacity are considered for job generation

**Implementation:**
- `scripts/gatherable_resource.gd` - Resource capacity system
- `scripts/land_claim.gd` - Job generation with capacity checks
- `scripts/ai/task_runner.gd` - Slot release on job completion/cancellation

### Herd Stealing Prevention

**Same-Clan Protection:**
- NPCs cannot steal herdable NPCs from members of the same clan
- Cross-clan stealing still allowed (competition between clans)
- Prevents internal conflict within clans

**Implementation:**
- `scripts/npc/states/herd_wildnpc_state.gd` - Same-clan check in stealing logic

### Clan Death System

**When Clan Dies:**
- Last caveman dies with no babies → clan dies
- All women and animals (sheep, goats) become wild again (herdable)
- Land claim area circle disappears
- All clan buildings start decaying
- Building inventories become raidable (`is_raidable` flag)

**Implementation:**
- `scripts/npc/components/health_component.gd` - Clan death detection and handling
- `scripts/land_claim.gd` - Circle hiding and decay start
- `scripts/buildings/building_base.gd` - Building decay system

### Building Health & Decay System

**Health Bars:**
- Visual health bars above all buildings
- Color-coded: Green (>60%), Yellow (30-60%), Red (<30%)
- Visible when building is damaged or decaying

**Decay Rates:**
- Land claim: 0.5 health/second (slowest)
- Living huts: 1.5 health/second
- Ovens: 2.0 health/second
- Other buildings: 2.0 health/second (default)

**Attack Damage:**
- Buildings can be damaged by player and NPC attacks
- Combat component checks for buildings and applies damage
- Buildings destroyed when health reaches 0
- Inventory items drop as ground items when destroyed

**Implementation:**
- `scripts/buildings/building_base.gd` - Health bar, decay, attack damage
- `scripts/land_claim.gd` - Health bar, decay, attack damage
- `scripts/npc/components/combat_component.gd` - Building damage handling

### NPC Enemy Land Claim Avoidance

**Behavior:**
- NPCs avoid entering enemy land claims unless in combat/agro state
- Only intentional raiding allows entry (very dangerous otherwise)
- Prevents NPCs from accidentally wandering into enemy territory

**Implementation:**
- `scripts/npc/npc_base.gd` - `can_enter_land_claim()` checks combat/agro state

## 3. Level 1 Buildings

### Building System Overview

**Placement:**
- Buildings placed via drag-and-drop from inventory
- Must be inside land claim radius
- Minimum 256px distance from other buildings/claims
- 128×128 pixel structures (2×2 tile footprint)

**Building Inventory:**
- All buildings have drag-and-drop inventory
- Materials placed in inventory for processing
- Outputs stack in building inventory
- Player/NPCs can take items from building inventory

**Production:**
- Buildings process materials over time (60s cycles)
- Requires assigned woman (for production buildings)
- Outputs appear in building inventory when ready

### Level 1 Building List

#### 1. Living Hut
- **Purpose**: Increases baby pool capacity
- **Materials**: 20 Wood, 10 Stone, 5 Hide
- **Craft Time**: 180s (when placed)
- **Outputs**: None
- **Special**: +5 baby pool capacity per hut
- **Woman Required**: No (0 women)

#### 2. Farm
- **Purpose**: Food production (wheat/berries)
- **Materials**: 15 Wood, 5 Stone
- **Craft Time**: 150s
- **Outputs**: 
  - Wheat: 1 per 60s
  - Berries: 1 per 120s
- **Special**: +5% Hunger regen for nearby NPCs (100px radius)
- **Woman Required**: Yes (1 woman)

#### 3. Storage Hut
- **Purpose**: Extra shared storage
- **Materials**: 25 Wood, 10 Stone
- **Craft Time**: 200s
- **Outputs**: None
- **Special**: Stores 20 stacks (shared with clan)
- **Woman Required**: No (0 women)

#### 4. Armory
- **Purpose**: Weapon crafting (spears, clubs)
- **Materials**: 20 Wood, 10 Stone
- **Craft Time**: 180s
- **Outputs**:
  - Spear: 1 per 120s (requires 2 Wood + 1 Stone)
  - Club: 1 per 90s (requires 1 Wood + 1 Stone)
- **Special**: Stores 10 stacks
- **Woman Required**: Yes (1 woman)

#### 5. Tailor
- **Purpose**: Clothing/armor crafting
- **Materials**: 20 Wood, 5 Stone, 5 Hide
- **Craft Time**: 200s
- **Outputs**:
  - Hide Armor: 1 per 180s (requires 1 Thread + 2 Hide)
  - Thread: 1 per 60s (requires 1 Wool)
- **Special**: Stores 10 stacks
- **Woman Required**: Yes (1 woman)

### Building Assignment System

**Auto-Assignment:**
- Women auto-assign to nearest unstaffed production building
- Priority: Farm > Armory > Tailor (closest first)
- Assignment range: 500px from building
- One woman per building (no stacking)

**Manual Assignment:**
- Player can drag-drop woman onto building to assign
- Drag-drop woman away from building to unassign
- Unassigned women return to idle/wander state

**Building States:**
- **Unbuilt**: Materials not yet placed
- **Building**: Materials placed, construction in progress
- **Built**: Construction complete, ready for assignment
- **Active**: Woman assigned, production running
- **Inactive**: No woman assigned, no production

### Building Implementation

**New Scripts:**
- `scripts/buildings/building_base.gd` – Base class for all buildings
- `scripts/buildings/living_hut.gd` – Living Hut implementation
- `scripts/buildings/farm.gd` – Farm implementation
- `scripts/buildings/storage_hut.gd` – Storage Hut implementation
- `scripts/buildings/armory.gd` – Armory implementation
- `scripts/buildings/tailor.gd` – Tailor implementation

**New States:**
- `assign_to_building_state.gd` – NPC state for moving to assigned building
- `work_at_building_state.gd` – NPC state for working at building

**New Components:**
- `building_inventory_component.gd` – Handles building inventory
- `production_component.gd` – Handles material processing and outputs

## 4. Melee Combat

**Status**: ✅ **CORE SYSTEM COMPLETE** - Event-driven combat with agro meter system, DetectionArea, and CombatScheduler implemented. Flight system and advanced features (weapon bonuses, armor, wounds) planned for future.

### Combat System Overview

**Style**: RimWorld / Dwarf Fortress auto-combat
- No direct unit control
- NPCs automatically engage in melee when enemies detected
- Combat happens automatically based on proximity and agro meter

**Combat Triggers:**
- ✅ **Implemented**: Land claim intrusion → `agro_meter` increases at 50.0/sec
- ✅ **Implemented**: When `agro_meter >= 70.0` → Enter combat state
- ✅ **Implemented**: Direct attack → `agro_meter` increases by 50.0, sets combat target
- ✅ **Implemented**: `DetectionArea` tracks nearby enemies (event-driven, 300px range)
- Combat state has high priority (12.0) to override other behaviors

### Combat Mechanics

**Attack Range:**
- ✅ Melee range: 100px (implemented)
- ✅ Attack cooldown: Weapon-specific (Axe: 0.45s windup, 0.8s recovery; Pick: 0.5s windup, 0.9s recovery; Unarmed: 0.4s windup, 0.7s recovery)
- ✅ Attack arcs: 90° cone validation (positioning matters)
- ✅ Stagger system: Successful hits interrupt enemy windup attacks
- 🔮 Damage calculation: Base damage + Strength stat modifier (planned)

**Damage System:**
- ✅ Base damage: 10 HP per hit (implemented)
- ✅ Event-driven timing: Uses `CombatScheduler` for precise windup → hit → recovery
- ✅ Player combat: Weapon requirement (1st hotbar slot), responsive timings (0.1s windup, 0.3s recovery)
- 🔮 Strength modifier: +1 damage per 10 Strength points (planned)
- 🔮 Weapon bonus: Spear (+5 damage), Club (+3 damage) (planned)
- 🔮 Armor reduction: Hide Armor (-3 damage per hit) (planned)

**Death System:**
- ✅ Death occurs at 0 HP (implemented)
- ✅ Corpse creation: Dead NPCs become lootable corpses (`corpsecm.png` sprite)
- ✅ Leader succession: When caveman dies, oldest clansman becomes new leader
- ✅ Inventory preservation: Corpses retain inventory for looting
- ✅ Herd release: Dead NPCs release any NPCs that were following them
- 🔮 Wound system: Temporary HP reduction (planned)
- 🔮 Medic Hut healing: Wounds heal over time at Medic Hut (planned)

**Combat States:**
- ✅ `combat_state.gd` – NPC actively fighting (implemented)
  - Priority: 12.0 (very high)
  - Uses `DetectionArea` for efficient enemy detection (throttled to 1 query/sec)
  - Positions at optimal attack range with head-on alignment
  - Respects `combat_locked` flag (prevents FSM switching during windup/recovery)
- 🔮 `flee_state.gd` – NPC running from danger (planned)
  - Priority: 11.5 (high, but below combat)
  - Will trigger when `agro_meter == 0 AND bravery == 0` (both must be exactly 0)

### Combat Implementation

**Implemented Components:**
- ✅ `combat_component.gd` – Event-driven attack logic with windup/recovery states, weapon profiles, attack arcs, stagger system
- ✅ `health_component.gd` – HP tracking, death handling, corpse creation, leader succession
- ✅ `CombatScheduler` (autoload singleton) – Event-driven timing system (no per-frame polling)
- ✅ `DetectionArea` – Event-driven spatial enemy detection (60x performance improvement)
- ✅ `combat_state.gd` – FSM state for automatic combat (priority 12.0)

**Planned Components:**
- 🔮 `weapon_component.gd` – Tracks equipped weapon, damage bonuses (weapon bonuses planned)
- 🔮 `flee_state.gd` – Fleeing from danger (flight system planned)

**Configuration:**
```gdscript
# scripts/config/combat_config.gd
@export var melee_range: float = 100.0  # Attack range
@export var attack_cooldown: float = 2.0  # Seconds between attacks
@export var base_damage: int = 10  # Base HP damage
@export var strength_damage_multiplier: float = 0.1  # +1 damage per 10 Strength
@export var spear_damage_bonus: int = 5
@export var club_damage_bonus: int = 3
@export var hide_armor_reduction: int = 3
```

## 5. Enemy Wild NPCs

### Predator System

**Enemy Types:**
- **Dire Wolf**: Fast, aggressive, moderate damage
- **Mammoth**: Slow, tanky, high damage (future)
- **Bear**: Balanced, high HP (future)

**Spawn Behavior:**
- Predators spawn in wilderness (outside land claims)
- Spawn rate: 1 per 5000px² area (configurable)
- Predators wander until they detect prey (NPCs, animals)

**Hostile Behavior:**
- Predators attack any NPC (player, clansmen, women, animals)
- Detection range: 800px (longer than normal NPCs)
- Attack range: 100px (same as melee combat)
- Predators prioritize weak targets (low HP, unarmed)

**Loot System:**
- Predators drop Hide and Bone on death
- Drop amounts: 2-4 Hide, 1-2 Bone (random)
- Loot appears as ground items (can be gathered)

### Predator Implementation

**New NPC Type:**
- `predator_npc.gd` – Extends NPCBase with hostile behavior
- `npc_type = "predator"` (distinct from "animal" and "human")

**New States:**
- `hunt_state.gd` – Predator actively hunting prey
  - Priority: 13.0 (very high)
  - Moves toward detected prey
  - Attacks when in range
- `predator_wander_state.gd` – Predator wandering (no prey detected)

**Configuration:**
```gdscript
# scripts/config/predator_config.gd
@export var predator_detection_range: float = 800.0  # Detection range
@export var predator_spawn_rate: float = 0.0002  # Per pixel² (1 per 5000px²)
@export var dire_wolf_damage: int = 15  # Base damage
@export var dire_wolf_hp: int = 50  # Base HP
@export var dire_wolf_speed_multiplier: float = 1.2  # 20% faster than normal
```

## Phase 2 Priority Sequence (FSM Updates)

Updated FSM priorities to include new Phase 2 states:

1. **Herd Catchup** (15.0) – When too far from leader (player ordered follow)
2. **Combat** (12.0) – Fighting enemies (life or death)
3. **Agro** (12.0) – Land claim defense (when intruder enters)
4. **Herd (ordered follow)** (11.0) – Following player (explicit command)
5. **Work (active job)** (10.0) – Don't interrupt active work
6. **Herd Wild NPC** (10.6) – Herding wild NPCs (Phase 1)
7. **Work (available job)** (9.0) – When job available
8. **Build** (9.5) – When has 8+ items
9. **Defend** (8.0) – Protecting territory (increased from 6.0)
10. **Reproduction** (7.5) – Seeking mate or gestating (reduced from 8.0)
11. **Occupy Building** (7.5) – Moving to building
12. **Gather (inventory full)** (5.0) – Need to deposit
13. **Search** (5.5) – Ant-style exploration for resources
14. **Gather Resources** (3.0) – Normal gathering
15. **Wander** (0.5-3.0) – Varies by context (default fallback)

**Priority Rules:**
- Combat (12.0) interrupts work (10.0) - Life over work
- Following (11.0) beats defend (8.0) - Player orders override auto-defense
- Combat (12.0) beats following (11.0) - Life over orders
- Defend (8.0) beats gather (3.0) - Defense takes priority over gathering

See `guides/phase2/STATE_PRIORITIES.md` for complete documentation.

## Integration with Phase 1

**Maintained Systems:**
- Land claims (unchanged)
- Herding system (unchanged)
- Gathering & deposit (unchanged)
- Agro/push defense (unchanged)

**New Interactions:**
- Women can reproduce while assigned to buildings
- Babies can become clansmen (surplus from pool)
- Clansmen can equip weapons/armor from Armory/Tailor
- Combat can interrupt herding/gathering
- Predators can attack herded NPCs (steal them)
- Context menu allows direct NPC control (FOLLOW, DEFEND, SEARCH, WORK)
- Drag-and-drop provides quick role assignment
- Hostile Mode enables raid-style gameplay with followers
- Defenders patrol borders and engage intruders automatically
- Searchers explore outward for resources using ant-style behavior
- Task system coordinates NPC work (gathering, production, transport)
- Resource capacity prevents NPC flooding at resources
- Clan death makes women/animals wild and buildings raidable
- Buildings decay when clan dies (different rates per building type)
- Buildings can be attacked and destroyed by players/NPCs
- NPCs avoid enemy land claims unless intentionally raiding

## Implementation Checklist

### Reproduction System
- [x] Create `reproduction_component.gd` ✅
- [x] Create `reproduction_state.gd` ✅
- [x] Create `baby_pool_manager.gd` ✅
- [x] Add birth timer logic to women ✅
- [x] Add baby spawning system ✅
- [ ] Add baby pool UI (Clan Menu / Stats Panel)
- [ ] Implement trait inheritance (50/50 hybridization)

### Baby Pool & Growth
- [x] Create baby pool storage system ✅
- [x] Implement capacity tracking (Living Hut bonuses) ✅
- [x] Add baby promotion system (pool → clansman) ✅
- [x] Create `baby_growth_component.gd` ✅
- [ ] Implement surplus baby → instant clansman (capacity check disabled)
- [x] Add baby sprite/visuals ✅

### Level 1 Buildings
- [x] Create `building_base.gd` base class ✅
- [x] Create `work_at_building_state.gd` ✅
- [x] Create `occupy_building_state.gd` ✅
- [x] Add building health/decay system ✅
- [x] Add building attack damage ✅
- [x] Add building inventory system ✅
- [x] Add production component system (ovens working) ✅
- [ ] Create `living_hut.gd` (specific building type)
- [ ] Create `farm.gd` (specific building type)
- [ ] Create `storage_hut.gd` (specific building type)
- [ ] Create `armory.gd` (specific building type)
- [ ] Create `tailor.gd` (specific building type)
- [x] Add building placement system (UI exists, needs actual placement) 🔶
- [x] Add building assignment UI (BuildMenuUI exists) ✅
- [ ] Add building sprites/visuals
- [x] Create `BuildingRegistry` ✅

### Melee Combat
- [x] Create `combat_component.gd` ✅
- [x] Create `health_component.gd` ✅
- [x] Create `CombatScheduler` (autoload singleton) ✅
- [x] Create `DetectionArea` (spatial detection) ✅
- [x] Create `combat_state.gd` ✅
- [x] Implement agro meter system ✅
- [x] Implement damage calculation ✅
- [x] Implement attack arcs (90° cone) ✅
- [x] Implement stagger system ✅
- [x] Add weapon profiles (Axe, Pick, Unarmed) ✅
- [x] Add player combat integration ✅
- [x] Implement death system with corpse creation ✅
- [x] Implement leader succession ✅
- [ ] Create `weapon_component.gd` (weapon bonuses planned)
- [ ] Create `flee_state.gd` (flight system planned)
- [ ] Implement wound system (temporary HP reduction)
- [ ] Add weapon/armor equipping (auto-equip works, manual planned)
- [ ] Add combat animations/visuals (red X hitmarker exists)

### NPC Control & Interaction Systems
- [x] Create `dropdown_menu_ui.gd` (context menu) ✅
- [x] Implement right-click → context menu open ✅
- [x] Implement hover highlight and left-click confirm ✅
- [x] Add NPC freezing when menu open ✅
- [x] Implement target resolution (`_resolve_click_target`) ✅
- [x] Add context-sensitive menu options ✅
- [x] Implement FOLLOW role assignment ✅
- [x] Implement DEFEND role assignment ✅
- [x] Implement SEARCH role assignment ✅
- [x] Implement WORK (clear role) ✅
- [x] Wire INFO option (character menu / building inventory) ✅
- [x] Create `defend_state.gd` (border patrol) ✅
- [x] Create `search_state.gd` (ant-style exploration) ✅
- [x] Implement NPC drag and drop system ✅
- [x] Add drag preview visual ✅
- [x] Implement drop target resolution ✅
- [x] Add `follow_is_ordered` flag for unbreakable follow ✅
- [x] Implement Hostile Mode toggle (HUD) ✅
- [x] Add `_update_followers_hostile()` function ✅
- [x] Implement raid path for Followers in Hostile Mode ✅
- [x] Add land claim role pools (`assigned_defenders`, `assigned_searchers`) ✅
- [x] Implement dead NPC filtering ✅
- [x] Add speed adjustments (women slower) ✅
- [x] Fix agro decay (always decays, no cap) ✅
- [x] Add player as combat target support ✅
- [x] Fix follower targeting (skip player and same-clan) ✅
- [x] Implement task system integration ✅
- [ ] Implement ratio-based auto-assignment (future)

### Task System
- [x] Create `Task` base class ✅
- [x] Create `TaskRunner` component ✅
- [x] Create `Job` system ✅
- [x] Implement `GatherJob`, `ProductionJob`, `TransportJob` ✅
- [x] Create task types: `MoveToTask`, `GatherTask`, `DropOffTask`, `PickUpTask`, `OccupyTask`, `WaitTask` ✅
- [x] Integrate with FSM states (task cancellation on critical states) ✅
- [x] Implement job generation from land claims and buildings ✅
- [x] Add resource capacity system (prevent NPC flooding) ✅
- [x] Implement task cleanup and state integration ✅

### Resource Management & Clan Systems
- [x] Implement resource capacity system (3 rules) ✅
- [x] Add herd stealing prevention (same clan check) ✅
- [x] Implement clan death system (women/animals become wild) ✅
- [x] Add building health/decay system ✅
- [x] Implement building attack damage ✅
- [x] Add NPC enemy land claim avoidance ✅
- [x] Create health bars for buildings ✅
- [x] Implement building inventory raiding system ✅

### Phase 2 Cleanup & Integration
- [x] Add helper functions to `base_state.gd` (`_is_defending()`, `_is_in_combat()`, `_is_following()`, `_cancel_tasks_if_active()`) ✅
- [x] Standardize state exit cleanup (all states cancel tasks on exit) ✅
- [x] Standardize state transition patterns (checks in both `can_enter()` and `update()`) ✅
- [x] Consolidate task cancellation logic ✅
- [x] Fix steering agent override pattern ✅
- [x] Document state priority hierarchy (`STATE_PRIORITIES.md`) ✅
- [x] Document state blocking rules (`STATE_BLOCKING_RULES.md`) ✅
- [x] Reduce excessive logging (INFO → DEBUG for clansman gather logs) ✅
- [x] Fix priority edge cases (reproduction 8.0 → 7.5) ✅

### Task System
- [x] Create `Task` base class ✅
- [x] Create `TaskRunner` component ✅
- [x] Create `Job` system ✅
- [x] Implement `GatherJob`, `ProductionJob`, `TransportJob` ✅
- [x] Create task types: `MoveToTask`, `GatherTask`, `DropOffTask`, `PickUpTask`, `OccupyTask`, `WaitTask` ✅
- [x] Integrate with FSM states (task cancellation on critical states) ✅
- [x] Implement job generation from land claims and buildings ✅
- [x] Add resource capacity system (prevent NPC flooding) ✅
- [x] Implement task cleanup and state integration ✅

### Resource Management & Clan Systems
- [x] Implement resource capacity system (3 rules) ✅
- [x] Add herd stealing prevention (same clan check) ✅
- [x] Implement clan death system (women/animals become wild) ✅
- [x] Add building health/decay system ✅
- [x] Implement building attack damage ✅
- [x] Add NPC enemy land claim avoidance ✅
- [x] Create health bars for buildings ✅
- [x] Implement building inventory raiding system ✅

### Phase 2 Cleanup & Integration
- [x] Add helper functions to `base_state.gd` (`_is_defending()`, `_is_in_combat()`, `_is_following()`, `_cancel_tasks_if_active()`) ✅
- [x] Standardize state exit cleanup (all states cancel tasks on exit) ✅
- [x] Standardize state transition patterns (checks in both `can_enter()` and `update()`) ✅
- [x] Consolidate task cancellation logic ✅
- [x] Fix steering agent override pattern ✅
- [x] Document state priority hierarchy (`STATE_PRIORITIES.md`) ✅
- [x] Document state blocking rules (`STATE_BLOCKING_RULES.md`) ✅
- [x] Reduce excessive logging (INFO → DEBUG for clansman gather logs) ✅
- [x] Fix priority edge cases (reproduction 8.0 → 7.5) ✅

### Enemy Wild NPCs
- [ ] Create `predator_npc.gd`
- [ ] Create `hunt_state.gd`
- [ ] Create `predator_wander_state.gd`
- [ ] Implement predator spawning system
- [ ] Add predator detection/attack logic
- [ ] Add predator loot drops
- [ ] Add predator sprites/visuals

## Configuration Files

**New Config Files:**
- `scripts/config/reproduction_config.gd`
- `scripts/config/combat_config.gd`
- `scripts/config/predator_config.gd`
- `scripts/config/building_config.gd`

## Testing Priorities

1. **Reproduction**: Verify women reproduce, babies spawn, pool fills
2. **Buildings**: Verify placement, assignment, production work
3. **Combat**: Verify NPCs fight, take damage, die correctly
4. **NPC Control**: Verify context menu, drag-and-drop, role assignments work (see `TEST_STEP1_context_menu.md`)
5. **Hostile Mode**: Verify followers attack enemies, stay close, move faster
6. **Predators**: Verify spawn, attack, loot drops work
7. **Integration**: Verify all systems work together without conflicts

## Known Design Questions

1. **Baby Growth**: Should babies in pool age over time, or only when promoted?
   - **Decision**: Frozen in pool, only age when promoted (simpler)

2. **Building Placement**: Can buildings be destroyed/moved?
   - **Decision**: Buildings can be destroyed (like land claims), but not moved (for Phase 2)

3. **Combat vs Herding**: What happens if predator attacks while herding?
   - **Decision**: Combat takes priority (12.0 > 10.6), herding pauses

4. **Weapon Durability**: Do weapons break?
   - **Decision**: No durability for Phase 2 (simpler)

5. **Predator Respawn**: Do predators respawn after death?
   - **Decision**: Yes, respawn in wilderness after 60 seconds

6. **NPC Role Assignment**: How do NPCs get assigned to roles?
   - **Decision**: Player explicitly assigns via context menu or drag-and-drop. Future: ratio-based auto-assignment for unassigned NPCs.

7. **Hostile Mode**: What happens when player toggles Hostile Mode?
   - **Decision**: All ordered followers (`follow_is_ordered`) mirror `is_hostile` state. Followers in Hostile Mode proactively attack enemies, stay close, move faster.

8. **Work vs Break Follow**: Should WORK clear follow?
   - **Decision**: Yes, WORK clears role assignment AND breaks follow for that specific NPC. Separate "Break Follow" button clears all followers.

9. **Resource Capacity**: How to prevent NPC flooding at resources?
   - **Decision**: Implement 3-rule system: (1) Resources have max_workers capacity, (2) Jobs reserve/release slots, (3) Job generator skips saturated resources. See `gatherable_resource.gd` for implementation.

10. **Herd Stealing**: Can NPCs steal from same clan?
   - **Decision**: No, same-clan herd stealing disabled. Cross-clan stealing still allowed for competition.

11. **Clan Death**: What happens when clan dies?
   - **Decision**: Women/animals become wild, land claim circle disappears, buildings decay and become raidable. Buildings drop inventory when destroyed.

12. **Building Decay**: How fast do buildings decay?
   - **Decision**: Different rates per building type. Land claim slowest (0.5/s), huts medium (1.5/s), ovens faster (2.0/s). Buildings can also be damaged by attacks.

13. **Enemy Land Claims**: Should NPCs enter enemy land claims?
   - **Decision**: Only if in combat/agro state (intentional raiding). Otherwise avoid entering (very dangerous).

---

## Phase 2 Cleanup & Integration Work

**Status**: ✅ **COMPLETE** - All integration fixes and code consolidation complete.

### Phase 1: Critical Integration Fixes ✅
- Added helper functions to `base_state.gd` for consistent state checks
- Fixed all states to check for defend/combat/follow correctly
- Standardized task cancellation patterns across all states
- Ensured tasks pause during critical states (defend, combat, following)

### Phase 2: Code Consolidation ✅
- Standardized state exit cleanup (all states cancel tasks on exit)
- Verified state transition patterns (checks in both `can_enter()` and `update()`)
- Consolidated task cancellation logic (all using helper functions)
- Fixed steering agent override pattern (all states cancel tasks before setting targets)

### Phase 3: Documentation & Polish ✅
- Created `STATE_PRIORITIES.md` documenting priority hierarchy
- Created `STATE_BLOCKING_RULES.md` documenting blocking rules
- Reduced excessive logging (changed INFO to DEBUG for clansman gather logs)
- Verified state validation checks (already in place)
- Fixed priority edge cases (reproduction 8.0 → 7.5, added priority comments)

**Files Modified:**
- All FSM state files (`scripts/npc/states/*.gd`)
- `scripts/ai/task_runner.gd`
- `scripts/ai/tasks/*.gd`
- `scripts/npc/states/base_state.gd` (helper functions)

See `guides/phase2/phase2cleanup.md` for complete cleanup plan and implementation details.

---

## Recent Updates (January 27, 2026)

### Task System Implementation
- Complete task/job system for NPC work coordination
- Atomic tasks (MoveTo, Gather, DropOff, PickUp, Occupy, Wait)
- Job system chains tasks together (GatherJob, ProductionJob, TransportJob)
- TaskRunner component executes jobs on NPCs
- Full integration with FSM states (tasks pause during combat/defend/follow)
- See `guides/phase2/Task_system.md` for complete documentation

### Resource Capacity System
- Implemented 3-rule system to prevent NPC flooding at resources
- Resources have worker capacity (trees: 3, boulders: 2, berries: 1)
- Jobs reserve/release slots on resources
- Job generator skips saturated resources
- Prevents multiple NPCs from targeting same resource simultaneously

### Clan Systems
- Clan death system: When last caveman dies with no babies, clan dies
- Women and animals become wild again (herdable)
- Land claim area circle disappears
- Buildings start decaying and become raidable
- Herd stealing prevention: Same-clan stealing disabled

### Building Systems
- Health bar system for all buildings (visual feedback)
- Decay system with different rates per building type
- Buildings can be damaged by player/NPC attacks
- Buildings drop inventory items when destroyed
- Health bars show green/yellow/red based on health

### NPC Behavior Improvements
- NPCs avoid entering enemy land claims unless intentionally raiding
- Only enter if in combat/agro state (very dangerous otherwise)
- Prevents accidental wandering into enemy territory

### Phase 2 Cleanup
- Added helper functions to `base_state.gd` for consistent state checks
- Standardized state exit cleanup (all states cancel tasks on exit)
- Standardized state transition patterns
- Consolidated task cancellation logic
- Fixed steering agent override pattern
- Created documentation: `STATE_PRIORITIES.md`, `STATE_BLOCKING_RULES.md`
- Reduced excessive logging
- Fixed priority edge cases

---

## Questions & Clarifications Needed

**Last Updated:** January 27, 2026

This section lists questions, optimization opportunities, and areas needing clarification for Phase 2 systems.

**Terminology Note:**
- **BuildingBase**: Base class for buildings like Ovens and Living Huts (defined in `scripts/buildings/building_base.gd`). Buildings like `Oven` extend this class.
- **LandClaim**: A separate building class (doesn't extend BuildingBase) - it's the land claim building that defines clan territory.

### Building Inventory Raiding

**Question 1:** The `is_raidable` flag is set when clans die, but it's not checked when accessing building inventories. Should we:
- **Option A:** Allow anyone to access raidable building inventories (current behavior) ✅ **SELECTED**

**Decision:** Keep current behavior - anyone can access raidable building inventories. The `is_raidable` flag is informational (can be used for visual indicators later) but doesn't restrict access.

**Current State:** `is_raidable` is set but not used in `_on_land_claim_clicked()` or building inventory access.

**Files:** `scripts/main.gd` (line 3336), `scripts/buildings/building_base.gd` (line 33), `scripts/land_claim.gd` (line 22)

---

### Babies on Clan Death

**Question 2:** When a clan dies, `_make_clan_members_wild()` only makes women, sheep, and goats wild. What should happen to babies?
a clan dies when there are no more babies, or when the landclaim building is destroyed.

**Current State:** Babies are not handled in `_make_clan_members_wild()` - they remain in the dead clan.

**Files:** `scripts/npc/components/health_component.gd` (line 375)

---

### Resource Capacity Configuration

**Question 3:** Resource capacity (`max_workers`) is hardcoded in `_ready()` based on resource type. Should these be:

- **Option B:** Make configurable via `NPCConfig` or resource config


**Current Values:**
- Trees: 3 workers
- Boulders: 4 workers
- Berry bushes: 2 worker
- Wheat: 1 worker
- Fiber plants: 1 worker

**Files:** `scripts/gatherable_resource.gd` (line 33-48)

---

### Building Decay Rate Balance

**Question 4:** Are the current decay rates balanced? Should they be:
-Keep current rates (land claim: 0.5/s, huts: 1.5/s, ovens: 2.0/s)
-Adjust rates based on playtesting feedback


**Current Rates:**
- Land claim: 0.5 health/second (200 seconds to destroy)
- Living huts: 1.5 health/second (~67 seconds to destroy)
- Ovens: 2.0 health/second (50 seconds to destroy)
- Other buildings: 2.0 health/second (default)

**Files:** `scripts/buildings/building_base.gd` (line 116), `scripts/land_claim.gd` (line 20)

---

### Building Attack Damage

**Question 5:** Currently all attacks do `base_damage` (10) to buildings. Should:
Different weapons do different damage (axe > pick > unarmed)
Buildings have different max health (land claim: 200, ovens: 100, etc.)


**Current State:** All buildings have 100 max health, all attacks do 5 damage.

**Files:** `scripts/npc/components/combat_component.gd` (line 288), `scripts/buildings/building_base.gd` (line 28)

---

### Health Bar Visibility

**Question 6:** Health bars are hidden until building is damaged or decaying. Should:
view health with info screen on dropdown menu

**Current State:** Health bars visible when `current_health < max_health` OR `is_decaying`.

**Files:** `scripts/buildings/building_base.gd` (line 138), `scripts/land_claim.gd` (line 288)

---

### Land Claim Health System Unification

**Question 7:** Land claim uses `decay_health` while BuildingBase uses `current_health`. Should:
- **Option A:** Keep separate (land claim is special case)

**Note:** `BuildingBase` is the base class for buildings like Ovens and Living Huts (defined in `scripts/buildings/building_base.gd`). `LandClaim` is a separate class that doesn't extend BuildingBase - it's its own building type.

**Current State:** Two separate health systems with similar functionality:
- `LandClaim`: Uses `decay_health` (legacy variable name)
- `BuildingBase` (Oven, LivingHut, etc.): Uses `current_health` (newer system)

**Files:** `scripts/land_claim.gd` (line 19), `scripts/buildings/building_base.gd` (line 29)

---

### Resource Lock vs Capacity System

**Question 8:** Resources have both `locked_by` (old lock system) and `reserved_workers` (new capacity system). Should:
Option C — migrate the old lock system to the capacity/reservation system (and then delete the old lock logic).

**Current State:** Both systems exist. Lock system used in `GatherTask`, capacity system used in job generation.

**Files:** `scripts/gatherable_resource.gd` (line 29, 34, 448)

---

### Task Cancellation Performance

**Question 9:** Some states cancel tasks every frame (defend, combat, occupy, work). Is this performant with many NPCs?
Option B — cancel tasks only on state change, not every frame.
Back it up with a cheap guard so accidental double-cancels are impossible.

This is the correct, scalable fix for 50+ NPCs.

**Current State:** States like `defend_state`, `combat_state`, `occupy_building_state`, `work_at_building_state` cancel tasks every frame.

**Files:** Various state files in `scripts/npc/states/`

---

### Building Placement Implementation

**Question 10:** Building placement UI exists but actual placement is not implemented. When should this be completed?
- **Option A:** Next priority (needed for baby pool capacity)


**Current State:** UI exists, registry exists, but no actual building scenes or placement logic.

**Files:** `scripts/buildings/building_base.gd` (exists), `scripts/main.gd` (placement logic missing)

---

### Resource Capacity Edge Cases

**Question 11:** What happens if:
- NPC dies while reserving a resource slot?
- Resource is destroyed while NPCs have reserved slots?
- NPC is reassigned (defend/follow) while gathering?
Great question — this is exactly the set of edge cases that separates a *working* task system from a **robust, scalable one**.

Short answer first, then the clean ruleset.

---

## Short Answer (Decisions)

**Recommended approach:**

* ✅ **Centralize cleanup at Job / TaskRunner boundaries**
* ✅ **Resources own reservation cleanup**
* ✅ **State transitions are hard interrupts**
* ❌ **Never rely on periodic global pruning alone**

Your `_prune_reserved_workers()` is **necessary but not sufficient**. It should be a *safety net*, not the primary mechanism.

---

## Canonical Rules (Think “ants + contracts”)

### Core Rule

> **Whoever *breaks* the contract is responsible for cleanup.**

That means:

* Death cleans up everything
* Reassignment cancels job → job releases reservations
* Resource destruction releases all reservations immediately

---

## Case-by-Case Answers

---

## 1️⃣ NPC dies while reserving a resource slot

### What SHOULD happen

* All reservations held by that NPC are released immediately
* Any job tied to that NPC is cancelled
* Any building occupation is cleared

### Correct Flow

```text
NPC dies
 ↓
TaskRunner.cancel_current_job("death")
 ↓
Job.cancel()
 ↓
Job releases all reservations
 ↓
Resource slots freed
```

### Required Implementation

#### NPC death handler

```gdscript
func die():
    task_runner.cancel_current_job("death")
    emit_signal("npc_died", self)
```

#### Job owns reservation release

```gdscript
func cancel(reason := ""):
    for reservation in reservations:
        reservation.resource.release(reservation.worker)
    reservations.clear()
```

### Why this works

* No dangling reservations
* No polling required
* Deterministic cleanup

✔ `_prune_reserved_workers()` becomes backup only

---

## 2️⃣ Resource is destroyed while NPCs have reserved slots

### What SHOULD happen

* Resource immediately invalidates all reservations
* Affected jobs are cancelled
* NPCs re-evaluate state next tick

### Correct Ownership

> **Resources own reservations → resources clean them**

### Correct Flow

```text
Resource destroyed
 ↓
Resource.on_destroyed()
 ↓
Release all reservations
 ↓
Notify workers
 ↓
Workers cancel jobs
```

### Required Implementation

#### Resource side

```gdscript
func destroy():
    for worker in reserved_workers:
        if is_instance_valid(worker):
            worker.task_runner.cancel_current_job("resource_destroyed")
    reserved_workers.clear()
    queue_free()
```

### Optional: reservation token pattern (cleaner)

```gdscript
class Reservation:
    var resource
    var worker
    var valid := true
```

Invalidate tokens on destroy.

---

## 3️⃣ NPC reassigned (defend / follow) while gathering

### This is the MOST important one

### What SHOULD happen

* Gathering job is immediately cancelled
* All reservations released
* NPC switches FSM state cleanly
* No partial hauling, no “finish first”

### Correct Flow

```text
Player / AI reassigns NPC
 ↓
ModeController.set_mode()
 ↓
TaskRunner.cancel_current_job("mode_switch")
 ↓
Reservations released
 ↓
FSM enters defend / follow
```

### Explicit Design Rule

> **Mode changes are hard interrupts, always.**

No exceptions.

### Why

* Predictable player control
* Prevents “NPC ignores me” bugs
* Matches your ant-like behavior model

---

## Why `_prune_reserved_workers()` Still Matters

Your pruning function is still GOOD — just not primary.

### What it should handle

* Crashes
* Script reloads
* Save/load mismatches
* Rare desyncs

### What it should NOT handle

* Normal gameplay transitions
* Death
* Reassignment
* Resource destruction

Think of it as **garbage collection**, not logic.

---

## Final Recommended Architecture (Locked)

### Reservation Lifecycle

| Event              | Who cleans up               |
| ------------------ | --------------------------- |
| Job cancelled      | Job                         |
| NPC dies           | TaskRunner → Job            |
| Resource destroyed | Resource                    |
| Mode/state change  | ModeController              |
| Edge-case desync   | `_prune_reserved_workers()` |

---

## One Golden Rule (Again)

> **If cleanup relies on “eventually”, it will break.**

Your system is already 90% correct — this just formalizes ownership and makes it bulletproof.

---

## Optional Next Steps (Highly Recommended)

If you want to future-proof further, I can help you add:

* 🔹 **Reservation tokens** (strongest pattern)
* 🔹 **Debug overlay** showing live reservations
* 🔹 **Assertion checks** (`assert(reserved_workers.size() <= capacity)`)
* 🔹 **Job reason enum** (`CANCEL_DEATH`, `CANCEL_MODE`, etc.)

If you want one of these next, tell me which.

**Current State:** `_prune_reserved_workers()` cleans up invalid workers, but edge cases may not be fully handled.

**Files:** `scripts/gatherable_resource.gd` (line 476)

---

### Building Decay Start Timing

**Question 12:** Should building decay start:
- **Option A:** Immediately when clan dies (current)


**Current State:** Decay starts immediately when `start_decay()` is called (when clan dies).

**Files:** `scripts/buildings/building_base.gd` (line 155), `scripts/land_claim.gd` (line 211)

---

### NPC Enemy Land Claim Exceptions

**Question 13:** Should NPCs be able to enter enemy land claims if:
Only in combat/agro (current)
Also when following player in hostile mode


**Current State:** Only enter if in combat or agro state.

**Files:** `scripts/npc/npc_base.gd` (line 971)

---

### Herd Stealing Cooldown

**Question 14:** Should there be a cooldown or restrictions on herd stealing?
- **Option A:** No cooldown (current - immediate competition)


**Current State:** No cooldown, but must be within 100px to attempt steal.

**Files:** `scripts/npc/states/herd_wildnpc_state.gd` (line 836)

---

### Building Health Bar Positioning

**Question 15:** Health bars are positioned at `Vector2(-40, -60)` above buildings. Should:
put health bar in the building inventory screen when the player clicks info on the drop down menu 

**Current State:** Fixed position above building.

**Files:** `scripts/buildings/building_base.gd` (line 108), `scripts/land_claim.gd` (line 255)

---

### Optimization Opportunities

**Potential Optimizations:**

1. **Resource Capacity Lookup:** Currently iterates all resources to find available ones. Could use spatial partitioning for large maps.

2. **Task Cancellation:** States cancel tasks every frame. Could optimize to only cancel when state changes.

3. **Health Bar Updates:** Health bars update every frame during decay. Could throttle to every N frames.

4. **Clan Death Check:** Currently checks all NPCs when caveman dies. Could cache clan members for faster lookup.

5. **Building Decay Processing:** All decaying buildings process every frame. Could batch updates or use timers.

---

### Design Decisions Needed

**Decisions to Make:**

1. **Building Inventory Access:** Should raidable buildings be accessible to anyone, or require same-clan/raidable check?
Raidable to anyone
2. **Baby Handling on Clan Death:** What happens to babies when clan dies?
clan dies when there are no more babies IF the landclaim building is destroyed before then babies will disappear.
3. **Resource Capacity Values:** Are current values (3/2/1) balanced, or should they be adjusted?
for now i think they are
4. **Building Decay Timing:** Should decay start immediately or after delay?
begin immidiatly after landclaim circle goes away
5. **Health System Unification:** Should land claim use same health system as BuildingBase?
landclaim building will have landclaim building health bar. i dont know what you mean by BuildingBase?
---

This document defines the complete Phase 2 implementation scope.  
All systems build on Phase 1 foundations while adding new gameplay depth.
