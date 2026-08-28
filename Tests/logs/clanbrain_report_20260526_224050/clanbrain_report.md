# ClanBrain Report (standard)

## Session

- **Duration:** 54.6s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_20260526_224050/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| QU JUSO | 0→9 | 5 | 0.0 | 1 | 0 | 5 | 6 | 0 | 8% | 25.0s | 6 | 2 | 26.4s |
| TA KILE | 0→9 | 5 | 0.0 | 1 | 0 | 13 | 13 | 0 | 8% | 25.0s | 6 | 2 | 26.1s |
| XO WAON | 0→9 | 5 | 0.0 | 1 | 0 | 2 | 7 | 0 | 20% | 20.1s | 6 | 2 | 24.9s |
| ZE PIOJ | 0→9 | 7 | 0.0 | 1 | 0 | 1 | 5 | 1 | 20% | 20.0s | 6 | 2 | 23.5s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 4 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 4

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| QU JUSO | — | — | 8% | — | 0.0→0.0→0.0 | 25.0s |
| TA KILE | — | — | 8% | — | 0.0→0.0→0.0 | 25.0s |
| XO WAON | — | — | 20% | — | 0.0→0.0→0.0 | 20.1s |
| ZE PIOJ | — | — | 20% | — | 0.0→0.0→0.0 | 20.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| QU JUSO | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| TA KILE | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| XO WAON | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| ZE PIOJ | 1 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| QU JUSO | 0 | 6 | 6 | 22.5s |
| TA KILE | 0 | 6 | 6 | 22.5s |
| XO WAON | 0 | 6 | 6 | 22.5s |
| ZE PIOJ | 0 | 6 | 6 | 22.6s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| QU JUSO | 0 | 0 | — | 0 | 0 | party 36%, hunt 23%, gather 21% |
| TA KILE | 0 | 0 | — | 0 | 0 | party 35%, hunt 24%, gather 22% |
| XO WAON | 0 | 0 | — | 0 | 0 | party 36%, hunt 24%, gather 18% |
| ZE PIOJ | 0 | 0 | — | 0 | 0 | party 38%, gather 35%, hunt 19% |

## Economy (session)

- **Items gathered:** 21
- **Items deposited:** 31
- **Deposit yield:** 148%
- **Gather failures (all):** 1
- **Gather failures (actionable):** 1
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Nuts | 2 | 0 | 0% |
| Spear | 0 | 15 | — |
| Stone | 1 | 1 | 100% |
| Wood | 18 | 15 | 83% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 8

### By source

- **herder_hut:** 8

### Chronological

- t=0.5s **XO WAON** — Living Hut (herder_hut) builder=VALO @ (3447,12)
- t=0.5s **XO WAON** — Living Hut (herder_hut) builder=VALO @ (3229,-67)
- t=0.5s **QU JUSO** — Living Hut (herder_hut) builder=QOMI @ (-336,2086)
- t=0.5s **QU JUSO** — Living Hut (herder_hut) builder=QOMI @ (-137,2190)
- t=0.5s **TA KILE** — Living Hut (herder_hut) builder=DAIV @ (-2708,52)
- t=0.6s **TA KILE** — Living Hut (herder_hut) builder=DAIV @ (-2936,-3)
- t=0.6s **ZE PIOJ** — Living Hut (herder_hut) builder=TAOS @ (1141,-3366)
- t=0.6s **ZE PIOJ** — Living Hut (herder_hut) builder=TAOS @ (937,-3474)

## Per-clan detail

### QU JUSO

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (8% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Nuts | 1 | 0 |
| Spear | 0 | 2 |
| Wood | 4 | 4 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DAFU | 0 | 0 | 1 | 0 | party 88%, gather 12% |
| DIAY | 0 | 0 | 0 | 0 | party 88%, gather 12% |
| LIPO | 0 | 0 | 0 | 0 | gather 79%, hunt 21% |
| QOMI | 0 | 0 | 4 | 5 | hunt 43%, gather 36%, wander 19% |
| SEZI | 0 | 0 | 0 | 0 | gather 88%, hunt 12% |
| SIJU | 0 | 0 | 0 | 0 | combat 55%, hunt 36%, gather 9% |
| SIQE | 0 | 0 | 0 | 0 | combat 61%, hunt 30%, gather 9% |

#### Hunts

- start t=26.4s prey=deer quota=3

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: QOMI)
- t=0.5s **Living Hut** — herder_hut (builder: QOMI)

### TA KILE

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (8% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Nuts | 1 | 0 |
| Spear | 0 | 4 |
| Wood | 12 | 9 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CUIJ | 0 | 0 | 1 | 0 | hunt 81%, combat 11%, gather 7% |
| DAIV | 0 | 0 | 6 | 9 | gather 49%, hunt 27%, wander 23% |
| GUES | 0 | 0 | 0 | 4 | gather 100% |
| MOOT | 0 | 0 | 0 | 0 | hunt 47%, wander 23%, combat 21% |
| ROPI | 0 | 0 | 0 | 0 | gather 100% |
| WUSI | 0 | 0 | 1 | 0 | party 88%, herd_wildnpc 11%, idle 1% |
| XILA | 0 | 0 | 1 | 0 | party 89%, gather 11% |

#### Hunts

- start t=26.1s prey=deer quota=3

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: DAIV)
- t=0.6s **Living Hut** — herder_hut (builder: DAIV)

### XO WAON

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 5 |
| Wood | 2 | 2 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GULA | 0 | 0 | 1 | 0 | hunt 45%, combat 38%, wander 16% |
| QIIQ | 0 | 0 | 1 | 0 | gather 100% |
| RAIM | 0 | 0 | 0 | 0 | hunt 66%, combat 34% |
| SEME | 0 | 0 | 1 | 0 | party 93%, gather 7% |
| TEHU | 0 | 0 | 1 | 0 | party 72%, wander 21%, herd_wildnpc 5% |
| TISE | 0 | 0 | 0 | 0 | gather 100% |
| VALO | 0 | 0 | 2 | 2 | gather 45%, hunt 39%, wander 14% |

#### Hunts

- start t=24.9s prey=deer quota=3

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: VALO)
- t=0.5s **Living Hut** — herder_hut (builder: VALO)

### ZE PIOJ

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 4 |
| Stone | 1 | 1 |

#### Failures

- **Gather:** resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEZO | 0 | 0 | 0 | 0 | gather 96%, hunt 4% |
| GAIK | 0 | 0 | 0 | 0 | gather 100% |
| NIMO | 0 | 0 | 1 | 0 | party 97%, gather 3% |
| QOTO | 0 | 0 | 1 | 0 | hunt 71%, gather 25%, combat 4% |
| TAOS | 0 | 0 | 2 | 1 | gather 63%, hunt 36%, wander 1% |
| YEUC | 0 | 0 | 0 | 0 | party 97%, gather 3% |
| ZUAW | 0 | 0 | 1 | 0 | wander 82%, gather 14%, idle 3% |

#### Hunts

- start t=23.5s prey=deer quota=3

#### Buildings

- t=0.6s **Living Hut** — herder_hut (builder: TAOS)
- t=0.6s **Living Hut** — herder_hut (builder: TAOS)

