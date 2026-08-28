# ClanBrain Report (standard)

## Session

- **Duration:** 120.7s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/party_hunt_test_20260526_225545/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| KE ZEZI | 0→15 | 11 | 0.1 | 0 | 0 | 85 | 28 | 2 | 80% | 20.0s | 10 | 2 | — |
| MA QAEP | 0→12 | 9 | 0.3 | 0 | 0 | 34 | 22 | 0 | 59% | 20.0s | 8 | 2 | — |
| NE ZIZI | 0→18 | 11 | 0.1 | 0 | 0 | 72 | 22 | 3 | 77% | 20.0s | 12 | 2 | — |
| RE DIAW | 0→16 | 13 | 0.2 | 0 | 0 | 67 | 34 | 6 | 76% | 25.0s | 12 | 2 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| KE ZEZI | — | — | 80% | — | 0.0→0.1→0.1 | 20.0s |
| MA QAEP | — | — | 59% | — | 0.0→0.3→0.3 | 20.0s |
| NE ZIZI | — | — | 77% | — | 0.0→0.1→0.1 | 20.0s |
| RE DIAW | — | — | 76% | — | 0.0→0.2→0.2 | 25.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| KE ZEZI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MA QAEP | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| NE ZIZI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| RE DIAW | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| KE ZEZI | 0 | 12 | 10 | 22.5s |
| MA QAEP | 0 | 8 | 8 | 22.4s |
| NE ZIZI | 0 | 12 | 12 | 22.4s |
| RE DIAW | 0 | 12 | 12 | 22.4s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| KE ZEZI | 0 | 0 | — | 0 | 6 | gather 80%, wander 11%, idle 9% |
| MA QAEP | 0 | 0 | — | 0 | 1 | gather 46%, herd_wildnpc 27%, wander 27% |
| NE ZIZI | 0 | 0 | — | 0 | 4 | gather 58%, herd_wildnpc 32%, wander 10% |
| RE DIAW | 0 | 0 | — | 0 | 1 | gather 62%, herd_wildnpc 25%, wander 10% |

## Economy (session)

- **Items gathered:** 258
- **Items deposited:** 106
- **Deposit yield:** 41%
- **Gather failures (all):** 141
- **Gather failures (actionable):** 11
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 6
- **not_harvestable:** 6
- **resource_invalid:** 5

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 18 | 6 | 33% |
| Fiber | 12 | 3 | 25% |
| Grain | 18 | 2 | 11% |
| Mushroom | 2 | 0 | 0% |
| Nuts | 33 | 10 | 30% |
| Spear | 0 | 20 | — |
| Stone | 14 | 0 | 0% |
| Wood | 161 | 65 | 40% |

## Buildings (session)

- **Total placed:** 8

### By type

- **Living Hut:** 8

### By source

- **herder_hut:** 8

### Chronological

- t=0.3s **NE ZIZI** — Living Hut (herder_hut) builder=DIQA @ (3049,-6)
- t=0.3s **NE ZIZI** — Living Hut (herder_hut) builder=DIQA @ (3007,38)
- t=0.4s **MA QAEP** — Living Hut (herder_hut) builder=YIIS @ (-665,3442)
- t=0.4s **MA QAEP** — Living Hut (herder_hut) builder=YIIS @ (-589,3362)
- t=0.4s **RE DIAW** — Living Hut (herder_hut) builder=PUIN @ (-2837,-906)
- t=0.4s **RE DIAW** — Living Hut (herder_hut) builder=PUIN @ (-3002,-1065)
- t=0.4s **KE ZEZI** — Living Hut (herder_hut) builder=REIC @ (597,-2160)
- t=0.5s **KE ZEZI** — Living Hut (herder_hut) builder=REIC @ (684,-1937)

## Per-clan detail

### KE ZEZI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (80% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 0 |
| Fiber | 3 | 0 |
| Grain | 12 | 0 |
| Nuts | 10 | 3 |
| Spear | 0 | 3 |
| Stone | 2 | 0 |
| Wood | 52 | 22 |

#### Failures

- **Gather:** inventory_full=102, empty_switch:not_harvestable=2, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CELI | 0 | 0 | 0 | 4 | gather 100% |
| CEOF | 0 | 0 | 2 | 7 | gather 83%, wander 17%, idle 0% |
| DUUV | 0 | 0 | 0 | 2 | gather 100% |
| HEIG | 0 | 0 | 1 | 11 | gather 87%, wander 13% |
| LOEZ | 0 | 0 | 0 | 9 | gather 61%, idle 39%, wander 0% |
| REIC | 0 | 0 | 7 | 12 | gather 59%, wander 41%, herd_wildnpc 0% |
| SOLI | 0 | 0 | 0 | 9 | gather 100% |
| VAIS | 0 | 0 | 0 | 9 | gather 88%, wander 12% |
| VEOM | 0 | 0 | 0 | 9 | gather 73%, idle 27%, wander 1% |
| WOZO | 0 | 0 | 0 | 9 | gather 88%, idle 11%, wander 1% |
| ZUIT | 0 | 0 | 0 | 4 | gather 100% |

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: REIC)
- t=0.5s **Living Hut** — herder_hut (builder: REIC)

### MA QAEP

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/3 (59% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.3 → 0.3

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 2 |
| Grain | 3 | 2 |
| Nuts | 4 | 2 |
| Spear | 0 | 5 |
| Stone | 4 | 0 |
| Wood | 20 | 11 |

#### Failures

- **Gather:** inventory_full=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIIF | 0 | 0 | 1 | 0 | herd_wildnpc 93%, gather 5%, wander 2% |
| COUZ | 0 | 0 | 0 | 0 | herd_wildnpc 93%, gather 5%, wander 2% |
| NOLU | 0 | 0 | 2 | 10 | gather 84%, wander 16% |
| ROIB | 0 | 0 | 0 | 5 | gather 100% |
| WIIV | 0 | 0 | 1 | 4 | wander 78%, herd_wildnpc 19%, gather 4% |
| WUCA | 0 | 0 | 0 | 0 | gather 100% |
| YIIS | 0 | 0 | 4 | 6 | gather 58%, wander 42% |
| ZIPE | 0 | 0 | 1 | 0 | gather 65%, wander 29%, idle 6% |
| ZOEV | 0 | 0 | 0 | 9 | gather 100% |

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: YIIS)
- t=0.4s **Living Hut** — herder_hut (builder: YIIS)

### NE ZIZI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (77% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Fiber | 6 | 0 |
| Mushroom | 1 | 0 |
| Nuts | 9 | 3 |
| Spear | 0 | 4 |
| Stone | 8 | 0 |
| Wood | 45 | 15 |

#### Failures

- **Gather:** inventory_full=21, empty_switch:not_harvestable=2, resource_invalid=2, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAEM | 0 | 0 | 0 | 2 | herd_wildnpc 87%, gather 13%, wander 0% |
| DIQA | 0 | 0 | 8 | 16 | gather 59%, wander 39%, herd_wildnpc 1% |
| FUUM | 0 | 0 | 1 | 13 | gather 89%, wander 11%, herd_wildnpc 0% |
| FUVI | 0 | 0 | 0 | 0 | gather 100% |
| JISO | 0 | 0 | 0 | 3 | herd_wildnpc 94%, gather 6%, wander 0% |
| LEJU | 0 | 0 | 0 | 9 | gather 88%, wander 12% |
| LIXO | 0 | 0 | 1 | 0 | gather 77%, herd_wildnpc 23% |
| PIAR | 0 | 0 | 0 | 9 | gather 69%, herd_wildnpc 23%, wander 8% |
| ROZO | 0 | 0 | 0 | 9 | gather 88%, wander 12% |
| TERU | 0 | 0 | 0 | 0 | gather 100% |
| YUKO | 0 | 0 | 1 | 0 | herd_wildnpc 95%, gather 5% |
| ZEPA | 0 | 0 | 0 | 2 | gather 100% |
| ZUHE | 0 | 0 | 0 | 9 | gather 100% |

#### Buildings

- t=0.3s **Living Hut** — herder_hut (builder: DIQA)
- t=0.3s **Living Hut** — herder_hut (builder: DIQA)

### RE DIAW

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (76% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 4 |
| Fiber | 3 | 3 |
| Grain | 3 | 0 |
| Mushroom | 1 | 0 |
| Nuts | 10 | 2 |
| Spear | 0 | 8 |
| Wood | 44 | 17 |

#### Failures

- **Gather:** not_harvestable=5, empty_switch:not_harvestable=2, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CIIW | 0 | 0 | 0 | 9 | gather 100% |
| FAEB | 0 | 0 | 0 | 0 | gather 78%, wander 21%, idle 2% |
| KOPU | 0 | 0 | 1 | 3 | gather 95%, wander 4%, idle 1% |
| MAIB | 0 | 0 | 1 | 3 | herd_wildnpc 67%, gather 33%, wander 0% |
| NUJU | 0 | 0 | 1 | 5 | gather 55%, herd_wildnpc 25%, wander 19% |
| PUIN | 0 | 0 | 7 | 19 | gather 65%, wander 35% |
| SOEP | 0 | 0 | 0 | 6 | gather 100% |
| TEOQ | 0 | 0 | 2 | 12 | gather 74%, wander 25%, herd_wildnpc 1% |
| TIFO | 0 | 0 | 1 | 2 | gather 57%, herd_wildnpc 42%, wander 1% |
| VOIG | 0 | 0 | 1 | 0 | gather 65%, herd_wildnpc 34%, wander 1% |
| WEGI | 0 | 0 | 0 | 8 | gather 66%, idle 24%, herd_wildnpc 10% |
| XEZE | 0 | 0 | 1 | 0 | herd_wildnpc 81%, gather 18%, wander 0% |
| YIVU | 0 | 0 | 0 | 0 | gather 100% |

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: PUIN)
- t=0.4s **Living Hut** — herder_hut (builder: PUIN)

