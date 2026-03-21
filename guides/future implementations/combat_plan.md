# Combat System Refactor - Implementation Plan

**Goal**: Scale combat system for raids (50+ units) and multiplayer while maintaining tactical feel.

**Reference**: See `main.md` for full design documentation and rationale.

---

## 📋 Overview

This plan implements:
- Event-driven combat (windup/hit/recovery)
- Spatial target detection (replaces `get_nodes_in_group()`)
- Combat scheduler (autoload singleton)
- Zone A combat (high-fidelity near player)
- Zone B combat (low-fidelity, postponed for now)

**Expected Performance Gain**: ~60x reduction in target acquisition overhead (360 scans/sec → 6 queries/sec)

---

## 🎯 Implementation Phases

### Phase 1: DetectionArea System (Biggest Win, Lowest Risk)
**Goal**: Remove `get_nodes_in_group()` performance bottleneck

**Files to Modify:**
- `scripts/npc/npc_base.gd` - Add DetectionArea node
- `scripts/npc/states/combat_state.gd` - Replace `_find_nearest_enemy()`
- Create: `scripts/npc/components/detection_area.gd`

**Steps:**

1. **Create DetectionArea Component**
   - New file: `scripts/npc/components/detection_area.gd`
   - Extends `Area2D`
   - Event-driven tracking (`_on_body_entered`, `_on_body_exited`)
   - Query API: `get_nearest_enemy()`, `has_enemies()`

2. **Add DetectionArea to NPC Scene**
   - Add `Area2D` node to NPC scene
   - Add `CollisionShape2D` (Circle, radius 200-400px)
   - Set physics layers/masks
   - Attach `detection_area.gd` script

3. **Refactor CombatState**
   - Remove `_find_nearest_enemy()` method (lines 94-132)
   - Remove `get_nodes_in_group()` calls
   - Add retarget timer (1 second interval)
   - Use `npc.detection_area.get_nearest_enemy()` instead

4. **Add Backwards Compatibility**
   - Check `if npc.has_node("DetectionArea")` before using
   - Fallback to old method during migration
   - Remove fallback once all NPCs have DetectionArea

5. **Testing**
   - 1 NPC vs Player - attacks still work
   - 5 NPCs idle - CPU stays flat
   - 5 NPCs fighting - no attack spam
   - Kill target - NPC retargets after ~1s

**Success Criteria:**
- No `get_nodes_in_group()` calls in combat code
- CPU usage flat with multiple NPCs
- Combat behavior unchanged

---

### Phase 2: Combat Scheduler (Event System Foundation)
**Goal**: Create event-driven combat timing system

**Files to Create:**
- `scripts/systems/combat_scheduler.gd` (autoload singleton)

**Files to Modify:**
- `project.godot` - Add CombatScheduler to autoload

**Steps:**

1. **Create CombatScheduler Singleton**
   - New file: `scripts/systems/combat_scheduler.gd`
   - Array-based event queue (sorted by time)
   - `schedule(time_msec, callable)` method
   - `_process()` loop to resolve events
   - Event validation (check `callable.is_valid()`)

2. **Add to Autoload**
   - In `project.godot`, add `CombatScheduler` as autoload
   - Path: `res://scripts/systems/combat_scheduler.gd`

3. **Basic Event Types**
   - `AttackHit` - Damage resolution
   - `RecoveryEnd` - Attack cooldown finished
   - `MoraleCheck` - Morale evaluation (future)

4. **Testing**
   - Schedule test events
   - Verify events fire at correct times
   - Verify event cancellation on death

**Success Criteria:**
- Events fire at scheduled times
- Events can be cancelled
- No memory leaks (invalid callables handled)

---

### Phase 3: CombatComponent Refactor (Windup/Recovery)
**Goal**: Add windup/recovery phases to combat

**Files to Modify:**
- `scripts/npc/components/combat_component.gd`

**Steps:**

1. **Add Internal State Machine**
   - States: `IDLE`, `WINDUP`, `RECOVERY`
   - State transitions triggered by events
   - Keep existing `attack()` method (deprecated, calls `request_attack()`)

2. **Add `request_attack()` Method**
   - Check if in `IDLE` state (reject spam)
   - Set state to `WINDUP`
   - Schedule `AttackHit` event via CombatScheduler
   - Store target reference

3. **Migrate from Cooldown to Windup/Recovery**
   - Replace `last_attack_time + cooldown` logic
   - Use `windup_time` (0.3-0.6s) and `recovery_time` (0.4-1.2s)
   - Total attack time = windup + recovery

4. **Hit Resolution**
   - On `AttackHit` event: validate target, apply damage, schedule `RecoveryEnd`
   - On `RecoveryEnd` event: set state back to `IDLE`

5. **Add Combat Lock**
   - Add `combat_locked` flag to NPC
   - Set `true` during windup, `false` after recovery
   - Prevents FSM state switching mid-attack

6. **Testing**
   - NPC attacks have visible windup
   - Attacks can't be spammed
   - FSM doesn't switch states during windup
   - Damage applies on hit frame, not instantly

**Success Criteria:**
- Attacks have windup/recovery phases
- No attack spam
- FSM respects combat lock
- Backwards compatible (old `attack()` still works)

---

### Phase 4: FSM Integration (Combat Lock)
**Goal**: Prevent FSM from interrupting combat

**Files to Modify:**
- `scripts/npc/npc_base.gd` - Add `combat_locked` property
- `scripts/npc/fsm.gd` - Check combat lock before state transitions

**Steps:**

1. **Add Combat Lock to NPC**
   - Add `var combat_locked := false` to NPCBase
   - CombatComponent sets this during windup/recovery

2. **Update FSM Transition Logic**
   - In `_evaluate_states()`, check `if npc.combat_locked: return`
   - Prevents state switching during windup/recovery

3. **Testing**
   - NPC in windup doesn't switch to wander/eat
   - Combat state persists through full attack cycle
   - State switching resumes after recovery

**Success Criteria:**
- No state flickering during combat
- Combat completes full cycle before state change
- Other states still work normally

---

### Phase 5: Player Combat Integration
**Goal**: Player uses same combat system

**Files to Modify:**
- `scripts/player.gd` - Add CombatComponent
- `scripts/main.gd` - Update `_player_attack_npc()`

**Steps:**

1. **Add CombatComponent to Player**
   - Add CombatComponent node to Player scene
   - Initialize in `_ready()`

2. **Update Player Attack**
   - Modify `_player_attack_npc()` to call `player.combat_component.request_attack()`
   - Remove instant damage logic
   - Player-specific timing: windup 0.1s, recovery 0.3-0.5s

3. **Player Movement During Combat**
   - Player can still move during windup (tactical positioning)
   - Or lock movement during windup (more commitment)

4. **Testing**
   - Player click-to-attack works
   - Player attacks have windup (short)
   - Player can't spam attacks
   - Combat feels responsive

**Success Criteria:**
- Player combat uses same system as NPCs
- Player attacks feel responsive (short windup)
- No special-casing in combat logic

---

### Phase 6: Zone A Combat (Full Implementation)
**Goal**: Complete Zone A combat system

**Note**: Zone B is postponed - implement only Zone A for now

**Files to Modify:**
- `scripts/npc/components/combat_component.gd` - Add attack profiles
- `scripts/npc/components/weapon_component.gd` - Weapon-specific timings

**Steps:**

1. **Attack Profiles**
   - Create `AttackProfile` data structure
   - Properties: `range`, `arc`, `windup_time`, `recovery_time`, `base_damage`, `stagger`
   - Different profiles per weapon type

2. **Hit Validation**
   - On hit frame: check target alive, in range, in arc, line-of-sight
   - Apply damage only if all checks pass
   - Whiff if checks fail

3. **Stagger System**
   - On hit: add `stagger_time` to target's recovery
   - Optional: cancel target's windup if hit early
   - Prevents attack spam

4. **Attack Arcs**
   - Calculate facing direction
   - Check if target is within 90° cone
   - Adds tactical positioning

5. **Testing**
   - Attacks can miss if target moves
   - Stagger interrupts enemy attacks
   - Attack arcs work correctly
   - Multiple weapon types have different timings

**Success Criteria:**
- Full windup/hit/recovery cycle works
- Hit validation prevents impossible hits
- Stagger system creates tactical depth
- Weapon variety feels different

---

## 🔧 Technical Details

### DetectionArea Implementation

**File**: `scripts/npc/components/detection_area.gd`

```gdscript
extends Area2D
class_name DetectionArea

var nearby_enemies := {}

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
    if body.is_in_group("combatant"):
        nearby_enemies[body.get_instance_id()] = body

func _on_body_exited(body: Node2D):
    nearby_enemies.erase(body.get_instance_id())

func get_nearest_enemy(origin: Vector2) -> Node:
    var closest := null
    var best_dist := INF
    
    for enemy in nearby_enemies.values():
        if not is_instance_valid(enemy):
            continue
        if not enemy.has_method("is_alive") or not enemy.is_alive():
            continue
        var d = origin.distance_squared_to(enemy.global_position)
        if d < best_dist:
            best_dist = d
            closest = enemy
    
    return closest

func has_enemies() -> bool:
    return nearby_enemies.size() > 0
```

### CombatScheduler Implementation

**File**: `scripts/systems/combat_scheduler.gd`

```gdscript
extends Node
class_name CombatScheduler

var events := []

func _process(_delta: float):
    var now = Time.get_ticks_msec()
    
    while events.size() > 0 and events[0].time <= now:
        var event = events.pop_front()
        if event.callable.is_valid():
            event.callable.call()

func schedule(time_msec: int, callable: Callable):
    events.append({ "time": time_msec, "callable": callable })
    events.sort_custom(func(a, b): return a.time < b.time)

func cancel_all_for_entity(entity_id: int):
    # Remove events for specific entity
    events = events.filter(func(e): return e.entity_id != entity_id)
```

### CombatComponent State Machine

**File**: `scripts/npc/components/combat_component.gd` (additions)

```gdscript
enum CombatState { IDLE, WINDUP, RECOVERY }

var state: CombatState = CombatState.IDLE
var current_target: Node = null
var windup_time: float = 0.45
var recovery_time: float = 0.8

func request_attack(target: Node) -> void:
    if state != CombatState.IDLE:
        return  # Reject spam
    
    if not _can_attack_target(target):
        return
    
    state = CombatState.WINDUP
    current_target = target
    
    # Set combat lock
    if npc:
        npc.combat_locked = true
    
    # Schedule hit event
    var hit_time = Time.get_ticks_msec() + int(windup_time * 1000)
    CombatScheduler.schedule(hit_time, _on_hit_frame.bind())
    
    # Play windup animation/sprite change

func _on_hit_frame():
    if not is_instance_valid(current_target):
        _cancel_attack()
        return
    
    # Validate hit
    if not _validate_hit(current_target):
        _cancel_attack()
        return
    
    # Apply damage
    var damage = base_damage + weapon_bonus
    var target_health = current_target.get_node_or_null("HealthComponent")
    if target_health:
        target_health.take_damage(damage, npc, weapon_type)
    
    # Schedule recovery
    state = CombatState.RECOVERY
    var recovery_end_time = Time.get_ticks_msec() + int(recovery_time * 1000)
    CombatScheduler.schedule(recovery_end_time, _on_recovery_end.bind())

func _on_recovery_end():
    state = CombatState.IDLE
    current_target = null
    
    # Release combat lock
    if npc:
        npc.combat_locked = false

func _validate_hit(target: Node) -> bool:
    if not is_instance_valid(target):
        return false
    
    var distance = npc.global_position.distance_to(target.global_position)
    if distance > attack_range:
        return false
    
    # Check attack arc (90° cone)
    var direction_to_target = (target.global_position - npc.global_position).normalized()
    var facing = Vector2(cos(npc.rotation), sin(npc.rotation))
    var angle = direction_to_target.angle_to(facing)
    if abs(angle) > PI / 4:  # 90 degrees
        return false
    
    return true
```

### CombatState Refactor

**File**: `scripts/npc/states/combat_state.gd` (changes)

```gdscript
const TARGET_CHECK_INTERVAL := 1.0
var next_target_check_time := 0

func update(_delta: float) -> void:
    _update_targeting()
    _update_movement()

func _update_targeting() -> void:
    var now = Time.get_ticks_msec()
    if now < next_target_check_time:
        return
    
    next_target_check_time = now + int(TARGET_CHECK_INTERVAL * 1000)
    
    # Target still valid? Keep it.
    if combat_target and _is_valid_target(combat_target):
        return
    
    # Ask DetectionArea, NOT the world
    if npc.has_node("DetectionArea"):
        var detection_area = npc.get_node("DetectionArea")
        if detection_area.has_enemies():
            combat_target = detection_area.get_nearest_enemy(npc.global_position)
        else:
            combat_target = null
    else:
        # Fallback during migration
        _find_nearest_enemy_legacy()

func _update_movement() -> void:
    if not combat_target:
        npc.steering_agent.stop()
        return
    
    var distance = npc.global_position.distance_to(combat_target.global_position)
    
    if distance > npc.attack_range:
        npc.steering_agent.set_target_position(combat_target.global_position)
    else:
        npc.steering_agent.stop()
        
        # IMPORTANT: we do NOT attack here
        # We only express intent
        var combat_comp = npc.get_node_or_null("CombatComponent")
        if combat_comp:
            combat_comp.request_attack(combat_target)

# DELETE THIS METHOD after migration:
func _find_nearest_enemy_legacy() -> void:
    # Old implementation for backwards compat
    pass
```

---

## ✅ Testing Checklist

### Phase 1: DetectionArea
- [ ] 1 NPC vs Player - attacks work
- [ ] 5 NPCs idle - CPU flat (no per-frame scanning)
- [ ] 5 NPCs fighting - no attack spam
- [ ] Kill target - NPC retargets after ~1s
- [ ] No `get_nodes_in_group()` in combat code

### Phase 2: Combat Scheduler
- [ ] Events fire at correct times
- [ ] Events can be cancelled
- [ ] No memory leaks (invalid callables handled)
- [ ] Multiple events scheduled correctly

### Phase 3: Windup/Recovery
- [ ] Attacks have visible windup
- [ ] Attacks can't be spammed
- [ ] Damage applies on hit frame
- [ ] Recovery prevents immediate re-attack
- [ ] Backwards compatible (old `attack()` works)

### Phase 4: FSM Integration
- [ ] No state switching during windup
- [ ] Combat completes full cycle
- [ ] Other states work normally
- [ ] Combat lock releases after recovery

### Phase 5: Player Combat
- [ ] Player click-to-attack works
- [ ] Player attacks have windup (short)
- [ ] Player can't spam attacks
- [ ] Feels responsive

### Phase 6: Zone A Complete
- [ ] Attacks can miss if target moves
- [ ] Stagger interrupts enemy attacks
- [ ] Attack arcs work (90° cone)
- [ ] Different weapons have different timings
- [ ] Hit validation prevents impossible hits

---

## 🚨 Common Pitfalls to Avoid

1. **Don't disable DetectionArea during combat** - it must stay active
2. **Don't call `attack()` every frame** - use `request_attack()` once
3. **Don't forget combat lock** - FSM will interrupt attacks
4. **Don't skip hit validation** - prevents impossible hits
5. **Don't remove backwards compat too early** - keep fallback during migration

---

## 📊 Performance Validation

Add debug counters to verify improvements:

```gdscript
# In CombatScheduler
var events_processed_per_second := 0
var event_count_this_second := 0

# In DetectionArea
var query_count := 0
```

Expected results:
- **Before**: ~360 `get_nodes_in_group()` calls per second (6 NPCs × 60fps)
- **After**: ~6 DetectionArea queries per second (6 NPCs × 1 query/sec)
- **60x reduction** in target acquisition overhead

---

## 🔄 Migration Strategy

1. **Feature Flag Approach**
   ```gdscript
   const USE_EVENT_COMBAT := true
   ```

2. **Gradual Rollout**
   - Phase 1: DetectionArea (no combat changes)
   - Phase 2: Scheduler (no combat changes)
   - Phase 3: Windup/recovery (combat changes)
   - Phase 4-6: Integration and polish

3. **Backwards Compatibility**
   - Keep old methods during migration
   - Remove fallbacks once stable
   - Test battle royale mode after each phase

4. **Rollback Plan**
   - Keep old code commented out
   - Feature flag to switch back
   - Test both paths

---

## 📝 Next Steps After This Plan

Once Phase 1-6 are complete:

1. **Zone B System** (when needed for raids)
   - Engagement clusters
   - Statistical combat resolution
   - Zone transition logic

2. **Morale System**
   - Morale breaks
   - Fleeing behavior
   - Rally mechanics

3. **Advanced Features**
   - Wounds system
   - Stagger stacking
   - Weapon variety expansion

---

## 🎯 Success Metrics

**Performance:**
- CPU usage flat with 50+ NPCs
- No frame spikes during combat
- 60x reduction in target acquisition overhead

**Gameplay:**
- Combat feels tactical (windup telegraphs)
- No attack spam
- Positioning matters (attack arcs)
- Smooth state transitions

**Code Quality:**
- No `get_nodes_in_group()` in combat
- Event-driven architecture
- Clear separation of concerns
- Backwards compatible

---

**Last Updated**: January 2026  
**Status**: Implementation Plan - Follow phases in order
