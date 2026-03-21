# Implementation Checklist

Based on logicguide.md answers and analysis, here's what needs to be implemented.

## Critical Fixes Needed

### 1. Minimum Distance Between Land Claims (200px)
**Status:** ❌ Not implemented  
**Priority:** High  
**Location:** `scripts/npc/states/build_state.gd`  
**Implementation:**
- Check distance to all existing land claims before placing
- Minimum 200px distance required
- If too close, search for new spot

### 2. Area of Agro (AOA) Within AOP
**Status:** ❌ Not implemented  
**Priority:** High  
**Location:** `scripts/npc/npc_base.gd`  
**Implementation:**
- Add AOA trait/value to cavemen (start with "medium")
- Trigger agro when other cavemen enter AOA (not just land claim)
- AOA should be smaller than AOP (e.g., 300-500px vs 1000px+ AOP)

### 3. Deposit Trigger with Herd Size
**Status:** ❌ Not implemented  
**Priority:** High  
**Location:** `scripts/npc/states/deposit_state.gd`  
**Implementation:**
- Check herd size in `can_enter()` or `get_priority()`
- If 2+ wild NPCs in herd, trigger deposit even if inventory < 80%
- Combine with existing 80% threshold (either condition triggers deposit)

## Performance Optimizations

### 4. Priority Caching
**Status:** ❌ Not implemented  
**Priority:** High  
**Location:** `scripts/npc/fsm.gd`  
**Benefits:** Massive performance boost - avoids recalculating priorities every frame  
**Implementation:** See `logicguide_analysis.md` for details

### 5. Distance-Based Update Scaling
**Status:** ❌ Not implemented  
**Priority:** Medium  
**Location:** `scripts/npc/npc_base.gd`  
**Benefits:** Scales performance with NPC count  
**Implementation:** Update frequency based on distance to player (see `logicguide_analysis.md`)

### 6. State Memory with Validation
**Status:** ❌ Not implemented  
**Priority:** Medium  
**Location:** `scripts/npc/npc_base.gd` and state files  
**Benefits:** Efficiency + realism - NPCs remember targets and resume after interruption  
**Implementation:** See `logicguide_analysis.md` for details

## System Implementations

### 7. NodeCache
**Status:** ❌ File exists but is empty  
**Priority:** Medium  
**Location:** `scripts/npc/node_cache.gd`  
**Implementation:**
- Cache resources, land claims, NPCs
- Update every 1-2 seconds or on-demand
- Provide fast spatial queries

### 8. State Completion Definitions
**Status:** ⚠️ Partially implemented  
**Priority:** Medium  
**Location:** Individual state files  
**Implementation:**
- Define clear "complete" conditions for each state
- States should exit when done (not linger)
- See `logicguide_analysis.md` for recommendations

### 9. Resource Empty State Handling
**Status:** ⚠️ Partially implemented  
**Priority:** Low  
**Location:** `scripts/npc/states/gather_state.gd`  
**Implementation:**
- Properly ignore "empty" resource nodes
- Don't mark as harvested (they respawn)
- NPCs should skip empty nodes in detection

## Future Systems (Low Priority)

### 10. Fight or Flight (FoF) System
**Status:** 🔮 Not started  
**Priority:** Low (Future)  
**Location:** New system  
**Notes:** Foundation for combat system, trait-based decisions

### 11. Tool Requirements
**Status:** 🔮 Not started  
**Priority:** Low (Future)  
**Location:** `scripts/npc/states/gather_state.gd`  
**Notes:** When crafting system is added

---

## Testing Checklist

After implementing fixes, test:
- [ ] 4/4 cavemen place land claims with 200px minimum distance
- [ ] Agro triggers in AOA (not just land claim)
- [ ] Deposit triggers with 2+ wild NPCs in herd
- [ ] Performance: 100+ NPCs at 60 FPS
- [ ] State memory: NPCs resume previous activities after interruption
- [ ] Priority caching: No performance degradation with many NPCs

---

*Generated from logicguide.md analysis - Dec 31, 2025*

