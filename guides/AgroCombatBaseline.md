# Agro combat baseline (Step 0b)

Record this after the **first green run** of the raid test (2 clans × 10, 1 leader + 9 followers). Use it to catch regressions (green = within ~20% of these ranges or better).

## Data collection

- **Run the raid test:** `--agro-combat-test` (playtest capture is **auto-enabled**; no need for `--playtest-capture`).
- Output: `user://playtest_YYYYMMDD_HHMMSS.jsonl` (Godot user data dir).
- Events recorded: `agro_increased`, `agro_threshold_crossed`, `combat_started`, `combat_ended`, `combat_target_switch`, `combat_hit`, `combat_whiff`, plus snapshots every 2s (fps, in_combat, alive_npcs).

## How to run the reporter

After a run, from project root:

```bash
godot --path . -s scripts/logging/playtest_reporter.gd
```

Uses `user://last_playtest_path.txt` (written by instrumentor at capture start), falling back to latest `user://playtest_*.jsonl` by mtime. Or pass a path explicitly:

```bash
godot --path . -s scripts/logging/playtest_reporter.gd /path/to/playtest_YYYYMMDD_HHMMSS.jsonl
```

## Raid test (ClanBrain)

Tests whether ClanBrain initiates raids and NPCs self-organize (no follow/guard). Two NPC clans: ClanA (9) as raider, ClanB (4) as target; claims ~1300 px apart. Run 90 s then auto-quit.

**Run:** `--raid-test` (capture auto-enabled). Reporter detects `raid_test: true` in session_start.

**Raid events:**

- `raid_evaluated` — ClanBrain evaluated raid (clan, score, score_breakdown).
- `raid_started` — Raid intent set (attacker_clan, target_clan).
- `raid_joined` — NPC entered RaidState (npc, raid_phase).
- `raid_aborted` — Raid cancelled (clan, reason).

**Pass criteria:**

1. At least one `raid_started`.
2. `raid_joined` >= 2 (MIN_RAID_PARTY_SIZE).
3. (Optional) Combat events after first raid_started.
4. (Optional) Raid ends (raid_aborted or completion).
5. Invariant: if any `raid_evaluated` has score >= 1.0 and no `raid_started`, a block must have been logged (no_weak_enemy or similar).

## Baseline (fill after first green run)

- **combat_started:** _____ – _____
- **combat_ended:** _____ – _____
- **combat_hit:** _____ – _____
- **combat_whiff:** _____ – _____
- **combat_target_switch:** _____ – _____
- **agro_increased:** _____ – _____
- **agro_threshold_crossed:** _____ – _____
- **FPS (min / avg / max):** _____ / _____ / _____

(Example: combat_started 40–60, hit 80–150, whiff 10–30, FPS ≥ 30.)

## Step 9: Save/load smoke test (optional)

**Checklist:**

1. Run a short agro combat session (or normal play).
2. Save game.
3. Load game.
4. Confirm: no crash, EntityRegistry rebuilt, IDs revalidated, invalid CommandContexts cleared.
5. Confirm: combat/agro still work (e.g. run `--agro-combat-test` after load and verify engagements).
