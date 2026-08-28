# ClanBrain Report (standard)

## Session

- **Duration:** 120.4s
- **JSONL:** `Tests/logs/playtest_npc_only_2min_20260615_211807/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4
- **Simulation ticks:** 1
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| DU ZEEK | 0→5 | 3 | 280 | 11.0k | 0.0 | 0 | 0 | 6 | 6 | 0 | 54% | 80.1s | 2 | 1 | — |
| JI ROIH | 0→4 | 2 | 230 | 6.9k | 0.0 | 0 | 0 | 7 | 3 | 2 | 44% | 105.1s | 1 | 1 | — |
| NU WUQA | 0→4 | 3 | 440 | 9.0k | 0.0 | 0 | 0 | 14 | 10 | 0 | 51% | 75.1s | 2 | 1 | — |
| TE DACI | 0→3 | 1 | 200 | 6.2k | 0.0 | 0 | 0 | 0 | 1 | 0 | 88% | 116.7s | 0 | 0 | — |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| DU ZEEK | — | — | 54% | 17% | 200→280→280 | 0.0→1.0→0.0 | 80.1s |
| JI ROIH | — | — | 44% | 10% | 200→230→230 | 0.0→1.0→0.0 | 105.1s |
| NU WUQA | — | — | 51% | 20% | 200→440→440 | 0.0→1.0→0.0 | 75.1s |
| TE DACI | — | — | 88% | 12% | 200→200→200 | 0.0→1.0→0.0 | 116.7s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| DU ZEEK | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| JI ROIH | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| NU WUQA | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| TE DACI | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| DU ZEEK | 1 | 2 | 2 | 84.3s |
| JI ROIH | 1 | 2 | 1 | 100.8s |
| NU WUQA | 1 | 2 | 2 | 76.9s |
| TE DACI | 0 | 0 | 0 | — |

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|
| DU ZEEK | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| JI ROIH | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| NU WUQA | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| TE DACI | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Milestone construction

| Clan | Queued | Claimed | Completed | Released |
|------|--------|---------|-----------|----------|
| DU ZEEK | 1 | 0 | 0 | 0 |
| JI ROIH | 0 | 0 | 0 | 0 |
| NU WUQA | 0 | 0 | 0 | 0 |
| TE DACI | 2 | 0 | 0 | 0 |

Build requests = clansmen walking to site and visibly constructing milestone buildings (oven, drying rack, farm, dairy). **Completed** = building placed; **Released** = interrupted.

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| DU ZEEK | 0 | 0 | — | 0 | 0 | herd_wildnpc 60%, wander 20%, build_hut_for_woman 12% |
| JI ROIH | 0 | 0 | — | 0 | 0 | gather 40%, herd_wildnpc 34%, build_hut_for_woman 15% |
| NU WUQA | 0 | 0 | — | 0 | 0 | herd_wildnpc 37%, gather 22%, idle 17% |
| TE DACI | 0 | 0 | — | 0 | 0 | herd_wildnpc 91%, wander 9% |

## Economy (session)

- **Items gathered:** 27
- **Items deposited:** 20
- **Deposit yield:** 74%
- **Gather failures (all):** 3
- **Gather failures (actionable):** 2
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 2
- **empty_switch:not_harvestable:** 1

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 6 | 4 | 67% |
| Fiber | 3 | 2 | 67% |
| Mushroom | 1 | 1 | 100% |
| Nuts | 3 | 2 | 67% |
| Spear | 0 | 5 | — |
| Stone | 2 | 1 | 50% |
| Wood | 12 | 5 | 42% |

## Buildings (session)

- **Total placed:** 3

### By type

- **Living Hut:** 3

### By source

- **herder_hut:** 3

### Chronological

- t=44.4s **NU WUQA** — Living Hut (herder_hut) builder=FEAW @ (592,2196)
- t=51.8s **DU ZEEK** — Living Hut (herder_hut) builder=JUUZ @ (-2134,633)
- t=68.3s **JI ROIH** — Living Hut (herder_hut) builder=HOLA @ (362,-2959)

## Per-clan detail

### DU ZEEK

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/3 (54% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 200 → 280 → 280
- **Daily calorie need (end):** 11.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Fiber | 3 | 2 |
| Nuts | 1 | 1 |
| Spear | 0 | 1 |
| Wood | 2 | 2 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| CIOX | 0 | 0 | 0 | 1 | herd_wildnpc 69%, wander 25%, gather 4% |
| JUUZ | 0 | 0 | 3 | 5 | herd_wildnpc 52%, wander 20%, build_hut_for_woman 18% |
| TOVU | 0 | 0 | 0 | 0 | herd_wildnpc 100% |

#### Buildings

- t=51.8s **Living Hut** — herder_hut (builder: JUUZ)

### JI ROIH

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/2 (44% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 200 → 230 → 230
- **Daily calorie need (end):** 6.9k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Mushroom | 1 | 1 |
| Nuts | 1 | 0 |
| Spear | 0 | 1 |
| Stone | 1 | 1 |
| Wood | 4 | 0 |

#### Failures

- **Gather:** resource_invalid=2, empty_switch:not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| HOLA | 0 | 0 | 2 | 3 | herd_wildnpc 39%, gather 32%, build_hut_for_woman 17% |
| JIBA | 0 | 0 | 0 | 4 | gather 94%, wander 4%, herd_wildnpc 2% |

#### Buildings

- t=68.3s **Living Hut** — herder_hut (builder: HOLA)

### NU WUQA

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/3 (51% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 200 → 440 → 440
- **Daily calorie need (end):** 9.0k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 6 | 4 |
| Nuts | 1 | 1 |
| Spear | 0 | 2 |
| Stone | 1 | 0 |
| Wood | 6 | 3 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DEEQ | 0 | 0 | 0 | 4 | idle 58%, gather 25%, wander 17% |
| FAOR | 0 | 0 | 1 | 0 | gather 95%, eat 5% |
| FEAW | 0 | 0 | 5 | 10 | herd_wildnpc 55%, gather 18%, build_hut_for_woman 17% |

#### Buildings

- t=44.4s **Living Hut** — herder_hut (builder: FEAW)

### TE DACI

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/1 (88% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 200 → 200 → 200
- **Daily calorie need (end):** 6.2k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| PATI | 0 | 0 | 1 | 0 | herd_wildnpc 91%, wander 9% |

