# NPC Task & Job System Implementation Guide
deposit range is 50px 
## Overview

This guide outlines the plan for implementing a scalable **Task/Job System** for NPCs that will streamline gathering, herding, building work, and resource logistics. The system is designed to replace hardcoded state logic with reusable, composable tasks that can be shared across all NPC types (women, sheep, goats, etc.).

---

## Current System Analysis

### What We Have Now

**State-Based FSM System:**
- NPCs use a Finite State Machine with states like `gather_state`, `herd_state`, `work_at_building_state`
- Each state contains its own logic for finding targets, moving, and executing actions
- States have priorities and can transition between each other
- NPCs have inventories (10 slots currently, but notes suggest 1 slot of 5 for women)

**Current Limitations:**
- Logic is duplicated across states (movement, inventory checks, etc.)
- Hard to add new work types without creating new states
- Building-specific logic is scattered
- Resource transfer between land claims and buildings is not automated
- No unified task framework for different NPC types

**What Works Well:**
- FSM provides good state management
- NPCs can already gather, herd, and occupy buildings
- Inventory system exists and works
- Movement system (steering_agent) is solid

---

## Proposed Task/Job System

### Core Philosophy

> **"Treat work as a sequence of reusable TASKS, not building-specific scripts."**

**Key Principles:**
1. **Tasks are atomic** - Each task does ONE thing (WalkTo, PickUp, DropOff, Occupy, Wait)
2. **Jobs are sequences** - A job is just an ordered list of tasks
3. **Buildings generate jobs** - Buildings don't control NPCs, they answer "what job should be done here?"
4. **Women execute tasks** - NPCs don't care WHY they're doing tasks, just execute them one-by-one
5. **Same framework for all** - Women, sheep, goats all use the same task system, just different job generators

---

## System Architecture

### 1. Task Base Class

```gdscript
# scripts/tasks/task_base.gd
extends RefCounted
class_name Task

enum TaskStatus {
    PENDING,    # Not started
    RUNNING,    # Currently executing
    SUCCESS,    # Completed successfully
    FAILED,     # Failed and cannot continue
    CANCELLED   # Cancelled (can be retried)
}

var woman: Node = null  # The NPC executing this task
var status: TaskStatus = TaskStatus.PENDING

func start() -> void:
    """Called when task begins execution"""
    status = TaskStatus.RUNNING

func tick(delta: float) -> TaskStatus:
    """Called every frame while task is running"""
    return status

func cancel() -> void:
    """Called when task is cancelled (building destroyed, enemy attack, etc.)"""
    status = TaskStatus.CANCELLED

func can_execute() -> bool:
    """Check if task can be executed (prerequisites met)"""
    return true
```

### 2. Concrete Task Types

**Movement Tasks:**
- `WalkToTask(target: Node2D)` - Move NPC to a target location/building
- `FollowTask(target: Node2D, distance: float)` - Follow a target at a distance

**Inventory Tasks:**
- `PickUpTask(source: Node, item_type: ResourceType, amount: int)` - Take items from source inventory
- `DropOffTask(destination: Node, item_type: ResourceType, amount: int)` - Put items into destination inventory
- `TransferTask(source: Node, dest: Node, item_type: ResourceType, amount: int)` - Move items between inventories

**Building Tasks:**
- `OccupyTask(building: Node)` - Enter and occupy a building
- `WorkAtTask(building: Node, duration: float)` - Work at building for a duration
- `WaitTask(duration: float)` - Wait for a period of time

**Resource Tasks:**
- `GatherTask(resource: Node2D)` - Gather from a resource node
- `HarvestTask(resource: Node2D)` - Harvest a resource (similar to gather but different context)

### 3. Job System

```gdscript
# scripts/tasks/job.gd
extends RefCounted
class_name Job

var tasks: Array[Task] = []
var current_task_index: int = 0
var woman: Node = null
var building: Node = null  # Building that generated this job
var is_claimed: bool = false  # Has a woman claimed this job?

func add_task(task: Task) -> void:
    task.woman = woman
    tasks.append(task)

func get_current_task() -> Task:
    if current_task_index < tasks.size():
        return tasks[current_task_index]
    return null

func advance() -> bool:
    """Move to next task, return true if more tasks remain"""
    current_task_index += 1
    return current_task_index < tasks.size()

func is_complete() -> bool:
    return current_task_index >= tasks.size()
```

### 4. Job Generator (Building Interface)

```gdscript
# Buildings implement this interface
func generate_job(woman: Node) -> Job:
    """Return a job for this woman, or null if no work available"""
    return null

func accepts_woman(woman: Node) -> bool:
    """Check if this building accepts this woman"""
    return false
```

**Example: Oven Job Generator**

```gdscript
# In BuildingBase or Oven-specific script
func generate_job(woman: Node) -> Job:
    if not has_work_available():
        return null
    
    var job := Job.new()
    job.woman = woman
    job.building = self
    
    # Get land claim for this clan
    var land_claim := _find_land_claim()
    if not land_claim:
        return null
    
    # Bake Bread Job:
    # 1. Walk to land claim
    job.add_task(WalkToTask.new(land_claim))
    # 2. Pick up wood (5)
    job.add_task(PickUpTask.new(land_claim, ResourceType.WOOD, 5))
    # 3. Walk to oven
    job.add_task(WalkToTask.new(self))
    # 4. Drop off wood
    job.add_task(DropOffTask.new(self, ResourceType.WOOD, 5))
    # 5. Walk back to land claim
    job.add_task(WalkToTask.new(land_claim))
    # 6. Pick up grain (5)
    job.add_task(PickUpTask.new(land_claim, ResourceType.GRAIN, 5))
    # 7. Walk to oven
    job.add_task(WalkToTask.new(self))
    # 8. Drop off grain
    job.add_task(DropOffTask.new(self, ResourceType.GRAIN, 5))
    # 9. Occupy oven
    job.add_task(OccupyTask.new(self))
    # 10. Wait until production complete
    job.add_task(WaitTask.new(production_duration))
    # 11. Pick up bread
    job.add_task(PickUpTask.new(self, ResourceType.BREAD, 5))
    # 12. Walk to land claim
    job.add_task(WalkToTask.new(land_claim))
    # 13. Drop off bread
    job.add_task(DropOffTask.new(land_claim, ResourceType.BREAD, 5))
    
    return job
```

### 5. Task Runner (NPC Component)

```gdscript
# scripts/npc/components/task_runner.gd
extends Node
class_name TaskRunner

var current_job: Job = null
var current_task: Task = null
var npc: Node = null

func _ready():
    npc = get_parent()

func _process(delta: float):
    if not current_job:
        return
    
    if not current_task:
        current_task = current_job.get_current_task()
        if current_task:
            current_task.start()
        else:
            # Job complete
            current_job = null
            return
    
    # Execute current task
    var status = current_task.tick(delta)
    
    if status == Task.TaskStatus.SUCCESS:
        # Task complete, move to next
        current_task = null
        if not current_job.advance():
            # Job complete
            current_job = null
    elif status == Task.TaskStatus.FAILED:
        # Task failed, cancel job
        current_task.cancel()
        current_job = null
        current_task = null

func assign_job(job: Job) -> bool:
    """Assign a job to this NPC"""
    if current_job:
        return false  # Already has a job
    current_job = job
    job.woman = npc
    return true

func cancel_current_job():
    """Cancel current job (enemy attack, building destroyed, etc.)"""
    if current_task:
        current_task.cancel()
    current_job = null
    current_task = null
```

---

## Implementation Plan

### Phase 1: Core Task System (Foundation)

**Step 1.1: Create Task Base Classes**
- [ ] Create `scripts/tasks/task_base.gd` with Task base class
- [ ] Create `scripts/tasks/job.gd` with Job class
- [ ] Create `scripts/tasks/task_runner.gd` component

**Step 1.2: Implement Basic Movement Tasks**
- [ ] `WalkToTask` - Move to target position/building
- [ ] `FollowTask` - Follow a target (for herding)

**Step 1.3: Implement Inventory Tasks**
- [ ] `PickUpTask` - Take items from source
- [ ] `DropOffTask` - Put items into destination
- [ ] `TransferTask` - Move items between inventories

**Step 1.4: Test Basic Task Execution**
- [ ] Create test job: WalkTo → PickUp → WalkTo → DropOff
- [ ] Verify NPC executes tasks in order
- [ ] Test task cancellation

### Phase 2: Building Integration

**Step 2.1: Add Job Generator Interface to Buildings**
- [ ] Add `generate_job()` method to `BuildingBase`
- [ ] Add `accepts_woman()` method to `BuildingBase`
- [ ] Create job manager/coordinator system

**Step 2.2: Implement Oven Job Generator**
- [ ] Create `BakeBreadJob` generator in Oven
- [ ] Test full bread baking workflow
- [ ] Verify resource transfer from land claim to oven

**Step 2.3: Job Claiming System**
- [ ] Prevent multiple women from taking same job
- [ ] Job queue/priority system
- [ ] Job expiration (if woman takes too long)

### Phase 3: Migrate Existing States

**Step 3.1: Convert Gather State to Task**
- [ ] Create `GatherTask` that handles resource gathering
- [ ] Replace `gather_state` logic with task execution
- [ ] Maintain compatibility with FSM during transition

**Step 3.2: Convert Herd State to Task**
- [ ] Create `FollowTask` for herding behavior
- [ ] Integrate with existing herd state or replace it
- [ ] Test herding still works correctly

**Step 3.3: Convert Work State to Task**
- [ ] Create `OccupyTask` and `WorkAtTask`
- [ ] Replace `work_at_building_state` with task execution
- [ ] Test building occupation and production

### Phase 4: Woman Inventory System

**Step 4.1: Implement Woman Inventory (1 slot, 5 items)**
- [ ] Create woman-specific inventory configuration
- [ ] Limit women to 1 stack of 5 items
- [ ] Update task system to respect inventory limits

**Step 4.2: Resource Transfer Tasks**
- [ ] Enhance `TransferTask` to handle land claim → building transfers
- [ ] Create automated resource movement jobs
- [ ] Test multiple women moving resources simultaneously

### Phase 5: Advanced Features

**Step 5.1: Job Priority System**
- [ ] Implement job priorities (urgent, normal, low)
- [ ] Women prefer higher priority jobs
- [ ] Dynamic priority adjustment (e.g., oven needs fuel = higher priority)

**Step 5.2: Job Failure Handling**
- [ ] Task cancellation on building destruction
- [ ] Task cancellation on enemy attack
- [ ] Resource return on job failure
- [ ] Job retry logic

**Step 5.3: Multi-Woman Coordination**
- [ ] Multiple women can work on same building (different jobs)
- [ ] Job distribution across available women
- [ ] Woman specialization (some prefer certain jobs)

---

## Integration with Existing Systems

### FSM Integration Strategy

**Option A: Hybrid Approach (Recommended for Phase 1-3)**
- Keep FSM for high-level state management (idle, combat, etc.)
- Use TaskRunner for work-related activities
- FSM states can assign jobs to TaskRunner
- Example: `work_state` enters → assigns job to TaskRunner → TaskRunner executes → job complete → exit state

**Option B: Full Replacement (Future)**
- Replace FSM entirely with task-based system
- All NPC behavior becomes tasks/jobs
- More flexible but requires complete rewrite

**Recommended: Start with Option A, migrate to Option B gradually**

### Inventory System Integration

**Current:** NPCs have 10-slot inventories
**Proposed:** Women have 1-slot inventory (5 items max)
women inventories would be different, they would have just 1 slot in their inventory that can hold a stack of 5 of the same item.

**Migration:**
- Keep existing inventory system
- Add woman inventory configuration
- Women use limited inventory, other NPCs keep full inventory
- Tasks check inventory capacity before executing

### Building System Integration

**Current:** Buildings have `occupy_building_state` and `work_at_building_state`
**Proposed:** Buildings generate jobs, women execute them

**Changes Needed:**
- Add `generate_job()` to `BuildingBase`
- Buildings track available jobs
- Women query buildings for available jobs
- Job claiming prevents conflicts

---

## Example: Complete Bake Bread Job Flow

```
1. Oven checks: "Do I need resources?" → Yes, need wood + grain
2. Oven generates BakeBreadJob
3. Woman NPC queries nearby buildings for jobs
4. Woman claims BakeBreadJob
5. Woman executes tasks:
   a. WalkTo(land_claim) → SUCCESS
   b. PickUp(wood, 5) → SUCCESS (inventory: 5 wood)
   c. WalkTo(oven) → SUCCESS
   d. DropOff(wood, 5) → SUCCESS (inventory: empty)
   e. WalkTo(land_claim) → SUCCESS
   f. PickUp(grain, 5) → SUCCESS (inventory: 5 grain)
   g. WalkTo(oven) → SUCCESS
   h. DropOff(grain, 5) → SUCCESS (inventory: empty)
   i. Occupy(oven) → SUCCESS (woman enters oven, sprite hidden)
   j. Wait(production_time) → SUCCESS (oven produces bread)
   k. PickUp(bread, 5) → SUCCESS (inventory: 5 bread)
   l. WalkTo(land_claim) → SUCCESS
   m. DropOff(bread, 5) → SUCCESS (inventory: empty)
6. Job complete → Woman looks for next job
```

**Visual Result:**
- Player sees woman walking between land claim and oven
- Woman carries visible resources (wood, grain, bread)
- Woman enters oven (sprite hidden) during production
- Woman exits oven and returns bread to land claim
- Multiple women can work simultaneously (different jobs or same job queued)

---

## Benefits of This System

### Scalability
- Add new work types by creating new job generators
- No need to modify NPC code for new buildings
- Tasks are reusable across different job types

### Maintainability
- Single source of truth for task logic
- Easy to debug (each task is isolated)
- Clear separation of concerns (buildings generate, women execute)

### Visual Richness
- NPCs visibly carry resources (1 stack of 5)
- Multiple women create "living village" feel
- Logistics are visible and understandable

### Flexibility
- Same system works for women, sheep, goats
- Easy to add woman specializations
- Job priorities allow dynamic work allocation

---

## Migration Path

### Week 1: Foundation
- Implement Task base class and Job system
- Create basic tasks (WalkTo, PickUp, DropOff)
- Test with simple job (walk to point, pick up item)

### Week 2: Building Integration
- Add job generator to buildings
- Implement Oven job generator
- Test full bread baking workflow

### Week 3: State Migration
- Convert gather state to use tasks
- Convert work state to use tasks
- Maintain FSM compatibility

### Week 4: Polish & Testing
- Woman inventory system (1 slot, 5 items)
- Job claiming and priority system
- Failure handling and edge cases
- Performance optimization

---

## Key Design Decisions

### 1. Task vs State
**Decision:** Tasks are for work, States are for behavior (combat, idle, etc.)
**Rationale:** Keeps system flexible while maintaining existing FSM benefits

### 2. Woman Inventory Size
**Decision:** 1 slot, 5 items max
**Rationale:** Creates visible logistics, prevents resource teleportation, encourages multiple women

### 3. Job Generation Location
**Decision:** Buildings generate jobs, not a central job manager
**Rationale:** Keeps buildings self-contained, easier to add new building types

### 4. Task Cancellation
**Decision:** All tasks must be cancellable
**Rationale:** Prevents stuck NPCs when buildings destroyed or enemies attack

### 5. Job Claiming
**Decision:** Jobs are claimed by women, not assigned
**Rationale:** Allows woman autonomy, easier to add woman preferences later

---

## Future Enhancements

### Woman Specialization
- Some women prefer certain job types
- Women can learn/improve at specific tasks
- Woman efficiency affects job completion time

### Job Chains
- Jobs can depend on other jobs completing first
- Example: "Wait for wood delivery" job
- Complex production chains (wood → planks → furniture)

### Dynamic Job Priorities
- Jobs adjust priority based on urgency
- Example: Oven running out of fuel = higher priority
- Resource scarcity affects job availability

### Multi-Step Production
- Jobs can span multiple buildings
- Example: Gather wheat → mill to flour → oven to bread
- Women automatically chain jobs together

---

## Testing Checklist

### Basic Functionality
- [ ] NPC can execute a simple job (WalkTo → PickUp → DropOff)
- [ ] Tasks execute in correct order
- [ ] Job completes successfully
- [ ] Task cancellation works (building destroyed mid-job)

### Building Integration
- [ ] Oven generates bread baking job
- [ ] Woman claims and executes job
- [ ] Resources transfer correctly (land claim → oven → land claim)
- [ ] Multiple women can work at same oven (different jobs)

### Edge Cases
- [ ] Woman dies mid-job (job cancelled, resources returned)
- [ ] Building destroyed mid-job (job cancelled, woman freed)
- [ ] No resources available (job not generated)
- [ ] Woman inventory full (task waits or fails gracefully)
- [ ] Multiple women compete for same job (only one claims it)

### Performance
- [ ] 10+ women executing jobs simultaneously
- [ ] Job generation doesn't cause lag
- [ ] Task updates are efficient

---

---

## Potential Conflicts & Solutions
- NPCs use `gather_state` with FSM priority system
- Auto-deposit happens when NPCs are near land claim (within 50px)
- NPCs gather until inventory is 80% full (4/5 slots), then deposit
- Gathering has priority 3.0, below herding (11.0) and deposit (11.0)

**Options:**
- **Option A:** Keep gathering as FSM state, use tasks only for building work
  - Pros: Minimal disruption, gathering already works well
  - Cons: Inconsistent system (some work uses tasks, some uses states)
  
- **Option B:** Convert gathering to tasks (`GatherTask` + `DepositTask`)
  - Pros: Unified system, easier to add gathering variations
  - Cons: Need to handle auto-deposit logic, may lose current efficiency
  
- **Option C:** Hybrid - Gathering stays as state, but uses tasks for deposit
  - Pros: Best of both worlds
  - Cons: More complex integration

**Recommendation:** Start with Option A, migrate to Option B after building work is proven.

**Conflict:** Auto-deposit currently happens automatically when near land claim. With tasks, we'd need explicit `DepositTask`. Should we:
- Keep auto-deposit for gatherers (simpler)?
- Require explicit deposit tasks (more control)?
- Hybrid: Auto-deposit for gatherers, explicit tasks for women?

---

#### 2. **Herding System Integration**

**Question:** Should herding use the task system?

**Current System:**
- `herd_state` handles following behavior with complex distance logic
- Herding has very high priority (11.0)
- Herding can be interrupted by combat, clan joining, etc.

**Options:**
- **Option A:** Keep herding as FSM state (recommended)
  - Pros: Herding is behavior, not work. FSM handles interruptions well
  - Cons: Inconsistent with task system
  
- **Option B:** Convert to `FollowTask`
  - Pros: Unified system
  - Cons: Herding needs complex logic (distance bands, catch-up, etc.) that doesn't fit task model well

**Recommendation:** Keep herding as FSM state. Herding is behavioral (following), not work (production). Tasks are for work, FSM is for behavior.

**Conflict:** None - herding and tasks can coexist.

---

#### 3. **Deposit System - Auto vs Explicit**

**Question:** How should deposits work with 50+ NPCs?

**Current System:**
- Auto-deposit when NPC is within 50px of land claim (reduced from 200px for realism)
- NPCs must physically approach the building/land claim to deposit
- Cooldown of 1 second between deposits
- Check interval of 0.5 seconds
- NPCs deposit all items at once

**Rationale for 50px Range:**
- Forces NPCs to get very close to buildings/land claims, making deposit behavior clearly visible
- Simulates NPCs physically putting materials away rather than teleporting items
- Creates more realistic village activity as NPCs cluster near storage areas
- Tight range ensures NPCs must approach the building itself, not just be anywhere in the claim

**Concerns at Scale (50+ NPCs):**
- **Performance:** 50 NPCs checking every 0.5s = 100 checks/second
- **Congestion:** Multiple NPCs trying to deposit simultaneously
- **Efficiency:** NPCs might walk past land claim without depositing if cooldown active

**Options:**
- **Option A:** Keep auto-deposit, optimize with spatial partitioning
  - Use spatial grid to only check NPCs near land claims
  - Reduce check frequency for NPCs far from claims
  - Pros: Simple, works well for gatherers
  - Cons: Still 100+ checks/second at scale
  
- **Option B:** Explicit deposit tasks with job queue
  - NPCs request deposit job when inventory full
  - Job manager queues deposits, prevents congestion
  - Pros: Better control, can prioritize, prevents stampedes
  - Cons: More complex, gatherers need to "request" deposit
  
- **Option C:** Hybrid - Auto-deposit for gatherers, explicit tasks for women
  - Gatherers: Keep current auto-deposit (they're always near claims)
  - Women: Use explicit `DepositTask` in job sequences
  - Pros: Best of both worlds
  - Cons: Two systems to maintain

**Recommendation:** Option C - Keep auto-deposit for gatherers (they're always near land claims anyway), use explicit tasks for women (they're doing multi-step jobs).

**Performance Optimization:**
- Spatial grid: Only check NPCs within 300px of any land claim
- Batch processing: Process deposits in batches (10 NPCs per frame)
- Distance-based checks: NPCs far from claims check less frequently

---

#### 4. **Job Discovery & Assignment**

**Question:** How should 50+ NPCs find jobs efficiently?

**Current System:**
- NPCs use FSM priority system to choose states
- States check conditions (can_enter, get_priority)

**Concerns at Scale:**
- **Performance:** 50 NPCs × 10 buildings = 500 job queries per evaluation cycle
- **Starvation:** Some NPCs might never get jobs if others are faster
- **Congestion:** Multiple NPCs competing for same job

**Options:**
- **Option A:** NPCs query buildings directly (current FSM model)
  - Each NPC checks nearby buildings for jobs
  - First to claim gets the job
  - Pros: Simple, decentralized
  - Cons: O(n×m) complexity, race conditions
  
- **Option B:** Central job manager/board
  - Buildings post jobs to central board
  - NPCs query board for available jobs
  - Pros: Better coordination, can prioritize, prevents duplicates
  - Cons: Single point of failure, more complex
  
- **Option C:** Spatial job board (recommended)
  - Jobs organized by spatial regions
  - NPCs only query jobs in their region
  - Pros: Scales well, reduces queries
  - Cons: More complex implementation

**Recommendation:** Start with Option A (simple)

**Performance Optimization:**
- Job caching: Buildings cache available jobs for 1-2 seconds
- Spatial queries: Only check buildings within 500px
- Job claiming: Atomic job claiming prevents race conditions

---

#### 5. **Task Execution Performance**

**Question:** Can the task system handle 50+ NPCs executing tasks simultaneously?

**Concerns:**
- **Update overhead:** Each task's `tick()` called every frame
- **Memory:** Each job stores task list
- **Pathfinding:** Multiple NPCs pathfinding simultaneously

**Performance Analysis:**
- **50 NPCs × 1 task per NPC = 50 task updates/frame**
- **Task updates are lightweight** (check distance, update timer, etc.)
- **Pathfinding is the bottleneck**, not task system

**Optimization Strategies:**
- **Task batching:** Update tasks in batches (10 per frame, round-robin)
- **LOD system:** NPCs far from camera update less frequently
- **Pathfinding pooling:** Reuse pathfinding calculations
- **Spatial partitioning:** Only update NPCs in active regions

**Recommendation:** Task system itself is lightweight. Focus optimization on pathfinding and spatial queries.

---

#### 6. **Inventory Management at Scale**

**Question:** How should woman inventory (1 slot, 5 items) work with 50+ women?

**Current System:**
- NPCs have 10-slot inventories
- Auto-deposit when near land claim

**Concerns:**
- **Resource flow:** 50 women × 5 items = 250 items in transit
- **Land claim capacity:** Can land claim handle 50 women depositing simultaneously?
- **Inventory locks:** What if woman tries to pick up item that's being used?

**Design Decisions:**
- **Inventory locking:** When woman picks up item, "reserve" it for 30 seconds
- **Deposit queuing:** Women queue at land claim if it's busy
- **Resource tracking:** Track items "in transit" vs "in storage"
- **Capacity planning:** Land claim needs enough slots for women + storage

**Recommendation:**
- Land claim should have slots = (woman_count × 2) + storage_slots
- Example: 50 women need 100 slots for in-transit items + 50 storage = 150 slots minimum
- Use inventory locking to prevent conflicts

---

#### 7. **Combat Interruption**

**Question:** How should tasks handle combat with 50+ NPCs?

**Current System:**
- FSM states have priorities, combat has highest priority
- States can be interrupted by combat

**Task System Needs:**
- **Task cancellation:** All tasks must be cancellable
- **Resource return:** If woman dies mid-job, return resources
- **Job suspension:** Can jobs be paused and resumed?

**Options:**
- **Option A:** Cancel job on combat, woman finds new job after
  - Pros: Simple, prevents stuck NPCs
  - Cons: Work is lost, inefficient
  
- **Option B:** Suspend job, resume after combat
  - Pros: Work preserved, efficient
  - Cons: More complex, need to track job state
  
- **Option C:** Hybrid - Cancel if woman dies, suspend if combat
  - Pros: Best of both worlds
  - Cons: Most complex

**Recommendation:** Option A for Phase 1 (simplicity), Option C for Phase 5 (optimization).

**Implementation:**
- TaskRunner checks for combat before each task
- If combat detected, cancel current job
- Return resources to source if possible
- Woman finds new job after combat ends

---

#### 8. **Job Priority & Woman Selection**

**Question:** How should jobs be prioritized with 50+ women?

**Current System:**
- FSM states have priorities (gather=3.0, herd=11.0, etc.)
- Higher priority states take precedence

**Task System Needs:**
- **Job priorities:** Which jobs are more important?
- **Woman selection:** Which woman should take which job?
- **Dynamic priorities:** Should priorities change based on urgency?

**Design:**
- **Job priorities:**
  - Urgent: Oven needs fuel NOW (priority 10.0)
  - Normal: Oven needs ingredients (priority 5.0)
  - Low: General gathering (priority 1.0)
  
- **Woman selection:**
  - Nearest woman takes job (distance-based)
  - Women can have preferences (some prefer certain jobs)
  - Prevent job hoarding (woman can only have 1 job)
  
- **Dynamic priorities:**
  - Oven running out of fuel → priority increases
  - Resource scarcity → gathering priority increases
  - Too many women idle → lower job requirements

**Recommendation:** Start with simple distance-based selection, add preferences later.

---

## Potential Conflicts & Solutions

### Conflict 1: Auto-Deposit vs Explicit Tasks

**Problem:** Current auto-deposit happens automatically. Task system requires explicit tasks.

**Solution:** Hybrid approach
- **Gatherers:** Keep auto-deposit (they're always near land claims)
- **Women:** Use explicit `DepositTask` in job sequences
- **Rationale:** Gatherers are simple (gather → deposit), women are complex (multi-step jobs)

---

### Conflict 2: FSM Priority vs Job Priority

**Problem:** FSM states have priorities (gather=3.0, herd=11.0). Jobs also need priorities.

**Solution:** Separate systems
- **FSM priorities:** For behavioral states (idle, combat, herd)
- **Job priorities:** For work states (gathering, building work)
- **Integration:** FSM state can assign job to TaskRunner based on FSM priority
- **Example:** `work_state` (priority 7.0) enters → assigns high-priority job to TaskRunner

---

### Conflict 3: Resource Competition

**Problem:** 50 women might all try to pick up same resource simultaneously.

**Solution:** Resource locking
- When woman starts `PickUpTask`, lock resource for 5 seconds
- Other women skip locked resources
- Lock expires if woman doesn't complete task
- Prevents stampedes and race conditions

---

### Conflict 4: Building Occupation

**Problem:** Current system uses `occupy_building_state`. Task system uses `OccupyTask`.

**Solution:** Task wraps state
- `OccupyTask` internally uses `occupy_building_state` logic
- Task manages occupation lifecycle
- State handles building interaction
- Gradual migration: Task → State → Building

---

### Conflict 5: Performance at Scale

**Problem:** 50+ NPCs might cause performance issues.

**Solution:** Optimization strategies
- **Spatial partitioning:** Only update NPCs in active regions
- **LOD system:** NPCs far from camera update less frequently
- **Job caching:** Cache job availability for 1-2 seconds
- **Batch processing:** Process tasks in batches (10 per frame)
- **Pathfinding pooling:** Reuse pathfinding calculations

**Performance Targets:**
- 50 NPCs: 60 FPS (current target)
- 100 NPCs: 30 FPS (future target)
- 200 NPCs: 15 FPS (stretch goal)

---

## Scalability Analysis

### Current System Performance (Estimated)

**With 50 NPCs:**
- FSM evaluations: 50 × 10 states = 500 checks/second (if evaluating every second)
- Pathfinding: 50 NPCs pathfinding = ~50 pathfinding calls/second
- Auto-deposit checks: 50 × 2 checks/second = 100 checks/second
- **Total overhead: ~650 operations/second**
- **Performance: Likely 30-60 FPS depending on pathfinding complexity**

### Task System Performance (Estimated)

**With 50 NPCs:**
- Task updates: 50 tasks × 60 FPS = 3000 updates/second
- Job queries: 50 NPCs × 5 buildings = 250 queries/second (with caching)
- Pathfinding: Same as current (~50 calls/second)
- **Total overhead: ~3300 operations/second**
- **Performance: Likely 20-40 FPS without optimization**

### Optimized Task System Performance (Estimated)

**With 50 NPCs (optimized):**
- Task updates: 50 tasks × 30 FPS (LOD) = 1500 updates/second
- Job queries: 50 NPCs × 1 query/second (cached) = 50 queries/second
- Pathfinding: Same as current (~50 calls/second)
- **Total overhead: ~1600 operations/second**
- **Performance: Likely 40-60 FPS**

**Conclusion:** Task system needs optimization to match current performance, but is achievable.

---

## Recommended Approach for 50+ NPCs

### Phase 1: Foundation (10-20 NPCs)
- Implement basic task system
- Test with small number of NPCs
- No optimization needed

### Phase 2: Optimization (20-50 NPCs)
- Add spatial partitioning
- Implement job caching
- Add LOD system for distant NPCs
- Performance target: 60 FPS with 50 NPCs

### Phase 3: Scale Testing (50-100 NPCs)
- Stress test with 100 NPCs
- Optimize bottlenecks
- Add batch processing
- Performance target: 30 FPS with 100 NPCs

### Phase 4: Production (100+ NPCs)
- Full optimization
- Advanced features (woman preferences, dynamic priorities)
- Performance target: 30 FPS with 100 NPCs, 15 FPS with 200 NPCs

---

## Conclusion

This task/job system provides a clean, scalable foundation for NPC work that will:
- Streamline gathering, herding, and building work
- Enable automated resource logistics
- Create visually rich village activity
- Support future expansion (sheep, goats, new buildings)

**Key Decisions Made:**
1. **Hybrid approach:** Keep gathering/herding as FSM states, use tasks for building work
2. **Auto-deposit for gatherers:** Keep current auto-deposit, use explicit tasks for women
3. **Spatial optimization:** Use spatial partitioning and job caching for performance
4. **Gradual migration:** Start simple, optimize as needed

---

## Critical Questions to Resolve

### 1. **Gathering System Integration**

**Question:** How should gathering work with the task system?

**Current System:**
- NPCs use `gather_state` with FSM priority system
- Auto-deposit happens when NPCs are near land claim (within 50px - reduced from 200px for realism)
- NPCs must physically approach the land claim to deposit items
- NPCs gather until inventory is 80% full (4/5 slots), then deposit
- Gathering has priority 3.0, below herding (11.0) and deposit (11.0)

**Options:**
- **Option A:** Keep gathering as FSM state, use tasks only for building work
  - Pros: Minimal disruption, gathering already works well
  - Cons: Inconsistent system (some work uses tasks, some uses states)
  
- **Option B:** Convert gathering to tasks (`GatherTask` + `DepositTask`)
  - Pros: Unified system, easier to add gathering variations
  - Cons: Need to handle auto-deposit logic, may lose current efficiency
  
- **Option C:** Hybrid - Gathering stays as state, but uses tasks for deposit
  - Pros: Best of both worlds
  - Cons: More complex integration

**Recommendation:** Start with Option A, migrate to Option B after building work is proven.

**Conflict:** Auto-deposit currently happens automatically when near land claim. With tasks, we'd need explicit `DepositTask`. Should we:
- Keep auto-deposit for gatherers (simpler)?
- Require explicit deposit tasks (more control)?
- Hybrid: Auto-deposit for gatherers, explicit tasks for women?

---

### 2. **Herding System Integration**

**Question:** Should herding use the task system?

**Current System:**
- `herd_state` handles following behavior with complex distance logic
- Herding has very high priority (11.0)
- Herding can be interrupted by combat, clan joining, etc.

**Options:**
- **Option A:** Keep herding as FSM state (recommended)
  - Pros: Herding is behavior, not work. FSM handles interruptions well
  - Cons: Inconsistent with task system
  
- **Option B:** Convert to `FollowTask`
  - Pros: Unified system
  - Cons: Herding needs complex logic (distance bands, catch-up, etc.) that doesn't fit task model well

**Recommendation:** Keep herding as FSM state. Herding is behavioral (following), not work (production). Tasks are for work, FSM is for behavior.

**Conflict:** None - herding and tasks can coexist.

---

### 3. **Deposit System - Auto vs Explicit**

**Question:** How should deposits work with 50+ NPCs?

**Current System:**
- Auto-deposit when NPC is within 50px of land claim
- Cooldown of 1 second between deposits
- Check interval of 0.5 seconds
- NPCs deposit all items at once

**Concerns at Scale (50+ NPCs):**
- **Performance:** 50 NPCs checking every 0.5s = 100 checks/second
- **Congestion:** Multiple NPCs trying to deposit simultaneously
- **Efficiency:** NPCs might walk past land claim without depositing if cooldown active

**Options:**
- **Option A:** Keep auto-deposit, optimize with spatial partitioning
  - Use spatial grid to only check NPCs near land claims
  - Reduce check frequency for NPCs far from claims
  - Pros: Simple, works well for gatherers
  - Cons: Still 100+ checks/second at scale
  
- **Option B:** Explicit deposit tasks with job queue
  - NPCs request deposit job when inventory full
  - Job manager queues deposits, prevents congestion
  - Pros: Better control, can prioritize, prevents stampedes
  - Cons: More complex, gatherers need to "request" deposit
  
- **Option C:** Hybrid - Auto-deposit for gatherers, explicit tasks for women
  - Gatherers: Keep current auto-deposit (they're always near claims)
  - Women: Use explicit `DepositTask` in job sequences
  - Pros: Best of both worlds
  - Cons: Two systems to maintain

**Recommendation:** Option C - Keep auto-deposit for gatherers (they're always near land claims anyway), use explicit tasks for women (they're doing multi-step jobs).

**Performance Optimization:**
- Spatial grid: Only check NPCs within 300px of any land claim
- Batch processing: Process deposits in batches (10 NPCs per frame)
- Distance-based checks: NPCs far from claims check less frequently

---

### 4. **Job Discovery & Assignment**

**Question:** How should 50+ NPCs find jobs efficiently?

**Current System:**
- NPCs use FSM priority system to choose states
- States check conditions (can_enter, get_priority)

**Concerns at Scale:**
- **Performance:** 50 NPCs × 10 buildings = 500 job queries per evaluation cycle
- **Starvation:** Some NPCs might never get jobs if others are faster
- **Congestion:** Multiple NPCs competing for same job

**Options:**
- **Option A:** NPCs query buildings directly (current FSM model)
  - Each NPC checks nearby buildings for jobs
  - First to claim gets the job
  - Pros: Simple, decentralized
  - Cons: O(n×m) complexity, race conditions
  
- **Option B:** Central job manager/board
  - Buildings post jobs to central board
  - NPCs query board for available jobs
  - Pros: Better coordination, can prioritize, prevents duplicates
  - Cons: Single point of failure, more complex
  
- **Option C:** Spatial job board (recommended)
  - Jobs organized by spatial regions
  - NPCs only query jobs in their region
  - Pros: Scales well, reduces queries
  - Cons: More complex implementation

**Recommendation:** Start with Option A (simple), migrate to Option C if performance becomes issue.

**Performance Optimization:**
- Job caching: Buildings cache available jobs for 1-2 seconds
- Spatial queries: Only check buildings within 500px
- Job claiming: Atomic job claiming prevents race conditions

---

### 5. **Task Execution Performance**

**Question:** Can the task system handle 50+ NPCs executing tasks simultaneously?

**Concerns:**
- **Update overhead:** Each task's `tick()` called every frame
- **Memory:** Each job stores task list
- **Pathfinding:** Multiple NPCs pathfinding simultaneously

**Performance Analysis:**
- **50 NPCs × 1 task per NPC = 50 task updates/frame**
- **Task updates are lightweight** (check distance, update timer, etc.)
- **Pathfinding is the bottleneck**, not task system

**Optimization Strategies:**
- **Task batching:** Update tasks in batches (10 per frame, round-robin)
- **LOD system:** NPCs far from camera update less frequently
- **Pathfinding pooling:** Reuse pathfinding calculations
- **Spatial partitioning:** Only update NPCs in active regions

**Recommendation:** Task system itself is lightweight. Focus optimization on pathfinding and spatial queries.

---

### 6. **Inventory Management at Scale**

**Question:** How should woman inventory (1 slot, 5 items) work with 50+ women?

**Current System:**
- NPCs have 10-slot inventories
- Auto-deposit when near land claim

**Concerns:**
- **Resource flow:** 50 women × 5 items = 250 items in transit
- **Land claim capacity:** Can land claim handle 50 women depositing simultaneously?
- **Inventory locks:** What if woman tries to pick up item that's being used?

**Design Decisions:**
- **Inventory locking:** When woman picks up item, "reserve" it for 30 seconds
- **Deposit queuing:** Women queue at land claim if it's busy
- **Resource tracking:** Track items "in transit" vs "in storage"
- **Capacity planning:** Land claim needs enough slots for women + storage

**Recommendation:**
- Land claim should have slots = (woman_count × 2) + storage_slots
- Example: 50 women need 100 slots for in-transit items + 50 storage = 150 slots minimum
- Use inventory locking to prevent conflicts

---

### 7. **Combat Interruption**

**Question:** How should tasks handle combat with 50+ NPCs?

**Current System:**
- FSM states have priorities, combat has highest priority
- States can be interrupted by combat

**Task System Needs:**
- **Task cancellation:** All tasks must be cancellable
- **Resource return:** If woman dies mid-job, return resources
- **Job suspension:** Can jobs be paused and resumed?

**Options:**
- **Option A:** Cancel job on combat, woman finds new job after
  - Pros: Simple, prevents stuck NPCs
  - Cons: Work is lost, inefficient
  
- **Option B:** Suspend job, resume after combat
  - Pros: Work preserved, efficient
  - Cons: More complex, need to track job state
  
- **Option C:** Hybrid - Cancel if woman dies, suspend if combat
  - Pros: Best of both worlds
  - Cons: Most complex

**Recommendation:** Option A for Phase 1 (simplicity), Option C for Phase 5 (optimization).

**Implementation:**
- TaskRunner checks for combat before each task
- If combat detected, cancel current job
- Return resources to source if possible
- Woman finds new job after combat ends

---

### 8. **Job Priority & Woman Selection**

**Question:** How should jobs be prioritized with 50+ women?

**Current System:**
- FSM states have priorities (gather=3.0, herd=11.0, etc.)
- Higher priority states take precedence

**Task System Needs:**
- **Job priorities:** Which jobs are more important?
- **Woman selection:** Which woman should take which job?
- **Dynamic priorities:** Should priorities change based on urgency?

**Design:**
- **Job priorities:**
  - Urgent: Oven needs fuel NOW (priority 10.0)
  - Normal: Oven needs ingredients (priority 5.0)
  - Low: General gathering (priority 1.0)
  
- **Woman selection:**
  - Nearest woman takes job (distance-based)
  - Women can have preferences (some prefer certain jobs)
  - Prevent job hoarding (woman can only have 1 job)
  
- **Dynamic priorities:**
  - Oven running out of fuel → priority increases
  - Resource scarcity → gathering priority increases
  - Too many women idle → lower job requirements

**Recommendation:** Start with simple distance-based selection, add preferences later.

---

## Additional Open Questions

1. Should we keep auto-deposit for gatherers or migrate to explicit tasks?
2. What's the target NPC count? (affects optimization strategy)
3. Should women have preferences for certain job types?
4. How should job priorities be determined? (static vs dynamic)

**Next Steps:**
1. Review and approve this plan
2. Resolve open questions
3. Start with Phase 1 (Core Task System) with 10-20 NPCs
4. Test and iterate
5. Optimize for scale in Phase 2
