# Guide Changelog

This document tracks updates to guides based on implementation changes and design decisions.

## February 6, 2026

### New Guides

#### Battle Royale Playtest Readiness
- **Created:** `BATTLE_ROYALE_READINESS.md` – Checklist for battle royale combat playtest (January 2026)
- **Covers:** Land claims disabled for BR; 6 cavemen spawn (200–300px radius, max agro, axe); UI (5-slot inventory, 10-slot hotbar, 80% deposit trigger); corpse system (50px range, corpsecm.png, character info, drag-and-drop looting); combat (30 HP, 10 dmg, 3 hits); world interactions blocked when inventory open
- **Not yet:** Corpse decomposition timers (60s to bones, 60s despawn)

#### Animation Test Guide
- **Created:** `ANIMATION_TEST_GUIDE.md` – How to use `AnimationTest.tscn` to test combat sprite sheet (`clubss.png`) in isolation
- **Covers:** Load sprite, frame count/timing (windup, hit display, recovery), play/pause, full attack sequence

#### Buildings (Phase 2 current state)
- **Created:** `Buildings.md` – Single source for current building implementation
- **Covers:** Placement (50px buffer, 128×128, Building.tscn for all types); Land Claim (400px, not in build menu); build menu (Living Hut, Supply Hut, Shrine, Dairy Farm, Oven); Oven production (1 Wood + 1 Grain → 1 Bread, 15s, fire button); disabled: Living Hut baby pool, woman occupation
- **References:** `phase2/build_menu.md` for full flow; design vs implemented clearly separated

### Updated Guides (Jan–Feb 2026)

- **phase2.md** – Last updated Jan 27, 2026; recent updates section
- **phase2/build_menu.md** – Jan 2026 (50px placement, Building.tscn, baby pool/woman occupation disabled)
- **phase2/PHASE2_AUDIT.md** – Date 2026-01-27
- **phase2/STATE_BLOCKING_RULES.md**, **phase2/STATE_PRIORITIES.md** – Last updated 2026-01-27
- **future implementations/ai_clan_brain.md** – Last updated 2026-02-03

### Implementation Status (unchanged from Dec 2025)

- **To Be Implemented ⏳** – Minimum distance between land claims (200px), AOA, FoF, resource scarcity, personality traits, deposit trigger with herd size (2+), priority caching, distance-based update scaling, state memory, NodeCache (see `IMPLEMENTATION_CHECKLIST.md`)

---

## December 31, 2025

### Major Changes

#### Agro System Overhaul
- **Changed:** Cavemen NO LONGER agro at wild NPCs (women, sheep, goats)
- **Changed:** Agro ONLY triggers when another caveman or player enters your land claim area
- **Changed:** Agro defends BOTH land claim territory AND herd (herded wild NPCs)
- **Changed:** Agro priority increased to 15.0 (was 10.0) - highest priority
- **Removed:** Lost wild NPC recovery agro trigger (cavemen don't fight over wild NPCs directly)
- **Clarified:** Land claim defense protects herd because herd is inside/going to land claim
- **Future:** Area of Agro (AOA) will allow herd defense outside land claim
- **Updated Guides:** `AgroGuide.md`, `NPCGUIDE.md`, `Priority.md`

#### Fight or Flight (FoF) & Area of Agro (AOA) System Design
- **Created:** `FightOrFlightGuide.md` - Complete system design document
- **Purpose:** Dynamic, personality-driven competition for herds and resources
- **Features:**
  - AOA: Personal defensive zone that triggers FoF rolls
  - FoF: Decision system based on personality traits and situation
  - Resource competition: As resources deplete, NPCs become more competitive
  - Herd competition: Dynamic herd stealing based on personality
- **Integration:** Works with existing agro system, enhances herding and gathering

#### Herding System Updates
- **Changed:** Cavemen MUST have a land claim placed before they can herd
- **Changed:** Wild NPCs IGNORE cavemen without land claims (they don't appear in detection)
- **Changed:** Herd is maintained during agro (doesn't break when defending)
- **Updated Guides:** `HerdGuide.md`, `NPCGUIDE.md`

#### Land Claim Requirements
- **Clarified:** Cavemen spawn with land claim item, must place it (after 15-second cooldown) before gathering or herding
- **Clarified:** Minimum distance between land claims: 200px (to be implemented)
- **Updated Guides:** `NPCGUIDE.md`, `logicguide.md`

#### Terminology Updates
- **Changed:** `lost_woman` → `lost_wildnpc` (to reflect broader applicability to all wild NPC types)
- **Updated Guides:** `AgroGuide.md`

### Design Decisions Documented

#### From logicguide.md Answers:
- NPCs play the game like players - competitive and autonomous
- Systems-first approach for performance and modability
- Realistic, immersive details (RimWorld/Dwarf Fortress style story generation)
- Priority-based decision making with dynamic values
- One task at a time, but herding and depositing happen simultaneously
- State persistence: Smart validation memory (store + validate before resume)
- Map boundaries: Infinite with gentle repulsion fallback + pathfinding

#### Future Systems Planned:
- Area of Agro (AOA) within AOP for proactive defense
- Fight or Flight (FoF) system for combat decisions
- Resource competition as resources deplete
- Dynamic herd competition based on personality
- Tool requirements (when crafting system added)
- Storage buildings (when building system expanded)

### Performance Recommendations

Added to `logicguide_analysis.md`:
- Priority caching (critical for performance)
- Distance-based update scaling (for scalability)
- State memory with validation (efficiency + realism)

### Guides Updated

1. ✅ `AgroGuide.md` - Complete rewrite with new agro system + AOA/FoF references
2. ✅ `HerdGuide.md` - Updated with land claim requirement
3. ✅ `NPCGUIDE.md` - Updated caveman behaviors and rules
4. ✅ `Priority.md` - Updated agro priority to 15.0
5. ✅ `logicguide.md` - Added user answers and cross-references
6. ✅ `logicguide_analysis.md` - Created with pros/cons analysis
7. ✅ `IMPLEMENTATION_CHECKLIST.md` - Created with action items
8. ✅ `FightOrFlightGuide.md` - **NEW** Complete AOA + FoF system design

### Implementation Status

#### Completed ✅
- Agro system: Only triggers on land claim intrusion
- Herding: Requires land claim
- Wild NPCs: Ignore cavemen without land claims

#### To Be Implemented ⏳
- Minimum distance between land claims (200px)
- Area of Agro (AOA) system
- Fight or Flight (FoF) system
- Resource scarcity calculation
- Personality trait system
- Deposit trigger with herd size (2+ wild NPCs)
- Priority caching
- Distance-based update scaling
- State memory with validation
- NodeCache implementation

---

*Last updated: February 6, 2026*
