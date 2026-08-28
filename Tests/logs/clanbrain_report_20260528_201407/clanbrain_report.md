# ClanBrain Report (standard)

## Session

- **Duration:** 300.3s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_20260528_201407/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| CO ROOF | 0→22 | 16 | 0.1 | 0 | 0 | 163 | 93 | 5 | 82% | 85.1s | 15 | 3 | — |
| GO PUPI | 0→13 | 11 | 1.2 | 0 | 0 | 134 | 103 | 5 | 70% | 110.1s | 10 | 2 | — |
| QE NIXU | 0→21 | 13 | 0.1 | 0 | 0 | 116 | 64 | 3 | 70% | 90.1s | 12 | 4 | — |
| ZA MEAB | 0→1 | 1 | 0.0 | 0 | 0 | 0 | 1 | 0 | 97% | 300.0s | 0 | 0 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| CO ROOF | 83% | 17% | 81% | 17% | 0.0→0.1→0.1 | 85.1s |
| GO PUPI | — | — | 70% | 12% | 0.0→1.2→1.2 | 110.1s |
| QE NIXU | — | — | 70% | 17% | 0.0→0.1→0.1 | 90.1s |
| ZA MEAB | — | — | 97% | 3% | 0.0→0.0→0.0 | 300.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| CO ROOF | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| GO PUPI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| QE NIXU | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| ZA MEAB | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| CO ROOF | 3 | 15 | 15 | 83.9s |
| GO PUPI | 2 | 10 | 10 | 109.3s |
| QE NIXU | 3 | 12 | 12 | 89.7s |
| ZA MEAB | 0 | 0 | 0 | — |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| CO ROOF | 0 | 0 | — | 0 | 7 | gather 52%, herd_wildnpc 19%, wander 17% |
| GO PUPI | 0 | 0 | — | 0 | 9 | gather 67%, wander 17%, herd_wildnpc 6% |
| QE NIXU | 0 | 0 | — | 0 | 5 | gather 46%, herd_wildnpc 28%, wander 20% |
| ZA MEAB | 0 | 0 | — | 0 | 0 | agro 44%, wander 42%, herd_wildnpc 13% |

## Economy (session)

- **Items gathered:** 413
- **Items deposited:** 261
- **Deposit yield:** 63%
- **Gather failures (all):** 486
- **Gather failures (actionable):** 13
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 19
- **resource_invalid:** 9
- **not_harvestable:** 4

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 18 | 16 | 89% |
| Fiber | 19 | 15 | 79% |
| Grain | 20 | 9 | 45% |
| Mushroom | 5 | 1 | 20% |
| Nuts | 56 | 16 | 29% |
| Spear | 0 | 30 | — |
| Stone | 19 | 16 | 84% |
| Wood | 276 | 158 | 57% |

## Buildings (session)

- **Total placed:** 9

### By type

- **Living Hut:** 8
- **Dairy Farm:** 1

### By source

- **herder_hut:** 8
- **milestone:** 1

### Chronological

- t=51.4s **CO ROOF** — Living Hut (herder_hut) builder=QOBE @ (1964,-272)
- t=57.2s **QE NIXU** — Living Hut (herder_hut) builder=HUOR @ (-2119,490)
- t=76.8s **GO PUPI** — Living Hut (herder_hut) builder=CUDA @ (816,1895)
- t=86.1s **CO ROOF** — Living Hut (herder_hut) builder=QOBE @ (2017,-313)
- t=137.4s **QE NIXU** — Living Hut (herder_hut) builder=GIQI @ (-2294,365)
- t=179.7s **QE NIXU** — Living Hut (herder_hut) builder=MESA @ (-2067,434)
- t=182.2s **CO ROOF** — Living Hut (herder_hut) builder=GIEP @ (1841,-475)
- t=194.7s **GO PUPI** — Living Hut (herder_hut) builder=QOYI @ (779,1958)
- t=274.0s **QE NIXU** — Dairy Farm (milestone) @ (-2250,290)

## Per-clan detail

### CO ROOF

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (83% fill) | searchers 4/4 (81% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 6 | 5 |
| Grain | 6 | 2 |
| Mushroom | 1 | 1 |
| Nuts | 21 | 2 |
| Spear | 0 | 11 |
| Stone | 12 | 9 |
| Wood | 117 | 63 |

#### Failures

- **Gather:** inventory_full=185, empty_switch:not_harvestable=10, resource_invalid=3, not_harvestable=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAFI | 0 | 0 | 1 | 14 | gather 70%, wander 30%, idle 0% |
| FAFA | 0 | 0 | 2 | 14 | herd_wildnpc 46%, gather 32%, wander 18% |
| FOOX | 0 | 0 | 1 | 9 | gather 48%, herd_wildnpc 29%, wander 23% |
| GIEP | 0 | 0 | 1 | 10 | gather 41%, herd_wildnpc 40%, build_hut_for_woman 15% |
| JOJI | 0 | 0 | 3 | 25 | gather 66%, wander 20%, herd_wildnpc 11% |
| LINI | 0 | 0 | 1 | 0 | gather 100% |
| PUIN | 0 | 0 | 0 | 6 | gather 100% |
| QABO | 0 | 0 | 0 | 2 | gather 100% |
| QOBE | 0 | 0 | 6 | 18 | wander 34%, gather 31%, herd_wildnpc 21% |
| SETI | 0 | 0 | 1 | 10 | combat 65%, gather 23%, wander 6% |
| SOAN | 0 | 0 | 0 | 0 | wander 52%, gather 45%, idle 3% |
| VEAK | 0 | 0 | 0 | 9 | gather 67%, herd_wildnpc 30%, wander 2% |
| WIRE | 0 | 0 | 1 | 13 | gather 85%, wander 14%, herd_wildnpc 0% |
| WUFE | 0 | 0 | 1 | 13 | gather 71%, wander 27%, idle 1% |
| ZEYE | 0 | 0 | 0 | 7 | gather 100% |
| ZOAC | 0 | 0 | 2 | 13 | gather 49%, herd_wildnpc 31%, wander 20% |

#### Buildings

- t=51.4s **Living Hut** — herder_hut (builder: QOBE)
- t=86.1s **Living Hut** — herder_hut (builder: QOBE)
- t=182.2s **Living Hut** — herder_hut (builder: GIEP)

### GO PUPI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (70% fill)
- **Pressure:** defend 0.12 | search 0.41 | gather 0.47
- **Food days buffer:** 0.0 → 1.2 → 1.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 18 | 16 |
| Fiber | 8 | 8 |
| Grain | 12 | 7 |
| Mushroom | 2 | 0 |
| Nuts | 15 | 8 |
| Spear | 0 | 7 |
| Stone | 6 | 6 |
| Wood | 73 | 51 |

#### Failures

- **Gather:** inventory_full=113, empty_switch:not_harvestable=6, resource_invalid=3, not_harvestable=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CUDA | 0 | 0 | 14 | 39 | gather 44%, wander 25%, herd_wildnpc 15% |
| DUVO | 0 | 0 | 1 | 8 | gather 83%, wander 17% |
| FAWO | 0 | 0 | 1 | 15 | gather 69%, wander 18%, craft 13% |
| LOIQ | 0 | 0 | 2 | 18 | gather 77%, wander 23%, idle 0% |
| MAIF | 0 | 0 | 4 | 13 | gather 82%, craft 17%, wander 1% |
| PURU | 0 | 0 | 0 | 9 | gather 96%, craft 3%, wander 1% |
| QOYI | 0 | 0 | 1 | 9 | gather 46%, herd_wildnpc 22%, wander 19% |
| RICU | 0 | 0 | 0 | 0 | craft 100% |
| RUAD | 0 | 0 | 0 | 1 | gather 100% |
| SUDU | 0 | 0 | 3 | 22 | gather 86%, wander 14% |
| XOVE | 0 | 0 | 0 | 0 | craft 100% |

#### Buildings

- t=76.8s **Living Hut** — herder_hut (builder: CUDA)
- t=194.7s **Living Hut** — herder_hut (builder: QOYI)

### QE NIXU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (70% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 5 | 2 |
| Grain | 2 | 0 |
| Mushroom | 2 | 0 |
| Nuts | 20 | 6 |
| Spear | 0 | 11 |
| Stone | 1 | 1 |
| Wood | 86 | 44 |

#### Failures

- **Gather:** inventory_full=156, empty_switch:not_harvestable=3, resource_invalid=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FOZE | 0 | 0 | 0 | 4 | gather 100% |
| GEGU | 0 | 0 | 1 | 9 | gather 59%, herd_wildnpc 26%, wander 15% |
| GIJA | 0 | 0 | 1 | 4 | gather 100% |
| GIQI | 0 | 0 | 1 | 18 | gather 65%, herd_wildnpc 18%, build_hut_for_woman 9% |
| HUOR | 0 | 0 | 8 | 17 | wander 57%, gather 25%, herd_wildnpc 9% |
| JAAH | 0 | 0 | 1 | 14 | gather 49%, herd_wildnpc 26%, idle 19% |
| JOUR | 0 | 0 | 1 | 0 | wander 69%, gather 28%, idle 2% |
| MESA | 0 | 0 | 0 | 9 | herd_wildnpc 60%, gather 28%, build_hut_for_woman 11% |
| POIL | 0 | 0 | 1 | 9 | gather 44%, herd_wildnpc 39%, wander 17% |
| QIIV | 0 | 0 | 1 | 10 | gather 77%, wander 22%, idle 1% |
| REAP | 0 | 0 | 1 | 0 | herd_wildnpc 84%, wander 9%, gather 7% |
| REVE | 0 | 0 | 1 | 12 | gather 73%, wander 26%, idle 0% |
| ZONI | 0 | 0 | 1 | 10 | herd_wildnpc 58%, gather 34%, wander 8% |

#### Buildings

- t=57.2s **Living Hut** — herder_hut (builder: HUOR)
- t=137.4s **Living Hut** — herder_hut (builder: GIQI)
- t=179.7s **Living Hut** — herder_hut (builder: MESA)
- t=274.0s **Dairy Farm** — milestone

### ZA MEAB

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (97% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| ZUPI | 0 | 0 | 1 | 0 | agro 44%, wander 42%, herd_wildnpc 13% |

