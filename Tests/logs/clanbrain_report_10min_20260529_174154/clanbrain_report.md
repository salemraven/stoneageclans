# ClanBrain Report (standard)

## Session

- **Duration:** 600.5s
- **JSONL:** `Tests/logs/clanbrain_report_10min_20260529_174154/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| BO CUKE | 0→44 | 34 | 0.0 | 0 | 0 | 299 | 118 | 25 | 73% | 80.1s | 33 | 6 | — |
| MU WUOK | 0→33 | 20 | 0.0 | 0 | 0 | 255 | 123 | 6 | 66% | 65.1s | 19 | 4 | — |
| RA CEDU | 0→19 | 9 | 0.0 | 0 | 0 | 86 | 45 | 4 | 64% | 170.2s | 8 | 4 | — |
| VA TIER | 0→29 | 25 | 0.0 | 0 | 0 | 302 | 134 | 18 | 51% | 65.1s | 24 | 4 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| BO CUKE | — | — | 73% | 20% | 0.0→0.1→0.0 | 80.1s |
| MU WUOK | — | — | 66% | 33% | 0.0→0.0→0.0 | 65.1s |
| RA CEDU | — | — | 64% | 9% | 0.0→0.1→0.0 | 170.2s |
| VA TIER | — | — | 51% | 33% | 0.0→0.8→0.0 | 65.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| BO CUKE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MU WUOK | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| RA CEDU | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| VA TIER | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| BO CUKE | 5 | 35 | 33 | 82.1s |
| MU WUOK | 3 | 19 | 19 | 68.7s |
| RA CEDU | 1 | 9 | 8 | 167.8s |
| VA TIER | 4 | 24 | 24 | 66.9s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| BO CUKE | 0 | 0 | — | 0 | 18 | idle 40%, gather 32%, herd_wildnpc 13% |
| MU WUOK | 0 | 0 | — | 0 | 5 | idle 48%, gather 28%, herd_wildnpc 14% |
| RA CEDU | 0 | 0 | — | 0 | 2 | idle 43%, herd_wildnpc 29%, gather 18% |
| VA TIER | 0 | 0 | — | 0 | 16 | idle 49%, gather 32%, wander 6% |

## Economy (session)

- **Items gathered:** 942
- **Items deposited:** 420
- **Deposit yield:** 45%
- **Gather failures (all):** 262
- **Gather failures (actionable):** 53
- **Deposit failures:** 0

### Gather failures (actionable)

- **not_harvestable:** 43
- **empty_switch:not_harvestable:** 36
- **resource_invalid:** 10

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 53 | 33 | 62% |
| Fiber | 57 | 25 | 44% |
| Grain | 37 | 9 | 24% |
| Mushroom | 8 | 0 | 0% |
| Nuts | 128 | 13 | 10% |
| Spear | 0 | 46 | — |
| Stone | 112 | 47 | 42% |
| Wood | 547 | 247 | 45% |

## Buildings (session)

- **Total placed:** 18

### By type

- **Living Hut:** 12
- **Dairy Farm:** 2
- **Farm:** 2
- **Oven:** 2

### By source

- **herder_hut:** 12
- **milestone:** 6

### Chronological

- t=34.4s **VA TIER** — Living Hut (herder_hut) builder=NEUL @ (-372,2141)
- t=36.2s **MU WUOK** — Living Hut (herder_hut) builder=GOYU @ (-2068,304)
- t=49.6s **BO CUKE** — Living Hut (herder_hut) builder=NEAF @ (462,-2413)
- t=109.0s **MU WUOK** — Living Hut (herder_hut) builder=VIFA @ (-2162,83)
- t=135.3s **RA CEDU** — Living Hut (herder_hut) builder=VEIH @ (3210,-600)
- t=174.4s **VA TIER** — Living Hut (herder_hut) builder=TEIB @ (-565,2021)
- t=193.2s **BO CUKE** — Living Hut (herder_hut) builder=FAQI @ (623,-2260)
- t=214.0s **MU WUOK** — Dairy Farm (milestone) @ (-2221,141)
- t=217.0s **VA TIER** — Living Hut (herder_hut) builder=FOUQ @ (-331,2076)
- t=224.0s **MU WUOK** — Farm (milestone) @ (-1992,193)
- t=242.3s **BO CUKE** — Living Hut (herder_hut) builder=DEUG @ (585,-2209)
- t=278.0s **VA TIER** — Living Hut (herder_hut) builder=FOUQ @ (-538,1969)
- t=341.1s **RA CEDU** — Dairy Farm (milestone) @ (3268,-680)
- t=363.1s **BO CUKE** — Living Hut (herder_hut) builder=TEXO @ (396,-2333)
- t=381.1s **RA CEDU** — Oven (milestone) @ (3439,-532)
- t=456.2s **BO CUKE** — Living Hut (herder_hut) builder=FAQI @ (600,-2136)
- t=465.2s **BO CUKE** — Oven (milestone) @ (643,-2166)
- t=574.3s **RA CEDU** — Farm (milestone) @ (3387,-471)

## Per-clan detail

### BO CUKE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 8/8 (73% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 14 | 4 |
| Fiber | 33 | 10 |
| Mushroom | 4 | 0 |
| Nuts | 39 | 3 |
| Spear | 0 | 19 |
| Stone | 46 | 11 |
| Wood | 163 | 71 |

#### Failures

- **Gather:** inventory_full=51, not_harvestable=20, resource_invalid=5, empty_switch:not_harvestable=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAWO | 0 | 0 | 0 | 4 | idle 55%, herd_wildnpc 22%, gather 20% |
| BUSU | 0 | 0 | 1 | 2 | herd_wildnpc 58%, gather 41%, wander 0% |
| COGE | 0 | 0 | 1 | 0 | herd_wildnpc 41%, wander 39%, gather 20% |
| DEUG | 0 | 0 | 0 | 9 | idle 60%, gather 19%, herd_wildnpc 9% |
| DOWE | 0 | 0 | 0 | 7 | idle 74%, gather 22%, eat 4% |
| FAQI | 0 | 0 | 1 | 11 | idle 45%, gather 19%, herd_wildnpc 15% |
| GEOM | 0 | 0 | 1 | 5 | gather 48%, wander 26%, herd_wildnpc 25% |
| GIRU | 0 | 0 | 1 | 3 | herd_wildnpc 60%, gather 40%, wander 0% |
| HOON | 0 | 0 | 0 | 3 | herd_wildnpc 57%, gather 42%, wander 1% |
| HOOQ | 0 | 0 | 1 | 5 | herd_wildnpc 75%, gather 21%, wander 4% |
| JAFA | 0 | 0 | 2 | 16 | idle 72%, gather 18%, herd_wildnpc 4% |
| JOOK | 0 | 0 | 0 | 7 | gather 75%, idle 13%, herd_wildnpc 10% |
| LOAF | 0 | 0 | 1 | 21 | idle 41%, gather 41%, herd_wildnpc 8% |
| MUIP | 0 | 0 | 1 | 14 | idle 57%, gather 22%, herd_wildnpc 15% |
| NAOH | 0 | 0 | 0 | 3 | herd_wildnpc 78%, gather 13%, wander 8% |
| NEAF | 0 | 0 | 13 | 40 | wander 44%, gather 31%, herd_wildnpc 17% |
| NEDU | 0 | 0 | 1 | 15 | idle 50%, gather 41%, wander 5% |
| NOMI | 0 | 0 | 0 | 11 | idle 63%, gather 25%, herd_wildnpc 7% |
| POAH | 0 | 0 | 1 | 7 | gather 93%, eat 5%, idle 1% |
| QIUZ | 0 | 0 | 0 | 0 | gather 100% |
| ROOB | 0 | 0 | 1 | 12 | idle 67%, gather 21%, herd_wildnpc 5% |
| ROOL | 0 | 0 | 1 | 5 | idle 86%, gather 11%, eat 3% |
| TAAR | 0 | 0 | 0 | 9 | gather 67%, wander 30%, herd_wildnpc 2% |
| TAUV | 0 | 0 | 0 | 0 | gather 61%, wander 38%, idle 1% |
| TEAT | 0 | 0 | 0 | 4 | idle 78%, gather 12%, wander 6% |
| TEXO | 0 | 0 | 4 | 30 | gather 50%, wander 24%, herd_wildnpc 10% |
| VAAH | 0 | 0 | 2 | 5 | gather 73%, herd_wildnpc 16%, wander 8% |
| VIOS | 0 | 0 | 0 | 0 | gather 100% |
| XOCU | 0 | 0 | 0 | 4 | herd_wildnpc 42%, wander 36%, gather 21% |
| YEAZ | 0 | 0 | 0 | 10 | idle 51%, gather 38%, eat 7% |
| YEFO | 0 | 0 | 1 | 5 | idle 87%, gather 10%, eat 3% |
| YIAL | 0 | 0 | 0 | 10 | gather 74%, herd_wildnpc 23%, eat 3% |
| ZEHU | 0 | 0 | 2 | 14 | gather 64%, wander 22%, herd_wildnpc 12% |
| ZOKI | 0 | 0 | 1 | 8 | gather 61%, wander 20%, herd_wildnpc 18% |

#### Buildings

- t=49.6s **Living Hut** — herder_hut (builder: NEAF)
- t=193.2s **Living Hut** — herder_hut (builder: FAQI)
- t=242.3s **Living Hut** — herder_hut (builder: DEUG)
- t=363.1s **Living Hut** — herder_hut (builder: TEXO)
- t=456.2s **Living Hut** — herder_hut (builder: FAQI)
- t=465.2s **Oven** — milestone

### MU WUOK

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/6 (66% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 12 | 9 |
| Grain | 3 | 0 |
| Mushroom | 3 | 0 |
| Nuts | 38 | 2 |
| Spear | 0 | 11 |
| Stone | 21 | 7 |
| Wood | 178 | 94 |

#### Failures

- **Gather:** inventory_full=65, empty_switch:not_harvestable=19, not_harvestable=4, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BETI | 0 | 0 | 0 | 4 | gather 39%, idle 31%, herd_wildnpc 29% |
| BOUS | 0 | 0 | 2 | 10 | idle 53%, herd_wildnpc 26%, gather 14% |
| CUUM | 0 | 0 | 0 | 4 | idle 79%, gather 20%, wander 1% |
| DAQI | 0 | 0 | 0 | 5 | idle 75%, gather 12%, herd_wildnpc 10% |
| DEUJ | 0 | 0 | 0 | 4 | idle 85%, gather 14%, wander 1% |
| GOYU | 0 | 0 | 14 | 53 | wander 36%, gather 33%, herd_wildnpc 23% |
| HOKI | 0 | 0 | 1 | 11 | gather 96%, eat 3%, wander 1% |
| KIOX | 0 | 0 | 2 | 16 | gather 42%, herd_wildnpc 39%, wander 12% |
| KIQI | 0 | 0 | 0 | 4 | gather 65%, idle 34%, wander 1% |
| LENU | 0 | 0 | 3 | 21 | idle 41%, herd_wildnpc 31%, gather 20% |
| LOAM | 0 | 0 | 0 | 4 | idle 86%, gather 13%, wander 1% |
| MUIK | 0 | 0 | 0 | 6 | idle 88%, gather 10%, eat 1% |
| NUFA | 0 | 0 | 1 | 6 | idle 74%, gather 18%, herd_wildnpc 8% |
| PAAP | 0 | 0 | 0 | 0 | wander 67%, gather 31%, idle 2% |
| TINE | 0 | 0 | 0 | 5 | idle 88%, gather 6%, wander 4% |
| VIFA | 0 | 0 | 2 | 19 | idle 55%, gather 22%, herd_wildnpc 10% |
| WEXO | 0 | 0 | 2 | 24 | gather 57%, herd_wildnpc 26%, idle 10% |
| WOYI | 0 | 0 | 4 | 19 | idle 51%, gather 34%, herd_wildnpc 13% |
| YIAN | 0 | 0 | 1 | 17 | gather 42%, idle 36%, herd_wildnpc 9% |
| ZUOX | 0 | 0 | 2 | 23 | gather 45%, idle 38%, herd_wildnpc 10% |

#### Buildings

- t=36.2s **Living Hut** — herder_hut (builder: GOYU)
- t=109.0s **Living Hut** — herder_hut (builder: VIFA)
- t=214.0s **Dairy Farm** — milestone
- t=224.0s **Farm** — milestone

### RA CEDU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 6/6 (64% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 3 |
| Grain | 7 | 2 |
| Nuts | 8 | 0 |
| Spear | 0 | 4 |
| Stone | 26 | 21 |
| Wood | 42 | 15 |

#### Failures

- **Gather:** inventory_full=22, not_harvestable=3, empty_switch:not_harvestable=2, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BOZA | 0 | 0 | 1 | 6 | idle 72%, herd_wildnpc 16%, gather 11% |
| CILI | 0 | 0 | 0 | 10 | idle 67%, gather 28%, herd_wildnpc 3% |
| DATE | 0 | 0 | 0 | 0 | herd_wildnpc 93%, gather 7% |
| DAXO | 0 | 0 | 1 | 4 | idle 34%, herd_wildnpc 30%, gather 24% |
| FAEH | 0 | 0 | 0 | 4 | idle 91%, gather 6%, wander 3% |
| JIVA | 0 | 0 | 0 | 10 | idle 79%, gather 17%, eat 2% |
| NIOC | 0 | 0 | 0 | 3 | herd_wildnpc 85%, wander 12%, gather 3% |
| PUIS | 0 | 0 | 3 | 18 | herd_wildnpc 67%, gather 22%, wander 8% |
| VEIH | 0 | 0 | 8 | 31 | herd_wildnpc 49%, gather 24%, wander 22% |

#### Buildings

- t=135.3s **Living Hut** — herder_hut (builder: VEIH)
- t=341.1s **Dairy Farm** — milestone
- t=381.1s **Oven** — milestone
- t=574.3s **Farm** — milestone

### VA TIER

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/5 (51% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.8 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 39 | 29 |
| Fiber | 9 | 3 |
| Grain | 27 | 7 |
| Mushroom | 1 | 0 |
| Nuts | 43 | 8 |
| Spear | 0 | 12 |
| Stone | 19 | 8 |
| Wood | 164 | 67 |

#### Failures

- **Gather:** inventory_full=35, not_harvestable=16, empty_switch:not_harvestable=11, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CEVU | 0 | 0 | 0 | 4 | idle 41%, gather 26%, wander 26% |
| DOMU | 0 | 0 | 1 | 5 | idle 88%, eat 6%, gather 6% |
| FOUQ | 0 | 0 | 0 | 10 | idle 56%, gather 23%, build_hut_for_woman 9% |
| HOEX | 0 | 0 | 1 | 6 | idle 72%, gather 21%, eat 6% |
| JUDI | 0 | 0 | 1 | 11 | idle 64%, gather 31%, eat 5% |
| KAYI | 0 | 0 | 0 | 4 | idle 72%, gather 21%, eat 6% |
| MIEX | 0 | 0 | 5 | 18 | gather 76%, idle 17%, eat 5% |
| MIOZ | 0 | 0 | 1 | 11 | idle 62%, gather 26%, eat 6% |
| NEUL | 0 | 0 | 20 | 64 | wander 40%, gather 39%, herd_wildnpc 12% |
| NIBO | 0 | 0 | 0 | 4 | idle 88%, eat 7%, gather 5% |
| PUBA | 0 | 0 | 0 | 11 | idle 62%, gather 33%, eat 5% |
| QAEN | 0 | 0 | 0 | 12 | idle 45%, gather 42%, eat 6% |
| QUDU | 0 | 0 | 0 | 4 | idle 86%, gather 8%, eat 5% |
| RESU | 0 | 0 | 0 | 4 | idle 62%, craft 25%, gather 7% |
| SABI | 0 | 0 | 2 | 15 | gather 48%, herd_wildnpc 29%, craft 10% |
| SEEW | 0 | 0 | 1 | 15 | idle 49%, gather 26%, craft 20% |
| SIJI | 0 | 0 | 0 | 0 | gather 100% |
| TEIB | 0 | 0 | 4 | 21 | idle 57%, gather 21%, herd_wildnpc 8% |
| VEBE | 0 | 0 | 0 | 10 | idle 69%, gather 19%, craft 6% |
| VOPE | 0 | 0 | 0 | 6 | gather 77%, idle 17%, eat 5% |
| WANI | 0 | 0 | 3 | 15 | gather 88%, wander 10%, eat 2% |
| WUEK | 0 | 0 | 3 | 25 | gather 43%, idle 39%, eat 6% |
| XIAV | 0 | 0 | 4 | 16 | gather 73%, wander 19%, herd_wildnpc 6% |
| YOWA | 0 | 0 | 0 | 8 | idle 54%, gather 41%, eat 5% |
| ZIIB | 0 | 0 | 0 | 3 | gather 79%, wander 20%, idle 1% |

#### Buildings

- t=34.4s **Living Hut** — herder_hut (builder: NEUL)
- t=174.4s **Living Hut** — herder_hut (builder: TEIB)
- t=217.0s **Living Hut** — herder_hut (builder: FOUQ)
- t=278.0s **Living Hut** — herder_hut (builder: FOUQ)

