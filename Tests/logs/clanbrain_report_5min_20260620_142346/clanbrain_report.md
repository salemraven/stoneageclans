# ClanBrain Report (standard)

## Session

- **Duration:** 300.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_5min_20260620_142346/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4
- **Simulation ticks:** 2
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| FE QOPA | 0→9 | 6 | 0 | 19.0k | 0.0 | 3 | 1 | 27 | 34 | 0 | 53% | 80.1s | 5 | 1 | 82.0s |
| JU VESA | 0→11 | 7 | 500 | 21.7k | 0.0 | 4 | 3 | 25 | 58 | 0 | 44% | 75.1s | 6 | 2 | 75.3s |
| MI NIUQ | 0→10 | 8 | 0 | 21.4k | 0.0 | 2 | 2 | 49 | 39 | 1 | 69% | 90.1s | 7 | 3 | 92.0s |
| QA GAVE | 0→9 | 7 | 0 | 19.2k | 0.0 | 2 | 2 | 38 | 35 | 1 | 74% | 85.1s | 6 | 2 | 86.6s |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 11 / 10
- **⚠ Possible stuck parties (formed − disbanded):** 1

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| FE QOPA | — | — | 53% | 20% | 0→1.2k→0 | 0.0→1.0→0.0 | 80.1s |
| JU VESA | — | — | 44% | 25% | 0→1.6k→500 | 0.0→1.0→0.0 | 75.1s |
| MI NIUQ | — | — | 69% | 14% | 0→2.8k→0 | 0.0→1.0→0.0 | 90.1s |
| QA GAVE | — | — | 74% | 14% | 0→2.2k→0 | 0.0→1.0→0.0 | 85.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| FE QOPA | 3 | 1 | 1 | 1 | 0 | 4 | 4 |
| JU VESA | 4 | 3 | 1 | 3 | 0 | 8 | 11 |
| MI NIUQ | 2 | 2 | 0 | 2 | 0 | 7 | 7 |
| QA GAVE | 2 | 2 | 0 | 2 | 0 | 6 | 7 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| FE QOPA | 1 | 5 | 5 | 78.1s |
| JU VESA | 2 | 7 | 6 | 72.6s |
| MI NIUQ | 1 | 7 | 7 | 87.7s |
| QA GAVE | 1 | 6 | 6 | 85.4s |

## Clansmen workforce

- **Unique clansmen seen:** 24 (gather FSM transitions: 99, productivity snapshots: 10)
- **Last snapshot:** clansmen=24 with_job=11 (all workers job %=50.0)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| FE QOPA | 5 | 5 | 23 | 26 | 5 | 6 | state_exit_clear_tasks=4, assign_job_supersede=1, exited_tree=1 |
| JU VESA | 6 | 6 | 19 | 45 | 12 | 18 | state_exit_clear_tasks=10, exited_tree=6, assign_job_supersede=2 |
| MI NIUQ | 7 | 7 | 35 | 21 | 7 | 12 | exited_tree=3, state_exit_clear_tasks=3, task_failed=3 |
| QA GAVE | 6 | 6 | 26 | 18 | 6 | 12 | state_exit_clear_tasks=6, assign_job_supersede=2, exited_tree=2 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BAOD | JU VESA | 0 | 1 | 2 | 0 | 2 | gather 88%, party 10%, combat 1% |
| CUJO | MI NIUQ | 6 | 1 | 4 | 0 | 0 | idle 62%, gather 20%, eat 10% |
| DESA | FE QOPA | 0 | 2 | 2 | 0 | 1 | combat 47%, party 22%, gather 10% |
| DEXE | MI NIUQ | 5 | 0 | 2 | 0 | 0 | idle 72%, gather 28%, wander 1% |
| FEBO | MI NIUQ | 5 | 4 | 21 | 0 | 4 | gather 53%, craft 35%, hunt 4% |
| GOKU | JU VESA | 6 | 1 | 4 | 0 | 1 | gather 35%, idle 28%, wander 25% |
| GOTI | QA GAVE | 0 | 2 | 5 | 0 | 1 | idle 43%, gather 26%, party 21% |
| HOEB | FE QOPA | 3 | 0 | 2 | 0 | 1 | gather 100% |
| HUCA | QA GAVE | 4 | 0 | 2 | 0 | 0 | idle 59%, gather 40%, wander 1% |
| JIWA | FE QOPA | 20 | 2 | 12 | 0 | 1 | gather 52%, hunt 28%, wander 13% |
| KUCE | QA GAVE | 6 | 3 | 16 | 1 | 5 | gather 53%, idle 21%, hunt 11% |
| LAAM | MI NIUQ | 6 | 2 | 7 | 0 | 0 | gather 45%, build_milestone 40%, herd_wildnpc 7% |
| LUAV | JU VESA | 13 | 4 | 11 | 0 | 2 | gather 42%, idle 31%, wander 13% |
| MIHU | JU VESA | 0 | 3 | 7 | 0 | 2 | combat 48%, gather 32%, party 11% |
| POZA | FE QOPA | 0 | 1 | 2 | 0 | 1 | combat 53%, party 26%, gather 10% |
| QUPA | QA GAVE | 0 | 1 | 10 | 0 | 1 | craft 49%, herd_wildnpc 47%, eat 3% |
| REIV | JU VESA | 0 | 1 | 2 | 0 | 3 | hunt 64%, build_hut_for_woman 13%, gather 12% |
| SIAB | QA GAVE | 6 | 0 | 4 | 0 | 0 | idle 45%, gather 21%, build_milestone 19% |
| SOUK | JU VESA | 0 | 2 | 9 | 0 | 4 | combat 45%, gather 36%, build_milestone 8% |
| TIHE | MI NIUQ | 7 | 0 | 6 | 2 | 3 | craft 55%, gather 31%, eat 13% |
| TUOF | QA GAVE | 10 | 0 | 5 | 0 | 2 | gather 85%, eat 14%, wander 1% |
| XEEF | MI NIUQ | 5 | 0 | 4 | 0 | 0 | idle 51%, gather 21%, wander 17% |
| XUKA | MI NIUQ | 1 | 0 | 2 | 0 | 1 | gather 69%, wander 28%, idle 3% |
| YIVA | FE QOPA | 0 | 0 | 0 | 0 | 0 | hunt 59%, herd_wildnpc 22%, wander 9% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| FE QOPA | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| JU VESA | 15 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MI NIUQ | 14 | 2 | 2 | 2 | 0 | 0 | 0 | 0 |
| QA GAVE | 14 | 1 | 1 | 1 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| FE QOPA | 2 | 4 | 0 | 2 |
| JU VESA | 2 | 2 | 0 | 0 |
| MI NIUQ | 2 | 2 | 2 | 0 |
| QA GAVE | 2 | 3 | 1 | 1 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| FE QOPA | 25 | 0 | 100% | 0 | 0 | combat 33%, party 15%, gather 15% |
| JU VESA | 48 | 0 | 100% | 0 | 0 | gather 32%, combat 25%, hunt 11% |
| MI NIUQ | 71 | 3 | 96% | 0 | 0 | gather 43%, idle 15%, craft 13% |
| QA GAVE | 60 | 1 | 98% | 0 | 1 | gather 36%, idle 18%, herd_wildnpc 13% |

## Economy (session)

- **Items gathered:** 139
- **Items deposited:** 166
- **Deposit yield:** 119%
- **Gather failures (all):** 5
- **Gather failures (actionable):** 2
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 3
- **not_harvestable:** 2

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Bone | 0 | 17 | — |
| Fiber | 12 | 6 | 50% |
| Grain | 12 | 0 | 0% |
| Hide | 0 | 24 | — |
| Meat | 0 | 40 | — |
| Nuts | 18 | 10 | 56% |
| Spear | 0 | 19 | — |
| Stone | 16 | 6 | 38% |
| Wood | 81 | 44 | 54% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 5
- **Drying Rack:** 2
- **Farm:** 1

### By source

- **herder_hut:** 5
- **milestone:** 3

### Chronological

- t=40.1s **JU VESA** — Living Hut (herder_hut) builder=GIOY @ (-1696,-904)
- t=45.6s **FE QOPA** — Living Hut (herder_hut) builder=XEDA @ (1809,850)
- t=52.9s **QA GAVE** — Living Hut (herder_hut) builder=MUVO @ (1164,-2147)
- t=55.2s **MI NIUQ** — Living Hut (herder_hut) builder=POEJ @ (-469,2743)
- t=157.1s **QA GAVE** — Drying Rack (milestone) @ (969,-2253)
- t=163.3s **MI NIUQ** — Drying Rack (milestone) @ (-687,2643)
- t=240.2s **MI NIUQ** — Farm (milestone) @ (-532,2800)
- t=271.3s **JU VESA** — Living Hut (herder_hut) builder=REIV @ (-1483,-804)

## Per-clan detail

### FE QOPA

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (53% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.2k → 0
- **Daily calorie need (end):** 19.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 3 |
| Grain | 3 | 0 |
| Hide | 0 | 4 |
| Meat | 0 | 5 |
| Nuts | 3 | 3 |
| Spear | 0 | 4 |
| Stone | 3 | 0 |
| Wood | 18 | 15 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DESA | 2 | 0 | 2 | 0 | combat 47%, party 22%, gather 10% |
| HOEB | 2 | 0 | 0 | 3 | gather 100% |
| JIWA | 12 | 0 | 2 | 20 | gather 52%, hunt 28%, wander 13% |
| POZA | 2 | 0 | 1 | 0 | combat 53%, party 26%, gather 10% |
| XEDA | 7 | 0 | 4 | 4 | combat 37%, herd_wildnpc 18%, party 18% |
| YIVA | 0 | 0 | 0 | 0 | hunt 59%, herd_wildnpc 22%, wander 9% |

#### Hunts

- start t=82.0s prey=deer quota=2
- start t=127.0s prey=deer quota=3
- start t=257.2s prey=deer quota=4
- hunt_completed t=123.7s reason=loot_complete
- hunt_aborted t=247.0s reason=active_timeout

#### Buildings

- t=45.6s **Living Hut** — herder_hut (builder: XEDA)

### JU VESA

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/2 (44% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.6k → 500
- **Daily calorie need (end):** 21.7k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 3 |
| Hide | 0 | 8 |
| Meat | 0 | 15 |
| Nuts | 4 | 4 |
| Spear | 0 | 7 |
| Wood | 21 | 21 |

#### Failures

- **Gather:** empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAOD | 2 | 0 | 1 | 0 | gather 88%, party 10%, combat 1% |
| GIOY | 13 | 0 | 7 | 6 | combat 33%, gather 28%, herd_wildnpc 17% |
| GOKU | 4 | 0 | 1 | 6 | gather 35%, idle 28%, wander 25% |
| LUAV | 11 | 0 | 4 | 13 | gather 42%, idle 31%, wander 13% |
| MIHU | 7 | 0 | 3 | 0 | combat 48%, gather 32%, party 11% |
| REIV | 2 | 0 | 1 | 0 | hunt 64%, build_hut_for_woman 13%, gather 12% |
| SOUK | 9 | 0 | 2 | 0 | combat 45%, gather 36%, build_milestone 8% |

#### Hunts

- start t=75.3s prey=deer quota=2
- start t=115.4s prey=deer quota=3
- start t=240.5s prey=deer quota=4
- start t=280.5s prey=deer quota=4
- hunt_completed t=110.4s reason=loot_complete
- hunt_aborted t=235.4s reason=active_timeout
- hunt_completed t=278.6s reason=loot_complete
- hunt_completed t=290.6s reason=loot_complete

#### Buildings

- t=40.1s **Living Hut** — herder_hut (builder: GIOY)
- t=271.3s **Living Hut** — herder_hut (builder: REIV)

### MI NIUQ

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (69% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.8k → 0
- **Daily calorie need (end):** 21.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Fiber | 3 | 0 |
| Grain | 6 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Nuts | 8 | 3 |
| Spear | 0 | 4 |
| Stone | 7 | 3 |
| Wood | 25 | 5 |

#### Failures

- **Gather:** empty_switch:not_harvestable=2, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CUJO | 4 | 0 | 1 | 6 | idle 62%, gather 20%, eat 10% |
| DEXE | 2 | 0 | 0 | 5 | idle 72%, gather 28%, wander 1% |
| FEBO | 21 | 0 | 4 | 5 | gather 53%, craft 35%, hunt 4% |
| LAAM | 7 | 0 | 2 | 6 | gather 45%, build_milestone 40%, herd_wildnpc 7% |
| POEJ | 17 | 1 | 7 | 14 | gather 56%, herd_wildnpc 18%, wander 10% |
| TIHE | 6 | 2 | 0 | 7 | craft 55%, gather 31%, eat 13% |
| XEEF | 4 | 0 | 0 | 5 | idle 51%, gather 21%, wander 17% |
| XUKA | 2 | 0 | 0 | 1 | gather 69%, wander 28%, idle 3% |

#### Hunts

- start t=92.0s prey=deer quota=2
- start t=137.1s prey=deer quota=2
- hunt_completed t=132.8s reason=loot_complete
- hunt_completed t=178.0s reason=loot_complete

#### Buildings

- t=55.2s **Living Hut** — herder_hut (builder: POEJ)
- t=163.3s **Drying Rack** — milestone
- t=240.2s **Farm** — milestone

### QA GAVE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/4 (74% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.2k → 0
- **Daily calorie need (end):** 19.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 5 |
| Fiber | 9 | 6 |
| Grain | 3 | 0 |
| Hide | 0 | 4 |
| Meat | 0 | 10 |
| Nuts | 3 | 0 |
| Spear | 0 | 4 |
| Stone | 6 | 3 |
| Wood | 17 | 3 |

#### Failures

- **Gather:** not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GOTI | 5 | 0 | 2 | 0 | idle 43%, gather 26%, party 21% |
| HUCA | 2 | 0 | 0 | 4 | idle 59%, gather 40%, wander 1% |
| KUCE | 16 | 1 | 3 | 6 | gather 53%, idle 21%, hunt 11% |
| MUVO | 14 | 0 | 7 | 12 | gather 42%, herd_wildnpc 23%, party 16% |
| QUPA | 10 | 0 | 1 | 0 | craft 49%, herd_wildnpc 47%, eat 3% |
| SIAB | 4 | 0 | 0 | 6 | idle 45%, gather 21%, build_milestone 19% |
| TUOF | 5 | 0 | 0 | 10 | gather 85%, eat 14%, wander 1% |

#### Hunts

- start t=86.6s prey=deer quota=2
- start t=131.6s prey=deer quota=3
- hunt_completed t=129.6s reason=loot_complete
- hunt_completed t=199.6s reason=loot_complete

#### Buildings

- t=52.9s **Living Hut** — herder_hut (builder: MUVO)
- t=157.1s **Drying Rack** — milestone

