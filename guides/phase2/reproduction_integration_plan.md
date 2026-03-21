# Reproduction System - Step-by-Step Integration Plan

**Date**: January 17, 2026  
**Status**: Implementation Plan  
**Goal**: Integrate reproduction system into existing game framework

## Overview

This document provides a step-by-step plan to implement the reproduction system as documented in `reproduction_system.md`. Each step builds on the previous ones and integrates with the existing Phase 1 systems.

---

## Prerequisites

Before starting, ensure you understand:
- Phase 1 systems (land claims, herding, gathering, FSM)
- NPC base structure (`npc_base.gd`)
- FSM state system (`fsm.gd`, `base_state.gd`)
- Land claim system (`land_claim.gd`)
- Naming utilities (`naming_utils.gd`)

---

## Step 1: Add Random Names to Women NPCs

**Purpose**: Women need random names when spawned (currently use "Woman %d" format)

### Files to Modify:
- `scripts/main.gd`

### Changes:
1. Update `_spawn_women()` function (around line 1119)
   - Change from: `var npc_name: String = "Woman %d" % (i + 1)`
   - Change to: `var npc_name: String = NamingUtils.generate_caveman_name()`

2. Update `_spawn_wild_woman()` function (around line 1272)
   - Change from: `var npc_name: String = "Woman %d" % (Time.get_ticks_msec() + i)`
   - Change to: `var npc_name: String = NamingUtils.generate_caveman_name()`

### Testing:
- Verify women spawn with random names (e.g., "Buki", "Laro")
- Check that names are unique (or at least different)

---

## Step 2: Create Reproduction Config

**Purpose**: Centralized configuration for reproduction system

### Files to Create:
- `scripts/config/reproduction_config.gd`

### Implementation:
```gdscript
extends Resource
class_name ReproductionConfig

@export var birth_timer_base: float = 90.0  # Fixed 90s for testing
@export var birth_cooldown: float = 20.0  # Seconds between births
@export var baby_pool_base_capacity: int = 3  # Base capacity from land claim
@export var living_hut_capacity_bonus: int = 5  # Per Living Hut
@export var baby_growth_time_testing: float = 60.0  # 1 minute to clansman (testing)
@export var baby_growth_age_normal: int = 13  # Age when becomes clansman (normal)
```

### Notes:
- Create as `.gd` resource file
- Will be loaded by reproduction component and baby pool manager

---

## Step 3: Create Baby Pool Manager

**Purpose**: Track baby pool capacity per clan

### Files to Create:
- `scripts/systems/baby_pool_manager.gd`

### Implementation Structure:
```gdscript
extends Node
class_name BabyPoolManager

var baby_pools: Dictionary = {}  # {clan_name: {capacity: int, current: int}}
var config: ReproductionConfig = null

func _ready() -> void:
    # Load config
    config = load("res://scripts/config/reproduction_config.gd").new()
    # Initialize baby pools for existing clans

func get_capacity(clan_name: String) -> int:
    # Calculate: 3 (base) + (living_hut_count * 5)
    # For now, just return base (3) until Living Huts are implemented
    return config.baby_pool_base_capacity

func get_current_count(clan_name: String) -> int:
    # Count actual baby NPCs in clan
    # TODO: Implement when babies exist

func can_add_baby(clan_name: String) -> bool:
    # Check if pool has space
    return get_current_count(clan_name) < get_capacity(clan_name)
```

### Integration Points:
- Add to Main scene in `_ready()`: `baby_pool_manager = BabyPoolManager.new()`
- Can be accessed via `get_node_or_null("/root/Main/BabyPoolManager")`

### Testing:
- Test capacity calculation (should return 3 for now)
- Test `can_add_baby()` function

---

## Step 4: Create Reproduction Component

**Purpose**: Handle birth timers, mate detection, pregnancy state for women

### Files to Create:
- `scripts/npc/components/reproduction_component.gd`

### Implementation Structure:
```gdscript
extends Node
class_name ReproductionComponent

var npc: NPCBase = null
var config: ReproductionConfig = null

var is_pregnant: bool = false
var birth_timer: float = 0.0
var last_birth_time: float = 0.0
var current_mate: NPCBase = null

func _ready() -> void:
    config = load("res://scripts/config/reproduction_config.gd").new()

func initialize(npc_ref: NPCBase) -> void:
    npc = npc_ref

func update(delta: float) -> void:
    # Only update if woman is in clan and inside land claim
    if not npc or npc.clan_name == "":
        return
    
    if not _is_in_land_claim():
        return
    
    if is_pregnant:
        _update_birth_timer(delta)
    elif _can_reproduce():
        _try_find_mate()

func _is_in_land_claim() -> bool:
    # Check if woman is inside her clan's land claim
    # TODO: Use land claim detection from base_state.gd
    return false

func _can_reproduce() -> bool:
    # Check cooldown
    var time_since_last_birth = Time.get_ticks_msec() / 1000.0 - last_birth_time
    return time_since_last_birth >= config.birth_cooldown

func _try_find_mate() -> void:
    # Find nearby male caveman (player or NPC) in same clan
    # TODO: Implement mate detection

func _update_birth_timer(delta: float) -> void:
    birth_timer -= delta
    if birth_timer <= 0.0:
        _spawn_baby()

func _spawn_baby() -> void:
    # Spawn baby at land claim center
    # TODO: Implement baby spawning
    is_pregnant = false
    birth_timer = 0.0
    last_birth_time = Time.get_ticks_msec() / 1000.0
```

### Integration Points:
- Attach to women NPCs in `npc_base.gd` or via scene
- Check `npc_type == "woman"` before attaching
- Update component in `_process()` or NPC update loop

### Testing:
- Verify component attaches to women NPCs
- Test initialization with valid NPC reference

---

## Step 5: Attach Reproduction Component to Women

**Purpose**: Ensure women NPCs have reproduction component

### Files to Modify:
- `scripts/npc/npc_base.gd`

### Changes:
1. Add component reference:
   ```gdscript
   var reproduction_component: Node = null
   ```

2. In `_ready()` or initialization:
   ```gdscript
   if npc_type == "woman":
       reproduction_component = preload("res://scripts/npc/components/reproduction_component.gd").new()
       add_child(reproduction_component)
       reproduction_component.initialize(self)
   ```

3. In `_process()` or update loop:
   ```gdscript
   if reproduction_component:
       reproduction_component.update(delta)
   ```

### Testing:
- Verify reproduction component exists on women NPCs
- Check component initializes correctly

---

## Step 6: Create Reproduction State

**Purpose**: FSM state for women seeking mates and gestating

### Files to Create:
- `scripts/npc/states/reproduction_state.gd`

### Implementation Structure:
```gdscript
extends "res://scripts/npc/states/base_state.gd"

func can_enter() -> bool:
    # Only women can enter
    if not npc or npc.get("npc_type") != "woman":
        return false
    
    # Must be in clan
    if not npc.clan_name or npc.clan_name == "":
        return false
    
    # Must have reproduction component
    if not npc.reproduction_component:
        return false
    
    return true

func get_priority() -> float:
    return 8.0  # Below herding (10.6), above gathering (3.0)

func enter() -> void:
    # State entered
    pass

func update(delta: float) -> void:
    # Reproduction logic handled by component
    # State just ensures woman can enter reproduction mode
    pass

func exit() -> void:
    pass
```

### Integration Points:
- Register in `fsm.gd` `_create_state_instances()` method
- Add to states dictionary as "reproduction"

### Testing:
- Verify state can be entered by women in clans
- Check priority is 8.0

---

## Step 7: Register Reproduction State in FSM

**Purpose**: Add reproduction state to FSM system

### Files to Modify:
- `scripts/npc/fsm.gd`

### Changes:
1. In `_create_state_instances()`:
   ```gdscript
   var reproduction_script: GDScript = load("res://scripts/npc/states/reproduction_state.gd") as GDScript
   
   if reproduction_script:
       var state: Node = Node.new()
       state.set_script(reproduction_script)
       state.name = "ReproductionState"
       add_child(state)
       states["reproduction"] = state
       state.initialize(npc)
       state.set("fsm", self)
   ```

2. In `_register_state()` calls (if needed):
   ```gdscript
   _register_state("reproduction", "")
   ```

### Testing:
- Verify reproduction state exists in FSM
- Check state can be entered/exited

---

## Step 8: Implement Land Claim Detection in Reproduction Component

**Purpose**: Check if woman is inside her clan's land claim

### Files to Modify:
- `scripts/npc/components/reproduction_component.gd`

### Changes:
1. Use helper from `base_state.gd`:
   ```gdscript
   func _is_in_land_claim() -> bool:
       var land_claim = _get_land_claim(npc.clan_name)
       if not land_claim:
           return false
       
       var distance = npc.global_position.distance_to(land_claim.global_position)
       return distance <= land_claim.radius
   ```

2. Helper function to get land claim:
   ```gdscript
   func _get_land_claim(clan_name: String) -> Node2D:
       var claims = get_tree().get_nodes_in_group("land_claims")
       for claim in claims:
           if claim.get("clan_name") == clan_name:
               return claim
       return null
   ```

### Testing:
- Verify detection works when woman is inside land claim
- Test detection when outside land claim

---

## Step 9: Implement Mate Detection in Reproduction Component

**Purpose**: Find nearby male cavemen (player or NPC) in same clan

### Files to Modify:
- `scripts/npc/components/reproduction_component.gd`

### Changes:
```gdscript
func _try_find_mate() -> void:
    # Find all NPCs in same clan
    var all_npcs = get_tree().get_nodes_in_group("npcs")
    var candidates: Array = []
    
    for candidate in all_npcs:
        if not is_instance_valid(candidate):
            continue
        
        # Check if male caveman (player or NPC caveman)
        var is_caveman = candidate.get("npc_type") == "caveman"
        var is_player = candidate.is_in_group("player")
        
        if not (is_caveman or is_player):
            continue
        
        # Check same clan
        if candidate.get("clan_name") != npc.clan_name:
            continue
        
        # Check if inside land claim
        if not _is_npc_in_land_claim(candidate):
            continue
        
        candidates.append(candidate)
    
    # Select best mate (prefer clan leader, higher quality)
    if candidates.size() > 0:
        current_mate = _select_best_mate(candidates)
        _start_pregnancy()

func _select_best_mate(candidates: Array) -> NPCBase:
    # For now, just pick first (or player if available)
    # TODO: Prioritize by traits and age (clan leader)
    for candidate in candidates:
        if candidate.is_in_group("player"):
            return candidate
    return candidates[0]

func _start_pregnancy() -> void:
    if not is_pregnant and _can_reproduce():
        is_pregnant = true
        birth_timer = config.birth_timer_base
        last_birth_time = Time.get_ticks_msec() / 1000.0
```

### Testing:
- Test mate detection with player in land claim
- Test mate detection with NPC cavemen in land claim
- Verify only same-clan mates are detected

---

## Step 10: Implement Baby Spawning

**Purpose**: Spawn baby NPC at land claim center when birth timer completes

### Files to Modify:
- `scripts/npc/components/reproduction_component.gd`
- `scripts/main.gd` (add baby spawning function)

### Changes in Reproduction Component:
```gdscript
func _spawn_baby() -> void:
    if not npc or npc.clan_name == "":
        return
    
    # Get land claim
    var land_claim = _get_land_claim(npc.clan_name)
    if not land_claim:
        return
    
    # Check baby pool capacity
    var baby_pool_manager = get_node_or_null("/root/Main/BabyPoolManager")
    if not baby_pool_manager or not baby_pool_manager.can_add_baby(npc.clan_name):
        return  # Pool full (for now, don't spawn)
    
    # Spawn baby at land claim center
    var main = get_tree().get_first_node_in_group("main")
    if main and main.has_method("_spawn_baby"):
        main._spawn_baby(npc.clan_name, land_claim.global_position, npc, current_mate)
    
    # Reset pregnancy
    is_pregnant = false
    birth_timer = 0.0
    last_birth_time = Time.get_ticks_msec() / 1000.0
    current_mate = null
```

### Changes in Main.gd:
```gdscript
func _spawn_baby(clan_name: String, spawn_pos: Vector2, mother: NPCBase, father: NPCBase) -> void:
    var npc: Node = NPC_SCENE.instantiate()
    if not npc:
        return
    
    # Generate random name for baby
    var npc_name: String = NamingUtils.generate_caveman_name()
    
    # Set properties
    npc.set("npc_name", npc_name)
    npc.set("npc_type", "baby")
    npc.set("clan_name", clan_name)
    npc.set("age", 0)
    
    # Set sprite
    var sprite: Sprite2D = npc.get_node_or_null("Sprite")
    if sprite:
        var texture: Texture2D = load("res://assets/sprites/baby.png") as Texture2D
        if texture:
            sprite.texture = texture
            sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    
    npcs_container.add_child(npc)
    npc.global_position = spawn_pos
    npc.visible = true
    
    print("✓ Spawned Baby: %s at %s (clan: %s)" % [npc_name, spawn_pos, clan_name])
```

### Testing:
- Test baby spawning when birth timer completes
- Verify baby spawns at land claim center
- Check baby has correct properties (type, clan, age, sprite)

---

## Step 11: Implement Baby Wander State (Within Land Claim)

**Purpose**: Babies wander within land claim boundaries only

### Files to Create/Modify:
- `scripts/npc/states/baby_wander_state.gd` (or modify existing `wander_state.gd`)

### Implementation:
```gdscript
extends "res://scripts/npc/states/wander_state.gd"

func update(delta: float) -> void:
    # Only for babies
    if npc.get("npc_type") != "baby":
        return super.update(delta)
    
    # Babies can only wander within land claim
    var clan_name = npc.get("clan_name")
    if not clan_name or clan_name == "":
        return
    
    var land_claim = _get_land_claim(clan_name)
    if not land_claim:
        return
    
    # Wander within land claim radius
    # TODO: Implement bounded wandering within radius
    super.update(delta)

func _get_land_claim(clan_name: String) -> Node2D:
    # Same helper as in reproduction component
    var claims = get_tree().get_nodes_in_group("land_claims")
    for claim in claims:
        if claim.get("clan_name") == clan_name:
            return claim
    return null
```

### Testing:
- Verify babies wander within land claim
- Test babies don't leave land claim boundaries

---

## Step 12: Implement Baby Inventory System

**Purpose**: Babies have 2 slots for food from land claim

### Files to Modify:
- `scripts/npc/npc_base.gd`
- `scripts/main.gd` (for inventory UI)

### Changes:
1. In `npc_base.gd` `_ready()` for babies:
   ```gdscript
   if npc_type == "baby":
       # Create inventory with 2 slots
       inventory = InventoryData.new(2, true, 999999)  # 2 slots, stacking enabled
   ```

2. Baby food consumption (add to baby update loop):
   ```gdscript
   if npc_type == "baby" and inventory:
       # Check if hungry, consume food from inventory
       # TODO: Implement hunger system
   ```

### Testing:
- Verify babies have 2-slot inventory
- Test inventory UI shows when baby clicked

---

## Step 13: Implement Baby Growth System

**Purpose**: Babies grow to clansmen after 1 minute (testing) or at 13 years (normal)

### Files to Modify:
- `scripts/npc/npc_base.gd`
- `scripts/npc/components/baby_growth_component.gd` (create new)

### Create Baby Growth Component:
```gdscript
extends Node
class_name BabyGrowthComponent

var npc: NPCBase = null
var growth_timer: float = 0.0
var growth_time: float = 60.0  # 1 minute for testing

func initialize(npc_ref: NPCBase) -> void:
    npc = npc_ref

func update(delta: float) -> void:
    if not npc or npc.get("npc_type") != "baby":
        return
    
    growth_timer += delta
    if growth_timer >= growth_time:
        _grow_to_clansman()

func _grow_to_clansman() -> void:
    # Change NPC type to clansman
    npc.set("npc_type", "clansman")
    npc.set("age", 13)
    
    # Change sprite to caveman sprite
    var sprite: Sprite2D = npc.get_node_or_null("Sprite")
    if sprite:
        var texture: Texture2D = load("res://assets/sprites/male1.png") as Texture2D
        if texture:
            sprite.texture = texture
    
    # Remove baby growth component
    queue_free()
    
    print("✓ Baby %s grew to clansman" % npc.npc_name)
```

### Integration:
- Attach to baby NPCs in `npc_base.gd`
- Update in `_process()` or update loop

### Testing:
- Verify babies grow after 1 minute
- Check clansman properties (type, age, sprite)

---

## Step 14: Update UI for Baby Information

**Purpose**: Show baby name and age when clicked

### Files to Modify:
- `scripts/npc/npc_debug_ui.gd` or inventory UI

### Changes:
- Add age display to NPC UI
- Show baby-specific info (name, age, growth timer)

### Testing:
- Verify baby info shows when clicked
- Test name and age display

---

## Step 15: Test Complete System

**Purpose**: Verify all systems work together

### Test Cases:
1. **Women Spawning**: Verify women spawn with random names
2. **Reproduction Start**: Woman in land claim with player/NPC caveman starts pregnancy
3. **Birth Timer**: Pregnancy timer counts down (90 seconds)
4. **Baby Spawning**: Baby spawns at land claim center when timer completes
5. **Baby Behavior**: Baby wanders within land claim
6. **Baby Growth**: Baby grows to clansman after 1 minute
7. **Clansman Behavior**: Clansman behaves like NPC cavemen (gather, herd, deposit)
8. **Birth Cooldown**: 20 second cooldown between births
9. **Land Claim Destroyed**: Pregnant woman loses pregnancy when land claim destroyed

### Integration Testing:
- Test with player as mate
- Test with NPC cavemen as mates
- Test multiple women reproducing
- Test baby pool capacity limits (when implemented)

---

## Implementation Order Summary

1. ✅ Add random names to women (Step 1)
2. ✅ Create reproduction config (Step 2)
3. ✅ Create baby pool manager (Step 3)
4. ✅ Create reproduction component (Step 4)
5. ✅ Attach component to women (Step 5)
6. ✅ Create reproduction state (Step 6)
7. ✅ Register state in FSM (Step 7)
8. ✅ Implement land claim detection (Step 8)
9. ✅ Implement mate detection (Step 9)
10. ✅ Implement baby spawning (Step 10)
11. ✅ Implement baby wander state (Step 11)
12. ✅ Implement baby inventory (Step 12)
13. ✅ Implement baby growth (Step 13)
14. ✅ Update UI for babies (Step 14)
15. ✅ Test complete system (Step 15)

---

## Notes

- **Living Huts**: Baby pool capacity starts at 3 (base). Living Hut integration comes later.
- **Trait Inheritance**: Disabled until traits system is implemented.
- **Player Reproduction**: Player can reproduce as clan leader.
- **Wild NPCs**: Cannot reproduce (must be in clan).
- **Modularity**: System designed to support sheep/goat reproduction later.

---

## Future Enhancements (Not in Phase 2)

- Living Hut capacity integration
- Trait inheritance (50/50 hybridization)
- Variable birth timer based on traits
- Baby growth based on age (13 years) instead of timer
- Manual baby promotion (currently automatic only)
