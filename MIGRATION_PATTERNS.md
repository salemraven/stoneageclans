# MinigameLogger Migration Patterns

## Migration Complete ✅

All files have been migrated to UnifiedLogger. This doc is kept for reference when adding new logging.

**Migrated files:** fsm.gd, wander_state.gd, herd_wildnpc_state.gd, herd_state.gd, npc_base.gd, eat_state.gd, build_state.gd, agro_state.gd, steering_agent.gd, idle_state.gd, stats.gd, seek_state.gd.

## Migration Patterns

### Pattern 1: Get logger reference
```gdscript
# OLD:
var minigame_logger = get_node_or_null("/root/MinigameLogger")

# NEW:
# Remove - not needed, use UnifiedLogger directly
```

### Pattern 2: log_state_change
```gdscript
# OLD:
minigame_logger.log_state_change(npc_name, "idle", "gather", "hungry")

# NEW:
UnifiedLogger.log_npc("State changed: idle → gather (hungry)", {
    "npc": npc_name,
    "from": "idle",
    "to": "gather",
    "reason": "hungry"
})
```

### Pattern 3: log_can_enter_check
```gdscript
# OLD:
minigame_logger.log_can_enter_check(npc_name, "gather", false, "no_resources")

# NEW:
UnifiedLogger.log_npc("Can enter check: %s cannot enter gather (no_resources)" % npc_name, {
    "npc": npc_name,
    "state": "gather",
    "can_enter": false,
    "reason": "no_resources"
}, UnifiedLogger.Level.DEBUG)
```

### Pattern 4: log_action_start/complete/failure
```gdscript
# OLD:
minigame_logger.log_action_start(npc_name, "gather", "tree")
minigame_logger.log_action_complete(npc_name, "gather", true)
minigame_logger.log_action_failure(npc_name, "gather", "no_resources")

# NEW:
UnifiedLogger.log_npc("Action started: gather (target: tree)", {
    "npc": npc_name,
    "action": "gather",
    "target": "tree"
})
UnifiedLogger.log_npc("Action completed: gather (success)", {
    "npc": npc_name,
    "action": "gather",
    "success": true
})
UnifiedLogger.log_npc("Action failed: gather (no_resources)", {
    "npc": npc_name,
    "action": "gather",
    "reason": "no_resources"
})
```

### Pattern 5: log_land_claim_placed
```gdscript
# OLD:
minigame_logger.log_land_claim_placed(npc_name, clan_name, position)

# NEW:
UnifiedLogger.log_npc("Land claim placed: %s placed claim '%s' at %s" % [npc_name, clan_name, position], {
    "npc": npc_name,
    "clan": clan_name,
    "pos": "%.1f,%.1f" % [position.x, position.y]
})
```

### Pattern 6: log_caveman_agro
```gdscript
# OLD:
minigame_logger.log_caveman_agro(npc_name, "trigger", "target", agro_level)

# NEW:
UnifiedLogger.log_npc("Caveman agro triggered: %s (trigger: %s, target: %s, level: %.1f)" % [npc_name, trigger, target, agro_level], {
    "npc": npc_name,
    "trigger": trigger,
    "target": target,
    "agro_level": "%.1f" % agro_level
}, UnifiedLogger.Category.COMBAT)
```

### Pattern 7: log_inventory_operation
```gdscript
# OLD:
minigame_logger.log_inventory_operation(npc_name, "add", "WOOD", 5)

# NEW:
UnifiedLogger.log_npc("Inventory operation: add 5 WOOD", {
    "npc": npc_name,
    "operation": "add",
    "item": "WOOD",
    "amount": 5
})
```

### Pattern 8: log_player_interaction
```gdscript
# OLD:
minigame_logger.log_player_interaction("placed_land_claim", clan_name, {"pos": position})

# NEW:
UnifiedLogger.log_system("Player interaction: placed_land_claim", {
    "action": "placed_land_claim",
    "clan": clan_name,
    "pos": position
})
```

### Pattern 9: log_event with category
```gdscript
# OLD:
minigame_logger.log_event(minigame_logger.LogCategory.HERDING, "message", details)

# NEW:
UnifiedLogger.log_herding("message", details)
# Or use appropriate category method
```

## Notes
- Most can_enter_check calls should use DEBUG level
- State changes and actions use default INFO level
- Errors use ERROR level
- All NPC-related logging uses UnifiedLogger.log_npc()
- System/player interactions use UnifiedLogger.log_system()
