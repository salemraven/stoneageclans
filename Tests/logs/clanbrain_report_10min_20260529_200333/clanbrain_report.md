# ClanBrain Report (standard)

## Session

- **Duration:** 600.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_10min_20260529_200333/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 10 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| CA CEQU | 0→4 | 1 | 0.1 | 0 | 0 | 76 | 73 | 0 | 25% | 598.9s | 0 | 2 | — |
| RA VUWO | 0→7 | 5 | 0.4 | 2 | 2 | 92 | 96 | 4 | 46% | 345.3s | 4 | 2 | 350.0s |
| RO JAUS | 0→8 | 1 | 0.3 | 0 | 0 | 54 | 52 | 0 | 45% | 599.8s | 0 | 3 | — |
| WE DOAZ | 0→16 | 1 | 0.0 | 0 | 0 | 48 | 47 | 1 | 58% | 598.6s | 0 | 3 | — |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 2 / 2
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| CA CEQU | — | — | 25% | 12% | 0.0→0.2→0.1 | 598.9s |
| RA VUWO | — | — | 46% | 11% | 0.0→0.6→0.4 | 345.3s |
| RO JAUS | — | — | 45% | 20% | 0.0→0.3→0.3 | 599.8s |
| WE DOAZ | — | — | 58% | 33% | 0.0→0.0→0.0 | 598.6s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| CA CEQU | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| RA VUWO | 2 | 2 | 0 | 0 | 0 | 2 | 0 |
| RO JAUS | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| WE DOAZ | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| CA CEQU | 2 | 0 | 0 | — |
| RA VUWO | 2 | 4 | 4 | 347.4s |
| RO JAUS | 3 | 0 | 0 | — |
| WE DOAZ | 3 | 0 | 0 | — |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| CA CEQU | 0 | 0 | — | 0 | 0 | gather 38%, wander 33%, herd_wildnpc 19% |
| RA VUWO | 0 | 0 | — | 0 | 2 | gather 40%, craft 21%, wander 13% |
| RO JAUS | 0 | 0 | — | 0 | 0 | wander 32%, herd_wildnpc 32%, gather 22% |
| WE DOAZ | 0 | 0 | — | 0 | 0 | herd_wildnpc 59%, gather 19%, wander 16% |

## Economy (session)

- **Items gathered:** 270
- **Items deposited:** 268
- **Deposit yield:** 99%
- **Gather failures (all):** 55
- **Gather failures (actionable):** 5
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 3
- **not_harvestable:** 3
- **resource_invalid:** 2

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 9 | 7 | 78% |
| Bone | 0 | 6 | — |
| Fiber | 21 | 15 | 71% |
| Grain | 13 | 13 | 100% |
| Hide | 0 | 8 | — |
| Meat | 0 | 10 | — |
| Nuts | 48 | 37 | 77% |
| Spear | 0 | 7 | — |
| Stone | 17 | 14 | 82% |
| Wood | 162 | 151 | 93% |

## Buildings (session)

- **Total placed:** 10

### By type

- **Living Hut:** 8
- **Dairy Farm:** 1
- **Farm:** 1

### By source

- **herder_hut:** 8
- **milestone:** 2

### Chronological

- t=34.8s **WE DOAZ** — Living Hut (herder_hut) builder=SAIX @ (2323,-561)
- t=41.6s **RO JAUS** — Living Hut (herder_hut) builder=DAHI @ (-2108,216)
- t=61.5s **CA CEQU** — Living Hut (herder_hut) builder=JAAB @ (-818,3291)
- t=66.0s **RA VUWO** — Living Hut (herder_hut) builder=BUED @ (-1446,-2802)
- t=86.9s **WE DOAZ** — Farm (milestone) @ (2528,-440)
- t=165.9s **RO JAUS** — Living Hut (herder_hut) builder=DAHI @ (-1963,405)
- t=319.9s **CA CEQU** — Living Hut (herder_hut) builder=JAAB @ (-1014,3177)
- t=437.1s **WE DOAZ** — Dairy Farm (milestone) @ (2552,-505)
- t=542.1s **RA VUWO** — Living Hut (herder_hut) builder=TEEN @ (-1300,-2637)
- t=595.2s **RO JAUS** — Living Hut (herder_hut) builder=DAHI @ (-2152,261)

## Per-clan detail

### CA CEQU

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (25% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.2 → 0.1

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Nuts | 14 | 10 |
| Spear | 0 | 1 |
| Wood | 62 | 62 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| JAAB | 0 | 0 | 22 | 76 | gather 38%, wander 33%, herd_wildnpc 19% |

#### Buildings

- t=61.5s **Living Hut** — herder_hut (builder: JAAB)
- t=319.9s **Living Hut** — herder_hut (builder: JAAB)

### RA VUWO

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/2 (46% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 0.6 → 0.4

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Bone | 0 | 6 |
| Fiber | 9 | 3 |
| Grain | 9 | 9 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Nuts | 18 | 13 |
| Spear | 0 | 4 |
| Stone | 6 | 3 |
| Wood | 50 | 40 |

#### Failures

- **Gather:** inventory_full=47, empty_switch:not_harvestable=3, not_harvestable=3, resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BUED | 0 | 0 | 16 | 49 | gather 36%, wander 25%, herd_wildnpc 14% |
| JOEH | 0 | 0 | 4 | 9 | gather 43%, craft 37%, idle 10% |
| TEEN | 0 | 0 | 2 | 9 | gather 30%, craft 23%, herd_wildnpc 17% |
| YEEM | 0 | 0 | 0 | 4 | craft 65%, gather 19%, idle 9% |
| ZORU | 0 | 0 | 6 | 21 | gather 68%, idle 9%, party 9% |

#### Hunts

- start t=350.0s prey=deer quota=2
- start t=405.0s prey=deer quota=3
- hunt_completed t=400.5s reason=loot_complete
- hunt_completed t=437.4s reason=loot_complete

#### Buildings

- t=66.0s **Living Hut** — herder_hut (builder: BUED)
- t=542.1s **Living Hut** — herder_hut (builder: TEEN)

### RO JAUS

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (45% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.3 → 0.3

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 7 |
| Grain | 4 | 4 |
| Nuts | 9 | 8 |
| Spear | 0 | 1 |
| Stone | 4 | 4 |
| Wood | 28 | 28 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DAHI | 0 | 0 | 12 | 54 | wander 32%, herd_wildnpc 32%, gather 22% |

#### Buildings

- t=41.6s **Living Hut** — herder_hut (builder: DAHI)
- t=165.9s **Living Hut** — herder_hut (builder: DAHI)
- t=595.2s **Living Hut** — herder_hut (builder: DAHI)

### WE DOAZ

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/1 (58% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 0.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 12 | 12 |
| Nuts | 7 | 6 |
| Spear | 0 | 1 |
| Stone | 7 | 7 |
| Wood | 22 | 21 |

#### Failures

- **Gather:** resource_invalid=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| SAIX | 0 | 0 | 18 | 48 | herd_wildnpc 59%, gather 19%, wander 16% |

#### Buildings

- t=34.8s **Living Hut** — herder_hut (builder: SAIX)
- t=86.9s **Farm** — milestone
- t=437.1s **Dairy Farm** — milestone

