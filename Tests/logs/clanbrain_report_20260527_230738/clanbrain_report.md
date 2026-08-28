# ClanBrain Report (standard)

## Session

- **Duration:** 300.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_20260527_230738/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| JE YAAN | 0→14 | 9 | 0.5 | 1 | 0 | 64 | 52 | 3 | 62% | 85.1s | 8 | 2 | 246.4s |
| KA RUOV | 0→6 | 4 | 0.5 | 0 | 0 | 47 | 30 | 2 | 66% | 165.2s | 3 | 1 | — |
| RI MEPE | 0→4 | 3 | 0.6 | 1 | 0 | 31 | 24 | 0 | 22% | 75.1s | 2 | 1 | 76.1s |
| WA LOUD | 0→20 | 10 | 0.1 | 0 | 0 | 85 | 46 | 1 | 68% | 75.1s | 9 | 3 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 2 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 2

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| JE YAAN | — | — | 62% | 17% | 0.0→0.6→0.5 | 85.1s |
| KA RUOV | — | — | 66% | 5% | 0.0→0.6→0.5 | 165.2s |
| RI MEPE | — | — | 22% | 25% | 0.0→0.6→0.6 | 75.1s |
| WA LOUD | — | — | 68% | 25% | 0.0→0.1→0.1 | 75.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| JE YAAN | 1 | 0 | 0 | 0 | 0 | 2 | 0 |
| KA RUOV | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| RI MEPE | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| WA LOUD | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| JE YAAN | 2 | 10 | 8 | 83.6s |
| KA RUOV | 1 | 4 | 3 | 165.2s |
| RI MEPE | 1 | 2 | 2 | 72.0s |
| WA LOUD | 1 | 10 | 9 | 73.5s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| JE YAAN | 0 | 0 | — | 0 | 3 | gather 57%, herd_wildnpc 19%, wander 12% |
| KA RUOV | 0 | 0 | — | 0 | 2 | gather 61%, wander 22%, herd_wildnpc 11% |
| RI MEPE | 0 | 0 | — | 0 | 3 | combat 34%, gather 30%, hunt 22% |
| WA LOUD | 0 | 0 | — | 0 | 5 | herd_wildnpc 48%, gather 34%, wander 14% |

## Economy (session)

- **Items gathered:** 227
- **Items deposited:** 152
- **Deposit yield:** 67%
- **Gather failures (all):** 262
- **Gather failures (actionable):** 6
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 5
- **empty_switch:not_harvestable:** 3
- **not_harvestable:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 21 | 9 | 43% |
| Bone | 0 | 3 | — |
| Fiber | 24 | 15 | 62% |
| Grain | 9 | 3 | 33% |
| Hide | 0 | 4 | — |
| Meat | 0 | 3 | — |
| Mushroom | 4 | 1 | 25% |
| Nuts | 31 | 13 | 42% |
| Spear | 0 | 21 | — |
| Stone | 8 | 4 | 50% |
| Wood | 130 | 76 | 58% |

## Buildings (session)

- **Total placed:** 7

### By type

- **Living Hut:** 5
- **Dairy Farm:** 1
- **Farm:** 1

### By source

- **herder_hut:** 5
- **milestone:** 2

### Chronological

- t=39.5s **RI MEPE** — Living Hut (herder_hut) builder=COEC @ (2113,-27)
- t=41.0s **WA LOUD** — Living Hut (herder_hut) builder=LILI @ (-1747,239)
- t=51.1s **JE YAAN** — Living Hut (herder_hut) builder=NAWU @ (-193,-3173)
- t=132.7s **KA RUOV** — Living Hut (herder_hut) builder=KUIG @ (-457,3468)
- t=152.2s **WA LOUD** — Farm (milestone) @ (-1672,139)
- t=245.1s **JE YAAN** — Living Hut (herder_hut) builder=NAWU @ (-29,-3004)
- t=257.3s **WA LOUD** — Dairy Farm (milestone) @ (-1910,108)

## Per-clan detail

### JE YAAN

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/0 (62% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.6 → 0.5

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 6 |
| Bone | 0 | 3 |
| Fiber | 12 | 9 |
| Grain | 6 | 3 |
| Hide | 0 | 4 |
| Meat | 0 | 3 |
| Mushroom | 2 | 0 |
| Nuts | 7 | 3 |
| Spear | 0 | 9 |
| Stone | 3 | 1 |
| Wood | 25 | 11 |

#### Failures

- **Gather:** inventory_full=32, resource_invalid=3, empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FURE | 0 | 0 | 1 | 0 | gather 96%, hunt 4% |
| HEIY | 0 | 0 | 1 | 0 | gather 98%, hunt 2% |
| NAWU | 0 | 0 | 8 | 14 | gather 43%, wander 20%, build_hut_for_woman 17% |
| NUMO | 0 | 0 | 1 | 10 | gather 96%, hunt 2%, wander 1% |
| REAH | 0 | 0 | 1 | 18 | gather 70%, wander 12%, idle 11% |
| SAUF | 0 | 0 | 2 | 6 | gather 88%, wander 10%, hunt 2% |
| VAIS | 0 | 0 | 3 | 5 | herd_wildnpc 55%, gather 26%, wander 10% |
| YEIV | 0 | 0 | 1 | 1 | gather 57%, wander 41%, idle 2% |
| ZABE | 0 | 0 | 1 | 10 | herd_wildnpc 56%, gather 30%, party 7% |

#### Hunts

- start t=246.4s prey=deer quota=4

#### Buildings

- t=51.1s **Living Hut** — herder_hut (builder: NAWU)
- t=245.1s **Living Hut** — herder_hut (builder: NAWU)

### KA RUOV

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (66% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.6 → 0.5

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Mushroom | 2 | 1 |
| Nuts | 10 | 5 |
| Spear | 0 | 3 |
| Stone | 3 | 3 |
| Wood | 29 | 18 |

#### Failures

- **Gather:** inventory_full=18, empty_switch:not_harvestable=1, not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| HOFI | 0 | 0 | 2 | 19 | gather 88%, wander 12% |
| KUIG | 0 | 0 | 5 | 11 | gather 38%, wander 29%, herd_wildnpc 21% |
| MUEY | 0 | 0 | 1 | 13 | gather 77%, wander 23%, idle 0% |
| VASA | 0 | 0 | 0 | 4 | gather 100% |

#### Buildings

- t=132.7s **Living Hut** — herder_hut (builder: KUIG)

### RI MEPE

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (22% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.6 → 0.6

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 3 |
| Nuts | 6 | 2 |
| Spear | 0 | 3 |
| Wood | 22 | 16 |

#### Failures

- **Gather:** inventory_full=87

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEKU | 0 | 0 | 1 | 0 | combat 86%, party 8%, gather 4% |
| COEC | 0 | 0 | 3 | 3 | hunt 53%, combat 19%, gather 10% |
| VODA | 0 | 0 | 3 | 28 | gather 85%, wander 14%, hunt 0% |

#### Hunts

- start t=76.1s prey=deer quota=2

#### Buildings

- t=39.5s **Living Hut** — herder_hut (builder: COEC)

### WA LOUD

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 7/7 (68% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 0 |
| Fiber | 12 | 6 |
| Grain | 3 | 0 |
| Nuts | 8 | 3 |
| Spear | 0 | 6 |
| Stone | 2 | 0 |
| Wood | 54 | 31 |

#### Failures

- **Gather:** inventory_full=116, empty_switch:not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIIH | 0 | 0 | 0 | 0 | herd_wildnpc 99%, gather 1%, wander 0% |
| HIBE | 0 | 0 | 1 | 10 | gather 69%, wander 31%, idle 0% |
| KUUG | 0 | 0 | 1 | 18 | gather 92%, wander 8% |
| LIEG | 0 | 0 | 1 | 7 | herd_wildnpc 85%, wander 10%, gather 4% |
| LILI | 0 | 0 | 12 | 29 | gather 45%, wander 42%, build_hut_for_woman 7% |
| MUIQ | 0 | 0 | 0 | 9 | gather 60%, idle 39%, wander 0% |
| NAOK | 0 | 0 | 0 | 0 | herd_wildnpc 86%, gather 14% |
| POAS | 0 | 0 | 1 | 0 | gather 100% |
| VIVE | 0 | 0 | 1 | 3 | herd_wildnpc 88%, gather 12%, wander 0% |
| XOZO | 0 | 0 | 0 | 9 | herd_wildnpc 63%, gather 33%, wander 4% |

#### Buildings

- t=41.0s **Living Hut** — herder_hut (builder: LILI)
- t=152.2s **Farm** — milestone
- t=257.3s **Dairy Farm** — milestone

