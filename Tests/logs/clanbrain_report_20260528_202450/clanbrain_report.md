# ClanBrain Report (standard)

## Session

- **Duration:** 300.3s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_20260528_202450/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| QE NAED | 0→17 | 11 | 0.2 | 0 | 0 | 72 | 50 | 5 | 85% | 85.1s | 10 | 3 | — |
| RA RILU | 0→6 | 5 | 0.6 | 0 | 0 | 58 | 47 | 5 | 69% | 110.1s | 4 | 1 | — |
| RO VIWO | 0→11 | 6 | 0.0 | 1 | 0 | 16 | 19 | 0 | 71% | 70.1s | 5 | 2 | 124.5s |
| RU HAQI | 0→11 | 10 | 1.0 | 0 | 0 | 128 | 82 | 1 | 72% | 90.1s | 9 | 1 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 1 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 1

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| QE NAED | 100% | 0% | 69% | 17% | 0.0→0.3→0.2 | 85.1s |
| RA RILU | — | — | 69% | 11% | 0.0→0.7→0.6 | 110.1s |
| RO VIWO | — | — | 71% | 33% | 0.0→0.1→0.0 | 70.1s |
| RU HAQI | — | — | 72% | 14% | 0.0→1.0→1.0 | 90.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| QE NAED | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| RA RILU | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| RO VIWO | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| RU HAQI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| QE NAED | 4 | 11 | 10 | 85.1s |
| RA RILU | 1 | 4 | 4 | 110.0s |
| RO VIWO | 1 | 5 | 5 | 70.1s |
| RU HAQI | 1 | 9 | 9 | 90.7s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| QE NAED | 0 | 0 | — | 0 | 1 | herd_wildnpc 28%, gather 26%, wander 15% |
| RA RILU | 0 | 0 | — | 0 | 4 | gather 54%, wander 17%, combat 15% |
| RO VIWO | 0 | 0 | — | 0 | 1 | hunt 27%, combat 18%, gather 17% |
| RU HAQI | 0 | 0 | — | 0 | 7 | gather 54%, craft 31%, wander 10% |

## Economy (session)

- **Items gathered:** 274
- **Items deposited:** 198
- **Deposit yield:** 72%
- **Gather failures (all):** 167
- **Gather failures (actionable):** 11
- **Deposit failures:** 0

### Gather failures (actionable)

- **not_harvestable:** 6
- **resource_invalid:** 5
- **empty_switch:not_harvestable:** 3

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 29 | 16 | 55% |
| Fiber | 15 | 15 | 100% |
| Grain | 18 | 10 | 56% |
| Mushroom | 3 | 0 | 0% |
| Nuts | 38 | 17 | 45% |
| Spear | 0 | 23 | — |
| Stone | 25 | 19 | 76% |
| Wood | 146 | 98 | 67% |

## Buildings (session)

- **Total placed:** 7

### By type

- **Living Hut:** 6
- **Farm:** 1

### By source

- **herder_hut:** 6
- **milestone:** 1

### Chronological

- t=37.6s **RO VIWO** — Living Hut (herder_hut) builder=JUYA @ (2599,-834)
- t=52.6s **QE NAED** — Living Hut (herder_hut) builder=HAPE @ (-1800,1002)
- t=58.2s **RU HAQI** — Living Hut (herder_hut) builder=NAEB @ (159,-2679)
- t=77.5s **RA RILU** — Living Hut (herder_hut) builder=WOWO @ (-1078,3294)
- t=124.5s **RO VIWO** — Farm (milestone) @ (2382,-935)
- t=140.6s **QE NAED** — Living Hut (herder_hut) builder=BEHU @ (-1947,818)
- t=223.3s **QE NAED** — Living Hut (herder_hut) builder=NUUC @ (-1906,787)

## Per-clan detail

### QE NAED

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (100% fill) | searchers 3/3 (69% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.3 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 12 | 3 |
| Fiber | 3 | 3 |
| Grain | 3 | 2 |
| Mushroom | 2 | 0 |
| Nuts | 4 | 1 |
| Spear | 0 | 9 |
| Stone | 4 | 1 |
| Wood | 44 | 31 |

#### Failures

- **Gather:** inventory_full=14, resource_invalid=4, empty_switch:not_harvestable=1, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEHU | 0 | 0 | 1 | 6 | idle 51%, herd_wildnpc 26%, build_hut_for_woman 9% |
| CARU | 0 | 0 | 1 | 7 | flee_combat 41%, herd_wildnpc 22%, gather 17% |
| FUKO | 0 | 0 | 1 | 9 | gather 67%, wander 19%, herd_wildnpc 14% |
| GOOR | 0 | 0 | 1 | 8 | herd_wildnpc 54%, gather 32%, wander 11% |
| HAPE | 0 | 0 | 9 | 24 | gather 39%, wander 31%, herd_wildnpc 10% |
| HOBO | 0 | 0 | 1 | 7 | herd_wildnpc 46%, combat 20%, gather 17% |
| KIAM | 0 | 0 | 0 | 3 | gather 98%, idle 2% |
| LAAD | 0 | 0 | 0 | 0 | combat 92%, gather 6%, idle 1% |
| LEUY | 0 | 0 | 1 | 5 | combat 33%, gather 28%, herd_wildnpc 22% |
| NUUC | 0 | 0 | 1 | 3 | herd_wildnpc 64%, build_hut_for_woman 17%, gather 9% |
| VIKU | 0 | 0 | 1 | 0 | gather 100% |

#### Buildings

- t=52.6s **Living Hut** — herder_hut (builder: HAPE)
- t=140.6s **Living Hut** — herder_hut (builder: BEHU)
- t=223.3s **Living Hut** — herder_hut (builder: NUUC)

### RA RILU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (69% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.7 → 0.6

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 6 |
| Fiber | 6 | 6 |
| Grain | 3 | 2 |
| Mushroom | 1 | 0 |
| Nuts | 9 | 5 |
| Spear | 0 | 5 |
| Stone | 6 | 6 |
| Wood | 27 | 17 |

#### Failures

- **Gather:** inventory_full=27, not_harvestable=4, empty_switch:not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIHA | 0 | 0 | 1 | 8 | combat 64%, gather 32%, wander 5% |
| BUQA | 0 | 0 | 2 | 17 | gather 81%, wander 19% |
| DOFA | 0 | 0 | 1 | 6 | gather 85%, wander 15% |
| NIKO | 0 | 0 | 2 | 19 | gather 66%, wander 21%, flee_combat 11% |
| WOWO | 0 | 0 | 4 | 8 | gather 34%, wander 20%, herd_wildnpc 15% |

#### Buildings

- t=77.5s **Living Hut** — herder_hut (builder: WOWO)

### RO VIWO

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (71% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 3 |
| Grain | 3 | 3 |
| Nuts | 1 | 0 |
| Spear | 0 | 4 |
| Stone | 6 | 6 |
| Wood | 3 | 3 |

#### Failures

- **Gather:** inventory_full=8

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| HAGE | 0 | 0 | 0 | 0 | hunt 77%, gather 23% |
| JUYA | 0 | 0 | 2 | 3 | wander 46%, herd_wildnpc 26%, hunt 11% |
| MEIT | 0 | 0 | 0 | 0 | combat 39%, herd_wildnpc 29%, hunt 19% |
| PION | 0 | 0 | 4 | 13 | gather 85%, wander 14%, hunt 1% |
| REOM | 0 | 0 | 1 | 0 | combat 46%, party 32%, gather 12% |
| ZEAQ | 0 | 0 | 1 | 0 | hunt 85%, gather 13%, wander 1% |

#### Hunts

- start t=124.5s prey=deer quota=3

#### Buildings

- t=37.6s **Living Hut** — herder_hut (builder: JUYA)
- t=124.5s **Farm** — milestone

### RU HAQI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (72% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 1.0 → 1.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 11 | 7 |
| Fiber | 3 | 3 |
| Grain | 9 | 3 |
| Nuts | 24 | 11 |
| Spear | 0 | 5 |
| Stone | 9 | 6 |
| Wood | 72 | 47 |

#### Failures

- **Gather:** inventory_full=104, empty_switch:not_harvestable=1, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DOUG | 0 | 0 | 0 | 9 | gather 96%, wander 2%, idle 1% |
| HEDO | 0 | 0 | 1 | 18 | gather 58%, craft 39%, wander 3% |
| JEOH | 0 | 0 | 0 | 0 | craft 90%, gather 10%, wander 0% |
| MUAB | 0 | 0 | 0 | 0 | gather 100% |
| NAEB | 0 | 0 | 14 | 44 | gather 50%, wander 23%, herd_wildnpc 11% |
| POZA | 0 | 0 | 2 | 27 | gather 86%, wander 14%, idle 0% |
| PUIH | 0 | 0 | 0 | 9 | gather 100% |
| QUWE | 0 | 0 | 2 | 11 | gather 83%, wander 16%, idle 0% |
| TIJU | 0 | 0 | 0 | 0 | craft 100% |
| ZOTU | 0 | 0 | 1 | 10 | craft 58%, gather 38%, wander 4% |

#### Buildings

- t=58.2s **Living Hut** — herder_hut (builder: NAEB)

