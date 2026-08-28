# ClanBrain Report (standard)

## Session

- **Duration:** 56.5s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_20260526_224244/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| HU JAVU | 0→9 | 5 | 0.1 | 1 | 0 | 2 | 5 | 0 | 17% | 25.0s | 4 | 2 | 27.0s |
| SO HOCI | 0→7 | 5 | 0.1 | 1 | 0 | 5 | 5 | 0 | 20% | 20.0s | 4 | 2 | 23.8s |
| YA LIRE | 0→9 | 7 | 0.1 | 1 | 0 | 4 | 3 | 0 | 20% | 20.0s | 6 | 2 | 23.5s |
| ZO ZUTU | 0→7 | 5 | 0.0 | 1 | 0 | 4 | 3 | 0 | 20% | 20.0s | 4 | 2 | 23.4s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 4 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 4

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| HU JAVU | — | — | 17% | — | 0.0→0.1→0.1 | 25.0s |
| SO HOCI | — | — | 20% | — | 0.0→0.2→0.1 | 20.0s |
| YA LIRE | — | — | 20% | — | 0.0→0.2→0.1 | 20.0s |
| ZO ZUTU | — | — | 20% | — | 0.0→0.0→0.0 | 20.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| HU JAVU | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| SO HOCI | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| YA LIRE | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| ZO ZUTU | 1 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| HU JAVU | 0 | 6 | 4 | 22.5s |
| SO HOCI | 0 | 4 | 4 | 22.4s |
| YA LIRE | 0 | 6 | 6 | 22.4s |
| ZO ZUTU | 0 | 4 | 4 | 22.3s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| HU JAVU | 0 | 0 | — | 0 | 0 | party 40%, hunt 24%, gather 20% |
| SO HOCI | 0 | 0 | — | 0 | 0 | party 40%, hunt 23%, gather 19% |
| YA LIRE | 0 | 0 | — | 0 | 0 | party 38%, hunt 22%, gather 21% |
| ZO ZUTU | 0 | 0 | — | 0 | 0 | party 38%, hunt 17%, wander 15% |

## Economy (session)

- **Items gathered:** 15
- **Items deposited:** 16
- **Deposit yield:** 107%
- **Gather failures (all):** 0
- **Gather failures (actionable):** 0
- **Deposit failures:** 0

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 8 | 6 | 75% |
| Fiber | 3 | 2 | 67% |
| Mushroom | 1 | 0 | 0% |
| Spear | 0 | 8 | — |
| Stone | 3 | 0 | 0% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 8

### By source

- **herder_hut:** 8

### Chronological

- t=0.3s **ZO ZUTU** — Living Hut (herder_hut) builder=QUDU @ (1782,-811)
- t=0.3s **ZO ZUTU** — Living Hut (herder_hut) builder=QUDU @ (1591,-928)
- t=0.4s **SO HOCI** — Living Hut (herder_hut) builder=KUCE @ (-138,3030)
- t=0.4s **SO HOCI** — Living Hut (herder_hut) builder=KUCE @ (-331,2914)
- t=0.4s **YA LIRE** — Living Hut (herder_hut) builder=JEOJ @ (-1963,405)
- t=0.4s **YA LIRE** — Living Hut (herder_hut) builder=JEOJ @ (-1935,360)
- t=0.5s **HU JAVU** — Living Hut (herder_hut) builder=FIKA @ (-1467,-3102)
- t=0.5s **HU JAVU** — Living Hut (herder_hut) builder=FIKA @ (-1419,-3172)

## Per-clan detail

### HU JAVU

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (17% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 2 | 2 |
| Spear | 0 | 3 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CUNU | 0 | 0 | 0 | 0 | party 87%, gather 13% |
| FEIQ | 0 | 0 | 0 | 0 | combat 59%, hunt 41% |
| FIKA | 0 | 0 | 3 | 2 | gather 39%, hunt 34%, wander 26% |
| WAZE | 0 | 0 | 1 | 0 | party 87%, gather 13% |
| XOOR | 0 | 0 | 1 | 0 | hunt 88%, combat 12% |

#### Hunts

- start t=27.0s prey=deer quota=3

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: FIKA)
- t=0.5s **Living Hut** — herder_hut (builder: FIKA)

### SO HOCI

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 2 |
| Spear | 0 | 3 |
| Stone | 2 | 0 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DUSI | 0 | 0 | 1 | 0 | hunt 82%, combat 11%, gather 7% |
| FAAB | 0 | 0 | 0 | 0 | party 96%, gather 4% |
| HENU | 0 | 0 | 0 | 0 | party 96%, gather 4% |
| KUCE | 0 | 0 | 3 | 5 | gather 49%, wander 25%, hunt 24% |
| VAKA | 0 | 0 | 1 | 0 | hunt 39%, combat 34%, wander 20% |

#### Hunts

- start t=23.8s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: KUCE)
- t=0.4s **Living Hut** — herder_hut (builder: KUCE)

### YA LIRE

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 2 |
| Mushroom | 1 | 0 |
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FIMU | 0 | 0 | 0 | 0 | gather 100% |
| JEOJ | 0 | 0 | 3 | 4 | gather 52%, hunt 32%, wander 14% |
| KEZO | 0 | 0 | 0 | 0 | party 78%, wander 19%, herd_wildnpc 2% |
| LIIH | 0 | 0 | 0 | 0 | gather 75%, hunt 25% |
| MECU | 0 | 0 | 0 | 0 | hunt 68%, combat 28%, gather 4% |
| REOG | 0 | 0 | 0 | 0 | party 97%, gather 3% |
| XACO | 0 | 0 | 0 | 0 | combat 57%, hunt 40%, gather 4% |

#### Hunts

- start t=23.5s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: JEOJ)
- t=0.4s **Living Hut** — herder_hut (builder: JEOJ)

### ZO ZUTU

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 2 |
| Spear | 0 | 1 |
| Stone | 1 | 0 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GAHO | 0 | 0 | 0 | 0 | combat 90%, hunt 10% |
| MIEH | 0 | 0 | 0 | 0 | party 97%, herd_wildnpc 3% |
| QUDU | 0 | 0 | 2 | 4 | gather 47%, hunt 30%, wander 21% |
| SEIW | 0 | 0 | 0 | 0 | hunt 44%, wander 34%, combat 21% |
| WADO | 0 | 0 | 0 | 0 | party 81%, wander 15%, gather 2% |

#### Hunts

- start t=23.4s prey=deer quota=3

#### Buildings

- t=0.3s **Living Hut** — herder_hut (builder: QUDU)
- t=0.3s **Living Hut** — herder_hut (builder: QUDU)

