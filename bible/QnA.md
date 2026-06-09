# Questions & Answers - Unanswered Questions

This document consolidates all unanswered questions from the guide documents. Questions that have been answered (marked with `!!` or `✅`) remain in their original documents.

---

## Eating & Inventory

1. ✅ **How many food items should NPCs keep in inventory before stopping collection?** (e.g., keep 2-3 berries, then stop collecting more unless inventory has space)
   - **Answer:** NPCs keep **1 food item** in inventory before stopping collection.
   - *Source: `npcguideog.md` Section 11 - Remaining Questions*

2. ✅ **What triggers a "village task" to gather a specific item?** Is this assigned by the player or automatically by the AI?
   - **Answer:** Both - there will be a village menu screen where the player can direct their clan, and the AI will also be responsible to develop a net positive with their clan.
   - *Source: `npcguideog.md` Section 11 - Remaining Questions*

---

## NPC Posture & Behavior

3. ✅ **How is NPC posture (peace, friendly, cautious, hostile) determined?** Is it based on stats, clan relationships, or player actions?
   - **Answer:** It is determined by their traits and panic level. Panic level goes down over time and is configurable in `npc_config.gd`.
   - *Source: `npcguideog.md` Section 11 - Remaining Questions*

4. ✅ **What should each posture do when seeing another NPC?** (e.g., peace=ignore, friendly=approach, cautious=keep distance, hostile=attack/flee?)
   - **Answer:** Cautious = stand ground in defense, friendly and peace = ignore. Animations will come later (sprite sheets). Trade system: NPCs will hold icon of item they want to give up in their hands (trade graphic to be created).
   - *Source: `npcguideog.md` Section 11 - Remaining Questions*

---

## Character Screen

5. ✅ **What is the "character screen"?** Is this a UI panel that opens when clicking an NPC, or something else?
   - **Answer:** Yes - it's like the inventory menu screen but the player presses the **C button**. The player can also walk up to an NPC and press **C button** to see both the player character menu screen and the NPC character menu screen.
   - *Source: `npcguideog.md` Section 11 - Remaining Questions*

---

## Herding Behavior

6. ✅ **What triggers "herding mode"?** Is it a toggle, or automatic when right-clicking?
   - **Answer:** Player can herd NPCs. NPC cavemen can herd other NPCs to their clan's landclaim. Clansmen and cavemen cannot be herded. Player cannot be herded by an NPC. 8 NPCs can be in a herd at a time.
   - *Source: `npcguideog.md` Section 11 - Remaining Questions*

7. ✅ **What is the follow distance for herded NPCs?** Should it vary by NPC type?
   - **Answer:** 3 to 5 tiles while following, spread out a little when not moving.
   - *Source: `npcguideog.md` Section 11 - Remaining Questions*

8. ✅ **Can herded NPCs break away from following?** (e.g., if they get too hungry or see danger)
   - **Answer:** Yes - if their panic level gets high they will go into hide mode behind resource sprites.
   - *Source: `npcguideog.md` Section 11 - Remaining Questions*

---

## State Machine & Priority Logic

9. ✅ **Should there be cooldowns between state transitions to prevent rapid switching?**
   - **Answer:** No - state transitions should be immediate. There should be a flow that is formulaic and tailored for efficiency.
   - *Source: `logicguide.md` State Transitions - Transition Rules*

10. ✅ **When should NPCs enter `idle` state?**
    - **Answer:** It's a fallback to quickly reset an NPC for now, later it will be longer and it will be animated to give the game a little more life.
    - *Source: `logicguide.md` State Persistence - Idle State*

---

## Land Claim System

11. ✅ **Why do cavemen start with a land claim item?** Should they craft it instead?
    - **Answer:** For testing purposes they will spawn with a landclaim.
    - *Source: `logicguide.md` Land Claim Requirements*

12. ✅ **What happens if a land claim is destroyed?**
    - **Answer:** When the landclaim gets destroyed in a raid, all the NPCs (woman and animals) become wild again, and can be herded back to the landclaim of the raiders.
    - *Source: `logicguide.md` Land Claim Ownership*

---

## Herding & Wild NPCs

13. ✅ **Should there be other requirements for herding?** (e.g., minimum resources, tools)
    - **Answer:** Maybe later, not yet. Maybe we add leather ties and ropes be equipped to herd.
    - *Source: `logicguide.md` Herding Prerequisites*

---

## Agro & Combat

14. ✅ **Should they agro at predators or other threats?**
    - **Answer:** Yes in the future.
    - *Source: `logicguide.md` Agro Triggers*

15. ✅ **What happens when two cavemen fight?**
    - **Answer:** The invader will have a chance to fight or flight (FoF), the values of which they choose is from their traits. For testing we will keep it in flight mode.
    - *Source: `logicguide.md` Combat Resolution*

16. ✅ **Should there be consequences for losing a fight?**
    - **Answer:** There will be injuries, and dead NPCs (in the future).
    - *Source: `logicguide.md` Combat Resolution*

---

## Resource Gathering

17. ✅ **What resources are needed to place a land claim?**
    - **Answer:** Not defined at this time, none are required at this time.
    - *Source: `logicguide.md` Gathering Prerequisites*

---

## Priority System

18. ✅ **What happens when two states have the same priority?**
    - **Answer:** Do which is closest first then recheck. There should be tie-breakers (e.g., distance, urgency). Some states should always win regardless of priority - priority should dictate unless there is a reason to do something else.
    - *Source: `logicguide.md` Priority Conflicts*

19. ✅ **How often should priorities be recalculated?**
    - **Answer:** Regularly. Should priorities be cached or calculated each frame? Let's do what's best for performance.
    - *Source: `logicguide.md` Priority Evaluation*

20. ✅ **Should priorities consider future needs, or just current state?**
    - **Answer:** Maybe not (just current state).
    - *Source: `logicguide.md` Priority Evaluation*

---

## State Transitions

21. ✅ **What should interrupt what?**
    - **Answer:** Agro should interrupt everything. Deposit should interrupt gather. Build is disabled at this time.
    - *Source: `logicguide.md` Interruptions*

22. ✅ **Should `build` interrupt `gather`?**
    - **Answer:** I don't know yet (build state is disabled at this time).
    - *Source: `logicguide.md` Interruptions*

23. **When is a state "complete"?**
    - *Source: `logicguide.md` State Completion*
    - *Note: User requested pros/cons analysis*

24. **Should NPCs automatically transition when a state completes?**
    - *Source: `logicguide.md` State Completion*
    - *Note: User requested pros/cons analysis*

25. **Should NPCs remember what they were doing before interruption?**
    - *Source: `logicguide.md` State Completion*
    - *Note: User requested pros/cons analysis*

26. **Should NPCs remember targets/resources between states?**
    - *Source: `logicguide.md` State Persistence*
    - *Note: User requested pros/cons analysis*

27. **Should NPCs resume previous activities after interruption?**
    - *Source: `logicguide.md` State Persistence*
    - *Note: User requested pros/cons analysis*

28. **How long should state memory persist?**
    - *Source: `logicguide.md` State Persistence*
    - *Note: User requested pros/cons analysis*

---

## Edge Cases & Conflicts

29. **What happens at map boundaries?**
    - *Source: `logicguide.md` Boundary Cases*
    - *Note: User requested pros/cons analysis*

30. **How many NPCs should the game support?**
    - *Source: `logicguide.md` Performance*
    - *Note: User requested pros/cons analysis*

31. **Should there be limits on active states/calculations?**
    - *Source: `logicguide.md` Performance*
    - *Note: User requested pros/cons analysis*

32. **Should NPCs be culled when far from player?**
    - *Source: `logicguide.md` Performance*
    - *Note: User requested pros/cons analysis*

---

## System Integration

33. **What level of logging is needed for debugging?**
    - *Source: `logicguide.md` System Integration - Logging*
    - *Note: Currently implemented, but question remains about level/scope*
    as much as needed to fix the problem

---

## Current Implementation Questions (New)

### Area of Perception (AOP) & Detection

34. **What is the intended Area of Perception (AOP) for cavemen NPCs?**
    - *Document (`caveman_logic.md`) states: "Caveman NPCs have 500px Area of Perception"*
    - *Current implementation: Base perception (10.0) × multiplier (200.0) = 2000px*
    - *Question: Should AOP be 500px or 2000px? If 500px, should we:*
      - *A) Lower the multiplier to 50.0 (affects all NPCs), or*
      - *B) Lower base perception to 2.5 for cavemen only (requires caveman-specific stat)?*
    - *Source: Recent testing discussion*

35. ✅ **How should herd_wildnpc priority be ensured when wild NPCs are in the caveman's AOP?**
    - **Answer:** herd_wildnpc priority is now **12.0** (base), can boost to **13.5** when defending from threats. This is higher than gather's max priority of **11.5**, ensuring herd_wildnpc always interrupts gather when wild NPCs are detected. This is sufficient - no additional checks needed.
    - *Source: Implementation fix (priority system ensures herd_wildnpc > gather)*

36. ✅ **Should cavemen always herd wild NPCs in their AOP before gathering resources?**
    - **Answer:** Yes - this is now enforced by the priority system. herd_wildnpc priority (12.0-13.5) is higher than gather's max priority (11.5), so herding wild NPCs always takes precedence over gathering resources. This ensures NPCs compete effectively for wild NPCs.
    - *Source: Implementation fix (priority system ensures herd_wildnpc > gather)*

---

## Notes

- ✅ = Questions that have been answered and can be removed from this document (they remain in their original documents)
- Questions marked with "User requested pros/cons analysis" have been noted in `logicguide_analysis.md` but may need further clarification or decisions.
- Some questions may have been answered implicitly in implementation but not explicitly documented.
- Questions about future features (e.g., tools, storage buildings) are marked as low priority in implementation checklist.

---

*This document should be updated as questions are answered. Last updated: After consolidation and answering from guides (Dec 31, 2025)*

