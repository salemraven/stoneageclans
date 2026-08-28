# ClanBrain Report (standard)

## Session

- **Duration:** 600.4s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_10min_20260613_004126/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 10 min
- **AI clans with eval:** 0
- **Simulation ticks:** 5
- **Sim tick interval:** 120.0s (5 ticks/sim-day)

## Summary

| Clan | Pop | Fight | Kcal store | Kcal need | Cal buffer | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-----------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|

*G fail* = gather failures excluding `inventory_full` noise. **Cal buffer** = stored kcal ÷ daily need (days of food). Legacy logs without calorie fields show `—` for kcal columns.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 0 / 0
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Kcal store min→max→end | Cal buffer min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------------|------------------------|----------|

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|

### Production economy

| Clan | Alloc evals | WR issued | WR claimed | WR completed | WR expired | WR released | Passive output | Campfire cooked |
|------|-------------|-----------|------------|--------------|------------|-------------|----------------|-----------------|

*WR* = ClanBrain **work request** (delivery or pickup). **Alloc evals** = `production_allocation_eval` rows (~every 15s on established campfire or land claim).

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|

## Economy (session)

- **Items gathered:** 0
- **Items deposited:** 0
- **Gather failures (all):** 2
- **Gather failures (actionable):** 2
- **Deposit failures:** 0

### Gather failures (actionable)

- **resource_invalid:** 2

## Buildings (session)

- **Total placed:** 0
## Per-clan detail

