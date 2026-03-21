# Code Refactoring & Cleanup Plan

## Overview
This document outlines the plan to clean up redundant loggers, remove unused code, and consolidate the logging system.

---

## Current State Analysis

### Loggers Found (6 total)

#### 1. **Logger** (`scripts/logger.gd`)
- **Status**: ✅ ACTIVE - Used in 24 files
- **Purpose**: Basic file logging with batching
- **Autoload**: Yes
- **Usage**: General purpose logging across the codebase
- **Issues**: Overlaps with ConsoleLogger functionality

#### 2. **ConsoleLogger** (`scripts/console_logger.gd`)
- **Status**: ✅ ACTIVE - Used in 2 files
- **Purpose**: Console output capture with file backup
- **Autoload**: Yes
- **Usage**: Minimal (only 2 files)
- **Issues**: Redundant with Logger, duplicates functionality

#### 3. **ErrorHandler** (`scripts/error_handler.gd`)
- **Status**: ❌ UNUSED - 0 references
- **Purpose**: Error catching/handling
- **Autoload**: Yes
- **Issues**: Not actually catching errors, minimal implementation

#### 4. **ErrorCapture** (`scripts/error_capture.gd`)
- **Status**: ❌ UNUSED - 0 references, NOT in autoload
- **Purpose**: Godot error system hook
- **Autoload**: No
- **Issues**: Never integrated, completely unused

#### 5. **DragDropLogger** (`scripts/inventory/drag_drop_logger.gd`)
- **Status**: ✅ ACTIVE - Used in 5 files
- **Purpose**: Drag-and-drop specific logging
- **Autoload**: Yes
- **Usage**: Inventory/drag system
- **Issues**: Could be merged into unified logger with categories

#### 6. **MinigameLogger** (`scripts/npc/minigame_logger.gd`)
- **Status**: ✅ ACTIVE - Used in 16 files
- **Purpose**: NPC/minigame state logging
- **Autoload**: Yes
- **Usage**: NPC states, FSM, herding, etc.
- **Issues**: Could be merged into unified logger with categories

### Other Findings
- **393 print() statements** across 45 files (many could use logging)
- **DebugConfig** exists but only partially integrated
- **ErrorHandler** attempts to hook errors but doesn't actually work

---

## Refactoring Strategy

### Phase 1: Create Unified Logger System

**Goal**: Consolidate all logging into a single, flexible system with categories.

**New Structure**:
```
scripts/logging/
  ├── unified_logger.gd          # Main logger singleton
  ├── log_categories.gd           # Category definitions
  └── log_config.gd              # Configuration (merge with debug_config)
```

**Features**:
- Single autoload singleton: `UnifiedLogger`
- Category-based logging (NPC, Inventory, DragDrop, System, Error, etc.)
- Configurable output: Console, File, or both
- Performance-optimized (batching, early exits)
- Log levels: DEBUG, INFO, WARNING, ERROR
- Integration with DebugConfig

### Phase 2: Remove Redundant Loggers

**Files to Remove**:
1. `scripts/logger.gd` → Migrate to UnifiedLogger
2. `scripts/console_logger.gd` → Migrate to UnifiedLogger
3. `scripts/error_handler.gd` → Remove (unused)
4. `scripts/error_capture.gd` → Remove (unused)

**Files to Refactor**:
1. `scripts/inventory/drag_drop_logger.gd` → Convert to UnifiedLogger categories
2. `scripts/npc/minigame_logger.gd` → Convert to UnifiedLogger categories

### Phase 3: Update All References

**Migration Path**:
- Replace `Logger.write_log()` → `UnifiedLogger.log()`
- Replace `ConsoleLogger.write_log()` → `UnifiedLogger.log()`
- Replace `MinigameLogger.log_event()` → `UnifiedLogger.log_npc()`
- Replace `DragDropLogger.log_event()` → `UnifiedLogger.log_inventory()`
- Update all 24 files using Logger
- Update all 16 files using MinigameLogger
- Update all 5 files using DragDropLogger

### Phase 4: Clean Up Unused Code

**Areas to Check**:
- Commented-out code blocks
- Unused functions/methods
- Dead code paths
- Unused variables
- Old test/debug code

**Tools**:
- Search for `# TODO`, `# FIXME`, `# DEPRECATED`
- Search for commented-out function definitions
- Check for unused exports/variables

### Phase 5: Consolidate Debug Config

**Merge**:
- `scripts/config/debug_config.gd` → Enhanced with logging controls
- Remove duplicate configuration logic
- Single source of truth for all debug settings

---

## Implementation Plan

### Step 1: Create Unified Logger (Priority: High)
- [ ] Create `scripts/logging/unified_logger.gd`
- [ ] Create `scripts/logging/log_categories.gd`
- [ ] Add to autoload as `UnifiedLogger`
- [ ] Implement category-based logging
- [ ] Add log level filtering
- [ ] Add file/console output toggles
- [ ] Integrate with DebugConfig

### Step 2: Migrate Existing Loggers (Priority: High)
- [ ] Create migration helper functions (backward compatibility)
- [ ] Update Logger references → UnifiedLogger
- [ ] Update ConsoleLogger references → UnifiedLogger
- [ ] Update MinigameLogger references → UnifiedLogger
- [ ] Update DragDropLogger references → UnifiedLogger

### Step 3: Remove Unused Code (Priority: Medium)
- [ ] Remove `scripts/error_handler.gd` from autoload
- [ ] Delete `scripts/error_handler.gd`
- [ ] Delete `scripts/error_capture.gd`
- [ ] Remove old logger files after migration complete
- [ ] Clean up commented code

### Step 4: Update project.godot (Priority: High)
- [ ] Remove old logger autoloads
- [ ] Add UnifiedLogger autoload
- [ ] Keep DebugConfig, NPCConfig, CompetitionTracker, NPCActivityTracker

### Step 5: Testing & Validation (Priority: High)
- [ ] Test all logging still works
- [ ] Verify no broken references
- [ ] Test performance (should be same or better)
- [ ] Test debug mode toggles

---

## Migration Examples

### Before (Logger):
```gdscript
var logger = get_node("/root/Logger")
logger.write_log("Something happened")
logger.log_error("Error occurred")
```

### After (UnifiedLogger):
```gdscript
UnifiedLogger.log("Something happened", UnifiedLogger.Category.SYSTEM)
UnifiedLogger.log_error("Error occurred", UnifiedLogger.Category.SYSTEM)
```

### Before (MinigameLogger):
```gdscript
MinigameLogger.log_state_change("NPC1", "idle", "gather", "hungry")
```

### After (UnifiedLogger):
```gdscript
UnifiedLogger.log_npc("State changed: idle → gather (reason: hungry)", {
    "npc": "NPC1",
    "from": "idle",
    "to": "gather"
})
```

### Before (DragDropLogger):
```gdscript
DragDropLogger.log_drag_start(slot, item_data)
```

### After (UnifiedLogger):
```gdscript
UnifiedLogger.log_inventory("Drag started", {
    "slot": slot_index,
    "item": item_name
})
```

---

## Benefits

1. **Single Source of Truth**: One logger, one way to log
2. **Better Performance**: Unified batching, early exits
3. **Easier Debugging**: All logs in one place, categorized
4. **Cleaner Codebase**: Remove 4 redundant files
5. **Better Configuration**: Centralized debug/logging controls
6. **Easier Maintenance**: One system to update/fix

---

## Risks & Mitigation

**Risk**: Breaking existing logging during migration
- **Mitigation**: Create backward-compatibility wrappers during transition

**Risk**: Performance regression
- **Mitigation**: Keep batching, early exits, same optimization patterns

**Risk**: Missing edge cases
- **Mitigation**: Test thoroughly, keep old loggers until migration verified

---

## Timeline Estimate

- **Step 1** (Create Unified Logger): 2-3 hours
- **Step 2** (Migrate References): 3-4 hours
- **Step 3** (Remove Unused): 1 hour
- **Step 4** (Update Config): 30 minutes
- **Step 5** (Testing): 1-2 hours

**Total**: ~8-10 hours of focused work

---

## Next Steps

1. Review this plan
2. Approve approach
3. Start with Step 1 (Create Unified Logger)
4. Iterate through phases
5. Test thoroughly before removing old code

---

## Notes

- Keep old loggers in place until migration is 100% complete
- Use feature flags in DebugConfig to toggle new vs old system
- Consider keeping a "legacy mode" for a few commits as safety net
- Document new logging API in code comments
