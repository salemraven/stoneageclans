# Playtest & session capture — issue tracker

This document lists **observed issues** from instrumented runs (notably long **windowed** sessions with `--session-instrument`, `--session-quickstart`, `--log-console`, and log truncation). Use it to **investigate root causes** one by one: bugs, design gaps, or expected behavior that needs tuning.

**Evidence source (example run):** `nohup_live_play.log` / `game_logs.txt` — on the order of **~100 MB / ~540k lines** for a long play session (Apr 18, 2026 sample).

---

## How to use

1. Pick an item below.
2. Mark status: `open` → `investigating` → `root cause` → `fix` / `wontfix` / `by design`.
3. Link PRs/commits and any follow-up docs in **Notes**.

---

## 1. Performance & instrumentation (engine / tooling)

| ID | Issue | Symptom / evidence | Status | Notes |
|----|--------|---------------------|--------|-------|
| P1 | **Logging I/O dominates frame time** | Single session produced **~100 MB** console+log files; **~300k** `[MOVEMENT]` and **~173k** `[SESSION]` lines in one run. | open | MOVEMENT/SESSION bypass global throttle; each line flushed to disk. |
| P2 | **`--log-console` doubles cost** | Full stream duplicated to stdout (e.g. `nohup` / `tee`). | open | Mitigation: file-only capture for long runs. |
| P3 | **Log size cap not applied mid-session** | `game_logs.txt` grew to **~97 MB**; `MAX_LOG_SIZE` (10 MB in `unified_logger.gd`) applies on **open**, not during a single long run. | open | One session can write an unbounded file. |
| P4 | **Movement debug dictionary growth** | `MovementDebugInstrument._last_sample_time` keyed by instance id; may grow if many NPCs spawn/despawn over hours. | open | Likely small vs I/O; verify + prune on exit. |
| P5 | **Append-only log confusion** | `user://game_logs.txt` is append-only unless truncated; easy to mix runs when analyzing. | open | Mitigated by `run_session_instrument.sh` + `TRUNCATE_SESSION_LOG=1`. |

---

## 2. NPC task system & gather work (behavior)

| ID | Issue | Symptom / evidence | Status | Notes |
|----|--------|---------------------|--------|-------|
| T1 | **Gather task step fails repeatedly** | **`gather_task.gd) FAILED`** (TaskRunner WARNING) **~10,667** times; often **task 1/3** then full job cancel. | open | Trace `gather_task.gd` failure conditions vs move/gather/move pipeline. |
| T2 | **“No resource” flood for territory gather** | **`WORK_GATHER_NO_RESOURCE`** (SESSION) **~42,211** lines; many clansmen same timestamp. | open | Suggests jobs assigned when nothing is gatherable / reservable, or severe contention. |
| T3 | **Task cancel churn** | **`TASK_CANCEL`** **~16,115**; reasons include **`assign_job_supersede`**, **`task_failed`**, **`resource_freed`** (~28). | open | Supersede + failed gather likely dominate; confirm intended vs thrash. |
| T4 | **Long wander / gather durations** | **`STATE_DURATION` … `potentially stuck!`** **~167** (wander + gather, tens of seconds). | open | Heuristic warnings; may correlate with T1–T2 or benign idle. |

**Related code areas (starting points):**

- `scripts/ai/task_runner.gd` — task fail / cancel
- `gather_task.gd` (path from logs)
- `scripts/systems/territory_job_service.gd` — `WORK_GATHER_NO_RESOURCE`, reservations
- Session lines: `WORK_TASK_FAILED`, `WORK_JOB_ASSIGNED`, etc.

---

## 3. NPC FSM / roles (informational vs bug)

| ID | Issue | Symptom / evidence | Status | Notes |
|----|--------|---------------------|--------|-------|
| F1 | **Women + agro state** | DEBUG: `Can enter agro (not_caveman)` for `QS_*`; FSM still picks **reproduction**. | by design? | Verify intended; reduce log noise if not debugging FSM. |
| F2 | **Clansmen babies → full economy** | Population growth increases SESSION/task volume (not a bug by itself). | informational | Scales T1–T3. |

---

## 4. Shell / launcher (fixed vs watch)

| ID | Issue | Symptom / evidence | Status | Notes |
|----|--------|---------------------|--------|-------|
| S1 | **`SESSION_QUIT_AFTER_SEC=0` + `set -u`** | Empty `QUIT_ARGS[@]` caused **unbound variable** (bash). | **fixed** | Replaced with `RUN_GODOT` array in `run_session_instrument.sh`. |
| S2 | **`awk` in run script** | Rare hang / no Godot start in some environments. | **fixed** | Replaced with bash arithmetic for auto-quit display. |

---

## 5. Error-level logging

| ID | Issue | Symptom / evidence | Status | Notes |
|----|--------|---------------------|--------|-------|
| E1 | **UnifiedLogger `[ERROR]`** | **0** `[ERROR]` lines in sampled long run. | open | No engine-logged hard failures in that capture; keep grep on future runs. |

---

## Suggested investigation order

1. **T2 + T1** together — why `WORK_GATHER_NO_RESOURCE` and gather fail align (assignment logic vs world state vs leases).
2. **T3** — whether supersede is too aggressive once T2 is understood.
3. **P1–P3** — if long instrumented runs are still needed, reduce volume or batch flush (product/engine decision).
4. **T4** — after gather path is sane, revisit false positives for “stuck.”

---

---

## Root cause analysis (deep dive)

Evidence is cross-checked against the current codebase (`stoneageclans` repo).

### P1 — Logging I/O dominates frame time

| | |
|--|--|
| **Root cause** | `UnifiedLogger.write_log_entry()` appends each line and calls `_flush_buffer()` **immediately** when file logging is on (`unified_logger.gd` ~255–258). **`MOVEMENT` and `SESSION`** skip the global `_should_throttle()` path (`_should_throttle` returns `false` for those categories, ~147–148). Session instrumentation enables **high-frequency** `NPC_MOVE` (~0.5s/NPC via `MovementDebugInstrument`) plus **every** `log_session` call from tasks/FSM. |
| **Not a gameplay bug** | Instrumentation is doing what it was asked; cost is **O(lines written × flush)**. |
| **Fix directions** | (a) Batch flush on a timer or N lines. (b) Throttle or sample `MOVEMENT`/`SESSION` when a flag is set. (c) Optional “lite” session mode: file-only, longer interval, or ring buffer. |

### P2 — `--log-console` doubles cost

| | |
|--|--|
| **Root cause** | Same log line goes to **print** and **file** when both flags are true (`write_log_entry` ~248–258). `run_session_instrument.sh` always passes `--log-console` next to file logging. |
| **Fix directions** | Add `SESSION_LOG_CONSOLE=0` env in the shell script to omit `--log-console` for long runs; or split “mirror to stderr” from “mirror to huge pipe”. |

### P3 — Log size cap not applied mid-session

| | |
|--|--|
| **Root cause** | `MAX_LOG_SIZE` is only consulted in `_open_log_file()` when (re)opening the file (`unified_logger.gd` ~108–114). During a single run the file stays open and **grows without rotation**. |
| **Fix directions** | (a) Check size every N MB and rotate/truncate. (b) Ring buffer in memory + periodic snapshot. |

### P4 — Movement debug dictionary growth

| | |
|--|--|
| **Root cause** | `MovementDebugInstrument._last_sample_time` is a **static** `Dictionary` keyed by `instance_id` (`movement_debug_instrument.gd` ~7, 31–35). **Nothing removes** keys when an NPC is freed. |
| **Risk** | Long sessions with many spawn/despawn cycles → **slow growth** of keys (usually secondary to P1). |
| **Fix directions** | Prune on `tree_exiting` / weak refs / periodic sweep of stale IDs. |

### P5 — Append-only log confusion

| | |
|--|--|
| **Root cause** | `user://game_logs.txt` is opened **append** (`READ_WRITE` + `seek_end`) so multiple runs stack. |
| **Fix directions** | Already mitigated by `TRUNCATE_SESSION_LOG=1` in `run_session_instrument.sh`; document as default for “analysis runs”. |

---

### T2 — `WORK_GATHER_NO_RESOURCE` flood

| | |
|--|--|
| **Where it fires** | `TerritoryJobService.generate_gather_job()` logs `WORK_GATHER_NO_RESOURCE` when `find_nearest_available_resource(claim, worker)` returns **null** (`territory_job_service.gd` ~12–24). |
| **Who calls it** | `gather_state.gd` → `_try_pull_gather_job()` → `land_claim.generate_gather_job(npc)` (~256–260), whenever the NPC is in gather flow, **has no job**, and throttle allows ( **`SEARCH_THROTTLE` 0.5 s** ~12–13, 80–84). |
| **Root cause** | **Many workers** × **retry ~2 Hz** × **no reservable node** (depleted world, `ResourceIndex.query_near` empty after filters, or everyone competing for the same nodes) ⇒ `generate_gather_job` returns `null` **repeatedly**, and **each attempt** emits a SESSION line when instrumentation is on. |
| **Fix directions** | (a) **Backoff / cooldown** after a failed pull (extend `_no_job_retry_time` or increase throttle when last result was null). (b) **Don’t log SESSION** on every miss — sample, rate-limit, or DEBUG only. (c) **Gating**: don’t enter gather intent for worker N if global “no resource” for claim (ClanBrain / claim helper). |

---

### T1 — `gather_task.gd` FAILED (~10k) with “1/3”

| | |
|--|--|
| **Progress meaning** | `Job.get_progress_string()` is **`current_index` / `tasks.size()`** (`job.gd` ~65–68) — **0-based index of the active task**. For `GatherJob`, tasks are **MoveTo → GatherTask → MoveTo(claim)** (`gather_job.gd` ~48–75). **`"1/3"`** means **second task** = **`GatherTask`** (gather_task.gd). |
| **Root cause** | Failures come from **`GatherTask._tick_impl` / `_start_impl`** — e.g. `should_abort_work()`, invalid/unharvestable resource, inner **`MoveToTask`** to resource failing (`gather_task.gd` ~133–138 “move_to_resource failed”), inventory full, lease/expiry handled in TaskRunner, etc. High count **correlates** with **contention** (resource freed mid-job), **pathing** stuck, or **abort** from combat/defend/follow. |
| **Fix directions** | (a) Correlate with `WORK_TASK_FAILED` + reason in SESSION if we add **failure reason enum** to GatherTask. (b) Reduce false aborts from `should_abort_work()`. (c) Replace inner MoveTo failure with **replan** instead of failing whole job when resource still valid. |

---

### T3 — `TASK_CANCEL` churn (`assign_job_supersede`, `task_failed`, …)

| | |
|--|--|
| **Root cause** | `TaskRunner.assign_job()` **always** calls `cancel_current_job("assign_job_supersede")` if `is_active` (`task_runner.gd` ~134–135). Any **second** `assign_job` while a job runs logs supersede. **`task_failed`** comes from `Task.TaskStatus.FAILED` (~104–120). So churn = **new jobs assigned over old** + **gather (or move) step failing** → cancel + new pull from gather_state. |
| **Fix directions** | (a) Avoid assigning a **new** gather job if the **current** job is still viable (diff resource vs supersede). (b) After T2 backoff, fewer pointless pulls ⇒ fewer supersede cycles. |

---

### T4 — `STATE_DURATION` … “potentially stuck”

| | |
|--|--|
| **Root cause** | `fsm.gd` on state **exit** compares duration to **fixed thresholds** (wander **30s**, gather **25s**, etc.) and logs WARNING (`fsm.gd` ~844–859). Long gather/wander is often **legitimate** (long walk, crowded nodes) or **stuck pathing** — heuristic only. |
| **Fix directions** | Tune thresholds; distinguish “moving toward goal” vs true stall (velocity + progress metrics). |

---

### F1 — Women + agro / `not_caveman`

| | |
|--|--|
| **Root cause** | FSM **evaluates** combat-related states for all NPCs; **agro** `can_enter` is **false** for `npc_type != caveman`** (women). Best state falls through to **reproduction** / others. |
| **Verdict** | **By design**; DEBUG spam is from verbose NPC logging, not wrong logic. |
| **Fix directions** | Skip logging agro eval for types that never enter agro, or gate behind `enable_verbose_npc_logging` only. |

### F2 — Population scaling

| | |
|--|--|
| **Root cause** | More clansmen ⇒ more gather pulls, SESSION lines, and task events. |
| **Verdict** | Expected; interacts with T1–T3. |

---

### E1 — Zero `[ERROR]` lines

| | |
|--|--|
| **Root cause** | UnifiedLogger **ERROR** category wasn’t used for those failure modes; gather/task issues use **WARNING** / NPC / SESSION **INFO**. `push_error` goes to Godot’s default log, not necessarily UnifiedLogger `[ERROR]`. |
| **Fix directions** | If you want UnifiedLogger errors for task failures, add explicit `log_error` on critical paths (careful with volume). |

---

### S1 / S2 — Shell script

| | |
|--|--|
| **Status** | **Fixed** in `run_session_instrument.sh` (`RUN_GODOT` array; bash time display). |

---

## Remediation matrix (prioritized)

| Priority | IDs | Theme | Smallest high-impact actions |
|----------|-----|--------|-------------------------------|
| 1 | T2 + P1 | Gather miss spam + log cost | Backoff after null job; rate-limit `WORK_GATHER_NO_RESOURCE`; optional flush batching |
| 2 | T1 | Gather task failures | Add failure reason to logs; replan inner MoveTo vs fail job |
| 3 | T3 | Supersede churn | Fewer redundant `assign_job` calls once T2 is calmer |
| 4 | P2–P3 | Long captures | Optional `--log-console` off; mid-session log rotation |
| 5 | T4 | Stuck heuristic | Tune thresholds or add movement-based stall detection |
| 6 | P4 | Memory | Prune `_last_sample_time` keys |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-04-18 | Initial list from session instrumentation analysis and `nohup_live_play.log` aggregates. |
| 2026-04-18 | Root cause deep dive + remediation matrix (code-traced). |
| 2026-04-18 | **Implemented:** gather backoff after null job (4s); rate-limited `WORK_GATHER_NO_RESOURCE` / reserve SESSION logs; batched file flush when session instrumentation; `NPCProductivityInstrument` SESSION snapshots; movement sample cache prune every 120s. |
