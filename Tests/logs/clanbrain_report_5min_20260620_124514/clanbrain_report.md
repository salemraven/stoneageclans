# ClanBrain Report (standard)

## Session

- **Duration:** 300.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_5min_20260620_124514/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4
- **Simulation ticks:** 2
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| JI DAUL | 0→8 | 7 | 1.4k | 17.8k | 0.1 | 3 | 2 | 20 | 42 | 2 | 49% | 80.1s | 6 | 3 | 80.7s |
| MA REOW | 0→5 | 4 | 1.9k | 11.2k | 0.2 | 3 | 2 | 11 | 32 | 0 | 63% | 85.1s | 3 | 3 | 87.4s |
| NI WASE | 0→8 | 6 | 0 | 17.0k | 0.0 | 3 | 1 | 31 | 40 | 1 | 59% | 80.1s | 5 | 2 | 83.7s |
| RE MEEG | 0→10 | 9 | 0 | 21.6k | 0.0 | 2 | 2 | 108 | 97 | 1 | 85% | 70.1s | 8 | 2 | 73.4s |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 11 / 10
- **⚠ Possible stuck parties (formed − disbanded):** 1

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| JI DAUL | — | — | 49% | 20% | 0→1.4k→1.4k | 0.0→1.0→0.1 | 80.1s |
| MA REOW | — | — | 63% | 17% | 40→1.9k→1.9k | 0.0→1.0→0.2 | 85.1s |
| NI WASE | — | — | 59% | 20% | 0→1.6k→0 | 0.0→1.0→0.0 | 80.1s |
| RE MEEG | — | — | 85% | 33% | 0→2.5k→0 | 0.0→1.0→0.0 | 70.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| JI DAUL | 3 | 2 | 1 | 2 | 0 | 6 | 7 |
| MA REOW | 3 | 2 | 1 | 2 | 0 | 4 | 6 |
| NI WASE | 3 | 1 | 1 | 1 | 0 | 3 | 3 |
| RE MEEG | 2 | 2 | 0 | 2 | 0 | 7 | 7 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| JI DAUL | 1 | 6 | 6 | 78.6s |
| MA REOW | 1 | 3 | 3 | 83.8s |
| NI WASE | 1 | 5 | 5 | 79.3s |
| RE MEEG | 1 | 8 | 8 | 68.7s |

## Clansmen workforce

- **Unique clansmen seen:** 22 (gather FSM transitions: 116, productivity snapshots: 10)
- **Last snapshot:** clansmen=22 with_job=7 (all workers job %=34.6153846153846)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| JI DAUL | 6 | 6 | 16 | 35 | 11 | 12 | state_exit_clear_tasks=5, exited_tree=4, task_failed=2 |
| MA REOW | 3 | 3 | 8 | 26 | 7 | 6 | state_exit_clear_tasks=4, exited_tree=2 |
| NI WASE | 5 | 5 | 22 | 28 | 7 | 7 | state_exit_clear_tasks=5, task_failed=2 |
| RE MEEG | 8 | 8 | 80 | 63 | 13 | 14 | state_exit_clear_tasks=5, assign_job_supersede=4, exited_tree=2 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BEFE | NI WASE | 7 | 1 | 14 | 0 | 0 | craft 46%, hunt 25%, gather 15% |
| FAUN | MA REOW | 8 | 2 | 6 | 0 | 2 | gather 29%, party 27%, idle 27% |
| JIIV | NI WASE | 0 | 1 | 0 | 0 | 0 | hunt 62%, party 26%, herd_wildnpc 6% |
| JOCA | JI DAUL | 0 | 3 | 6 | 0 | 2 | combat 39%, gather 21%, party 13% |
| JUUY | RE MEEG | 7 | 0 | 4 | 0 | 1 | idle 55%, build_milestone 21%, gather 14% |
| KETO | RE MEEG | 18 | 5 | 13 | 0 | 2 | gather 70%, eat 13%, wander 9% |
| KOFA | RE MEEG | 6 | 4 | 14 | 0 | 3 | gather 41%, idle 35%, eat 12% |
| LOBE | RE MEEG | 7 | 0 | 3 | 0 | 2 | gather 100% |
| MUOD | NI WASE | 0 | 1 | 3 | 0 | 1 | combat 55%, build_milestone 18%, gather 14% |
| NUFA | RE MEEG | 11 | 1 | 6 | 0 | 0 | idle 50%, gather 36%, wander 9% |
| PULO | RE MEEG | 6 | 0 | 4 | 0 | 0 | gather 90%, wander 10% |
| ROXE | JI DAUL | 2 | 2 | 9 | 1 | 1 | combat 44%, gather 28%, build_milestone 13% |
| SAPA | JI DAUL | 0 | 1 | 3 | 0 | 1 | hunt 65%, gather 15%, eat 10% |
| SUOC | JI DAUL | 0 | 0 | 2 | 0 | 1 | gather 99%, hunt 1% |
| TAON | MA REOW | 0 | 2 | 4 | 0 | 3 | combat 33%, party 22%, gather 22% |
| VOSU | JI DAUL | 9 | 2 | 4 | 0 | 1 | wander 42%, gather 33%, idle 20% |
| VUIR | RE MEEG | 15 | 2 | 11 | 0 | 3 | gather 67%, wander 19%, herd_wildnpc 13% |
| XADU | RE MEEG | 10 | 1 | 4 | 0 | 0 | gather 66%, wander 32%, eat 2% |
| XUCE | NI WASE | 0 | 3 | 6 | 0 | 2 | combat 49%, party 25%, gather 21% |
| YAIH | JI DAUL | 5 | 3 | 4 | 0 | 2 | combat 51%, gather 25%, party 18% |
| ZAAZ | NI WASE | 15 | 1 | 10 | 2 | 2 | gather 48%, idle 24%, eat 12% |
| ZUUX | MA REOW | 0 | 3 | 6 | 0 | 0 | hunt 56%, gather 21%, build_milestone 12% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| JI DAUL | 14 | 2 | 0 | 0 | 1 | 0 | 0 | 0 |
| MA REOW | 14 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| NI WASE | 14 | 2 | 0 | 0 | 1 | 0 | 0 | 0 |
| RE MEEG | 15 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| JI DAUL | 2 | 4 | 2 | 2 |
| MA REOW | 2 | 2 | 2 | 0 |
| NI WASE | 2 | 4 | 1 | 2 |
| RE MEEG | 2 | 2 | 1 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| JI DAUL | 36 | 2 | 95% | 0 | 0 | combat 32%, gather 24%, party 12% |
| MA REOW | 20 | 0 | 100% | 0 | 0 | party 23%, gather 20%, combat 17% |
| NI WASE | 42 | 2 | 95% | 0 | 0 | combat 30%, gather 19%, party 13% |
| RE MEEG | 82 | 1 | 99% | 0 | 1 | gather 53%, idle 18%, wander 13% |

## Economy (session)

- **Items gathered:** 170
- **Items deposited:** 211
- **Deposit yield:** 124%
- **Gather failures (all):** 9
- **Gather failures (actionable):** 4
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 5
- **resource_invalid:** 4

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Bone | 0 | 17 | — |
| Fiber | 12 | 12 | 100% |
| Grain | 12 | 6 | 50% |
| Hide | 0 | 21 | — |
| Meat | 0 | 35 | — |
| Mushroom | 7 | 4 | 57% |
| Nuts | 29 | 20 | 69% |
| Spear | 0 | 22 | — |
| Stone | 12 | 11 | 92% |
| Wood | 98 | 63 | 64% |

## Buildings (session)

- **Total placed:** 10

### By type

- **Living Hut:** 4
- **Drying Rack:** 3
- **Oven:** 2
- **Farm:** 1

### By source

- **milestone:** 6
- **herder_hut:** 4

### Chronological

- t=36.2s **RE MEEG** — Living Hut (herder_hut) builder=WEIF @ (184,1927)
- t=46.1s **JI DAUL** — Living Hut (herder_hut) builder=NELU @ (-1714,475)
- t=46.8s **NI WASE** — Living Hut (herder_hut) builder=NOEM @ (720,-1958)
- t=51.3s **MA REOW** — Living Hut (herder_hut) builder=LIAT @ (3382,-1451)
- t=102.5s **JI DAUL** — Farm (milestone) @ (-1889,314)
- t=116.3s **MA REOW** — Oven (milestone) @ (3184,-1561)
- t=147.9s **NI WASE** — Drying Rack (milestone) @ (520,-2049)
- t=177.2s **JI DAUL** — Drying Rack (milestone) @ (-1675,412)
- t=229.8s **RE MEEG** — Oven (milestone) @ (-31,1847)
- t=269.1s **MA REOW** — Drying Rack (milestone) @ (3363,-1405)

## Per-clan detail

### JI DAUL

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/4 (49% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.1
- **Calories in storage:** 0 → 1.4k → 1.4k
- **Daily calorie need (end):** 17.8k
- **Calorie days buffer:** 0.0 → 1.0 → 0.1
- **Productivity (end):** food_rate=1.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 5 |
| Hide | 0 | 5 |
| Meat | 0 | 10 |
| Mushroom | 1 | 1 |
| Nuts | 6 | 5 |
| Spear | 0 | 6 |
| Stone | 1 | 1 |
| Wood | 12 | 9 |

#### Failures

- **Gather:** resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| JOCA | 6 | 0 | 3 | 0 | combat 39%, gather 21%, party 13% |
| NELU | 8 | 1 | 3 | 4 | combat 30%, party 22%, gather 22% |
| ROXE | 9 | 1 | 2 | 2 | combat 44%, gather 28%, build_milestone 13% |
| SAPA | 3 | 0 | 1 | 0 | hunt 65%, gather 15%, eat 10% |
| SUOC | 2 | 0 | 0 | 0 | gather 99%, hunt 1% |
| VOSU | 4 | 0 | 2 | 9 | wander 42%, gather 33%, idle 20% |
| YAIH | 4 | 0 | 3 | 5 | combat 51%, gather 25%, party 18% |

#### Hunts

- start t=80.7s prey=deer quota=2
- start t=145.8s prey=deer quota=4
- start t=275.9s prey=deer quota=4
- hunt_completed t=143.3s reason=loot_complete
- hunt_aborted t=265.8s reason=active_timeout
- hunt_completed t=287.6s reason=loot_complete

#### Buildings

- t=46.1s **Living Hut** — herder_hut (builder: NELU)
- t=102.5s **Farm** — milestone
- t=177.2s **Drying Rack** — milestone

### MA REOW

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/3 (63% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.2
- **Calories in storage:** 40 → 1.9k → 1.9k
- **Daily calorie need (end):** 11.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.2
- **Productivity (end):** food_rate=1.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 3 |
| Grain | 3 | 3 |
| Hide | 0 | 4 |
| Meat | 0 | 10 |
| Nuts | 2 | 2 |
| Spear | 0 | 4 |
| Wood | 6 | 6 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FAUN | 6 | 0 | 2 | 8 | gather 29%, party 27%, idle 27% |
| LIAT | 4 | 0 | 3 | 3 | party 32%, combat 24%, herd_wildnpc 15% |
| TAON | 4 | 0 | 2 | 0 | combat 33%, party 22%, gather 22% |
| ZUUX | 6 | 0 | 3 | 0 | hunt 56%, gather 21%, build_milestone 12% |

#### Hunts

- start t=87.4s prey=deer quota=2
- start t=207.5s prey=deer quota=4
- start t=242.5s prey=deer quota=4
- hunt_aborted t=207.4s reason=active_timeout
- hunt_completed t=240.9s reason=loot_complete
- hunt_completed t=292.4s reason=loot_complete

#### Buildings

- t=51.3s **Living Hut** — herder_hut (builder: LIAT)
- t=116.3s **Oven** — milestone
- t=269.1s **Drying Rack** — milestone

### NI WASE

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (59% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.6k → 0
- **Daily calorie need (end):** 17.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 3 |
| Hide | 0 | 4 |
| Meat | 0 | 5 |
| Nuts | 5 | 3 |
| Spear | 0 | 6 |
| Stone | 4 | 3 |
| Wood | 22 | 16 |

#### Failures

- **Gather:** resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEFE | 14 | 0 | 1 | 7 | craft 46%, hunt 25%, gather 15% |
| JIIV | 0 | 0 | 1 | 0 | hunt 62%, party 26%, herd_wildnpc 6% |
| MUOD | 3 | 0 | 1 | 0 | combat 55%, build_milestone 18%, gather 14% |
| NOEM | 9 | 0 | 5 | 9 | combat 39%, gather 23%, party 18% |
| XUCE | 6 | 0 | 3 | 0 | combat 49%, party 25%, gather 21% |
| ZAAZ | 10 | 2 | 1 | 15 | gather 48%, idle 24%, eat 12% |

#### Hunts

- start t=83.7s prey=deer quota=2
- start t=128.7s prey=deer quota=3
- start t=258.9s prey=deer quota=4
- hunt_completed t=116.9s reason=loot_complete
- hunt_aborted t=248.7s reason=active_timeout

#### Buildings

- t=46.8s **Living Hut** — herder_hut (builder: NOEM)
- t=147.9s **Drying Rack** — milestone

### RE MEEG

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (85% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.5k → 0
- **Daily calorie need (end):** 21.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Fiber | 12 | 12 |
| Grain | 9 | 3 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 6 | 3 |
| Nuts | 16 | 10 |
| Spear | 0 | 6 |
| Stone | 7 | 7 |
| Wood | 58 | 32 |

#### Failures

- **Gather:** empty_switch:not_harvestable=5, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| JUUY | 4 | 0 | 0 | 7 | idle 55%, build_milestone 21%, gather 14% |
| KETO | 13 | 0 | 5 | 18 | gather 70%, eat 13%, wander 9% |
| KOFA | 14 | 0 | 4 | 6 | gather 41%, idle 35%, eat 12% |
| LOBE | 3 | 0 | 0 | 7 | gather 100% |
| NUFA | 6 | 0 | 1 | 11 | idle 50%, gather 36%, wander 9% |
| PULO | 4 | 0 | 0 | 6 | gather 90%, wander 10% |
| VUIR | 11 | 0 | 2 | 15 | gather 67%, wander 19%, herd_wildnpc 13% |
| WEIF | 23 | 1 | 13 | 28 | gather 53%, wander 26%, hunt 8% |
| XADU | 4 | 0 | 1 | 10 | gather 66%, wander 32%, eat 2% |

#### Hunts

- start t=73.4s prey=deer quota=2
- start t=118.5s prey=deer quota=3
- hunt_completed t=115.1s reason=loot_complete
- hunt_completed t=145.6s reason=loot_complete

#### Buildings

- t=36.2s **Living Hut** — herder_hut (builder: WEIF)
- t=229.8s **Oven** — milestone

