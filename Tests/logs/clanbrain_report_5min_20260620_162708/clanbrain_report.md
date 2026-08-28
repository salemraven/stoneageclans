# ClanBrain Report (standard)

## Session

- **Duration:** 300.6s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_5min_20260620_162708/playtest_session.jsonl`
- **World seed:** 0
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4
- **Simulation ticks:** 2
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| CU FAWE | 0→11 | 9 | 0 | 23.6k | 0.0 | 2 | 2 | 107 | 91 | 0 | 66% | 90.1s | 8 | 1 | 91.4s |
| JU DEOS | 0→10 | 8 | 80 | 21.4k | 0.0 | 2 | 2 | 55 | 54 | 0 | 84% | 125.1s | 7 | 2 | 127.5s |
| LO NUOD | 0→10 | 7 | 80 | 21.2k | 0.0 | 3 | 3 | 47 | 82 | 1 | 76% | 80.1s | 6 | 2 | 83.4s |
| TI TAUG | 0→10 | 8 | 0 | 21.4k | 0.0 | 2 | 2 | 67 | 55 | 2 | 83% | 80.1s | 7 | 1 | 84.7s |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 9 / 9
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| CU FAWE | — | — | 66% | 14% | 0→2.5k→0 | 0.0→1.0→0.0 | 90.1s |
| JU DEOS | — | — | 84% | 13% | 0→3.0k→80 | 0.0→1.0→0.0 | 125.1s |
| LO NUOD | — | — | 76% | 20% | 0→2.2k→80 | 0.0→1.0→0.0 | 80.1s |
| TI TAUG | — | — | 83% | 17% | 0→2.2k→0 | 0.0→1.0→0.0 | 80.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| CU FAWE | 2 | 2 | 0 | 2 | 0 | 8 | 9 |
| JU DEOS | 2 | 2 | 0 | 2 | 0 | 7 | 7 |
| LO NUOD | 3 | 3 | 0 | 3 | 0 | 12 | 13 |
| TI TAUG | 2 | 2 | 0 | 2 | 0 | 7 | 7 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| CU FAWE | 1 | 8 | 8 | 87.2s |
| JU DEOS | 1 | 7 | 7 | 126.7s |
| LO NUOD | 1 | 6 | 6 | 79.5s |
| TI TAUG | 1 | 7 | 7 | 83.1s |

## Clansmen workforce

- **Unique clansmen seen:** 28 (gather FSM transitions: 185, productivity snapshots: 10)
- **Last snapshot:** clansmen=28 with_job=14 (all workers job %=56.25)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| CU FAWE | 8 | 8 | 73 | 49 | 17 | 11 | state_exit_clear_tasks=8, exited_tree=2, resource_freed=1 |
| JU DEOS | 7 | 7 | 36 | 30 | 8 | 17 | state_exit_clear_tasks=7, exited_tree=6, resource_node_invalid=3 |
| LO NUOD | 6 | 6 | 38 | 64 | 13 | 22 | state_exit_clear_tasks=11, exited_tree=5, resource_node_invalid=3 |
| TI TAUG | 7 | 7 | 55 | 41 | 10 | 27 | resource_node_invalid=13, state_exit_clear_tasks=10, exited_tree=2 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| CIDO | JU DEOS | 13 | 4 | 16 | 0 | 2 | gather 56%, party 21%, eat 10% |
| COIS | CU FAWE | 13 | 3 | 11 | 0 | 0 | gather 38%, idle 36%, wander 13% |
| CUHE | CU FAWE | 6 | 1 | 7 | 0 | 1 | gather 66%, idle 27%, eat 6% |
| GEBA | CU FAWE | 7 | 2 | 12 | 0 | 1 | gather 49%, idle 23%, eat 10% |
| GEBE | CU FAWE | 15 | 6 | 23 | 0 | 2 | gather 65%, craft 15%, idle 11% |
| JEZE | TI TAUG | 6 | 3 | 15 | 0 | 3 | gather 53%, idle 25%, eat 12% |
| JOUM | JU DEOS | 3 | 0 | 2 | 0 | 1 | gather 100% |
| MUHE | LO NUOD | 6 | 3 | 11 | 0 | 4 | gather 65%, wander 16%, hunt 7% |
| PAAG | JU DEOS | 5 | 0 | 1 | 0 | 2 | gather 74%, eat 18%, wander 7% |
| PEJI | CU FAWE | 0 | 1 | 10 | 0 | 1 | craft 85%, gather 15% |
| PIUL | LO NUOD | 7 | 1 | 6 | 0 | 2 | gather 78%, wander 22%, idle 0% |
| PUER | JU DEOS | 3 | 1 | 11 | 0 | 1 | craft 60%, gather 24%, eat 16% |
| QEAD | CU FAWE | 4 | 0 | 1 | 0 | 1 | gather 100% |
| QUGO | TI TAUG | 9 | 3 | 11 | 0 | 3 | gather 86%, wander 8%, eat 6% |
| SIWO | LO NUOD | 13 | 2 | 14 | 0 | 3 | gather 76%, eat 11%, party 10% |
| SOAG | TI TAUG | 5 | 1 | 7 | 0 | 5 | gather 91%, eat 7%, wander 2% |
| SOOH | JU DEOS | 5 | 0 | 4 | 0 | 2 | gather 75%, wander 23%, idle 2% |
| TOQA | JU DEOS | 3 | 2 | 12 | 0 | 4 | gather 71%, build_milestone 13%, hunt 11% |
| VAUZ | TI TAUG | 9 | 1 | 15 | 0 | 10 | gather 92%, wander 5%, eat 1% |
| WOAL | TI TAUG | 8 | 0 | 4 | 0 | 0 | idle 70%, gather 23%, eat 7% |
| WUAZ | TI TAUG | 10 | 1 | 4 | 0 | 0 | gather 44%, wander 39%, idle 17% |
| XAOS | LO NUOD | 2 | 1 | 5 | 1 | 3 | gather 71%, party 14%, eat 13% |
| YOCI | LO NUOD | 10 | 3 | 9 | 0 | 2 | gather 87%, wander 11%, eat 2% |
| YOLA | JU DEOS | 4 | 1 | 6 | 0 | 1 | gather 72%, eat 16%, wander 11% |
| YOOK | CU FAWE | 17 | 3 | 16 | 0 | 0 | gather 52%, hunt 19%, idle 14% |
| ZUPA | TI TAUG | 8 | 1 | 5 | 1 | 3 | gather 92%, idle 6%, eat 2% |
| ZUTI | LO NUOD | 0 | 3 | 9 | 0 | 3 | gather 61%, eat 16%, party 11% |
| ZUVI | CU FAWE | 11 | 1 | 6 | 0 | 0 | gather 77%, wander 11%, eat 10% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| CU FAWE | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| JU DEOS | 11 | 2 | 2 | 2 | 0 | 0 | 0 | 0 |
| LO NUOD | 14 | 1 | 1 | 1 | 0 | 0 | 0 | 0 |
| TI TAUG | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| CU FAWE | 2 | 2 | 0 | 0 |
| JU DEOS | 3 | 5 | 1 | 2 |
| LO NUOD | 3 | 4 | 1 | 1 |
| TI TAUG | 2 | 2 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| CU FAWE | 116 | 0 | 100% | 0 | 3 | gather 55%, idle 13%, craft 8% |
| JU DEOS | 80 | 0 | 100% | 0 | 3 | gather 58%, eat 8%, craft 8% |
| LO NUOD | 77 | 2 | 97% | 0 | 4 | gather 69%, wander 8%, party 7% |
| TI TAUG | 82 | 2 | 98% | 0 | 7 | gather 66%, idle 11%, wander 7% |

## Economy (session)

- **Items gathered:** 276
- **Items deposited:** 282
- **Deposit yield:** 102%
- **Gather failures (all):** 14
- **Gather failures (actionable):** 3
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 11
- **resource_invalid:** 3

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 12 | 12 | 100% |
| Bone | 0 | 27 | — |
| Grain | 15 | 9 | 60% |
| Hide | 0 | 36 | — |
| Meat | 0 | 45 | — |
| Mushroom | 26 | 4 | 15% |
| Nuts | 38 | 21 | 55% |
| Spear | 0 | 27 | — |
| Stone | 28 | 14 | 50% |
| Wood | 157 | 87 | 55% |

## Buildings (session)

- **Total placed:** 6

### By type

- **Living Hut:** 4
- **Drying Rack:** 1
- **Oven:** 1

### By source

- **herder_hut:** 4
- **milestone:** 2

### Chronological

- t=47.0s **LO NUOD** — Living Hut (herder_hut) builder=CEUC @ (-1995,-807)
- t=50.6s **TI TAUG** — Living Hut (herder_hut) builder=VEEB @ (3048,-133)
- t=54.7s **CU FAWE** — Living Hut (herder_hut) builder=LEZU @ (-1016,-2629)
- t=94.2s **JU DEOS** — Living Hut (herder_hut) builder=LOEL @ (-137,3474)
- t=193.8s **LO NUOD** — Oven (milestone) @ (-2154,-944)
- t=197.6s **JU DEOS** — Drying Rack (milestone) @ (-309,3348)

## Per-clan detail

### CU FAWE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (66% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.5k → 0
- **Daily calorie need (end):** 23.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 0 | 3 |
| Bone | 0 | 6 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 4 | 0 |
| Nuts | 19 | 10 |
| Spear | 0 | 8 |
| Stone | 3 | 3 |
| Wood | 81 | 43 |

#### Failures

- **Gather:** empty_switch:not_harvestable=11

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| COIS | 11 | 0 | 3 | 13 | gather 38%, idle 36%, wander 13% |
| CUHE | 7 | 0 | 1 | 6 | gather 66%, idle 27%, eat 6% |
| GEBA | 12 | 0 | 2 | 7 | gather 49%, idle 23%, eat 10% |
| GEBE | 23 | 0 | 6 | 15 | gather 65%, craft 15%, idle 11% |
| LEZU | 30 | 0 | 20 | 34 | gather 56%, wander 13%, herd_wildnpc 12% |
| PEJI | 10 | 0 | 1 | 0 | craft 85%, gather 15% |
| QEAD | 1 | 0 | 0 | 4 | gather 100% |
| YOOK | 16 | 0 | 3 | 17 | gather 52%, hunt 19%, idle 14% |
| ZUVI | 6 | 0 | 1 | 11 | gather 77%, wander 11%, eat 10% |

#### Hunts

- start t=91.4s prey=deer quota=2
- start t=136.5s prey=deer quota=2
- hunt_completed t=132.1s reason=loot_complete
- hunt_completed t=197.6s reason=loot_complete

#### Buildings

- t=54.7s **Living Hut** — herder_hut (builder: LEZU)

### JU DEOS

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (84% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 3.0k → 80
- **Daily calorie need (end):** 21.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 6 |
| Bone | 0 | 6 |
| Grain | 12 | 6 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 7 | 0 |
| Nuts | 4 | 3 |
| Spear | 0 | 5 |
| Stone | 10 | 3 |
| Wood | 13 | 7 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CIDO | 16 | 0 | 4 | 13 | gather 56%, party 21%, eat 10% |
| JOUM | 2 | 0 | 0 | 3 | gather 100% |
| LOEL | 20 | 0 | 10 | 19 | gather 55%, herd_wildnpc 22%, wander 12% |
| PAAG | 1 | 0 | 0 | 5 | gather 74%, eat 18%, wander 7% |
| PUER | 11 | 0 | 1 | 3 | craft 60%, gather 24%, eat 16% |
| SOOH | 4 | 0 | 0 | 5 | gather 75%, wander 23%, idle 2% |
| TOQA | 12 | 0 | 2 | 3 | gather 71%, build_milestone 13%, hunt 11% |
| YOLA | 6 | 0 | 1 | 4 | gather 72%, eat 16%, wander 11% |

#### Hunts

- start t=127.5s prey=deer quota=2
- start t=172.6s prey=deer quota=2
- hunt_completed t=168.0s reason=loot_complete
- hunt_completed t=228.6s reason=loot_complete

#### Buildings

- t=94.2s **Living Hut** — herder_hut (builder: LOEL)
- t=197.6s **Drying Rack** — milestone

### LO NUOD

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (76% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.2k → 80
- **Daily calorie need (end):** 21.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.2/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 3 |
| Bone | 0 | 9 |
| Grain | 3 | 3 |
| Hide | 0 | 12 |
| Meat | 0 | 15 |
| Mushroom | 4 | 4 |
| Nuts | 8 | 6 |
| Spear | 0 | 7 |
| Stone | 6 | 6 |
| Wood | 23 | 17 |

#### Failures

- **Gather:** resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CEUC | 20 | 0 | 8 | 9 | gather 61%, hunt 10%, herd_wildnpc 9% |
| MUHE | 11 | 0 | 3 | 6 | gather 65%, wander 16%, hunt 7% |
| PIUL | 6 | 0 | 1 | 7 | gather 78%, wander 22%, idle 0% |
| SIWO | 14 | 0 | 2 | 13 | gather 76%, eat 11%, party 10% |
| XAOS | 5 | 1 | 1 | 2 | gather 71%, party 14%, eat 13% |
| YOCI | 9 | 0 | 3 | 10 | gather 87%, wander 11%, eat 2% |
| ZUTI | 9 | 0 | 3 | 0 | gather 61%, eat 16%, party 11% |

#### Hunts

- start t=83.4s prey=deer quota=2
- start t=123.4s prey=deer quota=2
- start t=208.5s prey=deer quota=4
- hunt_completed t=120.0s reason=loot_complete
- hunt_completed t=176.3s reason=loot_complete
- hunt_completed t=260.3s reason=loot_complete

#### Buildings

- t=47.0s **Living Hut** — herder_hut (builder: CEUC)
- t=193.8s **Oven** — milestone

### TI TAUG

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (83% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.2k → 0
- **Daily calorie need (end):** 21.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 11 | 0 |
| Nuts | 7 | 2 |
| Spear | 0 | 7 |
| Stone | 9 | 2 |
| Wood | 40 | 20 |

#### Failures

- **Gather:** resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| JEZE | 15 | 0 | 3 | 6 | gather 53%, idle 25%, eat 12% |
| QUGO | 11 | 0 | 3 | 9 | gather 86%, wander 8%, eat 6% |
| SOAG | 7 | 0 | 1 | 5 | gather 91%, eat 7%, wander 2% |
| VAUZ | 15 | 0 | 1 | 9 | gather 92%, wander 5%, eat 1% |
| VEEB | 21 | 1 | 6 | 12 | gather 47%, herd_wildnpc 17%, craft 12% |
| WOAL | 4 | 0 | 0 | 8 | idle 70%, gather 23%, eat 7% |
| WUAZ | 4 | 0 | 1 | 10 | gather 44%, wander 39%, idle 17% |
| ZUPA | 5 | 1 | 1 | 8 | gather 92%, idle 6%, eat 2% |

#### Hunts

- start t=84.7s prey=deer quota=2
- start t=124.7s prey=deer quota=2
- hunt_completed t=123.9s reason=loot_complete
- hunt_completed t=165.3s reason=loot_complete

#### Buildings

- t=50.6s **Living Hut** — herder_hut (builder: VEEB)

