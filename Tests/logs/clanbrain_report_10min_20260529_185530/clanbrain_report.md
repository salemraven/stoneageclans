# ClanBrain Report (standard)

## Session

- **Duration:** 600.5s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_10min_20260529_185530/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 10 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| BA MEIB | 0→42 | 27 | 0.0 | 2 | 2 | 297 | 138 | 11 | 53% | 80.1s | 26 | 5 | 81.1s |
| QA NIIZ | 0→20 | 14 | 0.0 | 2 | 2 | 199 | 116 | 6 | 73% | 80.1s | 13 | 2 | 81.5s |
| TA FEOS | 0→26 | 19 | 0.0 | 2 | 2 | 251 | 146 | 23 | 61% | 80.1s | 18 | 3 | 80.7s |
| XE TEIJ | 0→14 | 12 | 0.0 | 2 | 2 | 158 | 97 | 15 | 48% | 80.1s | 11 | 1 | 83.2s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 8 / 8
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| BA MEIB | — | — | 53% | 20% | 0.0→0.3→0.0 | 80.1s |
| QA NIIZ | — | — | 73% | 20% | 0.0→0.6→0.0 | 80.1s |
| TA FEOS | — | — | 61% | 20% | 0.0→0.4→0.0 | 80.1s |
| XE TEIJ | — | — | 48% | 20% | 0.0→0.3→0.0 | 80.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| BA MEIB | 2 | 2 | 0 | 0 | 0 | 1 | 0 |
| QA NIIZ | 2 | 2 | 0 | 0 | 0 | 2 | 0 |
| TA FEOS | 2 | 2 | 0 | 0 | 0 | 2 | 0 |
| XE TEIJ | 2 | 2 | 0 | 0 | 0 | 1 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| BA MEIB | 5 | 26 | 26 | 78.5s |
| QA NIIZ | 2 | 13 | 13 | 77.7s |
| TA FEOS | 2 | 18 | 18 | 77.5s |
| XE TEIJ | 1 | 11 | 11 | 80.6s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| BA MEIB | 0 | 0 | — | 0 | 7 | idle 46%, gather 31%, herd_wildnpc 9% |
| QA NIIZ | 0 | 0 | — | 0 | 13 | gather 36%, combat 24%, idle 19% |
| TA FEOS | 0 | 0 | — | 0 | 9 | gather 49%, idle 22%, herd_wildnpc 12% |
| XE TEIJ | 0 | 0 | — | 0 | 12 | gather 40%, idle 33%, wander 6% |

## Economy (session)

- **Items gathered:** 905
- **Items deposited:** 497
- **Deposit yield:** 55%
- **Gather failures (all):** 403
- **Gather failures (actionable):** 55
- **Deposit failures:** 0

### Gather failures (actionable)

- **not_harvestable:** 47
- **empty_switch:not_harvestable:** 37
- **resource_invalid:** 8

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 87 | 34 | 39% |
| Bone | 0 | 19 | — |
| Fiber | 67 | 33 | 49% |
| Grain | 55 | 15 | 27% |
| Hide | 0 | 27 | — |
| Meat | 0 | 29 | — |
| Mushroom | 11 | 2 | 18% |
| Nuts | 120 | 14 | 12% |
| Spear | 0 | 52 | — |
| Stone | 77 | 42 | 55% |
| Wood | 488 | 230 | 47% |

## Buildings (session)

- **Total placed:** 11

### By type

- **Living Hut:** 5
- **Oven:** 3
- **Dairy Farm:** 2
- **Farm:** 1

### By source

- **milestone:** 6
- **herder_hut:** 5

### Chronological

- t=45.0s **TA FEOS** — Living Hut (herder_hut) builder=MUOF @ (1247,2122)
- t=45.2s **QA NIIZ** — Living Hut (herder_hut) builder=XAET @ (-2974,-635)
- t=46.0s **BA MEIB** — Living Hut (herder_hut) builder=KOUY @ (2077,-820)
- t=48.1s **XE TEIJ** — Living Hut (herder_hut) builder=LEJI @ (-1039,-2963)
- t=206.9s **BA MEIB** — Living Hut (herder_hut) builder=VUNU @ (1878,-951)
- t=260.9s **TA FEOS** — Dairy Farm (milestone) @ (1270,2068)
- t=261.2s **BA MEIB** — Farm (milestone) @ (1925,-1000)
- t=276.2s **BA MEIB** — Dairy Farm (milestone) @ (1864,-903)
- t=390.0s **QA NIIZ** — Oven (milestone) @ (-3189,-733)
- t=526.3s **TA FEOS** — Oven (milestone) @ (1093,1944)
- t=580.4s **BA MEIB** — Oven (milestone) @ (2104,-895)

## Per-clan detail

### BA MEIB

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/8 (53% fill)
- **Pressure:** defend 0.12 | search 0.3 | gather 0.58
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 30 | 8 |
| Bone | 0 | 4 |
| Fiber | 32 | 15 |
| Grain | 12 | 5 |
| Hide | 0 | 7 |
| Meat | 0 | 7 |
| Mushroom | 5 | 0 |
| Nuts | 39 | 5 |
| Spear | 0 | 13 |
| Stone | 26 | 13 |
| Wood | 153 | 61 |

#### Failures

- **Gather:** inventory_full=117, empty_switch:not_harvestable=13, not_harvestable=9, resource_invalid=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DEYO | 0 | 0 | 1 | 10 | idle 62%, gather 20%, herd_wildnpc 9% |
| GAYI | 0 | 0 | 0 | 8 | idle 64%, gather 21%, herd_wildnpc 10% |
| HAIB | 0 | 0 | 0 | 9 | gather 81%, wander 16%, eat 2% |
| HEUP | 0 | 0 | 1 | 12 | gather 92%, eat 8%, herd_wildnpc 0% |
| JAFU | 0 | 0 | 0 | 6 | idle 73%, gather 16%, party 5% |
| KIUM | 0 | 0 | 0 | 4 | idle 73%, herd_wildnpc 13%, gather 9% |
| KOBO | 0 | 0 | 0 | 10 | idle 68%, gather 22%, eat 6% |
| KOUY | 0 | 0 | 11 | 34 | gather 37%, wander 32%, herd_wildnpc 12% |
| KUAM | 0 | 0 | 1 | 12 | gather 43%, idle 40%, herd_wildnpc 7% |
| LEXE | 0 | 0 | 3 | 9 | idle 66%, gather 19%, party 5% |
| LUDU | 0 | 0 | 0 | 5 | idle 72%, herd_wildnpc 13%, gather 10% |
| MUEN | 0 | 0 | 2 | 11 | gather 74%, wander 22%, eat 3% |
| PIXA | 0 | 0 | 3 | 19 | idle 37%, gather 31%, herd_wildnpc 15% |
| QOIM | 0 | 0 | 0 | 8 | gather 94%, eat 5%, wander 1% |
| RAJE | 0 | 0 | 1 | 13 | gather 70%, herd_wildnpc 18%, wander 8% |
| RAQI | 0 | 0 | 0 | 0 | gather 100% |
| SAYU | 0 | 0 | 2 | 19 | idle 43%, gather 26%, herd_wildnpc 16% |
| SUFA | 0 | 0 | 0 | 10 | gather 55%, idle 23%, herd_wildnpc 18% |
| SUNA | 0 | 0 | 0 | 4 | gather 97%, eat 2%, herd_wildnpc 1% |
| TOCO | 0 | 0 | 3 | 9 | idle 77%, gather 11%, party 5% |
| VAJO | 0 | 0 | 0 | 4 | idle 44%, gather 36%, herd_wildnpc 16% |
| VUNU | 0 | 0 | 4 | 22 | idle 43%, gather 18%, herd_wildnpc 16% |
| WEEX | 0 | 0 | 1 | 18 | idle 48%, gather 26%, herd_wildnpc 16% |
| YIUS | 0 | 0 | 1 | 22 | gather 53%, idle 36%, wander 7% |
| YUUD | 0 | 0 | 0 | 5 | idle 49%, gather 21%, herd_wildnpc 21% |
| ZUKA | 0 | 0 | 0 | 9 | idle 62%, gather 28%, wander 6% |
| ZUOG | 0 | 0 | 0 | 5 | idle 70%, gather 24%, wander 4% |

#### Hunts

- start t=81.1s prey=deer quota=2
- start t=141.1s prey=deer quota=4
- hunt_completed t=140.3s reason=loot_complete
- hunt_completed t=175.3s reason=loot_complete

#### Buildings

- t=46.0s **Living Hut** — herder_hut (builder: KOUY)
- t=206.9s **Living Hut** — herder_hut (builder: VUNU)
- t=261.2s **Farm** — milestone
- t=276.2s **Dairy Farm** — milestone
- t=580.4s **Oven** — milestone

### QA NIIZ

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 4/4 (73% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.6 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 33 | 20 |
| Bone | 0 | 6 |
| Fiber | 9 | 2 |
| Grain | 16 | 6 |
| Hide | 0 | 8 |
| Meat | 0 | 8 |
| Nuts | 27 | 3 |
| Spear | 0 | 12 |
| Stone | 29 | 17 |
| Wood | 85 | 34 |

#### Failures

- **Gather:** inventory_full=76, not_harvestable=5, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CUVO | 0 | 0 | 4 | 14 | gather 57%, wander 25%, build_hut_for_woman 9% |
| DOIZ | 0 | 0 | 3 | 28 | gather 43%, combat 24%, wander 16% |
| FUOB | 0 | 0 | 1 | 10 | gather 80%, idle 12%, wander 4% |
| JAAP | 0 | 0 | 2 | 15 | combat 40%, gather 29%, idle 19% |
| PAWO | 0 | 0 | 1 | 0 | combat 76%, gather 16%, wander 8% |
| PEIZ | 0 | 0 | 0 | 9 | combat 63%, idle 23%, gather 12% |
| RUTA | 0 | 0 | 1 | 23 | gather 49%, idle 41%, eat 5% |
| SUED | 0 | 0 | 0 | 4 | combat 64%, gather 23%, herd_wildnpc 9% |
| TAYA | 0 | 0 | 2 | 13 | idle 29%, gather 29%, combat 26% |
| VAQI | 0 | 0 | 2 | 19 | gather 57%, wander 17%, herd_wildnpc 13% |
| XAET | 0 | 0 | 9 | 28 | gather 39%, wander 23%, agro 12% |
| XOWE | 0 | 0 | 1 | 11 | gather 54%, idle 34%, wander 6% |
| YILI | 0 | 0 | 3 | 9 | idle 47%, combat 22%, gather 21% |
| ZIFA | 0 | 0 | 4 | 16 | gather 37%, combat 26%, idle 17% |

#### Hunts

- start t=81.5s prey=deer quota=2
- start t=136.5s prey=deer quota=3
- hunt_completed t=133.8s reason=loot_complete
- hunt_completed t=173.9s reason=loot_complete

#### Buildings

- t=45.2s **Living Hut** — herder_hut (builder: XAET)
- t=390.0s **Oven** — milestone

### TA FEOS

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/5 (61% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.4 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Bone | 0 | 6 |
| Fiber | 26 | 16 |
| Grain | 18 | 2 |
| Hide | 0 | 8 |
| Meat | 0 | 7 |
| Mushroom | 4 | 2 |
| Nuts | 36 | 3 |
| Spear | 0 | 16 |
| Stone | 21 | 12 |
| Wood | 143 | 74 |

#### Failures

- **Gather:** inventory_full=68, not_harvestable=22, empty_switch:not_harvestable=16, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAGU | 0 | 0 | 3 | 24 | gather 44%, herd_wildnpc 31%, wander 14% |
| COGE | 0 | 0 | 4 | 16 | idle 54%, gather 28%, party 6% |
| DIOL | 0 | 0 | 4 | 14 | gather 35%, herd_wildnpc 28%, idle 23% |
| FEAX | 0 | 0 | 0 | 7 | gather 84%, wander 12%, eat 3% |
| FEBI | 0 | 0 | 1 | 17 | idle 61%, gather 35%, eat 4% |
| HEGO | 0 | 0 | 0 | 11 | gather 52%, idle 42%, eat 6% |
| HUTE | 0 | 0 | 2 | 18 | gather 63%, herd_wildnpc 24%, wander 9% |
| JAHI | 0 | 0 | 1 | 16 | gather 53%, idle 33%, wander 9% |
| KIAP | 0 | 0 | 1 | 16 | gather 72%, wander 14%, herd_wildnpc 10% |
| LOTO | 0 | 0 | 3 | 26 | gather 61%, herd_wildnpc 22%, wander 12% |
| MODO | 0 | 0 | 0 | 3 | gather 97%, wander 2%, idle 1% |
| MUOF | 0 | 0 | 11 | 30 | gather 44%, wander 26%, herd_wildnpc 14% |
| NAAB | 0 | 0 | 1 | 6 | idle 56%, gather 32%, wander 9% |
| SISU | 0 | 0 | 1 | 4 | gather 80%, wander 20%, herd_wildnpc 0% |
| SUBI | 0 | 0 | 1 | 12 | idle 56%, gather 26%, herd_wildnpc 13% |
| VIPE | 0 | 0 | 1 | 7 | gather 89%, wander 8%, eat 3% |
| WAQE | 0 | 0 | 1 | 4 | gather 71%, wander 28%, herd_wildnpc 1% |
| WEBE | 0 | 0 | 1 | 11 | gather 68%, wander 28%, eat 4% |
| ZAZA | 0 | 0 | 1 | 9 | gather 74%, herd_wildnpc 12%, wander 11% |

#### Hunts

- start t=80.7s prey=deer quota=2
- start t=135.8s prey=deer quota=3
- hunt_completed t=134.2s reason=loot_complete
- hunt_completed t=199.5s reason=loot_complete

#### Buildings

- t=45.0s **Living Hut** — herder_hut (builder: MUOF)
- t=260.9s **Dairy Farm** — milestone
- t=526.3s **Oven** — milestone

### XE TEIJ

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/5 (48% fill)
- **Pressure:** defend 0.1 | search 0.45 | gather 0.45
- **Food days buffer:** 0.0 → 0.3 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 21 | 6 |
| Bone | 0 | 3 |
| Grain | 9 | 2 |
| Hide | 0 | 4 |
| Meat | 0 | 7 |
| Mushroom | 2 | 0 |
| Nuts | 18 | 3 |
| Spear | 0 | 11 |
| Stone | 1 | 0 |
| Wood | 107 | 61 |

#### Failures

- **Gather:** inventory_full=50, not_harvestable=11, empty_switch:not_harvestable=8, resource_invalid=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BIAT | 0 | 0 | 3 | 7 | idle 69%, gather 19%, hunt 4% |
| HAID | 0 | 0 | 1 | 2 | flee_combat 61%, gather 35%, eat 2% |
| LEJI | 0 | 0 | 8 | 25 | gather 40%, wander 21%, herd_wildnpc 18% |
| LOSU | 0 | 0 | 1 | 10 | gather 57%, idle 37%, eat 5% |
| MIUX | 0 | 0 | 1 | 7 | idle 71%, gather 18%, combat 4% |
| NOUL | 0 | 0 | 0 | 10 | gather 94%, eat 4%, wander 2% |
| QEEP | 0 | 0 | 1 | 7 | gather 36%, combat 34%, flee_combat 21% |
| QUCO | 0 | 0 | 4 | 34 | gather 51%, idle 24%, herd_wildnpc 12% |
| REEF | 0 | 0 | 1 | 19 | gather 49%, idle 46%, eat 4% |
| RESE | 0 | 0 | 4 | 16 | idle 54%, gather 26%, wander 6% |
| SOAY | 0 | 0 | 1 | 21 | gather 66%, idle 24%, wander 5% |
| WOEQ | 0 | 0 | 1 | 0 | gather 70%, wander 29%, idle 1% |

#### Hunts

- start t=83.2s prey=deer quota=2
- start t=138.3s prey=deer quota=4
- hunt_completed t=134.3s reason=loot_complete
- hunt_completed t=178.6s reason=loot_complete

#### Buildings

- t=48.1s **Living Hut** — herder_hut (builder: LEJI)

