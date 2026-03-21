# Playtest Checklist

Quick reference for testing StoneAgeClans.

**Run with occupation monitoring** (recommended for Farm/Dairy/women testing):

```bash
./Tests/run_occupation_test_with_monitor.sh
./Tests/run_occupation_test_with_monitor.sh --force  # if lock stuck, clear and run
```

Play in the game window. Terminal shows occupation events only (game stdout goes to `Tests/game_console.log`). Press Ctrl+C to stop.

**Run normally** (Godot editor F5 or):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/macbook/Desktop/stoneageclans
```

## Startup

- [ ] Game loads without errors
- [ ] Player spawns with 1 Land Claim, 1 Farm, 1 Dairy
- [ ] Women (8), sheep, goats spawn around map
- [ ] Resources (berries, wood, etc.) spawn

## Occupation System (recent fixes)

- [ ] **Place Land Claim** → women can path to it and occupy
- [ ] **Place Farm** → herd sheep into claim, they should enter Farm slots
- [ ] **Place Dairy** → herd goats into claim, they should enter Dairy slots
- [ ] **Drag woman/animal out** of building slot → previous occupant evicted cleanly
- [ ] **Drag woman/animal into occupied slot** → replaces occupant, old one unassigned
- [ ] No two women occupying same slot (race fix)
- [ ] Oven/Farm/Dairy production runs when occupied

## Core Loop

- [ ] Gather berries, wood
- [ ] Build oven, craft bread
- [ ] Herd animals into land claim
- [ ] Women work at buildings when occupied
- [ ] Combat/raiding (if testing)

## Debug Options (optional)

- `--occupation-diag` — logs occupation flow to `Tests/occupation_diag_*.log`
- `--debug` — verbose console logging
