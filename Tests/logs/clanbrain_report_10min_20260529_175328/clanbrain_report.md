# ClanBrain Report (standard)

## Session

- **Duration:** 600.5s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_10min_20260529_175328/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 10 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| NI ROWE | 0→27 | 19 | 0.0 | 0 | 0 | 214 | 78 | 8 | 86% | 135.1s | 18 | 4 | — |
| NO FEKI | 0→58 | 48 | 0.0 | 0 | 0 | 358 | 94 | 38 | 85% | 65.1s | 48 | 5 | — |
| VI MAJI | 0→20 | 15 | 0.0 | 0 | 0 | 231 | 155 | 3 | 47% | 85.1s | 14 | 2 | — |
| YE KUUL | 0→27 | 17 | 0.0 | 1 | 0 | 123 | 73 | 8 | 86% | 75.1s | 16 | 4 | 76.9s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 1 / 1
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| NI ROWE | — | — | 86% | 12% | 0.0→0.0→0.0 | 135.1s |
| NO FEKI | — | — | 85% | 50% | 0.0→0.8→0.0 | 65.1s |
| VI MAJI | — | — | 47% | 17% | 0.0→0.3→0.0 | 85.1s |
| YE KUUL | — | — | 86% | 20% | 0.0→0.0→0.0 | 75.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| NI ROWE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| NO FEKI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| VI MAJI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| YE KUUL | 1 | 0 | 1 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| NI ROWE | 4 | 18 | 18 | 135.7s |
| NO FEKI | 4 | 51 | 48 | 65.5s |
| VI MAJI | 1 | 15 | 14 | 88.2s |
| YE KUUL | 3 | 18 | 16 | 75.6s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| NI ROWE | 0 | 0 | — | 0 | 21 | idle 43%, gather 35%, herd_wildnpc 9% |
| NO FEKI | 0 | 0 | — | 0 | 43 | idle 40%, gather 38%, herd_wildnpc 6% |
| VI MAJI | 0 | 0 | — | 0 | 6 | idle 41%, gather 23%, herd_wildnpc 21% |
| YE KUUL | 0 | 0 | — | 0 | 17 | combat 25%, idle 22%, herd_wildnpc 20% |

## Economy (session)

- **Items gathered:** 926
- **Items deposited:** 400
- **Deposit yield:** 43%
- **Gather failures (all):** 259
- **Gather failures (actionable):** 57
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 63
- **not_harvestable:** 47
- **resource_invalid:** 10

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 54 | 17 | 31% |
| Fiber | 60 | 30 | 50% |
| Grain | 42 | 4 | 10% |
| Mushroom | 4 | 1 | 25% |
| Nuts | 129 | 18 | 14% |
| Spear | 0 | 54 | — |
| Stone | 63 | 27 | 43% |
| Wood | 574 | 249 | 43% |

## Buildings (session)

- **Total placed:** 15

### By type

- **Living Hut:** 10
- **Dairy Farm:** 2
- **Farm:** 2
- **Oven:** 1

### By source

- **herder_hut:** 10
- **milestone:** 5

### Chronological

- t=33.0s **NO FEKI** — Living Hut (herder_hut) builder=SUXE @ (-374,-2774)
- t=43.1s **YE KUUL** — Living Hut (herder_hut) builder=TIFE @ (-2392,-143)
- t=55.7s **VI MAJI** — Living Hut (herder_hut) builder=BEFE @ (1378,2758)
- t=63.2s **YE KUUL** — Living Hut (herder_hut) builder=TIFE @ (-2547,-291)
- t=103.2s **NI ROWE** — Living Hut (herder_hut) builder=NICE @ (3271,407)
- t=165.1s **NO FEKI** — Living Hut (herder_hut) builder=TUXU @ (-304,-2862)
- t=185.7s **NO FEKI** — Living Hut (herder_hut) builder=TUXU @ (-166,-2673)
- t=198.6s **NI ROWE** — Living Hut (herder_hut) builder=WIRE @ (3418,591)
- t=241.5s **NI ROWE** — Living Hut (herder_hut) builder=MAAX @ (3209,496)
- t=278.7s **NO FEKI** — Farm (milestone) @ (-137,-2738)
- t=303.7s **NO FEKI** — Oven (milestone) @ (-87,-2666)
- t=316.2s **NI ROWE** — Dairy Farm (milestone) @ (3448,513)
- t=373.3s **YE KUUL** — Living Hut (herder_hut) builder=NUKU @ (-2480,-366)
- t=490.2s **YE KUUL** — Farm (milestone) @ (-2334,-187)
- t=581.5s **VI MAJI** — Dairy Farm (milestone) @ (1400,2693)

## Per-clan detail

### NI ROWE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 5/5 (86% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 2 |
| Fiber | 15 | 3 |
| Mushroom | 1 | 0 |
| Nuts | 38 | 4 |
| Spear | 0 | 8 |
| Stone | 12 | 7 |
| Wood | 142 | 54 |

#### Failures

- **Gather:** inventory_full=43, empty_switch:not_harvestable=13, not_harvestable=5, resource_invalid=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAIN | 0 | 0 | 0 | 8 | idle 68%, gather 27%, eat 5% |
| CEOM | 0 | 0 | 0 | 4 | gather 79%, wander 16%, eat 4% |
| CILI | 0 | 0 | 2 | 21 | idle 41%, gather 35%, herd_wildnpc 13% |
| DEYO | 0 | 0 | 0 | 9 | idle 73%, gather 19%, herd_wildnpc 5% |
| FOLE | 0 | 0 | 1 | 10 | idle 65%, gather 22%, herd_wildnpc 8% |
| LUPE | 0 | 0 | 1 | 4 | gather 98%, wander 2% |
| MAAX | 0 | 0 | 1 | 10 | idle 54%, gather 18%, herd_wildnpc 14% |
| MAWA | 0 | 0 | 0 | 5 | idle 52%, gather 32%, herd_wildnpc 14% |
| NICE | 0 | 0 | 11 | 45 | wander 40%, gather 31%, herd_wildnpc 22% |
| POUV | 0 | 0 | 0 | 9 | gather 64%, idle 32%, eat 3% |
| QATO | 0 | 0 | 0 | 9 | idle 79%, gather 18%, eat 3% |
| QAXI | 0 | 0 | 0 | 0 | wander 58%, gather 40%, idle 2% |
| REBA | 0 | 0 | 0 | 9 | idle 65%, gather 32%, eat 3% |
| RIAP | 0 | 0 | 0 | 7 | idle 73%, gather 20%, wander 4% |
| VIIK | 0 | 0 | 0 | 9 | idle 79%, gather 18%, eat 3% |
| WIRE | 0 | 0 | 3 | 36 | gather 58%, wander 12%, herd_wildnpc 9% |
| WUHI | 0 | 0 | 0 | 4 | gather 57%, idle 42%, wander 1% |
| XAOS | 0 | 0 | 1 | 11 | gather 75%, wander 18%, herd_wildnpc 7% |
| YOEJ | 0 | 0 | 1 | 4 | herd_wildnpc 60%, gather 40%, wander 0% |

#### Buildings

- t=103.2s **Living Hut** — herder_hut (builder: NICE)
- t=198.6s **Living Hut** — herder_hut (builder: WIRE)
- t=241.5s **Living Hut** — herder_hut (builder: MAAX)
- t=316.2s **Dairy Farm** — milestone

### NO FEKI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 10/10 (85% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.8 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 33 | 12 |
| Fiber | 24 | 6 |
| Grain | 30 | 0 |
| Mushroom | 1 | 0 |
| Nuts | 39 | 2 |
| Spear | 0 | 25 |
| Stone | 40 | 14 |
| Wood | 191 | 35 |

#### Failures

- **Gather:** not_harvestable=36, empty_switch:not_harvestable=18, inventory_full=14, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEJA | 0 | 0 | 1 | 5 | gather 95%, idle 3%, wander 2% |
| BOZA | 0 | 0 | 1 | 4 | gather 98%, wander 2% |
| CUAK | 0 | 0 | 0 | 9 | idle 73%, gather 24%, eat 3% |
| DAAY | 0 | 0 | 0 | 7 | gather 63%, idle 21%, herd_wildnpc 13% |
| DAUX | 0 | 0 | 0 | 9 | flee_combat 67%, gather 25%, idle 5% |
| DUIM | 0 | 0 | 1 | 8 | gather 97%, wander 2%, eat 1% |
| FAAB | 0 | 0 | 0 | 6 | idle 85%, gather 14%, eat 1% |
| FAEB | 0 | 0 | 0 | 4 | gather 69%, idle 30%, wander 1% |
| FIIB | 0 | 0 | 1 | 9 | idle 78%, herd_wildnpc 13%, gather 7% |
| GUID | 0 | 0 | 1 | 6 | idle 89%, gather 9%, wander 1% |
| HUOH | 0 | 0 | 2 | 14 | gather 65%, wander 19%, herd_wildnpc 14% |
| JIXO | 0 | 0 | 2 | 21 | idle 54%, gather 22%, herd_wildnpc 13% |
| JUOM | 0 | 0 | 1 | 6 | idle 52%, gather 41%, herd_wildnpc 6% |
| KIPU | 0 | 0 | 0 | 8 | gather 64%, idle 33%, eat 2% |
| KOOZ | 0 | 0 | 0 | 7 | idle 56%, gather 39%, eat 4% |
| LEUB | 0 | 0 | 0 | 0 | flee_combat 69%, gather 20%, herd_wildnpc 11% |
| MATE | 0 | 0 | 0 | 3 | gather 100% |
| MEOZ | 0 | 0 | 1 | 7 | idle 48%, reproduction 25%, gather 13% |
| NAUC | 0 | 0 | 1 | 10 | idle 76%, gather 20%, eat 4% |
| NIOM | 0 | 0 | 0 | 9 | gather 53%, idle 43%, eat 4% |
| NUYI | 0 | 0 | 1 | 9 | idle 64%, gather 20%, herd_wildnpc 10% |
| PIAL | 0 | 0 | 0 | 4 | gather 98%, wander 2% |
| POQA | 0 | 0 | 1 | 0 | gather 100% |
| PUEF | 0 | 0 | 0 | 9 | idle 60%, gather 29%, herd_wildnpc 10% |
| QAZO | 0 | 0 | 1 | 0 | gather 100% |
| QEAL | 0 | 0 | 0 | 7 | idle 51%, gather 40%, herd_wildnpc 7% |
| QEPA | 0 | 0 | 1 | 12 | idle 45%, gather 33%, herd_wildnpc 14% |
| QUEZ | 0 | 0 | 0 | 6 | gather 57%, idle 38%, wander 4% |
| RAIZ | 0 | 0 | 0 | 1 | gather 100% |
| RIBU | 0 | 0 | 0 | 8 | idle 82%, gather 16%, eat 2% |
| RISI | 0 | 0 | 0 | 9 | gather 58%, idle 34%, eat 6% |
| RIUS | 0 | 0 | 0 | 6 | gather 56%, combat 28%, idle 8% |
| ROCA | 0 | 0 | 1 | 15 | gather 60%, idle 19%, herd_wildnpc 16% |
| RUIH | 0 | 0 | 0 | 9 | idle 53%, gather 45%, eat 1% |
| SADU | 0 | 0 | 2 | 17 | idle 41%, gather 30%, herd_wildnpc 12% |
| SIIV | 0 | 0 | 1 | 7 | idle 72%, gather 28%, wander 0% |
| SOTO | 0 | 0 | 1 | 3 | gather 98%, wander 2% |
| SUXE | 0 | 0 | 10 | 26 | wander 43%, gather 34%, herd_wildnpc 17% |
| TEEL | 0 | 0 | 1 | 0 | combat 56%, gather 40%, flee_combat 4% |
| TUXU | 0 | 0 | 0 | 4 | idle 75%, herd_wildnpc 10%, build_hut_for_woman 8% |
| VEAK | 0 | 0 | 1 | 3 | gather 74%, herd_wildnpc 23%, wander 2% |
| WAEB | 0 | 0 | 1 | 20 | gather 37%, combat 21%, idle 14% |
| WEOL | 0 | 0 | 0 | 9 | gather 74%, idle 19%, eat 6% |
| XESU | 0 | 0 | 0 | 3 | gather 63%, wander 36%, idle 1% |
| XIPA | 0 | 0 | 1 | 6 | gather 52%, combat 26%, wander 21% |
| XUSA | 0 | 0 | 1 | 4 | combat 55%, gather 42%, wander 3% |
| YAET | 0 | 0 | 0 | 6 | idle 66%, gather 34%, eat 0% |
| YEAH | 0 | 0 | 0 | 3 | gather 73%, herd_wildnpc 15%, wander 12% |
| YEEJ | 0 | 0 | 1 | 0 | gather 97%, wander 3% |

#### Buildings

- t=33.0s **Living Hut** — herder_hut (builder: SUXE)
- t=165.1s **Living Hut** — herder_hut (builder: TUXU)
- t=185.7s **Living Hut** — herder_hut (builder: TUXU)
- t=278.7s **Farm** — milestone
- t=303.7s **Oven** — milestone

### VI MAJI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 6/7 (47% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 3 |
| Fiber | 12 | 12 |
| Grain | 9 | 2 |
| Mushroom | 1 | 1 |
| Nuts | 34 | 10 |
| Spear | 0 | 8 |
| Stone | 1 | 0 |
| Wood | 168 | 119 |

#### Failures

- **Gather:** inventory_full=37, empty_switch:not_harvestable=24, resource_invalid=2, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEFE | 0 | 0 | 19 | 61 | wander 37%, herd_wildnpc 28%, gather 27% |
| BOTU | 0 | 0 | 0 | 10 | idle 58%, gather 32%, eat 5% |
| CEJU | 0 | 0 | 2 | 8 | herd_wildnpc 52%, gather 24%, wander 15% |
| DIAH | 0 | 0 | 10 | 36 | herd_wildnpc 42%, gather 35%, wander 19% |
| DIEK | 0 | 0 | 1 | 15 | idle 70%, gather 19%, eat 5% |
| FIUL | 0 | 0 | 0 | 0 | herd_wildnpc 100% |
| GIAX | 0 | 0 | 3 | 14 | herd_wildnpc 50%, gather 25%, wander 23% |
| HUKO | 0 | 0 | 0 | 4 | idle 90%, gather 4%, eat 4% |
| NESA | 0 | 0 | 0 | 5 | gather 54%, idle 40%, eat 4% |
| NUAZ | 0 | 0 | 4 | 23 | idle 57%, gather 19%, herd_wildnpc 12% |
| QAIP | 0 | 0 | 0 | 4 | idle 68%, gather 15%, herd_wildnpc 13% |
| QAIZ | 0 | 0 | 0 | 10 | idle 67%, gather 22%, herd_wildnpc 7% |
| RUSE | 0 | 0 | 2 | 8 | herd_wildnpc 54%, gather 36%, wander 10% |
| SIYI | 0 | 0 | 3 | 23 | herd_wildnpc 43%, gather 27%, idle 22% |
| XAUJ | 0 | 0 | 0 | 10 | idle 59%, gather 30%, eat 6% |

#### Buildings

- t=55.7s **Living Hut** — herder_hut (builder: BEFE)
- t=581.5s **Dairy Farm** — milestone

### YE KUUL

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 5/5 (86% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 0 |
| Fiber | 9 | 9 |
| Grain | 3 | 2 |
| Mushroom | 1 | 0 |
| Nuts | 18 | 2 |
| Spear | 0 | 13 |
| Stone | 10 | 6 |
| Wood | 73 | 41 |

#### Failures

- **Gather:** inventory_full=45, empty_switch:not_harvestable=8, not_harvestable=5, resource_invalid=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FEDO | 0 | 0 | 1 | 4 | herd_wildnpc 90%, gather 10%, wander 0% |
| GAIH | 0 | 0 | 0 | 4 | combat 37%, flee_combat 31%, gather 26% |
| JETE | 0 | 0 | 2 | 5 | combat 65%, gather 22%, wander 9% |
| JUSO | 0 | 0 | 1 | 4 | herd_wildnpc 40%, combat 35%, gather 19% |
| LEAK | 0 | 0 | 1 | 5 | combat 62%, gather 24%, wander 12% |
| MAWE | 0 | 0 | 1 | 7 | idle 76%, gather 16%, wander 4% |
| NUKU | 0 | 0 | 1 | 5 | herd_wildnpc 27%, combat 27%, gather 27% |
| PIEX | 0 | 0 | 1 | 1 | herd_wildnpc 93%, gather 7%, wander 0% |
| RUEF | 0 | 0 | 1 | 7 | flee_combat 40%, combat 36%, gather 17% |
| SALE | 0 | 0 | 1 | 9 | combat 57%, gather 22%, wander 19% |
| SOVU | 0 | 0 | 4 | 21 | idle 46%, gather 42%, wander 6% |
| TIFE | 0 | 0 | 6 | 20 | herd_wildnpc 23%, combat 22%, gather 22% |
| TOCU | 0 | 0 | 2 | 19 | idle 43%, combat 19%, gather 16% |
| VOON | 0 | 0 | 0 | 0 | combat 63%, herd_wildnpc 27%, gather 9% |
| YULA | 0 | 0 | 0 | 9 | idle 64%, combat 23%, gather 12% |
| ZAAB | 0 | 0 | 0 | 3 | herd_wildnpc 95%, gather 5%, wander 0% |
| ZERE | 0 | 0 | 1 | 0 | herd_wildnpc 94%, gather 6%, wander 0% |

#### Hunts

- start t=76.9s prey=deer quota=2
- hunt_aborted t=196.9s reason=active_timeout

#### Buildings

- t=43.1s **Living Hut** — herder_hut (builder: TIFE)
- t=63.2s **Living Hut** — herder_hut (builder: TIFE)
- t=373.3s **Living Hut** — herder_hut (builder: NUKU)
- t=490.2s **Farm** — milestone

