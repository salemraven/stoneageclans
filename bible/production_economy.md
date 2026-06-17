# Production Economy & ClanBrain Resource Management

**Status:** Implemented (Tier 1 campfire + Tier 2 land claim)  
**Last updated:** 2026-06-13  
**Related:** [ai_clan_brain.md](ai_clan_brain.md) · [earlygame.md](earlygame.md) · [tasks_guide.md](tasks_guide.md) · [Buildings.md](Buildings.md) · [clanbrain_report.md](clanbrain_report.md) · [Ultimate_npc_clanbrain_test.md](Ultimate_npc_clanbrain_test.md)

---

## Overview

ClanBrain runs a **job board** for women on **Tier 1 campfires** and **Tier 2 land claims**. It looks at stock levels, picks production chains, and posts **WorkRequests**. Women pull jobs through **`production_work`** FSM state and run multi-step **TaskRunner** jobs.

**Tier 1 (campfire):** Oven (bread), Drying Rack (leather), plus passive meat→cooked meat on the fire. Farm and Dairy stay **land-claim only**.

**Tier 2 (land claim):** Same bread/leather chains plus full milestone set (Farm, Dairy, Living Hut, etc.).

---

## Architecture

```
ClanBrain (every ~15s when camp is established, allocation_eval_interval × 5s eval tick)
  → refresh abundance ratios (stock ÷ daily need + safety buffer)
  → select chains (bread / leather rules)
  → issue PENDING WorkRequests (delivery or pickup)
  → scan passive buildings for ready output → pickup requests

ProductionWorkState (women, FSM priority ~9.6–10)
  → claim_work_request()
  → building.generate_clanbrain_delivery_job() or pickup_job()
  → TaskRunner (OccupyTask for Oven, deliver-only for Drying Rack)
  → restore_home_living_hut() when done

PassiveProductionComponent (Drying Rack)
  → hide in building inventory → timer → leather in building inventory

Campfire inventory
  → meat → cooked meat timer (no NPC)
```

---

## WorkRequest lifecycle

| State | Meaning |
|-------|---------|
| `PENDING` | On job board; any free woman can claim |
| `CLAIMED` | Woman reserved the slot (brief) |
| `IN_PROGRESS` | TaskRunner job running |
| `COMPLETED` | Job finished; row removed on next cleanup |

**Expiry:** PENDING requests older than **`work_request_expire_seconds`** (default 90s) are dropped and logged as `work_request_expired`.

**Types:**

| Type | Chain | Woman does |
|------|-------|------------|
| `delivery` | bread | Stays at Oven during craft (OccupyTask) |
| `delivery` | leather | Brings hide to Drying Rack, leaves |
| `pickup` | leather | Collects finished leather from rack → claim storage |

---

## Production chains

Defined in **`ProductionChainRegistry`** autoload (`scripts/data/production_chain_registry.gd`).

| Chain ID | Building | Passive? | Inputs | Output |
|----------|----------|----------|--------|--------|
| `bread` | Oven | No | 1 wood + 1 grain | 1 bread |
| `leather` | Drying Rack | Yes | 1 hide | 1 leather |

Data class: **`ProductionChain`** (`scripts/data/production_chain.gd`).

---

## Chain selection (abundance)

Every allocation tick ClanBrain refreshes **abundance ratios**:

```
abundance[resource] = stock / max(daily_need + safety_buffer, 1)
```

**Bread:**

- If **food_days_buffer** &lt; target → only when grain &gt; 1.5× need **and** wood &gt; 1.0× need.
- Else if grain abundance &gt; **abundance_threshold** (default 2.5) → queue bread.

**Leather:**

- Hide abundance &gt; **abundance_threshold** → queue leather delivery (if rack exists and accepts input).

**Delivery gate:** claim inventory must hold all chain inputs; building must exist and not already have a pending request for that building + type.

**Milestones:** Drying Rack auto-placed when hide count ≥ 3 (`clan_brain._evaluate_milestone_buildings`).

---

## Living Hut home binding

Women are assigned to **their own Living Hut** (pregnancy UI lives on that hut).

- **`OccupationSystem`** stores `HOME_LIVING_HUT_META` on the woman and `ASSIGNED_WOMAN_META` on the hut.
- After production work, **`restore_home_living_hut()`** puts the woman back on her hut — not “any hut in the clan.”
- **`production_work_state`**, **`occupy_task`**, and building UI read this binding when the woman is away.

---

## Tuning knobs (`BalanceConfig`)

| Key | Default | Role |
|-----|---------|------|
| `abundance_threshold` | 2.5 | Start luxury chains when stock is this many “days” above need |
| `safety_buffer_days` | 0.5 | Added to daily need in abundance denominator |
| `allocation_eval_interval` | 3 | Run allocation every N brain eval ticks (~15s) |
| `work_request_expire_seconds` | 90 | Drop stale PENDING requests |
| `daily_need_grain_per_capita` | 2.0 | Abundance math |
| `daily_need_wood_per_capita` | 2.0 | Abundance math |
| `daily_need_hide_per_capita` | 0.5 | Abundance math |
| `campfire_cooking_interval` | 30 | Seconds per meat→cooked meat at campfire |
| `drying_rack_process_time` | 120 | Passive hide→leather timer |
| `bread_craft_time` | (see config) | Oven OccupyTask duration |

---

## Code map

| Piece | Path |
|-------|------|
| ClanBrain allocation | `scripts/ai/clan_brain.gd` (`_evaluate_resource_allocation`, `work_requests`) |
| FSM state | `scripts/npc/states/production_work_state.gd` |
| Passive rack timer | `scripts/buildings/components/passive_production_component.gd` |
| Job generation | `scripts/buildings/building_base.gd` (`generate_clanbrain_*`) |
| Campfire cooking | `scripts/campfire.gd` (`_process_passive_cooking`) |
| Home hut binding | `scripts/systems/occupation_system.gd` |

---

## JSONL instrumentation (debug)

Enable with **`--playtest-capture`**. Events:

| Event | When |
|-------|------|
| `production_allocation_eval` | Allocation tick; includes `selected_chains`, `pending_requests`, `abundance_*` |
| `work_request_issued` | New job on board |
| `work_request_claimed` | Woman took job |
| `work_request_completed` | TaskRunner finished |
| `work_request_released` | Job aborted (exit state, job gen failed) |
| `work_request_expired` | PENDING timed out |
| `production_output` | Passive building finished a batch |
| `campfire_passive_cooked` | Campfire converted meat |

**`clan_brain_eval`** also includes `work_requests_pending` and `work_requests_active`.

---

## Testing

### Quick smoke

```bash
bash tools/run_instrumented_playtest.sh
```

### Production-focused (5 min NPC world)

```bash
bash tools/run_playtest_npc_only_5min_economy.sh
```

Uses **`--strict-production`** with soft floors (≥1 allocation eval). Stricter gates via env — see [Ultimate_npc_clanbrain_test.md](Ultimate_npc_clanbrain_test.md) §6.

### ClanBrain markdown report

```bash
bash tools/run_clanbrain_report_5min.sh
```

Report section **Production economy** summarizes work-request counts per clan.

### Analyzer flags

```bash
python3 scripts/logging/analyze_playtest.py \
  --strict-production \
  --min-production-allocation-eval 1 \
  --min-work-request-completed 1 \
  playtest_session.jsonl
```

---

## Edge cases & invariants

- **Nomad march:** allocation paused while `campfire.nomad_state != NONE` (camp is moving).
- **Tier 1 placement:** player/AI may place **Living Hut, Oven, Drying Rack** at campfire; Farm/Dairy require land claim.
- **Missing inputs:** no delivery request issued (silent skip).
- **Rack full / busy:** `can_accept_passive_input` blocks delivery.
- **Woman aborts work:** request released back to PENDING; home hut restored.
- **Debug builds:** `_assert_work_request_invariants()` — one active request per NPC, PENDING has no NPC.
- **Multiplayer (future):** allocation and WorkRequests must stay **server-authoritative**; clients only animate claimed jobs.

---

## Known gaps

- Farm/Dairy animal feed still use legacy occupy paths (not WorkRequests yet).
- Analyzer does not yet require bread **and** leather in one run (use report + manual JSONL grep).
- Scripted deterministic production scene (pre-stocked Oven + woman) is backlog — see Ultimate test §8.
