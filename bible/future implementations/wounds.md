# Wounds on living fighters (future)

**Status:** Design stub — **not implemented** (no `wound` in scripts today).  
**Scope:** Combat outcomes beyond instant death; ties to Medic Hut (bible §VII).  
**Drafted:** Sep 2026 · **Owner context:** [earlygame_vision.md](../earlygame_vision.md) §6

---

## Why

Combat today: health → 0 → **corpse** (lootable). **Living clansmen** do not retain hit consequences. Target: wounds change fight effectiveness and create medic / recovery gameplay without replacing corpses.

---

## Target outcomes (from early game vision)

| Event | Behavior |
|-------|----------|
| Hit that doesn’t kill | Apply **wound** (stack or severity band) |
| Wounded clansman | Lower damage, speed, or accuracy until cleared |
| Clear wound | Time, rest, **Medic Hut** + berries (bible planned), or future shaman |
| Player dies | Leader succession; **loot stays on corpse** |
| Failed STEAL bond | Herdable unbonded at current position |

---

## Open questions (before F1)

1. Wound **stacks** vs single **severity** tier?
2. Blocks: gather, raid, defend, or all combat only?
3. Heal only at Medic Hut or slow passive regen?
4. MP: server-owned wound state on `HealthComponent` or new `WoundComponent`?

---

## Promote criteria

When shipped: one row in `bible.md` §XXII; short §X Combat note linking here.
