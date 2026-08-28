# ClanBrain Report (standard)

## Session

- **Duration:** 120.7s
- **JSONL:** `Tests/logs/party_hunt_test_20260526_225833/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| LU QAOV | 0→9 | 7 | 0.0 | 2 | 1 | 29 | 5 | 0 | 17% | 20.9s | 6 | 2 | 23.9s |
| MA VAOH | 0→7 | 5 | 0.3 | 1 | 0 | 19 | 21 | 1 | 20% | 20.9s | 4 | 2 | 24.0s |
| MO YOYU | 0→7 | 5 | 0.1 | 1 | 0 | 19 | 13 | 0 | 83% | 25.9s | 4 | 2 | 28.2s |
| RA TUAG | 0→9 | 7 | 0.1 | 1 | 0 | 39 | 21 | 0 | 8% | 25.9s | 6 | 2 | 28.0s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 5 / 1
- **⚠ Possible stuck parties (formed − disbanded):** 4

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| LU QAOV | — | — | 17% | — | 0.0→0.0→0.0 | 20.9s |
| MA VAOH | — | — | 20% | — | 0.0→0.3→0.3 | 20.9s |
| MO YOYU | — | — | 83% | — | 0.0→0.1→0.1 | 25.9s |
| RA TUAG | — | — | 8% | — | 0.0→0.1→0.1 | 25.9s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| LU QAOV | 2 | 1 | 1 | 0 | 0 | 0 | 0 |
| MA VAOH | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| MO YOYU | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| RA TUAG | 1 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| LU QAOV | 0 | 6 | 6 | 23.3s |
| MA VAOH | 0 | 4 | 4 | 23.3s |
| MO YOYU | 0 | 4 | 4 | 23.4s |
| RA TUAG | 0 | 6 | 6 | 23.3s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| LU QAOV | 0 | 0 | — | 0 | 0 | gather 32%, party 26%, combat 17% |
| MA VAOH | 0 | 0 | — | 0 | 2 | combat 40%, gather 32%, hunt 13% |
| MO YOYU | 0 | 0 | — | 0 | 1 | gather 30%, combat 29%, party 17% |
| RA TUAG | 0 | 0 | — | 0 | 4 | gather 45%, combat 28%, hunt 12% |

## Economy (session)

- **Items gathered:** 106
- **Items deposited:** 60
- **Deposit yield:** 57%
- **Gather failures (all):** 172
- **Gather failures (actionable):** 1
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 1
- **resource_invalid:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 3 | 2 | 67% |
| Fiber | 6 | 5 | 83% |
| Grain | 3 | 2 | 67% |
| Mushroom | 1 | 1 | 100% |
| Nuts | 16 | 2 | 12% |
| Spear | 0 | 15 | — |
| Stone | 6 | 6 | 100% |
| Wood | 71 | 27 | 38% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 8

### By source

- **herder_hut:** 8

### Chronological

- t=0.4s **LU QAOV** — Living Hut (herder_hut) builder=WOUM @ (3160,-1583)
- t=0.4s **LU QAOV** — Living Hut (herder_hut) builder=WOUM @ (2962,-1711)
- t=0.4s **MA VAOH** — Living Hut (herder_hut) builder=TEKE @ (-1455,3154)
- t=0.4s **MA VAOH** — Living Hut (herder_hut) builder=TEKE @ (-1421,3108)
- t=0.5s **RA TUAG** — Living Hut (herder_hut) builder=ZONE @ (-2568,-1016)
- t=0.5s **RA TUAG** — Living Hut (herder_hut) builder=ZONE @ (-2802,-1061)
- t=0.5s **MO YOYU** — Living Hut (herder_hut) builder=YUUW @ (730,-1905)
- t=0.5s **MO YOYU** — Living Hut (herder_hut) builder=YUUW @ (557,-2070)

## Per-clan detail

### LU QAOV

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (17% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 2 |
| Nuts | 4 | 0 |
| Spear | 0 | 3 |
| Wood | 22 | 0 |

#### Failures

- **Gather:** inventory_full=8

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| LOOQ | 0 | 0 | 0 | 0 | party 55%, combat 44%, gather 1% |
| MILA | 0 | 0 | 1 | 0 | party 53%, combat 42%, wander 3% |
| MUUN | 0 | 0 | 0 | 8 | gather 66%, herd_wildnpc 33%, wander 1% |
| NOUG | 0 | 0 | 0 | 9 | gather 88%, hunt 12%, wander 1% |
| PEOM | 0 | 0 | 0 | 2 | party 44%, gather 40%, hunt 15% |
| TOAW | 0 | 0 | 1 | 7 | gather 59%, herd_wildnpc 40%, wander 1% |
| WOUM | 0 | 0 | 2 | 3 | hunt 59%, gather 27%, wander 9% |

#### Hunts

- start t=23.9s prey=deer quota=3
- start t=88.9s prey=deer quota=4
- hunt_completed t=86.2s reason=retreat_complete
- hunt_aborted t=86.5s reason=brain_lost

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: WOUM)
- t=0.4s **Living Hut** — herder_hut (builder: WOUM)

### MA VAOH

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.3 → 0.3

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 2 |
| Mushroom | 1 | 1 |
| Nuts | 2 | 1 |
| Spear | 0 | 4 |
| Stone | 6 | 6 |
| Wood | 7 | 7 |

#### Failures

- **Gather:** inventory_full=23, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GARA | 0 | 0 | 1 | 8 | gather 89%, wander 11% |
| JEZE | 0 | 0 | 1 | 0 | combat 77%, party 22%, gather 1% |
| KEUH | 0 | 0 | 0 | 0 | combat 77%, party 22%, gather 1% |
| QUZO | 0 | 0 | 1 | 9 | gather 85%, wander 15% |
| TEKE | 0 | 0 | 2 | 2 | hunt 52%, combat 31%, gather 11% |

#### Hunts

- start t=24.0s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: TEKE)
- t=0.4s **Living Hut** — herder_hut (builder: TEKE)

### MO YOYU

- **Brain:** PEACEFUL | alert NONE | hunt RETREATING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (83% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Nuts | 5 | 1 |
| Spear | 0 | 5 |
| Wood | 14 | 7 |

#### Failures

- **Gather:** inventory_full=41

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAES | 0 | 0 | 1 | 9 | gather 80%, wander 11%, hunt 9% |
| NEVI | 0 | 0 | 1 | 10 | gather 78%, wander 20%, hunt 1% |
| WIHA | 0 | 0 | 1 | 0 | combat 55%, party 40%, gather 5% |
| YEAM | 0 | 0 | 1 | 0 | combat 55%, party 40%, gather 5% |
| YUUW | 0 | 0 | 1 | 0 | hunt 46%, combat 23%, herd_wildnpc 20% |

#### Hunts

- start t=28.2s prey=deer quota=3

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: YUUW)
- t=0.5s **Living Hut** — herder_hut (builder: YUUW)

### RA TUAG

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (8% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 3 |
| Grain | 3 | 2 |
| Nuts | 5 | 0 |
| Spear | 0 | 3 |
| Wood | 28 | 13 |

#### Failures

- **Gather:** inventory_full=98, empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DUYU | 0 | 0 | 0 | 9 | gather 89%, idle 10%, wander 1% |
| GOIL | 0 | 0 | 0 | 9 | gather 90%, wander 10% |
| LAMI | 0 | 0 | 1 | 9 | gather 84%, wander 16% |
| NUMI | 0 | 0 | 0 | 0 | combat 77%, party 18%, gather 5% |
| VIJO | 0 | 0 | 0 | 0 | combat 77%, party 18%, herd_wildnpc 5% |
| XAKE | 0 | 0 | 1 | 9 | gather 79%, wander 21%, idle 0% |
| ZONE | 0 | 0 | 3 | 3 | hunt 61%, combat 17%, gather 14% |

#### Hunts

- start t=28.0s prey=deer quota=3

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: ZONE)
- t=0.5s **Living Hut** — herder_hut (builder: ZONE)

