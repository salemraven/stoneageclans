# Stone Age Clans – Phase 1 Design Document

**Date**: January 16, 2026  
**Status**: Production Ready – Core Loop Locked  
**Scope**: 1 player-controlled caveman + 4 autonomous NPC cavemen on a small fixed test map.

## Phase 1 Core Loop

- Five cavemen spawn in the map.
- Each caveman must place a land claim to enable full behavior.
- Once a claim exists, cavemen target wild NPCs (women, sheep, goats) and resource nodes.
- Herding is the primary acquisition method.
- Herd ownership is contested by proximity.
- Claim areas are defended by push behavior.
- Items and NPCs are transported to the claim and deposited.
- The loop runs continuously with limited world resources.
- Total ownership of available NPCs/resources is the win condition (not yet enforced).

## Active Mechanics (Phase 1 Only)

### 1. Land Claim
- Caveman spawns with a land claim item in inventory.
- Post-spawn cooldown: 10 seconds.
- After cooldown, caveman enters `build_state` to place claim.
- Build requirement bypassed if inventory contains 8+ items.
- Minimum distance between claims: 800 px.
- Claim radius: 400 px.
- Deposit range: 300 px.
- Wild NPCs entering claim radius convert to clan ownership.

### 2. Gathering & Deposit
- Inventory size: 10 slots.
- Caveman gathers until inventory reaches 70% capacity (7/10 slots).
- Caveman maintains exactly 1 food item total.
- Upon reaching threshold:
  - Perform brief wander/reset (≤ 0.1 s).
  - Navigate to own claim.
  - Auto-deposit all inventory items except the single retained food item when within 300 px.
- After deposit, FSM reevaluates priorities (typically returning to herding).

### 3. Herding
- Herding enabled only after claim placement.
- Wild NPCs ignore cavemen without a claim.
- Herding disabled at ≥80% inventory capacity.
- Area of perception (AOP): 1500 px.
- Herd initiation distance: 150 px.
- When triggered, NPC enters follow state.
- Herd stealing:
  - Another caveman within 150 px can take control.
  - Steal effectiveness increases at ≤100 px.
- When a herded NPC enters the claim radius (400 px), ownership becomes permanent.

### 4. Agro (Push-Based Defense)
- Trigger condition: another caveman enters claim radius.
- Herd stealing alone does not trigger agro.
- Priority values:
  - 10.0: recover lost NPC
  - 15.0: standard claim defense
  - 17.0: defense against player-controlled caveman
- Action: move toward intruder and apply push force until intruder exits claim.
- Active herd remains attached during defense behavior.

## Caveman Priority Sequence (FSM – Highest Priority Evaluated Per Frame)

1. **Build Land Claim**
   - Priority: 25.0 if inventory ≥8 items
   - Priority: 9.5 otherwise
   - Condition: no claim exists

2. **Agro**
   - Priority: 10.0 (NPC recovery)
   - Priority: 15.0–17.0 (claim defense)
   - Condition: intruder detected in claim

3. **Herd Wild NPC**
   - Priority: 10.6–10.9
   - Condition: wild NPC detected within AOP

4. **Gather Resources**
   - Priority: 3.0
   - Condition: no viable herd targets

5. **Wander / Reset**
   - Duration: ≤ 0.1 s
   - Purpose: FSM reset, deposit travel, auto-deposit handling

## Phase 1 Game Flow Summary

1. Player and four NPC cavemen spawn.
2. After 10 seconds, each places a land claim (respecting spacing rules).
3. Cavemen continuously scan AOP.
4. Wild NPCs are herded when detected.
5. If no wild NPCs are available, cavemen gather resources.
6. At 70% inventory capacity, cavemen return to claim and deposit.
7. Intrusions into claim or herd proximity trigger push defense.
8. Loop repeats indefinitely.

This document defines the complete and final Phase 1 implementation scope.  
No additional systems, progression, or win conditions are included at this stage.
