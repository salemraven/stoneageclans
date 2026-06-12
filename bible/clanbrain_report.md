# ClanBrain Report — Standard Spec

**Purpose:** One markdown report per playtest session — the **standard** tuning artifact for ClanBrain and NPC efficiency.

Answers:

1. Did each AI clan **grow** (population, fighters, stock)?
2. What did **ClanBrain decide** (quotas, hunt, raid, alert, survival)?
3. Did decisions **finish, fail, or get stuck**?
4. Which **fighters** did real work (gather, deposit, tasks, FSM time)?

**Generator:** `scripts/logging/clanbrain_report.py`  
**Run:** `bash tools/run_clanbrain_report_5min.sh`

**Related docs:** `bible/ai_clan_brain.md`, `bible/Ultimate_npc_clanbrain_test.md`, `bible/PLAYTEST.md`

**Last updated:** 2026-06-12

---

## 1. Pipeline

```
Main.tscn + --playtest-capture
    → playtest_session.jsonl (PlaytestInstrumentor)
    → python3 scripts/logging/clanbrain_report.py … -o clanbrain_report.md
```

Output folder: `Tests/logs/clanbrain_report_<timestamp>/` (`jsonl`, `md`, `console.log`).

| Session length | Use for |
|----------------|---------|
| 2 min | Smoke / fast regression |
| **5 min** | **Standard tuning run** (babies → clansmen → hunts) |
| 6–7 min | Full hunt disband + raid cycle |

Use fixed `--playtest-world-seed` when comparing patches.

---

## 2. Standard report sections (implemented)

The markdown file is always generated in this order:

| # | Section | What it tells you |
|---|---------|-------------------|
| 1 | **Session** | Duration, seed, flags, clan count |
| 2 | **Summary** | One row per AI clan — growth, economy, brain, hunts |
| 3 | **Gates** | Invariants, stuck parties |
| 4 | **ClanBrain health** | Quota fill, **calorie buffer**, kcal stored/need, survival time |
| 4a | Hunt lifecycle | Started / completed / prey / hunt deposit |
| 4b | Breeding pipeline | Women joined → babies → clansmen |
| 5 | **Worker efficiency** | Tasks, gather starvation, FSM time % |
| 6 | **Economy (session)** | Gather/deposit totals, yield, failures |
| 7 | **Buildings (session)** | All placements by type, source, time |
| 8 | **Per-clan detail** | Brain, economy, failures, **fighter roster**, hunts, buildings |
| 9 | **Invariant failures** | Should be empty on healthy runs |

### 2.1 Summary table columns

| Column | Source |
|--------|--------|
| Pop | `clan_brain_eval` clan_members start→end |
| Fight | End `cavemen` |
| Kcal store | End `calories_in_storage` (kcal in land claim) |
| Kcal need | End `calories_daily_need` (clan daily burn) |
| Cal buffer | End `calories_days_buffer` (= stored ÷ daily need; mirrors `food_days_buffer`) |
| Hunts | Count `hunt_started` |
| Hunt OK | Count `hunt_completed` |
| Gath / Dep | Sum `gather_completed` / `deposit_completed` |
| G fail* | Actionable gather fails (excludes `inventory_full`) |
| Quota fill | Mean defender+searcher fill from evals |
| Surv | Seconds in `survival_mode` (from eval integration) |
| Clansmen | Count `baby_grew_to_clansman` |
| Bld | Count `building_placed` |
| 1st hunt | `t` of first `hunt_started` |

### 2.2 Economy JSONL events

| Event | Emitter | Key fields |
|-------|---------|------------|
| `gather_completed` | `gather_task.gd` | `npc`, `clan`, `resource`, `amount` |
| `gather_failed` | `gather_task.gd` | `npc`, `clan`, `reason` |
| `gather_empty_switch` | `gather_task.gd` | `npc`, `clan`, `reason` |
| `deposit_completed` | `npc_base.gd` | `npc`, `clan`, `items`, `total` |
| `deposit_failed` | `npc_base.gd` | `npc`, `clan`, `reason` |

### 2.3 Buildings JSONL events

| Event | Emitter | `source` values |
|-------|---------|-----------------|
| `building_placed` | `main.gd`, milestone, campfire | `herder_hut`, `milestone`, `campfire` |

Legacy: `milestone_building_placed`, `campfire_building_built` (also emit `building_placed`).

### 2.4 Worker / task JSONL events

| Event | Emitter | Key fields |
|-------|---------|------------|
| `task_completed` | `task_runner.gd` | `npc`, `clan`, `task_type` |
| `task_failed` | `task_runner.gd` | `npc`, `clan`, `task_type`, `reason` |
| `gather_no_resource` | `territory_job_service.gd` | `npc`, `clan`, `reason` |
| `npc_fsm_transition` | `playtest_instrumentor.gd` | `npc`, `clan`, `type`, `from`, `to` |
| `npc_stuck_state_escaped` | instrumentor | `npc`, `from_state` |

### 2.5 ClanBrain health JSONL events

| Event | Use in report |
|-------|---------------|
| `clan_brain_eval` | Quota fill, **kcal stored/need/buffer**, pressures, alert |
| `simulation_tick` | Session tick count, tick interval (calorie drain cadence) |
| `productivity_report` | Per-clan food/herd rate + calorie buffer snapshots |
| `survival_mode_changed` | Survival transitions (eval integration for duration) |
| `hunt_started` / `hunt_completed` / `hunt_aborted` | Hunt lifecycle table |
| `hunt_prey_killed` / `hunt_prey_escaped` | Hunt outcomes |
| `hunt_deposit` / `hunt_butcher_complete` | Loot reaching claim |
| `npc_joined_clan` / `baby_spawned` / `baby_grew_to_clansman` | Breeding pipeline |
| `party_formed` / `party_disbanded` | Gates (stuck parties) |

### 2.6 Per-clan fighter roster

One table per clan (cavemen + clansmen only):

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |

- **Tasks:** `task_completed` / `task_failed` per NPC
- **Deposits:** count `deposit_completed` per NPC
- **Gathered:** sum `gather_completed` per NPC
- **Top states:** dwell time from `npc_fsm_transition` (top 3 by %)

---

## 3. Efficiency KPIs (read from standard report)

| KPI | Where in report | Good direction |
|-----|-----------------|----------------|
| Calorie buffer | ClanBrain health → Cal buffer min→max→end | ↑ end value |
| Kcal in storage | Summary + health → Kcal store | ↑ with population |
| Quota fill | Summary + health tables | → 100% when quota > 0 |
| Hunt completion | Hunt lifecycle → Completed / Started | ↑ |
| Stuck parties | Gates | 0 |
| Deposit yield | Economy → Deposit yield | ↑ (non-food kept on person is OK) |
| Actionable gather fails | Summary G fail* | ↓ |
| Task success rate | Worker efficiency | ↑ |
| Gather no-resource | Worker efficiency | ↓ |
| Party disband integrity | Gates formed/disbanded | → 1.0 |
| Time to first clansman | Breeding pipeline → 1st clansman | ↓ |

**Noise:** `inventory_full` gather fails are normal (full pack). Summary column *G fail* already excludes them.

---

## 4. JSONL inventory (capture)

### In standard report today

All events in §2.2–2.5 plus `clan_brain_invariant_failed`, `clan_brain_quota_update`, `party_*`, `hunt_*`, `raid_*`, `snapshot`, `npc_world_probe`, **`simulation_tick`**, **`productivity_report`**.

**Calorie fields on `clan_brain_eval`:** `calories_in_storage`, `calories_daily_need`, `calories_days_buffer` (required for post–2026-06 calorie system reports; legacy logs show `—` and a Gates warning).

### Not yet in report (future tiers)

| Gap | Event to add |
|-----|--------------|
| Unified action ledger | `brain_action_started` / `brain_action_ended` |
| Full job lifecycle | `task_job_started`, `task_job_completed`, `task_job_cancelled` |
| Raid section in markdown | `raid_evaluated`, `raid_started`, … (events exist) |
| Alert time breakdown | Per `alert_level` from eval (data exists, section TBD) |
| Herd → hut latency | Link `npc_joined_clan` → `building_placed` timestamps |
| Building placement fail | `building_placement_failed` |
| Death / hunger detail | `npc_died`, `npc_ate` per-clan section |
| Party follower churn | `party_follow_cleared` vs `party_disbanded` |

---

## 5. Example snippet (standard shape)

```markdown
# ClanBrain Report (standard)

## Summary
| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
| JI YUEF | 0→13 | 11 | 2.1k | 8.4k | 0.3 | 1 | 0 | 55 | 13 | 1 | 25% | 25.0s | 10 | 2 | 25.3s |

## ClanBrain health
| Clan | Def fill | Search fill | Kcal store min→max→end | Cal buffer min→max→end | Survival |
| JI YUEF | — | 25% | 0→2.1k→2.1k | 0.0→0.3→0.3 | 25.0s |

## Worker efficiency
| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Top FSM (fighters) |
| JI YUEF | 42 | 3 | 93% | 2 | gather 31%, party 24%, combat 24% |

#### Fighter roster (JI YUEF)
| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
| HACA | 18 | 1 | 4 | 22 | gather 45%, herd_wildnpc 20% |
```

---

## 6. Pass/fail gates (CI-friendly)

| Gate | Threshold |
|------|-----------|
| `clan_brain_invariant_failed` | > 0 → fail |
| Parties formed − disbanded at session end | > 0 → warn/fail |
| Hunt started, zero completed+aborted, party active | per clan → fail |
| Zero deposits with gather > 0 and calorie buffer = 0 | warn |
| Task fail / (ok+fail) > 25% per clan | warn (when tasks logged) |

Also run: `python3 scripts/logging/analyze_playtest.py … --strict-clanbrain`

---

## 7. How to run

```bash
# Standard 5-min report (headless — fast CI / no window)
bash tools/run_clanbrain_report_5min.sh

# 5-min OBSERVER — window open, no player, WASD/arrows pan camera, scroll zoom
bash tools/run_clanbrain_report_5min_observer.sh

# 2-min smoke (headless)
bash tools/run_party_hunt_debug.sh 2min
python3 scripts/logging/clanbrain_report.py Tests/logs/party_hunt_*/playtest_session.jsonl -o report.md
```

Optional console debug: `DebugConfig.clan_brain_debug` (not the report source of truth).

---

## 8. Design principles

1. **JSONL only** — never scrape console for the report.
2. **Intent vs outcome** — quotas (intent) + FSM/tasks/deposits (outcome).
3. **Named NPCs** — always `npc_name` from events.
4. **Reason on failures** — every fail event carries `reason`.
5. **Deterministic seeds** — compare runs fairly.
6. **Server authority** — multiplayer logs from server sim only.

---

## 9. Future stats (Tier 3–4, not in standard report yet)

Worth adding when raid/combat tuning becomes the focus:

- **Raid score vs start rate** — `raid_evaluated` vs `raid_started`
- **Alert duration by level** — integrated from eval
- **Deaths by cause** — `npc_died`, starvation via `npc_hunger_threshold`
- **Defender combat blocks** — `clansman_combat_blocked`, `clansman_leash_break`
- **Deposit distance** — add field to `deposit_completed`
- **Party follower retention** — `party_follow_cleared` mid-hunt
- **Building placement failures** — new event when milestone met but placement fails

---

## 10. Rollout status

| Phase | Status |
|-------|--------|
| P0 — JSONL + manual grep | Done |
| **P2 — Standard markdown report** | **Done** (this document) |
| P1 — `brain_action_*` unified ledger | Planned |
| P3 — KPI dashboard / seed compare canvas | Optional |
| P4 — Multiplayer server-only capture | Planned |
