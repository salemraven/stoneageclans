# Playtest Readiness

Quick reference for running playtests and analyzing results.

---

## Prep (before playtest)

```bash
./playtest_prep.sh
```

Verifies Godot, game loads, and prints run commands.

---

## Quick Start

| Mode | Command | Duration |
|------|---------|----------|
| **Normal play** | `./run_playtest.sh` | Manual |
| **2-min productivity** | `./run_2min_test.sh` | 120s auto-quit |
| **4-min productivity** | `./run_4min_test.sh` | 240s auto-quit |
| **Agro/combat test** | `godot --path . -- --agro-combat-test` | 60–90s (manual close or auto-quit) |
| **Raid test** | `godot --path . -- --raid-test` | 90s auto-quit |

---

## Early Game Focus (Campfire, Travois, Clansmen)

**What to test:**
- Place campfire → deposit, cooking, clan join
- Build travois → carry, drop, pick up
- Clansmen carry travois (PickUpTravoisTask, PlaceTravoisTask)
- NPC death while carrying travois → drops at corpse
- Movement slow (70%) and no defend when carrying

**Recommended:** Run `./run_2min_test.sh` or `./run_4min_test.sh` for timed capture with snapshots. Play normally: place claim, gather, herd, build campfire, use travois.

---

## Data & Reporter

- **Capture:** `--playtest-capture` or `--playtest-2min` / `--playtest-4min` / `--agro-combat-test` / `--raid-test` (auto-enables)
- **Output:** `user://playtest_YYYYMMDD_HHMMSS.jsonl` or `Tests/playtest_session.jsonl` when `GODOT_TEST_LOG_DIR=Tests`
- **Reporter:** `godot --path . -s scripts/logging/playtest_reporter.gd [path]` — summarizes events, FPS, counts

---

## Environment

- **Godot path:** Set `GODOT` env var if not at `/Applications/Godot.app/Contents/MacOS/Godot` (macOS)
- **Log dir:** `export GODOT_TEST_LOG_DIR=Tests` to write logs into project (used by run_2min/4min scripts)
- **Manual run:** `godot --path . -- --playtest-2min` — leave window open; auto-quits at 120s

---

## Pre-Flight Checklist

- [ ] Game starts without errors
- [ ] Campfire places and accepts deposits
- [ ] Travois builds, carries, drops
- [ ] Clansmen can pick up / place travois (if AI jobs wired)
- [ ] NPC death drops travois at corpse
- [ ] Reporter runs on latest JSONL
