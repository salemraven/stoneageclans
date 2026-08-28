# ClanBrain Report (standard)

## Session

- **Duration:** 900.6s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_15min_20260621_225400/playtest_session.jsonl`
- **World seed:** 0
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 7
- **Simulation ticks:** 7
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 7/7 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| CE VIUN | 0→7 | 5 | 0 | 14.8k | 0.0 | 0 | 0 | 97 | 50 | 0 | 96% | 80.1s | 6 | 1 | — |
| CU BUAB | 0→25 | 14 | 0 | 51.8k | 0.0 | 0 | 0 | 321 | 181 | 0 | 91% | 65.0s | 14 | 5 | — |
| DU QEPI | 0→4 | 1 | 0 | 8.2k | 0.0 | 0 | 0 | 0 | 2 | 0 | 47% | 571.4s | 0 | 0 | — |
| FU NEIV | 0→9 | 1 | 0 | 18.2k | 0.0 | 0 | 0 | 0 | 2 | 0 | 94% | 898.8s | 0 | 0 | — |
| HI MAIP | 0→36 | 25 | 0 | 72.6k | 0.0 | 0 | 0 | 583 | 365 | 24 | 92% | 84.9s | 26 | 3 | — |
| KA PAHE | 0→1 | 1 | 200 | 2.2k | 0.1 | 0 | 0 | 0 | 1 | 0 | 96% | 898.2s | 0 | 0 | — |
| QE LIOY | 0→19 | 8 | 0 | 39.0k | 0.0 | 0 | 0 | 125 | 68 | 3 | 63% | 90.1s | 7 | 3 | — |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| CE VIUN | — | — | 96% | 20% | 0→200→0 | 0.0→1.0→0.0 | 80.1s |
| CU BUAB | — | — | 91% | 50% | 0→650→0 | 0.0→1.0→0.0 | 65.0s |
| DU QEPI | 56% | 44% | 39% | 61% | 0→200→0 | 0.0→1.0→0.0 | 571.4s |
| FU NEIV | — | — | 94% | 6% | 0→200→0 | 0.0→1.0→0.0 | 898.8s |
| HI MAIP | — | — | 92% | 17% | 0→500→0 | 0.0→1.0→0.0 | 84.9s |
| KA PAHE | — | — | 96% | 4% | 200→200→200 | 0.1→1.0→0.1 | 898.2s |
| QE LIOY | — | — | 63% | 14% | 0→400→0 | 0.0→1.0→0.0 | 90.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| CE VIUN | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| CU BUAB | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| DU QEPI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| FU NEIV | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HI MAIP | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KA PAHE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE LIOY | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| CE VIUN | 1 | 6 | 6 | 78.7s |
| CU BUAB | 5 | 14 | 14 | 65.5s |
| DU QEPI | 0 | 0 | 0 | — |
| FU NEIV | 0 | 0 | 0 | — |
| HI MAIP | 3 | 29 | 26 | 80.7s |
| KA PAHE | 0 | 0 | 0 | — |
| QE LIOY | 3 | 7 | 7 | 92.8s |

## Clansmen workforce

- **Unique clansmen seen:** 53 (gather FSM transitions: 373, productivity snapshots: 29)
- **Last snapshot:** clansmen=48 with_job=6 (all workers job %=14.8148148148148)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| CE VIUN | 6 | 6 | 55 | 15 | 4 | 38 | task_failed=34, state_exit_clear_tasks=3, assign_job_supersede=1 |
| CU BUAB | 14 | 14 | 194 | 70 | 16 | 37 | task_failed=23, state_exit_clear_tasks=8, assign_job_supersede=3 |
| DU QEPI | 0 | 0 | 0 | 0 | 0 | 0 | — |
| FU NEIV | 0 | 0 | 0 | 0 | 0 | 0 | — |
| HI MAIP | 26 | 26 | 514 | 295 | 52 | 232 | task_failed=151, state_exit_clear_tasks=31, assign_job_supersede=22 |
| KA PAHE | 0 | 0 | 0 | 0 | 0 | 0 | — |
| QE LIOY | 7 | 7 | 67 | 19 | 6 | 16 | state_exit_clear_tasks=7, task_failed=7, resource_node_invalid=2 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BAIY | CU BUAB | 7 | 0 | 4 | 0 | 0 | idle 94%, eat 3%, gather 3% |
| BASE | HI MAIP | 18 | 1 | 19 | 2 | 10 | idle 54%, gather 29%, eat 9% |
| BECI | CU BUAB | 13 | 1 | 8 | 0 | 0 | idle 85%, gather 10%, eat 2% |
| COCA | HI MAIP | 52 | 7 | 46 | 3 | 6 | gather 66%, craft 15%, wander 14% |
| COEV | QE LIOY | 7 | 1 | 7 | 2 | 4 | idle 61%, combat 15%, craft 15% |
| COUN | CE VIUN | 12 | 1 | 24 | 0 | 2 | idle 72%, craft 15%, gather 13% |
| CUAQ | HI MAIP | 14 | 1 | 8 | 0 | 1 | gather 84%, wander 10%, eat 6% |
| DIKE | CU BUAB | 6 | 0 | 4 | 0 | 0 | idle 94%, eat 3%, gather 2% |
| DURU | HI MAIP | 11 | 0 | 7 | 1 | 1 | idle 42%, gather 41%, eat 12% |
| FIAB | CU BUAB | 7 | 1 | 14 | 0 | 0 | idle 84%, craft 9%, gather 4% |
| FIFO | HI MAIP | 33 | 4 | 33 | 3 | 12 | gather 46%, idle 29%, craft 11% |
| FUWE | HI MAIP | 5 | 0 | 2 | 0 | 0 | idle 79%, gather 11%, eat 8% |
| GAQU | HI MAIP | 45 | 6 | 33 | 1 | 7 | gather 75%, wander 15%, craft 6% |
| GUAQ | QE LIOY | 8 | 0 | 2 | 1 | 2 | idle 67%, gather 17%, wander 8% |
| GULU | QE LIOY | 7 | 0 | 5 | 1 | 4 | idle 77%, gather 22%, eat 1% |
| HOMI | HI MAIP | 14 | 1 | 8 | 0 | 0 | idle 76%, gather 11%, eat 8% |
| JOIR | CU BUAB | 37 | 5 | 22 | 1 | 4 | idle 54%, gather 30%, eat 7% |
| KAZO | CE VIUN | 6 | 1 | 4 | 0 | 0 | idle 79%, combat 17%, gather 4% |
| KUUP | CE VIUN | 5 | 0 | 4 | 0 | 0 | idle 91%, gather 4%, wander 2% |
| LIIW | CU BUAB | 15 | 1 | 10 | 0 | 0 | idle 62%, gather 27%, wander 7% |
| LUHU | QE LIOY | 8 | 0 | 4 | 0 | 0 | idle 94%, gather 5%, eat 1% |
| LUYI | HI MAIP | 6 | 0 | 5 | 0 | 2 | gather 91%, wander 9% |
| MIXO | QE LIOY | 18 | 2 | 12 | 2 | 5 | idle 50%, gather 19%, combat 15% |
| MOFA | HI MAIP | 40 | 4 | 26 | 1 | 7 | gather 77%, wander 17%, eat 6% |
| MUEH | CU BUAB | 23 | 0 | 14 | 0 | 0 | idle 64%, gather 24%, eat 11% |
| MUFU | HI MAIP | 24 | 2 | 13 | 1 | 3 | gather 49%, idle 34%, wander 9% |
| NIOV | HI MAIP | 5 | 0 | 2 | 1 | 2 | idle 81%, gather 10%, eat 9% |
| NOUC | HI MAIP | 18 | 2 | 13 | 1 | 3 | gather 78%, wander 14%, eat 8% |
| NUTO | CU BUAB | 6 | 0 | 1 | 0 | 1 | idle 81%, gather 10%, wander 4% |
| POMO | HI MAIP | 6 | 0 | 1 | 0 | 1 | idle 79%, eat 12%, gather 8% |
| PUIM | HI MAIP | 11 | 0 | 2 | 0 | 2 | idle 71%, gather 18%, eat 10% |
| QOAG | QE LIOY | 12 | 2 | 6 | 0 | 0 | idle 82%, gather 14%, wander 3% |
| QUCA | CE VIUN | 10 | 1 | 6 | 0 | 0 | flee_combat 78%, idle 14%, eat 4% |
| RAEZ | CU BUAB | 14 | 1 | 7 | 1 | 2 | idle 79%, craft 9%, gather 9% |
| RAMU | CE VIUN | 10 | 1 | 6 | 0 | 1 | idle 94%, gather 5%, eat 1% |
| REPU | HI MAIP | 18 | 2 | 16 | 2 | 8 | gather 42%, idle 39%, eat 8% |
| RIAF | CU BUAB | 24 | 4 | 23 | 0 | 1 | idle 46%, combat 15%, gather 15% |
| SOHI | CU BUAB | 6 | 1 | 5 | 0 | 2 | flee_combat 93%, gather 6%, combat 1% |
| TEHA | HI MAIP | 7 | 1 | 5 | 1 | 1 | idle 81%, gather 10%, eat 9% |
| TIOZ | HI MAIP | 16 | 2 | 8 | 1 | 5 | flee_combat 61%, gather 29%, wander 7% |
| TOLO | CU BUAB | 19 | 1 | 12 | 0 | 1 | idle 64%, gather 25%, eat 7% |
| VEPI | HI MAIP | 17 | 2 | 11 | 1 | 4 | gather 83%, wander 12%, eat 5% |
| VOAN | HI MAIP | 60 | 6 | 45 | 2 | 6 | gather 57%, wander 15%, eat 9% |
| VUXU | QE LIOY | 7 | 1 | 15 | 1 | 1 | idle 74%, craft 11%, herd_wildnpc 7% |
| WOXO | CE VIUN | 12 | 0 | 8 | 0 | 0 | idle 91%, gather 6%, eat 2% |
| WUXI | HI MAIP | 0 | 0 | 1 | 1 | 2 | gather 90%, wander 9%, idle 1% |
| XAOB | HI MAIP | 15 | 2 | 11 | 1 | 5 | idle 57%, gather 29%, eat 9% |
| XASA | HI MAIP | 20 | 1 | 14 | 0 | 0 | idle 61%, gather 23%, eat 11% |
| XUKO | CU BUAB | 8 | 1 | 9 | 0 | 0 | idle 84%, gather 6%, craft 5% |
| YIPI | HI MAIP | 46 | 7 | 37 | 3 | 11 | gather 76%, wander 18%, eat 6% |
| YUDO | HI MAIP | 3 | 0 | 1 | 0 | 1 | flee_combat 93%, gather 7%, combat 0% |
| ZIBI | CU BUAB | 9 | 0 | 6 | 0 | 0 | idle 89%, gather 7%, eat 4% |
| ZURI | HI MAIP | 10 | 1 | 16 | 0 | 3 | idle 65%, gather 13%, craft 11% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| CE VIUN | 59 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| CU BUAB | 60 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| DU QEPI | 38 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| FU NEIV | 60 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HI MAIP | 60 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KA PAHE | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE LIOY | 59 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| CE VIUN | 1 | 1 | 0 | 0 |
| CU BUAB | 1 | 1 | 0 | 0 |
| DU QEPI | 0 | 0 | 0 | 0 |
| FU NEIV | 0 | 0 | 0 | 0 |
| HI MAIP | 1 | 1 | 0 | 0 |
| KA PAHE | 0 | 0 | 0 | 0 |
| QE LIOY | 0 | 0 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| CE VIUN | 112 | 34 | 77% | 0 | 3 | idle 61%, flee_combat 12%, agro 10% |
| CU BUAB | 241 | 23 | 91% | 0 | 5 | idle 63%, gather 16%, flee_combat 7% |
| DU QEPI | 0 | 0 | — | 0 | 0 | wander 53%, herd_wildnpc 32%, defend 6% |
| FU NEIV | 0 | 0 | — | 0 | 6 | herd_wildnpc 94%, wander 5%, eat 1% |
| HI MAIP | 552 | 151 | 79% | 0 | 37 | gather 38%, idle 36%, wander 8% |
| KA PAHE | 0 | 0 | — | 0 | 0 | wander 96%, herd_wildnpc 4%, combat 0% |
| QE LIOY | 91 | 7 | 93% | 0 | 7 | idle 60%, gather 19%, craft 6% |

## Economy (session)

- **Items gathered:** 1126
- **Items deposited:** 669
- **Deposit yield:** 59%
- **Gather failures (all):** 41
- **Gather failures (actionable):** 27
- **Deposit failures:** 0

### Gather failures (actionable)

- **not_harvestable:** 18
- **empty_switch:not_harvestable:** 14
- **resource_invalid:** 9

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 141 | 63 | 45% |
| Fiber | 150 | 102 | 68% |
| Grain | 165 | 73 | 44% |
| Mushroom | 53 | 23 | 43% |
| Nuts | 60 | 25 | 42% |
| Spear | 0 | 42 | — |
| Stone | 272 | 176 | 65% |
| Wood | 285 | 165 | 58% |

## Buildings (session)

- **Total placed:** 12

### By type

- **Living Hut:** 12

### By source

- **herder_hut:** 12

### Chronological

- t=33.0s **CU BUAB** — Living Hut (herder_hut) builder=PIIY @ (-203,-2214)
- t=46.2s **CE VIUN** — Living Hut (herder_hut) builder=NUAQ @ (-565,-3737)
- t=48.2s **HI MAIP** — Living Hut (herder_hut) builder=YOUW @ (1868,481)
- t=60.3s **QE LIOY** — Living Hut (herder_hut) builder=VUXE @ (-1423,2925)
- t=172.4s **HI MAIP** — Living Hut (herder_hut) builder=VOAN @ (2055,609)
- t=192.5s **HI MAIP** — Living Hut (herder_hut) builder=VOAN @ (2089,569)
- t=312.5s **QE LIOY** — Living Hut (herder_hut) builder=GUAQ @ (-1555,2729)
- t=314.5s **CU BUAB** — Living Hut (herder_hut) builder=RIAF @ (-225,-2166)
- t=429.0s **QE LIOY** — Living Hut (herder_hut) builder=GUAQ @ (-1592,2813)
- t=643.3s **CU BUAB** — Living Hut (herder_hut) builder=NUTO @ (-391,-2337)
- t=677.9s **CU BUAB** — Living Hut (herder_hut) builder=PIIY @ (-429,-2289)
- t=714.4s **CU BUAB** — Living Hut (herder_hut) builder=PIIY @ (-130,-2228)

## Per-clan detail

### CE VIUN

- **Brain:** AGGRESSIVE | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (96% fill)
- **Pressure:** defend 0.18 | search 0.27 | gather 0.55
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 14.8k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 15 | 8 |
| Fiber | 24 | 6 |
| Grain | 9 | 3 |
| Nuts | 3 | 0 |
| Spear | 0 | 5 |
| Stone | 28 | 16 |
| Wood | 18 | 12 |

#### Failures

- **Gather:** empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| COUN | 24 | 0 | 1 | 12 | idle 72%, craft 15%, gather 13% |
| KAZO | 4 | 0 | 1 | 6 | idle 79%, combat 17%, gather 4% |
| KUUP | 4 | 0 | 0 | 5 | idle 91%, gather 4%, wander 2% |
| NUAQ | 60 | 34 | 12 | 42 | agro 58%, gather 19%, wander 8% |
| QUCA | 6 | 0 | 1 | 10 | flee_combat 78%, idle 14%, eat 4% |
| RAMU | 6 | 0 | 1 | 10 | idle 94%, gather 5%, eat 1% |
| WOXO | 8 | 0 | 0 | 12 | idle 91%, gather 6%, eat 2% |

#### Buildings

- t=46.2s **Living Hut** — herder_hut (builder: NUAQ)

### CU BUAB

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (91% fill)
- **Pressure:** defend 0.15 | search 0.27 | gather 0.58
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 650 → 0
- **Daily calorie need (end):** 51.8k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 27 | 6 |
| Fiber | 33 | 21 |
| Grain | 54 | 19 |
| Mushroom | 15 | 8 |
| Nuts | 13 | 7 |
| Spear | 0 | 10 |
| Stone | 122 | 79 |
| Wood | 57 | 31 |

#### Failures

- **Gather:** empty_switch:not_harvestable=5

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAIY | 4 | 0 | 0 | 7 | idle 94%, eat 3%, gather 3% |
| BECI | 8 | 0 | 1 | 13 | idle 85%, gather 10%, eat 2% |
| DIKE | 4 | 0 | 0 | 6 | idle 94%, eat 3%, gather 2% |
| FIAB | 14 | 0 | 1 | 7 | idle 84%, craft 9%, gather 4% |
| JOIR | 22 | 1 | 5 | 37 | idle 54%, gather 30%, eat 7% |
| LIIW | 10 | 0 | 1 | 15 | idle 62%, gather 27%, wander 7% |
| MUEH | 14 | 0 | 0 | 23 | idle 64%, gather 24%, eat 11% |
| NUTO | 1 | 0 | 0 | 6 | idle 81%, gather 10%, wander 4% |
| PIIY | 102 | 21 | 45 | 127 | gather 54%, wander 23%, build_hut_for_woman 7% |
| RAEZ | 7 | 1 | 1 | 14 | idle 79%, craft 9%, gather 9% |
| RIAF | 23 | 0 | 4 | 24 | idle 46%, combat 15%, gather 15% |
| SOHI | 5 | 0 | 1 | 6 | flee_combat 93%, gather 6%, combat 1% |
| TOLO | 12 | 0 | 1 | 19 | idle 64%, gather 25%, eat 7% |
| XUKO | 9 | 0 | 1 | 8 | idle 84%, gather 6%, craft 5% |
| ZIBI | 6 | 0 | 0 | 9 | idle 89%, gather 7%, eat 4% |

#### Buildings

- t=33.0s **Living Hut** — herder_hut (builder: PIIY)
- t=314.5s **Living Hut** — herder_hut (builder: RIAF)
- t=643.3s **Living Hut** — herder_hut (builder: NUTO)
- t=677.9s **Living Hut** — herder_hut (builder: PIIY)
- t=714.4s **Living Hut** — herder_hut (builder: PIIY)

### DU QEPI

- **Brain:** DEFENSIVE | alert RAID | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/1 (56% fill) | searchers 0/0 (39% fill)
- **Pressure:** defend 0.26 | search 0.25 | gather 0.49
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 8.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 0 | 1 |
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FIWE | 0 | 0 | 2 | 0 | wander 53%, herd_wildnpc 32%, defend 6% |

### FU NEIV

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (94% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 18.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 0 | 1 |
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| MATO | 0 | 0 | 2 | 0 | herd_wildnpc 94%, wander 5%, eat 1% |

### HI MAIP

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 7/7 (92% fill)
- **Pressure:** defend 0.12 | search 0.29 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 500 → 0
- **Daily calorie need (end):** 72.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 99 | 47 |
| Fiber | 93 | 75 |
| Grain | 102 | 51 |
| Mushroom | 27 | 11 |
| Nuts | 30 | 17 |
| Spear | 0 | 19 |
| Stone | 107 | 70 |
| Wood | 125 | 75 |

#### Failures

- **Gather:** not_harvestable=18, resource_invalid=6, empty_switch:not_harvestable=5

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BASE | 19 | 2 | 1 | 18 | idle 54%, gather 29%, eat 9% |
| COCA | 46 | 3 | 7 | 52 | gather 66%, craft 15%, wander 14% |
| CUAQ | 8 | 0 | 1 | 14 | gather 84%, wander 10%, eat 6% |
| DURU | 7 | 1 | 0 | 11 | idle 42%, gather 41%, eat 12% |
| FIFO | 33 | 3 | 4 | 33 | gather 46%, idle 29%, craft 11% |
| FUWE | 2 | 0 | 0 | 5 | idle 79%, gather 11%, eat 8% |
| GAQU | 33 | 1 | 6 | 45 | gather 75%, wander 15%, craft 6% |
| HOMI | 8 | 0 | 1 | 14 | idle 76%, gather 11%, eat 8% |
| LUYI | 5 | 0 | 0 | 6 | gather 91%, wander 9% |
| MOFA | 26 | 1 | 4 | 40 | gather 77%, wander 17%, eat 6% |
| MUFU | 13 | 1 | 2 | 24 | gather 49%, idle 34%, wander 9% |
| NIOV | 2 | 1 | 0 | 5 | idle 81%, gather 10%, eat 9% |
| NOUC | 13 | 1 | 2 | 18 | gather 78%, wander 14%, eat 8% |
| POMO | 1 | 0 | 0 | 6 | idle 79%, eat 12%, gather 8% |
| PUIM | 2 | 0 | 0 | 11 | idle 71%, gather 18%, eat 10% |
| REPU | 16 | 2 | 2 | 18 | gather 42%, idle 39%, eat 8% |
| TEHA | 5 | 1 | 1 | 7 | idle 81%, gather 10%, eat 9% |
| TIOZ | 8 | 1 | 2 | 16 | flee_combat 61%, gather 29%, wander 7% |
| VEPI | 11 | 1 | 2 | 17 | gather 83%, wander 12%, eat 5% |
| VOAN | 45 | 2 | 6 | 60 | gather 57%, wander 15%, eat 9% |
| WUXI | 1 | 1 | 0 | 0 | gather 90%, wander 9%, idle 1% |
| XAOB | 11 | 1 | 2 | 15 | idle 57%, gather 29%, eat 9% |
| XASA | 14 | 0 | 1 | 20 | idle 61%, gather 23%, eat 11% |
| YIPI | 37 | 3 | 7 | 46 | gather 76%, wander 18%, eat 6% |
| YOUW | 169 | 125 | 22 | 69 | gather 54%, wander 32%, craft 7% |
| YUDO | 1 | 0 | 0 | 3 | flee_combat 93%, gather 7%, combat 0% |
| ZURI | 16 | 0 | 1 | 10 | idle 65%, gather 13%, craft 11% |

#### Buildings

- t=48.2s **Living Hut** — herder_hut (builder: YOUW)
- t=172.4s **Living Hut** — herder_hut (builder: VOAN)
- t=192.5s **Living Hut** — herder_hut (builder: VOAN)

### KA PAHE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (96% fill)
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
| BIFO | 0 | 0 | 1 | 0 | wander 96%, herd_wildnpc 4%, combat 0% |

### QE LIOY

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/2 (63% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 400 → 0
- **Daily calorie need (end):** 39.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Mushroom | 11 | 4 |
| Nuts | 14 | 1 |
| Spear | 0 | 5 |
| Stone | 15 | 11 |
| Wood | 85 | 47 |

#### Failures

- **Gather:** empty_switch:not_harvestable=3, resource_invalid=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| COEV | 7 | 2 | 1 | 7 | idle 61%, combat 15%, craft 15% |
| GUAQ | 2 | 1 | 0 | 8 | idle 67%, gather 17%, wander 8% |
| GULU | 5 | 1 | 0 | 7 | idle 77%, gather 22%, eat 1% |
| LUHU | 4 | 0 | 0 | 8 | idle 94%, gather 5%, eat 1% |
| MIXO | 12 | 2 | 2 | 18 | idle 50%, gather 19%, combat 15% |
| QOAG | 6 | 0 | 2 | 12 | idle 82%, gather 14%, wander 3% |
| VUXE | 40 | 0 | 15 | 58 | gather 51%, wander 29%, craft 7% |
| VUXU | 15 | 1 | 1 | 7 | idle 74%, craft 11%, herd_wildnpc 7% |

#### Buildings

- t=60.3s **Living Hut** — herder_hut (builder: VUXE)
- t=312.5s **Living Hut** — herder_hut (builder: GUAQ)
- t=429.0s **Living Hut** — herder_hut (builder: GUAQ)

