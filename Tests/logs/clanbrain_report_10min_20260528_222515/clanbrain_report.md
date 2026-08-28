# ClanBrain Report (standard)

## Session

- **Duration:** 600.4s
- **JSONL:** `Tests/logs/clanbrain_report_10min_20260528_222515/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| BU WULE | 0→17 | 8 | 0.0 | 1 | 0 | 60 | 32 | 7 | 57% | 135.1s | 10 | 2 | 405.2s |
| KE DIZE | 0→25 | 21 | 0.0 | 0 | 0 | 190 | 47 | 9 | 65% | 75.1s | 20 | 2 | — |
| KE DURO | 0→34 | 24 | 0.0 | 0 | 0 | 295 | 134 | 5 | 51% | 85.1s | 23 | 3 | — |
| ZI NEOQ | 0→24 | 15 | 0.0 | 1 | 0 | 212 | 105 | 6 | 58% | 85.1s | 14 | 2 | 441.3s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 2 / 2
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| BU WULE | — | — | 57% | 12% | 0.0→0.1→0.0 | 135.1s |
| KE DIZE | — | — | 65% | 20% | 0.0→0.3→0.0 | 75.1s |
| KE DURO | — | — | 51% | 17% | 0.0→0.3→0.0 | 85.1s |
| ZI NEOQ | — | — | 58% | 17% | 0.0→0.1→0.0 | 85.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| BU WULE | 1 | 0 | 1 | 0 | 0 | 0 | 0 |
| KE DIZE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| KE DURO | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| ZI NEOQ | 1 | 0 | 1 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| BU WULE | 1 | 11 | 10 | 139.2s |
| KE DIZE | 2 | 21 | 20 | 75.6s |
| KE DURO | 2 | 25 | 23 | 83.6s |
| ZI NEOQ | 2 | 16 | 14 | 81.8s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| BU WULE | 0 | 0 | — | 0 | 2 | combat 21%, herd_wildnpc 21%, flee_combat 21% |
| KE DIZE | 0 | 0 | — | 0 | 10 | idle 58%, gather 30%, wander 7% |
| KE DURO | 0 | 0 | — | 0 | 10 | idle 50%, gather 31%, wander 8% |
| ZI NEOQ | 0 | 0 | — | 0 | 14 | combat 30%, idle 23%, gather 21% |

## Economy (session)

- **Items gathered:** 757
- **Items deposited:** 318
- **Deposit yield:** 42%
- **Gather failures (all):** 454
- **Gather failures (actionable):** 27
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 37
- **not_harvestable:** 25
- **resource_invalid:** 2

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 24 | 11 | 46% |
| Fiber | 30 | 5 | 17% |
| Grain | 51 | 11 | 22% |
| Mushroom | 2 | 1 | 50% |
| Nuts | 108 | 15 | 14% |
| Spear | 0 | 29 | — |
| Stone | 64 | 32 | 50% |
| Wood | 478 | 214 | 45% |

## Buildings (session)

- **Total placed:** 9

### By type

- **Living Hut:** 5
- **Farm:** 2
- **Dairy Farm:** 1
- **Oven:** 1

### By source

- **herder_hut:** 5
- **milestone:** 4

### Chronological

- t=43.1s **KE DIZE** — Living Hut (herder_hut) builder=LIAT @ (-972,-3028)
- t=49.3s **ZI NEOQ** — Living Hut (herder_hut) builder=RUOJ @ (1040,2322)
- t=51.1s **KE DURO** — Living Hut (herder_hut) builder=VORI @ (-2303,485)
- t=106.7s **BU WULE** — Living Hut (herder_hut) builder=NIKU @ (3314,1253)
- t=195.0s **BU WULE** — Farm (milestone) @ (3153,1105)
- t=270.4s **KE DIZE** — Living Hut (herder_hut) builder=GEIW @ (-1116,-3214)
- t=323.6s **KE DURO** — Oven (milestone) @ (-2412,272)
- t=328.6s **KE DURO** — Dairy Farm (milestone) @ (-2457,303)
- t=376.2s **ZI NEOQ** — Farm (milestone) @ (1191,2494)

## Per-clan detail

### BU WULE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/6 (57% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 4 |
| Nuts | 6 | 0 |
| Spear | 0 | 6 |
| Stone | 16 | 8 |
| Wood | 29 | 14 |

#### Failures

- **Gather:** not_harvestable=7, empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| GEOJ | 0 | 0 | 0 | 4 | combat 85%, gather 11%, flee_combat 3% |
| GULU | 0 | 0 | 0 | 2 | combat 45%, flee_combat 29%, herd_wildnpc 20% |
| GUON | 0 | 0 | 1 | 5 | gather 99%, herd_wildnpc 1%, wander 0% |
| HOAZ | 0 | 0 | 0 | 5 | gather 46%, hunt 39%, wander 7% |
| MUIG | 0 | 0 | 1 | 8 | party 28%, gather 19%, combat 19% |
| MUTI | 0 | 0 | 0 | 2 | herd_wildnpc 61%, gather 39% |
| NIKU | 0 | 0 | 7 | 20 | herd_wildnpc 37%, wander 23%, gather 19% |
| QOYU | 0 | 0 | 2 | 14 | herd_wildnpc 36%, combat 28%, gather 21% |
| SAUY | 0 | 0 | 1 | 0 | gather 100% |
| WAIQ | 0 | 0 | 0 | 0 | flee_combat 68%, combat 27%, gather 3% |
| YUPA | 0 | 0 | 1 | 0 | flee_combat 79%, herd_wildnpc 14%, gather 6% |

#### Hunts

- start t=405.2s prey=deer quota=4
- hunt_aborted t=525.2s reason=active_timeout

#### Buildings

- t=106.7s **Living Hut** — herder_hut (builder: NIKU)
- t=195.0s **Farm** — milestone

### KE DIZE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/5 (65% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Fiber | 27 | 5 |
| Grain | 48 | 11 |
| Mushroom | 2 | 1 |
| Nuts | 18 | 2 |
| Spear | 0 | 7 |
| Stone | 1 | 0 |
| Wood | 91 | 21 |

#### Failures

- **Gather:** inventory_full=24, not_harvestable=7, empty_switch:not_harvestable=6, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAUX | 0 | 0 | 0 | 12 | gather 47%, idle 41%, wander 8% |
| BIUW | 0 | 0 | 0 | 6 | gather 74%, wander 11%, idle 10% |
| COPU | 0 | 0 | 0 | 10 | gather 56%, idle 32%, herd_wildnpc 7% |
| CUKA | 0 | 0 | 1 | 0 | gather 100% |
| CUMI | 0 | 0 | 1 | 8 | gather 60%, idle 35%, eat 4% |
| DUKE | 0 | 0 | 1 | 4 | gather 74%, herd_wildnpc 21%, wander 5% |
| FAOJ | 0 | 0 | 0 | 5 | idle 83%, gather 11%, wander 4% |
| GEIW | 0 | 0 | 0 | 10 | idle 67%, gather 22%, build_hut_for_woman 4% |
| HIIK | 0 | 0 | 1 | 5 | idle 79%, gather 20%, wander 0% |
| KIOC | 0 | 0 | 0 | 4 | idle 84%, gather 12%, wander 3% |
| LAOK | 0 | 0 | 0 | 4 | idle 80%, gather 18%, eat 2% |
| LIAT | 0 | 0 | 13 | 48 | gather 46%, wander 42%, herd_wildnpc 4% |
| PAUQ | 0 | 0 | 1 | 11 | idle 75%, gather 22%, eat 3% |
| QIIH | 0 | 0 | 0 | 3 | gather 61%, herd_wildnpc 39% |
| QOUX | 0 | 0 | 0 | 12 | gather 54%, idle 41%, eat 4% |
| QULE | 0 | 0 | 0 | 10 | idle 81%, gather 13%, wander 3% |
| QUZA | 0 | 0 | 0 | 4 | idle 61%, gather 31%, wander 8% |
| REOT | 0 | 0 | 0 | 9 | idle 72%, gather 24%, eat 4% |
| TOZA | 0 | 0 | 0 | 6 | gather 52%, herd_wildnpc 18%, wander 18% |
| WIEQ | 0 | 0 | 1 | 15 | idle 50%, gather 42%, wander 7% |
| YOTE | 0 | 0 | 0 | 4 | idle 92%, gather 6%, eat 2% |

#### Buildings

- t=43.1s **Living Hut** — herder_hut (builder: LIAT)
- t=270.4s **Living Hut** — herder_hut (builder: GEIW)

### KE DURO

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 5/6 (51% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 12 | 7 |
| Grain | 3 | 0 |
| Nuts | 48 | 7 |
| Spear | 0 | 7 |
| Stone | 32 | 15 |
| Wood | 200 | 98 |

#### Failures

- **Gather:** inventory_full=243, empty_switch:not_harvestable=18, not_harvestable=5

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DOWA | 0 | 0 | 0 | 10 | idle 58%, gather 26%, herd_wildnpc 10% |
| FEKO | 0 | 0 | 0 | 11 | gather 51%, idle 42%, wander 5% |
| FUZE | 0 | 0 | 0 | 10 | gather 45%, idle 45%, wander 5% |
| HAQU | 0 | 0 | 0 | 5 | idle 92%, gather 5%, eat 3% |
| LUOZ | 0 | 0 | 0 | 4 | idle 62%, gather 27%, herd_wildnpc 9% |
| NAAG | 0 | 0 | 1 | 5 | idle 58%, gather 38%, eat 4% |
| NECI | 0 | 0 | 0 | 4 | idle 91%, gather 5%, eat 4% |
| NENA | 0 | 0 | 0 | 0 | herd_wildnpc 54%, wander 25%, gather 20% |
| NOCU | 0 | 0 | 0 | 10 | idle 58%, gather 38%, eat 4% |
| PIOK | 0 | 0 | 1 | 16 | idle 70%, gather 19%, herd_wildnpc 6% |
| QOOG | 0 | 0 | 1 | 21 | idle 51%, gather 40%, eat 4% |
| QUKI | 0 | 0 | 0 | 5 | gather 64%, herd_wildnpc 13%, wander 11% |
| SAOP | 0 | 0 | 0 | 6 | idle 70%, gather 24%, herd_wildnpc 4% |
| SUIR | 0 | 0 | 0 | 0 | gather 58%, wander 39%, idle 3% |
| VIUK | 0 | 0 | 0 | 10 | idle 58%, gather 37%, eat 4% |
| VORI | 0 | 0 | 15 | 66 | gather 40%, wander 32%, herd_wildnpc 20% |
| WOAK | 0 | 0 | 0 | 4 | gather 93%, eat 6%, wander 1% |
| WUAH | 0 | 0 | 6 | 41 | gather 37%, idle 30%, wander 15% |
| YAFI | 0 | 0 | 0 | 10 | idle 74%, gather 22%, eat 4% |
| YOKU | 0 | 0 | 0 | 4 | gather 63%, herd_wildnpc 33%, eat 3% |
| ZILA | 0 | 0 | 7 | 41 | gather 58%, wander 22%, herd_wildnpc 17% |
| ZODU | 0 | 0 | 1 | 5 | idle 71%, gather 25%, eat 3% |
| ZOHA | 0 | 0 | 0 | 4 | idle 77%, gather 21%, eat 2% |
| ZOIB | 0 | 0 | 0 | 3 | gather 50%, wander 47%, idle 3% |

#### Buildings

- t=51.1s **Living Hut** — herder_hut (builder: VORI)
- t=323.6s **Oven** — milestone
- t=328.6s **Dairy Farm** — milestone

### ZI NEOQ

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 5/5 (58% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 0 |
| Nuts | 36 | 6 |
| Spear | 0 | 9 |
| Stone | 15 | 9 |
| Wood | 158 | 81 |

#### Failures

- **Gather:** inventory_full=123, empty_switch:not_harvestable=12, not_harvestable=6

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CAHE | 0 | 0 | 6 | 24 | combat 52%, herd_wildnpc 16%, gather 15% |
| DAIF | 0 | 0 | 0 | 4 | hunt 32%, combat 20%, idle 19% |
| FAYU | 0 | 0 | 3 | 22 | combat 40%, gather 25%, idle 21% |
| HIOB | 0 | 0 | 4 | 14 | combat 38%, idle 29%, gather 21% |
| KEIR | 0 | 0 | 0 | 5 | idle 85%, gather 10%, wander 3% |
| QUAR | 0 | 0 | 3 | 17 | combat 33%, gather 27%, idle 23% |
| ROGI | 0 | 0 | 0 | 5 | combat 45%, idle 25%, gather 23% |
| RUOJ | 0 | 0 | 14 | 47 | herd_wildnpc 31%, gather 25%, wander 19% |
| RUUJ | 0 | 0 | 1 | 11 | combat 40%, idle 29%, herd_wildnpc 20% |
| SAWI | 0 | 0 | 0 | 5 | idle 51%, gather 48%, wander 1% |
| TEAW | 0 | 0 | 0 | 9 | gather 59%, idle 40%, wander 0% |
| VIAZ | 0 | 0 | 1 | 21 | idle 46%, gather 23%, combat 19% |
| XEUD | 0 | 0 | 1 | 11 | combat 40%, idle 27%, gather 14% |
| ZAED | 0 | 0 | 3 | 10 | combat 40%, herd_wildnpc 29%, gather 20% |
| ZOOZ | 0 | 0 | 0 | 7 | gather 31%, idle 27%, combat 23% |

#### Hunts

- start t=441.3s prey=deer quota=4
- hunt_aborted t=561.3s reason=active_timeout

#### Buildings

- t=49.3s **Living Hut** — herder_hut (builder: RUOJ)
- t=376.2s **Farm** — milestone

