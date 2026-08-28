# ClanBrain Report (standard)

## Session

- **Duration:** 300.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_5min_20260620_125116/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4
- **Simulation ticks:** 2
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| QU PUNO | 0→13 | 8 | 0 | 27.4k | 0.0 | 2 | 2 | 66 | 53 | 1 | 72% | 90.1s | 7 | 1 | 92.6s |
| SA LEUK | 0→19 | 14 | 300 | 37.8k | 0.0 | 2 | 2 | 46 | 68 | 1 | 74% | 90.1s | 13 | 4 | 148.6s |
| SU BILE | 0→12 | 8 | 0 | 25.2k | 0.0 | 2 | 2 | 60 | 68 | 2 | 78% | 85.1s | 7 | 3 | 92.3s |
| YI HAAK | 0→11 | 8 | 0 | 23.2k | 0.0 | 2 | 2 | 48 | 43 | 3 | 69% | 95.1s | 7 | 1 | 98.5s |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 8 / 8
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| QU PUNO | — | — | 72% | 14% | 0→2.7k→0 | 0.0→1.0→0.0 | 90.1s |
| SA LEUK | — | — | 74% | 14% | 0→1.8k→300 | 0.0→1.0→0.0 | 90.1s |
| SU BILE | — | — | 78% | 17% | 0→1.4k→0 | 0.0→1.0→0.0 | 85.1s |
| YI HAAK | — | — | 69% | 12% | 0→2.3k→0 | 0.0→1.0→0.0 | 95.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| QU PUNO | 2 | 2 | 0 | 2 | 0 | 7 | 7 |
| SA LEUK | 2 | 2 | 0 | 2 | 0 | 6 | 6 |
| SU BILE | 2 | 2 | 0 | 2 | 0 | 6 | 6 |
| YI HAAK | 2 | 2 | 0 | 2 | 0 | 7 | 8 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| QU PUNO | 1 | 7 | 7 | 87.7s |
| SA LEUK | 2 | 15 | 13 | 90.2s |
| SU BILE | 2 | 7 | 7 | 83.0s |
| YI HAAK | 2 | 7 | 7 | 96.6s |

## Clansmen workforce

- **Unique clansmen seen:** 34 (gather FSM transitions: 127, productivity snapshots: 10)
- **Last snapshot:** clansmen=34 with_job=13 (all workers job %=36.8421052631579)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| QU PUNO | 7 | 7 | 48 | 28 | 7 | 10 | state_exit_clear_tasks=6, assign_job_supersede=2, resource_node_invalid=1 |
| SA LEUK | 13 | 13 | 32 | 54 | 16 | 98 | production_work_exit=65, state_exit_clear_tasks=11, exited_tree=9 |
| SU BILE | 7 | 7 | 49 | 58 | 17 | 90 | production_work_exit=76, state_exit_clear_tasks=6, exited_tree=2 |
| YI HAAK | 7 | 7 | 39 | 32 | 8 | 21 | state_exit_clear_tasks=10, assign_job_supersede=3, exited_tree=3 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BEUV | SA LEUK | 0 | 1 | 5 | 2 | 3 | craft 81%, gather 17%, eat 2% |
| BIKI | SA LEUK | 3 | 0 | 4 | 0 | 2 | gather 98%, eat 2%, wander 0% |
| BOUD | SA LEUK | 3 | 0 | 2 | 0 | 1 | gather 63%, wander 35%, idle 1% |
| CAED | QU PUNO | 10 | 3 | 12 | 0 | 2 | gather 60%, idle 14%, eat 13% |
| CAOJ | SA LEUK | 5 | 4 | 10 | 0 | 3 | gather 48%, party 32%, craft 15% |
| CEIC | QU PUNO | 6 | 0 | 4 | 0 | 0 | idle 66%, gather 26%, eat 4% |
| CIOS | SA LEUK | 8 | 3 | 16 | 0 | 6 | craft 35%, gather 24%, wander 16% |
| DAGU | QU PUNO | 13 | 3 | 13 | 0 | 1 | gather 51%, idle 26%, wander 10% |
| DEQE | SA LEUK | 0 | 1 | 12 | 1 | 2 | craft 80%, gather 13%, eat 5% |
| FAXE | YI HAAK | 8 | 3 | 19 | 1 | 6 | gather 73%, eat 11%, party 10% |
| FUKI | YI HAAK | 5 | 0 | 3 | 1 | 1 | gather 46%, idle 40%, eat 13% |
| GOFA | SU BILE | 8 | 5 | 12 | 0 | 2 | gather 37%, idle 26%, party 20% |
| GOPA | YI HAAK | 9 | 2 | 9 | 0 | 0 | gather 47%, idle 25%, herd_wildnpc 21% |
| GUNA | SU BILE | 8 | 2 | 9 | 0 | 3 | gather 76%, hunt 18%, wander 4% |
| HEMA | QU PUNO | 8 | 0 | 4 | 0 | 0 | idle 45%, gather 28%, herd_wildnpc 15% |
| HOED | SU BILE | 16 | 4 | 13 | 0 | 0 | gather 55%, hunt 20%, eat 13% |
| JUEQ | SA LEUK | 0 | 1 | 2 | 2 | 2 | craft 92%, wander 5%, eat 2% |
| KEOD | YI HAAK | 5 | 1 | 3 | 0 | 1 | gather 78%, wander 22% |
| MEKO | YI HAAK | 3 | 0 | 2 | 0 | 1 | gather 94%, herd_wildnpc 6% |
| MOOH | QU PUNO | 0 | 0 | 3 | 1 | 3 | gather 71%, herd_wildnpc 28%, wander 1% |
| PAUX | SA LEUK | 0 | 0 | 1 | 1 | 1 | craft 70%, wander 14%, hunt 13% |
| QEBA | SA LEUK | 0 | 1 | 3 | 0 | 1 | gather 91%, wander 7%, idle 1% |
| QEIC | YI HAAK | 3 | 1 | 7 | 0 | 4 | gather 93%, eat 7%, wander 0% |
| QIXA | SA LEUK | 6 | 1 | 4 | 0 | 1 | gather 56%, wander 42%, idle 1% |
| RUIZ | YI HAAK | 6 | 1 | 14 | 1 | 5 | gather 70%, wander 12%, party 12% |
| SIIR | SA LEUK | 0 | 0 | 0 | 0 | 1 | gather 100% |
| SOIX | SU BILE | 4 | 1 | 2 | 0 | 0 | gather 46%, wander 35%, herd_wildnpc 19% |
| VOOH | SU BILE | 3 | 3 | 8 | 1 | 3 | gather 70%, build_milestone 12%, combat 5% |
| VOUK | SA LEUK | 0 | 2 | 6 | 0 | 3 | party 39%, gather 37%, build_milestone 19% |
| WUCO | QU PUNO | 11 | 1 | 9 | 0 | 0 | idle 45%, gather 35%, herd_wildnpc 9% |
| XAUC | QU PUNO | 0 | 0 | 0 | 0 | 0 | herd_wildnpc 69%, wander 30%, idle 1% |
| XUIZ | SU BILE | 6 | 1 | 8 | 0 | 2 | gather 59%, party 23%, wander 10% |
| YOIS | SA LEUK | 7 | 2 | 5 | 0 | 1 | gather 49%, build_milestone 28%, eat 15% |
| ZEOJ | SU BILE | 4 | 1 | 4 | 0 | 0 | gather 41%, herd_wildnpc 37%, wander 23% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| QU PUNO | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| SA LEUK | 14 | 3 | 68 | 2 | 0 | 65 | 0 | 0 |
| SU BILE | 14 | 2 | 78 | 2 | 0 | 76 | 0 | 0 |
| YI HAAK | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| QU PUNO | 2 | 3 | 0 | 1 |
| SA LEUK | 3 | 23 | 2 | 20 |
| SU BILE | 2 | 3 | 1 | 1 |
| YI HAAK | 2 | 3 | 0 | 1 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| QU PUNO | 66 | 1 | 99% | 0 | 2 | gather 42%, idle 23%, herd_wildnpc 16% |
| SA LEUK | 105 | 7 | 94% | 0 | 1 | gather 33%, craft 32%, party 11% |
| SU BILE | 75 | 2 | 97% | 0 | 3 | gather 51%, party 9%, herd_wildnpc 8% |
| YI HAAK | 74 | 3 | 96% | 0 | 3 | gather 62%, herd_wildnpc 10%, idle 6% |

## Economy (session)

- **Items gathered:** 220
- **Items deposited:** 232
- **Deposit yield:** 105%
- **Gather failures (all):** 19
- **Gather failures (actionable):** 7
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 12
- **resource_invalid:** 4
- **not_harvestable:** 3

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 9 | 6 | 67% |
| Blade | 0 | 1 | — |
| Bone | 0 | 24 | — |
| Fiber | 27 | 12 | 44% |
| Grain | 12 | 3 | 25% |
| Hide | 0 | 32 | — |
| Meat | 0 | 40 | — |
| Mushroom | 2 | 1 | 50% |
| Nuts | 24 | 13 | 54% |
| Spear | 0 | 28 | — |
| Stone | 28 | 15 | 54% |
| Wood | 118 | 57 | 48% |

## Buildings (session)

- **Total placed:** 9

### By type

- **Living Hut:** 6
- **Drying Rack:** 2
- **Oven:** 1

### By source

- **herder_hut:** 6
- **milestone:** 3

### Chronological

- t=50.5s **SU BILE** — Living Hut (herder_hut) builder=CAOP @ (2223,423)
- t=55.2s **QU PUNO** — Living Hut (herder_hut) builder=HUSA @ (-3127,-1259)
- t=57.7s **SA LEUK** — Living Hut (herder_hut) builder=SOOW @ (830,1767)
- t=64.1s **YI HAAK** — Living Hut (herder_hut) builder=GEYU @ (182,-2216)
- t=130.2s **SU BILE** — Living Hut (herder_hut) builder=CAOP @ (2187,487)
- t=146.6s **SA LEUK** — Living Hut (herder_hut) builder=CIOS @ (649,1652)
- t=172.0s **SU BILE** — Drying Rack (milestone) @ (2342,626)
- t=199.5s **SA LEUK** — Oven (milestone) @ (867,1732)
- t=238.3s **SA LEUK** — Drying Rack (milestone) @ (888,1664)

## Per-clan detail

### QU PUNO

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/5 (72% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.7k → 0
- **Daily calorie need (end):** 27.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Fiber | 6 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Nuts | 14 | 5 |
| Spear | 0 | 4 |
| Stone | 3 | 0 |
| Wood | 43 | 20 |

#### Failures

- **Gather:** not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CAED | 12 | 0 | 3 | 10 | gather 60%, idle 14%, eat 13% |
| CEIC | 4 | 0 | 0 | 6 | idle 66%, gather 26%, eat 4% |
| DAGU | 13 | 0 | 3 | 13 | gather 51%, idle 26%, wander 10% |
| HEMA | 4 | 0 | 0 | 8 | idle 45%, gather 28%, herd_wildnpc 15% |
| HUSA | 21 | 0 | 9 | 18 | gather 38%, herd_wildnpc 34%, wander 15% |
| MOOH | 3 | 1 | 0 | 0 | gather 71%, herd_wildnpc 28%, wander 1% |
| WUCO | 9 | 0 | 1 | 11 | idle 45%, gather 35%, herd_wildnpc 9% |
| XAUC | 0 | 0 | 0 | 0 | herd_wildnpc 69%, wander 30%, idle 1% |

#### Hunts

- start t=92.6s prey=deer quota=2
- start t=137.7s prey=deer quota=3
- hunt_completed t=128.9s reason=loot_complete
- hunt_completed t=159.3s reason=loot_complete

#### Buildings

- t=55.2s **Living Hut** — herder_hut (builder: HUSA)

### SA LEUK

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (74% fill)
- **Pressure:** defend 0.15 | search 0.28 | gather 0.57
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.8k → 300
- **Daily calorie need (end):** 37.8k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Blade | 0 | 1 |
| Bone | 0 | 6 |
| Fiber | 3 | 0 |
| Grain | 6 | 3 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 1 | 1 |
| Nuts | 3 | 3 |
| Spear | 0 | 10 |
| Stone | 13 | 15 |
| Wood | 20 | 11 |

#### Failures

- **Gather:** resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEUV | 5 | 2 | 1 | 0 | craft 81%, gather 17%, eat 2% |
| BIKI | 4 | 0 | 0 | 3 | gather 98%, eat 2%, wander 0% |
| BOUD | 2 | 0 | 0 | 3 | gather 63%, wander 35%, idle 1% |
| CAOJ | 10 | 0 | 4 | 5 | gather 48%, party 32%, craft 15% |
| CIOS | 16 | 0 | 3 | 8 | craft 35%, gather 24%, wander 16% |
| DEQE | 12 | 1 | 1 | 0 | craft 80%, gather 13%, eat 5% |
| JUEQ | 2 | 2 | 1 | 0 | craft 92%, wander 5%, eat 2% |
| PAUX | 1 | 1 | 0 | 0 | craft 70%, wander 14%, hunt 13% |
| QEBA | 3 | 0 | 1 | 0 | gather 91%, wander 7%, idle 1% |
| QIXA | 4 | 0 | 1 | 6 | gather 56%, wander 42%, idle 1% |
| SIIR | 0 | 0 | 0 | 0 | gather 100% |
| SOOW | 19 | 1 | 7 | 14 | gather 26%, herd_wildnpc 23%, party 19% |
| VOUK | 6 | 0 | 2 | 0 | party 39%, gather 37%, build_milestone 19% |
| YOIS | 5 | 0 | 2 | 7 | gather 49%, build_milestone 28%, eat 15% |

#### Hunts

- start t=148.6s prey=deer quota=4
- start t=203.7s prey=deer quota=4
- hunt_completed t=199.9s reason=loot_complete
- hunt_completed t=270.9s reason=loot_complete

#### Buildings

- t=57.7s **Living Hut** — herder_hut (builder: SOOW)
- t=146.6s **Living Hut** — herder_hut (builder: CIOS)
- t=199.5s **Oven** — milestone
- t=238.3s **Drying Rack** — milestone

### SU BILE

- **Brain:** AGGRESSIVE | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (78% fill)
- **Pressure:** defend 0.17 | search 0.28 | gather 0.56
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.4k → 0
- **Daily calorie need (end):** 25.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=-0.2/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 3 |
| Bone | 0 | 6 |
| Fiber | 6 | 6 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Nuts | 5 | 4 |
| Spear | 0 | 8 |
| Stone | 6 | 0 |
| Wood | 37 | 23 |

#### Failures

- **Gather:** empty_switch:not_harvestable=9, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CAOP | 11 | 1 | 4 | 11 | gather 32%, herd_wildnpc 25%, build_hut_for_woman 14% |
| GOFA | 12 | 0 | 5 | 8 | gather 37%, idle 26%, party 20% |
| GUNA | 9 | 0 | 2 | 8 | gather 76%, hunt 18%, wander 4% |
| HOED | 13 | 0 | 4 | 16 | gather 55%, hunt 20%, eat 13% |
| SOIX | 2 | 0 | 1 | 4 | gather 46%, wander 35%, herd_wildnpc 19% |
| VOOH | 8 | 1 | 3 | 3 | gather 70%, build_milestone 12%, combat 5% |
| XUIZ | 8 | 0 | 1 | 6 | gather 59%, party 23%, wander 10% |
| ZEOJ | 4 | 0 | 1 | 4 | gather 41%, herd_wildnpc 37%, wander 23% |

#### Hunts

- start t=92.3s prey=deer quota=2
- start t=142.3s prey=deer quota=4
- hunt_completed t=125.4s reason=loot_complete
- hunt_completed t=198.6s reason=loot_complete

#### Buildings

- t=50.5s **Living Hut** — herder_hut (builder: CAOP)
- t=130.2s **Living Hut** — herder_hut (builder: CAOP)
- t=172.0s **Drying Rack** — milestone

### YI HAAK

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/2 (69% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.3k → 0
- **Daily calorie need (end):** 23.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 3 |
| Bone | 0 | 6 |
| Fiber | 12 | 6 |
| Grain | 6 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 1 | 0 |
| Nuts | 2 | 1 |
| Spear | 0 | 6 |
| Stone | 6 | 0 |
| Wood | 18 | 3 |

#### Failures

- **Gather:** empty_switch:not_harvestable=3, not_harvestable=2, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FAXE | 19 | 1 | 3 | 8 | gather 73%, eat 11%, party 10% |
| FUKI | 3 | 1 | 0 | 5 | gather 46%, idle 40%, eat 13% |
| GEYU | 17 | 0 | 5 | 9 | gather 43%, herd_wildnpc 27%, build_hut_for_woman 12% |
| GOPA | 9 | 0 | 2 | 9 | gather 47%, idle 25%, herd_wildnpc 21% |
| KEOD | 3 | 0 | 1 | 5 | gather 78%, wander 22% |
| MEKO | 2 | 0 | 0 | 3 | gather 94%, herd_wildnpc 6% |
| QEIC | 7 | 0 | 1 | 3 | gather 93%, eat 7%, wander 0% |
| RUIZ | 14 | 1 | 1 | 6 | gather 70%, wander 12%, party 12% |

#### Hunts

- start t=98.5s prey=deer quota=2
- start t=158.6s prey=deer quota=3
- hunt_completed t=154.9s reason=loot_complete
- hunt_completed t=197.9s reason=loot_complete

#### Buildings

- t=64.1s **Living Hut** — herder_hut (builder: GEYU)

