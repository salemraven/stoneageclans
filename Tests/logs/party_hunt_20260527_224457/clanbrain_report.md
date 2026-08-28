# ClanBrain Report (standard)

## Session

- **Duration:** 300.5s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/party_hunt_20260527_224457/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| DA YASO | 0→15 | 9 | 0.3 | 0 | 0 | 75 | 42 | 5 | 82% | 90.8s | 8 | 3 | — |
| GA SERU | 0→19 | 13 | 0.2 | 0 | 0 | 122 | 90 | 5 | 85% | 90.8s | 12 | 3 | — |
| JA GIEM | 0→15 | 12 | 0.2 | 0 | 0 | 103 | 67 | 6 | 71% | 85.8s | 12 | 2 | — |
| LI ZETA | 0→13 | 9 | 0.2 | 0 | 0 | 51 | 22 | 6 | 66% | 95.8s | 8 | 3 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| DA YASO | — | — | 82% | 20% | 0.0→0.3→0.3 | 90.8s |
| GA SERU | — | — | 85% | 12% | 0.0→0.2→0.2 | 90.8s |
| JA GIEM | — | — | 71% | 17% | 0.0→0.2→0.2 | 85.8s |
| LI ZETA | — | — | 66% | 17% | 0.0→0.5→0.2 | 95.8s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| DA YASO | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| GA SERU | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| JA GIEM | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| LI ZETA | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| DA YASO | 2 | 8 | 8 | 90.0s |
| GA SERU | 2 | 12 | 12 | 91.5s |
| JA GIEM | 2 | 12 | 12 | 87.7s |
| LI ZETA | 3 | 9 | 8 | 96.5s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| DA YASO | 0 | 0 | — | 0 | 6 | gather 42%, herd_wildnpc 28%, wander 17% |
| GA SERU | 0 | 0 | — | 0 | 10 | gather 48%, herd_wildnpc 25%, wander 18% |
| JA GIEM | 0 | 0 | — | 0 | 8 | gather 67%, wander 18%, idle 9% |
| LI ZETA | 0 | 0 | — | 0 | 3 | gather 50%, craft 26%, wander 10% |

## Economy (session)

- **Items gathered:** 351
- **Items deposited:** 221
- **Deposit yield:** 63%
- **Gather failures (all):** 134
- **Gather failures (actionable):** 22
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 19
- **not_harvestable:** 17
- **resource_invalid:** 5

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 30 | 13 | 43% |
| Fiber | 21 | 12 | 57% |
| Mushroom | 3 | 2 | 67% |
| Nuts | 51 | 15 | 29% |
| Spear | 0 | 30 | — |
| Stone | 36 | 14 | 39% |
| Wood | 210 | 135 | 64% |

## Buildings (session)

- **Total placed:** 11

### By type

- **Living Hut:** 9
- **Dairy Farm:** 1
- **Farm:** 1

### By source

- **herder_hut:** 9
- **milestone:** 2

### Chronological

- t=42.6s **DA YASO** — Living Hut (herder_hut) builder=TAIZ @ (2936,-1529)
- t=51.0s **LI ZETA** — Living Hut (herder_hut) builder=TESO @ (536,-3182)
- t=55.2s **JA GIEM** — Living Hut (herder_hut) builder=YIJE @ (-332,3235)
- t=59.0s **GA SERU** — Living Hut (herder_hut) builder=TUFE @ (-2505,97)
- t=113.6s **GA SERU** — Living Hut (herder_hut) builder=TUFE @ (-2322,240)
- t=157.6s **DA YASO** — Living Hut (herder_hut) builder=TAIZ @ (2697,-1554)
- t=166.9s **JA GIEM** — Living Hut (herder_hut) builder=NUAX @ (-137,3341)
- t=223.3s **LI ZETA** — Living Hut (herder_hut) builder=MINI @ (491,-3152)
- t=233.4s **GA SERU** — Farm (milestone) @ (-2543,147)
- t=241.7s **LI ZETA** — Living Hut (herder_hut) builder=SIPO @ (335,-3303)
- t=252.2s **DA YASO** — Dairy Farm (milestone) @ (2719,-1606)

## Per-clan detail

### DA YASO

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (82% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.3 → 0.3

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 12 | 6 |
| Fiber | 3 | 3 |
| Mushroom | 1 | 1 |
| Nuts | 11 | 2 |
| Spear | 0 | 7 |
| Stone | 11 | 8 |
| Wood | 37 | 15 |

#### Failures

- **Gather:** inventory_full=14, empty_switch:not_harvestable=6, not_harvestable=3, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GAOD | 0 | 0 | 1 | 4 | wander 53%, gather 47%, herd_wildnpc 0% |
| NAEL | 0 | 0 | 1 | 6 | gather 76%, wander 18%, combat 6% |
| PUPI | 0 | 0 | 2 | 16 | herd_wildnpc 45%, wander 29%, gather 22% |
| SIMU | 0 | 0 | 1 | 11 | gather 79%, wander 21%, idle 0% |
| TAIZ | 0 | 0 | 2 | 5 | herd_wildnpc 57%, gather 20%, build_hut_for_woman 13% |
| TOKE | 0 | 0 | 0 | 9 | gather 39%, idle 34%, craft 13% |
| ZAZA | 0 | 0 | 2 | 8 | herd_wildnpc 51%, gather 29%, wander 20% |
| ZIAQ | 0 | 0 | 1 | 7 | gather 73%, craft 16%, wander 10% |
| ZIEP | 0 | 0 | 0 | 9 | gather 71%, craft 23%, wander 6% |

#### Buildings

- t=42.6s **Living Hut** — herder_hut (builder: TAIZ)
- t=157.6s **Living Hut** — herder_hut (builder: TAIZ)
- t=252.2s **Dairy Farm** — milestone

### GA SERU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (85% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Fiber | 3 | 3 |
| Mushroom | 1 | 1 |
| Nuts | 25 | 8 |
| Spear | 0 | 11 |
| Stone | 3 | 3 |
| Wood | 87 | 64 |

#### Failures

- **Gather:** inventory_full=47, empty_switch:not_harvestable=5, not_harvestable=4, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DOPU | 0 | 0 | 1 | 9 | herd_wildnpc 48%, gather 36%, wander 16% |
| GEOH | 0 | 0 | 2 | 19 | gather 44%, herd_wildnpc 30%, wander 27% |
| HEID | 0 | 0 | 0 | 0 | herd_wildnpc 77%, gather 23% |
| JIUS | 0 | 0 | 2 | 13 | gather 78%, wander 22%, herd_wildnpc 0% |
| KACO | 0 | 0 | 1 | 9 | gather 86%, wander 13%, idle 1% |
| KOGI | 0 | 0 | 1 | 9 | gather 77%, wander 23% |
| KOQA | 0 | 0 | 1 | 3 | herd_wildnpc 83%, gather 17% |
| MEAX | 0 | 0 | 2 | 11 | gather 81%, wander 19% |
| RIIM | 0 | 0 | 0 | 9 | idle 60%, gather 40%, wander 0% |
| SIUG | 0 | 0 | 2 | 14 | gather 77%, wander 23%, idle 0% |
| TUFE | 0 | 0 | 7 | 17 | wander 31%, herd_wildnpc 29%, gather 26% |
| TUUC | 0 | 0 | 1 | 4 | herd_wildnpc 67%, gather 29%, wander 4% |
| YUYA | 0 | 0 | 1 | 5 | gather 71%, wander 28%, idle 2% |

#### Buildings

- t=59.0s **Living Hut** — herder_hut (builder: TUFE)
- t=113.6s **Living Hut** — herder_hut (builder: TUFE)
- t=233.4s **Farm** — milestone

### JA GIEM

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (71% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 2 |
| Fiber | 6 | 3 |
| Nuts | 13 | 4 |
| Spear | 0 | 9 |
| Stone | 10 | 0 |
| Wood | 71 | 49 |

#### Failures

- **Gather:** inventory_full=17, empty_switch:not_harvestable=7, not_harvestable=6

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DEEJ | 0 | 0 | 0 | 3 | gather 100% |
| DOTE | 0 | 0 | 1 | 8 | gather 78%, wander 21%, idle 1% |
| HIUN | 0 | 0 | 1 | 10 | gather 78%, wander 21%, idle 0% |
| KIOG | 0 | 0 | 1 | 10 | gather 80%, wander 20% |
| KOZI | 0 | 0 | 2 | 17 | gather 88%, wander 12% |
| LUIX | 0 | 0 | 0 | 2 | gather 100% |
| NUAX | 0 | 0 | 1 | 7 | idle 71%, gather 13%, build_hut_for_woman 11% |
| POOZ | 0 | 0 | 0 | 1 | gather 100% |
| PUSU | 0 | 0 | 2 | 16 | gather 73%, wander 18%, herd_wildnpc 9% |
| SUER | 0 | 0 | 1 | 12 | gather 81%, wander 18%, idle 0% |
| VIIP | 0 | 0 | 1 | 0 | gather 100% |
| VIOF | 0 | 0 | 0 | 0 | gather 100% |
| YIJE | 0 | 0 | 8 | 17 | gather 51%, wander 31%, herd_wildnpc 10% |

#### Buildings

- t=55.2s **Living Hut** — herder_hut (builder: YIJE)
- t=166.9s **Living Hut** — herder_hut (builder: NUAX)

### LI ZETA

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (66% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.5 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 12 | 5 |
| Fiber | 9 | 3 |
| Mushroom | 1 | 0 |
| Nuts | 2 | 1 |
| Spear | 0 | 3 |
| Stone | 12 | 3 |
| Wood | 15 | 7 |

#### Failures

- **Gather:** inventory_full=15, not_harvestable=4, resource_invalid=2, empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GAAZ | 0 | 0 | 0 | 1 | gather 100% |
| HEXO | 0 | 0 | 0 | 4 | gather 100% |
| JOIS | 0 | 0 | 0 | 4 | craft 56%, gather 43%, wander 1% |
| MINI | 0 | 0 | 0 | 9 | craft 52%, gather 32%, build_hut_for_woman 11% |
| SIPO | 0 | 0 | 1 | 18 | gather 63%, wander 19%, herd_wildnpc 9% |
| SONI | 0 | 0 | 0 | 0 | gather 100% |
| TEMU | 0 | 0 | 0 | 0 | herd_wildnpc 87%, gather 12%, wander 2% |
| TESO | 0 | 0 | 5 | 15 | gather 40%, craft 27%, wander 17% |
| VOIV | 0 | 0 | 1 | 0 | gather 70%, combat 30% |

#### Buildings

- t=51.0s **Living Hut** — herder_hut (builder: TESO)
- t=223.3s **Living Hut** — herder_hut (builder: MINI)
- t=241.7s **Living Hut** — herder_hut (builder: SIPO)

