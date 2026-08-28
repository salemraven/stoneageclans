# ClanBrain Report (standard)

## Session

- **Duration:** 600.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_10min_20260529_201350/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 10 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| CE FOWU | 0→28 | 14 | 0.0 | 2 | 2 | 139 | 108 | 10 | 60% | 305.2s | 13 | 3 | 443.5s |
| CE WEEQ | 0→15 | 13 | 0.0 | 2 | 2 | 170 | 101 | 4 | 62% | 195.2s | 12 | 3 | 215.8s |
| JO NAEL | 0→6 | 3 | 0.3 | 3 | 1 | 32 | 34 | 1 | 20% | 270.2s | 2 | 1 | 274.8s |
| ZA WIAL | 0→10 | 1 | 0.0 | 0 | 0 | 14 | 14 | 0 | 86% | 600.2s | 0 | 2 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 7 / 6
- **⚠ Possible stuck parties (formed − disbanded):** 1

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| CE FOWU | — | — | 60% | 33% | 0.0→0.1→0.0 | 305.2s |
| CE WEEQ | — | — | 62% | 17% | 0.0→0.6→0.0 | 195.2s |
| JO NAEL | — | — | 20% | 17% | 0.0→0.5→0.3 | 270.2s |
| ZA WIAL | — | — | 86% | 10% | 0.0→0.0→0.0 | 600.2s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| CE FOWU | 2 | 2 | 0 | 0 | 0 | 5 | 0 |
| CE WEEQ | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| JO NAEL | 3 | 1 | 1 | 0 | 0 | 1 | 0 |
| ZA WIAL | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| CE FOWU | 6 | 13 | 13 | 307.0s |
| CE WEEQ | 2 | 12 | 12 | 193.3s |
| JO NAEL | 1 | 2 | 2 | 270.6s |
| ZA WIAL | 1 | 0 | 0 | — |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| CE FOWU | 0 | 0 | — | 0 | 6 | gather 40%, herd_wildnpc 27%, wander 8% |
| CE WEEQ | 0 | 0 | — | 0 | 4 | idle 41%, gather 39%, wander 7% |
| JO NAEL | 0 | 0 | — | 0 | 0 | combat 42%, gather 29%, wander 12% |
| ZA WIAL | 0 | 0 | — | 0 | 0 | herd_wildnpc 82%, wander 14%, gather 3% |

## Economy (session)

- **Items gathered:** 355
- **Items deposited:** 257
- **Deposit yield:** 72%
- **Gather failures (all):** 132
- **Gather failures (actionable):** 15
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 10
- **not_harvestable:** 9
- **resource_invalid:** 6

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 27 | 17 | 63% |
| Bone | 0 | 11 | — |
| Fiber | 17 | 6 | 35% |
| Grain | 24 | 10 | 42% |
| Hide | 0 | 17 | — |
| Meat | 0 | 22 | — |
| Mushroom | 4 | 0 | 0% |
| Nuts | 38 | 18 | 47% |
| Spear | 0 | 23 | — |
| Stone | 31 | 20 | 65% |
| Wood | 214 | 113 | 53% |

## Buildings (session)

- **Total placed:** 9

### By type

- **Living Hut:** 4
- **Dairy Farm:** 2
- **Farm:** 2
- **Oven:** 1

### By source

- **milestone:** 5
- **herder_hut:** 4

### Chronological

- t=36.2s **CE FOWU** — Living Hut (herder_hut) builder=NORA @ (-1937,-915)
- t=45.9s **CE WEEQ** — Living Hut (herder_hut) builder=RUCU @ (-742,-1777)
- t=52.6s **JO NAEL** — Living Hut (herder_hut) builder=FUAY @ (376,2186)
- t=183.4s **CE FOWU** — Dairy Farm (milestone) @ (-2159,-1005)
- t=230.5s **ZA WIAL** — Farm (milestone) @ (1978,222)
- t=395.6s **ZA WIAL** — Dairy Farm (milestone) @ (1931,293)
- t=400.9s **CE WEEQ** — Living Hut (herder_hut) builder=NADU @ (-714,-1836)
- t=416.0s **CE WEEQ** — Oven (milestone) @ (-876,-1968)
- t=538.6s **CE FOWU** — Farm (milestone) @ (-2118,-1058)

## Per-clan detail

### CE FOWU

- **Brain:** AGGRESSIVE | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/4 (60% fill)
- **Pressure:** defend 0.18 | search 0.26 | gather 0.56
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Bone | 0 | 5 |
| Fiber | 9 | 6 |
| Grain | 13 | 8 |
| Hide | 0 | 7 |
| Meat | 0 | 7 |
| Mushroom | 3 | 0 |
| Nuts | 12 | 6 |
| Spear | 0 | 10 |
| Stone | 17 | 6 |
| Wood | 82 | 53 |

#### Failures

- **Gather:** not_harvestable=7, resource_invalid=3, empty_switch:not_harvestable=2, inventory_full=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FAET | 0 | 0 | 1 | 5 | gather 53%, herd_wildnpc 35%, wander 8% |
| FAWE | 0 | 0 | 1 | 9 | gather 54%, idle 33%, party 8% |
| FOZA | 0 | 0 | 1 | 4 | herd_wildnpc 47%, gather 45%, wander 4% |
| HAEC | 0 | 0 | 0 | 9 | gather 51%, wander 17%, build_hut_for_woman 17% |
| HEOV | 0 | 0 | 2 | 10 | gather 54%, idle 33%, party 4% |
| HUUN | 0 | 0 | 3 | 14 | gather 54%, herd_wildnpc 20%, build_hut_for_woman 7% |
| JUAF | 0 | 0 | 2 | 5 | herd_wildnpc 41%, gather 27%, build_hut_for_woman 15% |
| NORA | 0 | 0 | 14 | 48 | herd_wildnpc 30%, agro 22%, wander 21% |
| QAET | 0 | 0 | 1 | 1 | herd_wildnpc 75%, gather 15%, hunt 4% |
| SAQO | 0 | 0 | 4 | 18 | gather 53%, herd_wildnpc 30%, build_hut_for_woman 7% |
| TILU | 0 | 0 | 0 | 3 | herd_wildnpc 77%, gather 21%, eat 2% |
| WAYU | 0 | 0 | 0 | 0 | idle 70%, gather 16%, hunt 5% |
| WIIQ | 0 | 0 | 0 | 3 | gather 68%, combat 27%, wander 4% |
| ZASE | 0 | 0 | 1 | 10 | gather 91%, herd_wildnpc 5%, eat 2% |

#### Hunts

- start t=443.5s prey=deer quota=4
- start t=463.5s prey=deer quota=4
- hunt_completed t=462.3s reason=loot_complete
- hunt_completed t=483.5s reason=loot_complete

#### Buildings

- t=36.2s **Living Hut** — herder_hut (builder: NORA)
- t=183.4s **Dairy Farm** — milestone
- t=538.6s **Farm** — milestone

### CE WEEQ

- **Brain:** AGGRESSIVE | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (62% fill)
- **Pressure:** defend 0.18 | search 0.27 | gather 0.55
- **Food days buffer:** 0.0 → 0.6 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 5 |
| Bone | 0 | 3 |
| Fiber | 8 | 0 |
| Grain | 9 | 2 |
| Hide | 0 | 6 |
| Meat | 0 | 10 |
| Mushroom | 1 | 0 |
| Nuts | 23 | 10 |
| Spear | 0 | 10 |
| Stone | 10 | 10 |
| Wood | 113 | 45 |

#### Failures

- **Gather:** inventory_full=40, empty_switch:not_harvestable=8, not_harvestable=2, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BELU | 0 | 0 | 0 | 0 | combat 84%, gather 16% |
| FADA | 0 | 0 | 1 | 9 | idle 58%, gather 24%, wander 8% |
| FIVU | 0 | 0 | 2 | 10 | idle 63%, gather 24%, combat 4% |
| FOUG | 0 | 0 | 1 | 10 | idle 55%, gather 37%, herd_wildnpc 5% |
| GORU | 0 | 0 | 3 | 11 | idle 54%, gather 32%, combat 6% |
| JIIR | 0 | 0 | 1 | 13 | gather 76%, idle 19%, eat 5% |
| MUVA | 0 | 0 | 1 | 10 | idle 54%, gather 43%, eat 3% |
| NADU | 0 | 0 | 1 | 14 | gather 44%, idle 25%, herd_wildnpc 10% |
| NAOY | 0 | 0 | 0 | 10 | gather 77%, idle 19%, eat 3% |
| PAIF | 0 | 0 | 1 | 1 | idle 83%, gather 10%, wander 3% |
| PAWA | 0 | 0 | 1 | 10 | gather 55%, idle 35%, wander 6% |
| PIAS | 0 | 0 | 0 | 9 | idle 52%, gather 45%, eat 3% |
| RUCU | 0 | 0 | 15 | 63 | gather 52%, wander 27%, herd_wildnpc 8% |

#### Hunts

- start t=215.8s prey=deer quota=2
- start t=265.9s prey=deer quota=3
- hunt_completed t=264.1s reason=loot_complete
- hunt_completed t=312.2s reason=loot_complete

#### Buildings

- t=45.9s **Living Hut** — herder_hut (builder: RUCU)
- t=400.9s **Living Hut** — herder_hut (builder: NADU)
- t=416.0s **Oven** — milestone

### JO NAEL

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 0.5 → 0.3

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 18 | 12 |
| Bone | 0 | 3 |
| Grain | 2 | 0 |
| Hide | 0 | 4 |
| Meat | 0 | 5 |
| Nuts | 1 | 0 |
| Spear | 0 | 2 |
| Stone | 1 | 1 |
| Wood | 10 | 7 |

#### Failures

- **Gather:** inventory_full=66, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DOEH | 0 | 0 | 4 | 3 | combat 62%, gather 22%, hunt 13% |
| DUZO | 0 | 0 | 0 | 9 | gather 91%, wander 4%, eat 4% |
| FUAY | 0 | 0 | 5 | 20 | combat 35%, gather 26%, wander 18% |

#### Hunts

- start t=274.8s prey=deer quota=2
- start t=394.9s prey=deer quota=2
- start t=504.9s prey=deer quota=2
- hunt_aborted t=394.8s reason=active_timeout
- hunt_completed t=500.4s reason=loot_complete

#### Buildings

- t=52.6s **Living Hut** — herder_hut (builder: FUAY)

### ZA WIAL

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (86% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Nuts | 2 | 2 |
| Spear | 0 | 1 |
| Stone | 3 | 3 |
| Wood | 9 | 8 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| VUIL | 0 | 0 | 5 | 14 | herd_wildnpc 82%, wander 14%, gather 3% |

#### Buildings

- t=230.5s **Farm** — milestone
- t=395.6s **Dairy Farm** — milestone

