# ClanBrain Report (standard)

## Session

- **Duration:** 300.5s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_5min_20260620_112027/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4
- **Simulation ticks:** 2
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| GU TUKA | 0→12 | 8 | 0 | 25.4k | 0.0 | 2 | 2 | 64 | 35 | 5 | 70% | 110.1s | 7 | 1 | 110.4s |
| HI TEXE | 0→15 | 8 | 0 | 31.2k | 0.0 | 2 | 2 | 58 | 40 | 0 | 76% | 100.1s | 7 | 2 | 102.9s |
| JA CALI | 0→7 | 5 | 0 | 14.6k | 0.0 | 2 | 2 | 56 | 45 | 2 | 66% | 85.1s | 4 | 2 | 86.7s |
| WE LIJI | 0→8 | 7 | 0 | 17.2k | 0.0 | 2 | 2 | 69 | 42 | 6 | 79% | 100.1s | 6 | 1 | 103.9s |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 8 / 8
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| GU TUKA | — | — | 70% | 18% | 0→2.2k→0 | 0.0→1.0→0.0 | 110.1s |
| HI TEXE | — | — | 76% | 11% | 0→2.3k→0 | 0.0→1.0→0.0 | 100.1s |
| JA CALI | — | — | 66% | 17% | 0→2.4k→0 | 0.0→1.0→0.0 | 85.1s |
| WE LIJI | — | — | 79% | 10% | 0→3.0k→0 | 0.0→1.0→0.0 | 100.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| GU TUKA | 2 | 2 | 0 | 2 | 0 | 6 | 0 |
| HI TEXE | 2 | 2 | 0 | 2 | 0 | 8 | 0 |
| JA CALI | 2 | 2 | 0 | 2 | 0 | 5 | 0 |
| WE LIJI | 2 | 2 | 0 | 2 | 0 | 7 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| GU TUKA | 1 | 7 | 7 | 107.0s |
| HI TEXE | 2 | 7 | 7 | 98.4s |
| JA CALI | 2 | 4 | 4 | 84.3s |
| WE LIJI | 1 | 6 | 6 | 103.3s |

## Clansmen workforce

- **Unique clansmen seen:** 24 (gather FSM transitions: 98, productivity snapshots: 10)
- **Last snapshot:** clansmen=24 with_job=11 (all workers job %=42.8571428571429)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| GU TUKA | 7 | 7 | 52 | 23 | 7 | 44 | task_failed=29, state_exit_clear_tasks=10, assign_job_supersede=3 |
| HI TEXE | 7 | 7 | 47 | 26 | 10 | 37 | task_failed=22, state_exit_clear_tasks=11, exited_tree=4 |
| JA CALI | 4 | 4 | 40 | 28 | 10 | 78 | task_failed=65, state_exit_clear_tasks=9, assign_job_supersede=2 |
| WE LIJI | 6 | 6 | 50 | 22 | 5 | 47 | task_failed=29, state_exit_clear_tasks=10, exited_tree=4 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BAIY | JA CALI | 17 | 8 | 29 | 9 | 13 | gather 80%, eat 17%, hunt 3% |
| BOIQ | GU TUKA | 8 | 1 | 14 | 3 | 5 | gather 85%, party 5%, idle 5% |
| BOUM | WE LIJI | 10 | 3 | 15 | 1 | 5 | gather 80%, eat 8%, party 6% |
| DAIY | HI TEXE | 10 | 1 | 6 | 0 | 1 | gather 46%, herd_wildnpc 35%, wander 10% |
| DUWO | HI TEXE | 3 | 1 | 5 | 0 | 1 | gather 52%, herd_wildnpc 47%, hunt 0% |
| FOEB | WE LIJI | 8 | 2 | 15 | 2 | 6 | gather 86%, hunt 7%, wander 5% |
| JANI | HI TEXE | 10 | 4 | 32 | 18 | 21 | gather 76%, party 12%, eat 7% |
| KOUM | GU TUKA | 11 | 4 | 27 | 15 | 18 | gather 55%, idle 16%, eat 15% |
| LIET | GU TUKA | 9 | 0 | 9 | 5 | 6 | gather 51%, idle 33%, eat 17% |
| LIIG | JA CALI | 5 | 2 | 13 | 1 | 3 | idle 42%, gather 41%, eat 10% |
| LUUK | GU TUKA | 5 | 0 | 3 | 1 | 2 | gather 88%, eat 12%, wander 0% |
| MIGU | JA CALI | 9 | 0 | 6 | 2 | 2 | gather 62%, idle 27%, eat 10% |
| NEVE | JA CALI | 9 | 0 | 9 | 3 | 4 | gather 59%, idle 31%, wander 10% |
| NIEJ | WE LIJI | 8 | 0 | 7 | 0 | 2 | gather 44%, idle 36%, eat 19% |
| NUUT | HI TEXE | 4 | 0 | 4 | 0 | 2 | gather 59%, build_hut_for_woman 27%, herd_wildnpc 13% |
| PUOV | HI TEXE | 9 | 2 | 9 | 0 | 1 | idle 52%, gather 41%, eat 7% |
| QIEG | GU TUKA | 10 | 2 | 10 | 1 | 4 | gather 89%, party 6%, eat 2% |
| QIER | GU TUKA | 9 | 0 | 8 | 2 | 4 | gather 57%, idle 38%, eat 5% |
| REUC | WE LIJI | 8 | 0 | 6 | 1 | 2 | gather 70%, idle 29%, wander 0% |
| SIUV | HI TEXE | 1 | 0 | 2 | 0 | 1 | gather 100% |
| SUGA | WE LIJI | 7 | 0 | 7 | 2 | 5 | gather 88%, eat 11%, wander 0% |
| XIQI | HI TEXE | 10 | 2 | 13 | 1 | 3 | gather 73%, party 11%, idle 9% |
| ZIIR | GU TUKA | 0 | 0 | 0 | 0 | 1 | gather 100% |
| ZUME | WE LIJI | 9 | 0 | 18 | 12 | 13 | gather 100% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| GU TUKA | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HI TEXE | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| JA CALI | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| WE LIJI | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| GU TUKA | 9 | 0 | 0 | 0 |
| HI TEXE | 6 | 0 | 0 | 0 |
| JA CALI | 2 | 0 | 0 | 0 |
| WE LIJI | 4 | 0 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| GU TUKA | 91 | 29 | 76% | 0 | 5 | gather 65%, idle 10%, eat 7% |
| HI TEXE | 92 | 22 | 81% | 0 | 5 | gather 60%, herd_wildnpc 13%, idle 9% |
| JA CALI | 119 | 65 | 65% | 0 | 3 | gather 59%, idle 16%, eat 7% |
| WE LIJI | 98 | 29 | 77% | 0 | 7 | gather 70%, idle 7%, eat 6% |

## Economy (session)

- **Items gathered:** 247
- **Items deposited:** 162
- **Deposit yield:** 66%
- **Gather failures (all):** 161
- **Gather failures (actionable):** 13
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 16
- **not_harvestable:** 9
- **resource_invalid:** 4

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 15 | 9 | 60% |
| Bone | 0 | 21 | — |
| Fiber | 15 | 0 | 0% |
| Grain | 24 | 9 | 38% |
| Hide | 0 | 28 | — |
| Meat | 0 | 40 | — |
| Mushroom | 1 | 1 | 100% |
| Nuts | 30 | 4 | 13% |
| Spear | 0 | 16 | — |
| Stone | 17 | 1 | 6% |
| Wood | 145 | 33 | 23% |

## Buildings (session)

- **Total placed:** 6

### By type

- **Living Hut:** 6

### By source

- **herder_hut:** 6

### Chronological

- t=51.7s **JA CALI** — Living Hut (herder_hut) builder=FOOM @ (456,2528)
- t=65.9s **HI TEXE** — Living Hut (herder_hut) builder=NIPU @ (-2824,70)
- t=70.8s **WE LIJI** — Living Hut (herder_hut) builder=ZOGU @ (-564,-2589)
- t=74.5s **GU TUKA** — Living Hut (herder_hut) builder=NIEN @ (2490,-1185)
- t=273.1s **HI TEXE** — Living Hut (herder_hut) builder=NUUT @ (-3042,-6)
- t=280.9s **JA CALI** — Living Hut (herder_hut) builder=FOOM @ (273,2386)

## Per-clan detail

### GU TUKA

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 5/5 (70% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.2k → 0
- **Daily calorie need (end):** 25.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 1 |
| Bone | 0 | 4 |
| Fiber | 3 | 0 |
| Grain | 9 | 3 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 1 | 1 |
| Nuts | 11 | 0 |
| Spear | 0 | 4 |
| Stone | 6 | 0 |
| Wood | 31 | 4 |

#### Failures

- **Gather:** inventory_full=24, empty_switch:not_harvestable=3, resource_invalid=3, not_harvestable=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BOIQ | 14 | 3 | 1 | 8 | gather 85%, party 5%, idle 5% |
| KOUM | 27 | 15 | 4 | 11 | gather 55%, idle 16%, eat 15% |
| LIET | 9 | 5 | 0 | 9 | gather 51%, idle 33%, eat 17% |
| LUUK | 3 | 1 | 0 | 5 | gather 88%, eat 12%, wander 0% |
| NIEN | 20 | 2 | 6 | 12 | gather 49%, herd_wildnpc 23%, wander 13% |
| QIEG | 10 | 1 | 2 | 10 | gather 89%, party 6%, eat 2% |
| QIER | 8 | 2 | 0 | 9 | gather 57%, idle 38%, eat 5% |
| ZIIR | 0 | 0 | 0 | 0 | gather 100% |

#### Hunts

- start t=110.4s prey=deer quota=2
- start t=165.4s prey=deer quota=4
- hunt_completed t=161.5s reason=loot_complete
- hunt_completed t=181.5s reason=loot_complete

#### Buildings

- t=74.5s **Living Hut** — herder_hut (builder: NIEN)

### HI TEXE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (76% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.3k → 0
- **Daily calorie need (end):** 31.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 1 |
| Bone | 0 | 6 |
| Fiber | 6 | 0 |
| Grain | 6 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Nuts | 5 | 1 |
| Spear | 0 | 6 |
| Stone | 6 | 0 |
| Wood | 32 | 8 |

#### Failures

- **Gather:** inventory_full=22, empty_switch:not_harvestable=6

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DAIY | 6 | 0 | 1 | 10 | gather 46%, herd_wildnpc 35%, wander 10% |
| DUWO | 5 | 0 | 1 | 3 | gather 52%, herd_wildnpc 47%, hunt 0% |
| JANI | 32 | 18 | 4 | 10 | gather 76%, party 12%, eat 7% |
| NIPU | 21 | 3 | 7 | 11 | gather 57%, herd_wildnpc 14%, wander 12% |
| NUUT | 4 | 0 | 0 | 4 | gather 59%, build_hut_for_woman 27%, herd_wildnpc 13% |
| PUOV | 9 | 0 | 2 | 9 | idle 52%, gather 41%, eat 7% |
| SIUV | 2 | 0 | 0 | 1 | gather 100% |
| XIQI | 13 | 1 | 2 | 10 | gather 73%, party 11%, idle 9% |

#### Hunts

- start t=102.9s prey=deer quota=2
- start t=143.0s prey=deer quota=3
- hunt_completed t=142.0s reason=loot_complete
- hunt_completed t=182.2s reason=loot_complete

#### Buildings

- t=65.9s **Living Hut** — herder_hut (builder: NIPU)
- t=273.1s **Living Hut** — herder_hut (builder: NUUT)

### JA CALI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (66% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.4k → 0
- **Daily calorie need (end):** 14.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 7 |
| Bone | 0 | 5 |
| Fiber | 6 | 0 |
| Hide | 0 | 4 |
| Meat | 0 | 10 |
| Nuts | 6 | 2 |
| Spear | 0 | 3 |
| Stone | 1 | 1 |
| Wood | 34 | 13 |

#### Failures

- **Gather:** inventory_full=63, not_harvestable=2, empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAIY | 29 | 9 | 8 | 17 | gather 80%, eat 17%, hunt 3% |
| FOOM | 62 | 50 | 7 | 16 | gather 58%, build_hut_for_woman 14%, wander 11% |
| LIIG | 13 | 1 | 2 | 5 | idle 42%, gather 41%, eat 10% |
| MIGU | 6 | 2 | 0 | 9 | gather 62%, idle 27%, eat 10% |
| NEVE | 9 | 3 | 0 | 9 | gather 59%, idle 31%, wander 10% |

#### Hunts

- start t=86.7s prey=deer quota=2
- start t=131.7s prey=deer quota=3
- hunt_completed t=126.9s reason=loot_complete
- hunt_completed t=169.7s reason=loot_complete

#### Buildings

- t=51.7s **Living Hut** — herder_hut (builder: FOOM)
- t=280.9s **Living Hut** — herder_hut (builder: FOOM)

### WE LIJI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (79% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 3.0k → 0
- **Daily calorie need (end):** 17.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Grain | 9 | 6 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Nuts | 8 | 1 |
| Spear | 0 | 3 |
| Stone | 4 | 0 |
| Wood | 48 | 8 |

#### Failures

- **Gather:** inventory_full=23, empty_switch:not_harvestable=6, not_harvestable=5, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BOUM | 15 | 1 | 3 | 10 | gather 80%, eat 8%, party 6% |
| FOEB | 15 | 2 | 2 | 8 | gather 86%, hunt 7%, wander 5% |
| NIEJ | 7 | 0 | 0 | 8 | gather 44%, idle 36%, eat 19% |
| REUC | 6 | 1 | 0 | 8 | gather 70%, idle 29%, wander 0% |
| SUGA | 7 | 2 | 0 | 7 | gather 88%, eat 11%, wander 0% |
| ZOGU | 30 | 11 | 10 | 19 | gather 55%, herd_wildnpc 15%, wander 14% |
| ZUME | 18 | 12 | 0 | 9 | gather 100% |

#### Hunts

- start t=103.9s prey=deer quota=2
- start t=148.9s prey=deer quota=3
- hunt_completed t=147.3s reason=loot_complete
- hunt_completed t=177.2s reason=loot_complete

#### Buildings

- t=70.8s **Living Hut** — herder_hut (builder: ZOGU)

