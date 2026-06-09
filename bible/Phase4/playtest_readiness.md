# Playtest Readiness

## Quick Start

1. **Launch** – Run from command line: `./run_playtest.sh` (or open in Godot editor and press Play).
2. No `--woman-test` or `--debug` args.
2. **Place your land claim** – You start with 1 land claim only.
3. **Keys 9 and 0** – Eat from hotbar slots 9 and 0 to restore hunger.

---

## Current Playtest Config

| Setting | Value |
|--------|-------|
| Player starts with | 1 land claim only |
| AI cavemen | 4 (spread far apart) |
| Wild women | 3 initial, +1/min (cap 12) |
| Sheep / goats | 3 each, +1 each/min (caps 15) |
| Buildings | Spawn empty |
| Hunger | Player: depletes, no death. NPCs: die after 20s safety. |
| Combat | On (agro, hitmarker X, !!! indicator) |
| Tools | Wood/stone gatherable without axe/pick |

Tune values in `scripts/config/balance_config.gd` or `balance_config.md`.

---

## Debug Flags (off by default)

- `--debug` / `--verbose` – Extra logging
- `--woman-test` – Skips cavemen, test env only
- `--occupation-diag` – Occupation flow logs

Don’t use these for a normal playtest.

---

## Checks Before Playtest

- [ ] No `--woman-test` in launch args
- [ ] `NPCConfig.combat_disabled = false`
- [ ] BalanceConfig autoload registered (project.godot)
