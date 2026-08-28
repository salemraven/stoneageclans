# ClanBrain Report (standard)

## Session

- **Duration:** 900.9s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_15min_20260622_174037/playtest_session.jsonl`
- **World seed:** 0
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 7
- **Simulation ticks:** 4
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 7/7 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| CE VIUN | 0→2 | 1 | 440 | 4.2k | 0.1 | 1 | 0 | 13 | 15 | 0 | 18% | 897.5s | 0 | 0 | 3.4s |
| CU BUAB | 0→21 | 15 | 500 | 42.0k | 0.0 | 6 | 5 | 190 | 222 | 5 | 75% | 166.2s | 15 | 2 | 4.4s |
| FU NEIV | 0→12 | 1 | 0 | 24.2k | 0.0 | 0 | 0 | 0 | 2 | 0 | 91% | 893.2s | 0 | 0 | — |
| HI MAIP | 0→12 | 6 | 0 | 25.0k | 0.0 | 1 | 0 | 148 | 106 | 3 | 88% | 166.2s | 5 | 2 | 4.4s |
| KA PAHE | 0→6 | 4 | 0 | 12.4k | 0.0 | 0 | 0 | 71 | 42 | 5 | 91% | 166.1s | 3 | 2 | — |
| QE LIOY | 0→16 | 5 | 0 | 32.6k | 0.0 | 0 | 0 | 81 | 49 | 4 | 54% | 156.3s | 4 | 2 | — |
| VA KUEF | 0→3 | 1 | 200 | 6.2k | 0.0 | 0 | 0 | 0 | 1 | 0 | 87% | 128.7s | 0 | 0 | — |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 5 / 5
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| CE VIUN | — | — | 18% | 82% | 200→440→440 | 0.0→1.0→0.1 | 897.5s |
| CU BUAB | — | — | 75% | 71% | 0→1.4k→500 | 0.0→1.0→0.0 | 166.2s |
| FU NEIV | — | — | 91% | 9% | 0→200→0 | 0.0→1.0→0.0 | 893.2s |
| HI MAIP | — | — | 88% | 57% | 0→200→0 | 0.0→1.0→0.0 | 166.2s |
| KA PAHE | — | — | 91% | 14% | 0→310→0 | 0.0→1.0→0.0 | 166.1s |
| QE LIOY | — | — | 54% | 17% | 0→280→0 | 0.0→1.0→0.0 | 156.3s |
| VA KUEF | — | — | 87% | 13% | 200→200→200 | 0.0→1.0→0.0 | 128.7s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| CE VIUN | 1 | 0 | 0 | 1 | 0 | 0 | 0 |
| CU BUAB | 6 | 5 | 1 | 5 | 0 | 17 | 20 |
| FU NEIV | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HI MAIP | 1 | 0 | 1 | 0 | 0 | 0 | 0 |
| KA PAHE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE LIOY | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| VA KUEF | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| CE VIUN | 0 | 0 | 0 | — |
| CU BUAB | 2 | 17 | 15 | 169.4s |
| FU NEIV | 0 | 0 | 0 | — |
| HI MAIP | 1 | 5 | 5 | 168.6s |
| KA PAHE | 2 | 3 | 3 | 170.1s |
| QE LIOY | 2 | 4 | 4 | 159.0s |
| VA KUEF | 0 | 0 | 0 | — |

## Clansmen workforce

- **Unique clansmen seen:** 27 (gather FSM transitions: 336, productivity snapshots: 16)
- **Last snapshot:** clansmen=26 with_job=12 (all workers job %=46.875)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| CE VIUN | 0 | 0 | 0 | 0 | 0 | 0 | — |
| CU BUAB | 15 | 15 | 165 | 191 | 51 | 89 | state_exit_clear_tasks=39, assign_job_supersede=20, resource_node_invalid=11 |
| FU NEIV | 0 | 0 | 0 | 0 | 0 | 0 | — |
| HI MAIP | 5 | 5 | 105 | 67 | 14 | 23 | state_exit_clear_tasks=9, task_failed=5, gather_lease_expired=4 |
| KA PAHE | 3 | 3 | 40 | 18 | 3 | 25 | state_exit_clear_tasks=9, resource_node_invalid=8, task_failed=5 |
| QE LIOY | 4 | 4 | 46 | 16 | 3 | 20 | state_exit_clear_tasks=8, resource_node_invalid=5, task_failed=4 |
| VA KUEF | 0 | 0 | 0 | 0 | 0 | 0 | — |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| DIKE | CU BUAB | 6 | 1 | 4 | 0 | 3 | gather 46%, idle 29%, eat 13% |
| GUIZ | QE LIOY | 13 | 1 | 6 | 1 | 4 | gather 41%, idle 37%, herd_wildnpc 13% |
| HIAF | CU BUAB | 26 | 7 | 24 | 0 | 7 | gather 61%, idle 16%, eat 14% |
| HOEM | KA PAHE | 8 | 1 | 7 | 2 | 8 | gather 39%, idle 37%, combat 16% |
| HOVU | HI MAIP | 12 | 0 | 8 | 0 | 0 | idle 50%, gather 31%, eat 19% |
| HUID | QE LIOY | 13 | 1 | 12 | 1 | 8 | gather 46%, idle 31%, herd_wildnpc 13% |
| KAHI | QE LIOY | 8 | 0 | 5 | 1 | 1 | idle 84%, gather 14%, eat 2% |
| KEAM | HI MAIP | 25 | 2 | 13 | 0 | 7 | gather 71%, idle 14%, eat 11% |
| MAID | CU BUAB | 12 | 2 | 14 | 0 | 4 | gather 58%, idle 28%, eat 7% |
| REAS | HI MAIP | 6 | 1 | 11 | 0 | 1 | craft 53%, gather 32%, wander 15% |
| RIEP | QE LIOY | 12 | 1 | 7 | 0 | 3 | gather 44%, idle 40%, build_hut_for_woman 7% |
| RIHE | CU BUAB | 7 | 2 | 11 | 0 | 8 | gather 56%, idle 31%, eat 5% |
| SUDU | KA PAHE | 18 | 1 | 11 | 0 | 5 | gather 75%, idle 7%, wander 7% |
| SUFO | CU BUAB | 3 | 1 | 6 | 0 | 3 | gather 81%, wander 10%, hunt 8% |
| TOAR | CU BUAB | 9 | 2 | 5 | 1 | 3 | idle 57%, gather 30%, wander 7% |
| TOIZ | CU BUAB | 0 | 3 | 10 | 1 | 8 | gather 83%, party 14%, hunt 2% |
| VEUR | CU BUAB | 25 | 6 | 15 | 1 | 5 | gather 43%, idle 38%, eat 13% |
| WADI | CU BUAB | 6 | 3 | 4 | 0 | 1 | gather 92%, wander 4%, eat 3% |
| WEID | CU BUAB | 17 | 8 | 23 | 1 | 11 | gather 74%, combat 17%, eat 4% |
| WEOG | CU BUAB | 9 | 2 | 14 | 0 | 3 | idle 45%, gather 44%, party 6% |
| WERI | CU BUAB | 4 | 1 | 9 | 1 | 8 | flee_combat 51%, gather 46%, wander 1% |
| XADI | KA PAHE | 14 | 1 | 16 | 1 | 6 | gather 47%, idle 31%, craft 18% |
| XUHE | CU BUAB | 7 | 3 | 11 | 0 | 5 | gather 86%, party 11%, wander 2% |
| XUOC | CU BUAB | 21 | 6 | 26 | 0 | 4 | gather 46%, idle 21%, wander 10% |
| YIGU | HI MAIP | 38 | 7 | 22 | 0 | 4 | gather 63%, wander 18%, eat 10% |
| YIOJ | HI MAIP | 24 | 4 | 16 | 2 | 5 | gather 53%, craft 15%, idle 11% |
| ZESA | CU BUAB | 13 | 4 | 8 | 0 | 3 | idle 41%, gather 37%, eat 9% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| CE VIUN | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| CU BUAB | 32 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| FU NEIV | 32 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HI MAIP | 32 | 1 | 1 | 1 | 0 | 0 | 0 | 0 |
| KA PAHE | 32 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE LIOY | 32 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| VA KUEF | 5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| CE VIUN | 0 | 0 | 0 | 0 |
| CU BUAB | 2 | 3 | 0 | 1 |
| FU NEIV | 0 | 0 | 0 | 0 |
| HI MAIP | 1 | 1 | 1 | 0 |
| KA PAHE | 0 | 0 | 0 | 0 |
| QE LIOY | 0 | 0 | 0 | 0 |
| VA KUEF | 0 | 0 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| CE VIUN | 8 | 0 | 100% | 0 | 0 | herd_wildnpc 64%, hunt 22%, gather 8% |
| CU BUAB | 217 | 5 | 98% | 0 | 24 | gather 53%, idle 21%, wander 7% |
| FU NEIV | 0 | 0 | — | 0 | 1 | herd_wildnpc 67%, wander 31%, eat 3% |
| HI MAIP | 99 | 5 | 95% | 0 | 18 | gather 56%, wander 13%, idle 11% |
| KA PAHE | 52 | 5 | 91% | 0 | 22 | gather 55%, idle 18%, wander 10% |
| QE LIOY | 49 | 4 | 92% | 0 | 15 | gather 40%, idle 34%, wander 11% |
| VA KUEF | 0 | 0 | — | 0 | 0 | herd_wildnpc 91%, wander 9% |

## Economy (session)

- **Items gathered:** 503
- **Items deposited:** 437
- **Deposit yield:** 87%
- **Gather failures (all):** 28
- **Gather failures (actionable):** 17
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 11
- **resource_invalid:** 11
- **not_harvestable:** 5
- **moved_during_gather:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 33 | 23 | 70% |
| Bone | 0 | 15 | — |
| Fiber | 39 | 33 | 85% |
| Grain | 40 | 26 | 65% |
| Hide | 0 | 20 | — |
| Meat | 0 | 25 | — |
| Mushroom | 38 | 13 | 34% |
| Nuts | 49 | 21 | 43% |
| Spear | 0 | 32 | — |
| Stone | 133 | 114 | 86% |
| Wood | 171 | 115 | 67% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 7
- **Oven:** 1

### By source

- **herder_hut:** 7
- **milestone:** 1

### Chronological

- t=95.7s **QE LIOY** — Living Hut (herder_hut) builder=VUXE @ (-1353,2833)
- t=105.1s **HI MAIP** — Living Hut (herder_hut) builder=YOUW @ (2024,625)
- t=105.8s **CU BUAB** — Living Hut (herder_hut) builder=PIIY @ (-416,-2312)
- t=106.5s **KA PAHE** — Living Hut (herder_hut) builder=BIFO @ (-2629,926)
- t=447.2s **CU BUAB** — Living Hut (herder_hut) builder=XUOC @ (-272,-2130)
- t=521.4s **QE LIOY** — Living Hut (herder_hut) builder=RIEP @ (-1406,2916)
- t=654.1s **HI MAIP** — Oven (milestone) @ (2093,561)
- t=802.0s **KA PAHE** — Living Hut (herder_hut) builder=SUDU @ (-2493,1124)

## Per-clan detail

### CE VIUN

- **Brain:** PEACEFUL | alert NONE | hunt RECRUITING | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/1 (18% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.1
- **Calories in storage:** 200 → 440 → 440
- **Daily calorie need (end):** 4.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.1
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 4 |
| Fiber | 3 | 3 |
| Nuts | 1 | 1 |
| Spear | 0 | 1 |
| Stone | 3 | 3 |
| Wood | 3 | 3 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| TEAQ | 8 | 0 | 6 | 13 | herd_wildnpc 64%, hunt 22%, gather 8% |

#### Hunts

- start t=3.4s prey=deer quota=1

### CU BUAB

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (75% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.4k → 500
- **Daily calorie need (end):** 42.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.12/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 12 | 3 |
| Bone | 0 | 15 |
| Fiber | 18 | 18 |
| Grain | 25 | 17 |
| Hide | 0 | 20 |
| Meat | 0 | 25 |
| Mushroom | 10 | 4 |
| Nuts | 12 | 8 |
| Spear | 0 | 16 |
| Stone | 74 | 60 |
| Wood | 39 | 36 |

#### Failures

- **Gather:** empty_switch:not_harvestable=8, not_harvestable=4, moved_during_gather=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DIKE | 4 | 0 | 1 | 6 | gather 46%, idle 29%, eat 13% |
| HIAF | 24 | 0 | 7 | 26 | gather 61%, idle 16%, eat 14% |
| MAID | 14 | 0 | 2 | 12 | gather 58%, idle 28%, eat 7% |
| PIIY | 33 | 0 | 12 | 25 | gather 57%, wander 16%, hunt 12% |
| RIHE | 11 | 0 | 2 | 7 | gather 56%, idle 31%, eat 5% |
| SUFO | 6 | 0 | 1 | 3 | gather 81%, wander 10%, hunt 8% |
| TOAR | 5 | 1 | 2 | 9 | idle 57%, gather 30%, wander 7% |
| TOIZ | 10 | 1 | 3 | 0 | gather 83%, party 14%, hunt 2% |
| VEUR | 15 | 1 | 6 | 25 | gather 43%, idle 38%, eat 13% |
| WADI | 4 | 0 | 3 | 6 | gather 92%, wander 4%, eat 3% |
| WEID | 23 | 1 | 8 | 17 | gather 74%, combat 17%, eat 4% |
| WEOG | 14 | 0 | 2 | 9 | idle 45%, gather 44%, party 6% |
| WERI | 9 | 1 | 1 | 4 | flee_combat 51%, gather 46%, wander 1% |
| XUHE | 11 | 0 | 3 | 7 | gather 86%, party 11%, wander 2% |
| XUOC | 26 | 0 | 6 | 21 | gather 46%, idle 21%, wander 10% |
| ZESA | 8 | 0 | 4 | 13 | idle 41%, gather 37%, eat 9% |

#### Hunts

- start t=4.4s prey=deer quota=1
- start t=180.4s prey=deer quota=2
- start t=471.7s prey=deer quota=3
- start t=776.0s prey=deer quota=8
- start t=837.2s prey=deer quota=8
- start t=862.9s prey=deer quota=8
- hunt_aborted t=170.8s reason=recruitment_timeout
- hunt_completed t=340.4s reason=loot_complete
- hunt_completed t=504.6s reason=loot_complete
- hunt_completed t=799.6s reason=loot_complete
- hunt_completed t=847.1s reason=loot_complete
- hunt_completed t=880.7s reason=loot_complete

#### Buildings

- t=105.8s **Living Hut** — herder_hut (builder: PIIY)
- t=447.2s **Living Hut** — herder_hut (builder: XUOC)

### FU NEIV

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (91% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 24.2k
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
| QOKO | 0 | 0 | 2 | 0 | herd_wildnpc 67%, wander 31%, eat 3% |

### HI MAIP

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (88% fill)
- **Pressure:** defend 0.13 | search 0.29 | gather 0.58
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 25.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 18 | 15 |
| Fiber | 18 | 12 |
| Grain | 15 | 9 |
| Mushroom | 11 | 2 |
| Nuts | 9 | 3 |
| Spear | 0 | 5 |
| Stone | 37 | 31 |
| Wood | 40 | 29 |

#### Failures

- **Gather:** empty_switch:not_harvestable=2, resource_invalid=2, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| HOVU | 8 | 0 | 0 | 12 | idle 50%, gather 31%, eat 19% |
| KEAM | 13 | 0 | 2 | 25 | gather 71%, idle 14%, eat 11% |
| REAS | 11 | 0 | 1 | 6 | craft 53%, gather 32%, wander 15% |
| YIGU | 22 | 0 | 7 | 38 | gather 63%, wander 18%, eat 10% |
| YIOJ | 16 | 2 | 4 | 24 | gather 53%, craft 15%, idle 11% |
| YOUW | 23 | 1 | 13 | 43 | gather 54%, wander 22%, hunt 8% |

#### Hunts

- start t=4.4s prey=deer quota=1
- hunt_aborted t=170.8s reason=recruitment_timeout

#### Buildings

- t=105.1s **Living Hut** — herder_hut (builder: YOUW)
- t=654.1s **Oven** — milestone

### KA PAHE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (91% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 310 → 0
- **Daily calorie need (end):** 12.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Mushroom | 9 | 1 |
| Nuts | 12 | 4 |
| Spear | 0 | 4 |
| Stone | 13 | 14 |
| Wood | 37 | 19 |

#### Failures

- **Gather:** resource_invalid=5, empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIFO | 18 | 2 | 9 | 31 | gather 60%, wander 26%, herd_wildnpc 7% |
| HOEM | 7 | 2 | 1 | 8 | gather 39%, idle 37%, combat 16% |
| SUDU | 11 | 0 | 1 | 18 | gather 75%, idle 7%, wander 7% |
| XADI | 16 | 1 | 1 | 14 | gather 47%, idle 31%, craft 18% |

#### Buildings

- t=106.5s **Living Hut** — herder_hut (builder: BIFO)
- t=802.0s **Living Hut** — herder_hut (builder: SUDU)

### QE LIOY

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/2 (54% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 280 → 0
- **Daily calorie need (end):** 32.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Mushroom | 8 | 6 |
| Nuts | 15 | 5 |
| Spear | 0 | 4 |
| Stone | 6 | 6 |
| Wood | 52 | 28 |

#### Failures

- **Gather:** resource_invalid=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GUIZ | 6 | 1 | 1 | 13 | gather 41%, idle 37%, herd_wildnpc 13% |
| HUID | 12 | 1 | 1 | 13 | gather 46%, idle 31%, herd_wildnpc 13% |
| KAHI | 5 | 1 | 0 | 8 | idle 84%, gather 14%, eat 2% |
| RIEP | 7 | 0 | 1 | 12 | gather 44%, idle 40%, build_hut_for_woman 7% |
| VUXE | 19 | 1 | 12 | 35 | gather 49%, wander 33%, herd_wildnpc 12% |

#### Buildings

- t=95.7s **Living Hut** — herder_hut (builder: VUXE)
- t=521.4s **Living Hut** — herder_hut (builder: RIEP)

### VA KUEF

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (87% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 200 → 200 → 200
- **Daily calorie need (end):** 6.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| LAAP | 0 | 0 | 1 | 0 | herd_wildnpc 91%, wander 9% |

