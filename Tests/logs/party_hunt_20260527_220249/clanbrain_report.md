# ClanBrain Report (standard)

## Session

- **Duration:** 120.7s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/party_hunt_20260527_220249/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| FO WUMA | 0→13 | 11 | 0.3 | 1 | 0 | 64 | 30 | 2 | 8% | 25.0s | 10 | 2 | 27.2s |
| HE DUTA | 0→7 | 5 | 0.2 | 1 | 0 | 25 | 11 | 1 | 17% | 25.0s | 4 | 2 | 27.1s |
| PO WUUJ | 0→16 | 10 | 0.1 | 1 | 0 | 60 | 18 | 1 | 20% | 20.0s | 12 | 3 | 23.1s |
| RA CAGI | 0→11 | 9 | 0.2 | 1 | 0 | 17 | 18 | 1 | 17% | 25.0s | 8 | 2 | 25.6s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 4 / 0
- **⚠ Possible stuck parties (formed − disbanded):** 4

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| FO WUMA | — | — | 8% | — | 0.0→0.4→0.3 | 25.0s |
| HE DUTA | — | — | 17% | — | 0.0→0.2→0.2 | 25.0s |
| PO WUUJ | — | — | 20% | — | 0.0→0.2→0.1 | 20.0s |
| RA CAGI | — | — | 17% | — | 0.0→0.2→0.2 | 25.0s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| FO WUMA | 1 | 0 | 0 | 0 | 0 | 1 | 0 |
| HE DUTA | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| PO WUUJ | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| RA CAGI | 1 | 0 | 0 | 0 | 0 | 1 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| FO WUMA | 0 | 10 | 10 | 22.4s |
| HE DUTA | 0 | 4 | 4 | 22.5s |
| PO WUUJ | 1 | 12 | 12 | 22.4s |
| RA CAGI | 0 | 8 | 8 | 22.4s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| FO WUMA | 0 | 0 | — | 0 | 0 | gather 82%, wander 5%, party 5% |
| HE DUTA | 0 | 0 | — | 0 | 0 | gather 65%, party 15%, hunt 13% |
| PO WUUJ | 0 | 0 | — | 0 | 0 | gather 80%, wander 7%, party 5% |
| RA CAGI | 0 | 0 | — | 0 | 0 | gather 77%, party 9%, hunt 7% |

## Economy (session)

- **Items gathered:** 166
- **Items deposited:** 77
- **Deposit yield:** 46%
- **Gather failures (all):** 127
- **Gather failures (actionable):** 5
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 13
- **resource_invalid:** 4
- **not_harvestable:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 3 | 0 | 0% |
| Bone | 0 | 8 | — |
| Fiber | 3 | 3 | 100% |
| Grain | 12 | 6 | 50% |
| Hide | 0 | 16 | — |
| Meat | 0 | 11 | — |
| Mushroom | 4 | 0 | 0% |
| Nuts | 31 | 1 | 3% |
| Spear | 0 | 25 | — |
| Stone | 11 | 2 | 18% |
| Wood | 102 | 5 | 5% |

## Buildings (session)

- **Total placed:** 9

### By type

- **Living Hut:** 9

### By source

- **herder_hut:** 9

### Chronological

- t=0.4s **PO WUUJ** — Living Hut (herder_hut) builder=WIOR @ (2157,-145)
- t=0.4s **PO WUUJ** — Living Hut (herder_hut) builder=WIOR @ (2228,-226)
- t=0.4s **FO WUMA** — Living Hut (herder_hut) builder=NASE @ (1379,2372)
- t=0.4s **FO WUMA** — Living Hut (herder_hut) builder=NASE @ (1177,2243)
- t=0.4s **RA CAGI** — Living Hut (herder_hut) builder=FIEZ @ (-2833,-1490)
- t=0.4s **RA CAGI** — Living Hut (herder_hut) builder=FIEZ @ (-2877,-1437)
- t=0.5s **HE DUTA** — Living Hut (herder_hut) builder=CIKO @ (435,-3229)
- t=0.5s **HE DUTA** — Living Hut (herder_hut) builder=CIKO @ (200,-3269)
- t=73.9s **PO WUUJ** — Living Hut (herder_hut) builder=WIOR @ (2004,-308)

## Per-clan detail

### FO WUMA

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (8% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.4 → 0.3

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 3 |
| Fiber | 3 | 3 |
| Grain | 6 | 4 |
| Hide | 0 | 4 |
| Meat | 0 | 3 |
| Mushroom | 1 | 0 |
| Nuts | 11 | 0 |
| Spear | 0 | 8 |
| Stone | 5 | 2 |
| Wood | 38 | 3 |

#### Failures

- **Gather:** empty_switch:not_harvestable=9, inventory_full=2, not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CESO | 0 | 0 | 0 | 6 | gather 100% |
| DIUY | 0 | 0 | 1 | 10 | gather 77%, party 17%, combat 5% |
| FIIV | 0 | 0 | 1 | 0 | gather 100% |
| LUUC | 0 | 0 | 1 | 8 | gather 96%, hunt 4% |
| LUUT | 0 | 0 | 1 | 7 | gather 96%, hunt 4% |
| MICU | 0 | 0 | 0 | 0 | gather 100% |
| NASE | 0 | 0 | 4 | 10 | gather 48%, wander 31%, hunt 17% |
| RIBO | 0 | 0 | 1 | 9 | gather 73%, party 17%, combat 5% |
| VEFO | 0 | 0 | 1 | 3 | gather 98%, hunt 2% |
| XIAY | 0 | 0 | 1 | 8 | gather 96%, hunt 4% |
| ZIUB | 0 | 0 | 0 | 3 | gather 100% |

#### Hunts

- start t=27.2s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: NASE)
- t=0.4s **Living Hut** — herder_hut (builder: NASE)

### HE DUTA

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (17% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 1 | 0 |
| Hide | 0 | 4 |
| Meat | 0 | 3 |
| Mushroom | 1 | 0 |
| Nuts | 6 | 0 |
| Spear | 0 | 4 |
| Stone | 2 | 0 |
| Wood | 15 | 0 |

#### Failures

- **Gather:** inventory_full=81, empty_switch:not_harvestable=1, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BOHE | 0 | 0 | 0 | 9 | gather 89%, hunt 11% |
| CIKO | 0 | 0 | 1 | 4 | gather 52%, hunt 36%, combat 8% |
| REUK | 0 | 0 | 1 | 0 | gather 56%, party 34%, combat 9% |
| WUXU | 0 | 0 | 2 | 2 | gather 56%, party 34%, combat 9% |
| ZIVE | 0 | 0 | 1 | 10 | gather 89%, hunt 11% |

#### Hunts

- start t=27.1s prey=deer quota=3

#### Buildings

- t=0.5s **Living Hut** — herder_hut (builder: CIKO)
- t=0.5s **Living Hut** — herder_hut (builder: CIKO)

### PO WUUJ

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (20% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 2 | 0 |
| Bone | 0 | 2 |
| Grain | 3 | 0 |
| Hide | 0 | 4 |
| Meat | 0 | 3 |
| Mushroom | 1 | 0 |
| Nuts | 10 | 1 |
| Spear | 0 | 6 |
| Stone | 4 | 0 |
| Wood | 40 | 2 |

#### Failures

- **Gather:** inventory_full=24, empty_switch:not_harvestable=3, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CIUN | 0 | 0 | 0 | 3 | gather 100% |
| DIPO | 0 | 0 | 1 | 0 | gather 81%, wander 18%, idle 1% |
| JION | 0 | 0 | 1 | 9 | gather 99%, hunt 1% |
| KISE | 0 | 0 | 0 | 0 | gather 100% |
| KOVA | 0 | 0 | 1 | 0 | gather 100% |
| NAEM | 0 | 0 | 2 | 10 | gather 72%, party 20%, wander 7% |
| QIQI | 0 | 0 | 2 | 6 | gather 78%, party 13%, combat 8% |
| SOOR | 0 | 0 | 0 | 8 | gather 87%, wander 11%, hunt 1% |
| WIOR | 0 | 0 | 4 | 6 | gather 45%, wander 19%, build_hut_for_woman 17% |
| WOOS | 0 | 0 | 0 | 9 | gather 100% |
| WOTO | 0 | 0 | 0 | 9 | gather 100% |
| XISE | 0 | 0 | 0 | 0 | gather 100% |
| XOLO | 0 | 0 | 0 | 0 | gather 100% |

#### Hunts

- start t=23.1s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: WIOR)
- t=0.4s **Living Hut** — herder_hut (builder: WIOR)
- t=73.9s **Living Hut** — herder_hut (builder: WIOR)

### RA CAGI

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/0 (17% fill)
- **Pressure:** defend 0.11 | search 0.38 | gather 0.51
- **Food days buffer:** 0.0 → 0.2 → 0.2

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 3 |
| Grain | 3 | 2 |
| Hide | 0 | 4 |
| Meat | 0 | 2 |
| Mushroom | 1 | 0 |
| Nuts | 4 | 0 |
| Spear | 0 | 7 |
| Wood | 9 | 0 |

#### Failures

- **Gather:** inventory_full=2, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FIEZ | 0 | 0 | 3 | 2 | gather 63%, hunt 24%, wander 10% |
| FUBI | 0 | 0 | 0 | 0 | gather 100% |
| JODE | 0 | 0 | 1 | 6 | gather 68%, party 25%, combat 4% |
| KIDI | 0 | 0 | 1 | 0 | gather 94%, hunt 6% |
| LAWE | 0 | 0 | 1 | 0 | gather 100% |
| LEMU | 0 | 0 | 2 | 9 | gather 71%, party 25%, combat 4% |
| LOEG | 0 | 0 | 1 | 0 | gather 100% |
| NUJO | 0 | 0 | 0 | 0 | wander 73%, gather 24%, idle 3% |
| ZOEQ | 0 | 0 | 2 | 0 | gather 94%, hunt 6% |

#### Hunts

- start t=25.6s prey=deer quota=3

#### Buildings

- t=0.4s **Living Hut** — herder_hut (builder: FIEZ)
- t=0.4s **Living Hut** — herder_hut (builder: FIEZ)

