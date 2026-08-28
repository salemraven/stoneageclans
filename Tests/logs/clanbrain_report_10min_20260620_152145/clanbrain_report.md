# ClanBrain Report (standard)

## Session

- **Duration:** 600.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_10min_20260620_152145/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 10 min
- **AI clans with eval:** 4
- **Simulation ticks:** 5
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| GA BIYI | 0→19 | 10 | 0 | 39.2k | 0.0 | 3 | 2 | 164 | 111 | 2 | 93% | 100.1s | 9 | 5 | 102.6s |
| LI GIMU | 0→31 | 22 | 0 | 65.6k | 0.0 | 3 | 2 | 344 | 243 | 7 | 89% | 75.1s | 21 | 4 | 80.1s |
| SO MOED | 0→9 | 7 | 0 | 19.2k | 0.0 | 2 | 2 | 105 | 77 | 6 | 78% | 95.1s | 6 | 2 | 97.9s |
| TI CARI | 0→23 | 11 | 0 | 47.4k | 0.0 | 3 | 3 | 226 | 199 | 10 | 88% | 85.1s | 10 | 4 | 89.6s |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 11 / 11
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| GA BIYI | — | — | 93% | 11% | 0→2.1k→0 | 0.0→1.0→0.0 | 100.1s |
| LI GIMU | — | — | 89% | 25% | 0→1.3k→0 | 0.0→1.0→0.0 | 75.1s |
| SO MOED | — | — | 78% | 12% | 0→2.3k→0 | 0.0→1.0→0.0 | 95.1s |
| TI CARI | — | — | 88% | 17% | 0→2.3k→0 | 0.0→1.0→0.0 | 85.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| GA BIYI | 3 | 2 | 0 | 3 | 0 | 4 | 7 |
| LI GIMU | 3 | 2 | 1 | 2 | 0 | 6 | 7 |
| SO MOED | 2 | 2 | 0 | 2 | 0 | 7 | 8 |
| TI CARI | 3 | 3 | 0 | 3 | 0 | 10 | 10 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| GA BIYI | 4 | 9 | 9 | 100.1s |
| LI GIMU | 4 | 21 | 21 | 76.9s |
| SO MOED | 1 | 6 | 6 | 94.9s |
| TI CARI | 4 | 10 | 10 | 85.8s |

## Clansmen workforce

- **Unique clansmen seen:** 46 (gather FSM transitions: 512, productivity snapshots: 20)
- **Last snapshot:** clansmen=46 with_job=4 (all workers job %=10.0)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| GA BIYI | 9 | 9 | 136 | 82 | 18 | 28 | state_exit_clear_tasks=15, resource_node_invalid=5, task_failed=5 |
| LI GIMU | 21 | 21 | 310 | 208 | 40 | 38 | state_exit_clear_tasks=24, task_failed=10, exited_tree=3 |
| SO MOED | 6 | 6 | 71 | 47 | 10 | 15 | state_exit_clear_tasks=8, task_failed=6, assign_job_supersede=1 |
| TI CARI | 10 | 10 | 183 | 154 | 32 | 54 | task_failed=25, state_exit_clear_tasks=18, assign_job_supersede=6 |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| BAGE | LI GIMU | 28 | 3 | 18 | 0 | 1 | gather 48%, idle 41%, wander 8% |
| BAVU | TI CARI | 13 | 3 | 13 | 2 | 6 | gather 85%, wander 8%, herd_wildnpc 7% |
| CAER | LI GIMU | 12 | 1 | 9 | 0 | 0 | idle 56%, gather 18%, build_milestone 11% |
| DATO | LI GIMU | 13 | 2 | 11 | 1 | 4 | gather 52%, herd_wildnpc 22%, wander 12% |
| DEDO | TI CARI | 5 | 1 | 6 | 0 | 1 | idle 66%, gather 17%, build_milestone 13% |
| DOIN | GA BIYI | 12 | 1 | 8 | 0 | 0 | idle 60%, gather 24%, wander 11% |
| DUUX | LI GIMU | 17 | 2 | 10 | 0 | 0 | idle 55%, gather 35%, eat 7% |
| FANU | TI CARI | 16 | 3 | 19 | 1 | 3 | idle 39%, gather 27%, craft 13% |
| FAOP | LI GIMU | 14 | 1 | 10 | 0 | 1 | idle 32%, gather 26%, hunt 24% |
| FEOY | LI GIMU | 23 | 2 | 15 | 1 | 2 | idle 44%, gather 41%, eat 6% |
| FOSO | GA BIYI | 7 | 1 | 7 | 1 | 2 | idle 58%, gather 22%, eat 8% |
| FUUV | GA BIYI | 8 | 1 | 5 | 0 | 2 | idle 73%, gather 14%, eat 6% |
| GENI | GA BIYI | 7 | 0 | 4 | 0 | 0 | idle 80%, gather 11%, eat 6% |
| GIME | GA BIYI | 23 | 2 | 13 | 0 | 2 | gather 53%, idle 16%, wander 11% |
| GOON | TI CARI | 30 | 4 | 26 | 2 | 3 | gather 38%, herd_wildnpc 20%, idle 15% |
| GUEZ | GA BIYI | 24 | 3 | 17 | 0 | 4 | gather 61%, wander 16%, idle 7% |
| JAPE | SO MOED | 6 | 0 | 4 | 0 | 0 | idle 70%, gather 14%, herd_wildnpc 11% |
| JAUQ | LI GIMU | 28 | 4 | 22 | 1 | 2 | gather 60%, idle 19%, wander 14% |
| KUKO | SO MOED | 10 | 1 | 10 | 1 | 3 | idle 66%, gather 26%, herd_wildnpc 5% |
| LAUG | LI GIMU | 15 | 2 | 14 | 1 | 5 | gather 58%, herd_wildnpc 29%, wander 13% |
| LIAH | TI CARI | 19 | 3 | 9 | 0 | 1 | gather 45%, idle 30%, herd_wildnpc 10% |
| MAAW | LI GIMU | 19 | 2 | 16 | 4 | 6 | gather 51%, idle 25%, craft 12% |
| MAYI | LI GIMU | 13 | 4 | 13 | 0 | 2 | idle 35%, gather 28%, combat 20% |
| NEEZ | GA BIYI | 13 | 3 | 13 | 0 | 2 | idle 50%, gather 34%, wander 7% |
| NUBA | SO MOED | 6 | 0 | 4 | 0 | 0 | idle 87%, gather 8%, eat 4% |
| QAEF | SO MOED | 11 | 2 | 18 | 1 | 3 | gather 50%, idle 34%, craft 8% |
| QAFU | LI GIMU | 5 | 0 | 4 | 0 | 0 | idle 56%, gather 35%, wander 9% |
| QOIY | TI CARI | 25 | 5 | 17 | 0 | 3 | idle 43%, gather 37%, wander 7% |
| QOVU | LI GIMU | 7 | 2 | 2 | 0 | 0 | idle 45%, gather 37%, wander 8% |
| QUUJ | LI GIMU | 7 | 0 | 5 | 0 | 1 | idle 67%, gather 24%, eat 5% |
| REVI | TI CARI | 7 | 1 | 4 | 0 | 1 | herd_wildnpc 36%, gather 35%, idle 27% |
| ROLA | SO MOED | 23 | 3 | 22 | 2 | 3 | gather 63%, idle 14%, party 9% |
| RUIS | LI GIMU | 6 | 0 | 4 | 0 | 0 | idle 79%, gather 16%, eat 4% |
| SAED | LI GIMU | 4 | 0 | 2 | 0 | 0 | idle 68%, gather 30%, wander 1% |
| SOFI | LI GIMU | 28 | 4 | 33 | 0 | 2 | gather 40%, idle 27%, craft 15% |
| TELI | GA BIYI | 25 | 5 | 24 | 0 | 4 | gather 37%, idle 37%, wander 15% |
| TOZA | GA BIYI | 17 | 2 | 16 | 0 | 3 | gather 55%, idle 25%, wander 11% |
| TUOB | LI GIMU | 5 | 0 | 3 | 1 | 1 | idle 85%, gather 10%, eat 3% |
| VIXO | TI CARI | 28 | 6 | 24 | 1 | 3 | gather 51%, idle 27%, wander 13% |
| VULI | LI GIMU | 14 | 1 | 11 | 0 | 0 | idle 52%, gather 41%, eat 4% |
| VUZO | LI GIMU | 20 | 3 | 14 | 0 | 2 | gather 54%, herd_wildnpc 31%, wander 11% |
| WUIW | LI GIMU | 20 | 5 | 20 | 0 | 4 | gather 51%, combat 19%, herd_wildnpc 10% |
| XAUQ | SO MOED | 15 | 4 | 21 | 1 | 4 | idle 44%, gather 40%, build_milestone 4% |
| XIVE | LI GIMU | 12 | 2 | 15 | 1 | 3 | gather 58%, idle 30%, wander 10% |
| ZIEP | TI CARI | 16 | 2 | 10 | 2 | 4 | gather 50%, idle 40%, wander 7% |
| ZONI | TI CARI | 24 | 4 | 18 | 4 | 10 | gather 53%, craft 25%, wander 9% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| GA BIYI | 33 | 4 | 4 | 4 | 0 | 0 | 2 | 0 |
| LI GIMU | 34 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| SO MOED | 33 | 5 | 5 | 5 | 0 | 0 | 3 | 0 |
| TI CARI | 34 | 8 | 8 | 8 | 0 | 0 | 3 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| GA BIYI | 3 | 5 | 2 | 2 |
| LI GIMU | 3 | 4 | 2 | 1 |
| SO MOED | 2 | 2 | 1 | 0 |
| TI CARI | 4 | 4 | 3 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| GA BIYI | 170 | 5 | 97% | 0 | 10 | idle 38%, gather 36%, wander 12% |
| LI GIMU | 272 | 10 | 96% | 0 | 23 | gather 39%, idle 32%, herd_wildnpc 8% |
| SO MOED | 131 | 6 | 96% | 0 | 8 | idle 41%, gather 39%, wander 7% |
| TI CARI | 232 | 25 | 90% | 0 | 14 | gather 44%, idle 25%, wander 8% |

## Economy (session)

- **Items gathered:** 839
- **Items deposited:** 630
- **Deposit yield:** 75%
- **Gather failures (all):** 130
- **Gather failures (actionable):** 25
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 105
- **not_harvestable:** 15
- **resource_invalid:** 10

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 42 | 22 | 52% |
| Bone | 0 | 27 | — |
| Fiber | 39 | 36 | 92% |
| Grain | 21 | 7 | 33% |
| Hide | 0 | 36 | — |
| Meat | 0 | 44 | — |
| Mushroom | 10 | 10 | 100% |
| Nuts | 137 | 51 | 37% |
| Spear | 0 | 42 | — |
| Stone | 31 | 26 | 84% |
| Wood | 559 | 329 | 59% |

## Buildings (session)

- **Total placed:** 15

### By type

- **Living Hut:** 7
- **Drying Rack:** 3
- **Dairy Farm:** 2
- **Farm:** 2
- **Oven:** 1

### By source

- **milestone:** 8
- **herder_hut:** 7

### Chronological

- t=44.4s **LI GIMU** — Living Hut (herder_hut) builder=VAIR @ (-762,-2473)
- t=53.3s **TI CARI** — Living Hut (herder_hut) builder=BANI @ (2012,973)
- t=62.4s **SO MOED** — Living Hut (herder_hut) builder=POAD @ (824,3461)
- t=67.6s **GA BIYI** — Living Hut (herder_hut) builder=ZAAX @ (-2990,1553)
- t=109.3s **LI GIMU** — Living Hut (herder_hut) builder=VAIR @ (-591,-2327)
- t=170.5s **SO MOED** — Drying Rack (milestone) @ (760,3562)
- t=174.6s **TI CARI** — Drying Rack (milestone) @ (2037,924)
- t=180.7s **GA BIYI** — Living Hut (herder_hut) builder=ZAAX @ (-2896,1774)
- t=220.5s **GA BIYI** — Drying Rack (milestone) @ (-2847,1735)
- t=259.8s **TI CARI** — Oven (milestone) @ (1800,891)
- t=291.9s **GA BIYI** — Living Hut (herder_hut) builder=GUEZ @ (-2825,1679)
- t=331.7s **GA BIYI** — Dairy Farm (milestone) @ (-3055,1618)
- t=361.4s **LI GIMU** — Dairy Farm (milestone) @ (-807,-2430)
- t=413.2s **LI GIMU** — Farm (milestone) @ (-649,-2262)
- t=416.7s **TI CARI** — Farm (milestone) @ (1841,805)

## Per-clan detail

### GA BIYI

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/0 (93% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.1k → 0
- **Daily calorie need (end):** 39.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 4 |
| Bone | 0 | 6 |
| Fiber | 12 | 12 |
| Grain | 9 | 2 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 1 | 1 |
| Nuts | 28 | 9 |
| Spear | 0 | 9 |
| Stone | 3 | 1 |
| Wood | 102 | 49 |

#### Failures

- **Gather:** empty_switch:not_harvestable=7, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DOIN | 8 | 0 | 1 | 12 | idle 60%, gather 24%, wander 11% |
| FOSO | 7 | 1 | 1 | 7 | idle 58%, gather 22%, eat 8% |
| FUUV | 5 | 0 | 1 | 8 | idle 73%, gather 14%, eat 6% |
| GENI | 4 | 0 | 0 | 7 | idle 80%, gather 11%, eat 6% |
| GIME | 13 | 0 | 2 | 23 | gather 53%, idle 16%, wander 11% |
| GUEZ | 17 | 0 | 3 | 24 | gather 61%, wander 16%, idle 7% |
| NEEZ | 13 | 0 | 3 | 13 | idle 50%, gather 34%, wander 7% |
| TELI | 24 | 0 | 5 | 25 | gather 37%, idle 37%, wander 15% |
| TOZA | 16 | 0 | 2 | 17 | gather 55%, idle 25%, wander 11% |
| ZAAX | 22 | 1 | 10 | 28 | gather 44%, wander 32%, herd_wildnpc 12% |

#### Hunts

- start t=102.6s prey=deer quota=2
- start t=152.6s prey=deer quota=3
- start t=587.9s prey=deer quota=4
- hunt_completed t=149.6s reason=loot_complete
- hunt_completed t=185.4s reason=loot_complete

#### Buildings

- t=67.6s **Living Hut** — herder_hut (builder: ZAAX)
- t=180.7s **Living Hut** — herder_hut (builder: ZAAX)
- t=220.5s **Drying Rack** — milestone
- t=291.9s **Living Hut** — herder_hut (builder: GUEZ)
- t=331.7s **Dairy Farm** — milestone

### LI GIMU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 6/6 (89% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.3k → 0
- **Daily calorie need (end):** 65.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 15 | 9 |
| Bone | 0 | 6 |
| Fiber | 15 | 12 |
| Hide | 0 | 8 |
| Meat | 0 | 9 |
| Mushroom | 3 | 3 |
| Nuts | 57 | 20 |
| Spear | 0 | 17 |
| Stone | 14 | 14 |
| Wood | 240 | 145 |

#### Failures

- **Gather:** empty_switch:not_harvestable=69, not_harvestable=4, resource_invalid=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAGE | 18 | 0 | 3 | 28 | gather 48%, idle 41%, wander 8% |
| CAER | 9 | 0 | 1 | 12 | idle 56%, gather 18%, build_milestone 11% |
| DATO | 11 | 1 | 2 | 13 | gather 52%, herd_wildnpc 22%, wander 12% |
| DUUX | 10 | 0 | 2 | 17 | idle 55%, gather 35%, eat 7% |
| FAOP | 10 | 0 | 1 | 14 | idle 32%, gather 26%, hunt 24% |
| FEOY | 15 | 1 | 2 | 23 | idle 44%, gather 41%, eat 6% |
| JAUQ | 22 | 1 | 4 | 28 | gather 60%, idle 19%, wander 14% |
| LAUG | 14 | 1 | 2 | 15 | gather 58%, herd_wildnpc 29%, wander 13% |
| MAAW | 16 | 4 | 2 | 19 | gather 51%, idle 25%, craft 12% |
| MAYI | 13 | 0 | 4 | 13 | idle 35%, gather 28%, combat 20% |
| QAFU | 4 | 0 | 0 | 5 | idle 56%, gather 35%, wander 9% |
| QOVU | 2 | 0 | 2 | 7 | idle 45%, gather 37%, wander 8% |
| QUUJ | 5 | 0 | 0 | 7 | idle 67%, gather 24%, eat 5% |
| RUIS | 4 | 0 | 0 | 6 | idle 79%, gather 16%, eat 4% |
| SAED | 2 | 0 | 0 | 4 | idle 68%, gather 30%, wander 1% |
| SOFI | 33 | 0 | 4 | 28 | gather 40%, idle 27%, craft 15% |
| TUOB | 3 | 1 | 0 | 5 | idle 85%, gather 10%, eat 3% |
| VAIR | 21 | 0 | 10 | 34 | gather 31%, herd_wildnpc 23%, combat 17% |
| VULI | 11 | 0 | 1 | 14 | idle 52%, gather 41%, eat 4% |
| VUZO | 14 | 0 | 3 | 20 | gather 54%, herd_wildnpc 31%, wander 11% |
| WUIW | 20 | 0 | 5 | 20 | gather 51%, combat 19%, herd_wildnpc 10% |
| XIVE | 15 | 1 | 2 | 12 | gather 58%, idle 30%, wander 10% |

#### Hunts

- start t=80.1s prey=deer quota=2
- start t=120.1s prey=deer quota=3
- start t=275.3s prey=deer quota=4
- hunt_completed t=118.3s reason=loot_complete
- hunt_aborted t=240.2s reason=active_timeout
- hunt_completed t=311.7s reason=loot_complete

#### Buildings

- t=44.4s **Living Hut** — herder_hut (builder: VAIR)
- t=109.3s **Living Hut** — herder_hut (builder: VAIR)
- t=361.4s **Dairy Farm** — milestone
- t=413.2s **Farm** — milestone

### SO MOED

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (78% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.3k → 0
- **Daily calorie need (end):** 19.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 3 |
| Bone | 0 | 6 |
| Fiber | 6 | 6 |
| Grain | 3 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 2 | 1 |
| Nuts | 13 | 3 |
| Spear | 0 | 5 |
| Stone | 2 | 2 |
| Wood | 70 | 33 |

#### Failures

- **Gather:** empty_switch:not_harvestable=7, not_harvestable=3, resource_invalid=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| JAPE | 4 | 0 | 0 | 6 | idle 70%, gather 14%, herd_wildnpc 11% |
| KUKO | 10 | 1 | 1 | 10 | idle 66%, gather 26%, herd_wildnpc 5% |
| NUBA | 4 | 0 | 0 | 6 | idle 87%, gather 8%, eat 4% |
| POAD | 29 | 1 | 10 | 34 | gather 54%, wander 24%, party 8% |
| QAEF | 18 | 1 | 2 | 11 | gather 50%, idle 34%, craft 8% |
| ROLA | 22 | 2 | 3 | 23 | gather 63%, idle 14%, party 9% |
| XAUQ | 21 | 1 | 4 | 15 | idle 44%, gather 40%, build_milestone 4% |

#### Hunts

- start t=97.9s prey=deer quota=2
- start t=143.0s prey=deer quota=3
- hunt_completed t=139.9s reason=loot_complete
- hunt_completed t=206.0s reason=loot_complete

#### Buildings

- t=62.4s **Living Hut** — herder_hut (builder: POAD)
- t=170.5s **Drying Rack** — milestone

### TI CARI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/4 (88% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.3k → 0
- **Daily calorie need (end):** 47.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 6 |
| Bone | 0 | 9 |
| Fiber | 6 | 6 |
| Grain | 9 | 5 |
| Hide | 0 | 12 |
| Meat | 0 | 15 |
| Mushroom | 4 | 5 |
| Nuts | 39 | 19 |
| Spear | 0 | 11 |
| Stone | 12 | 9 |
| Wood | 147 | 102 |

#### Failures

- **Gather:** empty_switch:not_harvestable=22, not_harvestable=8, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BANI | 39 | 2 | 15 | 43 | gather 57%, wander 24%, herd_wildnpc 9% |
| BAVU | 13 | 2 | 3 | 13 | gather 85%, wander 8%, herd_wildnpc 7% |
| DEDO | 6 | 0 | 1 | 5 | idle 66%, gather 17%, build_milestone 13% |
| FANU | 19 | 1 | 3 | 16 | idle 39%, gather 27%, craft 13% |
| GOON | 26 | 2 | 4 | 30 | gather 38%, herd_wildnpc 20%, idle 15% |
| LIAH | 9 | 0 | 3 | 19 | gather 45%, idle 30%, herd_wildnpc 10% |
| QOIY | 17 | 0 | 5 | 25 | idle 43%, gather 37%, wander 7% |
| REVI | 4 | 0 | 1 | 7 | herd_wildnpc 36%, gather 35%, idle 27% |
| VIXO | 24 | 1 | 6 | 28 | gather 51%, idle 27%, wander 13% |
| ZIEP | 10 | 2 | 2 | 16 | gather 50%, idle 40%, wander 7% |
| ZONI | 18 | 4 | 4 | 24 | gather 53%, craft 25%, wander 9% |

#### Hunts

- start t=89.6s prey=deer quota=2
- start t=129.7s prey=deer quota=3
- start t=234.8s prey=deer quota=4
- hunt_completed t=127.4s reason=loot_complete
- hunt_completed t=157.6s reason=loot_complete
- hunt_completed t=273.9s reason=loot_complete

#### Buildings

- t=53.3s **Living Hut** — herder_hut (builder: BANI)
- t=174.6s **Drying Rack** — milestone
- t=259.8s **Oven** — milestone
- t=416.7s **Farm** — milestone

