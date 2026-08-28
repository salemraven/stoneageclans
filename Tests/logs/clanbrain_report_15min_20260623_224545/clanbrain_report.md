# ClanBrain Report (standard)

## Session

- **Duration:** 900.8s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_15min_20260623_224545/playtest_session.jsonl`
- **World seed:** 0
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 6
- **Simulation ticks:** 3
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 6/6 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| CE VIUN | 0→6 | 1 | 0 | 11.8k | 0.0 | 1 | 0 | 19 | 12 | 0 | 68% | 893.9s | 0 | 2 | 6.9s |
| CU BUAB | 0→1 | 1 | 0 | 2.2k | 0.0 | 1 | 0 | 0 | 1 | 0 | 50% | 899.7s | 0 | 0 | 1.1s |
| FU NEIV | 0→9 | 3 | 0 | 18.4k | 0.0 | 0 | 0 | 45 | 16 | 7 | 85% | 419.5s | 2 | 1 | — |
| HI MAIP | 0→24 | 14 | 0 | 50.0k | 0.0 | 1 | 0 | 175 | 115 | 3 | 70% | 267.4s | 13 | 4 | 4.3s |
| KA PAHE | 0→12 | 8 | 0 | 25.0k | 0.0 | 0 | 0 | 78 | 32 | 5 | 86% | 227.2s | 7 | 2 | — |
| QE LIOY | 0→17 | 4 | 0 | 34.6k | 0.0 | 0 | 0 | 41 | 24 | 4 | 84% | 471.8s | 3 | 1 | — |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| CE VIUN | — | — | 68% | 38% | 0→200→0 | 0.0→1.0→0.0 | 893.9s |
| CU BUAB | — | — | 50% | 50% | 0→200→0 | 0.0→1.0→0.0 | 899.7s |
| FU NEIV | — | — | 85% | 16% | 0→200→0 | 0.0→1.0→0.0 | 419.5s |
| HI MAIP | — | — | 70% | 69% | 0→440→0 | 0.0→1.0→0.0 | 267.4s |
| KA PAHE | — | — | 86% | 18% | 0→380→0 | 0.0→1.0→0.0 | 227.2s |
| QE LIOY | — | — | 84% | 8% | 0→200→0 | 0.0→1.0→0.0 | 471.8s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| CE VIUN | 1 | 0 | 1 | 0 | 0 | 0 | 0 |
| CU BUAB | 1 | 0 | 1 | 0 | 0 | 0 | 0 |
| FU NEIV | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HI MAIP | 1 | 0 | 1 | 0 | 0 | 0 | 0 |
| KA PAHE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE LIOY | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| CE VIUN | 2 | 0 | 0 | — |
| CU BUAB | 0 | 0 | 0 | — |
| FU NEIV | 1 | 2 | 2 | 416.2s |
| HI MAIP | 4 | 13 | 13 | 264.1s |
| KA PAHE | 3 | 7 | 7 | 234.7s |
| QE LIOY | 1 | 3 | 3 | 471.8s |

## Clansmen workforce

- **Unique clansmen seen:** 25 (gather FSM transitions: 183, productivity snapshots: 15)
- **Last snapshot:** clansmen=22 with_job=5 (all workers job %=28.5714285714286)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| CE VIUN | 0 | 0 | 0 | 0 | 0 | 0 | — |
| CU BUAB | 0 | 0 | 0 | 0 | 0 | 0 | — |
| FU NEIV | 2 | 2 | 25 | 0 | 0 | 22 | resource_node_invalid=8, state_exit_clear_tasks=7, task_failed=7 |
| HI MAIP | 13 | 13 | 149 | 92 | 21 | 54 | state_exit_clear_tasks=20, resource_node_invalid=10, task_failed=10 |
| KA PAHE | 7 | 7 | 52 | 11 | 4 | 44 | resource_node_invalid=17, state_exit_clear_tasks=16, task_failed=8 |
| QE LIOY | 3 | 3 | 24 | 7 | 3 | 13 | state_exit_clear_tasks=6, task_failed=4, exited_tree=1 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BUSO | KA PAHE | 4 | 0 | 2 | 0 | 2 | idle 73%, gather 26%, eat 1% |
| CAUX | HI MAIP | 20 | 4 | 20 | 2 | 6 | gather 50%, craft 19%, idle 12% |
| DOIN | HI MAIP | 8 | 0 | 5 | 0 | 1 | idle 43%, gather 29%, build_hut_for_woman 11% |
| GEID | HI MAIP | 3 | 0 | 3 | 0 | 2 | gather 96%, wander 2%, idle 1% |
| GIOQ | QE LIOY | 7 | 1 | 3 | 0 | 1 | idle 68%, gather 26%, wander 3% |
| GUYU | KA PAHE | 10 | 0 | 4 | 1 | 4 | gather 47%, idle 45%, eat 4% |
| JEAG | HI MAIP | 11 | 1 | 7 | 0 | 3 | gather 64%, herd_wildnpc 12%, build_hut_for_woman 10% |
| JOQA | HI MAIP | 19 | 3 | 25 | 0 | 7 | gather 48%, craft 33%, build_milestone 11% |
| JUIY | FU NEIV | 12 | 0 | 9 | 1 | 6 | gather 77%, wander 9%, idle 7% |
| KAVE | QE LIOY | 5 | 1 | 2 | 0 | 0 | idle 58%, gather 41%, wander 1% |
| LUBA | KA PAHE | 9 | 1 | 13 | 1 | 11 | gather 71%, herd_wildnpc 14%, wander 10% |
| MELI | KA PAHE | 8 | 1 | 12 | 2 | 10 | gather 62%, idle 13%, build_hut_for_woman 12% |
| NAEW | HI MAIP | 19 | 5 | 22 | 2 | 8 | gather 40%, craft 29%, herd_wildnpc 14% |
| NIZU | HI MAIP | 22 | 3 | 13 | 1 | 6 | gather 64%, herd_wildnpc 13%, eat 12% |
| PEYU | HI MAIP | 1 | 1 | 1 | 1 | 2 | gather 100% |
| QAPU | KA PAHE | 7 | 2 | 20 | 2 | 6 | craft 40%, gather 33%, idle 21% |
| QULE | FU NEIV | 13 | 0 | 10 | 3 | 7 | gather 71%, idle 18%, eat 10% |
| SOIG | KA PAHE | 9 | 0 | 5 | 2 | 3 | idle 60%, gather 17%, craft 14% |
| TETE | HI MAIP | 4 | 0 | 1 | 0 | 1 | gather 100% |
| VOAX | HI MAIP | 20 | 2 | 13 | 0 | 3 | gather 55%, eat 13%, wander 11% |
| XEIS | HI MAIP | 12 | 1 | 17 | 3 | 9 | gather 45%, craft 31%, idle 16% |
| YEUV | HI MAIP | 7 | 0 | 2 | 0 | 2 | gather 87%, idle 11%, wander 2% |
| YOAR | HI MAIP | 3 | 1 | 2 | 0 | 1 | gather 100% |
| ZIET | KA PAHE | 5 | 0 | 2 | 0 | 2 | idle 61%, gather 32%, wander 7% |
| ZIUR | QE LIOY | 12 | 1 | 7 | 2 | 6 | gather 67%, idle 19%, wander 8% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| CE VIUN | 31 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| CU BUAB | 31 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| FU NEIV | 31 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HI MAIP | 31 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KA PAHE | 31 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE LIOY | 31 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| CE VIUN | 0 | 0 | 0 | 0 |
| CU BUAB | 0 | 0 | 0 | 0 |
| FU NEIV | 0 | 0 | 0 | 0 |
| HI MAIP | 1 | 1 | 0 | 0 |
| KA PAHE | 0 | 0 | 0 | 0 |
| QE LIOY | 0 | 0 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| CE VIUN | 12 | 0 | 100% | 0 | 0 | herd_wildnpc 29%, wander 25%, hunt 19% |
| CU BUAB | 0 | 0 | — | 0 | 2 | hunt 51%, wander 46%, eat 3% |
| FU NEIV | 33 | 7 | 82% | 0 | 13 | gather 59%, herd_wildnpc 15%, wander 11% |
| HI MAIP | 159 | 10 | 94% | 0 | 26 | gather 48%, craft 16%, wander 8% |
| KA PAHE | 81 | 8 | 91% | 0 | 30 | gather 44%, idle 29%, craft 9% |
| QE LIOY | 19 | 4 | 83% | 0 | 6 | gather 38%, idle 24%, herd_wildnpc 20% |

## Economy (session)

- **Items gathered:** 358
- **Items deposited:** 200
- **Deposit yield:** 56%
- **Gather failures (all):** 22
- **Gather failures (actionable):** 19
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 17
- **empty_switch:not_harvestable:** 3
- **moved_during_gather:** 1
- **not_harvestable:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 22 | 5 | 23% |
| Fiber | 30 | 18 | 60% |
| Grain | 36 | 14 | 39% |
| Mushroom | 37 | 11 | 30% |
| Nuts | 32 | 12 | 38% |
| Spear | 0 | 21 | — |
| Stone | 70 | 55 | 79% |
| Wood | 131 | 64 | 49% |

## Buildings (session)

- **Total placed:** 10

### By type

- **Living Hut:** 10

### By source

- **herder_hut:** 10

### Chronological

- t=170.9s **KA PAHE** — Living Hut (herder_hut) builder=BIFO @ (-2680,1024)
- t=199.8s **HI MAIP** — Living Hut (herder_hut) builder=YOUW @ (2101,540)
- t=350.6s **FU NEIV** — Living Hut (herder_hut) builder=ZEGI @ (4902,-846)
- t=404.5s **QE LIOY** — Living Hut (herder_hut) builder=VUXE @ (-1367,2875)
- t=645.7s **HI MAIP** — Living Hut (herder_hut) builder=DOIN @ (2055,608)
- t=718.8s **HI MAIP** — Living Hut (herder_hut) builder=VOAX @ (1864,507)
- t=721.1s **CE VIUN** — Living Hut (herder_hut) builder=MECI @ (-374,-3617)
- t=756.5s **CE VIUN** — Living Hut (herder_hut) builder=MECI @ (-533,-3797)
- t=814.7s **HI MAIP** — Living Hut (herder_hut) builder=JEAG @ (1879,454)
- t=888.3s **KA PAHE** — Living Hut (herder_hut) builder=MELI @ (-2450,1072)

## Per-clan detail

### CE VIUN

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (68% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 11.8k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Fiber | 3 | 3 |
| Grain | 3 | 0 |
| Nuts | 2 | 2 |
| Spear | 0 | 1 |
| Stone | 5 | 3 |
| Wood | 3 | 3 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| MECI | 12 | 0 | 4 | 19 | herd_wildnpc 29%, wander 25%, hunt 19% |

#### Hunts

- start t=6.9s prey=deer quota=1
- hunt_aborted t=180.1s reason=prey_invalid_killing

#### Buildings

- t=721.1s **Living Hut** — herder_hut (builder: MECI)
- t=756.5s **Living Hut** — herder_hut (builder: MECI)

### CU BUAB

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (50% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 2.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| PIIY | 0 | 0 | 1 | 0 | hunt 51%, wander 46%, eat 3% |

#### Hunts

- start t=1.1s prey=deer quota=1
- hunt_aborted t=468.9s reason=prey_invalid_killing

### FU NEIV

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/1 (85% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 18.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 4 | 0 |
| Fiber | 6 | 3 |
| Grain | 6 | 0 |
| Mushroom | 9 | 0 |
| Nuts | 3 | 0 |
| Spear | 0 | 1 |
| Stone | 4 | 3 |
| Wood | 13 | 9 |

#### Failures

- **Gather:** resource_invalid=7

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| JUIY | 9 | 1 | 0 | 12 | gather 77%, wander 9%, idle 7% |
| QULE | 10 | 3 | 0 | 13 | gather 71%, idle 18%, eat 10% |
| ZEGI | 14 | 3 | 5 | 20 | gather 44%, herd_wildnpc 32%, wander 17% |

#### Buildings

- t=350.6s **Living Hut** — herder_hut (builder: ZEGI)

### HI MAIP

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (70% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 440 → 0
- **Daily calorie need (end):** 50.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 15 | 5 |
| Fiber | 21 | 12 |
| Grain | 27 | 14 |
| Mushroom | 11 | 2 |
| Nuts | 13 | 9 |
| Spear | 0 | 10 |
| Stone | 36 | 32 |
| Wood | 52 | 31 |

#### Failures

- **Gather:** empty_switch:not_harvestable=2, moved_during_gather=1, not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CAUX | 20 | 2 | 4 | 20 | gather 50%, craft 19%, idle 12% |
| DOIN | 5 | 0 | 0 | 8 | idle 43%, gather 29%, build_hut_for_woman 11% |
| GEID | 3 | 0 | 0 | 3 | gather 96%, wander 2%, idle 1% |
| JEAG | 7 | 0 | 1 | 11 | gather 64%, herd_wildnpc 12%, build_hut_for_woman 10% |
| JOQA | 25 | 0 | 3 | 19 | gather 48%, craft 33%, build_milestone 11% |
| NAEW | 22 | 2 | 5 | 19 | gather 40%, craft 29%, herd_wildnpc 14% |
| NIZU | 13 | 1 | 3 | 22 | gather 64%, herd_wildnpc 13%, eat 12% |
| PEYU | 1 | 1 | 1 | 1 | gather 100% |
| TETE | 1 | 0 | 0 | 4 | gather 100% |
| VOAX | 13 | 0 | 2 | 20 | gather 55%, eat 13%, wander 11% |
| XEIS | 17 | 3 | 1 | 12 | gather 45%, craft 31%, idle 16% |
| YEUV | 2 | 0 | 0 | 7 | gather 87%, idle 11%, wander 2% |
| YOAR | 2 | 0 | 1 | 3 | gather 100% |
| YOUW | 28 | 1 | 7 | 26 | gather 31%, craft 22%, hunt 15% |

#### Hunts

- start t=4.3s prey=deer quota=1
- hunt_aborted t=272.0s reason=recruitment_timeout

#### Buildings

- t=199.8s **Living Hut** — herder_hut (builder: YOUW)
- t=645.7s **Living Hut** — herder_hut (builder: DOIN)
- t=718.8s **Living Hut** — herder_hut (builder: VOAX)
- t=814.7s **Living Hut** — herder_hut (builder: JEAG)

### KA PAHE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (86% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 380 → 0
- **Daily calorie need (end):** 25.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Mushroom | 11 | 6 |
| Nuts | 9 | 1 |
| Spear | 0 | 4 |
| Stone | 18 | 10 |
| Wood | 40 | 11 |

#### Failures

- **Gather:** resource_invalid=5, empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIFO | 23 | 0 | 8 | 26 | gather 50%, wander 20%, herd_wildnpc 11% |
| BUSO | 2 | 0 | 0 | 4 | idle 73%, gather 26%, eat 1% |
| GUYU | 4 | 1 | 0 | 10 | gather 47%, idle 45%, eat 4% |
| LUBA | 13 | 1 | 1 | 9 | gather 71%, herd_wildnpc 14%, wander 10% |
| MELI | 12 | 2 | 1 | 8 | gather 62%, idle 13%, build_hut_for_woman 12% |
| QAPU | 20 | 2 | 2 | 7 | craft 40%, gather 33%, idle 21% |
| SOIG | 5 | 2 | 0 | 9 | idle 60%, gather 17%, craft 14% |
| ZIET | 2 | 0 | 0 | 5 | idle 61%, gather 32%, wander 7% |

#### Buildings

- t=170.9s **Living Hut** — herder_hut (builder: BIFO)
- t=888.3s **Living Hut** — herder_hut (builder: MELI)

### QE LIOY

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (84% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 34.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Mushroom | 6 | 3 |
| Nuts | 5 | 0 |
| Spear | 0 | 4 |
| Stone | 7 | 7 |
| Wood | 23 | 10 |

#### Failures

- **Gather:** resource_invalid=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GIOQ | 3 | 0 | 1 | 7 | idle 68%, gather 26%, wander 3% |
| KAVE | 2 | 0 | 1 | 5 | idle 58%, gather 41%, wander 1% |
| VUXE | 7 | 2 | 6 | 17 | herd_wildnpc 42%, gather 31%, wander 18% |
| ZIUR | 7 | 2 | 1 | 12 | gather 67%, idle 19%, wander 8% |

#### Buildings

- t=404.5s **Living Hut** — herder_hut (builder: VUXE)

