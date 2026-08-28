# ClanBrain Report (standard)

## Session

- **Duration:** 300.3s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_20260528_214633/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 5 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| JO GUAH | 0→28 | 16 | 0.2 | 0 | 0 | 78 | 53 | 4 | 37% | 75.1s | 15 | 4 | — |
| SO BUZA | 0→19 | 13 | 0.1 | 0 | 0 | 121 | 88 | 6 | 85% | 100.1s | 12 | 3 | — |
| TI NUFI | 0→11 | 8 | 0.7 | 0 | 0 | 91 | 54 | 2 | 64% | 80.1s | 7 | 1 | — |
| WU ZOZE | 0→12 | 8 | 0.0 | 0 | 0 | 88 | 42 | 2 | 69% | 100.1s | 7 | 2 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| JO GUAH | 0% | 100% | 73% | 20% | 0.0→0.4→0.2 | 75.1s |
| SO BUZA | — | — | 85% | 11% | 0.0→0.2→0.1 | 100.1s |
| TI NUFI | — | — | 64% | 20% | 0.0→0.7→0.7 | 80.1s |
| WU ZOZE | — | — | 69% | 20% | 0.0→0.1→0.0 | 100.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| JO GUAH | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| SO BUZA | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| TI NUFI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| WU ZOZE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| JO GUAH | 3 | 16 | 15 | 77.1s |
| SO BUZA | 2 | 12 | 12 | 100.0s |
| TI NUFI | 1 | 8 | 7 | 81.7s |
| WU ZOZE | 2 | 8 | 7 | 98.8s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| JO GUAH | 0 | 0 | — | 0 | 2 | craft 35%, herd_wildnpc 30%, gather 18% |
| SO BUZA | 0 | 0 | — | 0 | 6 | gather 46%, herd_wildnpc 22%, wander 21% |
| TI NUFI | 0 | 0 | — | 0 | 4 | gather 33%, craft 30%, herd_wildnpc 21% |
| WU ZOZE | 0 | 0 | — | 0 | 4 | gather 50%, wander 15%, herd_wildnpc 13% |

## Economy (session)

- **Items gathered:** 378
- **Items deposited:** 237
- **Deposit yield:** 63%
- **Gather failures (all):** 193
- **Gather failures (actionable):** 14
- **Deposit failures:** 0

### Gather failures (actionable)

- **not_harvestable:** 9
- **resource_invalid:** 5
- **empty_switch:not_harvestable:** 3

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 9 | 9 | 100% |
| Fiber | 15 | 14 | 93% |
| Grain | 18 | 6 | 33% |
| Mushroom | 3 | 1 | 33% |
| Nuts | 65 | 22 | 34% |
| Spear | 0 | 24 | — |
| Stone | 33 | 26 | 79% |
| Wood | 235 | 135 | 57% |

## Buildings (session)

- **Total placed:** 10

### By type

- **Living Hut:** 6
- **Dairy Farm:** 2
- **Farm:** 1
- **Oven:** 1

### By source

- **herder_hut:** 6
- **milestone:** 4

### Chronological

- t=44.6s **JO GUAH** — Living Hut (herder_hut) builder=RUQI @ (-1490,945)
- t=49.2s **TI NUFI** — Living Hut (herder_hut) builder=CENE @ (-432,-2606)
- t=66.3s **WU ZOZE** — Living Hut (herder_hut) builder=GABA @ (727,2451)
- t=67.5s **SO BUZA** — Living Hut (herder_hut) builder=HOHE @ (2438,993)
- t=113.2s **SO BUZA** — Living Hut (herder_hut) builder=HOHE @ (2293,802)
- t=199.2s **JO GUAH** — Oven (milestone) @ (-1521,986)
- t=204.2s **JO GUAH** — Farm (milestone) @ (-1714,859)
- t=212.6s **WU ZOZE** — Living Hut (herder_hut) builder=MIEV @ (760,2375)
- t=259.2s **JO GUAH** — Dairy Farm (milestone) @ (-1674,801)
- t=273.7s **SO BUZA** — Dairy Farm (milestone) @ (2477,947)

## Per-clan detail

### JO GUAH

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (0% fill) | searchers 5/5 (73% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.4 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 6 |
| Mushroom | 1 | 0 |
| Nuts | 10 | 5 |
| Spear | 0 | 5 |
| Stone | 17 | 15 |
| Wood | 44 | 22 |

#### Failures

- **Gather:** not_harvestable=3, empty_switch:not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CIAQ | 0 | 0 | 0 | 0 | craft 84%, wander 16%, idle 0% |
| DEOK | 0 | 0 | 0 | 0 | craft 100% |
| DETO | 0 | 0 | 0 | 0 | wander 60%, gather 36%, idle 3% |
| KEMO | 0 | 0 | 2 | 12 | craft 45%, herd_wildnpc 29%, gather 15% |
| KIAC | 0 | 0 | 0 | 0 | craft 83%, wander 16%, idle 1% |
| LAPU | 0 | 0 | 0 | 0 | craft 100% |
| LOYA | 0 | 0 | 0 | 0 | craft 100% |
| REAM | 0 | 0 | 1 | 5 | herd_wildnpc 48%, craft 24%, gather 23% |
| RUQI | 0 | 0 | 14 | 41 | gather 51%, wander 23%, craft 12% |
| TOIZ | 0 | 0 | 1 | 0 | craft 100% |
| TUMU | 0 | 0 | 1 | 4 | wander 56%, herd_wildnpc 25%, build_hut_for_woman 12% |
| WIEQ | 0 | 0 | 0 | 0 | gather 100% |
| XAJI | 0 | 0 | 0 | 4 | herd_wildnpc 60%, craft 33%, gather 7% |
| XIAX | 0 | 0 | 0 | 8 | gather 100% |
| YUOB | 0 | 0 | 0 | 0 | gather 100% |
| ZOEY | 0 | 0 | 0 | 4 | herd_wildnpc 92%, wander 5%, gather 2% |

#### Buildings

- t=44.6s **Living Hut** — herder_hut (builder: RUQI)
- t=199.2s **Oven** — milestone
- t=204.2s **Farm** — milestone
- t=259.2s **Dairy Farm** — milestone

### SO BUZA

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (85% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 9 | 9 |
| Grain | 6 | 0 |
| Mushroom | 1 | 0 |
| Nuts | 24 | 8 |
| Spear | 0 | 11 |
| Stone | 6 | 3 |
| Wood | 75 | 57 |

#### Failures

- **Gather:** inventory_full=67, not_harvestable=5, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BALI | 0 | 0 | 2 | 9 | herd_wildnpc 55%, wander 24%, gather 21% |
| BASE | 0 | 0 | 1 | 4 | wander 66%, herd_wildnpc 23%, gather 11% |
| CAUT | 0 | 0 | 1 | 14 | gather 87%, wander 13%, idle 0% |
| HOHE | 0 | 0 | 7 | 19 | herd_wildnpc 40%, wander 21%, gather 19% |
| HOJA | 0 | 0 | 1 | 14 | gather 78%, combat 14%, wander 8% |
| KIRU | 0 | 0 | 2 | 25 | gather 85%, wander 15% |
| MELE | 0 | 0 | 0 | 3 | combat 70%, gather 30% |
| MOQU | 0 | 0 | 0 | 1 | herd_wildnpc 46%, gather 40%, wander 13% |
| NEGU | 0 | 0 | 1 | 5 | combat 37%, herd_wildnpc 25%, wander 23% |
| RAEL | 0 | 0 | 1 | 9 | gather 91%, wander 9% |
| TOAL | 0 | 0 | 1 | 0 | gather 59%, wander 37%, idle 4% |
| TOUQ | 0 | 0 | 1 | 18 | gather 68%, herd_wildnpc 23%, wander 8% |
| TUKI | 0 | 0 | 1 | 0 | gather 100% |

#### Buildings

- t=67.5s **Living Hut** — herder_hut (builder: HOHE)
- t=113.2s **Living Hut** — herder_hut (builder: HOHE)
- t=273.7s **Dairy Farm** — milestone

### TI NUFI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (64% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.7 → 0.7

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 3 |
| Fiber | 3 | 2 |
| Grain | 9 | 6 |
| Mushroom | 1 | 1 |
| Nuts | 16 | 6 |
| Spear | 0 | 4 |
| Stone | 8 | 7 |
| Wood | 51 | 25 |

#### Failures

- **Gather:** inventory_full=25, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BELI | 0 | 0 | 1 | 9 | herd_wildnpc 61%, craft 27%, wander 9% |
| BOOK | 0 | 0 | 0 | 0 | craft 100% |
| CENE | 0 | 0 | 11 | 26 | wander 36%, gather 31%, craft 18% |
| GEYU | 0 | 0 | 0 | 9 | craft 56%, gather 44%, wander 0% |
| LOAV | 0 | 0 | 0 | 9 | gather 59%, craft 41%, wander 0% |
| NAIY | 0 | 0 | 0 | 9 | gather 100% |
| XUBI | 0 | 0 | 1 | 8 | herd_wildnpc 48%, craft 39%, wander 8% |
| YIBA | 0 | 0 | 3 | 21 | gather 79%, wander 21%, idle 0% |

#### Buildings

- t=49.2s **Living Hut** — herder_hut (builder: CENE)

### WU ZOZE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (69% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 3 |
| Grain | 3 | 0 |
| Nuts | 15 | 3 |
| Spear | 0 | 4 |
| Stone | 2 | 1 |
| Wood | 65 | 31 |

#### Failures

- **Gather:** inventory_full=84, empty_switch:not_harvestable=2, not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GABA | 0 | 0 | 6 | 12 | herd_wildnpc 43%, wander 27%, gather 18% |
| MIEV | 0 | 0 | 0 | 6 | combat 45%, gather 31%, build_hut_for_woman 16% |
| QIKU | 0 | 0 | 2 | 18 | gather 74%, wander 25%, idle 0% |
| ROKI | 0 | 0 | 0 | 9 | eat 66%, gather 34%, wander 0% |
| SEEX | 0 | 0 | 0 | 9 | gather 80%, wander 19%, idle 1% |
| WEUV | 0 | 0 | 0 | 1 | gather 100% |
| WUEK | 0 | 0 | 1 | 8 | gather 100% |
| YUMI | 0 | 0 | 3 | 25 | gather 83%, wander 17% |

#### Buildings

- t=66.3s **Living Hut** — herder_hut (builder: GABA)
- t=212.6s **Living Hut** — herder_hut (builder: MIEV)

