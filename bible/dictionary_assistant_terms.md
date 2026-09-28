# Assistant terms

**Written:** Sep 2026. **Sources:** design docs only. No code was used.

These are names added in write-ups to run or describe the sim: flags, buffers, indexes, and state names. They are not the words you use for the fantasy. If a row here is actually your word, say so and it moves to `dictionary_your_terms.md`.

---

## Orders, as data

| Term | Definition | Doc |
|------|------------|-----|
| **Ordered follow** | Clansmen locked into a party command. Not broken by a normal herd steal. Cleared by **Break** or the leash. | `game_dictionary.md` |
| **follow_is_ordered** | On/off flag while that ordered follow is active (drag, menu, horn, or an AI raid party). Blocks cross-clan herd steal. | `bible.md` terminology |
| **command_context** | The packet on those clansmen: mode (follow / guard / attack), tuning, who commands them, when it was issued. | `game_dictionary.md` |
| **formation_slots** | Saved stand-points around the leader (you or an NPC) so followers steer to a slot. | `game_dictionary.md` |
| **RTS_CONFIG** | The settings sheet for rally radius, horn cooldown, leash, catch-up speed, and stance numbers. | `game_dictionary.md` |
| **returning_from_break** | Priority bump so clansmen walk home after Break instead of wandering off. | `game_dictionary.md` |

---

## Sensing and threat, as components

| Term | Definition | Doc |
|------|------------|-----|
| **PerceptionArea** | The sensor circle that implements your **AOP**. Tracks who is in range and feeds agro, combat, and herd detection. | `bible.md` |
| **EnemiesInClaim** | A sensor on the land claim that notices intruders for defenders. | `game_dictionary.md` |
| **HerdInfluenceArea** | A sensor on each herdable. Overlap builds influence until they attach or a contest resolves. | `game_dictionary.md` |
| **Fighter activity** | A count of who is **in** combat, defend, agro, or raid right now. Not “how many clansmen exist.” | `bible.md` |

---

## Hunt and food math

| Term | Definition | Doc |
|------|------------|-----|
| **Area of Hunt (AoH)** | A ring on the **flag** wider than the claim. Counts prey (deer, mammoth) for the AI hunt. Herdables in that ring are still a **search** job, not a hunt. Campfire has no AoH. | `bible.md`, `nomad.md` |
| **Hunt intent** | AI clans: the brain says “hunt” when that ring has prey and food math allows. Player clans: the brain does not run the hunt. You use Peace / Agro / Hunt. | `bible.md` |
| **WildRole.PREY** | Label for deer and mammoth: hunt targets that flee. Not herdables. | `bible.md` |
| **food_days_buffer** | Pantry in **days**: stored food calories divided by what the clan eats per day. Gates work, hunt, raid, breeding, and off-screen sim. | `bible.md`, `earlygame_vision.md` |
| **calories_days_buffer** | The same number as `food_days_buffer`. Older name kept in sync. | `bible.md` |
| **defend / search / gather pressure** | Three weights (0–1, forced to sum cleanly) that bias quotas and job urgency, beside the older economic weights. | `bible.md` |
| **Economic weights** | `food_weight`, `resource_weight`, `build_weight`, `herd_weight`. Bias which jobs people pick. | `game_dictionary.md` |
| **Survival mode** | An AI clan with fewer than 2 fighters skips hunt and raid. Gather and herd only. | `bible.md` |

---

## Work pipeline

| Term | Definition | Doc |
|------|------------|-----|
| **Task** | One step: move, gather, or drop. | `game_dictionary.md` |
| **Job** | An ordered list of tasks. | `game_dictionary.md` |
| **Gather job** | Move to a resource, gather, move back to the claim, auto-deposit near the center. | `game_dictionary.md` |
| **Deposit threshold** | About **40%** of slots full (at least 3) means “go deposit.” Keep one food stack. Send the rest to the claim. | `game_dictionary.md` |
| **Occupation** | A building slot assignment (woman to a hut, animal to a farm): request the slot, then confirm arrival. | `game_dictionary.md` |
| **SimulationManager** | The clock that ticks on a fixed step (docs say about 120 seconds) for personal calories and farm/dairy pools. | `bible.md` |

---

## Map bookkeeping

| Term | Definition | Doc |
|------|------------|-----|
| **ResourceIndex** | A grid (about 200 px cells) so a claim can ask “what resources are near me?” | `game_dictionary.md` |
| **HostileEntityIndex** | Fast lookup for hostile NPCs. | `game_dictionary.md` |
| **ClaimBuildingIndex** | Which buildings sit inside which claim. | `game_dictionary.md` |
| **pseudo-biome** | A **code-only** label per chunk (`forest`, `plains`, `rocky`, `swamp`) used for off-screen gathering math. Not the biomes the player sees. Those are not shipped under this name. | `bible.md` |
| **MutationStore** | Where the world remembers what players changed after the seed (chopped, built, claimed, clan deaths). | `clan_founding_and_exile.md`, `earlygame.md` |
| **Chunk exhausted** | A chunk has recorded enough clan deaths (default 3) that **seeded** clans stop there. Founder clans are a separate question. | `clan_founding_and_exile.md` |

---

## Look, and names that are explicitly not used

| Term | Definition | Doc |
|------|------------|-----|
| **Appearance (2D)** | How an NPC looks: sprite sheets. Not a morph body, not Mixamo. | `game_dictionary.md` |
| **DragonBones** | **Not used.** Removed. 2D is sprite sheets only. | `bible.md` |
| **Stockpile** | Claim, building, or campfire list: one row per item type, stacked, empty rows hidden except one drop row. | `game_dictionary.md` |
| **Hotbar** | Keys 1–8 gear. Keys 9 and 0 food you eat on the key. | `game_dictionary.md` |

---

## Old lines this file does not revive

- **Genome** as live body math. Your term list records it as retired.
- Campfire “has no ClanBrain.” Current nomad doc says it does, in nomadic mode.
- “All cavemen are wild.” Current dictionary says wild caveman means **no claim**, and that path is planned.
