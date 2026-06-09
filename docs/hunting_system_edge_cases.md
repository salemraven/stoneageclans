# Hunting System Edge Cases & Bulletproof Solutions

**Purpose:** Identify every edge case before implementing the hunting system, with concrete solutions.

---

## 1. Deer Behavior Edge Cases

### 1.1 Cornered Deer (Map Edge / Surrounded)
**Problem:** Deer can't flee—map boundary or hunters on all sides.

**Solution:** 
- **MVP:** Deer stops and cowers (speed = 0, plays "scared" animation if available).
- **No fight-back** for deer (unlike boar/mammoth which could be aggressive).
- Deer becomes easy target when cornered—this is intentional (reward for good hunting).

### 1.2 Multiple Threats
**Problem:** Two players or parties approach—who does deer flee from?

**Solution:**
- Flee from **centroid of all threats within perception range** (already in plan: `flee_prey_state.gd`).
- Formula: `escape_vector = normalize(deer_pos - avg(threat_positions))`.
- This naturally handles multiple threats and creates interesting dynamics.

### 1.3 Deer Runs Into Water/Obstacles
**Problem:** Deer flees into impassable terrain.

**Solution:**
- Use existing `steering_agent` avoidance logic—deer treats water/cliffs same as land claim boundaries.
- If stuck >2s: deer picks a random perpendicular direction (same as `_wander()` stuck recovery in `steering_agent.gd`).

### 1.4 Infinite Flee (No Stamina MVP)
**Problem:** With no stamina system, deer could flee forever.

**Solution:**
- **Flee duration cap:** 8-10 seconds of sustained fleeing, then deer slows to 60% speed for 3s ("winded").
- After winded period: returns to full flee speed if threats still present.
- This is **simpler than full stamina** but prevents infinite chases.
- Config: `NPCConfig.deer_flee_duration_sec = 10.0`, `deer_winded_speed_mult = 0.6`, `deer_winded_duration_sec = 3.0`.

### 1.5 Deer at Spawn Location
**Problem:** Deer spawns inside a hunter ambush.

**Solution:**
- SpawnManager already has minimum distance checks for NPCs.
- Add deer to same spawn rules: no spawn within 300px of player or clansmen.
- If deer somehow spawns in ambush, it immediately enters ALERT state (grace period for flee).

---

## 2. Formation Edge Cases

### 2.1 Arc Repositioning Frequency
**Problem:** Player moves/turns—does Arc constantly reposition or only on command?

**Solution:**
- **Smooth follow** with throttle: Arc slots recalculate every 0.3s (same as `party_state.target_update_interval`).
- When leader stops: slots freeze in place (same as existing FOLLOW/GUARD/ATTACK behavior).
- No "snap" repositioning—uses existing slot transition logic.

### 2.2 Mode Switch Mid-Hunt
**Problem:** Player in HUNT/STALK, switches to PEACE—what happens?

**Solution:**
- **Immediate stance change:** Stalking clansmen switch to new stance's behavior.
- If new mode is PEACE: clansmen stop stalking, return to normal FOLLOW distance.
- If new mode is AGRO: clansmen become combat-ready (existing `agro_meter` logic).
- **No "finish approach" delay**—responsive UI is more important than realism.

### 2.3 Clansman Dies Mid-Hunt
**Problem:** Formation has 4 slots, clansman #2 dies—what happens?

**Solution:**
- Existing `FormationUtils.compute_formation_slots()` recalculates on next tick.
- Remaining 3 clansmen get new slots automatically.
- Dead clansman's slot simply disappears—no "hole" in formation.
- Works same as raid party death handling.

### 2.4 Arc at Map Edge
**Problem:** Player backs into corner—Arc ahead has no valid positions.

**Solution:**
- Clamp slot positions to valid world bounds (same as wander target clamping in `steering_agent.gd`).
- Slots compress if needed—Arc becomes tighter near edges.
- Use existing `_get_random_wander_point()` boundary logic as reference.

---

## 3. Cover/Hiding Edge Cases

### 3.1 No Cover Nearby
**Problem:** Clansman ordered to HIDE, but no trees/bushes in range.

**Solution:**
- **Option A (recommended):** Clansman crouches in open (partial concealment).
  - Sets `is_hidden = true` but with reduced effectiveness (50% detection reduction vs 90% behind cover).
  - Shows visual feedback: crouching sprite + "exposed" icon.
- If player doesn't like position, they can manually reposition the clansman.

### 3.2 Multiple Clansmen Same Bush
**Problem:** Two clansmen pick the same small bush.

**Solution:**
- **Allow stacking** with diminishing returns:
  - First clansman: 90% detection reduction.
  - Second clansman behind same cover: 70% detection reduction.
  - Third+: 50% detection reduction.
- This naturally encourages spreading out without hard blocking.
- `CoverQuery.find_nearest_cover()` returns covers sorted by distance—different clansmen may naturally pick different covers.

### 3.3 Cover Destroyed While Hiding
**Problem:** Tree chopped down while clansman is hiding behind it.

**Solution:**
- `GatherableResource` destruction emits signal or calls `_exit_tree()`.
- `hide_state.gd` polls cover validity each tick (cheap: just `is_instance_valid(cover_node)`).
- If cover gone: clansman auto-finds next nearest cover, or falls back to "exposed crouch."
- Transitions smoothly—no jarring state change.

### 3.4 Hide Position Calculation (Peace Mode)
**Problem:** In PEACE mode with HIDE stance, there's no threat—which direction to hide?

**Solution:**
- Hide **facing away from player** (player is the reference point).
- Clansman positions on opposite side of cover from player's facing direction.
- If player turns, clansman doesn't reposition (too fidgety)—only repositions if player moves significantly (>50px).

---

## 4. Combat Edge Cases

### 4.1 Friendly Fire
**Problem:** Thrown spear hits your own clansman in Arc formation.

**Solution:**
- **No friendly fire** from same clan (standard RTS convention).
- `CombatAllyCheck.is_ally()` already exists—use it for projectile hit detection.
- Projectiles pass through allies without damage.
- Simple, predictable, player-friendly.

### 4.2 Missed Spear Landing
**Problem:** Thrown spear misses deer—what happens?

**Solution:**
- **Spear lands as pickup item** at impact point.
- Uses existing `GroundItem` system (same as dropped resources).
- Despawn timer: 60s (configurable).
- Players/clansmen can pick up missed spears.
- Server-authoritative: server determines impact point, spawns ground item, replicates to clients.

### 4.3 Ambush Trigger Radius
**Problem:** What distance triggers the ambush attack?

**Solution:**
- Reuse existing `DetectionArea` radius from `PerceptionArea` (default 300px).
- Ambush triggers when prey/enemy enters **any** hidden clansman's detection radius.
- One trigger = all hidden clansmen attack (coordinated ambush).
- Alternative trigger: player attacks first (simpler for MVP).

### 4.4 Spear Throw While Moving
**Problem:** Clansman throws spear while running—accuracy? Animation?

**Solution:**
- **Stop to throw:** Clansman stops movement for 0.3s windup, throws, then can move.
- Same pattern as existing melee attack windup in `combat_component.gd`.
- Movement locked during throw animation.
- Server validates throw timing—no "running throw" exploits.

---

## 5. Sound Detection Edge Cases

### 5.1 Hidden Clansman Makes Noise
**Problem:** Player is hidden, but a non-hidden clansman nearby makes footstep noise.

**Solution:**
- Sound sources are **per-NPC**, not per-party.
- Hidden clansman has `is_stalking = true` → half sound volume.
- Non-hidden clansman at normal volume → can spook prey.
- **Player responsibility** to ensure all hunters are stalking/hidden.
- UI feedback: show "stealth broken" icon when any party member is loud.

### 5.2 Sound Through Walls/Obstacles
**Problem:** Does sound pass through terrain?

**Solution:**
- **MVP: Sound ignores obstacles** (no line-of-sight check).
- Simpler to implement, easier to predict.
- Future polish: could add LOS check using raycasts, but not for MVP.

### 5.3 Multiple Simultaneous Sounds
**Problem:** Attack swing + footsteps + horn—which does deer react to?

**Solution:**
- React to **loudest audible sound** (highest `volume / distance` ratio above threshold).
- Formula: `heard = max(volume / distance for all sounds) > prey.sound_threshold`.
- If multiple sounds above threshold, flee direction = centroid of all sound sources.

### 5.4 Sound Throttling Edge Cases
**Problem:** Footstep throttle (0.3s) means running past deer might not trigger flee.

**Solution:**
- Running has **higher volume** (60 vs 30 for walking) → larger effective range.
- Sprint/running emits sound every 0.15s (faster than walk 0.3s).
- Deer polls for sounds every 0.5s → catches running sounds reliably.
- Net effect: running is louder and more frequent—harder to sneak.

---

## 6. Multiplayer Edge Cases

### 6.1 Two Players Hunt Same Deer
**Problem:** Player A and Player B both hunting same deer—who gets credit?

**Solution:**
- **Deer becomes corpse** (same as other NPCs)—loot spawns at corpse.
- First to pick up loot gets it—no automatic "killing blow = ownership."
- **Emergent conflict:** Two rival clans in close proximity during a hunt will likely trigger existing agro system → combat.
- This creates natural territorial disputes over hunting grounds—good for gameplay.

### 6.2 Scare-Steal / Hunt Conflict
**Problem:** Player A's noisy approach scares deer into Player B's ambush.

**Solution:**
- **Allow it**—this is emergent gameplay.
- Likely outcome: clans get agro from proximity → fight over the kill.
- Creates interesting dynamics:
  - Coordinated hunts between allied clans.
  - Territorial disputes between rivals.
  - Risk/reward of hunting near enemy territory.
- No special prevention—existing agro/combat systems handle it naturally.

### 6.3 Latency: Deer Position Desync
**Problem:** Deer position differs between server and client during chase.

**Solution:**
- **Server-authoritative deer position** (same as all NPCs).
- Client prediction for visual smoothness, server reconciliation.
- Hit detection on server only—no "I hit it but it didn't count."
- Existing NPC replication handles this—deer uses same pattern.

### 6.4 Party Leader Disconnects
**Problem:** Hunt party leader disconnects mid-hunt.

**Solution:**
- Same as raid party disconnect (already implemented in `clan_brain.gd`).
- Followers lose leader reference → `party_state` exits → FSM evaluates → wander.
- Hunt auto-cancels if leader was the player.
- If NPC leader: ClanBrain picks new leader or cancels hunt.

---

## 7. AI Clan Hunting Edge Cases

### 7.1 Hunt Trigger Conditions
**Problem:** What makes an AI clan decide to hunt?

**Solution:**
- **Food pressure:** `food_days_buffer < 3.0` triggers hunt consideration.
- **Huntable available:** `territory.get_huntables_in_aoh().size() > 0`. Only wild types with `WildRole.PREY` in `NPCConfig` (e.g. **deer**, **mammoth**). Sheep/goat/woman are herdables and are **not** huntables for ClanBrain hunts.
- **Cooldown:** 45s between hunts (existing `HUNT_COOLDOWN_SEC`).
- **Fighters available:** `cavemen.size() >= 2` and not all on defense.
- Already implemented in `_evaluate_hunt_opportunity()`.

### 7.2 Who Goes, Who Stays
**Problem:** Does entire clan hunt, or subset?

**Solution:**
- **Subset:** `hunter_quota = clamp(available, MIN_HUNT_SIZE, MAX_HUNT_SIZE)`.
- Available = fighters not on defense duty.
- Defenders stay at claim (existing quota system).
- Women/animals never join hunts.

### 7.3 AI Hunt Fails
**Problem:** AI hunt party can't catch deer—what happens?

**Solution:**
- **Timeout:** Hunt phase lasts max 60s.
- If deer escapes (out of AoH or dead from other cause): hunt phase → RETURNING.
- Hunters return home, cooldown starts, try again later.
- No infinite chase—same as raid timeout logic.

---

## 8. Deer Herd Behavior Edge Cases

### 8.1 Solo vs Herd Spawning
**Problem:** Do deer spawn alone or in groups?

**Solution:**
- **Small herds:** Spawn 2-4 deer together (50% chance) or solo (50% chance).
- SpawnManager already supports group spawning (used for sheep/goats).
- Herd spawns at random offset within 100px of each other.

### 8.2 Panic Spread
**Problem:** One deer flees—do nearby deer also flee?

**Solution:**
- **Yes, with delay:** If deer A flees, deer within 150px check alert.
- Delay: 0.3-0.5s random per deer (not instant cascade).
- Creates realistic herd flight behavior.
- Implementation: `SoundDetection.emit_sound()` with "deer_panic" type, high volume.

---

## 9. Feedback & UI Edge Cases

### 9.1 Hidden Indicator
**Problem:** How does player know clansman is successfully hidden?

**Solution:**
- **Visual:** Clansman crouches (use existing crouch sprite if available, or tint overlay).
- **Icon:** Small "eye with slash" icon above head when hidden.
- **Transparency:** 50% alpha when hidden (distinguishes from non-hidden).
- These are visual-only—don't affect gameplay logic.

### 9.2 Deer Alert States
**Problem:** Should player see deer's state transitions?

**Solution:**
- **Grazing:** Normal animation, no icon.
- **Alert:** Ears perk up animation + "!" icon for 0.5s freeze.
- **Fleeing:** Running animation, no icon (obvious from movement).
- Alert icon helps player time their ambush.

### 9.3 Post-Kill Auto-Loot
**Problem:** Does killer auto-collect meat/hide?

**Solution:**
- **No auto-loot** for MVP—requires manual pickup (player or clansman).
- Keeps consistency with existing resource pickup behavior.
- Future: could add "auto-loot party" option, but not MVP.

---

## 10. Time of Day Edge Cases

### 10.1 Night Hunting
**Problem:** Different detection ranges at night?

**Solution:**
- **MVP: Same as day**—no time-of-day modifiers.
- Future polish: reduce visual detection range by 30% at night, increase sound importance.
- Keep MVP simple—time-of-day is separate feature.

---

## 11. State Transition Edge Cases

### 11.1 Hunt → Combat → Hunt Return
**Problem:** Clansman in hunt, enters combat with enemy, combat ends—where does he go?

**Solution:**
- Existing pattern from `hunt_state.gd`:
  - Set `hunt_after_combat` meta on NPC.
  - `combat_state` checks this on exit.
  - Returns to hunt if brain still hunting.
- Same pattern already works for raid.

### 11.2 Party State vs Hunt State Priority
**Problem:** Follower in party_state, brain starts hunt—conflict?

**Solution:**
- `hunt_state.can_enter()` already checks `follow_is_ordered`.
- If clansman is in player party (ordered follow), they don't join AI hunt.
- Player must release them first (Break command) to join clan hunts.
- Clear hierarchy: player orders > clan brain suggestions.

---

## 12. Performance Edge Cases

### 12.1 Many Deer + Many Hunters
**Problem:** 20 deer + 30 hunters = expensive calculations.

**Solution:**
- **Sound detection throttling:** Already in plan (0.3s footsteps, 0.5s prey polling).
- **Spatial queries:** Use `PerceptionArea` (already optimized with Area2D).
- **Range culling:** Only process prey within 500px of sound source.
- **Group node limit:** Max 10-15 deer per spawn area.
- Same performance patterns as existing mammoth/sheep systems.

### 12.2 Cover Query Performance
**Problem:** Finding nearest cover across hundreds of resources.

**Solution:**
- Use `ResourceIndex` spatial queries (already exists).
- Filter by resource type (WOOD, BERRIES, WHEAT, FIBER).
- Return nearest N (limit 5) within max_dist (300px).
- Cache result for 0.5s—cover doesn't change that fast.

---

## Summary: Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Cornered deer | Cower (no fight) | Reward skilled hunting |
| Flee duration | 10s cap + winded period | Prevent infinite chase without full stamina |
| Friendly fire | None (pass through allies) | Standard RTS, player-friendly |
| Missed spear | Drops as pickup | Resource preservation, realism |
| No cover | Crouch in open (reduced effectiveness) | Always allow HIDE stance |
| Sound through walls | Yes (MVP) | Simplicity over realism |
| Deer death | Becomes corpse, loot drops | Same as other NPCs |
| Hunt conflict | Existing agro handles it | Emergent territorial disputes |
| Night hunting | Same as day (MVP) | Separate feature |
| Panic spread | Yes, with delay | Realistic herd behavior |
| Auto-loot | No (manual pickup) | Consistency with existing systems |
| Crouch art | Required for HIDE stance | Player will create sprites |

---

## Implementation Order (Safe Path)

1. **Deer NPC + Flee** — Standalone, no dependencies
2. **Sound Detection** — Isolated system, throttled
3. **HUNT mode + Arc formation** — Additive to existing formations
4. **STALK stance** — Variant of FOLLOW
5. **Cover Query + HIDE/AMBUSH** — Most complex, last

Each step is testable independently before adding complexity.
