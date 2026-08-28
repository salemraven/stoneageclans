# ClanBrain Report (standard)

## Session

- **Duration:** 300.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_20260528_215200/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| BO MIOR | 0→8 | 6 | 0.0 | 0 | 0 | 53 | 32 | 2 | 28% | 105.1s | 5 | 2 | — |
| DO PEXU | 0→1 | 1 | 0.0 | 0 | 0 | 0 | 1 | 0 | 92% | 299.1s | 0 | 0 | — |
| YE CEJU | 0→17 | 10 | 0.0 | 0 | 0 | 88 | 67 | 4 | 48% | 80.1s | 9 | 2 | — |
| YU CIAB | 0→18 | 13 | 0.0 | 1 | 1 | 64 | 16 | 2 | 66% | 65.1s | 12 | 3 | 70.0s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 1 / 1
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| BO MIOR | — | — | 28% | 14% | 0.0→0.3→0.0 | 105.1s |
| DO PEXU | — | — | 92% | 8% | 0.0→0.0→0.0 | 299.1s |
| YE CEJU | — | — | 48% | 20% | 0.0→0.3→0.0 | 80.1s |
| YU CIAB | — | — | 66% | 33% | 0.0→0.3→0.0 | 65.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| BO MIOR | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| DO PEXU | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| YE CEJU | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| YU CIAB | 1 | 1 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| BO MIOR | 1 | 6 | 5 | 109.3s |
| DO PEXU | 0 | 0 | 0 | — |
| YE CEJU | 1 | 10 | 9 | 78.8s |
| YU CIAB | 3 | 12 | 12 | 69.1s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| BO MIOR | 0 | 0 | — | 0 | 1 | gather 39%, idle 27%, wander 14% |
| DO PEXU | 0 | 0 | — | 0 | 0 | wander 72%, herd_wildnpc 16%, combat 7% |
| YE CEJU | 0 | 0 | — | 0 | 0 | herd_wildnpc 38%, gather 24%, idle 18% |
| YU CIAB | 0 | 0 | — | 0 | 2 | gather 65%, herd_wildnpc 7%, build_hut_for_woman 5% |

## Economy (session)

- **Items gathered:** 205
- **Items deposited:** 116
- **Deposit yield:** 57%
- **Gather failures (all):** 403
- **Gather failures (actionable):** 8
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 7
- **not_harvestable:** 5
- **resource_invalid:** 3

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 18 | 6 | 33% |
| Bone | 0 | 1 | — |
| Fiber | 7 | 6 | 86% |
| Grain | 24 | 7 | 29% |
| Hide | 0 | 4 | — |
| Meat | 0 | 3 | — |
| Mushroom | 1 | 0 | 0% |
| Nuts | 23 | 8 | 35% |
| Spear | 0 | 15 | — |
| Stone | 19 | 13 | 68% |
| Wood | 113 | 53 | 47% |

## Buildings (session)

- **Total placed:** 7

### By type

- **Living Hut:** 5
- **Dairy Farm:** 1
- **Oven:** 1

### By source

- **herder_hut:** 5
- **milestone:** 2

### Chronological

- t=36.6s **YU CIAB** — Living Hut (herder_hut) builder=WIHO @ (-136,-1850)
- t=46.3s **YE CEJU** — Living Hut (herder_hut) builder=HIXO @ (2988,-971)
- t=76.8s **BO MIOR** — Living Hut (herder_hut) builder=YOXU @ (-531,2602)
- t=104.0s **YU CIAB** — Living Hut (herder_hut) builder=WIHO @ (-158,-1786)
- t=177.0s **YE CEJU** — Dairy Farm (milestone) @ (2761,-1035)
- t=221.6s **YU CIAB** — Living Hut (herder_hut) builder=WIHO @ (-198,-1751)
- t=270.3s **BO MIOR** — Oven (milestone) @ (-328,2695)

## Per-clan detail

### BO MIOR

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/4 (28% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 6 |
| Fiber | 6 | 6 |
| Grain | 6 | 0 |
| Nuts | 3 | 0 |
| Spear | 0 | 3 |
| Stone | 11 | 11 |
| Wood | 18 | 6 |

#### Failures

- **Gather:** inventory_full=38, not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEYU | 0 | 0 | 3 | 17 | gather 44%, idle 40%, wander 7% |
| JUSI | 0 | 0 | 1 | 2 | gather 53%, wander 24%, herd_wildnpc 23% |
| MOLU | 0 | 0 | 0 | 0 | gather 91%, herd_wildnpc 9% |
| XEQE | 0 | 0 | 0 | 10 | gather 41%, idle 32%, combat 16% |
| XUIF | 0 | 0 | 0 | 4 | idle 78%, gather 17%, eat 5% |
| YOXU | 0 | 0 | 7 | 20 | gather 37%, wander 31%, herd_wildnpc 15% |

#### Buildings

- t=76.8s **Living Hut** — herder_hut (builder: YOXU)
- t=270.3s **Oven** — milestone

### DO PEXU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (92% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| NIAN | 0 | 0 | 1 | 0 | wander 72%, herd_wildnpc 16%, combat 7% |

### YE CEJU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/6 (48% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Grain | 9 | 7 |
| Nuts | 11 | 6 |
| Spear | 0 | 6 |
| Stone | 7 | 2 |
| Wood | 61 | 46 |

#### Failures

- **Gather:** not_harvestable=4, empty_switch:not_harvestable=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| COOX | 0 | 0 | 1 | 7 | gather 37%, idle 31%, wander 21% |
| HEEJ | 0 | 0 | 4 | 25 | gather 31%, herd_wildnpc 29%, idle 18% |
| HIIB | 0 | 0 | 0 | 0 | herd_wildnpc 58%, wander 21%, gather 20% |
| HIXO | 0 | 0 | 11 | 34 | wander 39%, gather 32%, herd_wildnpc 18% |
| JAAS | 0 | 0 | 1 | 4 | herd_wildnpc 68%, gather 23%, wander 9% |
| KUDE | 0 | 0 | 0 | 4 | idle 87%, gather 8%, eat 4% |
| MIAK | 0 | 0 | 2 | 5 | herd_wildnpc 76%, gather 17%, wander 7% |
| PAUK | 0 | 0 | 0 | 0 | gather 100% |
| TARO | 0 | 0 | 1 | 4 | herd_wildnpc 80%, gather 12%, wander 8% |
| ZIAW | 0 | 0 | 0 | 5 | herd_wildnpc 67%, gather 26%, wander 3% |

#### Buildings

- t=46.3s **Living Hut** — herder_hut (builder: HIXO)
- t=177.0s **Dairy Farm** — milestone

### YU CIAB

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/4 (66% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 0 |
| Bone | 0 | 1 |
| Fiber | 1 | 0 |
| Grain | 9 | 0 |
| Hide | 0 | 4 |
| Meat | 0 | 3 |
| Mushroom | 1 | 0 |
| Nuts | 9 | 2 |
| Spear | 0 | 5 |
| Stone | 1 | 0 |
| Wood | 34 | 1 |

#### Failures

- **Gather:** inventory_full=350, empty_switch:not_harvestable=5, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FIZI | 0 | 0 | 3 | 4 | gather 51%, party 29%, combat 17% |
| GAEL | 0 | 0 | 0 | 0 | gather 100% |
| JEHU | 0 | 0 | 0 | 2 | gather 100% |
| JUPI | 0 | 0 | 1 | 10 | gather 100% |
| KENO | 0 | 0 | 0 | 9 | gather 83%, wander 17%, idle 1% |
| QIUF | 0 | 0 | 1 | 7 | gather 100% |
| SOUK | 0 | 0 | 0 | 9 | gather 96%, eat 4%, hunt 0% |
| TOQA | 0 | 0 | 0 | 9 | gather 84%, idle 13%, eat 3% |
| WIHO | 0 | 0 | 4 | 5 | build_hut_for_woman 24%, gather 23%, hunt 20% |
| WUES | 0 | 0 | 1 | 0 | herd_wildnpc 64%, gather 26%, wander 9% |
| XIFO | 0 | 0 | 0 | 0 | gather 64%, wander 33%, idle 2% |
| YUUY | 0 | 0 | 0 | 9 | gather 95%, hunt 3%, eat 2% |

#### Hunts

- start t=70.0s prey=deer quota=2
- hunt_completed t=244.3s reason=loot_complete

#### Buildings

- t=36.6s **Living Hut** — herder_hut (builder: WIHO)
- t=104.0s **Living Hut** — herder_hut (builder: WIHO)
- t=221.6s **Living Hut** — herder_hut (builder: WIHO)

