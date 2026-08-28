# ClanBrain Report (standard)

## Session

- **Duration:** 120.7s
- **JSONL:** `Tests/logs/party_hunt_test_20260527_171036/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| BU COMI | 0→10 | 5 | 0.1 | 1 | 0 | 25 | 17 | 1 | 25% | 25.0s | 4 | 2 | 25.4s |
| CE HIVU | 0→5 | 3 | 0.0 | 1 | 0 | 0 | 1 | 0 | 67% | 25.0s | 2 | 2 | 27.1s |
| DO CEID | 0→9 | 7 | 0.2 | 1 | 0 | 36 | 25 | 1 | 8% | 25.0s | 6 | 2 | 25.4s |
| KU JIUJ | 0→9 | 7 | 0.2 | 1 | 0 | 43 | 14 | 1 | 40% | 20.0s | 6 | 2 | 22.7s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 4 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 4

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| BU COMI | — | — | 25% | — | 0.0→0.1→0.1 | 25.0s |
| CE HIVU | — | — | 67% | — | 0.0→0.0→0.0 | 25.0s |
| DO CEID | — | — | 8% | — | 0.0→0.2→0.2 | 25.0s |
| KU JIUJ | — | — | 40% | — | 0.0→0.2→0.2 | 20.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| BU COMI | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| CE HIVU | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| DO CEID | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| KU JIUJ | 1 | 0 | 0 | 0 | 0 | 0 | 1 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| BU COMI | 0 | 6 | 4 | 22.4s |
| CE HIVU | 0 | 2 | 2 | 22.4s |
| DO CEID | 0 | 6 | 6 | 22.3s |
| KU JIUJ | 0 | 6 | 6 | 22.4s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| BU COMI | 0 | 0 | — | 0 | 1 | combat 36%, gather 31%, hunt 16% |
| CE HIVU | 0 | 0 | — | 0 | 0 | party 55%, hunt 28%, herd_wildnpc 6% |
| DO CEID | 0 | 0 | — | 0 | 2 | gather 38%, party 29%, hunt 14% |
| KU JIUJ | 0 | 0 | — | 0 | 4 | gather 43%, party 20%, hunt 15% |

## Economy (session)

- **Items gathered:** 104
- **Items deposited:** 57
- **Deposit yield:** 55%
- **Gather failures (all):** 183
- **Gather failures (actionable):** 3
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 2
- **empty_switch:not_harvestable:** 1
- **not_harvestable:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 5 | 1 | 20% |
| Fiber | 2 | 2 | 100% |
| Grain | 6 | 2 | 33% |
| Mushroom | 1 | 0 | 0% |
| Nuts | 23 | 7 | 30% |
| Spear | 0 | 10 | — |
| Stone | 1 | 0 | 0% |
| Wood | 66 | 35 | 53% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 8

### By source

- **herder_hut:** 8

### Chronological

- t=0.3s **DO CEID** — Living Hut (herder_hut) builder=WOOB @ (2369,805)
- t=0.3s **DO CEID** — Living Hut (herder_hut) builder=WOOB @ (2192,661)
- t=0.4s **BU COMI** — Living Hut (herder_hut) builder=HUFO @ (1075,2596)
- t=0.4s **BU COMI** — Living Hut (herder_hut) builder=HUFO @ (1246,2763)
- t=0.4s **CE HIVU** — Living Hut (herder_hut) builder=KOHI @ (-3211,-1253)
- t=0.4s **CE HIVU** — Living Hut (herder_hut) builder=KOHI @ (-3249,-1190)
- t=0.4s **KU JIUJ** — Living Hut (herder_hut) builder=XUXA @ (909,-2157)
- t=0.4s **KU JIUJ** — Living Hut (herder_hut) builder=XUXA @ (1076,-2016)

## Per-clan detail

### BU COMI

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (25% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 4 | 0 |
| Fiber | 2 | 2 |
| Mushroom | 1 | 0 |
| Nuts | 4 | 2 |
| Spear | 0 | 3 |
| Wood | 14 | 10 |

#### Failures

- **Gather:** inventory_full=30, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CELU | 0 | 0 | 0 | 9 | gather 58%, hunt 42% |
| CIAX | 0 | 0 | 1 | 0 | combat 80%, party 17%, gather 3% |
| HAAP | 0 | 0 | 0 | 0 | combat 80%, party 17%, gather 3% |
| HUFO | 0 | 0 | 4 | 7 | hunt 34%, wander 27%, gather 23% |
| JOIH | 0 | 0 | 1 | 9 | gather 84%, wander 16% |

#### Hunts

- start t=25.4s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: HUFO)
- t=0.4s **Living Hut** — herder_hut (builder: HUFO)

### CE HIVU

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (67% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DAUS | 0 | 0 | 0 | 0 | party 90%, combat 6%, gather 5% |
| KOHI | 0 | 0 | 1 | 0 | hunt 74%, herd_wildnpc 16%, combat 5% |
| WOUZ | 0 | 0 | 0 | 0 | party 87%, combat 6%, gather 5% |

#### Hunts

- start t=27.1s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: KOHI)
- t=0.4s **Living Hut** — herder_hut (builder: KOHI)

### DO CEID

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (8% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 1 | 1 |
| Grain | 3 | 0 |
| Nuts | 8 | 3 |
| Spear | 0 | 4 |
| Wood | 24 | 17 |

#### Failures

- **Gather:** inventory_full=60, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAZE | 0 | 0 | 0 | 0 | party 92%, combat 5%, herd_wildnpc 3% |
| HIOL | 0 | 0 | 1 | 0 | party 92%, combat 5%, gather 3% |
| JIXI | 0 | 0 | 0 | 9 | gather 57%, combat 34%, flee_combat 7% |
| KOIL | 0 | 0 | 2 | 13 | gather 91%, wander 9% |
| NAUT | 0 | 0 | 0 | 0 | flee_combat 51%, gather 41%, combat 6% |
| SOAT | 0 | 0 | 1 | 9 | gather 79%, wander 20%, idle 0% |
| WOOB | 0 | 0 | 4 | 5 | hunt 75%, gather 15%, combat 4% |

#### Hunts

- start t=25.4s prey=deer quota=3

#### Buildings

- t=0.3s **Living Hut** — herder_hut (builder: WOOB)
- t=0.3s **Living Hut** — herder_hut (builder: WOOB)

### KU JIUJ

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (40% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Grain | 3 | 2 |
| Nuts | 11 | 2 |
| Spear | 0 | 2 |
| Stone | 1 | 0 |
| Wood | 28 | 8 |

#### Failures

- **Gather:** inventory_full=89, empty_switch:not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CEQA | 0 | 0 | 0 | 0 | party 62%, combat 38%, herd_wildnpc 0% |
| FAUZ | 0 | 0 | 1 | 9 | gather 81%, wander 19% |
| MUEZ | 0 | 0 | 0 | 9 | gather 88%, wander 12% |
| NONE | 0 | 0 | 0 | 9 | gather 88%, wander 12% |
| VIIY | 0 | 0 | 0 | 9 | gather 72%, idle 27%, wander 1% |
| XUCA | 0 | 0 | 0 | 0 | party 61%, combat 37%, wander 1% |
| XUXA | 0 | 0 | 4 | 7 | hunt 76%, gather 15%, combat 7% |

#### Hunts

- start t=22.7s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: XUXA)
- t=0.4s **Living Hut** — herder_hut (builder: XUXA)

