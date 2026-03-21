# Dev Resources & Cursor Plans

**Location:** `C:\Users\mxz\.cursor\plans` (user-level, not project-specific)

Cursor stores implementation plans in this folder. Plans use frontmatter (`name`, `overview`, `todos`, `isProject`) and markdown bodies with implementation details.

---

## Playtest

**Modes:**
- **Manual** — Play, then close. Run `Tests\run_playtest.ps1`.
- **Timed** — `.\run_playtest.ps1 -Timed 2` (2 min) or `-Timed 4` (4 min). Auto-quit, then reporter runs.
- **Agro/Combat** — `run_agro_combat_test.ps1` or `--agro-combat-test` for combat engagement capture.
- **Raid** — `--raid-test` for ClanBrain raid behavior capture.

**Data flow:**
1. Game runs with `--playtest-capture` (or `-Timed` / `-agro-combat-test` / `-raid-test`).
2. `run_playtest.ps1` passes `--playtest-log-dir <Tests\playtest_…>` (and sets `GODOT_TEST_LOG_DIR`) → `Tests/playtest_YYYYMMDD_HHMMSS/playtest_session.jsonl`. CLI wins if env is missing on Windows.
3. If env unset: `user://playtest_*.jsonl`. Instrumentor writes `user://last_playtest_path.txt` or absolute path when env is set.
4. On quit, run_playtest.ps1 invokes reporter: `godot -s scripts/logging/playtest_reporter.gd -- <path>`.
5. Reporter reads JSONL, prints summary to `playtest_report.txt`.

**Verification events:** `deposit_while_herding` (herded_count≥2 deposit path), agro/combat counts, raid_started/raid_joined.

---

## Stone Age Clans Plans

| Plan | Focus |
|------|--------|
| `phase_a_survival_basics_*.plan.md` | Hunger bar UI, tool requirements (Oldowan), hand gather |
| `early_game_hut_system_*.plan.md` | Campfire Living Huts, woman assignment, reproduction gates |
| `clansmen_attack_player_fix_*.plan.md` | HostileEntityIndex vs PerceptionArea, player-protection logic |
| `aop_phase_2_plan_*.plan.md` | AOP Phase 2 |
| `aop_as_base_refactor_*.plan.md` | AOP as base refactor |
| `critical_fixes_implementation_*.plan.md` | CRITICAL_FIXES.md items (Tier 1–5) |

*Note: Filenames include a hash suffix (e.g. `_7144fc52`). Use glob or search by name.*

---

## Other Projects

The same folder holds plans for SpriteForge, 3D refactors, pixel-perfect POV, pipeline robustness, etc. Filter by plan `name` or `overview` to find Stone Age Clans–specific plans.
