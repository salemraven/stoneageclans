# Clan insanity / enlightenment meter (concept)

**Scope:** Clan-wide psyche — affects the **whole clan**, not individuals.

## Idea

- One shared value per clan (or a **two-sided meter**: insanity vs enlightenment — design TBD).
- **Raises insanity (or lowers enlightenment):** killing, **cannibalism**, and similarly harsh acts (exact list when implemented).
- **Raises enlightenment:** peaceful play — craft, trade, rituals, calm gathering, coexistence cues, etc. (exact list TBD).

## Implementation sketch (later)

- Authoritative clan field on **`LandClaim`** / **`ClanBrain`** (MP-safe, server-owned).
- Tick or event hooks: combat kills, corpse consumption pipeline, peaceful job completions → adjust meter with clamps and decay optional.
- **Effects:** clan-wide thresholds — morale / AI hesitation or aggression shifts, horn behavior, diplomacy, hallucination/UI flavor, or gated actions — locked in when the feature ships.
