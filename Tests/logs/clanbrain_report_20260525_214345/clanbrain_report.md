# ClanBrain Report

## Session

- **Duration:** 120.4s
- **JSONL:** `Tests/logs/clanbrain_report_20260525_214345/playtest_session.jsonl`
- **NPC-only world:** yes
- **AI clans with eval:** 4

## Summary

| Clan | Pop (start→end) | Fighters | Food days (end) | Hunts | Clansmen grown | Gathered | Deposited | G fail | D fail | Buildings | First hunt |
|------|-----------------|----------|-----------------|-------|----------------|----------|-----------|--------|--------|-----------|------------|
| JI YUEF | 0→13 | 11 | 0.0 | 1 | 10 | 55 | 13 | 74 | 0 | 2 | 25.3s |
| MI KASO | 0→17 | 13 | 0.0 | 1 | 12 | 19 | 19 | 0 | 0 | 2 | 26.7s |
| RO NEGU | 0→17 | 11 | 0.0 | 1 | 10 | 30 | 11 | 25 | 0 | 3 | 22.9s |
| WO FAEC | 0→17 | 15 | 0.1 | 1 | 14 | 35 | 11 | 26 | 0 | 2 | 24.4s |

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 4 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 4

## Economy (session)

- **Items gathered (all clans):** 139
- **Items deposited (all clans):** 54
- **Gather failures:** 125
- **Deposit failures:** 0

### Items by resource (session)

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 2 |
| Fiber | 6 | 3 |
| Mushroom | 1 | 0 |
| Nuts | 22 | 2 |
| Spear | 0 | 20 |
| Stone | 9 | 0 |
| Wood | 92 | 27 |

### Gather failures by reason (session)

- **inventory_full:** 121
- **not_harvestable:** 3
- **resource_invalid:** 1

## Buildings (session)

- **Total placed:** 9

### By type

- **Living Hut:** 9

### By source

- **herder_hut:** 9

### All buildings (chronological)

- t=0.1s **WO FAEC** — Living Hut (herder_hut) builder=WASE @ (1984,486)
- t=0.1s **WO FAEC** — Living Hut (herder_hut) builder=WASE @ (1821,317)
- t=0.2s **MI KASO** — Living Hut (herder_hut) builder=MEPU @ (-933,3342)
- t=0.2s **MI KASO** — Living Hut (herder_hut) builder=MEPU @ (-981,3371)
- t=0.2s **RO NEGU** — Living Hut (herder_hut) builder=TAYU @ (-2529,329)
- t=0.2s **RO NEGU** — Living Hut (herder_hut) builder=TAYU @ (-2738,220)
- t=0.3s **JI YUEF** — Living Hut (herder_hut) builder=HACA @ (944,-1686)
- t=0.3s **JI YUEF** — Living Hut (herder_hut) builder=HACA @ (712,-1735)
- t=57.3s **RO NEGU** — Living Hut (herder_hut) builder=TAYU @ (-2587,370)

## Per-clan detail

### JI YUEF

- **End state:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE
- **Quotas:** defenders 0/0 | searchers 0/0
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Breeding females:** 2 | huntables in AoH: 2
- **Quota update events:** 0

#### Items gathered & deposited

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Mushroom | 1 | 0 |
| Nuts | 11 | 1 |
| Spear | 0 | 3 |
| Stone | 3 | 0 |
| Wood | 37 | 9 |

#### Failures

- **Gather:** inventory_full=73, resource_invalid=1

#### Buildings

- t=0.3s **Living Hut** — herder_hut (builder: HACA)
- t=0.3s **Living Hut** — herder_hut (builder: HACA)
- **Clansmen grown:** DERI, SIOZ, DUME, TAZA, HUER, TAEL, FIAB, MAZO (+2 more)
- **Hunts:**
  - t=25.3s prey=deer quota=3 pressure=1.0

### MI KASO

- **End state:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE
- **Quotas:** defenders 0/0 | searchers 1/0
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Breeding females:** 2 | huntables in AoH: 3
- **Quota update events:** 0

#### Items gathered & deposited

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Nuts | 3 | 1 |
| Spear | 0 | 7 |
| Wood | 16 | 11 |

#### Buildings

- t=0.2s **Living Hut** — herder_hut (builder: MEPU)
- t=0.2s **Living Hut** — herder_hut (builder: MEPU)
- **Clansmen grown:** GUMI, VIWI, FUKU, NITI, PAGU, PEIB, XOET, JIEL (+4 more)
- **Hunts:**
  - t=26.7s prey=deer quota=3 pressure=1.0

### RO NEGU

- **End state:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE
- **Quotas:** defenders 0/0 | searchers 0/0
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Breeding females:** 3 | huntables in AoH: 3
- **Quota update events:** 0

#### Items gathered & deposited

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 0 |
| Fiber | 3 | 3 |
| Nuts | 4 | 0 |
| Spear | 0 | 5 |
| Stone | 3 | 0 |
| Wood | 17 | 3 |

#### Failures

- **Gather:** inventory_full=22, not_harvestable=3

#### Buildings

- t=0.2s **Living Hut** — herder_hut (builder: TAYU)
- t=0.2s **Living Hut** — herder_hut (builder: TAYU)
- t=57.3s **Living Hut** — herder_hut (builder: TAYU)
- **Clansmen grown:** QOGU, GOWU, LEUR, DARA, ZEUX, LAAP, YASI, DAMA (+2 more)
- **Hunts:**
  - t=22.9s prey=deer quota=3 pressure=1.0

### WO FAEC

- **End state:** PEACEFUL | alert NONE | hunt ACTIVE | raid NONE
- **Quotas:** defenders 0/0 | searchers 0/0
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Breeding females:** 2 | huntables in AoH: 3
- **Quota update events:** 0

#### Items gathered & deposited

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 3 | 2 |
| Fiber | 3 | 0 |
| Nuts | 4 | 0 |
| Spear | 0 | 5 |
| Stone | 3 | 0 |
| Wood | 22 | 4 |

#### Failures

- **Gather:** inventory_full=26

#### Buildings

- t=0.1s **Living Hut** — herder_hut (builder: WASE)
- t=0.1s **Living Hut** — herder_hut (builder: WASE)
- **Clansmen grown:** ZUIN, LUKU, KUKI, NEJA, YOAH, ZUBE, LIAQ, XOIX (+6 more)
- **Hunts:**
  - t=24.4s prey=deer quota=3 pressure=1.0

