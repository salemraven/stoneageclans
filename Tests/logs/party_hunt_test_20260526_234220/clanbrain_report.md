# ClanBrain Report (standard)

## Session

- **Duration:** 115.3s
- **JSONL:** `Tests/logs/party_hunt_test_20260526_234220/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| DU GAVA | 0→11 | 7 | 0.2 | 2 | 1 | 25 | 20 | 0 | 17% | 20.0s | 6 | 2 | 24.8s |
| HA WEYO | 0→12 | 7 | 0.0 | 1 | 1 | 35 | 17 | 2 | 20% | 20.0s | 6 | 2 | 24.1s |
| LO LOEX | 0→11 | 7 | 0.1 | 2 | 1 | 32 | 15 | 3 | 17% | 20.0s | 6 | 2 | 24.9s |
| QA HOAN | 0→11 | 7 | 0.0 | 2 | 1 | 33 | 21 | 3 | 21% | 25.0s | 8 | 2 | 25.6s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 7 / 4
- **⚠ Possible stuck parties (formed − disbanded):** 3

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| DU GAVA | — | — | 17% | — | 0.0→0.3→0.2 | 20.0s |
| HA WEYO | — | — | 20% | — | 0.0→0.0→0.0 | 20.0s |
| LO LOEX | — | — | 17% | — | 0.0→0.1→0.1 | 20.0s |
| QA HOAN | — | — | 21% | — | 0.0→0.0→0.0 | 25.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| DU GAVA | 2 | 1 | 1 | 0 | 0 | 0 | 0 |
| HA WEYO | 1 | 1 | 1 | 0 | 0 | 0 | 0 |
| LO LOEX | 2 | 1 | 1 | 0 | 0 | 0 | 0 |
| QA HOAN | 2 | 1 | 1 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| DU GAVA | 0 | 8 | 6 | 22.5s |
| HA WEYO | 2 | 6 | 6 | 22.5s |
| LO LOEX | 0 | 8 | 6 | 22.4s |
| QA HOAN | 0 | 8 | 8 | 22.5s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| DU GAVA | 0 | 0 | — | 0 | 0 | party 39%, gather 25%, hunt 17% |
| HA WEYO | 0 | 0 | — | 0 | 1 | gather 45%, party 19%, combat 16% |
| LO LOEX | 0 | 0 | — | 0 | 2 | gather 46%, party 27%, hunt 13% |
| QA HOAN | 0 | 0 | — | 0 | 2 | gather 46%, party 29%, hunt 13% |

## Economy (session)

- **Items gathered:** 125
- **Items deposited:** 73
- **Deposit yield:** 58%
- **Gather failures (all):** 26
- **Gather failures (actionable):** 8
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 10
- **not_harvestable:** 5
- **resource_invalid:** 3

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 3 | 3 | 100% |
| Fiber | 12 | 7 | 58% |
| Grain | 10 | 3 | 30% |
| Mushroom | 1 | 0 | 0% |
| Nuts | 13 | 1 | 8% |
| Spear | 0 | 17 | — |
| Stone | 13 | 9 | 69% |
| Wood | 73 | 33 | 45% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 8

### By source

- **herder_hut:** 8

### Chronological

- t=0.4s **LO LOEX** — Living Hut (herder_hut) builder=PEOY @ (3083,94)
- t=0.4s **LO LOEX** — Living Hut (herder_hut) builder=PEOY @ (2906,-63)
- t=0.4s **HA WEYO** — Living Hut (herder_hut) builder=LIAS @ (683,2795)
- t=0.4s **HA WEYO** — Living Hut (herder_hut) builder=LIAS @ (655,2839)
- t=0.5s **DU GAVA** — Living Hut (herder_hut) builder=SEEW @ (-2094,-553)
- t=0.5s **DU GAVA** — Living Hut (herder_hut) builder=SEEW @ (-2291,-673)
- t=0.5s **QA HOAN** — Living Hut (herder_hut) builder=BOZU @ (1254,-2958)
- t=0.5s **QA HOAN** — Living Hut (herder_hut) builder=BOZU @ (1102,-3108)

## Per-clan detail

### DU GAVA

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (17% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.3 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 3 |
| Fiber | 3 | 3 |
| Grain | 6 | 2 |
| Nuts | 1 | 0 |
| Spear | 0 | 3 |
| Stone | 9 | 6 |
| Wood | 3 | 3 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GABU | 0 | 0 | 2 | 11 | gather 56%, herd_wildnpc 24%, hunt 11% |
| GEDA | 0 | 0 | 0 | 0 | craft 100% |
| REIS | 0 | 0 | 0 | 0 | party 91%, combat 7%, gather 2% |
| SEEW | 0 | 0 | 2 | 5 | hunt 60%, gather 26%, wander 8% |
| XEOR | 0 | 0 | 2 | 9 | gather 62%, party 26%, hunt 9% |
| YULE | 0 | 0 | 0 | 0 | craft 100% |
| ZIUP | 0 | 0 | 0 | 0 | party 88%, combat 7%, herd_wildnpc 2% |

#### Hunts

- start t=24.8s prey=deer quota=3
- start t=94.9s prey=deer quota=4
- hunt_completed t=92.5s reason=retreat_complete
- hunt_aborted t=92.9s reason=brain_lost

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: SEEW)
- t=0.5s **Living Hut** — herder_hut (builder: SEEW)

### HA WEYO

- **Brain:** PEACEFUL | alert NONE | hunt RETREATING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (20% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 2 |
| Grain | 3 | 0 |
| Nuts | 5 | 0 |
| Spear | 0 | 4 |
| Wood | 24 | 11 |

#### Failures

- **Gather:** inventory_full=4, empty_switch:not_harvestable=2, not_harvestable=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEER | 0 | 0 | 1 | 7 | gather 81%, hunt 10%, wander 9% |
| DUUB | 0 | 0 | 1 | 0 | party 60%, combat 38%, herd_wildnpc 2% |
| FAUM | 0 | 0 | 0 | 8 | gather 96%, wander 4% |
| HUTU | 0 | 0 | 0 | 9 | gather 72%, hunt 16%, build_hut_for_woman 6% |
| KODA | 0 | 0 | 2 | 6 | gather 75%, hunt 14%, wander 10% |
| LIAS | 0 | 0 | 2 | 5 | hunt 34%, gather 30%, combat 20% |
| SAIV | 0 | 0 | 0 | 0 | party 60%, combat 38%, gather 2% |

#### Hunts

- start t=24.1s prey=deer quota=3
- hunt_completed t=114.4s reason=retreat_complete
- hunt_aborted t=114.8s reason=brain_lost

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: LIAS)
- t=0.4s **Living Hut** — herder_hut (builder: LIAS)

### LO LOEX

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/2 (17% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 6 | 2 |
| Grain | 1 | 1 |
| Nuts | 3 | 1 |
| Spear | 0 | 5 |
| Stone | 1 | 0 |
| Wood | 21 | 6 |

#### Failures

- **Gather:** inventory_full=4, empty_switch:not_harvestable=3, resource_invalid=2, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BETA | 0 | 0 | 1 | 7 | gather 98%, wander 2% |
| BUBI | 0 | 0 | 0 | 6 | gather 83%, hunt 11%, wander 6% |
| HEUP | 0 | 0 | 1 | 0 | party 82%, combat 15%, herd_wildnpc 3% |
| MEPO | 0 | 0 | 1 | 9 | gather 75%, hunt 15%, wander 10% |
| PEOY | 0 | 0 | 2 | 2 | hunt 50%, gather 30%, combat 13% |
| XIUC | 0 | 0 | 0 | 8 | gather 79%, wander 21% |
| XIUZ | 0 | 0 | 1 | 0 | party 82%, combat 15%, gather 3% |

#### Hunts

- start t=24.9s prey=deer quota=3
- start t=115.0s prey=deer quota=4
- hunt_completed t=111.5s reason=retreat_complete
- hunt_aborted t=111.7s reason=brain_lost

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: PEOY)
- t=0.4s **Living Hut** — herder_hut (builder: PEOY)

### QA HOAN

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (21% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Mushroom | 1 | 0 |
| Nuts | 4 | 0 |
| Spear | 0 | 5 |
| Stone | 3 | 3 |
| Wood | 25 | 13 |

#### Failures

- **Gather:** empty_switch:not_harvestable=5, not_harvestable=2, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIPA | 0 | 0 | 0 | 0 | party 89%, combat 8%, gather 3% |
| BOZU | 0 | 0 | 2 | 4 | hunt 59%, gather 28%, wander 7% |
| FAEZ | 0 | 0 | 0 | 9 | gather 93%, wander 6%, idle 1% |
| HUUV | 0 | 0 | 0 | 0 | wander 73%, gather 20%, idle 7% |
| LEEX | 0 | 0 | 1 | 5 | gather 78%, party 12%, idle 9% |
| RUUJ | 0 | 0 | 0 | 0 | gather 100% |
| VIIH | 0 | 0 | 1 | 0 | party 89%, combat 8%, gather 3% |
| WIWA | 0 | 0 | 1 | 9 | gather 79%, hunt 11%, wander 10% |
| YOEG | 0 | 0 | 2 | 6 | gather 77%, wander 19%, hunt 4% |

#### Hunts

- start t=25.6s prey=deer quota=3
- start t=105.7s prey=deer quota=4
- hunt_completed t=101.2s reason=retreat_complete
- hunt_aborted t=101.4s reason=brain_lost

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: BOZU)
- t=0.5s **Living Hut** — herder_hut (builder: BOZU)

