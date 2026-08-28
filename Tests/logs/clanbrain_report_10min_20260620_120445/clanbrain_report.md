# ClanBrain Report (standard)

## Session

- **Duration:** 600.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_10min_20260620_120445/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 10 min
- **AI clans with eval:** 4
- **Simulation ticks:** 5
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| KI ZAOW | 0→27 | 21 | 0 | 57.6k | 0.0 | 4 | 3 | 276 | 257 | 9 | 82% | 85.1s | 20 | 4 | 86.8s |
| MO NIYU | 0→23 | 17 | 0 | 48.6k | 0.0 | 2 | 2 | 346 | 294 | 13 | 87% | 70.1s | 16 | 5 | 72.1s |
| RI CUIL | 0→23 | 9 | 750 | 46.8k | 0.0 | 4 | 3 | 125 | 131 | 1 | 80% | 65.1s | 8 | 3 | 68.6s |
| WA PAIT | 0→16 | 12 | 0 | 32.7k | 0.0 | 3 | 2 | 218 | 183 | 19 | 83% | 75.1s | 11 | 3 | 75.8s |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 13 / 13
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| KI ZAOW | — | — | 82% | 17% | 0→1.9k→0 | 0.0→1.0→0.0 | 85.1s |
| MO NIYU | — | — | 87% | 33% | 0→3.2k→0 | 0.0→1.0→0.0 | 70.1s |
| RI CUIL | — | — | 80% | 33% | 0→1.4k→750 | 0.0→1.0→0.0 | 65.1s |
| WA PAIT | — | — | 83% | 20% | 0→1.5k→0 | 0.0→1.0→0.0 | 75.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| KI ZAOW | 4 | 3 | 1 | 3 | 0 | 9 | 10 |
| MO NIYU | 2 | 2 | 0 | 2 | 0 | 7 | 7 |
| RI CUIL | 4 | 3 | 1 | 3 | 0 | 9 | 12 |
| WA PAIT | 3 | 2 | 1 | 2 | 0 | 7 | 7 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| KI ZAOW | 3 | 20 | 20 | 83.3s |
| MO NIYU | 4 | 16 | 16 | 68.4s |
| RI CUIL | 2 | 9 | 8 | 68.4s |
| WA PAIT | 2 | 12 | 11 | 74.4s |

## Clansmen workforce

- **Unique clansmen seen:** 55 (gather FSM transitions: 540, productivity snapshots: 20)
- **Last snapshot:** clansmen=51 with_job=23 (all workers job %=47.2727272727273)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| KI ZAOW | 20 | 20 | 247 | 233 | 42 | 82 | state_exit_clear_tasks=39, assign_job_supersede=18, task_failed=15 |
| MO NIYU | 16 | 16 | 301 | 254 | 54 | 66 | state_exit_clear_tasks=29, assign_job_supersede=14, task_failed=14 |
| RI CUIL | 8 | 8 | 92 | 91 | 19 | 26 | state_exit_clear_tasks=12, exited_tree=7, assign_job_supersede=5 |
| WA PAIT | 11 | 11 | 191 | 156 | 32 | 64 | state_exit_clear_tasks=20, task_failed=19, assign_job_supersede=13 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BEXO | WA PAIT | 9 | 2 | 11 | 3 | 7 | gather 58%, idle 13%, eat 8% |
| BIHA | MO NIYU | 28 | 5 | 17 | 0 | 3 | gather 74%, wander 21%, idle 4% |
| BIIX | KI ZAOW | 8 | 1 | 10 | 0 | 4 | gather 77%, combat 12%, wander 10% |
| BOOV | RI CUIL | 16 | 2 | 10 | 0 | 3 | gather 47%, herd_wildnpc 30%, build_milestone 13% |
| DAAG | MO NIYU | 18 | 2 | 9 | 1 | 2 | idle 66%, gather 17%, eat 14% |
| DERE | MO NIYU | 13 | 4 | 17 | 1 | 5 | gather 38%, idle 37%, eat 10% |
| DEUJ | RI CUIL | 7 | 4 | 13 | 0 | 3 | idle 37%, gather 26%, combat 18% |
| DICI | KI ZAOW | 12 | 2 | 7 | 0 | 1 | gather 47%, herd_wildnpc 19%, wander 14% |
| DUAL | MO NIYU | 30 | 4 | 19 | 1 | 3 | gather 51%, idle 31%, wander 12% |
| DURI | WA PAIT | 9 | 3 | 11 | 1 | 5 | gather 49%, hunt 22%, combat 18% |
| GEQU | MO NIYU | 13 | 1 | 6 | 0 | 0 | idle 67%, eat 14%, gather 10% |
| GOIL | MO NIYU | 16 | 5 | 11 | 0 | 4 | gather 52%, combat 37%, wander 6% |
| GOYI | KI ZAOW | 2 | 0 | 3 | 1 | 2 | gather 100% |
| GUIT | KI ZAOW | 9 | 4 | 17 | 2 | 8 | gather 47%, combat 35%, craft 6% |
| HAIR | KI ZAOW | 0 | 0 | 1 | 0 | 1 | combat 72%, gather 28% |
| HEOZ | MO NIYU | 20 | 5 | 15 | 0 | 4 | gather 73%, wander 15%, herd_wildnpc 10% |
| JAPE | MO NIYU | 36 | 4 | 20 | 0 | 6 | gather 73%, wander 18%, build_hut_for_woman 5% |
| JEXA | RI CUIL | 0 | 3 | 7 | 0 | 4 | idle 46%, combat 19%, gather 18% |
| JUIT | WA PAIT | 5 | 0 | 2 | 0 | 0 | flee_combat 40%, idle 38%, gather 17% |
| JUPI | KI ZAOW | 4 | 1 | 4 | 0 | 1 | idle 58%, gather 24%, eat 9% |
| KEAZ | MO NIYU | 10 | 2 | 13 | 1 | 5 | idle 47%, gather 37%, eat 12% |
| KEIK | WA PAIT | 8 | 0 | 6 | 2 | 6 | gather 77%, flee_combat 20%, idle 2% |
| KUGE | KI ZAOW | 36 | 7 | 25 | 0 | 4 | gather 47%, hunt 23%, wander 16% |
| LAGU | KI ZAOW | 38 | 5 | 36 | 0 | 6 | gather 63%, craft 15%, wander 13% |
| LEWI | KI ZAOW | 15 | 2 | 11 | 1 | 6 | gather 78%, wander 20%, eat 2% |
| LIEF | WA PAIT | 14 | 2 | 12 | 1 | 5 | gather 41%, idle 26%, combat 19% |
| MACE | RI CUIL | 11 | 1 | 10 | 0 | 3 | gather 85%, eat 8%, wander 7% |
| MAIY | MO NIYU | 33 | 6 | 16 | 0 | 3 | gather 70%, wander 27%, eat 4% |
| MECU | KI ZAOW | 12 | 1 | 11 | 0 | 4 | gather 53%, idle 16%, combat 16% |
| MEOM | KI ZAOW | 16 | 1 | 6 | 0 | 0 | gather 54%, idle 30%, wander 10% |
| NEET | KI ZAOW | 5 | 0 | 2 | 0 | 0 | gather 70%, idle 29%, wander 1% |
| PAHU | KI ZAOW | 14 | 4 | 15 | 0 | 4 | gather 60%, wander 12%, idle 12% |
| RAIC | WA PAIT | 18 | 4 | 14 | 2 | 7 | gather 58%, combat 20%, craft 6% |
| RAPU | KI ZAOW | 0 | 2 | 20 | 2 | 7 | gather 40%, combat 36%, craft 15% |
| REBE | WA PAIT | 16 | 5 | 22 | 3 | 7 | gather 49%, combat 19%, build_milestone 12% |
| ROET | MO NIYU | 17 | 2 | 11 | 3 | 5 | gather 58%, combat 28%, wander 10% |
| SIQU | WA PAIT | 28 | 3 | 22 | 2 | 10 | gather 74%, wander 10%, eat 8% |
| TEYO | MO NIYU | 16 | 3 | 11 | 1 | 5 | gather 86%, wander 12%, eat 2% |
| TOXE | MO NIYU | 7 | 0 | 4 | 0 | 0 | idle 65%, build_milestone 13%, eat 13% |
| VILI | RI CUIL | 13 | 1 | 14 | 1 | 4 | gather 38%, herd_wildnpc 30%, flee_combat 15% |
| VOWA | KI ZAOW | 12 | 2 | 14 | 1 | 5 | gather 64%, idle 16%, wander 15% |
| WAEX | MO NIYU | 16 | 4 | 8 | 2 | 3 | gather 51%, combat 30%, wander 17% |
| WAIQ | WA PAIT | 25 | 3 | 14 | 0 | 2 | gather 47%, combat 30%, wander 13% |
| WIEZ | RI CUIL | 12 | 1 | 7 | 0 | 2 | gather 86%, eat 9%, wander 5% |
| WOOZ | KI ZAOW | 14 | 1 | 9 | 1 | 1 | idle 49%, gather 34%, eat 13% |
| WORO | MO NIYU | 7 | 1 | 6 | 1 | 5 | gather 54%, combat 42%, wander 3% |
| WURO | KI ZAOW | 17 | 3 | 16 | 2 | 6 | gather 57%, build_milestone 12%, idle 11% |
| XEAL | RI CUIL | 13 | 3 | 10 | 0 | 2 | gather 49%, herd_wildnpc 18%, idle 17% |
| XONO | WA PAIT | 30 | 4 | 21 | 2 | 4 | gather 53%, combat 19%, idle 13% |
| XUOW | KI ZAOW | 13 | 1 | 12 | 3 | 7 | gather 57%, craft 33%, wander 8% |
| YAAP | RI CUIL | 20 | 4 | 17 | 0 | 3 | gather 33%, hunt 24%, herd_wildnpc 23% |
| YUOJ | MO NIYU | 21 | 6 | 32 | 2 | 6 | gather 57%, craft 21%, herd_wildnpc 12% |
| ZAXE | KI ZAOW | 16 | 5 | 18 | 1 | 6 | gather 60%, build_milestone 13%, wander 10% |
| ZIIL | WA PAIT | 29 | 6 | 17 | 1 | 6 | gather 58%, wander 22%, herd_wildnpc 15% |
| ZOEZ | KI ZAOW | 4 | 0 | 2 | 1 | 4 | gather 93%, eat 4%, herd_wildnpc 3% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| KI ZAOW | 34 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MO NIYU | 35 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| RI CUIL | 35 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| WA PAIT | 35 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| KI ZAOW | 3 | 5 | 2 | 2 |
| MO NIYU | 4 | 4 | 3 | 0 |
| RI CUIL | 3 | 3 | 1 | 0 |
| WA PAIT | 4 | 4 | 2 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| KI ZAOW | 262 | 15 | 95% | 0 | 25 | gather 52%, combat 10%, wander 9% |
| MO NIYU | 251 | 14 | 95% | 0 | 26 | gather 49%, idle 21%, wander 11% |
| RI CUIL | 126 | 1 | 99% | 0 | 4 | gather 38%, idle 16%, herd_wildnpc 13% |
| WA PAIT | 173 | 19 | 90% | 0 | 19 | gather 49%, combat 14%, wander 8% |

## Economy (session)

- **Items gathered:** 965
- **Items deposited:** 865
- **Deposit yield:** 90%
- **Gather failures (all):** 139
- **Gather failures (actionable):** 42
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 97
- **not_harvestable:** 30
- **resource_invalid:** 12

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 63 | 35 | 56% |
| Bone | 0 | 27 | — |
| Fiber | 42 | 30 | 71% |
| Grain | 63 | 40 | 63% |
| Hide | 0 | 36 | — |
| Meat | 0 | 48 | — |
| Mushroom | 11 | 4 | 36% |
| Nuts | 157 | 98 | 62% |
| Spear | 0 | 52 | — |
| Stone | 68 | 58 | 85% |
| Wood | 561 | 437 | 78% |

## Buildings (session)

- **Total placed:** 15

### By type

- **Living Hut:** 7
- **Farm:** 4
- **Dairy Farm:** 2
- **Oven:** 2

### By source

- **milestone:** 8
- **herder_hut:** 7

### Chronological

- t=35.9s **RI CUIL** — Living Hut (herder_hut) builder=REEL @ (-2073,-910)
- t=35.9s **MO NIYU** — Living Hut (herder_hut) builder=LAIL @ (-55,-2259)
- t=41.9s **WA PAIT** — Living Hut (herder_hut) builder=VAIH @ (-531,1967)
- t=50.8s **KI ZAOW** — Living Hut (herder_hut) builder=BOFE @ (1912,967)
- t=98.0s **MO NIYU** — Living Hut (herder_hut) builder=LAIL @ (-2,-2341)
- t=113.4s **KI ZAOW** — Living Hut (herder_hut) builder=BOFE @ (1874,1048)
- t=198.0s **MO NIYU** — Oven (milestone) @ (141,-2148)
- t=283.5s **WA PAIT** — Farm (milestone) @ (-475,1921)
- t=333.9s **RI CUIL** — Living Hut (herder_hut) builder=YAAP @ (-2220,-1075)
- t=357.1s **KI ZAOW** — Farm (milestone) @ (1701,882)
- t=375.6s **WA PAIT** — Oven (milestone) @ (-616,1743)
- t=382.0s **RI CUIL** — Farm (milestone) @ (-2016,-952)
- t=428.6s **MO NIYU** — Dairy Farm (milestone) @ (179,-2204)
- t=440.4s **MO NIYU** — Farm (milestone) @ (184,-2236)
- t=472.9s **KI ZAOW** — Dairy Farm (milestone) @ (1743,850)

## Per-clan detail

### KI ZAOW

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/5 (82% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.9k → 0
- **Daily calorie need (end):** 57.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 12 | 12 |
| Bone | 0 | 8 |
| Fiber | 9 | 6 |
| Hide | 0 | 8 |
| Meat | 0 | 15 |
| Mushroom | 4 | 1 |
| Nuts | 49 | 32 |
| Spear | 0 | 17 |
| Stone | 23 | 22 |
| Wood | 179 | 136 |

#### Failures

- **Gather:** empty_switch:not_harvestable=53, not_harvestable=6, resource_invalid=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIIX | 10 | 0 | 1 | 8 | gather 77%, combat 12%, wander 10% |
| BOFE | 23 | 0 | 8 | 29 | gather 37%, combat 16%, wander 15% |
| DICI | 7 | 0 | 2 | 12 | gather 47%, herd_wildnpc 19%, wander 14% |
| GOYI | 3 | 1 | 0 | 2 | gather 100% |
| GUIT | 17 | 2 | 4 | 9 | gather 47%, combat 35%, craft 6% |
| HAIR | 1 | 0 | 0 | 0 | combat 72%, gather 28% |
| JUPI | 4 | 0 | 1 | 4 | idle 58%, gather 24%, eat 9% |
| KUGE | 25 | 0 | 7 | 36 | gather 47%, hunt 23%, wander 16% |
| LAGU | 36 | 0 | 5 | 38 | gather 63%, craft 15%, wander 13% |
| LEWI | 11 | 1 | 2 | 15 | gather 78%, wander 20%, eat 2% |
| MECU | 11 | 0 | 1 | 12 | gather 53%, idle 16%, combat 16% |
| MEOM | 6 | 0 | 1 | 16 | gather 54%, idle 30%, wander 10% |
| NEET | 2 | 0 | 0 | 5 | gather 70%, idle 29%, wander 1% |
| PAHU | 15 | 0 | 4 | 14 | gather 60%, wander 12%, idle 12% |
| RAPU | 20 | 2 | 2 | 0 | gather 40%, combat 36%, craft 15% |
| VOWA | 14 | 1 | 2 | 12 | gather 64%, idle 16%, wander 15% |
| WOOZ | 9 | 1 | 1 | 14 | idle 49%, gather 34%, eat 13% |
| WURO | 16 | 2 | 3 | 17 | gather 57%, build_milestone 12%, idle 11% |
| XUOW | 12 | 3 | 1 | 13 | gather 57%, craft 33%, wander 8% |
| ZAXE | 18 | 1 | 5 | 16 | gather 60%, build_milestone 13%, wander 10% |
| ZOEZ | 2 | 1 | 0 | 4 | gather 93%, eat 4%, herd_wildnpc 3% |

#### Hunts

- start t=86.8s prey=deer quota=2
- start t=126.8s prey=deer quota=3
- start t=257.0s prey=deer quota=4
- start t=362.0s prey=deer quota=4
- hunt_completed t=126.7s reason=loot_complete
- hunt_aborted t=246.8s reason=active_timeout
- hunt_completed t=286.6s reason=loot_complete
- hunt_completed t=404.6s reason=loot_complete

#### Buildings

- t=50.8s **Living Hut** — herder_hut (builder: BOFE)
- t=113.4s **Living Hut** — herder_hut (builder: BOFE)
- t=357.1s **Farm** — milestone
- t=472.9s **Dairy Farm** — milestone

### MO NIYU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (87% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 3.2k → 0
- **Daily calorie need (end):** 48.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 21 | 10 |
| Bone | 0 | 6 |
| Fiber | 27 | 21 |
| Grain | 30 | 19 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 3 | 2 |
| Nuts | 61 | 41 |
| Spear | 0 | 16 |
| Stone | 14 | 14 |
| Wood | 190 | 147 |

#### Failures

- **Gather:** empty_switch:not_harvestable=29, not_harvestable=9, resource_invalid=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIHA | 17 | 0 | 5 | 28 | gather 74%, wander 21%, idle 4% |
| DAAG | 9 | 1 | 2 | 18 | idle 66%, gather 17%, eat 14% |
| DERE | 17 | 1 | 4 | 13 | gather 38%, idle 37%, eat 10% |
| DUAL | 19 | 1 | 4 | 30 | gather 51%, idle 31%, wander 12% |
| GEQU | 6 | 0 | 1 | 13 | idle 67%, eat 14%, gather 10% |
| GOIL | 11 | 0 | 5 | 16 | gather 52%, combat 37%, wander 6% |
| HEOZ | 15 | 0 | 5 | 20 | gather 73%, wander 15%, herd_wildnpc 10% |
| JAPE | 20 | 0 | 4 | 36 | gather 73%, wander 18%, build_hut_for_woman 5% |
| KEAZ | 13 | 1 | 2 | 10 | idle 47%, gather 37%, eat 12% |
| LAIL | 36 | 1 | 15 | 45 | gather 54%, wander 26%, build_hut_for_woman 7% |
| MAIY | 16 | 0 | 6 | 33 | gather 70%, wander 27%, eat 4% |
| ROET | 11 | 3 | 2 | 17 | gather 58%, combat 28%, wander 10% |
| TEYO | 11 | 1 | 3 | 16 | gather 86%, wander 12%, eat 2% |
| TOXE | 4 | 0 | 0 | 7 | idle 65%, build_milestone 13%, eat 13% |
| WAEX | 8 | 2 | 4 | 16 | gather 51%, combat 30%, wander 17% |
| WORO | 6 | 1 | 1 | 7 | gather 54%, combat 42%, wander 3% |
| YUOJ | 32 | 2 | 6 | 21 | gather 57%, craft 21%, herd_wildnpc 12% |

#### Hunts

- start t=72.1s prey=deer quota=2
- start t=122.1s prey=deer quota=3
- hunt_completed t=117.7s reason=loot_complete
- hunt_completed t=146.9s reason=loot_complete

#### Buildings

- t=35.9s **Living Hut** — herder_hut (builder: LAIL)
- t=98.0s **Living Hut** — herder_hut (builder: LAIL)
- t=198.0s **Oven** — milestone
- t=428.6s **Dairy Farm** — milestone
- t=440.4s **Farm** — milestone

### RI CUIL

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (80% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.4k → 750
- **Daily calorie need (end):** 46.8k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 18 | 6 |
| Bone | 0 | 7 |
| Fiber | 6 | 3 |
| Hide | 0 | 12 |
| Meat | 0 | 13 |
| Mushroom | 1 | 0 |
| Nuts | 16 | 6 |
| Spear | 0 | 9 |
| Stone | 9 | 9 |
| Wood | 75 | 66 |

#### Failures

- **Gather:** empty_switch:not_harvestable=5, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BOOV | 10 | 0 | 2 | 16 | gather 47%, herd_wildnpc 30%, build_milestone 13% |
| DEUJ | 13 | 0 | 4 | 7 | idle 37%, gather 26%, combat 18% |
| JEXA | 7 | 0 | 3 | 0 | idle 46%, combat 19%, gather 18% |
| MACE | 10 | 0 | 1 | 11 | gather 85%, eat 8%, wander 7% |
| REEL | 38 | 0 | 14 | 33 | gather 42%, combat 17%, wander 16% |
| VILI | 14 | 1 | 1 | 13 | gather 38%, herd_wildnpc 30%, flee_combat 15% |
| WIEZ | 7 | 0 | 1 | 12 | gather 86%, eat 9%, wander 5% |
| XEAL | 10 | 0 | 3 | 13 | gather 49%, herd_wildnpc 18%, idle 17% |
| YAAP | 17 | 0 | 4 | 20 | gather 33%, hunt 24%, herd_wildnpc 23% |

#### Hunts

- start t=68.6s prey=deer quota=2
- start t=113.6s prey=deer quota=3
- start t=243.7s prey=deer quota=4
- start t=544.0s prey=deer quota=4
- hunt_completed t=113.1s reason=loot_complete
- hunt_aborted t=233.6s reason=active_timeout
- hunt_completed t=280.1s reason=loot_complete
- hunt_completed t=588.3s reason=loot_complete

#### Buildings

- t=35.9s **Living Hut** — herder_hut (builder: REEL)
- t=333.9s **Living Hut** — herder_hut (builder: YAAP)
- t=382.0s **Farm** — milestone

### WA PAIT

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (83% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.5k → 0
- **Daily calorie need (end):** 32.7k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 12 | 7 |
| Bone | 0 | 6 |
| Grain | 33 | 21 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 3 | 1 |
| Nuts | 31 | 19 |
| Spear | 0 | 10 |
| Stone | 22 | 13 |
| Wood | 117 | 88 |

#### Failures

- **Gather:** not_harvestable=15, empty_switch:not_harvestable=10, resource_invalid=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEXO | 11 | 3 | 2 | 9 | gather 58%, idle 13%, eat 8% |
| DURI | 11 | 1 | 3 | 9 | gather 49%, hunt 22%, combat 18% |
| JUIT | 2 | 0 | 0 | 5 | flee_combat 40%, idle 38%, gather 17% |
| KEIK | 6 | 2 | 0 | 8 | gather 77%, flee_combat 20%, idle 2% |
| LIEF | 12 | 1 | 2 | 14 | gather 41%, idle 26%, combat 19% |
| RAIC | 14 | 2 | 4 | 18 | gather 58%, combat 20%, craft 6% |
| REBE | 22 | 3 | 5 | 16 | gather 49%, combat 19%, build_milestone 12% |
| SIQU | 22 | 2 | 3 | 28 | gather 74%, wander 10%, eat 8% |
| VAIH | 21 | 2 | 11 | 27 | gather 31%, combat 17%, wander 16% |
| WAIQ | 14 | 0 | 3 | 25 | gather 47%, combat 30%, wander 13% |
| XONO | 21 | 2 | 4 | 30 | gather 53%, combat 19%, idle 13% |
| ZIIL | 17 | 1 | 6 | 29 | gather 58%, wander 22%, herd_wildnpc 15% |

#### Hunts

- start t=75.8s prey=deer quota=2
- start t=125.9s prey=deer quota=3
- start t=246.0s prey=deer quota=4
- hunt_completed t=123.8s reason=loot_complete
- hunt_aborted t=245.9s reason=active_timeout
- hunt_completed t=354.9s reason=loot_complete

#### Buildings

- t=41.9s **Living Hut** — herder_hut (builder: VAIH)
- t=283.5s **Farm** — milestone
- t=375.6s **Oven** — milestone

