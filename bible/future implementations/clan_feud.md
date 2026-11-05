# Clan feud (future)

**Status:** Decisions from the director on **2026-11-04**, including the grill that day. Not built. The raid-pressure rules in [raid.md](../raid.md) still decide when a march is allowed. This file is the score between two clans, and how it shows on the clan screen.
**Locks:** [director_locks_2026_10.md](../director_locks_2026_10.md) §11.

This is the nemesis idea, at clan scale. The famous version is the orc captains in *Shadow of Mordor* and *Shadow of War*: a named enemy remembers the last fight, climbs rank when he beats you, and throws that history at you later. Here the **clan** is that character. One man does not level up, come back from the dead, or remember “I killed you.”

The rival is a **clan**. Each clan brain keeps one feud line per neighbor clan. People still have names, so the screen can say who killed whom. The brain acts on the score.

**Not this system:** a captain skill tree, forts, mind control, or a man who rises from the dead. Death stays final. A son does not reopen a blood raid that was already answered.

---

## Director picks (grill, 2026-11-04)

| Question | Decision |
|----------|----------|
| Unseen blood raid | Two named fighters die, once. A seeded roll among fighters. Not women. Not babies. |
| Who-killed-whom list | Last **3** pairs. Older names drop. Counts stay. |
| Several open bloods | March on the worst score among neighbors they can beat. One death still answers the oldest blood. |
| Screen label | One stamped rival. Other neighbors are a plain list. |
| After blood is answered | They are shamed. We are emboldened. Shame can drop their clan morale under 30, which already stops a raid. Size and length are measured in play. |
| High seats | A kill does not promote anyone. |
| The killer | Keeps one fact: the rival clan, and the victim’s name. A newer rival kill replaces it. In the player’s clan that fact is also a life beat. |
| Faces | Not decided. |

---

## The line

One line per neighbor:

- their clan
- how many of ours they have killed, and how many of theirs we have killed
- the last **3** death pairs (victim name, killer name). Older pairs drop off. The counts stay.
- whether a blood or a theft is still open

Both brains write the same fight. Your clan stores the line too, even though your brain does not start raids. AI clans get this list only. It is not a diary of their camp. Names still stay after the person dies and after the raid pressure clears.

**The score** is their kills of us minus our kills of them. The worst open score is the **stamped rival**. One stamp. Other neighbors stay on a plain list under it.

---

## What the brain does with it

- A raid or a blood feud starts only when the odds look good. Opportunity, distance, and whether they can win are the heavy weights. A rival adds weight and can tip a close call. A rival cannot send the clan on a suicide march. If the stamped rival fails that gate, the grudge stays open and they do not march on that rival. The line for “good odds” is measured in play. The old raid score table stays retired. Details: [director_locks_2026_10.md](../director_locks_2026_10.md) §11.
- If several bloods are open, they march on the **worst open score among neighbors they can beat**. One returned death still answers the **oldest** open blood. Those two orders are allowed to differ.
- A food raid that finishes while both camps are asleep still only moves a limited amount of food, once.
- A **blood** raid that finishes while both camps are asleep removes **two named fighters** from the defender’s roster, once. The two names are a seeded roll among that clan’s fighters. Not women. Not babies. The same seed always picks the same two. That matches the live blood goal. No bodies, no pathfinding, no second payout if you arrive later and the trip already resolved.
- If you walk into the raid while it is still traveling, it becomes a real fight, and the record does not also apply the two deaths or the food move.
- Your camp does not send itself. An AI march that reaches your awake camp is a real fight.

When a blood is answered, both clans feel it. Their clan morale drops and a shame debuff shows on their clan screen. Your clan morale rises and an emboldened buff shows on yours. The drop is allowed to push the loser under 30, which already stops a raid, so they stay home until morale recovers. How big the drop is, and how long it lasts, is measured in play, not guessed. The 60-second gap between raids stays.

A kill does not move anyone into a high seat. Seats stay on the clan’s law. The killer does get recognition. He keeps one fact: he killed someone from that rival clan, and that victim’s name. A newer rival kill replaces that fact. It does not grow into a diary. His raid-kill tally still goes up, the same tally every fighter already keeps. If he is in the player’s clan, that same fact is also a life beat.

---

## AI clan against AI clan

This runs while both camps are asleep. The brain already lives off-screen. The feud line is written on that same record. Two AI clans can change each other’s score and morale without the player watching. Two fighters can be gone from the roster. When the player arrives, the camp is already smaller or prouder. The fight is not played a second time.

---

## On the clan screen

The hierarchy screen ([clan_hierarchy.md](clan_hierarchy.md)) is where this is read. Under the seats, traits, morale, and buffs:

- the stamped rival at the top
- the other neighbor lines under it
- the last three names on the open line

---

## Still open

**Faces.** Not decided. The director has not chosen whether the stamped rival’s men wear the angry face, or whether faces stay on personal moodles only.
