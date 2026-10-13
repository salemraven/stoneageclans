# Morale bar and flight threshold (near future)

**Status:** **Core is built** (`scripts/combat/morale_bar.gd`, used for flight in fights; bravery shifts the flight line). The player-facing UI bar is **not** built. Replaces the split between `fight_flight` score-at-zero and the climbing `rout_meter`.

**Locked 2026-10-13 ([director_locks_2026_10.md](../director_locks_2026_10.md) §3–§4):** bravery is a lasting trait that also feeds an individual **aggression bar** (attack at one end, flee at the other). Clan raid appetite is the fighters' average, tilted by the leader. An Attack or Guard order gives a courage bonus but does not stop a man from breaking. Today the raid nudge in code never lowers a `raid_joined` man's bar, which must change.

**Clan vs fighter:** This doc is **per clansman** in combat. The **ClanBrain** has a separate **clan morale bar** (strategy, defection, raid appetite) — `ai_clan_brain.md` § Clan identity · `wiki/terms/morale-bar-clan.md`.

## One bar

- Morale runs **0–100**. **50** is steady middle. Below 50 is low morale; above 50 is high morale.
- **Flight** is crossing below a personal **flight line** on that bar (default **50**). Skills and traits move that line up or down.
- Fold **rout_meter** contagion and ally-death pressure into **drops on this bar**. No separate rout threshold.
- Yellow **`!!`** marks flight (today’s rout flash). Terminology in new docs: **flight**, not rout/flee.

## Leader death

- Big temporary drop on the bar for every living man of that clan (offense and defense). Whether that triggers flight depends on traits.

## Not in scope until this ships

- UI bar for player. Perks/skills that move the flight line (hook only).
