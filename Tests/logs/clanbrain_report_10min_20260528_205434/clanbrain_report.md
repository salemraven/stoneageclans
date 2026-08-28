# ClanBrain Report (standard)

## Session

- **Duration:** 600.6s
- **JSONL:** `Tests/logs/clanbrain_report_10min_20260528_205434/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| LO POOJ | 0→32 | 27 | 0.0 | 0 | 0 | 440 | 365 | 44 | 87% | 80.1s | 26 | 3 | — |
| MA COEY | 0→27 | 18 | 0.0 | 1 | 0 | 236 | 177 | 16 | 69% | 145.2s | 17 | 5 | 311.1s |
| RE VIPO | 0→30 | 24 | 0.3 | 1 | 0 | 262 | 215 | 23 | 74% | 80.1s | 25 | 3 | 330.7s |
| VE HIOD | 0→29 | 17 | 0.0 | 0 | 0 | 172 | 140 | 11 | 77% | 150.2s | 17 | 4 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 2 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 2

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| LO POOJ | — | — | 87% | 17% | 0.0→0.3→0.0 | 80.1s |
| MA COEY | — | — | 69% | 17% | 0.0→0.4→0.0 | 145.2s |
| RE VIPO | — | — | 74% | 20% | 0.0→0.3→0.3 | 80.1s |
| VE HIOD | — | — | 77% | 5% | 0.0→0.3→0.0 | 150.2s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| LO POOJ | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MA COEY | 1 | 0 | 0 | 0 | 0 | 2 | 0 |
| RE VIPO | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| VE HIOD | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| LO POOJ | 3 | 26 | 26 | 83.4s |
| MA COEY | 2 | 17 | 17 | 143.6s |
| RE VIPO | 3 | 25 | 25 | 76.9s |
| VE HIOD | 4 | 20 | 17 | 150.6s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| LO POOJ | 0 | 0 | — | 0 | 62 | gather 61%, wander 23%, herd_wildnpc 9% |
| MA COEY | 0 | 0 | — | 0 | 26 | gather 45%, combat 27%, wander 8% |
| RE VIPO | 0 | 0 | — | 0 | 45 | gather 39%, craft 21%, combat 12% |
| VE HIOD | 0 | 0 | — | 0 | 23 | gather 41%, wander 29%, craft 13% |

## Economy (session)

- **Items gathered:** 1110
- **Items deposited:** 897
- **Deposit yield:** 81%
- **Gather failures (all):** 385
- **Gather failures (actionable):** 94
- **Deposit failures:** 0

### Gather failures (actionable)

- **not_harvestable:** 81
- **empty_switch:not_harvestable:** 63
- **resource_invalid:** 12
- **moved_during_gather:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 38 | 24 | 63% |
| Bone | 0 | 3 | — |
| Fiber | 57 | 42 | 74% |
| Grain | 51 | 33 | 65% |
| Hide | 0 | 4 | — |
| Meat | 0 | 5 | — |
| Mushroom | 5 | 1 | 20% |
| Nuts | 146 | 74 | 51% |
| Spear | 0 | 64 | — |
| Stone | 100 | 82 | 82% |
| Wood | 713 | 565 | 79% |

## Buildings (session)

- **Total placed:** 15

### By type

- **Living Hut:** 9
- **Oven:** 3
- **Farm:** 2
- **Dairy Farm:** 1

### By source

- **herder_hut:** 9
- **milestone:** 6

### Chronological

- t=44.4s **RE VIPO** — Living Hut (herder_hut) builder=JOTA @ (-1269,-2457)
- t=50.9s **LO POOJ** — Living Hut (herder_hut) builder=FUQE @ (-371,2780)
- t=111.1s **MA COEY** — Living Hut (herder_hut) builder=YOWE @ (-2847,-10)
- t=118.1s **VE HIOD** — Living Hut (herder_hut) builder=HIOT @ (2825,-1615)
- t=128.1s **LO POOJ** — Living Hut (herder_hut) builder=FOAM @ (-328,2691)
- t=228.7s **MA COEY** — Living Hut (herder_hut) builder=BELA @ (-2672,153)
- t=233.0s **RE VIPO** — Living Hut (herder_hut) builder=KERO @ (-1032,-2431)
- t=265.7s **RE VIPO** — Oven (milestone) @ (-1093,-2327)
- t=326.1s **MA COEY** — Farm (milestone) @ (-2872,56)
- t=361.1s **MA COEY** — Dairy Farm (milestone) @ (-2633,78)
- t=372.1s **VE HIOD** — Living Hut (herder_hut) builder=LABE @ (3002,-1495)
- t=393.3s **VE HIOD** — Oven (milestone) @ (3062,-1579)
- t=401.2s **LO POOJ** — Living Hut (herder_hut) builder=ROSI @ (-563,2654)
- t=411.4s **MA COEY** — Oven (milestone) @ (-2566,100)
- t=580.1s **VE HIOD** — Farm (milestone) @ (2859,-1685)

## Per-clan detail

### LO POOJ

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 6/6 (87% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 32 | 20 |
| Fiber | 21 | 15 |
| Grain | 15 | 7 |
| Nuts | 59 | 38 |
| Spear | 0 | 19 |
| Stone | 5 | 5 |
| Wood | 308 | 261 |

#### Failures

- **Gather:** inventory_full=74, not_harvestable=40, empty_switch:not_harvestable=35, resource_invalid=3, moved_during_gather=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAET | 0 | 0 | 3 | 27 | gather 72%, wander 28% |
| CERO | 0 | 0 | 0 | 0 | gather 100% |
| DAVA | 0 | 0 | 0 | 0 | gather 100% |
| FIAZ | 0 | 0 | 2 | 20 | gather 77%, wander 23%, idle 0% |
| FOAM | 0 | 0 | 5 | 35 | herd_wildnpc 43%, gather 42%, wander 11% |
| FUQE | 0 | 0 | 13 | 37 | gather 56%, wander 35%, herd_wildnpc 5% |
| HUAS | 0 | 0 | 3 | 18 | herd_wildnpc 43%, gather 37%, wander 19% |
| JIUV | 0 | 0 | 4 | 32 | gather 76%, wander 24% |
| KIVE | 0 | 0 | 1 | 6 | gather 61%, wander 38%, idle 0% |
| LIBE | 0 | 0 | 2 | 14 | wander 52%, gather 48%, herd_wildnpc 0% |
| LOHE | 0 | 0 | 3 | 19 | gather 78%, wander 22%, idle 0% |
| LOIF | 0 | 0 | 0 | 9 | gather 96%, wander 4% |
| MAOW | 0 | 0 | 3 | 18 | herd_wildnpc 52%, gather 35%, wander 13% |
| MOZU | 0 | 0 | 5 | 36 | gather 77%, wander 23% |
| QUER | 0 | 0 | 1 | 12 | gather 76%, wander 24% |
| RIFE | 0 | 0 | 0 | 9 | gather 81%, wander 18%, idle 0% |
| ROSI | 0 | 0 | 1 | 9 | wander 45%, idle 26%, gather 13% |
| SIHA | 0 | 0 | 3 | 18 | gather 75%, wander 25% |
| TAUQ | 0 | 0 | 4 | 26 | gather 77%, wander 23%, idle 0% |
| TEUJ | 0 | 0 | 0 | 0 | gather 100% |
| VEIJ | 0 | 0 | 1 | 16 | gather 73%, wander 27% |
| VIHO | 0 | 0 | 0 | 3 | herd_wildnpc 59%, gather 39%, wander 1% |
| VIIN | 0 | 0 | 0 | 1 | gather 96%, wander 4% |
| WAYO | 0 | 0 | 1 | 10 | gather 78%, wander 22% |
| WIYE | 0 | 0 | 0 | 9 | eat 80%, gather 16%, herd_wildnpc 4% |
| ZUJO | 0 | 0 | 4 | 28 | gather 80%, wander 20% |
| ZUQE | 0 | 0 | 5 | 28 | gather 76%, wander 24% |

#### Buildings

- t=50.9s **Living Hut** — herder_hut (builder: FUQE)
- t=128.1s **Living Hut** — herder_hut (builder: FOAM)
- t=401.2s **Living Hut** — herder_hut (builder: ROSI)

### MA COEY

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/0 (69% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.4 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 3 |
| Grain | 9 | 5 |
| Hide | 0 | 4 |
| Meat | 0 | 5 |
| Mushroom | 1 | 0 |
| Nuts | 37 | 15 |
| Spear | 0 | 13 |
| Stone | 22 | 16 |
| Wood | 167 | 116 |

#### Failures

- **Gather:** inventory_full=107, empty_switch:not_harvestable=16, not_harvestable=14, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BELA | 0 | 0 | 1 | 6 | eat 36%, combat 17%, herd_wildnpc 15% |
| DEIP | 0 | 0 | 2 | 17 | gather 53%, combat 36%, wander 10% |
| GEIL | 0 | 0 | 2 | 10 | gather 82%, wander 18% |
| KOSU | 0 | 0 | 3 | 20 | gather 51%, combat 40%, eat 8% |
| KOUH | 0 | 0 | 2 | 4 | combat 61%, gather 37%, wander 1% |
| NEYO | 0 | 0 | 0 | 6 | combat 81%, gather 19%, wander 0% |
| QEUV | 0 | 0 | 0 | 0 | gather 100% |
| REEW | 0 | 0 | 0 | 7 | gather 64%, idle 34%, wander 2% |
| ROAL | 0 | 0 | 1 | 15 | gather 71%, combat 14%, wander 8% |
| RUOV | 0 | 0 | 1 | 12 | gather 56%, combat 41%, wander 3% |
| SIVI | 0 | 0 | 1 | 9 | gather 44%, combat 37%, herd_wildnpc 10% |
| TIPU | 0 | 0 | 3 | 18 | combat 40%, gather 34%, herd_wildnpc 19% |
| WILO | 0 | 0 | 3 | 19 | gather 53%, combat 33%, wander 14% |
| WORU | 0 | 0 | 2 | 22 | gather 42%, combat 32%, eat 20% |
| XIJE | 0 | 0 | 0 | 7 | gather 76%, wander 22%, idle 2% |
| YOWE | 0 | 0 | 16 | 40 | gather 51%, wander 28%, herd_wildnpc 13% |
| ZUQU | 0 | 0 | 0 | 7 | idle 62%, gather 31%, flee_combat 5% |
| ZUZI | 0 | 0 | 1 | 17 | gather 57%, eat 42%, wander 0% |

#### Hunts

- start t=311.1s prey=deer quota=4

#### Buildings

- t=111.1s **Living Hut** — herder_hut (builder: YOWE)
- t=228.7s **Living Hut** — herder_hut (builder: BELA)
- t=326.1s **Farm** — milestone
- t=361.1s **Dairy Farm** — milestone
- t=411.4s **Oven** — milestone

### RE VIPO

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (74% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.3 → 0.3

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 21 | 15 |
| Grain | 12 | 9 |
| Mushroom | 2 | 0 |
| Nuts | 32 | 19 |
| Spear | 0 | 19 |
| Stone | 42 | 35 |
| Wood | 153 | 118 |

#### Failures

- **Gather:** inventory_full=32, not_harvestable=19, empty_switch:not_harvestable=6, resource_invalid=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BILI | 0 | 0 | 0 | 0 | gather 70%, wander 29%, idle 1% |
| DEAC | 0 | 0 | 3 | 26 | gather 60%, craft 35%, wander 5% |
| FIFI | 0 | 0 | 3 | 13 | gather 52%, craft 45%, wander 3% |
| FUIV | 0 | 0 | 1 | 8 | craft 56%, gather 41%, wander 4% |
| GUED | 0 | 0 | 0 | 7 | hunt 42%, flee_combat 28%, gather 19% |
| HOAS | 0 | 0 | 0 | 1 | craft 65%, gather 33%, wander 2% |
| JAUK | 0 | 0 | 1 | 2 | gather 49%, hunt 35%, wander 15% |
| JOTA | 0 | 0 | 10 | 21 | gather 33%, wander 21%, hunt 19% |
| KAVE | 0 | 0 | 2 | 8 | gather 98%, wander 2% |
| KERO | 0 | 0 | 1 | 5 | idle 56%, craft 27%, gather 8% |
| KICI | 0 | 0 | 2 | 22 | combat 47%, gather 36%, party 9% |
| LAMA | 0 | 0 | 0 | 7 | gather 94%, wander 6% |
| MERE | 0 | 0 | 2 | 16 | gather 77%, wander 23%, idle 0% |
| QOEP | 0 | 0 | 3 | 15 | combat 43%, herd_wildnpc 26%, wander 12% |
| QOZU | 0 | 0 | 3 | 24 | combat 43%, gather 36%, wander 9% |
| QUUP | 0 | 0 | 1 | 12 | craft 49%, gather 31%, flee_combat 13% |
| RAIN | 0 | 0 | 0 | 0 | craft 93%, gather 6%, wander 1% |
| RAJI | 0 | 0 | 0 | 5 | craft 77%, gather 23%, wander 0% |
| RIOG | 0 | 0 | 2 | 13 | gather 48%, craft 44%, wander 8% |
| ROVO | 0 | 0 | 1 | 8 | gather 30%, hunt 25%, herd_wildnpc 24% |
| SAEN | 0 | 0 | 1 | 11 | gather 50%, combat 34%, wander 15% |
| XIYO | 0 | 0 | 1 | 4 | craft 63%, gather 36%, wander 1% |
| XUAP | 0 | 0 | 2 | 12 | gather 52%, craft 31%, herd_wildnpc 14% |
| YAER | 0 | 0 | 2 | 16 | gather 83%, wander 17%, idle 0% |
| YIWO | 0 | 0 | 0 | 0 | flee_combat 82%, gather 13%, wander 4% |
| YUBA | 0 | 0 | 1 | 6 | gather 88%, wander 12% |

#### Hunts

- start t=330.7s prey=deer quota=4

#### Buildings

- t=44.4s **Living Hut** — herder_hut (builder: JOTA)
- t=233.0s **Living Hut** — herder_hut (builder: KERO)
- t=265.7s **Oven** — milestone

### VE HIOD

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 5/5 (77% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 4 |
| Fiber | 15 | 12 |
| Grain | 15 | 12 |
| Mushroom | 2 | 1 |
| Nuts | 18 | 2 |
| Spear | 0 | 13 |
| Stone | 31 | 26 |
| Wood | 85 | 70 |

#### Failures

- **Gather:** inventory_full=15, not_harvestable=8, empty_switch:not_harvestable=6, resource_invalid=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| COAK | 0 | 0 | 0 | 6 | gather 100% |
| FAAK | 0 | 0 | 1 | 4 | wander 92%, gather 8%, herd_wildnpc 0% |
| FEAX | 0 | 0 | 3 | 13 | gather 55%, craft 32%, wander 12% |
| HIOT | 0 | 0 | 12 | 37 | wander 31%, gather 30%, herd_wildnpc 22% |
| LABE | 0 | 0 | 2 | 15 | gather 48%, wander 22%, eat 19% |
| NOSA | 0 | 0 | 5 | 18 | gather 39%, craft 28%, eat 18% |
| NUIL | 0 | 0 | 1 | 2 | gather 79%, wander 19%, idle 1% |
| PATU | 0 | 0 | 2 | 11 | gather 75%, wander 25% |
| QORE | 0 | 0 | 4 | 11 | gather 71%, wander 16%, herd_wildnpc 13% |
| SEIY | 0 | 0 | 1 | 18 | gather 76%, wander 24% |
| SUEL | 0 | 0 | 0 | 0 | herd_wildnpc 64%, gather 24%, wander 12% |
| TEQI | 0 | 0 | 0 | 0 | herd_wildnpc 53%, gather 47% |
| TEUD | 0 | 0 | 3 | 13 | wander 46%, craft 30%, gather 24% |
| WODO | 0 | 0 | 1 | 11 | gather 53%, wander 27%, build_hut_for_woman 11% |
| XAUB | 0 | 0 | 0 | 0 | gather 100% |
| YUUT | 0 | 0 | 1 | 4 | craft 38%, herd_wildnpc 30%, gather 22% |
| ZIOX | 0 | 0 | 0 | 2 | herd_wildnpc 69%, gather 31% |
| ZODU | 0 | 0 | 1 | 7 | gather 61%, wander 39% |

#### Buildings

- t=118.1s **Living Hut** — herder_hut (builder: HIOT)
- t=372.1s **Living Hut** — herder_hut (builder: LABE)
- t=393.3s **Oven** — milestone
- t=580.1s **Farm** — milestone

