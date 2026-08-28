# ClanBrain Report (standard)

## Session

- **Duration:** 300.6s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_5min_20260620_160217/playtest_session.jsonl`
- **World seed:** 0
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 6
- **Simulation ticks:** 2
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 6/6 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| BA DOJA | 0→11 | 9 | 0 | 23.6k | 0.0 | 3 | 3 | 74 | 70 | 1 | 79% | 94.9s | 8 | 1 | 99.1s |
| JU SALO | 0→15 | 9 | 0 | 31.2k | 0.0 | 2 | 2 | 34 | 41 | 2 | 78% | 85.0s | 8 | 2 | 86.6s |
| KI YAFE | 0→10 | 8 | 0 | 21.4k | 0.0 | 2 | 2 | 33 | 38 | 1 | 77% | 80.1s | 7 | 3 | 85.0s |
| TA DAER | 0→10 | 8 | 0 | 21.4k | 0.0 | 2 | 2 | 66 | 59 | 1 | 68% | 75.0s | 7 | 2 | 75.8s |
| TI JAXO | 0→9 | 1 | 0 | 18.2k | 0.0 | 0 | 0 | 0 | 1 | 0 | 80% | 295.6s | 0 | 0 | — |
| YU QEFI | 0→0 | 0 | 200 | 0 | 1.0 | 0 | 0 | 0 | 1 | 0 | — | 0.0s | 0 | 0 | — |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 9 / 9
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| BA DOJA | — | — | 79% | 12% | 0→2.8k→0 | 0.0→1.0→0.0 | 94.9s |
| JU SALO | — | — | 78% | 17% | 0→1.8k→0 | 0.0→1.0→0.0 | 85.0s |
| KI YAFE | — | — | 77% | 17% | 0→2.7k→0 | 0.0→1.0→0.0 | 80.1s |
| TA DAER | — | — | 68% | 25% | 0→2.7k→0 | 0.0→1.0→0.0 | 75.0s |
| TI JAXO | — | — | 80% | 20% | 0→200→0 | 0.0→1.0→0.0 | 295.6s |
| YU QEFI | — | — | — | — | 200→200→200 | 1.0→1.0→1.0 | 0.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| BA DOJA | 3 | 3 | 0 | 3 | 0 | 11 | 12 |
| JU SALO | 2 | 2 | 0 | 2 | 0 | 8 | 8 |
| KI YAFE | 2 | 2 | 0 | 2 | 0 | 7 | 7 |
| TA DAER | 2 | 2 | 0 | 2 | 0 | 7 | 7 |
| TI JAXO | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| YU QEFI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| BA DOJA | 1 | 8 | 8 | 96.8s |
| JU SALO | 3 | 8 | 8 | 81.7s |
| KI YAFE | 1 | 7 | 7 | 83.0s |
| TA DAER | 1 | 7 | 7 | 72.0s |
| TI JAXO | 0 | 0 | 0 | — |
| YU QEFI | 0 | 0 | 0 | — |

## Clansmen workforce

- **Unique clansmen seen:** 30 (gather FSM transitions: 144, productivity snapshots: 10)
- **Last snapshot:** clansmen=30 with_job=15 (all workers job %=48.5714285714286)

| Clan | Clansmen | Grown | Gathered (clansmen) | Deposited (clansmen) | Deposit trips | Task cancels | Top cancel reasons |
|------|----------|-------|---------------------|----------------------|---------------|--------------|-------------------|
| BA DOJA | 8 | 8 | 64 | 54 | 14 | 23 | state_exit_clear_tasks=11, exited_tree=4, resource_node_invalid=3 |
| JU SALO | 8 | 8 | 33 | 37 | 12 | 24 | state_exit_clear_tasks=10, exited_tree=7, resource_node_invalid=5 |
| KI YAFE | 7 | 7 | 26 | 24 | 9 | 21 | state_exit_clear_tasks=9, resource_node_invalid=5, exited_tree=4 |
| TA DAER | 7 | 7 | 49 | 41 | 9 | 15 | state_exit_clear_tasks=7, resource_node_invalid=4, exited_tree=3 |
| TI JAXO | 0 | 0 | 0 | 0 | 0 | 0 | — |
| YU QEFI | 0 | 0 | 0 | 0 | 0 | 0 | — |

### Per-clansman activity

| NPC | Clan | Gathered | Deposits | Task OK | Task fail | Cancels | Top states |
|-----|------|----------|----------|---------|-----------|---------|------------|
| DAEQ | KI YAFE | 3 | 1 | 1 | 0 | 1 | gather 52%, build_milestone 24%, wander 15% |
| DAKA | JU SALO | 0 | 1 | 0 | 0 | 1 | wander 49%, gather 47%, idle 4% |
| DIGE | TA DAER | 6 | 1 | 2 | 0 | 1 | idle 50%, gather 24%, build_milestone 22% |
| DOXE | BA DOJA | 10 | 4 | 15 | 1 | 3 | gather 47%, idle 16%, craft 11% |
| FIAT | TA DAER | 7 | 0 | 2 | 0 | 0 | gather 57%, idle 36%, eat 6% |
| GEOB | BA DOJA | 6 | 1 | 16 | 0 | 2 | craft 68%, gather 13%, wander 12% |
| GORU | BA DOJA | 4 | 0 | 1 | 0 | 1 | gather 100% |
| JAOW | KI YAFE | 4 | 1 | 8 | 0 | 5 | gather 78%, herd_wildnpc 12%, wander 10% |
| JIZU | JU SALO | 3 | 1 | 2 | 0 | 1 | herd_wildnpc 63%, wander 23%, gather 13% |
| JUIJ | BA DOJA | 11 | 1 | 10 | 1 | 2 | gather 72%, idle 17%, eat 10% |
| MOJA | JU SALO | 9 | 2 | 12 | 1 | 4 | gather 75%, wander 10%, hunt 8% |
| NAJO | KI YAFE | 5 | 1 | 1 | 0 | 1 | gather 96%, wander 3%, idle 1% |
| NAJU | KI YAFE | 9 | 1 | 7 | 1 | 2 | gather 69%, build_milestone 20%, idle 4% |
| PALE | JU SALO | 0 | 1 | 5 | 0 | 4 | gather 76%, herd_wildnpc 22%, wander 1% |
| QEHE | JU SALO | 6 | 4 | 10 | 1 | 5 | gather 59%, eat 12%, party 11% |
| SUJE | JU SALO | 6 | 2 | 11 | 0 | 2 | gather 76%, party 15%, eat 7% |
| VISE | KI YAFE | 0 | 4 | 15 | 2 | 7 | gather 57%, craft 28%, eat 5% |
| VOAK | BA DOJA | 2 | 0 | 1 | 0 | 1 | gather 83%, wander 16%, idle 1% |
| VOYE | BA DOJA | 9 | 5 | 16 | 0 | 2 | gather 73%, eat 10%, idle 8% |
| VUIW | TA DAER | 4 | 0 | 1 | 0 | 2 | gather 91%, eat 9%, wander 0% |
| VUOD | TA DAER | 5 | 2 | 13 | 0 | 2 | craft 41%, herd_wildnpc 30%, gather 16% |
| WOAR | KI YAFE | 5 | 0 | 1 | 0 | 1 | gather 52%, eat 19%, idle 15% |
| WUGO | BA DOJA | 4 | 1 | 7 | 0 | 3 | gather 97%, wander 3%, hunt 1% |
| XANU | BA DOJA | 18 | 2 | 21 | 1 | 4 | gather 45%, craft 27%, eat 16% |
| XAQI | TA DAER | 12 | 1 | 5 | 0 | 1 | gather 67%, wander 18%, idle 11% |
| XEJA | TA DAER | 6 | 2 | 11 | 0 | 3 | idle 37%, gather 36%, eat 16% |
| XELA | JU SALO | 6 | 1 | 3 | 0 | 3 | gather 71%, wander 22%, eat 6% |
| XUNA | JU SALO | 3 | 0 | 1 | 0 | 1 | gather 84%, wander 15%, idle 1% |
| YEPI | KI YAFE | 0 | 1 | 0 | 0 | 1 | gather 100% |
| ZOOG | TA DAER | 9 | 3 | 14 | 1 | 4 | gather 43%, idle 37%, party 10% |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| BA DOJA | 13 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| JU SALO | 14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KI YAFE | 14 | 2 | 2 | 2 | 0 | 0 | 0 | 0 |
| TA DAER | 15 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| TI JAXO | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| YU QEFI | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| BA DOJA | 3 | 3 | 0 | 0 |
| JU SALO | 2 | 2 | 1 | 0 |
| KI YAFE | 2 | 2 | 2 | 0 |
| TA DAER | 2 | 2 | 1 | 0 |
| TI JAXO | 1 | 1 | 0 | 0 |
| YU QEFI | 0 | 0 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| BA DOJA | 109 | 3 | 97% | 0 | 3 | gather 56%, craft 13%, eat 6% |
| JU SALO | 54 | 2 | 96% | 0 | 4 | gather 58%, herd_wildnpc 14%, party 10% |
| KI YAFE | 59 | 3 | 95% | 0 | 6 | gather 59%, craft 11%, wander 7% |
| TA DAER | 62 | 1 | 98% | 0 | 1 | gather 42%, idle 20%, herd_wildnpc 10% |
| TI JAXO | 0 | 0 | — | 0 | 0 | herd_wildnpc 82%, wander 14%, eat 4% |
| YU QEFI | 0 | 0 | — | 0 | 0 | — |

## Economy (session)

- **Items gathered:** 207
- **Items deposited:** 210
- **Deposit yield:** 101%
- **Gather failures (all):** 6
- **Gather failures (actionable):** 5
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 5
- **empty_switch:not_harvestable:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 6 | 0 | 0% |
| Bone | 0 | 24 | — |
| Fiber | 21 | 10 | 48% |
| Grain | 6 | 3 | 50% |
| Hide | 0 | 36 | — |
| Meat | 0 | 45 | — |
| Mushroom | 35 | 17 | 49% |
| Nuts | 18 | 4 | 22% |
| Spear | 0 | 30 | — |
| Stone | 56 | 19 | 34% |
| Wood | 65 | 22 | 34% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 4
- **Farm:** 2
- **Dairy Farm:** 1
- **Drying Rack:** 1

### By source

- **herder_hut:** 4
- **milestone:** 4

### Chronological

- t=39.5s **TA DAER** — Living Hut (herder_hut) builder=VOJU @ (276,2252)
- t=49.2s **JU SALO** — Living Hut (herder_hut) builder=QEON @ (2980,706)
- t=50.6s **KI YAFE** — Living Hut (herder_hut) builder=PIIZ @ (-2094,-937)
- t=64.4s **BA DOJA** — Living Hut (herder_hut) builder=MAGA @ (1006,-2191)
- t=109.9s **JU SALO** — Farm (milestone) @ (2763,612)
- t=169.2s **KI YAFE** — Drying Rack (milestone) @ (-2290,-1063)
- t=234.6s **KI YAFE** — Farm (milestone) @ (-2237,-1127)
- t=289.3s **TA DAER** — Dairy Farm (milestone) @ (432,2414)

## Per-clan detail

### BA DOJA

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (79% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.8k → 0
- **Daily calorie need (end):** 23.6k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 0 |
| Bone | 0 | 6 |
| Fiber | 12 | 10 |
| Grain | 6 | 3 |
| Hide | 0 | 12 |
| Meat | 0 | 15 |
| Mushroom | 4 | 3 |
| Nuts | 5 | 1 |
| Spear | 0 | 7 |
| Stone | 17 | 7 |
| Wood | 24 | 6 |

#### Failures

- **Gather:** resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DOXE | 15 | 1 | 4 | 10 | gather 47%, idle 16%, craft 11% |
| GEOB | 16 | 0 | 1 | 6 | craft 68%, gather 13%, wander 12% |
| GORU | 1 | 0 | 0 | 4 | gather 100% |
| JUIJ | 10 | 1 | 1 | 11 | gather 72%, idle 17%, eat 10% |
| MAGA | 22 | 0 | 8 | 10 | gather 52%, herd_wildnpc 27%, build_hut_for_woman 7% |
| VOAK | 1 | 0 | 0 | 2 | gather 83%, wander 16%, idle 1% |
| VOYE | 16 | 0 | 5 | 9 | gather 73%, eat 10%, idle 8% |
| WUGO | 7 | 0 | 1 | 4 | gather 97%, wander 3%, hunt 1% |
| XANU | 21 | 1 | 2 | 18 | gather 45%, craft 27%, eat 16% |

#### Hunts

- start t=99.1s prey=deer quota=2
- start t=139.1s prey=deer quota=3
- start t=193.9s prey=deer quota=4
- hunt_completed t=138.7s reason=loot_complete
- hunt_completed t=157.3s reason=loot_complete
- hunt_completed t=227.6s reason=loot_complete

#### Buildings

- t=64.4s **Living Hut** — herder_hut (builder: MAGA)

### JU SALO

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (78% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 1.8k → 0
- **Daily calorie need (end):** 31.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Fiber | 3 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 12 | 5 |
| Nuts | 2 | 1 |
| Spear | 0 | 8 |
| Stone | 9 | 0 |
| Wood | 8 | 3 |

#### Failures

- **Gather:** resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DAKA | 0 | 0 | 1 | 0 | wander 49%, gather 47%, idle 4% |
| JIZU | 2 | 0 | 1 | 3 | herd_wildnpc 63%, wander 23%, gather 13% |
| MOJA | 12 | 1 | 2 | 9 | gather 75%, wander 10%, hunt 8% |
| PALE | 5 | 0 | 1 | 0 | gather 76%, herd_wildnpc 22%, wander 1% |
| QEHE | 10 | 1 | 4 | 6 | gather 59%, eat 12%, party 11% |
| QEON | 10 | 0 | 3 | 1 | gather 34%, herd_wildnpc 33%, party 24% |
| SUJE | 11 | 0 | 2 | 6 | gather 76%, party 15%, eat 7% |
| XELA | 3 | 0 | 1 | 6 | gather 71%, wander 22%, eat 6% |
| XUNA | 1 | 0 | 0 | 3 | gather 84%, wander 15%, idle 1% |

#### Hunts

- start t=86.6s prey=deer quota=2
- start t=176.3s prey=deer quota=4
- hunt_completed t=175.0s reason=loot_complete
- hunt_completed t=226.7s reason=loot_complete

#### Buildings

- t=49.2s **Living Hut** — herder_hut (builder: QEON)
- t=109.9s **Farm** — milestone

### KI YAFE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (77% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.7k → 0
- **Daily calorie need (end):** 21.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 5 | 0 |
| Nuts | 4 | 0 |
| Spear | 0 | 7 |
| Stone | 15 | 3 |
| Wood | 9 | 4 |

#### Failures

- **Gather:** empty_switch:not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DAEQ | 1 | 0 | 1 | 3 | gather 52%, build_milestone 24%, wander 15% |
| JAOW | 8 | 0 | 1 | 4 | gather 78%, herd_wildnpc 12%, wander 10% |
| NAJO | 1 | 0 | 1 | 5 | gather 96%, wander 3%, idle 1% |
| NAJU | 7 | 1 | 1 | 9 | gather 69%, build_milestone 20%, idle 4% |
| PIIZ | 18 | 0 | 6 | 7 | gather 45%, craft 21%, wander 12% |
| VISE | 15 | 2 | 4 | 0 | gather 57%, craft 28%, eat 5% |
| WOAR | 1 | 0 | 0 | 5 | gather 52%, eat 19%, idle 15% |
| YEPI | 0 | 0 | 1 | 0 | gather 100% |

#### Hunts

- start t=85.0s prey=deer quota=2
- start t=129.7s prey=deer quota=2
- hunt_completed t=125.2s reason=loot_complete
- hunt_completed t=177.3s reason=loot_complete

#### Buildings

- t=50.6s **Living Hut** — herder_hut (builder: PIIZ)
- t=169.2s **Drying Rack** — milestone
- t=234.6s **Farm** — milestone

### TA DAER

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (68% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 2.7k → 0
- **Daily calorie need (end):** 21.4k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Fiber | 6 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 14 | 9 |
| Nuts | 7 | 2 |
| Spear | 0 | 6 |
| Stone | 15 | 9 |
| Wood | 24 | 9 |

#### Failures

- **Gather:** resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DIGE | 2 | 0 | 1 | 6 | idle 50%, gather 24%, build_milestone 22% |
| FIAT | 2 | 0 | 0 | 7 | gather 57%, idle 36%, eat 6% |
| VOJU | 14 | 0 | 8 | 17 | gather 40%, herd_wildnpc 25%, wander 18% |
| VUIW | 1 | 0 | 0 | 4 | gather 91%, eat 9%, wander 0% |
| VUOD | 13 | 0 | 2 | 5 | craft 41%, herd_wildnpc 30%, gather 16% |
| XAQI | 5 | 0 | 1 | 12 | gather 67%, wander 18%, idle 11% |
| XEJA | 11 | 0 | 2 | 6 | idle 37%, gather 36%, eat 16% |
| ZOOG | 14 | 1 | 3 | 9 | gather 43%, idle 37%, party 10% |

#### Hunts

- start t=75.8s prey=deer quota=2
- start t=115.6s prey=deer quota=3
- hunt_completed t=113.5s reason=loot_complete
- hunt_completed t=141.5s reason=loot_complete

#### Buildings

- t=39.5s **Living Hut** — herder_hut (builder: VOJU)
- t=289.3s **Dairy Farm** — milestone

### TI JAXO

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (80% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 0 → 200 → 0
- **Daily calorie need (end):** 18.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| LAAX | 0 | 0 | 1 | 0 | herd_wildnpc 82%, wander 14%, eat 4% |

### YU QEFI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (— fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 1.0 → 1.0 → 1.0
- **Calories in storage:** 200 → 200 → 200
- **Daily calorie need (end):** 0
- **Calorie days buffer:** 1.0 → 1.0 → 1.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

