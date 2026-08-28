# ClanBrain Report (standard)

## Session

- **Duration:** 600.5s
- **JSONL:** `Tests/logs/clanbrain_report_10min_20260528_220420/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| ME ROLU | 0→34 | 29 | 0.0 | 0 | 0 | 319 | 90 | 5 | 85% | 70.0s | 28 | 3 | — |
| RA NEOM | 0→18 | 13 | 0.0 | 0 | 0 | 182 | 97 | 21 | 39% | 80.1s | 12 | 3 | — |
| TI BERE | 0→28 | 20 | 0.0 | 0 | 0 | 205 | 103 | 16 | 71% | 95.1s | 19 | 3 | — |
| ZA VAQE | 0→27 | 18 | 0.0 | 1 | 0 | 150 | 37 | 4 | 65% | 75.1s | 17 | 2 | 142.0s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 1 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 1

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| ME ROLU | — | — | 85% | 33% | 0.0→0.1→0.0 | 70.0s |
| RA NEOM | — | — | 39% | 17% | 0.0→0.0→0.0 | 80.1s |
| TI BERE | — | — | 71% | 11% | 0.0→0.1→0.0 | 95.1s |
| ZA VAQE | — | — | 65% | 25% | 0.0→0.1→0.0 | 75.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| ME ROLU | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| RA NEOM | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| TI BERE | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| ZA VAQE | 1 | 0 | 1 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| ME ROLU | 3 | 28 | 28 | 68.6s |
| RA NEOM | 1 | 13 | 12 | 79.2s |
| TI BERE | 2 | 20 | 19 | 95.7s |
| ZA VAQE | 4 | 17 | 17 | 74.2s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| ME ROLU | 0 | 0 | — | 0 | 20 | idle 58%, gather 26%, wander 6% |
| RA NEOM | 0 | 0 | — | 0 | 6 | idle 47%, gather 32%, herd_wildnpc 11% |
| TI BERE | 0 | 0 | — | 0 | 8 | gather 36%, idle 29%, herd_wildnpc 21% |
| ZA VAQE | 0 | 0 | — | 0 | 18 | idle 32%, combat 21%, gather 20% |

## Economy (session)

- **Items gathered:** 856
- **Items deposited:** 327
- **Deposit yield:** 38%
- **Gather failures (all):** 374
- **Gather failures (actionable):** 46
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 57
- **not_harvestable:** 40
- **resource_invalid:** 6

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 29 | 4 | 14% |
| Fiber | 23 | 9 | 39% |
| Grain | 30 | 1 | 3% |
| Mushroom | 5 | 0 | 0% |
| Nuts | 120 | 9 | 8% |
| Spear | 0 | 33 | — |
| Stone | 59 | 34 | 58% |
| Wood | 590 | 237 | 40% |

## Buildings (session)

- **Total placed:** 11

### By type

- **Living Hut:** 7
- **Dairy Farm:** 2
- **Farm:** 1
- **Oven:** 1

### By source

- **herder_hut:** 7
- **milestone:** 4

### Chronological

- t=36.1s **ME ROLU** — Living Hut (herder_hut) builder=LOCI @ (347,-2609)
- t=41.7s **ZA VAQE** — Living Hut (herder_hut) builder=BUNE @ (2189,-941)
- t=46.7s **RA NEOM** — Living Hut (herder_hut) builder=ZANE @ (1412,2584)
- t=63.2s **TI BERE** — Living Hut (herder_hut) builder=XAAG @ (-3409,174)
- t=63.2s **ME ROLU** — Living Hut (herder_hut) builder=LOCI @ (155,-2752)
- t=101.9s **ZA VAQE** — Farm (milestone) @ (2348,-780)
- t=191.0s **ME ROLU** — Living Hut (herder_hut) builder=ZIOT @ (374,-2665)
- t=216.0s **RA NEOM** — Oven (milestone) @ (1359,2648)
- t=388.1s **TI BERE** — Living Hut (herder_hut) builder=SASU @ (-3544,-17)
- t=476.2s **RA NEOM** — Dairy Farm (milestone) @ (1572,2755)
- t=529.5s **TI BERE** — Dairy Farm (milestone) @ (-3347,114)

## Per-clan detail

### ME ROLU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 6/6 (85% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 0 |
| Grain | 15 | 0 |
| Mushroom | 1 | 0 |
| Nuts | 49 | 4 |
| Spear | 0 | 11 |
| Stone | 14 | 6 |
| Wood | 231 | 69 |

#### Failures

- **Gather:** inventory_full=93, empty_switch:not_harvestable=28, not_harvestable=4, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIOX | 0 | 0 | 0 | 9 | idle 74%, gather 19%, herd_wildnpc 6% |
| DEXO | 0 | 0 | 0 | 10 | idle 83%, gather 13%, eat 2% |
| DIJU | 0 | 0 | 0 | 0 | gather 100% |
| FOHO | 0 | 0 | 0 | 10 | idle 58%, gather 36%, wander 3% |
| FOTO | 0 | 0 | 0 | 9 | idle 80%, gather 17%, eat 2% |
| GAZO | 0 | 0 | 1 | 10 | gather 57%, idle 33%, wander 5% |
| GUON | 0 | 0 | 0 | 9 | idle 77%, gather 20%, eat 3% |
| LOCI | 0 | 0 | 13 | 54 | wander 45%, gather 38%, build_hut_for_woman 8% |
| LUIZ | 0 | 0 | 0 | 11 | idle 53%, herd_wildnpc 26%, gather 19% |
| MESO | 0 | 0 | 0 | 9 | idle 73%, gather 19%, wander 5% |
| NASE | 0 | 0 | 0 | 6 | gather 92%, wander 7%, idle 1% |
| QUWA | 0 | 0 | 1 | 6 | idle 79%, gather 14%, wander 5% |
| RUIY | 0 | 0 | 2 | 19 | idle 38%, herd_wildnpc 26%, gather 24% |
| SAOY | 0 | 0 | 2 | 19 | idle 63%, gather 28%, herd_wildnpc 3% |
| SEAS | 0 | 0 | 0 | 0 | gather 100% |
| TAOS | 0 | 0 | 0 | 9 | idle 84%, gather 13%, eat 3% |
| TEOZ | 0 | 0 | 0 | 10 | idle 77%, gather 19%, eat 2% |
| TOEW | 0 | 0 | 2 | 25 | idle 48%, gather 31%, herd_wildnpc 10% |
| TUIB | 0 | 0 | 2 | 16 | idle 41%, herd_wildnpc 30%, gather 20% |
| VEIY | 0 | 0 | 0 | 9 | idle 51%, gather 37%, wander 5% |
| VOIY | 0 | 0 | 2 | 12 | gather 59%, wander 19%, idle 11% |
| VOUR | 0 | 0 | 0 | 9 | gather 51%, idle 35%, wander 14% |
| WAAW | 0 | 0 | 0 | 9 | idle 49%, gather 36%, herd_wildnpc 8% |
| WIEF | 0 | 0 | 0 | 9 | idle 53%, gather 41%, eat 6% |
| WIMA | 0 | 0 | 1 | 0 | gather 100% |
| YOJO | 0 | 0 | 1 | 9 | gather 83%, idle 11%, eat 6% |
| ZIOT | 0 | 0 | 1 | 7 | idle 75%, gather 16%, build_hut_for_woman 4% |
| ZOBA | 0 | 0 | 0 | 10 | idle 79%, gather 16%, wander 3% |
| ZOOS | 0 | 0 | 0 | 4 | idle 84%, gather 15%, eat 1% |

#### Buildings

- t=36.1s **Living Hut** — herder_hut (builder: LOCI)
- t=63.2s **Living Hut** — herder_hut (builder: LOCI)
- t=191.0s **Living Hut** — herder_hut (builder: ZIOT)

### RA NEOM

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/6 (39% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 8 | 0 |
| Fiber | 8 | 3 |
| Grain | 6 | 1 |
| Mushroom | 1 | 0 |
| Nuts | 22 | 2 |
| Spear | 0 | 7 |
| Stone | 34 | 19 |
| Wood | 103 | 65 |

#### Failures

- **Gather:** inventory_full=24, not_harvestable=20, empty_switch:not_harvestable=8, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| COOC | 0 | 0 | 0 | 10 | idle 83%, gather 15%, eat 2% |
| DIBA | 0 | 0 | 0 | 5 | gather 47%, idle 44%, eat 6% |
| GOAJ | 0 | 0 | 2 | 19 | idle 51%, gather 26%, herd_wildnpc 11% |
| HAEL | 0 | 0 | 5 | 36 | gather 44%, idle 27%, herd_wildnpc 16% |
| HIMO | 0 | 0 | 0 | 4 | idle 65%, gather 33%, eat 2% |
| HOOX | 0 | 0 | 0 | 0 | gather 53%, wander 46%, idle 1% |
| KEIW | 0 | 0 | 2 | 16 | gather 61%, herd_wildnpc 32%, wander 5% |
| LOQU | 0 | 0 | 0 | 4 | idle 83%, herd_wildnpc 12%, gather 4% |
| TIAY | 0 | 0 | 1 | 5 | idle 89%, gather 9%, eat 1% |
| VAUW | 0 | 0 | 3 | 11 | gather 63%, herd_wildnpc 26%, wander 10% |
| YOQA | 0 | 0 | 0 | 10 | gather 48%, idle 46%, eat 5% |
| YUOL | 0 | 0 | 1 | 5 | idle 71%, gather 26%, wander 2% |
| ZANE | 0 | 0 | 20 | 57 | gather 45%, wander 26%, herd_wildnpc 21% |

#### Buildings

- t=46.7s **Living Hut** — herder_hut (builder: ZANE)
- t=216.0s **Oven** — milestone
- t=476.2s **Dairy Farm** — milestone

### TI BERE

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/5 (71% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 12 | 4 |
| Fiber | 12 | 6 |
| Grain | 3 | 0 |
| Mushroom | 1 | 0 |
| Nuts | 27 | 2 |
| Spear | 0 | 10 |
| Stone | 9 | 7 |
| Wood | 141 | 74 |

#### Failures

- **Gather:** not_harvestable=15, empty_switch:not_harvestable=9, inventory_full=6, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEOZ | 0 | 0 | 0 | 4 | idle 82%, gather 17%, eat 1% |
| FEUD | 0 | 0 | 3 | 22 | idle 48%, herd_wildnpc 21%, gather 21% |
| HAVE | 0 | 0 | 2 | 10 | idle 62%, herd_wildnpc 21%, gather 11% |
| HIUD | 0 | 0 | 1 | 11 | gather 71%, wander 23%, eat 4% |
| KENE | 0 | 0 | 0 | 5 | herd_wildnpc 66%, gather 34%, wander 1% |
| LAYE | 0 | 0 | 2 | 19 | idle 50%, gather 24%, wander 12% |
| MAIW | 0 | 0 | 2 | 17 | gather 48%, herd_wildnpc 33%, wander 16% |
| NUUP | 0 | 0 | 0 | 8 | gather 77%, idle 18%, eat 5% |
| PIAP | 0 | 0 | 0 | 0 | gather 100% |
| POUN | 0 | 0 | 3 | 16 | gather 51%, herd_wildnpc 35%, wander 14% |
| QEIF | 0 | 0 | 0 | 10 | idle 47%, gather 46%, eat 6% |
| QOUT | 0 | 0 | 1 | 10 | gather 67%, wander 15%, herd_wildnpc 10% |
| RUPE | 0 | 0 | 0 | 3 | gather 47%, herd_wildnpc 26%, wander 25% |
| SASU | 0 | 0 | 0 | 8 | idle 69%, gather 10%, herd_wildnpc 9% |
| XAAG | 0 | 0 | 10 | 35 | herd_wildnpc 36%, wander 32%, gather 27% |
| YAOD | 0 | 0 | 0 | 0 | wander 36%, herd_wildnpc 35%, gather 25% |
| YAPO | 0 | 0 | 0 | 7 | gather 70%, idle 16%, wander 7% |
| YERE | 0 | 0 | 1 | 4 | gather 73%, wander 22%, herd_wildnpc 5% |
| ZUFO | 0 | 0 | 0 | 5 | gather 60%, idle 33%, eat 6% |
| ZUUH | 0 | 0 | 1 | 11 | gather 57%, herd_wildnpc 35%, wander 7% |

#### Buildings

- t=63.2s **Living Hut** — herder_hut (builder: XAAG)
- t=388.1s **Living Hut** — herder_hut (builder: SASU)
- t=529.5s **Dairy Farm** — milestone

### ZA VAQE

- **Brain:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (65% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.1 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 0 |
| Grain | 6 | 0 |
| Mushroom | 2 | 0 |
| Nuts | 22 | 1 |
| Spear | 0 | 5 |
| Stone | 2 | 2 |
| Wood | 115 | 29 |

#### Failures

- **Gather:** inventory_full=148, empty_switch:not_harvestable=12, resource_invalid=3, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BUEF | 0 | 0 | 0 | 3 | combat 58%, idle 19%, herd_wildnpc 12% |
| BUNE | 0 | 0 | 11 | 27 | hunt 45%, gather 21%, herd_wildnpc 14% |
| FELI | 0 | 0 | 1 | 10 | hunt 41%, idle 33%, gather 14% |
| JOIM | 0 | 0 | 0 | 9 | gather 57%, idle 26%, wander 14% |
| LOHI | 0 | 0 | 0 | 8 | gather 66%, idle 34%, wander 0% |
| MISU | 0 | 0 | 1 | 9 | gather 58%, idle 26%, wander 13% |
| MOXE | 0 | 0 | 2 | 19 | hunt 49%, idle 29%, gather 20% |
| NAKI | 0 | 0 | 0 | 9 | idle 76%, gather 18%, wander 3% |
| PUOZ | 0 | 0 | 0 | 8 | gather 94%, eat 5%, idle 1% |
| RUUJ | 0 | 0 | 1 | 0 | combat 66%, idle 23%, party 9% |
| SEIK | 0 | 0 | 0 | 9 | gather 95%, eat 5%, wander 0% |
| SICO | 0 | 0 | 0 | 3 | gather 100% |
| TAIY | 0 | 0 | 0 | 9 | idle 72%, gather 25%, eat 3% |
| TUWO | 0 | 0 | 0 | 3 | gather 99%, idle 1% |
| VOPA | 0 | 0 | 0 | 9 | idle 86%, gather 14%, eat 0% |
| XIDE | 0 | 0 | 0 | 0 | combat 62%, idle 21%, party 8% |
| YEEG | 0 | 0 | 0 | 9 | gather 92%, eat 5%, idle 3% |
| ZUYO | 0 | 0 | 0 | 6 | gather 69%, wander 30%, idle 1% |

#### Hunts

- start t=142.0s prey=deer quota=4
- hunt_aborted t=431.8s reason=assembly_timeout

#### Buildings

- t=41.7s **Living Hut** — herder_hut (builder: BUNE)
- t=101.9s **Farm** — milestone

