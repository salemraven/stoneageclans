# ClanBrain Report (standard)

## Session

- **Duration:** 120.5s
- **JSONL:** `Tests/logs/clanbrain_calorie_smoke_20260612_083958/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 2 min
- **AI clans with eval:** 4
- **Simulation ticks:** 1
- **Sim tick interval:** 120.0s (5 ticks/sim-day)
- **Calorie eval coverage:** 4/4 clans (100%)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| BA XIID | 0→1 | 1 | 200 | 2.2k | 0.1 | 1 | 0 | 0 | 1 | 0 | 0% | 119.6s | 0 | 0 | 0.8s |
| GA TACO | 0→1 | 1 | 200 | 2.2k | 0.1 | 1 | 0 | 0 | 1 | 0 | 0% | 119.0s | 0 | 0 | 1.5s |
| KO GAIZ | 0→1 | 1 | 200 | 2.2k | 0.1 | 1 | 0 | 0 | 1 | 0 | 0% | 119.9s | 0 | 0 | 0.5s |
| XU PECU | 0→7 | 3 | 200 | 12.3k | 0.0 | 2 | 0 | 2 | 2 | 0 | 60% | 70.1s | 2 | 2 | 3.0s |

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 1 / 1
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|
| BA XIID | — | — | 0% | 100% | 200→200→200 | 0.1→1.0→0.1 | 119.6s |
| GA TACO | — | — | 0% | 100% | 200→200→200 | 0.1→1.0→0.1 | 119.0s |
| KO GAIZ | — | — | 0% | 100% | 200→200→200 | 0.1→1.0→0.1 | 119.9s |
| XU PECU | — | — | 60% | 33% | 200→200→200 | 0.0→1.0→0.0 | 70.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| BA XIID | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| GA TACO | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| KO GAIZ | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| XU PECU | 2 | 0 | 1 | 1 | 0 | 0 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| BA XIID | 0 | 0 | 0 | — |
| GA TACO | 0 | 0 | 0 | — |
| KO GAIZ | 0 | 0 | 0 | — |
| XU PECU | 2 | 4 | 2 | 68.8s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| BA XIID | 0 | 0 | — | 0 | 0 | hunt 100% |
| GA TACO | 0 | 0 | — | 0 | 0 | hunt 100% |
| KO GAIZ | 0 | 0 | — | 0 | 0 | hunt 100% |
| XU PECU | 0 | 0 | — | 0 | 0 | build_hut_for_woman 25%, herd_wildnpc 19%, hunt 16% |

## Economy (session)

- **Items gathered:** 2
- **Items deposited:** 5
- **Deposit yield:** 250%
- **Gather failures (all):** 0
- **Gather failures (actionable):** 0
- **Deposit failures:** 0

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Spear | 0 | 5 | — |
| Wood | 2 | 0 | 0% |

## Buildings (session)

- **Total placed:** 2

### By type

- **Living Hut:** 2

### By source

- **herder_hut:** 2

### Chronological

- t=36.3s **XU PECU** — Living Hut (herder_hut) builder=MIUD @ (1732,-797)
- t=98.5s **XU PECU** — Living Hut (herder_hut) builder=MIUD @ (1621,-1008)

## Per-clan detail

### BA XIID

- **Brain:** PEACEFUL | alert NONE | hunt RECRUITING | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/1 (0% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.1 → 1.0 → 0.1
- **Calories in storage:** 200 → 200 → 200
- **Daily calorie need (end):** 2.2k
- **Calorie days buffer:** 0.1 → 1.0 → 0.1
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| JODA | 0 | 0 | 1 | 0 | hunt 100% |

#### Hunts

- start t=0.8s prey=deer quota=1

### GA TACO

- **Brain:** PEACEFUL | alert NONE | hunt RECRUITING | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/1 (0% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.1 → 1.0 → 0.1
- **Calories in storage:** 200 → 200 → 200
- **Daily calorie need (end):** 2.2k
- **Calorie days buffer:** 0.1 → 1.0 → 0.1
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| FIKU | 0 | 0 | 1 | 0 | hunt 100% |

#### Hunts

- start t=1.5s prey=deer quota=1

### KO GAIZ

- **Brain:** PEACEFUL | alert NONE | hunt RECRUITING | raid NONE | survival True
- **Quotas (end):** defenders 0/0 (— fill) | searchers 0/1 (0% fill)
- **Pressure:** defend 0.2 | search 0.5 | gather 0.6
- **Food days buffer:** 0.1 → 1.0 → 0.1
- **Calories in storage:** 200 → 200 → 200
- **Daily calorie need (end):** 2.2k
- **Calorie days buffer:** 0.1 → 1.0 → 0.1
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 1 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| JANI | 0 | 0 | 1 | 0 | hunt 100% |

#### Hunts

- start t=0.5s prey=deer quota=1

### XU PECU

- **Brain:** PEACEFUL | alert NONE | hunt LOOTING | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/0 (60% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0
- **Calories in storage:** 200 → 200 → 200
- **Daily calorie need (end):** 12.3k
- **Calorie days buffer:** 0.0 → 1.0 → 0.0
- **Productivity (end):** food_rate=0.0/s | herd_rate=0.0/s

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Spear | 0 | 2 |
| Wood | 2 | 0 |

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| KUIR | 0 | 0 | 1 | 0 | hunt 56%, wander 35%, gather 6% |
| MIUD | 0 | 0 | 1 | 2 | build_hut_for_woman 46%, herd_wildnpc 35%, hunt 8% |
| NOJE | 0 | 0 | 0 | 0 | party 46%, wander 18%, combat 17% |

#### Hunts

- start t=3.0s prey=deer quota=1
- start t=78.1s prey=deer quota=2
- hunt_aborted t=73.1s reason=recruitment_timeout

#### Buildings

- t=36.3s **Living Hut** — herder_hut (builder: MIUD)
- t=98.5s **Living Hut** — herder_hut (builder: MIUD)

