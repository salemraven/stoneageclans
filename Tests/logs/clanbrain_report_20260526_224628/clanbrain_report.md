# ClanBrain Report (standard)

## Session

- **Duration:** 91.9s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_20260526_224628/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| HI COUX | 0→15 | 11 | 0.1 | 0 | 0 | 51 | 18 | 4 | 65% | 20.0s | 10 | 2 | — |
| HO ZEUW | 0→15 | 9 | 0.0 | 0 | 0 | 36 | 10 | 3 | 68% | 25.0s | 8 | 3 | — |
| PA MOJA | 0→14 | 9 | 0.0 | 1 | 0 | 31 | 11 | 1 | 44% | 20.0s | 8 | 2 | 39.5s |
| QE MAJA | 0→9 | 7 | 0.0 | 1 | 0 | 38 | 6 | 0 | 20% | 20.0s | 6 | 2 | 24.0s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 2 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 2

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| HI COUX | — | — | 65% | — | 0.0→0.1→0.1 | 20.0s |
| HO ZEUW | — | — | 68% | — | 0.0→0.0→0.0 | 25.0s |
| PA MOJA | — | — | 44% | — | 0.0→0.0→0.0 | 20.0s |
| QE MAJA | — | — | 20% | — | 0.0→0.0→0.0 | 20.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| HI COUX | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| HO ZEUW | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| PA MOJA | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE MAJA | 1 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| HI COUX | 2 | 10 | 10 | 22.4s |
| HO ZEUW | 2 | 8 | 8 | 22.4s |
| PA MOJA | 0 | 10 | 8 | 22.3s |
| QE MAJA | 0 | 6 | 6 | 22.4s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| HI COUX | 0 | 0 | — | 0 | 0 | gather 65%, herd_wildnpc 21%, wander 9% |
| HO ZEUW | 0 | 0 | — | 0 | 0 | gather 50%, herd_wildnpc 30%, wander 13% |
| PA MOJA | 0 | 0 | — | 0 | 0 | gather 38%, party 33%, hunt 11% |
| QE MAJA | 0 | 0 | — | 0 | 0 | gather 49%, party 32%, hunt 16% |

## Economy (session)

- **Items gathered:** 156
- **Items deposited:** 45
- **Deposit yield:** 29%
- **Gather failures (all):** 72
- **Gather failures (actionable):** 8
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 5
- **not_harvestable:** 4
- **resource_invalid:** 4

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 3 | 0 | 0% |
| Fiber | 8 | 4 | 50% |
| Grain | 6 | 0 | 0% |
| Mushroom | 5 | 0 | 0% |
| Nuts | 19 | 3 | 16% |
| Spear | 0 | 14 | — |
| Stone | 21 | 0 | 0% |
| Wood | 94 | 24 | 26% |

## Buildings (session)

- **Total placed:** 9

### By type

- **Living Hut:** 9

### By source

- **herder_hut:** 9

### Chronological

- t=0.3s **PA MOJA** — Living Hut (herder_hut) builder=KUAS @ (2657,1159)
- t=0.3s **PA MOJA** — Living Hut (herder_hut) builder=KUAS @ (2680,1089)
- t=0.3s **HO ZEUW** — Living Hut (herder_hut) builder=HUTU @ (562,1893)
- t=0.4s **HO ZEUW** — Living Hut (herder_hut) builder=HUTU @ (397,1748)
- t=0.4s **QE MAJA** — Living Hut (herder_hut) builder=GIEG @ (-3275,-292)
- t=0.4s **QE MAJA** — Living Hut (herder_hut) builder=GIEG @ (-3328,-219)
- t=0.5s **HI COUX** — Living Hut (herder_hut) builder=YAXI @ (718,-1701)
- t=0.5s **HI COUX** — Living Hut (herder_hut) builder=YAXI @ (756,-1763)
- t=91.2s **HO ZEUW** — Living Hut (herder_hut) builder=COUF @ (340,1803)

## Per-clan detail

### HI COUX

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (65% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 1 |
| Grain | 3 | 0 |
| Mushroom | 3 | 0 |
| Nuts | 8 | 3 |
| Spear | 0 | 4 |
| Stone | 7 | 0 |
| Wood | 27 | 10 |

#### Failures

- **Gather:** inventory_full=18, empty_switch:not_harvestable=3, not_harvestable=2, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CENI | 0 | 0 | 1 | 4 | gather 91%, herd_wildnpc 9% |
| CESA | 0 | 0 | 0 | 3 | gather 100% |
| DIUQ | 0 | 0 | 2 | 12 | gather 43%, herd_wildnpc 39%, wander 18% |
| GIUM | 0 | 0 | 0 | 0 | herd_wildnpc 74%, gather 17%, build_hut_for_woman 9% |
| HIZO | 0 | 0 | 0 | 0 | gather 90%, idle 10% |
| MIXO | 0 | 0 | 1 | 10 | gather 100% |
| MOAW | 0 | 0 | 0 | 2 | herd_wildnpc 66%, build_hut_for_woman 29%, gather 4% |
| PUTU | 0 | 0 | 0 | 0 | gather 79%, herd_wildnpc 21% |
| QOOD | 0 | 0 | 0 | 0 | gather 100% |
| SUUZ | 0 | 0 | 0 | 9 | gather 100% |
| YAXI | 0 | 0 | 5 | 11 | gather 64%, wander 36% |

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: YAXI)
- t=0.5s **Living Hut** — herder_hut (builder: YAXI)

### HO ZEUW

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (68% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Fiber | 5 | 3 |
| Mushroom | 2 | 0 |
| Nuts | 1 | 0 |
| Spear | 0 | 2 |
| Stone | 5 | 0 |
| Wood | 20 | 5 |

#### Failures

- **Gather:** inventory_full=22, resource_invalid=2, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BOTI | 0 | 0 | 0 | 9 | gather 100% |
| CEZE | 0 | 0 | 0 | 0 | herd_wildnpc 85%, build_hut_for_woman 15% |
| COUF | 0 | 0 | 0 | 0 | herd_wildnpc 62%, build_hut_for_woman 30%, gather 8% |
| GEAB | 0 | 0 | 1 | 3 | gather 100% |
| HUTU | 0 | 0 | 4 | 12 | gather 61%, wander 38%, herd_wildnpc 0% |
| JOUL | 0 | 0 | 0 | 6 | gather 64%, wander 35%, idle 1% |
| KUMI | 0 | 0 | 0 | 2 | herd_wildnpc 54%, gather 45%, wander 1% |
| WOAR | 0 | 0 | 0 | 1 | gather 77%, wander 20%, idle 2% |
| ZUIW | 0 | 0 | 0 | 3 | gather 68%, herd_wildnpc 32% |

#### Buildings

- t=0.3s **Living Hut** — herder_hut (builder: HUTU)
- t=0.4s **Living Hut** — herder_hut (builder: HUTU)
- t=91.2s **Living Hut** — herder_hut (builder: COUF)

### PA MOJA

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (44% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Nuts | 5 | 0 |
| Spear | 0 | 5 |
| Stone | 6 | 0 |
| Wood | 20 | 6 |

#### Failures

- **Gather:** inventory_full=15, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAEN | 0 | 0 | 0 | 0 | hunt 59%, herd_wildnpc 29%, gather 12% |
| BAOZ | 0 | 0 | 0 | 0 | party 80%, wander 16%, gather 3% |
| KAZO | 0 | 0 | 1 | 10 | gather 100% |
| KUAS | 0 | 0 | 4 | 7 | gather 40%, wander 36%, hunt 23% |
| MEUQ | 0 | 0 | 0 | 1 | gather 100% |
| XENE | 0 | 0 | 1 | 0 | party 75%, herd_wildnpc 25% |
| XIFA | 0 | 0 | 0 | 9 | gather 100% |
| XOUR | 0 | 0 | 1 | 0 | party 75%, herd_wildnpc 14%, gather 10% |
| XUZO | 0 | 0 | 1 | 4 | gather 100% |

#### Hunts

- start t=39.5s prey=deer quota=4

#### Buildings

- t=0.3s **Living Hut** — herder_hut (builder: KUAS)
- t=0.3s **Living Hut** — herder_hut (builder: KUAS)

### QE MAJA

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Grain | 3 | 0 |
| Nuts | 5 | 0 |
| Spear | 0 | 3 |
| Stone | 3 | 0 |
| Wood | 27 | 3 |

#### Failures

- **Gather:** inventory_full=4, empty_switch:not_harvestable=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DAMU | 0 | 0 | 0 | 0 | party 88%, wander 10%, gather 2% |
| FUOH | 0 | 0 | 0 | 9 | gather 100% |
| GAUL | 0 | 0 | 0 | 5 | hunt 64%, gather 36% |
| GIEG | 0 | 0 | 3 | 6 | gather 57%, hunt 38%, wander 5% |
| HOOV | 0 | 0 | 1 | 8 | gather 100% |
| HUOF | 0 | 0 | 0 | 0 | party 98%, gather 2% |
| JAFE | 0 | 0 | 1 | 10 | gather 97%, wander 2%, idle 1% |

#### Hunts

- start t=24.0s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: GIEG)
- t=0.4s **Living Hut** — herder_hut (builder: GIEG)

