---
search:
  keywords: clanbrain clan brain planner
---

# ClanBrain

**Status:** Draft (identity layer planned; quotas and raid/hunt logic exist today in code)

**Whose word:** Yours

## Definition

The clan’s planner, owned by the territory (flag or campfire). It sets defenders, searchers, raids, and hunts. Clansmen pull those orders instead of being micromanaged. It also **reflects the clan as a whole**: skills, traits, stats, morale, plus buffs and debuffs that change how bold or brittle the tribe acts.

## Stats from clansmen

- **Stats** on the ClanBrain are built from **clansmen** (male fighters in the clan), not from women or herd animals.
- Each numeric stat on the brain is the **average** of that stat across all clansmen counted (exact roster rules TBD at implementation).
- When the roster changes (birth, death, exile), the brain’s stats **recompute**.

## Traits from clansmen

- **Traits** on the ClanBrain come from the same trait system as individual NPCs.
- If **enough** clansmen share the same trait, the ClanBrain **gains that trait** for clan-level decisions (exact headcount or percent TBD).
- Traits the brain carries can bias raid appetite, defend stubbornness, herd focus, and similar—same families as personal traits, applied at clan scale.

## Skills

- The ClanBrain has its own **skill** list (separate from one guy’s skills). Design target; not shipped.
- Skills modify how the brain uses quotas, pressures, and raid/hunt picks. Specific skills TBD.

## Morale bar

- The ClanBrain has a **morale bar** (clan mood), not only the old strategic-state enum.
- Morale rises and falls from wins, losses, hunger, leader death, raids, and buffs/debuffs.
- Low morale pushes cautious brains (fewer raids, easier retreat, defectors later). High morale pushes risk and cohesion.
- **Not the same as** a single fighter’s personal morale / flight bar — see [Morale bar (fighter)](../terms/morale-bar-fighter.md) and `bible/future implementations/morale_bar_flight.md`.

## Buffs and debuffs

- The ClanBrain can hold **buffs** and **debuffs** (relics, shrine effects, drought, shame after a wipe, horn rally, etc.).
- These stack with averaged stats and quorum traits. They should be visible in UI when the clan panel ships.

## Related

- [Morale bar (ClanBrain)](morale-bar-clan.md)
- [Trait](trait.md)
- [Stats](stats.md)
- [Defender quota](defender-quota.md)
- [Searcher quota](searcher-quota.md)
- [Strategic state](strategic-state.md)
- [Campfire](campfire.md)
- [Flag](flag.md)
- [Clansman](clansman.md)

## Systems

- [Clan planner](../systems/clan-planner.md)

## Bible

- `bible/ai_clan_brain.md` — implementation today + planned identity layer
- `bible/game_dictionary.md` — terminology table
