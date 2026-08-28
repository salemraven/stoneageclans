# ClanBrain Report (standard)

## Session

- **Duration:** 300.6s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_5min_20260620_222341/playtest_session.jsonl`
- **World seed:** 0
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 7
- **Simulation ticks:** 2
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 7/7 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| BI GUNE | 0→13 | 7 | 0 | 26.6k | 0.0 | 2 | 2 | 27 | 33 | 4 | 73% | 110.1s | 6 | 2 | 112.2s |
| KA LOOV | 0→12 | 10 | 0 | 25.6k | 0.0 | 2 | 2 | 40 | 39 | 3 | 87% | 135.1s | 9 | 3 | 152.7s |
| PO YIUH | 0→10 | 7 | 0 | 21.0k | 0.0 | 0 | 0 | 106 | 87 | 0 | 82% | 90.1s | 6 | 2 | — |
| TA VIIX | 0→7 | 1 | 0 | 14.2k | 0.0 | 0 | 0 | 0 | 2 | 0 | 91% | 299.8s | 0 | 0 | — |
| XU ZESO | 0→3 | 1 | 0 | 6.2k | 0.0 | 0 | 0 | 0 | 1 | 0 | 92% | 295.7s | 0 | 0 | — |
| ZE ZILU | 0→9 | 6 | 0 | 18.8k | 0.0 | 3 | 1 | 43 | 54 | 0 | 71% | 80.1s | 5 | 2 | 81.5s |
| ZO NOOH | 0→4 | 1 | 0 | 8.2k | 0.0 | 0 | 0 | 0 | 1 | 0 | 92% | 299.4s | 0 | 0 | — |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 7 / 7
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| BI GUNE | — | — | 73% | 18% | 0→1.7k→0 | 0.0→1.0→0.0 | 110.1s |
| KA LOOV | — | — | 87% | 6% | 0→2.8k→0 | 0.0→1.0→0.0 | 135.1s |
| PO YIUH | — | — | 82% | 14% | 0→520→0 | 0.0→1.0→0.0 | 90.1s |
| TA VIIX | 100% | 0% | 81% | 19% | 0→200→0 | 0.0→1.0→0.0 | 299.8s |
| XU ZESO | — | — | 92% | 8% | 0→200→0 | 0.0→1.0→0.0 | 295.7s |
| ZE ZILU | — | — | 71% | 17% | 0→1.4k→0 | 0.0→1.0→0.0 | 80.1s |
| ZO NOOH | — | — | 92% | 8% | 0→200→0 | 0.0→1.0→0.0 | 299.4s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| BI GUNE | 2 | 2 | 0 | 2 | 0 | 7 | 9 |
| KA LOOV | 2 | 2 | 0 | 2 | 0 | 7 | 7 |
| PO YIUH | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| TA VIIX | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| XU ZESO | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| ZE ZILU | 3 | 1 | 1 | 2 | 0 | 6 | 8 |
| ZO NOOH | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| BI GUNE | 4 | 6 | 6 | 110.0s |
| KA LOOV | 2 | 9 | 9 | 133.7s |
| PO YIUH | 2 | 6 | 6 | 86.6s |
| TA VIIX | 0 | 0 | 0 | — |
| XU ZESO | 0 | 0 | 0 | — |
| ZE ZILU | 2 | 5 | 5 | 81.4s |
| ZO NOOH | 0 | 0 | 0 | — |

## Clansmen workforce

- **Unique clansmen seen:** 26 (gather FSM transitions: 110, productivity snapshots: 10)
- **Last snapshot:** clansmen=26 with_job=17 (all workers job %=63.6363636363636)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| BI GUNE | 6 | 6 | 20 | 22 | 7 | 26 | state_exit_clear_tasks=10, resource_node_invalid=9, task_failed=4 |
| KA LOOV | 9 | 9 | 33 | 28 | 9 | 31 | resource_node_invalid=9, exited_tree=8, state_exit_clear_tasks=7 |
| PO YIUH | 6 | 6 | 76 | 59 | 10 | 19 | assign_job_supersede=12, exited_tree=4, state_exit_clear_tasks=2 |
| TA VIIX | 0 | 0 | 0 | 0 | 0 | 0 | — |
| XU ZESO | 0 | 0 | 0 | 0 | 0 | 0 | — |
| ZE ZILU | 5 | 5 | 42 | 46 | 12 | 12 | exited_tree=6, state_exit_clear_tasks=6 |
| ZO NOOH | 0 | 0 | 0 | 0 | 0 | 0 | — |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BUSU | BI GUNE | 6 | 3 | 14 | 0 | 5 | gather 76%, party 10%, wander 9% |
| CATE | ZE ZILU | 15 | 3 | 13 | 0 | 1 | idle 43%, gather 39%, eat 12% |
| CIYO | PO YIUH | 2 | 0 | 1 | 0 | 1 | gather 57%, wander 42%, idle 1% |
| DOUW | BI GUNE | 1 | 1 | 11 | 0 | 3 | gather 43%, craft 28%, herd_wildnpc 19% |
| FIME | KA LOOV | 0 | 0 | 2 | 0 | 3 | gather 100% |
| HISO | KA LOOV | 0 | 0 | 2 | 0 | 3 | gather 100% |
| HUAM | PO YIUH | 4 | 1 | 20 | 0 | 6 | craft 71%, gather 20%, wander 9% |
| JEHU | KA LOOV | 5 | 1 | 7 | 4 | 5 | gather 72%, build_milestone 13%, craft 8% |
| JIVA | ZE ZILU | 12 | 7 | 13 | 0 | 3 | combat 46%, gather 41%, build_milestone 7% |
| KEIF | PO YIUH | 6 | 0 | 4 | 0 | 1 | gather 91%, wander 9% |
| KOEH | ZE ZILU | 0 | 0 | 1 | 0 | 2 | hunt 67%, build_hut_for_woman 20%, gather 10% |
| KOJE | KA LOOV | 0 | 0 | 3 | 1 | 4 | gather 69%, eat 16%, craft 15% |
| KUYE | PO YIUH | 17 | 1 | 9 | 0 | 3 | gather 47%, idle 37%, eat 9% |
| LAUW | KA LOOV | 1 | 4 | 18 | 0 | 3 | craft 43%, gather 43%, hunt 7% |
| MAVO | BI GUNE | 3 | 1 | 5 | 0 | 3 | gather 55%, build_hut_for_woman 29%, herd_wildnpc 13% |
| MIAX | KA LOOV | 8 | 0 | 2 | 0 | 0 | gather 44%, idle 44%, eat 11% |
| MUED | PO YIUH | 17 | 4 | 11 | 0 | 4 | gather 57%, wander 24%, build_hut_for_woman 15% |
| MUQU | BI GUNE | 6 | 0 | 5 | 0 | 1 | gather 55%, idle 44%, wander 1% |
| NEYU | KA LOOV | 7 | 1 | 2 | 0 | 2 | gather 98%, wander 2% |
| PAIM | ZE ZILU | 8 | 1 | 4 | 0 | 1 | idle 49%, gather 21%, wander 16% |
| QUAC | KA LOOV | 5 | 2 | 12 | 0 | 6 | gather 91%, party 7%, wander 2% |
| QUAM | PO YIUH | 30 | 4 | 13 | 0 | 3 | gather 66%, wander 17%, eat 17% |
| SAYI | ZE ZILU | 7 | 1 | 4 | 0 | 1 | idle 62%, gather 15%, wander 12% |
| TEEH | BI GUNE | 1 | 2 | 9 | 1 | 3 | gather 41%, idle 39%, eat 9% |
| YEUV | KA LOOV | 7 | 1 | 5 | 1 | 1 | gather 53%, eat 16%, idle 15% |
| ZOID | BI GUNE | 3 | 0 | 2 | 1 | 4 | gather 90%, eat 7%, wander 3% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| BI GUNE | 12 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KA LOOV | 11 | 2 | 2 | 2 | 0 | 0 | 0 | 0 |
| PO YIUH | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| TA VIIX | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| XU ZESO | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| ZE ZILU | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| ZO NOOH | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| BI GUNE | 1 | 1 | 0 | 0 |
| KA LOOV | 1 | 1 | 1 | 0 |
| PO YIUH | 0 | 0 | 0 | 0 |
| TA VIIX | 0 | 0 | 0 | 0 |
| XU ZESO | 0 | 0 | 0 | 0 |
| ZE ZILU | 1 | 1 | 0 | 0 |
| ZO NOOH | 0 | 0 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| BI GUNE | 64 | 4 | 94% | 0 | 4 | gather 58%, idle 10%, herd_wildnpc 8% |
| KA LOOV | 69 | 6 | 92% | 0 | 2 | gather 63%, craft 9%, wander 6% |
| PO YIUH | 71 | 0 | 100% | 0 | 1 | gather 53%, wander 17%, craft 11% |
| TA VIIX | 0 | 0 | — | 0 | 0 | herd_wildnpc 66%, wander 26%, eat 4% |
| XU ZESO | 0 | 0 | — | 0 | 1 | herd_wildnpc 92%, wander 5%, eat 4% |
| ZE ZILU | 47 | 0 | 100% | 0 | 0 | gather 27%, idle 20%, combat 18% |
| ZO NOOH | 0 | 0 | — | 0 | 0 | wander 51%, herd_wildnpc 45%, eat 4% |

## Economy (session)

- **Items gathered:** 216
- **Items deposited:** 217
- **Deposit yield:** 100%
- **Gather failures (all):** 7
- **Gather failures (actionable):** 7
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 7

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 6 | 7 | 117% |
| Bone | 0 | 15 | — |
| Fiber | 32 | 26 | 81% |
| Grain | 6 | 0 | 0% |
| Hide | 0 | 18 | — |
| Meat | 0 | 26 | — |
| Mushroom | 30 | 14 | 47% |
| Nuts | 19 | 5 | 26% |
| Spear | 0 | 24 | — |
| Stone | 40 | 26 | 65% |
| Wood | 83 | 56 | 67% |

## Buildings (session)

- **Total placed:** 9

### By type

- **Living Hut:** 8
- **Drying Rack:** 1

### By source

- **herder_hut:** 8
- **milestone:** 1

### Chronological

- t=48.9s **ZE ZILU** — Living Hut (herder_hut) builder=MEBA @ (1102,-2541)
- t=54.0s **PO YIUH** — Living Hut (herder_hut) builder=QOUL @ (499,-403)
- t=77.5s **BI GUNE** — Living Hut (herder_hut) builder=QAES @ (-2450,-977)
- t=101.2s **KA LOOV** — Living Hut (herder_hut) builder=YUPA @ (-1679,3181)
- t=121.2s **KA LOOV** — Living Hut (herder_hut) builder=YUPA @ (-1617,3117)
- t=226.8s **PO YIUH** — Living Hut (herder_hut) builder=MUED @ (409,-625)
- t=228.7s **KA LOOV** — Drying Rack (milestone) @ (-1847,3054)
- t=280.5s **BI GUNE** — Living Hut (herder_hut) builder=MAVO @ (-2622,-1127)
- t=284.8s **ZE ZILU** — Living Hut (herder_hut) builder=KOEH @ (1225,-2336)

## Per-clan detail

### BI GUNE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/2 (73% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.7k → 0
- **Daily calorie need (end):** 26.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Fiber | 5 | 5 |
| Grain | 3 | 0 |
| Hide | 0 | 6 |
| Meat | 0 | 8 |
| Mushroom | 7 | 0 |
| Nuts | 1 | 0 |
| Spear | 0 | 5 |
| Stone | 6 | 2 |
| Wood | 5 | 1 |

#### Failures

- **Gather:** resource_invalid=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BUSU | 14 | 0 | 3 | 6 | gather 76%, party 10%, wander 9% |
| DOUW | 11 | 0 | 1 | 1 | gather 43%, craft 28%, herd_wildnpc 19% |
| MAVO | 5 | 0 | 1 | 3 | gather 55%, build_hut_for_woman 29%, herd_wildnpc 13% |
| MUQU | 5 | 0 | 0 | 6 | gather 55%, idle 44%, wander 1% |
| QAES | 18 | 2 | 6 | 7 | gather 61%, herd_wildnpc 16%, hunt 7% |
| TEEH | 9 | 1 | 2 | 1 | gather 41%, idle 39%, eat 9% |
| ZOID | 2 | 1 | 0 | 3 | gather 90%, eat 7%, wander 3% |

#### Hunts

- start t=112.2s prey=deer quota=2
- start t=157.2s prey=deer quota=2
- hunt_completed t=153.9s reason=loot_complete
- hunt_completed t=205.6s reason=loot_complete

#### Buildings

- t=77.5s **Living Hut** — herder_hut (builder: QAES)
- t=280.5s **Living Hut** — herder_hut (builder: MAVO)

### KA LOOV

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/3 (87% fill)
- **Pressure:** defend 0.12 | search 0.29 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.8k → 0
- **Daily calorie need (end):** 25.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Fiber | 6 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 9 | 3 |
| Nuts | 4 | 0 |
| Spear | 0 | 6 |
| Stone | 11 | 3 |
| Wood | 10 | 3 |

#### Failures

- **Gather:** resource_invalid=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FIME | 2 | 0 | 0 | 0 | gather 100% |
| HISO | 2 | 0 | 0 | 0 | gather 100% |
| JEHU | 7 | 4 | 1 | 5 | gather 72%, build_milestone 13%, craft 8% |
| KOJE | 3 | 1 | 0 | 0 | gather 69%, eat 16%, craft 15% |
| LAUW | 18 | 0 | 4 | 1 | craft 43%, gather 43%, hunt 7% |
| MIAX | 2 | 0 | 0 | 8 | gather 44%, idle 44%, eat 11% |
| NEYU | 2 | 0 | 1 | 7 | gather 98%, wander 2% |
| QUAC | 12 | 0 | 2 | 5 | gather 91%, party 7%, wander 2% |
| YEUV | 5 | 1 | 1 | 7 | gather 53%, eat 16%, idle 15% |
| YUPA | 8 | 0 | 5 | 7 | gather 41%, wander 20%, herd_wildnpc 16% |

#### Hunts

- start t=152.7s prey=deer quota=2
- start t=197.7s prey=deer quota=3
- hunt_completed t=197.1s reason=loot_complete
- hunt_completed t=218.3s reason=loot_complete

#### Buildings

- t=101.2s **Living Hut** — herder_hut (builder: YUPA)
- t=121.2s **Living Hut** — herder_hut (builder: YUPA)
- t=228.7s **Drying Rack** — milestone

### PO YIUH

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (82% fill)
- **Pressure:** defend 0.12 | search 0.29 | gather 0.58
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 520 → 0
- **Daily calorie need (end):** 21.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 6 |
| Fiber | 18 | 18 |
| Grain | 3 | 0 |
| Mushroom | 13 | 10 |
| Nuts | 8 | 4 |
| Spear | 0 | 5 |
| Stone | 18 | 20 |
| Wood | 40 | 24 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CIYO | 1 | 0 | 0 | 2 | gather 57%, wander 42%, idle 1% |
| HUAM | 20 | 0 | 1 | 4 | craft 71%, gather 20%, wander 9% |
| KEIF | 4 | 0 | 0 | 6 | gather 91%, wander 9% |
| KUYE | 9 | 0 | 1 | 17 | gather 47%, idle 37%, eat 9% |
| MUED | 11 | 0 | 4 | 17 | gather 57%, wander 24%, build_hut_for_woman 15% |
| QOUL | 13 | 0 | 10 | 30 | gather 62%, wander 21%, herd_wildnpc 11% |
| QUAM | 13 | 0 | 4 | 30 | gather 66%, wander 17%, eat 17% |

#### Buildings

- t=54.0s **Living Hut** — herder_hut (builder: QOUL)
- t=226.8s **Living Hut** — herder_hut (builder: MUED)

### TA VIIX

- **Brain:** DEFENSIVE | alert RAID | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 1/1 (100% fill) | searchers 0/0 (81% fill)
- **Pressure:** defend 0.25 | search 0.25 | gather 0.5
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 14.2k
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
| QOLI | 0 | 0 | 2 | 0 | herd_wildnpc 66%, wander 26%, eat 4% |

### XU ZESO

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (92% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
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
| NIAM | 0 | 0 | 1 | 0 | herd_wildnpc 92%, wander 5%, eat 4% |

### ZE ZILU

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (71% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.4k → 0
- **Daily calorie need (end):** 18.8k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 3 |
| Fiber | 3 | 3 |
| Hide | 0 | 4 |
| Meat | 0 | 8 |
| Mushroom | 1 | 1 |
| Nuts | 6 | 1 |
| Spear | 0 | 5 |
| Stone | 5 | 1 |
| Wood | 28 | 28 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CATE | 13 | 0 | 3 | 15 | idle 43%, gather 39%, eat 12% |
| JIVA | 13 | 0 | 7 | 12 | combat 46%, gather 41%, build_milestone 7% |
| KOEH | 1 | 0 | 0 | 0 | hunt 67%, build_hut_for_woman 20%, gather 10% |
| MEBA | 12 | 0 | 5 | 1 | combat 34%, gather 28%, herd_wildnpc 19% |
| PAIM | 4 | 0 | 1 | 8 | idle 49%, gather 21%, wander 16% |
| SAYI | 4 | 0 | 1 | 7 | idle 62%, gather 15%, wander 12% |

#### Hunts

- start t=81.5s prey=deer quota=2
- start t=126.6s prey=deer quota=2
- start t=256.7s prey=deer quota=4
- hunt_completed t=122.9s reason=loot_complete
- hunt_aborted t=246.6s reason=active_timeout

#### Buildings

- t=48.9s **Living Hut** — herder_hut (builder: MEBA)
- t=284.8s **Living Hut** — herder_hut (builder: KOEH)

### ZO NOOH

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (92% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 8.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| TIRI | 0 | 0 | 1 | 0 | wander 51%, herd_wildnpc 45%, eat 4% |

