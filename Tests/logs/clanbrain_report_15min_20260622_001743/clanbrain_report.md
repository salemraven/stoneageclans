# ClanBrain Report (standard)

## Session

- **Duration:** 901.0s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_15min_20260622_001743/playtest_session.jsonl`
- **World seed:** 0
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 7
- **Simulation ticks:** 3
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 7/7 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| CE VIUN | 0→11 | 7 | 0 | 23.2k | 0.0 | 0 | 0 | 99 | 52 | 2 | 89% | 479.0s | 6 | 1 | — |
| CU BUAB | 0→10 | 9 | 0 | 21.6k | 0.0 | 0 | 0 | 202 | 155 | 0 | 88% | 172.4s | 10 | 1 | — |
| FU NEIV | 0→7 | 1 | 200 | 14.2k | 0.0 | 0 | 0 | 0 | 1 | 0 | 77% | 892.0s | 0 | 0 | — |
| HI MAIP | 0→11 | 5 | 660 | 23.4k | 0.0 | 0 | 0 | 83 | 69 | 1 | 90% | 203.9s | 5 | 1 | — |
| KA PAHE | 0→11 | 6 | 0 | 23.0k | 0.0 | 0 | 0 | 65 | 42 | 4 | 89% | 162.1s | 5 | 1 | — |
| KI LISO | 0→1 | 1 | 200 | 2.2k | 0.1 | 0 | 0 | 0 | 1 | 0 | 83% | 47.3s | 0 | 0 | — |
| QE LIOY | 0→18 | 6 | 0 | 36.6k | 0.0 | 0 | 0 | 92 | 59 | 4 | 81% | 183.1s | 5 | 3 | — |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| CE VIUN | — | — | 89% | 11% | 0→380→0 | 0.0→1.0→0.0 | 479.0s |
| CU BUAB | — | — | 88% | 17% | 0→460→0 | 0.0→1.0→0.0 | 172.4s |
| FU NEIV | — | — | 77% | 23% | 200→200→200 | 0.0→1.0→0.0 | 892.0s |
| HI MAIP | 93% | 7% | 87% | 11% | 0→660→660 | 0.0→1.0→0.0 | 203.9s |
| KA PAHE | — | — | 89% | 20% | 0→240→0 | 0.0→1.0→0.0 | 162.1s |
| KI LISO | — | — | 83% | 17% | 200→200→200 | 0.1→1.0→0.1 | 47.3s |
| QE LIOY | — | — | 81% | 14% | 0→200→0 | 0.0→1.0→0.0 | 183.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| CE VIUN | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| CU BUAB | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| FU NEIV | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HI MAIP | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KA PAHE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KI LISO | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE LIOY | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| CE VIUN | 1 | 6 | 6 | 481.3s |
| CU BUAB | 1 | 10 | 10 | 166.6s |
| FU NEIV | 0 | 0 | 0 | — |
| HI MAIP | 1 | 6 | 5 | 200.9s |
| KA PAHE | 1 | 5 | 5 | 163.9s |
| KI LISO | 0 | 0 | 0 | — |
| QE LIOY | 3 | 5 | 5 | 177.8s |

## Clansmen workforce

- **Unique clansmen seen:** 31 (gather FSM transitions: 244, productivity snapshots: 15)
- **Last snapshot:** clansmen=23 with_job=8 (all workers job %=37.9310344827586)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| CE VIUN | 6 | 6 | 66 | 18 | 5 | 11 | state_exit_clear_tasks=6, should_abort_work=3, task_failed=2 |
| CU BUAB | 10 | 10 | 145 | 99 | 27 | 30 | state_exit_clear_tasks=17, resource_node_invalid=4, exited_tree=3 |
| FU NEIV | 0 | 0 | 0 | 0 | 0 | 0 | — |
| HI MAIP | 5 | 5 | 45 | 32 | 6 | 24 | state_exit_clear_tasks=10, exited_tree=4, should_abort_work=4 |
| KA PAHE | 5 | 5 | 44 | 23 | 5 | 32 | state_exit_clear_tasks=12, resource_node_invalid=8, gather_lease_expired=5 |
| KI LISO | 0 | 0 | 0 | 0 | 0 | 0 | — |
| QE LIOY | 5 | 5 | 57 | 27 | 6 | 35 | state_exit_clear_tasks=15, resource_node_invalid=9, task_failed=6 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| CUEM | HI MAIP | 6 | 1 | 6 | 0 | 1 | idle 82%, craft 10%, gather 6% |
| DEZO | QE LIOY | 9 | 1 | 6 | 0 | 3 | idle 44%, gather 23%, herd_wildnpc 19% |
| DUJI | CE VIUN | 13 | 1 | 9 | 1 | 2 | gather 52%, idle 34%, eat 13% |
| DUUH | HI MAIP | 15 | 2 | 7 | 0 | 9 | gather 50%, idle 22%, defend 10% |
| FACI | KA PAHE | 6 | 0 | 3 | 1 | 2 | gather 92%, idle 6%, wander 3% |
| GAUN | HI MAIP | 5 | 0 | 6 | 0 | 2 | combat 70%, gather 16%, idle 7% |
| JIDE | CE VIUN | 4 | 0 | 2 | 0 | 0 | idle 85%, gather 9%, wander 5% |
| MEIG | HI MAIP | 0 | 0 | 0 | 0 | 1 | craft 100% |
| MEQE | CU BUAB | 9 | 1 | 8 | 1 | 3 | flee_combat 54%, craft 21%, gather 15% |
| NAAH | CU BUAB | 5 | 1 | 9 | 0 | 2 | idle 65%, craft 13%, gather 11% |
| NEIV | KA PAHE | 4 | 0 | 2 | 0 | 2 | idle 77%, gather 19%, wander 3% |
| NEJE | QE LIOY | 11 | 1 | 7 | 1 | 3 | idle 73%, gather 20%, wander 6% |
| PIET | CU BUAB | 18 | 1 | 18 | 0 | 5 | gather 45%, idle 30%, craft 15% |
| QAUM | CE VIUN | 10 | 0 | 6 | 0 | 0 | idle 66%, gather 20%, wander 9% |
| QOGO | KA PAHE | 9 | 3 | 5 | 1 | 6 | gather 45%, idle 41%, wander 8% |
| REPE | CE VIUN | 6 | 1 | 4 | 0 | 0 | idle 59%, gather 37%, wander 3% |
| RIUM | CU BUAB | 15 | 2 | 18 | 0 | 2 | flee_combat 46%, gather 24%, craft 19% |
| ROOR | CE VIUN | 25 | 2 | 18 | 1 | 3 | gather 58%, flee_combat 23%, eat 17% |
| SAOW | CE VIUN | 8 | 1 | 5 | 0 | 1 | idle 70%, gather 25%, eat 4% |
| SOYI | QE LIOY | 8 | 1 | 12 | 1 | 6 | gather 33%, idle 24%, craft 19% |
| VAEJ | CU BUAB | 6 | 1 | 5 | 0 | 2 | gather 55%, combat 37%, eat 6% |
| VARO | CU BUAB | 32 | 6 | 21 | 0 | 2 | gather 61%, wander 19%, idle 12% |
| XAEC | CU BUAB | 0 | 0 | 0 | 0 | 1 | gather 100% |
| XEAW | KA PAHE | 18 | 2 | 18 | 2 | 10 | gather 71%, craft 16%, wander 6% |
| YOIL | CU BUAB | 19 | 3 | 11 | 0 | 3 | idle 44%, gather 43%, eat 10% |
| YUFO | QE LIOY | 11 | 1 | 12 | 1 | 10 | gather 53%, craft 18%, idle 15% |
| ZEVU | QE LIOY | 18 | 2 | 12 | 2 | 8 | gather 60%, idle 16%, herd_wildnpc 10% |
| ZEZE | KA PAHE | 7 | 0 | 4 | 0 | 4 | idle 60%, gather 38%, wander 1% |
| ZIIG | CU BUAB | 7 | 1 | 5 | 0 | 1 | idle 66%, gather 23%, eat 7% |
| ZIOW | HI MAIP | 19 | 3 | 15 | 0 | 7 | gather 47%, herd_wildnpc 16%, wander 14% |
| ZUYI | CU BUAB | 34 | 11 | 28 | 0 | 4 | gather 43%, idle 19%, flee_combat 11% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| CE VIUN | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| CU BUAB | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| FU NEIV | 15 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HI MAIP | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KA PAHE | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KI LISO | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE LIOY | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| CE VIUN | 1 | 1 | 0 | 0 |
| CU BUAB | 1 | 1 | 0 | 0 |
| FU NEIV | 0 | 0 | 0 | 0 |
| HI MAIP | 1 | 1 | 0 | 0 |
| KA PAHE | 0 | 0 | 0 | 0 |
| KI LISO | 0 | 0 | 0 | 0 |
| QE LIOY | 0 | 0 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| CE VIUN | 64 | 2 | 97% | 0 | 5 | idle 35%, gather 31%, herd_wildnpc 12% |
| CU BUAB | 163 | 1 | 99% | 0 | 20 | gather 37%, idle 24%, flee_combat 12% |
| FU NEIV | 0 | 0 | — | 0 | 0 | agro 48%, herd_wildnpc 34%, wander 10% |
| HI MAIP | 59 | 1 | 98% | 0 | 10 | gather 33%, idle 21%, combat 15% |
| KA PAHE | 45 | 4 | 92% | 0 | 25 | gather 49%, idle 30%, wander 10% |
| KI LISO | 0 | 0 | — | 0 | 0 | herd_wildnpc 100% |
| QE LIOY | 70 | 6 | 92% | 0 | 20 | gather 42%, idle 25%, herd_wildnpc 10% |

## Economy (session)

- **Items gathered:** 541
- **Items deposited:** 379
- **Deposit yield:** 70%
- **Gather failures (all):** 18
- **Gather failures (actionable):** 11
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 9
- **empty_switch:not_harvestable:** 7
- **not_harvestable:** 2

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 27 | 16 | 59% |
| Fiber | 60 | 45 | 75% |
| Grain | 60 | 33 | 55% |
| Mushroom | 37 | 20 | 54% |
| Nuts | 34 | 13 | 38% |
| Spear | 0 | 30 | — |
| Stone | 154 | 112 | 73% |
| Wood | 169 | 110 | 65% |

## Buildings (session)

- **Total placed:** 7

### By type

- **Living Hut:** 7

### By source

- **herder_hut:** 7

### Chronological

- t=96.1s **KA PAHE** — Living Hut (herder_hut) builder=BIFO @ (-2449,1069)
- t=98.7s **CU BUAB** — Living Hut (herder_hut) builder=PIIY @ (-222,-2171)
- t=110.6s **QE LIOY** — Living Hut (herder_hut) builder=VUXE @ (-1356,2847)
- t=134.6s **HI MAIP** — Living Hut (herder_hut) builder=YOUW @ (2083,580)
- t=412.4s **CE VIUN** — Living Hut (herder_hut) builder=PUIF @ (-568,-3721)
- t=558.5s **QE LIOY** — Living Hut (herder_hut) builder=DEZO @ (-1588,2785)
- t=632.7s **QE LIOY** — Living Hut (herder_hut) builder=SOYI @ (-1518,2705)

## Per-clan detail

### CE VIUN

- **Brain:** AGGRESSIVE | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (89% fill)
- **Pressure:** defend 0.18 | search 0.27 | gather 0.55
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 380 → 0
- **Daily calorie need (end):** 23.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 15 | 11 |
| Fiber | 24 | 18 |
| Grain | 18 | 3 |
| Mushroom | 1 | 0 |
| Nuts | 6 | 2 |
| Spear | 0 | 5 |
| Stone | 17 | 7 |
| Wood | 18 | 6 |

#### Failures

- **Gather:** not_harvestable=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DUJI | 9 | 1 | 1 | 13 | gather 52%, idle 34%, eat 13% |
| JIDE | 2 | 0 | 0 | 4 | idle 85%, gather 9%, wander 5% |
| PUIF | 20 | 0 | 12 | 33 | herd_wildnpc 38%, gather 28%, wander 16% |
| QAUM | 6 | 0 | 0 | 10 | idle 66%, gather 20%, wander 9% |
| REPE | 4 | 0 | 1 | 6 | idle 59%, gather 37%, wander 3% |
| ROOR | 18 | 1 | 2 | 25 | gather 58%, flee_combat 23%, eat 17% |
| SAOW | 5 | 0 | 1 | 8 | idle 70%, gather 25%, eat 4% |

#### Buildings

- t=412.4s **Living Hut** — herder_hut (builder: PUIF)

### CU BUAB

- **Brain:** AGGRESSIVE | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (88% fill)
- **Pressure:** defend 0.18 | search 0.27 | gather 0.54
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 460 → 0
- **Daily calorie need (end):** 21.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 12 | 5 |
| Fiber | 27 | 18 |
| Grain | 30 | 19 |
| Mushroom | 9 | 6 |
| Nuts | 6 | 3 |
| Spear | 0 | 10 |
| Stone | 84 | 62 |
| Wood | 34 | 32 |

#### Failures

- **Gather:** empty_switch:not_harvestable=5

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| MEQE | 8 | 1 | 1 | 9 | flee_combat 54%, craft 21%, gather 15% |
| NAAH | 9 | 0 | 1 | 5 | idle 65%, craft 13%, gather 11% |
| PIET | 18 | 0 | 1 | 18 | gather 45%, idle 30%, craft 15% |
| PIIY | 40 | 0 | 22 | 57 | gather 55%, wander 23%, craft 8% |
| RIUM | 18 | 0 | 2 | 15 | flee_combat 46%, gather 24%, craft 19% |
| VAEJ | 5 | 0 | 1 | 6 | gather 55%, combat 37%, eat 6% |
| VARO | 21 | 0 | 6 | 32 | gather 61%, wander 19%, idle 12% |
| XAEC | 0 | 0 | 0 | 0 | gather 100% |
| YOIL | 11 | 0 | 3 | 19 | idle 44%, gather 43%, eat 10% |
| ZIIG | 5 | 0 | 1 | 7 | idle 66%, gather 23%, eat 7% |
| ZUYI | 28 | 0 | 11 | 34 | gather 43%, idle 19%, flee_combat 11% |

#### Buildings

- t=98.7s **Living Hut** — herder_hut (builder: PIIY)

### FU NEIV

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (77% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 200 → 200 → 200
- **Daily calorie need (end):** 14.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| HUID | 0 | 0 | 1 | 0 | agro 48%, herd_wildnpc 34%, wander 10% |

### HI MAIP

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 1/1 (93% fill) | searchers 1/2 (87% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 660 → 660
- **Daily calorie need (end):** 23.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 9 | 9 |
| Grain | 12 | 11 |
| Mushroom | 9 | 7 |
| Nuts | 5 | 2 |
| Spear | 0 | 4 |
| Stone | 23 | 20 |
| Wood | 25 | 16 |

#### Failures

- **Gather:** resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CUEM | 6 | 0 | 1 | 6 | idle 82%, craft 10%, gather 6% |
| DUUH | 7 | 0 | 2 | 15 | gather 50%, idle 22%, defend 10% |
| GAUN | 6 | 0 | 0 | 5 | combat 70%, gather 16%, idle 7% |
| MEIG | 0 | 0 | 0 | 0 | craft 100% |
| YOUW | 25 | 1 | 12 | 38 | gather 46%, wander 22%, herd_wildnpc 14% |
| ZIOW | 15 | 0 | 3 | 19 | gather 47%, herd_wildnpc 16%, wander 14% |

#### Buildings

- t=134.6s **Living Hut** — herder_hut (builder: YOUW)

### KA PAHE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (89% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 240 → 0
- **Daily calorie need (end):** 23.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Mushroom | 12 | 4 |
| Nuts | 9 | 3 |
| Spear | 0 | 3 |
| Stone | 18 | 11 |
| Wood | 26 | 21 |

#### Failures

- **Gather:** resource_invalid=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIFO | 13 | 0 | 7 | 21 | gather 55%, wander 27%, herd_wildnpc 11% |
| FACI | 3 | 1 | 0 | 6 | gather 92%, idle 6%, wander 3% |
| NEIV | 2 | 0 | 0 | 4 | idle 77%, gather 19%, wander 3% |
| QOGO | 5 | 1 | 3 | 9 | gather 45%, idle 41%, wander 8% |
| XEAW | 18 | 2 | 2 | 18 | gather 71%, craft 16%, wander 6% |
| ZEZE | 4 | 0 | 0 | 7 | idle 60%, gather 38%, wander 1% |

#### Buildings

- t=96.1s **Living Hut** — herder_hut (builder: BIFO)

### KI LISO

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (83% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.1 → 1.0 → 0.1
- **Calories in storage:** 200 → 200 → 200
- **Daily calorie need (end):** 2.2k
- **Calorie days buffer:** 0.1 → 1.0 → 0.1
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| NEHI | 0 | 0 | 1 | 0 | herd_wildnpc 100% |

### QE LIOY

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (81% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 36.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Mushroom | 6 | 3 |
| Nuts | 8 | 3 |
| Spear | 0 | 6 |
| Stone | 12 | 12 |
| Wood | 66 | 35 |

#### Failures

- **Gather:** resource_invalid=4, empty_switch:not_harvestable=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DEZO | 6 | 0 | 1 | 9 | idle 44%, gather 23%, herd_wildnpc 19% |
| NEJE | 7 | 1 | 1 | 11 | idle 73%, gather 20%, wander 6% |
| SOYI | 12 | 1 | 1 | 8 | gather 33%, idle 24%, craft 19% |
| VUXE | 21 | 1 | 11 | 35 | gather 52%, wander 33%, herd_wildnpc 8% |
| YUFO | 12 | 1 | 1 | 11 | gather 53%, craft 18%, idle 15% |
| ZEVU | 12 | 2 | 2 | 18 | gather 60%, idle 16%, herd_wildnpc 10% |

#### Buildings

- t=110.6s **Living Hut** — herder_hut (builder: VUXE)
- t=558.5s **Living Hut** — herder_hut (builder: DEZO)
- t=632.7s **Living Hut** — herder_hut (builder: SOYI)

