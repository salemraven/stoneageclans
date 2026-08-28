# ClanBrain Report (standard)

## Session

- **Duration:** 120.5s
- **JSONL:** `Tests/logs/party_hunt_test_20260526_234541/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| FA MIIR | 0→9 | 7 | 0.4 | 1 | 0 | 36 | 19 | 1 | 20% | 20.0s | 6 | 2 | 24.9s |
| HU XORA | 0→8 | 5 | 0.0 | 1 | 0 | 18 | 2 | 0 | 83% | 25.0s | 4 | 2 | 26.3s |
| JA GUUH | 0→18 | 11 | 0.1 | 1 | 0 | 53 | 20 | 1 | 85% | 25.0s | 10 | 2 | 47.1s |
| QA QOOQ | 0→11 | 9 | 0.0 | 1 | 0 | 51 | 17 | 1 | 39% | 25.0s | 8 | 2 | 40.5s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 4 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 4

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| FA MIIR | — | — | 20% | — | 0.0→0.4→0.4 | 20.0s |
| HU XORA | — | — | 83% | — | 0.0→0.0→0.0 | 25.0s |
| JA GUUH | — | — | 85% | — | 0.0→0.1→0.1 | 25.0s |
| QA QOOQ | — | — | 39% | — | 0.0→0.0→0.0 | 25.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| FA MIIR | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| HU XORA | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| JA GUUH | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| QA QOOQ | 1 | 0 | 0 | 0 | 0 | 0 | 1 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| FA MIIR | 0 | 6 | 6 | 22.3s |
| HU XORA | 0 | 4 | 4 | 22.3s |
| JA GUUH | 0 | 12 | 10 | 22.2s |
| QA QOOQ | 0 | 8 | 8 | 22.4s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| FA MIIR | 0 | 0 | — | 0 | 4 | gather 42%, party 29%, hunt 14% |
| HU XORA | 0 | 0 | — | 0 | 2 | gather 28%, combat 26%, party 18% |
| JA GUUH | 0 | 0 | — | 0 | 0 | gather 35%, party 27%, hunt 10% |
| QA QOOQ | 0 | 0 | — | 0 | 2 | gather 40%, party 31%, hunt 10% |

## Economy (session)

- **Items gathered:** 158
- **Items deposited:** 58
- **Deposit yield:** 37%
- **Gather failures (all):** 186
- **Gather failures (actionable):** 3
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 7
- **resource_invalid:** 2
- **not_harvestable:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 6 | 0 | 0% |
| Fiber | 9 | 0 | 0% |
| Grain | 6 | 6 | 100% |
| Mushroom | 4 | 0 | 0% |
| Nuts | 26 | 3 | 12% |
| Spear | 0 | 15 | — |
| Wood | 107 | 34 | 32% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 8

### By source

- **herder_hut:** 8

### Chronological

- t=0.2s **JA GUUH** — Living Hut (herder_hut) builder=VUXA @ (2544,-598)
- t=0.2s **JA GUUH** — Living Hut (herder_hut) builder=VUXA @ (2312,-650)
- t=0.3s **FA MIIR** — Living Hut (herder_hut) builder=LIGO @ (246,3179)
- t=0.3s **FA MIIR** — Living Hut (herder_hut) builder=LIGO @ (292,3138)
- t=0.3s **HU XORA** — Living Hut (herder_hut) builder=YUAR @ (-1676,96)
- t=0.3s **HU XORA** — Living Hut (herder_hut) builder=YUAR @ (-1723,162)
- t=0.3s **QA QOOQ** — Living Hut (herder_hut) builder=JOIQ @ (1208,-2041)
- t=0.3s **QA QOOQ** — Living Hut (herder_hut) builder=JOIQ @ (1000,-2130)

## Per-clan detail

### FA MIIR

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.4 → 0.4

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 0 |
| Grain | 6 | 6 |
| Mushroom | 1 | 0 |
| Nuts | 5 | 1 |
| Spear | 0 | 4 |
| Wood | 21 | 8 |

#### Failures

- **Gather:** inventory_full=8, empty_switch:not_harvestable=3, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIVE | 0 | 0 | 2 | 8 | gather 78%, wander 22% |
| BOUM | 0 | 0 | 1 | 10 | gather 88%, idle 11%, wander 1% |
| GUAM | 0 | 0 | 0 | 0 | party 91%, combat 6%, gather 3% |
| LIGO | 0 | 0 | 2 | 2 | hunt 78%, gather 11%, wander 6% |
| MAIZ | 0 | 0 | 0 | 9 | gather 88%, idle 11%, wander 1% |
| VEDU | 0 | 0 | 0 | 0 | party 83%, wander 9%, combat 5% |
| VUWA | 0 | 0 | 2 | 7 | gather 74%, wander 26% |

#### Hunts

- start t=24.9s prey=deer quota=3

#### Buildings

- t=0.3s **Living Hut** — herder_hut (builder: LIGO)
- t=0.3s **Living Hut** — herder_hut (builder: LIGO)

### HU XORA

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (83% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Nuts | 2 | 0 |
| Spear | 0 | 2 |
| Wood | 16 | 0 |

#### Failures

- **Gather:** inventory_full=61

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| JAIT | 0 | 0 | 0 | 9 | gather 86%, wander 14% |
| KUNO | 0 | 0 | 1 | 0 | combat 53%, party 40%, gather 4% |
| PIRU | 0 | 0 | 0 | 0 | combat 55%, party 41%, gather 4% |
| RARO | 0 | 0 | 0 | 9 | gather 86%, wander 14% |
| YUAR | 0 | 0 | 1 | 0 | hunt 67%, herd_wildnpc 23%, combat 10% |

#### Hunts

- start t=26.3s prey=deer quota=3

#### Buildings

- t=0.3s **Living Hut** — herder_hut (builder: YUAR)
- t=0.3s **Living Hut** — herder_hut (builder: YUAR)

### JA GUUH

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (85% fill)
- **Pressure:** defend 0.15 | search 0.36 | gather 0.49
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Fiber | 3 | 0 |
| Mushroom | 1 | 0 |
| Nuts | 10 | 2 |
| Spear | 0 | 5 |
| Wood | 36 | 13 |

#### Failures

- **Gather:** inventory_full=35, empty_switch:not_harvestable=2, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FOKI | 0 | 0 | 0 | 0 | combat 64%, hunt 31%, wander 2% |
| HEFI | 0 | 0 | 1 | 0 | party 90%, combat 10%, herd_wildnpc 1% |
| KOOW | 0 | 0 | 1 | 4 | party 68%, herd_wildnpc 15%, combat 7% |
| KUUP | 0 | 0 | 1 | 2 | gather 100% |
| MIEB | 0 | 0 | 1 | 0 | hunt 83%, gather 17% |
| NAIR | 0 | 0 | 0 | 9 | gather 100% |
| QUKE | 0 | 0 | 0 | 9 | gather 100% |
| RAER | 0 | 0 | 0 | 9 | gather 100% |
| VOAY | 0 | 0 | 0 | 0 | party 62%, herd_wildnpc 20%, wander 9% |
| VUXA | 0 | 0 | 7 | 13 | wander 49%, gather 26%, herd_wildnpc 24% |
| XOAR | 0 | 0 | 0 | 7 | gather 100% |

#### Hunts

- start t=47.1s prey=deer quota=4

#### Buildings

- t=0.2s **Living Hut** — herder_hut (builder: VUXA)
- t=0.2s **Living Hut** — herder_hut (builder: VUXA)

### QA QOOQ

- **Brain:** AGGRESSIVE | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (39% fill)
- **Pressure:** defend 0.16 | search 0.35 | gather 0.48
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Fiber | 3 | 0 |
| Mushroom | 2 | 0 |
| Nuts | 9 | 0 |
| Spear | 0 | 4 |
| Wood | 34 | 13 |

#### Failures

- **Gather:** inventory_full=72, empty_switch:not_harvestable=2, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIKE | 0 | 0 | 0 | 9 | gather 100% |
| DUMU | 0 | 0 | 0 | 0 | party 72%, herd_wildnpc 14%, wander 8% |
| FAJO | 0 | 0 | 0 | 3 | combat 69%, gather 28%, flee_combat 3% |
| GAKA | 0 | 0 | 0 | 0 | party 79%, herd_wildnpc 18%, combat 3% |
| JOIQ | 0 | 0 | 3 | 6 | hunt 65%, gather 26%, wander 7% |
| LIDU | 0 | 0 | 1 | 10 | gather 80%, wander 19%, idle 1% |
| MUON | 0 | 0 | 1 | 0 | party 93%, gather 4%, combat 3% |
| NIGA | 0 | 0 | 1 | 14 | gather 89%, wander 11% |
| WUAD | 0 | 0 | 0 | 9 | gather 100% |

#### Hunts

- start t=40.5s prey=deer quota=4

#### Buildings

- t=0.3s **Living Hut** — herder_hut (builder: JOIQ)
- t=0.3s **Living Hut** — herder_hut (builder: JOIQ)

