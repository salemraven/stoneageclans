---
search:
  keywords: raid raiding motive
---

# Raid

**Status:** Draft (summary from bible; confirm wording when ready)

**Whose word:** Yours

## Definition

An **offensive clan action**: fighters leave home, march to a **neighbor’s** claim, complete one **goal** (food, captives, weaken them, etc.), then retreat. **NPC clans:** the ClanBrain sets **raid intent**; fighters **pull** into raid FSM states. **Player clans:** no auto-raids — you lead a hostile party (weapon out + ordered follow) or use the planned raid verbs on an enemy claim.

## What it is not

- Not a score bar anymore. NPC raids pick the **first true motive** in a fixed list (blood, theft, food, thin, restless), not a weighted “raid score.”
- Not “wipe the map.” Most raids **retreat** when the goal is done or fails. **Territory wipe** is destroying the flag — a separate verb ([WIPE / BURN FLAG](wipe-burn-flag.md)).

## From the bible (today’s code)

- Needs about **6 living fighters**; smaller clans hunt instead (`too_few`).
- **Hard stops:** outnumbered by every neighbor, under attack, hunt still out, 60s cooldown since last raid ended, no prize, etc.
- **Clan morale under 30** can call off an active raid (ties to planned [Morale bar (ClanBrain)](morale-bar-clan.md)).
- Player war party: **War Horn** + ordered followers = big marching band (see [War Horn](war-horn.md)).

**Bible (repo):** `bible/raid.md` · player four verbs: `bible/earlygame_vision.md` §4

## Related

- [War Horn](war-horn.md)
- [STEAL / TAKE HERD](steal-take-herd.md)
- [LOOT / TAKE GOODS](loot-take-goods.md)
- [KILL / ATTACK MEN](kill-attack-men.md)
- [WIPE / BURN FLAG](wipe-burn-flag.md)
- [Territory wipe](territory-wipe.md)
- [ClanBrain](clan-brain.md)
- [Fight](fight.md)
- [Hunt intent](hunt-intent.md)

## Systems

- [Fight and raid](../systems/fight-and-raid.md)
