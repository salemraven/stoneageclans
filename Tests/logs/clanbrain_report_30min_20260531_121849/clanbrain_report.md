# ClanBrain Report (standard)

## Session

- **Duration:** 1800.5s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_30min_20260531_121849/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 30 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| MI VAIJ | 0→7 | 1 | 0.2 | 0 | 0 | 159 | 139 | 0 | 30% | 1796.8s | 0 | 3 | — |
| NE SAZU | 0→12 | 1 | 0.3 | 0 | 0 | 285 | 286 | 0 | 41% | 1798.8s | 0 | 4 | — |
| QO QOIW | 0→12 | 1 | 0.0 | 0 | 0 | 115 | 107 | 1 | 33% | 1797.6s | 0 | 5 | — |
| TA NISO | 0→16 | 4 | 0.1 | 4 | 2 | 152 | 151 | 4 | 67% | 1091.2s | 3 | 3 | 1091.8s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 4 / 4
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| MI VAIJ | — | — | 30% | 7% | 0.0→0.2→0.2 | 1796.8s |
| NE SAZU | — | — | 41% | 20% | 0.0→0.3→0.3 | 1798.8s |
| QO QOIW | — | — | 33% | 12% | 0.0→0.0→0.0 | 1797.6s |
| TA NISO | 93% | 7% | 40% | 20% | 0.0→0.4→0.1 | 1091.2s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| MI VAIJ | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| NE SAZU | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QO QOIW | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| TA NISO | 4 | 2 | 2 | 2 | 0 | 5 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| MI VAIJ | 2 | 0 | 0 | — |
| NE SAZU | 3 | 0 | 0 | — |
| QO QOIW | 2 | 0 | 0 | — |
| TA NISO | 4 | 3 | 3 | 1089.3s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| MI VAIJ | 0 | 0 | — | 0 | 0 | wander 37%, gather 31%, herd_wildnpc 26% |
| NE SAZU | 0 | 0 | — | 0 | 0 | herd_wildnpc 33%, gather 33%, wander 26% |
| QO QOIW | 0 | 0 | — | 0 | 0 | wander 37%, herd_wildnpc 30%, gather 29% |
| TA NISO | 0 | 0 | — | 0 | 2 | idle 25%, gather 16%, party 14% |

## Economy (session)

- **Items gathered:** 711
- **Items deposited:** 683
- **Deposit yield:** 96%
- **Gather failures (all):** 9
- **Gather failures (actionable):** 5
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 4
- **empty_switch:not_harvestable:** 1
- **not_harvestable:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 77 | 58 | 75% |
| Bone | 0 | 6 | — |
| Fiber | 45 | 42 | 93% |
| Grain | 28 | 19 | 68% |
| Hide | 0 | 8 | — |
| Meat | 0 | 7 | — |
| Mushroom | 3 | 2 | 67% |
| Nuts | 77 | 70 | 91% |
| Spear | 0 | 7 | — |
| Stone | 90 | 81 | 90% |
| Wood | 391 | 383 | 98% |

## Buildings (session)

- **Total placed:** 15

### By type

- **Living Hut:** 8
- **Oven:** 3
- **Dairy Farm:** 2
- **Farm:** 2

### By source

- **herder_hut:** 8
- **milestone:** 7

### Chronological

- t=43.4s **TA NISO** — Living Hut (herder_hut) builder=KEAH @ (-941,1678)
- t=43.9s **NE SAZU** — Living Hut (herder_hut) builder=DUZE @ (1645,-785)
- t=62.4s **QO QOIW** — Living Hut (herder_hut) builder=WUZE @ (-3308,-170)
- t=96.6s **MI VAIJ** — Living Hut (herder_hut) builder=CEGI @ (-1357,-3103)
- t=153.6s **NE SAZU** — Living Hut (herder_hut) builder=DUZE @ (1689,-816)
- t=158.1s **QO QOIW** — Living Hut (herder_hut) builder=WUZE @ (-3473,-345)
- t=213.2s **MI VAIJ** — Living Hut (herder_hut) builder=CEGI @ (-1514,-3248)
- t=255.9s **TA NISO** — Dairy Farm (milestone) @ (-773,1832)
- t=409.0s **NE SAZU** — Living Hut (herder_hut) builder=DUZE @ (1545,-1002)
- t=457.2s **NE SAZU** — Farm (milestone) @ (1493,-949)
- t=523.5s **QO QOIW** — Dairy Farm (milestone) @ (-3277,-222)
- t=654.3s **MI VAIJ** — Oven (milestone) @ (-1569,-3207)
- t=713.7s **QO QOIW** — Farm (milestone) @ (-3512,-263)
- t=916.6s **TA NISO** — Oven (milestone) @ (-872,1615)
- t=974.0s **QO QOIW** — Oven (milestone) @ (-3266,-114)

## Per-clan detail

### MI VAIJ

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/1 (30% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.2 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 26 | 11 |
| Grain | 5 | 2 |
| Nuts | 13 | 10 |
| Spear | 0 | 1 |
| Stone | 30 | 30 |
| Wood | 85 | 85 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CEGI | 0 | 0 | 36 | 159 | wander 37%, gather 31%, herd_wildnpc 26% |

#### Buildings

- t=96.6s **Living Hut** — herder_hut (builder: CEGI)
- t=213.2s **Living Hut** — herder_hut (builder: CEGI)
- t=654.3s **Oven** — milestone

### NE SAZU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (41% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.3 → 0.3

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 24 | 24 |
| Grain | 8 | 8 |
| Nuts | 45 | 45 |
| Spear | 0 | 1 |
| Stone | 9 | 9 |
| Wood | 199 | 199 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DUZE | 0 | 0 | 94 | 285 | herd_wildnpc 33%, gather 33%, wander 26% |

#### Buildings

- t=43.9s **Living Hut** — herder_hut (builder: DUZE)
- t=153.6s **Living Hut** — herder_hut (builder: DUZE)
- t=409.0s **Living Hut** — herder_hut (builder: DUZE)
- t=457.2s **Farm** — milestone

### QO QOIW

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/1 (33% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 3 |
| Mushroom | 1 | 0 |
| Nuts | 15 | 11 |
| Spear | 0 | 1 |
| Stone | 27 | 24 |
| Wood | 69 | 68 |

#### Failures

- **Gather:** resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| WUZE | 0 | 0 | 27 | 115 | wander 37%, herd_wildnpc 30%, gather 29% |

#### Buildings

- t=62.4s **Living Hut** — herder_hut (builder: WUZE)
- t=158.1s **Living Hut** — herder_hut (builder: WUZE)
- t=523.5s **Dairy Farm** — milestone
- t=713.7s **Farm** — milestone
- t=974.0s **Oven** — milestone

### TA NISO

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (93% fill) | searchers 1/2 (40% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 0.4 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 51 | 47 |
| Bone | 0 | 6 |
| Fiber | 18 | 15 |
| Grain | 15 | 9 |
| Hide | 0 | 8 |
| Meat | 0 | 7 |
| Mushroom | 2 | 2 |
| Nuts | 4 | 4 |
| Spear | 0 | 4 |
| Stone | 24 | 18 |
| Wood | 38 | 31 |

#### Failures

- **Gather:** inventory_full=3, resource_invalid=3, empty_switch:not_harvestable=1, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GUGA | 0 | 0 | 3 | 8 | idle 46%, party 28%, gather 11% |
| KEAH | 0 | 0 | 31 | 127 | wander 30%, gather 23%, herd_wildnpc 23% |
| SOZI | 0 | 0 | 4 | 10 | idle 46%, party 22%, craft 17% |
| YUUN | 0 | 0 | 3 | 7 | idle 46%, party 22%, combat 11% |

#### Hunts

- start t=1091.8s prey=deer quota=3
- start t=1211.9s prey=deer quota=4
- start t=1332.0s prey=deer quota=4
- start t=1357.0s prey=deer quota=4
- hunt_aborted t=1211.8s reason=active_timeout
- hunt_aborted t=1331.9s reason=active_timeout
- hunt_completed t=1354.5s reason=loot_complete
- hunt_completed t=1392.1s reason=loot_complete

#### Buildings

- t=43.4s **Living Hut** — herder_hut (builder: KEAH)
- t=255.9s **Dairy Farm** — milestone
- t=916.6s **Oven** — milestone

