# ClanBrain Report (standard)

## Session

- **Duration:** 1800.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_30min_20260531_133029/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 30 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| CA DEAR | 0→30 | 19 | 0.0 | 3 | 2 | 405 | 292 | 12 | 49% | 310.3s | 18 | 3 | 314.2s |
| DI XUAL | 0→27 | 16 | 0.0 | 3 | 2 | 430 | 314 | 39 | 70% | 225.3s | 15 | 4 | 230.3s |
| NA ZIQE | 0→8 | 1 | 0.0 | 0 | 0 | 130 | 120 | 0 | 34% | 1797.3s | 0 | 3 | — |
| YO GAXI | 0→28 | 16 | 0.0 | 3 | 2 | 425 | 302 | 11 | 78% | 405.5s | 15 | 3 | 407.3s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 9 / 9
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| CA DEAR | — | — | 49% | 33% | 0.0→0.2→0.0 | 310.3s |
| DI XUAL | — | — | 70% | 14% | 0.0→0.5→0.0 | 225.3s |
| NA ZIQE | — | — | 34% | 17% | 0.0→0.0→0.0 | 1797.3s |
| YO GAXI | — | — | 78% | 17% | 0.0→0.2→0.0 | 405.5s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| CA DEAR | 3 | 2 | 1 | 2 | 0 | 0 | 0 |
| DI XUAL | 3 | 2 | 1 | 2 | 0 | 3 | 0 |
| NA ZIQE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| YO GAXI | 3 | 2 | 1 | 2 | 0 | 4 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| CA DEAR | 5 | 18 | 18 | 314.0s |
| DI XUAL | 3 | 15 | 15 | 229.3s |
| NA ZIQE | 2 | 0 | 0 | — |
| YO GAXI | 2 | 15 | 15 | 402.7s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| CA DEAR | 0 | 0 | — | 0 | 10 | idle 65%, gather 16%, wander 6% |
| DI XUAL | 0 | 0 | — | 0 | 17 | idle 68%, gather 16%, wander 5% |
| NA ZIQE | 0 | 0 | — | 0 | 0 | wander 39%, herd_wildnpc 30%, gather 28% |
| YO GAXI | 0 | 0 | — | 0 | 11 | idle 72%, gather 12%, eat 4% |

## Economy (session)

- **Items gathered:** 1390
- **Items deposited:** 1028
- **Deposit yield:** 74%
- **Gather failures (all):** 554
- **Gather failures (actionable):** 62
- **Deposit failures:** 0

### Gather failures (actionable)

- **not_harvestable:** 58
- **empty_switch:not_harvestable:** 45
- **resource_invalid:** 4

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 69 | 40 | 58% |
| Bone | 0 | 13 | — |
| Fiber | 90 | 69 | 77% |
| Grain | 46 | 25 | 54% |
| Hide | 0 | 22 | — |
| Meat | 0 | 29 | — |
| Mushroom | 3 | 2 | 67% |
| Nuts | 183 | 86 | 47% |
| Spear | 0 | 29 | — |
| Stone | 169 | 133 | 79% |
| Wood | 830 | 580 | 70% |

## Buildings (session)

- **Total placed:** 13

### By type

- **Farm:** 4
- **Living Hut:** 4
- **Dairy Farm:** 3
- **Oven:** 2

### By source

- **milestone:** 9
- **herder_hut:** 4

### Chronological

- t=48.6s **YO GAXI** — Living Hut (herder_hut) builder=MOAC @ (1547,2717)
- t=50.9s **NA ZIQE** — Living Hut (herder_hut) builder=QOES @ (3522,548)
- t=60.4s **DI XUAL** — Living Hut (herder_hut) builder=JABE @ (631,-3187)
- t=65.2s **CA DEAR** — Living Hut (herder_hut) builder=BUJE @ (-2824,651)
- t=277.2s **YO GAXI** — Dairy Farm (milestone) @ (1590,2645)
- t=423.6s **NA ZIQE** — Farm (milestone) @ (3336,437)
- t=463.7s **NA ZIQE** — Oven (milestone) @ (3560,508)
- t=505.6s **DI XUAL** — Oven (milestone) @ (393,-3216)
- t=582.5s **YO GAXI** — Farm (milestone) @ (1375,2553)
- t=759.6s **CA DEAR** — Dairy Farm (milestone) @ (-2856,722)
- t=844.6s **CA DEAR** — Farm (milestone) @ (-3048,580)
- t=850.8s **DI XUAL** — Farm (milestone) @ (603,-3122)
- t=1091.0s **DI XUAL** — Dairy Farm (milestone) @ (440,-3296)

## Per-clan detail

### CA DEAR

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/6 (49% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 0.2 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 1 |
| Fiber | 33 | 27 |
| Grain | 43 | 22 |
| Hide | 0 | 6 |
| Meat | 0 | 10 |
| Nuts | 60 | 32 |
| Spear | 0 | 8 |
| Stone | 9 | 2 |
| Wood | 260 | 184 |

#### Failures

- **Gather:** inventory_full=167, empty_switch:not_harvestable=11, not_harvestable=10, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIAG | 0 | 0 | 0 | 9 | idle 84%, gather 9%, eat 4% |
| BUCE | 0 | 0 | 0 | 4 | idle 78%, gather 13%, eat 3% |
| BUJE | 0 | 0 | 42 | 175 | wander 36%, gather 32%, herd_wildnpc 17% |
| DUED | 0 | 0 | 0 | 4 | gather 82%, idle 15%, wander 2% |
| HEHU | 0 | 0 | 0 | 10 | idle 85%, gather 12%, eat 3% |
| JIIS | 0 | 0 | 0 | 3 | gather 77%, wander 21%, idle 1% |
| LIDE | 0 | 0 | 1 | 5 | idle 80%, combat 8%, gather 5% |
| MIHA | 0 | 0 | 3 | 8 | idle 78%, combat 9%, gather 5% |
| NOMO | 0 | 0 | 0 | 2 | gather 100% |
| QAAW | 0 | 0 | 0 | 1 | gather 100% |
| QALU | 0 | 0 | 0 | 9 | idle 84%, gather 9%, eat 4% |
| SIIZ | 0 | 0 | 1 | 6 | idle 78%, herd_wildnpc 14%, eat 4% |
| VOMI | 0 | 0 | 7 | 56 | idle 45%, gather 28%, herd_wildnpc 15% |
| WELE | 0 | 0 | 0 | 1 | herd_wildnpc 53%, gather 47% |
| WIOV | 0 | 0 | 2 | 21 | idle 62%, gather 26%, wander 6% |
| XEMU | 0 | 0 | 0 | 11 | idle 75%, gather 19%, eat 4% |
| YONI | 0 | 0 | 4 | 37 | idle 65%, gather 28%, eat 4% |
| ZEEC | 0 | 0 | 4 | 33 | idle 72%, gather 14%, herd_wildnpc 4% |
| ZEUP | 0 | 0 | 0 | 10 | idle 82%, gather 14%, eat 3% |

#### Hunts

- start t=314.2s prey=deer quota=2
- start t=364.3s prey=deer quota=3
- start t=489.4s prey=deer quota=4
- hunt_completed t=360.1s reason=loot_complete
- hunt_aborted t=484.3s reason=active_timeout
- hunt_completed t=574.9s reason=loot_complete

#### Buildings

- t=65.2s **Living Hut** — herder_hut (builder: BUJE)
- t=759.6s **Dairy Farm** — milestone
- t=844.6s **Farm** — milestone

### DI XUAL

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/5 (70% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 0.5 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 33 | 16 |
| Bone | 0 | 6 |
| Fiber | 12 | 6 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 2 | 2 |
| Nuts | 54 | 24 |
| Spear | 0 | 9 |
| Stone | 89 | 73 |
| Wood | 240 | 160 |

#### Failures

- **Gather:** inventory_full=71, not_harvestable=39, empty_switch:not_harvestable=15

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DEUP | 0 | 0 | 3 | 20 | idle 78%, gather 8%, craft 5% |
| DUVU | 0 | 0 | 0 | 10 | idle 89%, gather 9%, eat 2% |
| FUOJ | 0 | 0 | 3 | 20 | idle 82%, gather 10%, craft 4% |
| GOAR | 0 | 0 | 5 | 24 | idle 72%, gather 12%, combat 7% |
| JABE | 0 | 0 | 28 | 98 | gather 33%, wander 30%, herd_wildnpc 23% |
| KUAR | 0 | 0 | 0 | 8 | idle 88%, gather 9%, eat 2% |
| MIVO | 0 | 0 | 15 | 110 | gather 55%, idle 15%, wander 14% |
| QEOG | 0 | 0 | 2 | 16 | idle 80%, gather 14%, eat 3% |
| RIUC | 0 | 0 | 2 | 14 | idle 81%, gather 10%, craft 4% |
| SIQO | 0 | 0 | 0 | 5 | idle 91%, gather 6%, eat 2% |
| TEUQ | 0 | 0 | 0 | 4 | idle 46%, gather 37%, wander 14% |
| TUCE | 0 | 0 | 2 | 10 | idle 79%, gather 6%, craft 6% |
| VUUN | 0 | 0 | 9 | 60 | idle 45%, gather 25%, herd_wildnpc 13% |
| WIUG | 0 | 0 | 0 | 9 | idle 81%, gather 14%, eat 3% |
| XAHO | 0 | 0 | 0 | 9 | idle 92%, gather 6%, eat 2% |
| XUME | 0 | 0 | 0 | 13 | idle 88%, gather 9%, eat 3% |

#### Hunts

- start t=230.3s prey=deer quota=2
- start t=350.4s prey=deer quota=2
- start t=405.4s prey=deer quota=3
- hunt_aborted t=350.3s reason=active_timeout
- hunt_completed t=404.2s reason=loot_complete
- hunt_completed t=428.8s reason=loot_complete

#### Buildings

- t=60.4s **Living Hut** — herder_hut (builder: JABE)
- t=505.6s **Oven** — milestone
- t=850.8s **Farm** — milestone
- t=1091.0s **Dairy Farm** — milestone

### NA ZIQE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/1 (34% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 12 | 9 |
| Nuts | 10 | 2 |
| Spear | 0 | 1 |
| Stone | 54 | 54 |
| Wood | 54 | 54 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| QOES | 0 | 0 | 34 | 130 | wander 39%, herd_wildnpc 30%, gather 28% |

#### Buildings

- t=50.9s **Living Hut** — herder_hut (builder: QOES)
- t=423.6s **Farm** — milestone
- t=463.7s **Oven** — milestone

### YO GAXI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 5/5 (78% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 0.2 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 36 | 24 |
| Bone | 0 | 6 |
| Fiber | 33 | 27 |
| Grain | 3 | 3 |
| Hide | 0 | 8 |
| Meat | 0 | 9 |
| Mushroom | 1 | 0 |
| Nuts | 59 | 28 |
| Spear | 0 | 11 |
| Stone | 17 | 4 |
| Wood | 276 | 182 |

#### Failures

- **Gather:** inventory_full=209, empty_switch:not_harvestable=19, not_harvestable=9, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| COKE | 0 | 0 | 0 | 5 | idle 89%, eat 4%, gather 4% |
| FUEM | 0 | 0 | 4 | 31 | idle 65%, gather 11%, party 10% |
| HIPI | 0 | 0 | 5 | 37 | idle 64%, gather 17%, combat 9% |
| KEIC | 0 | 0 | 2 | 9 | idle 83%, gather 10%, eat 4% |
| KIEK | 0 | 0 | 2 | 21 | idle 77%, gather 12%, herd_wildnpc 7% |
| LAIL | 0 | 0 | 1 | 5 | idle 94%, eat 4%, gather 2% |
| MOAC | 0 | 0 | 45 | 186 | gather 33%, wander 30%, herd_wildnpc 22% |
| MUIX | 0 | 0 | 0 | 10 | idle 89%, gather 7%, eat 4% |
| NITU | 0 | 0 | 0 | 10 | idle 84%, gather 12%, eat 4% |
| PIBO | 0 | 0 | 1 | 19 | idle 77%, gather 16%, eat 4% |
| QEAN | 0 | 0 | 1 | 10 | idle 80%, combat 10%, gather 5% |
| QUEN | 0 | 0 | 0 | 10 | idle 83%, gather 12%, eat 5% |
| QUSO | 0 | 0 | 3 | 10 | idle 83%, gather 11%, eat 4% |
| XAEQ | 0 | 0 | 3 | 15 | idle 83%, gather 8%, eat 4% |
| YUAP | 0 | 0 | 4 | 38 | idle 72%, gather 18%, wander 6% |
| ZUKO | 0 | 0 | 0 | 9 | idle 88%, gather 8%, eat 5% |

#### Hunts

- start t=407.3s prey=deer quota=2
- start t=477.4s prey=deer quota=4
- start t=707.5s prey=deer quota=4
- hunt_completed t=472.9s reason=loot_complete
- hunt_completed t=515.8s reason=loot_complete
- hunt_aborted t=827.6s reason=active_timeout

#### Buildings

- t=48.6s **Living Hut** — herder_hut (builder: MOAC)
- t=277.2s **Dairy Farm** — milestone
- t=582.5s **Farm** — milestone

