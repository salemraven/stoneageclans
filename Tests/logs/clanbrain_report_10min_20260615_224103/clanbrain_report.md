# ClanBrain Report (standard)

## Session

- **Duration:** 600.5s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_10min_20260615_224103/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 10 min
- **AI clans with eval:** 4
- **Simulation ticks:** 4
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| FA VAOL | 0→10 | 8 | 0 | 21.4k | 0.0 | 2 | 2 | 143 | 87 | 5 | 93% | 75.1s | 7 | 1 | 75.8s |
| NA ZEPU | 0→16 | 11 | 0 | 33.4k | 0.0 | 2 | 2 | 141 | 41 | 6 | 88% | 180.2s | 11 | 4 | 180.5s |
| PE MIAQ | 0→14 | 7 | 0 | 29.0k | 0.0 | 3 | 2 | 101 | 47 | 2 | 87% | 70.1s | 6 | 2 | 74.3s |
| XE DUUV | 0→11 | 5 | 0 | 22.4k | 0.0 | 2 | 2 | 63 | 53 | 1 | 89% | 90.1s | 4 | 3 | 91.7s |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 9 / 9
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| FA VAOL | — | — | 93% | 20% | 0→2.2k→0 | 0.0→1.0→0.0 | 75.1s |
| NA ZEPU | — | — | 88% | 8% | 0→2.7k→0 | 0.0→1.0→0.0 | 180.2s |
| PE MIAQ | — | — | 87% | 33% | 0→1.4k→0 | 0.0→1.0→0.0 | 70.1s |
| XE DUUV | — | — | 89% | 12% | 0→2.2k→0 | 0.0→1.0→0.0 | 90.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| FA VAOL | 2 | 2 | 0 | 2 | 0 | 7 | 0 |
| NA ZEPU | 2 | 2 | 0 | 2 | 0 | 7 | 0 |
| PE MIAQ | 3 | 2 | 1 | 2 | 0 | 6 | 0 |
| XE DUUV | 2 | 2 | 0 | 2 | 0 | 5 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| FA VAOL | 1 | 7 | 7 | 75.6s |
| NA ZEPU | 4 | 11 | 11 | 179.6s |
| PE MIAQ | 2 | 6 | 6 | 72.5s |
| XE DUUV | 3 | 4 | 4 | 91.1s |

## Clansmen workforce

- **Unique clansmen seen:** 28 (gather FSM transitions: 188, productivity snapshots: 19)
- **Last snapshot:** clansmen=27 with_job=0 (all workers job %=6.45161290322581)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| FA VAOL | 7 | 7 | 95 | 43 | 9 | 112 | task_failed=93, state_exit_clear_tasks=11, assign_job_supersede=7 |
| NA ZEPU | 11 | 11 | 121 | 28 | 10 | 78 | task_failed=41, state_exit_clear_tasks=25, assign_job_supersede=6 |
| PE MIAQ | 6 | 6 | 89 | 43 | 9 | 292 | task_failed=262, assign_job_supersede=16, state_exit_clear_tasks=13 |
| XE DUUV | 4 | 4 | 36 | 27 | 7 | 135 | task_failed=120, state_exit_clear_tasks=8, resource_node_invalid=4 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BAAG | NA ZEPU | 9 | 0 | 15 | 8 | 9 | flee_combat 72%, gather 18%, idle 8% |
| BONO | XE DUUV | 10 | 1 | 22 | 12 | 16 | idle 65%, gather 30%, eat 4% |
| BUIV | NA ZEPU | 9 | 0 | 7 | 1 | 2 | idle 82%, gather 17%, eat 1% |
| DAOR | NA ZEPU | 13 | 1 | 21 | 9 | 11 | idle 64%, gather 32%, eat 4% |
| DIUB | FA VAOL | 37 | 4 | 36 | 4 | 9 | gather 60%, idle 30%, eat 5% |
| GELE | NA ZEPU | 10 | 3 | 15 | 1 | 6 | idle 57%, gather 36%, eat 3% |
| GILE | NA ZEPU | 15 | 1 | 12 | 0 | 4 | gather 49%, idle 47%, eat 4% |
| GIUG | NA ZEPU | 12 | 2 | 13 | 1 | 7 | gather 47%, idle 44%, eat 3% |
| LOAX | FA VAOL | 8 | 0 | 8 | 1 | 2 | idle 84%, gather 15%, eat 1% |
| MUHI | NA ZEPU | 10 | 0 | 8 | 2 | 3 | idle 63%, gather 34%, eat 2% |
| NEVA | PE MIAQ | 12 | 3 | 18 | 3 | 8 | idle 34%, gather 32%, party 30% |
| PEET | PE MIAQ | 10 | 1 | 11 | 1 | 3 | combat 26%, hunt 24%, idle 19% |
| PUVO | NA ZEPU | 8 | 0 | 5 | 1 | 4 | idle 65%, gather 33%, eat 1% |
| QIIX | FA VAOL | 9 | 0 | 11 | 7 | 7 | idle 80%, gather 13%, eat 4% |
| QOOH | XE DUUV | 6 | 0 | 6 | 0 | 3 | idle 74%, gather 16%, build_hut_for_woman 6% |
| QUMA | NA ZEPU | 14 | 0 | 9 | 3 | 6 | idle 58%, gather 37%, eat 5% |
| TUUL | XE DUUV | 10 | 5 | 28 | 8 | 10 | idle 61%, gather 31%, eat 3% |
| VEAF | NA ZEPU | 8 | 2 | 9 | 0 | 3 | idle 68%, gather 23%, eat 4% |
| VONE | PE MIAQ | 16 | 0 | 71 | 57 | 61 | idle 61%, gather 34%, eat 5% |
| VUGU | FA VAOL | 9 | 0 | 23 | 17 | 18 | idle 74%, gather 26%, wander 0% |
| VUUR | PE MIAQ | 26 | 4 | 114 | 90 | 97 | gather 37%, idle 28%, combat 19% |
| VUWU | XE DUUV | 10 | 1 | 7 | 0 | 3 | idle 66%, gather 17%, build_hut_for_woman 10% |
| WEOS | FA VAOL | 13 | 1 | 30 | 20 | 22 | idle 62%, gather 36%, eat 2% |
| YIZO | NA ZEPU | 13 | 1 | 9 | 0 | 3 | idle 56%, gather 36%, eat 5% |
| YOPA | FA VAOL | 9 | 0 | 8 | 2 | 2 | idle 84%, gather 14%, eat 2% |
| ZOAB | PE MIAQ | 14 | 1 | 21 | 11 | 13 | idle 62%, gather 25%, party 6% |
| ZUBU | PE MIAQ | 11 | 0 | 49 | 41 | 42 | idle 38%, combat 27%, gather 26% |
| ZUMU | FA VAOL | 10 | 4 | 18 | 1 | 4 | idle 69%, gather 21%, eat 4% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| FA VAOL | 35 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| NA ZEPU | 28 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| PE MIAQ | 35 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| XE DUUV | 34 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| FA VAOL | 7 | 0 | 0 | 0 |
| NA ZEPU | 6 | 0 | 0 | 0 |
| PE MIAQ | 10 | 0 | 0 | 0 |
| XE DUUV | 7 | 0 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| FA VAOL | 221 | 93 | 70% | 0 | 8 | idle 56%, gather 33%, herd_wildnpc 3% |
| NA ZEPU | 157 | 41 | 79% | 0 | 23 | idle 49%, gather 34%, flee_combat 5% |
| PE MIAQ | 359 | 262 | 58% | 0 | 8 | idle 33%, gather 27%, combat 13% |
| XE DUUV | 187 | 120 | 61% | 0 | 6 | idle 48%, gather 33%, wander 7% |

## Economy (session)

- **Items gathered:** 448
- **Items deposited:** 228
- **Deposit yield:** 51%
- **Gather failures (all):** 533
- **Gather failures (actionable):** 14
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 17
- **not_harvestable:** 10
- **resource_invalid:** 4

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 22 | 0 | 0% |
| Bone | 0 | 24 | — |
| Fiber | 36 | 21 | 58% |
| Grain | 34 | 3 | 9% |
| Hide | 0 | 32 | — |
| Meat | 0 | 40 | — |
| Mushroom | 3 | 0 | 0% |
| Nuts | 60 | 3 | 5% |
| Spear | 0 | 20 | — |
| Stone | 34 | 6 | 18% |
| Wood | 259 | 79 | 31% |

## Buildings (session)

- **Total placed:** 10

### By type

- **Living Hut:** 10

### By source

- **herder_hut:** 10

### Chronological

- t=40.0s **PE MIAQ** — Living Hut (herder_hut) builder=TOIT @ (1892,642)
- t=43.1s **FA VAOL** — Living Hut (herder_hut) builder=NUBU @ (-593,-2385)
- t=58.6s **XE DUUV** — Living Hut (herder_hut) builder=COIQ @ (-3146,727)
- t=101.6s **PE MIAQ** — Living Hut (herder_hut) builder=TOIT @ (1681,529)
- t=147.1s **NA ZEPU** — Living Hut (herder_hut) builder=XIIG @ (990,3530)
- t=167.1s **NA ZEPU** — Living Hut (herder_hut) builder=XIIG @ (785,3410)
- t=206.9s **NA ZEPU** — Living Hut (herder_hut) builder=XIIG @ (836,3352)
- t=345.5s **XE DUUV** — Living Hut (herder_hut) builder=QOOH @ (-3367,643)
- t=432.0s **NA ZEPU** — Living Hut (herder_hut) builder=XIIG @ (1016,3461)
- t=456.7s **XE DUUV** — Living Hut (herder_hut) builder=VUWU @ (-3202,806)

## Per-clan detail

### FA VAOL

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (93% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.2k → 0
- **Daily calorie need (end):** 21.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 0 |
| Bone | 0 | 6 |
| Fiber | 18 | 12 |
| Grain | 3 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Nuts | 21 | 3 |
| Spear | 0 | 4 |
| Stone | 6 | 0 |
| Wood | 89 | 44 |

#### Failures

- **Gather:** inventory_full=88, not_harvestable=5, empty_switch:not_harvestable=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DIUB | 36 | 4 | 4 | 37 | gather 60%, idle 30%, eat 5% |
| LOAX | 8 | 1 | 0 | 8 | idle 84%, gather 15%, eat 1% |
| NUBU | 87 | 41 | 13 | 48 | gather 63%, herd_wildnpc 15%, wander 13% |
| QIIX | 11 | 7 | 0 | 9 | idle 80%, gather 13%, eat 4% |
| VUGU | 23 | 17 | 0 | 9 | idle 74%, gather 26%, wander 0% |
| WEOS | 30 | 20 | 1 | 13 | idle 62%, gather 36%, eat 2% |
| YOPA | 8 | 2 | 0 | 9 | idle 84%, gather 14%, eat 2% |
| ZUMU | 18 | 1 | 4 | 10 | idle 69%, gather 21%, eat 4% |

#### Hunts

- start t=75.8s prey=deer quota=2
- start t=115.9s prey=deer quota=2
- hunt_completed t=115.5s reason=loot_complete
- hunt_completed t=163.4s reason=loot_complete

#### Buildings

- t=43.1s **Living Hut** — herder_hut (builder: NUBU)

### NA ZEPU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (88% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.7k → 0
- **Daily calorie need (end):** 33.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 10 | 0 |
| Bone | 0 | 6 |
| Fiber | 6 | 0 |
| Grain | 15 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 1 | 0 |
| Nuts | 20 | 0 |
| Spear | 0 | 7 |
| Stone | 15 | 2 |
| Wood | 74 | 8 |

#### Failures

- **Gather:** inventory_full=35, empty_switch:not_harvestable=11, not_harvestable=4, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAAG | 15 | 8 | 0 | 9 | flee_combat 72%, gather 18%, idle 8% |
| BUIV | 7 | 1 | 0 | 9 | idle 82%, gather 17%, eat 1% |
| DAOR | 21 | 9 | 1 | 13 | idle 64%, gather 32%, eat 4% |
| GELE | 15 | 1 | 3 | 10 | idle 57%, gather 36%, eat 3% |
| GILE | 12 | 0 | 1 | 15 | gather 49%, idle 47%, eat 4% |
| GIUG | 13 | 1 | 2 | 12 | gather 47%, idle 44%, eat 3% |
| MUHI | 8 | 2 | 0 | 10 | idle 63%, gather 34%, eat 2% |
| PUVO | 5 | 1 | 0 | 8 | idle 65%, gather 33%, eat 1% |
| QUMA | 9 | 3 | 0 | 14 | idle 58%, gather 37%, eat 5% |
| VEAF | 9 | 0 | 2 | 8 | idle 68%, gather 23%, eat 4% |
| XIIG | 34 | 15 | 4 | 20 | gather 41%, wander 26%, build_hut_for_woman 16% |
| YIZO | 9 | 0 | 1 | 13 | idle 56%, gather 36%, eat 5% |

#### Hunts

- start t=180.5s prey=deer quota=2
- start t=215.5s prey=deer quota=4
- hunt_completed t=215.2s reason=loot_complete
- hunt_completed t=235.7s reason=loot_complete

#### Buildings

- t=147.1s **Living Hut** — herder_hut (builder: XIIG)
- t=167.1s **Living Hut** — herder_hut (builder: XIIG)
- t=206.9s **Living Hut** — herder_hut (builder: XIIG)
- t=432.0s **Living Hut** — herder_hut (builder: XIIG)

### PE MIAQ

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (87% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.4k → 0
- **Daily calorie need (end):** 29.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 0 |
| Bone | 0 | 6 |
| Grain | 15 | 3 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Nuts | 14 | 0 |
| Spear | 0 | 5 |
| Stone | 10 | 4 |
| Wood | 56 | 11 |

#### Failures

- **Gather:** inventory_full=260, empty_switch:not_harvestable=2, not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| NEVA | 18 | 3 | 3 | 12 | idle 34%, gather 32%, party 30% |
| PEET | 11 | 1 | 1 | 10 | combat 26%, hunt 24%, idle 19% |
| TOIT | 75 | 59 | 2 | 12 | agro 40%, gather 18%, combat 16% |
| VONE | 71 | 57 | 0 | 16 | idle 61%, gather 34%, eat 5% |
| VUUR | 114 | 90 | 4 | 26 | gather 37%, idle 28%, combat 19% |
| ZOAB | 21 | 11 | 1 | 14 | idle 62%, gather 25%, party 6% |
| ZUBU | 49 | 41 | 0 | 11 | idle 38%, combat 27%, gather 26% |

#### Hunts

- start t=74.3s prey=deer quota=2
- start t=119.3s prey=deer quota=3
- start t=274.7s prey=deer quota=4
- hunt_completed t=114.7s reason=loot_complete
- hunt_aborted t=239.3s reason=active_timeout
- hunt_completed t=352.5s reason=loot_complete

#### Buildings

- t=40.0s **Living Hut** — herder_hut (builder: TOIT)
- t=101.6s **Living Hut** — herder_hut (builder: TOIT)

### XE DUUV

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (89% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.2k → 0
- **Daily calorie need (end):** 22.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Fiber | 12 | 9 |
| Grain | 1 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 2 | 0 |
| Nuts | 5 | 0 |
| Spear | 0 | 4 |
| Stone | 3 | 0 |
| Wood | 40 | 16 |

#### Failures

- **Gather:** inventory_full=119, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BONO | 22 | 12 | 1 | 10 | idle 65%, gather 30%, eat 4% |
| COIQ | 124 | 100 | 7 | 27 | gather 57%, wander 20%, herd_wildnpc 14% |
| QOOH | 6 | 0 | 0 | 6 | idle 74%, gather 16%, build_hut_for_woman 6% |
| TUUL | 28 | 8 | 5 | 10 | idle 61%, gather 31%, eat 3% |
| VUWU | 7 | 0 | 1 | 10 | idle 66%, gather 17%, build_hut_for_woman 10% |

#### Hunts

- start t=91.7s prey=deer quota=2
- start t=161.7s prey=deer quota=2
- hunt_completed t=160.2s reason=loot_complete
- hunt_completed t=213.6s reason=loot_complete

#### Buildings

- t=58.6s **Living Hut** — herder_hut (builder: COIQ)
- t=345.5s **Living Hut** — herder_hut (builder: QOOH)
- t=456.7s **Living Hut** — herder_hut (builder: VUWU)

