# ClanBrain Report (standard)

## Session

- **Duration:** 1800.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_30min_20260530_004636/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 30 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| BI VURU | 0→22 | 15 | 0.0 | 2 | 2 | 482 | 371 | 12 | 34% | 195.2s | 15 | 2 | 196.4s |
| DE VUAL | 0→30 | 20 | 0.0 | 3 | 2 | 640 | 480 | 20 | 31% | 190.2s | 19 | 4 | 193.0s |
| GA COPI | 0→30 | 13 | 0.0 | 3 | 3 | 275 | 251 | 4 | 44% | 1601.3s | 12 | 4 | 1601.8s |
| NA PUOK | 0→23 | 16 | 0.0 | 4 | 2 | 354 | 229 | 17 | 92% | 155.2s | 15 | 7 | 155.7s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 12 / 12
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| BI VURU | — | — | 34% | 20% | 0.0→0.5→0.0 | 195.2s |
| DE VUAL | — | — | 31% | 17% | 0.0→0.5→0.0 | 190.2s |
| GA COPI | — | — | 44% | 33% | 0.0→0.1→0.0 | 1601.3s |
| NA PUOK | — | — | 92% | 20% | 0.0→0.4→0.0 | 155.2s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| BI VURU | 2 | 2 | 0 | 0 | 0 | 1 | 0 |
| DE VUAL | 3 | 2 | 1 | 0 | 0 | 2 | 0 |
| GA COPI | 3 | 3 | 0 | 0 | 0 | 3 | 0 |
| NA PUOK | 4 | 2 | 2 | 0 | 0 | 2 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| BI VURU | 1 | 15 | 15 | 192.3s |
| DE VUAL | 3 | 19 | 19 | 190.5s |
| GA COPI | 3 | 12 | 12 | 1600.1s |
| NA PUOK | 6 | 15 | 15 | 154.2s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| BI VURU | 0 | 0 | — | 0 | 6 | idle 59%, gather 21%, wander 8% |
| DE VUAL | 0 | 0 | — | 0 | 9 | idle 60%, gather 17%, wander 8% |
| GA COPI | 0 | 0 | — | 0 | 2 | gather 43%, herd_wildnpc 20%, wander 19% |
| NA PUOK | 0 | 0 | — | 0 | 15 | idle 72%, gather 12%, eat 4% |

## Economy (session)

- **Items gathered:** 1751
- **Items deposited:** 1331
- **Deposit yield:** 76%
- **Gather failures (all):** 461
- **Gather failures (actionable):** 53
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 60
- **not_harvestable:** 45
- **resource_invalid:** 7
- **moved_during_gather:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 141 | 91 | 65% |
| Bone | 0 | 24 | — |
| Fiber | 170 | 136 | 80% |
| Grain | 84 | 44 | 52% |
| Hide | 0 | 35 | — |
| Meat | 0 | 43 | — |
| Mushroom | 8 | 6 | 75% |
| Nuts | 244 | 143 | 59% |
| Spear | 0 | 46 | — |
| Stone | 99 | 61 | 62% |
| Wood | 1005 | 702 | 70% |

## Buildings (session)

- **Total placed:** 17

### By type

- **Living Hut:** 10
- **Farm:** 3
- **Dairy Farm:** 2
- **Oven:** 2

### By source

- **herder_hut:** 10
- **milestone:** 7

### Chronological

- t=32.2s **GA COPI** — Living Hut (herder_hut) builder=DEOX @ (1673,623)
- t=43.3s **NA PUOK** — Living Hut (herder_hut) builder=WIID @ (344,3011)
- t=45.0s **BI VURU** — Living Hut (herder_hut) builder=ZAJU @ (426,-2960)
- t=79.4s **DE VUAL** — Living Hut (herder_hut) builder=SIWO @ (-3107,-1396)
- t=390.9s **GA COPI** — Dairy Farm (milestone) @ (1872,729)
- t=451.6s **BI VURU** — Farm (milestone) @ (269,-3106)
- t=456.0s **GA COPI** — Farm (milestone) @ (1700,563)
- t=476.0s **GA COPI** — Oven (milestone) @ (1906,677)
- t=583.7s **NA PUOK** — Living Hut (herder_hut) builder=PULA @ (381,2972)
- t=616.1s **DE VUAL** — Living Hut (herder_hut) builder=VOWE @ (-3314,-1508)
- t=653.5s **DE VUAL** — Farm (milestone) @ (-3272,-1568)
- t=737.9s **NA PUOK** — Living Hut (herder_hut) builder=WIID @ (524,3164)
- t=758.0s **NA PUOK** — Living Hut (herder_hut) builder=WIID @ (559,3226)
- t=1002.3s **NA PUOK** — Living Hut (herder_hut) builder=TEOL @ (568,3083)
- t=1063.8s **DE VUAL** — Dairy Farm (milestone) @ (-3150,-1363)
- t=1115.1s **NA PUOK** — Living Hut (herder_hut) builder=RODO @ (259,3057)
- t=1306.7s **NA PUOK** — Oven (milestone) @ (328,3063)

## Per-clan detail

### BI VURU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/7 (34% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 0.5 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 54 | 40 |
| Bone | 0 | 3 |
| Fiber | 92 | 70 |
| Grain | 27 | 14 |
| Hide | 0 | 7 |
| Meat | 0 | 10 |
| Mushroom | 3 | 3 |
| Nuts | 56 | 31 |
| Spear | 0 | 12 |
| Stone | 1 | 0 |
| Wood | 249 | 181 |

#### Failures

- **Gather:** inventory_full=63, empty_switch:not_harvestable=12, not_harvestable=10, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CIOK | 0 | 0 | 0 | 0 | idle 93%, eat 4%, gather 2% |
| CUFA | 0 | 0 | 4 | 36 | idle 64%, gather 24%, wander 7% |
| DOEH | 0 | 0 | 0 | 7 | idle 91%, gather 5%, eat 4% |
| GIZU | 0 | 0 | 3 | 21 | idle 73%, herd_wildnpc 10%, gather 9% |
| HAWI | 0 | 0 | 4 | 19 | gather 71%, herd_wildnpc 13%, flee_combat 8% |
| JIIG | 0 | 0 | 2 | 17 | idle 77%, gather 11%, herd_wildnpc 6% |
| NIIH | 0 | 0 | 2 | 24 | idle 77%, gather 11%, herd_wildnpc 7% |
| QEEH | 0 | 0 | 11 | 79 | gather 36%, idle 34%, wander 17% |
| QOBA | 0 | 0 | 3 | 28 | idle 79%, gather 8%, herd_wildnpc 5% |
| TUXO | 0 | 0 | 2 | 15 | idle 79%, gather 13%, wander 4% |
| VUPE | 0 | 0 | 2 | 16 | idle 69%, gather 13%, herd_wildnpc 8% |
| WUWO | 0 | 0 | 1 | 5 | idle 90%, gather 6%, eat 3% |
| XAJO | 0 | 0 | 0 | 10 | idle 71%, gather 25%, eat 4% |
| XEBO | 0 | 0 | 6 | 33 | idle 53%, herd_wildnpc 18%, gather 17% |
| ZAJU | 0 | 0 | 36 | 162 | wander 43%, gather 38%, herd_wildnpc 10% |
| ZEHU | 0 | 0 | 0 | 10 | gather 52%, idle 44%, eat 3% |

#### Hunts

- start t=196.4s prey=deer quota=2
- start t=246.4s prey=deer quota=2
- hunt_completed t=244.9s reason=loot_complete
- hunt_completed t=301.5s reason=loot_complete

#### Buildings

- t=45.0s **Living Hut** — herder_hut (builder: ZAJU)
- t=451.6s **Farm** — milestone

### DE VUAL

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/6 (31% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 0.5 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 45 | 29 |
| Bone | 0 | 6 |
| Fiber | 78 | 66 |
| Grain | 48 | 27 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Mushroom | 3 | 3 |
| Nuts | 97 | 54 |
| Spear | 0 | 17 |
| Stone | 26 | 9 |
| Wood | 343 | 251 |

#### Failures

- **Gather:** inventory_full=53, empty_switch:not_harvestable=34, not_harvestable=17, resource_invalid=2, moved_during_gather=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BOIY | 0 | 0 | 0 | 10 | idle 68%, gather 28%, eat 3% |
| DUON | 0 | 0 | 0 | 4 | idle 91%, eat 6%, gather 2% |
| GUAK | 0 | 0 | 1 | 10 | idle 88%, eat 6%, gather 5% |
| HIIV | 0 | 0 | 0 | 4 | idle 64%, gather 29%, wander 5% |
| KAAY | 0 | 0 | 4 | 24 | idle 70%, gather 10%, herd_wildnpc 9% |
| KAEG | 0 | 0 | 4 | 40 | idle 50%, gather 29%, wander 10% |
| KIOD | 0 | 0 | 4 | 35 | idle 59%, gather 24%, wander 8% |
| KIXO | 0 | 0 | 8 | 60 | idle 47%, gather 20%, herd_wildnpc 18% |
| KUFA | 0 | 0 | 2 | 25 | idle 61%, gather 15%, combat 11% |
| LAEV | 0 | 0 | 4 | 44 | idle 58%, gather 29%, wander 8% |
| MUAG | 0 | 0 | 4 | 26 | idle 61%, gather 26%, wander 10% |
| NECA | 0 | 0 | 4 | 49 | idle 66%, gather 21%, herd_wildnpc 5% |
| NUIJ | 0 | 0 | 4 | 32 | idle 58%, gather 31%, wander 6% |
| QAZO | 0 | 0 | 2 | 17 | idle 69%, gather 12%, herd_wildnpc 12% |
| QEFI | 0 | 0 | 3 | 28 | idle 68%, gather 11%, herd_wildnpc 10% |
| SIWO | 0 | 0 | 32 | 130 | wander 43%, gather 30%, herd_wildnpc 10% |
| VOWE | 0 | 0 | 5 | 32 | idle 62%, gather 13%, herd_wildnpc 11% |
| XIEW | 0 | 0 | 4 | 10 | idle 77%, combat 8%, gather 7% |
| YEUV | 0 | 0 | 2 | 23 | idle 59%, gather 14%, combat 11% |
| ZOUS | 0 | 0 | 3 | 37 | idle 46%, gather 20%, herd_wildnpc 14% |

#### Hunts

- start t=193.0s prey=deer quota=2
- start t=313.2s prey=deer quota=2
- start t=358.2s prey=deer quota=3
- hunt_aborted t=313.0s reason=active_timeout
- hunt_completed t=358.0s reason=loot_complete
- hunt_completed t=406.7s reason=loot_complete

#### Buildings

- t=79.4s **Living Hut** — herder_hut (builder: SIWO)
- t=616.1s **Living Hut** — herder_hut (builder: VOWE)
- t=653.5s **Farm** — milestone
- t=1063.8s **Dairy Farm** — milestone

### GA COPI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/4 (44% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Bone | 0 | 9 |
| Hide | 0 | 12 |
| Meat | 0 | 14 |
| Mushroom | 1 | 0 |
| Nuts | 43 | 32 |
| Spear | 0 | 10 |
| Stone | 44 | 30 |
| Wood | 184 | 144 |

#### Failures

- **Gather:** inventory_full=37, empty_switch:not_harvestable=5, not_harvestable=3, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DEOX | 0 | 0 | 62 | 196 | herd_wildnpc 36%, wander 31%, gather 25% |
| JEUX | 0 | 0 | 0 | 4 | idle 55%, gather 23%, wander 19% |
| JIAR | 0 | 0 | 0 | 1 | gather 91%, eat 9% |
| JIKI | 0 | 0 | 1 | 6 | gather 80%, wander 15%, idle 4% |
| LOIS | 0 | 0 | 2 | 4 | gather 72%, party 15%, idle 8% |
| QEWI | 0 | 0 | 1 | 7 | gather 92%, idle 5%, eat 3% |
| TAWE | 0 | 0 | 2 | 9 | gather 83%, wander 9%, eat 6% |
| WOED | 0 | 0 | 3 | 9 | gather 61%, party 24%, idle 7% |
| XUIT | 0 | 0 | 1 | 9 | gather 52%, wander 23%, combat 11% |
| YUDU | 0 | 0 | 2 | 8 | gather 43%, idle 37%, party 15% |
| YUOM | 0 | 0 | 3 | 8 | gather 96%, eat 3%, hunt 2% |
| YUWA | 0 | 0 | 2 | 12 | gather 50%, idle 28%, party 11% |
| ZOEY | 0 | 0 | 0 | 2 | gather 91%, eat 9% |

#### Hunts

- start t=1601.8s prey=deer quota=3
- start t=1646.8s prey=deer quota=4
- start t=1696.8s prey=deer quota=4
- hunt_completed t=1637.5s reason=loot_complete
- hunt_completed t=1686.7s reason=loot_complete
- hunt_completed t=1724.6s reason=loot_complete

#### Buildings

- t=32.2s **Living Hut** — herder_hut (builder: DEOX)
- t=390.9s **Dairy Farm** — milestone
- t=456.0s **Farm** — milestone
- t=476.0s **Oven** — milestone

### NA PUOK

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (92% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 0.4 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 39 | 22 |
| Bone | 0 | 6 |
| Grain | 9 | 3 |
| Hide | 0 | 8 |
| Meat | 0 | 9 |
| Mushroom | 1 | 0 |
| Nuts | 48 | 26 |
| Spear | 0 | 7 |
| Stone | 28 | 22 |
| Wood | 229 | 126 |

#### Failures

- **Gather:** inventory_full=195, not_harvestable=15, empty_switch:not_harvestable=9, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIZE | 0 | 0 | 0 | 9 | idle 76%, craft 12%, gather 8% |
| DADU | 0 | 0 | 0 | 6 | idle 92%, eat 4%, gather 4% |
| FIEF | 0 | 0 | 0 | 9 | idle 86%, gather 9%, eat 4% |
| LAAJ | 0 | 0 | 4 | 27 | idle 68%, gather 14%, craft 10% |
| LOGU | 0 | 0 | 0 | 9 | idle 90%, gather 5%, eat 4% |
| MEUT | 0 | 0 | 6 | 16 | idle 66%, party 16%, gather 10% |
| NAWA | 0 | 0 | 0 | 10 | idle 91%, gather 6%, eat 3% |
| PULA | 0 | 0 | 0 | 9 | idle 90%, gather 4%, eat 4% |
| RODO | 0 | 0 | 2 | 18 | idle 72%, gather 17%, eat 4% |
| SUBA | 0 | 0 | 0 | 11 | idle 74%, combat 15%, gather 5% |
| TEOL | 0 | 0 | 2 | 23 | idle 57%, gather 30%, build_hut_for_woman 6% |
| TEUW | 0 | 0 | 0 | 15 | idle 66%, gather 18%, herd_wildnpc 11% |
| VUCO | 0 | 0 | 0 | 6 | idle 88%, gather 8%, eat 4% |
| VUYU | 0 | 0 | 2 | 10 | idle 72%, party 9%, gather 8% |
| WIID | 0 | 0 | 39 | 166 | gather 38%, wander 33%, combat 15% |
| XEUF | 0 | 0 | 1 | 10 | idle 90%, gather 6%, eat 3% |

#### Hunts

- start t=155.7s prey=deer quota=2
- start t=290.9s prey=deer quota=4
- start t=431.0s prey=deer quota=4
- start t=556.1s prey=deer quota=4
- hunt_completed t=285.9s reason=loot_complete
- hunt_aborted t=410.9s reason=active_timeout
- hunt_aborted t=551.0s reason=active_timeout
- hunt_completed t=578.5s reason=loot_complete

#### Buildings

- t=43.3s **Living Hut** — herder_hut (builder: WIID)
- t=583.7s **Living Hut** — herder_hut (builder: PULA)
- t=737.9s **Living Hut** — herder_hut (builder: WIID)
- t=758.0s **Living Hut** — herder_hut (builder: WIID)
- t=1002.3s **Living Hut** — herder_hut (builder: TEOL)
- t=1115.1s **Living Hut** — herder_hut (builder: RODO)
- t=1306.7s **Oven** — milestone

