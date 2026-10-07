# Dormancy

**Status:** Design lock, October 2026. The record tick, roster, away trips, and abstract hunt and raid already run. Saved places, staggered wake, lone field bodies, milk on the sleep tick, and the player camp staying awake are the next build. They are part of this design, not optional flavor.

**This document is the dormancy canon.** Older notes in [settlement_sim.md](settlement_sim.md) describe the same split (actors may sleep, the settlement may not) but their status lines are stale. Clan jobs and quotas stay in [ai_clan_brain.md](ai_clan_brain.md) and `bible.md` §XVI. This file is why the camp sleeps, what must keep happening, and what the player character is allowed to see.

---

## Why we do it

The world is one continuous plane. AI camps sit at real coordinates. The player character can walk to any of them. A late game has many camps, each with women, men, babies, and animals.

A body is expensive. It is a `CharacterBody2D` with an FSM, steering, perception, and sprites. A camp of thirty people is thirty of those, every frame. Ten camps in memory is hundreds. They still cost time when they are off the screen, because the scene tree is still stepping them. Chunks load around the player character only. A clansman walking does not load the world. If every AI man were a body, the game would either load the whole map or move people through chunks that are not there.

Dormancy exists so the map can hold many living camps without simulating every step. The camp remains. The bodies do not, until someone is close enough to see them.

Multiplayer makes the same rule stricter. The server cannot run full pawn physics for every clan near every peer. Interest is the union of player positions. Camps outside that interest stay on the record. The local player's own camp is the exception, below.

## The goal

An AI clan that the player character is not looking at must still eat, gather, give birth, grow children, hunt, raid, and work its buildings. When the player character arrives, the camp must look like that life already happened. It must not look like everyone was stored on the totem and released at once.

The player character should be able to meet one of that clan's men in the wilderness, follow him toward the claim, and then see a village that is already arranged: defenders on the circle, women at the huts and the oven, gatherers out in the ring, animals by the farm. Nothing in that picture is allowed to require a second simulation of the same food, the same birth, or the same raid.

The owning player's camp does not use this picture. His people stay awake for the whole session so he never sees his own clan pop into existence. That cost is accepted. If a huge player roster later hurts the frame, the same record can be applied to camps no player is standing in. It is not applied to his camp in this design.

## The rule

> Actors may sleep. The settlement may not.

- An **actor** is a walking node. Physics, FSM, pathfinding, combat, sprites.
- The **settlement** is the clan: the roster, the pantry, the buildings, pregnancies, and parties.
- The **record** is the settlement while it is unseen. It is the truth. A body is a view of one row on that record.

When the view is gone, the record keeps the clock. When the view comes back, it is drawn from the record. The view must not invent a second history.

## Who sleeps

| Camp | While unseen | While the player character is there |
|------|----------------|--------------------------------------|
| AI land claim or campfire | Record. No bodies, except a field man whose point is already inside a loaded chunk. | Village bodies at their saved places. Parties you can see become real. |
| The owning player's camp | Does not sleep. `set_dormant(true)` is never called. | Same men, still awake. Sleep math does not also run, or the pantry would fill twice. |

Player clans do not auto-hunt and do not auto-raid. The brain does not score those for `player_owned`. The player character orders his men. AI clans do both, on the record when unseen and as real parties when seen.

A campfire that is marching (nomad relocation) pauses the record. Relocation is the campfire's own march, not a ClanBrain eval.

## How the record works

The land claim or campfire node stays in the world at its coordinates. It owns the pantry and the ClanBrain. The brain holds a roster of members. Each living person has an id, type, hunger, pregnancy or growth timer, alive flag, and a place.

Going to sleep:

1. Copy the live people onto the roster, including timers.
2. Remember building slots (oven, rack, hut, farm, dairy) on the claim so later ticks do not search the tree for nodes that have unloaded.
3. Remember owned sheep and goats. They are not person types. They are a short list: type and a place beside the farm or dairy.
4. A man already out on a gather, hunt, or raid stays **away**. He is not copied back onto the totem.

The slow tick then runs. Default interval is the settlement tick, on the order of thirty seconds, not every frame. A few seconds of leftover time carry into the next slice. The tick walks the roster once. It does not pathfind and it does not load chunks.

What that tick already does:

- Drain hunger and feed the asleep members from the pantry. Food is berries, bread, meat, grain, milk, and the other edibles, in that feed order.
- Gather from the chunk pools in the home ring (the claim chunk and the eight around it). Pools deplete and regen. Edible goods come before wood and stone when the camp is thin. Men marked away, and chunks they are already working, are skipped so the same patch is not gathered twice.
- Hunt wildlife from the pool when meat is low, and slaughter an owned animal only as a last resort when the camp is starving.
- Age babies, advance pregnancies, and start new ones when the rules allow. Births are written onto the roster. A new baby is placed with the mother, not on the totem.
- Cook meat at a campfire, bake bread when the camp has an oven, grain, and wood, and dry hides when it has a rack.
- Advance an unseen hunt or raid along a travel time. No bodies.

What the next build adds on that same tick, still as math:

- One role and one point per person (the places below).
- Milk. If the camp has a living woman and at least one owned goat, add one milk per goat per `milk_craft_time` (45 seconds) into the pantry, and stop when the stack is full. Feeding already drinks milk. No cheese and no butter in this pass. Goats are not simulated one by one.

The gather rate is the whole home workforce, including men who are only *shown* as defenders. Places are where people stand. They do not shrink the pantry. The exception is a man who currently has a body: the ledger skips him, because his real delivery is the one that counts. When the body is gone, he is home and the ledger counts him again.

Under two fighters the camp is in survival. No hunt, no raid, no defender posts. If there is no woman, that one man is the searcher.

## Places

Places are how a sleeping camp remembers a pose. They are not a second FSM.

Written on each slice, from the roster, using the same ClanBrain gates:

- **Defenders.** About one fighter in four, on fixed angles around the claim circle at about 0.9 times the radius. Quota is 0 under two fighters. Quota is 0 under 10 stone, 10 wood, and 10 food unless the alert is already INTRUDER or higher. INTRUDER can add posts above the one-in-four baseline. RAID posts every fighter. With three or fewer fighters, a defender may also be the searcher and leave the circle. With four or more, he stays. `next_job` must not send him to gather, hunt, or the next chunk.
- **Women.** At the oven, the drying rack, or a hut. Babies with the mother.
- **Gatherers.** In the gather ring, about one chunk out from the claim. Some of those points sit on the way back in, so the camp looks mid-delivery.
- **Searchers.** Outside the claim, out to the herd range (about 2000 pixels), and only up to the searcher quota. A raid, or skirmish alert and above, clears that quota.
- **Hunters.** Out to the hunt range, and only while a hunt party is actually out. Prey is deer and mammoth. Sheep, goats, and women are never hunt targets.
- **Raiders.** On the line toward the enemy claim while the raid is unresolved. They are not given a home post.
- **Sheep and goats.** Beside the farm or the dairy, or loose near the claim if those buildings were never there.

Dead members are not placed and are not spawned. A man who dies does not leave a chunk stamp behind.

## What the player character sees

Chunks stream around the player character. Load radius is 2 chunks. A chunk is 2048 pixels. The village itself appears when the player character is inside the sim-wake radius, 1200 pixels from the claim, or when a hostile is already inside the claim.

Before that, the wilderness is not required to be empty.

If a gatherer, searcher, or hunter has a saved point inside a chunk that is already loaded, that one man gets a body. The claim stays on the record. The village does not wake. While the body exists, the player character can follow him. He walks with the real job system, and only inside loaded chunks. He does not load chunks by walking.

When that chunk unloads, the body is removed. He is marked home. Anything still in his pack is deposited once. A second deposit of the same load adds nothing. There is no trail to find by turning around. The next time the player character looks, that man is at his home place, or out on a later job.

The village, when it appears, does not appear as one pile:

- A few bodies per frame, at the saved points, then they keep the job those points mean.
- Defenders are already on the circle.
- Women and babies are already at the buildings.
- Gatherers are already out in the ring.
- Animals are already by the farm or dairy.
- Anyone still marked away is not in that spawn. They appear with their party, or they are already home if the trip finished.

Standing on the totem and running at the player character is a failure of this picture. It is what happens today, because every saved position is still the claim center and every living member is spawned in one frame. The places and the staggered spawn are how that failure is removed. They do not add bodies while the camp is asleep.

## Defense when someone arrives

Defenders are a job. They are not idle, and they are not "whoever is in combat."

- One intruder, including the player character alone: the men already posted step in. Gatherers, women, and searchers keep their jobs. Women are never called to the gate.
- Two or more intruders: that is the raid alert. Every fighter drops his job and defends. Outgoing raids cancel.
- Alert steps down on its own: RAID, then SKIRMISH, then INTRUDER, then NONE, about ten seconds a step.
- A posted defender leaves the circle to fight someone inside the claim, then returns to his angle. With four or more fighters he does not leave to gather or to hunt.

The live gate today calls every fighter within twice the claim radius. That call is changed so that, below RAID, only the posted men are called. The quota math for RAID is unchanged.

## Hunts and raids

AI clans can call both. The player clan cannot call them for him.

**Unseen.** The party is a token on the brain: who went, which way, and how much travel time is left. Defenders are not taken. A hunt needs enough men left at home and low meat. It removes one deer from the chunk's wildlife pool and adds that carcass's meat and hide to the pantry once. A raid needs a neighbor, a motive, and at least two men who are not the home guard. It moves a bounded amount of food from the other pantry once, then the men are on the way home. No pathfinding. No bodies. No chunks loaded for the trip.

**Seen.** If the party's point lies in a loaded chunk, those men become bodies and the token is marked materialized. A hunt that is still outbound gets a real deer or mammoth in that chunk, and the pool meat is not added. A raid wakes the other camp's posted defenders and they fight, and the food transfer does not also run. A party already on the way home is spawned walking in. The goods are already in the pantry. They are not paid again.

If the player character never comes near the party, it finishes on the record and the men are home on a later slice.

## Reproduction and work

Reproduction is on the record, not on the bodies. Women on the roster get pregnant, carry, and give birth while the camp is asleep. Babies grow on the roster and become clansmen. The player character who stays away and comes back finds more children than he left, if the camp had food and a father under the usual rules. He does not find them spawned on the totem. They are with the mother.

Work is the same idea. The oven, the rack, and the cook fire advance on timers and inventory counts. A woman does not need a body to turn grain and wood into bread while the camp is unseen. When she has a body, she stands at that building because the place says so. The tick does not also craft a second loaf for the same interval in which a live woman already crafted one. Camps that are fully on the record have no live crafter, so the tick is the only craft.

Eating is per living member on the roster: hunger drains, then the pantry pays the meal. The camp can grow itself hungry. That is intentional. A camp that only gathers and never feeds would outpace the player character for free.

## What this is not allowed to do

These are the performance and correctness locks. A feature that breaks one of them is not a dormancy feature.

- No FSM, steering, physics, or perception for members who are only on the record.
- No chunk load caused by an AI man. Chunks load around player characters.
- No body spawned every second to "check" the camp. Field bodies spawn because a loaded chunk already contains their point. Village bodies spawn because the player character is inside sim-wake, or a hostile is inside the claim.
- No second gather, second deposit, second hunt carcass, or second raid theft for the same trip. The first resolution sticks. The next call adds nothing.
- No full-camp spawn on the totem.
- No sleep math on the owning player's camp while his men are awake.
- The record tick does not end just because the claim enters the wide interest radius (about 2400 pixels). Interest may mark the claim. The village still waits for sim-wake or an intruder. One field body does not wake the rest.

## What is true in the code today

Already true:

- Unwatched AI camps run `dormant_update` and the settlement slice: hunger, gather, hunt, slaughter, birth, growth, bread, leather, cooking.
- Away trips skip home gather. An unwatched trip deposits once.
- Record hunts and raids advance on travel time and set `materialized` when a player is watching, which blocks a second payout.
- Wake uses `member.position` when spawning. Babies copy the mother.

Not true yet, and that is why a visited camp still looks dead until the frame it explodes:

- Positions saved at sleep are the claim center, so everyone appears on the totem.
- The whole living roster spawns in one call.
- The village gate calls every nearby fighter, and a raid alert sets the defender quota to all of them.
- A man out in a loaded chunk does not get a lone body. The wilderness between camps is empty.
- Milk is eaten if it is in the pantry and is never produced by the tick.
- A player-owned claim can still be set dormant when the player character walks far enough.

The build that follows this document closes that list. It does not replace the tick.

## Files

- Record and tick: `scripts/ai/clan_brain.gd` (`set_dormant`, `dormant_update`, `_tick_settlement_clock`, `materialize_clan_for_combat`)
- Slice: `scripts/systems/settlement_sim_tick.gd`
- Gather pools: `scripts/systems/abstract_gather.gd`
- Parties: `scripts/systems/settlement_party.gd`
- Roster and spawn pose: `scripts/systems/settlement_roster.gd`
- When a claim is inside wide interest: `scripts/systems/world_interest_manager.gd`
- When the village may spawn: `WorldGenConfig.sim_wake_player_radius_px` (1200)
- Gate: `scripts/land_claim.gd` `village_gate`
- Jobs the player character's own men use while awake: `scripts/systems/territory_job_service.gd` `next_job`
