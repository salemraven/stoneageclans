# Ultimate NPC & ClanBrain Test Specification

**Purpose:** Define integration + oracle tests that prove **NPC FSM**, **pull-based quotas**, **ClanBrain** (defend / search / raid / hunt), and cross-system invariants work correctly—both in single-player and future multiplayer.

**Non-goals:** Full worldgen/chunk exhaustive runs (separate doc), UI/UX polish, player-only mechanics.

**Last Updated:** 2026-05-14

---

## 1. How to Run

### 1.1 Headless smoke (quick sanity)

```bash
bash tools/run_instrumented_playtest.sh
```

Boots `Main.tscn` headless for ~4 iterations; logs to `Tests/logs/`.

### 1.1b One-command bundled gate (recommended)

Runs instrumented smoke, territory/brain integration, short ClanBrain `Main` capture, **`analyze_playtest.py --strict-clanbrain`**, then **by default** a **~120 s NPC-only `Main`** (`--npc-only-world`, player hidden at origin) with **`analyze_playtest.py --strict-clanbrain --strict-npc-sim`** so AI clans must show gather FSM touches, hunt telemetry, and baby/growth signals. Bundle root **`Tests/logs/ultimate_npc_cb_<timestamp>/`** contains **`npc_only_2min/`**.

```bash
bash tools/run_ultimate_npc_clanbrain_test.sh
```

Environment:

- **`SKIP_NPC_ONLY_2MIN=1`** — skip the NPC-only ~120 s step + **`--strict-npc-sim`** gate (saves ~2 min wall time).
- **`ULTIMATE_LONG_2MIN=1`** — also runs **`bash tools/run_playtest_2min_analyze.sh`** (~2 min `Main`): herd **`--strict`** plus **`--strict-clanbrain`** via **`ANALYZER_EXTRA_ARGS`**.
- **`ULTIMATE_ECONOMY_5MIN=1`** — append **5-min economy stress test** (`--playtest-5min --npc-only-world`): validates hunger/eat loop working (≥10 `npc_ate` events), **zero starvation deaths** (`--strict-economy --max-starvation-deaths 0 --min-eat-events 10`). Proves long-term play sustainability.
- **`ULTIMATE_MIN_CLAN_BRAIN_EVALS`** — default **`1`**; passed to **`--min-clanbrain-eval-events`** (short ClanBrain JSONL and NPC-only analyzer).
- **`ULTIMATE_MIN_QUOTA_UPDATES`** — default **`0`**; set **`1`** if the short ClanBrain slice must prove quota logs.
- **`ULTIMATE_NPC_SIM_MIN_GATHER`** / **`ULTIMATE_NPC_SIM_MIN_HUNT_WORLD`** / **`ULTIMATE_NPC_SIM_MIN_HUNT_BRAIN`** / **`ULTIMATE_NPC_SIM_MIN_GROWTH_UNIQUE`** — NPC-only analyzer thresholds (defaults **`8`** / **`1`** / **`1`** / **`1`**). **`MIN_NPC_SESSION_SEC_FOR_ANALYZE`** (default **`90`**) gates **`max(t)`**. **`PLAYTEST_WORLD_SEED`** default **`88442201`** on the bundled NPC-only runners; **`random`** omits **`--playtest-world-seed`**. JSONL **`session_start`** stores **`playtest_world_seed_cli`** when the CLI flag is present (and **`world_seed`** when **`WorldGenConfig`** is on the tree at capture start).

### 1.2 JSONL capture (full instrumentation)

```bash
# Windows (PowerShell)
.\Tests\run_live_verify.ps1

# Or manual:
godot --path . -- --playtest-capture --playtest-log-dir Tests/live_verify
```

Writes `playtest_session.jsonl` with structured events.

### 1.3 Profile modes

| Flag | Behavior |
|------|----------|
| `--playtest-2min` | 2-min timed run, auto-quit, 2s snapshots |
| `--npc-only-world` | Hub AI/wildlife sim: player pinned/hidden at origin (with `--playtest-*`, proves ClanBrain without moving an avatar) |
| `--playtest-world-seed <int>` | Fixed **`WorldGenConfig.world_seed`** for reproducible streamed content (recommended for CI); omit if you intentionally want randomized seed rolls |
| `--playtest-4min` | 4-min timed run |
| `--raid-test` | Tags session for raid validation, 2s snapshots |
| `--party-test` | Party/formation validation |
| `--agro-combat-test` | Combat stability checks |

### 1.4 Session text logs

Set `DebugConfig.enable_session_instrumentation = true` for FSM/agro/task logs in console (separate from JSONL).

---

## 2. Artifacts Produced

| Artifact | Description | Use |
|----------|-------------|-----|
| `playtest_session.jsonl` | One JSON object per line; `t` (seconds) + `evt` | Machine analysis |
| Godot console log | Print errors, `[COMBAT]`, parse failures | Crash triage |
| `session_start` row | Path, flags, duration | Know which rules apply |
| `test_run_ended*` rows | Counters, friendly-fire flags | Pass/fail gate |

---

## 3. Instrumentation Inventory

### A. Session & health
- `session_start`, periodic `snapshot` (FPS, counters)
- `npc_world_probe` — positions, states, velocities (spatial debugging)
- `test_run_ended`, `test_run_ended_2min`

### B. ClanBrain & territory
- `clan_brain_eval` — full metrics dump per evaluation cycle
- `clan_brain_food_ratio` — food economy tracking
- `clan_brain_quota_update` — defender/searcher quotas + alert level

### C. Raiders
- `raid_evaluated` — score + breakdown (food pressure, aggression, weak enemy, etc.)
- `raid_started`, `raid_joined`, `raid_aborted`
- `party_formed`, `party_disbanded`, `party_formation_tick`

### D. Hunters (NPC clans)
- `hunt_started` — JSON field **`prey`** (analyzer also accepts **`prey_type`**); quota + pressures + meat/hide counts
- `hunt_joined`, `hunt_phase_changed`
- `hunt_completed`, `hunt_aborted`, `hunt_prey_escaped`
- `hunt_butcher_*`, `hunt_deposit`

### E. Herd / search recruitment
- `herd_wildnpc_*` — can_enter, enter, exit
- `herd_influence_*` — contested, transfer
- `herd_count_change`, `npc_joined_clan`

### F. NPC FSM
- `npc_fsm_transition` — from/to states, clan, herded_count, follow_ordered
- `herd_fsm_transition` — herd/party adjacent

### G. Combat / agro
- `agro_increased`, `agro_threshold_crossed`
- `combat_started`, `combat_ended`, `combat_hit`, `combat_whiff`
- `friendly_fire_combat_started` — **must stay at 0**

### H. Tasks & economy
- `task_no_job` — why NPC couldn't get work
- `land_claim_placed`, `milestone_building_placed`
- `baby_spawned`, `baby_grew_to_clansman`

### I. Hunger & sustainability (NEW)
- `npc_hunger_threshold` — fires when NPC crosses 80%, 50%, 30% hunger (direction: above/below)
- `npc_ate` — fires when NPC successfully eats food (food type, hunger before/after)
- `npc_died` — includes `cause` field: `"combat"`, `"starvation"`, or `"unknown"`

---

## 4. Test Scenarios — Single Player

Each scenario has **Setup**, **Stimulus**, **Expected JSONL**, **Pass criteria**.

### 4.1 Defender quota under peace

**Setup:** NPC clan with 4+ clansmen, no enemies nearby, min stock met.

**Stimulus:** Let ClanBrain evaluate (5s interval).

**Expected JSONL:**
```json
{"evt": "clan_brain_quota_update", "clan": "...", "defender_quota": 1, "cavemen": 4, "alert_level": "NONE"}
```

**Pass:** `defender_quota ≈ cavemen / 4` (baseline ratio).

---

### 4.2 Alert escalation (INTRUDER → SKIRMISH → RAID)

**Setup:** NPC clan at peace, enemy approaches.

**Stimulus:** Enemy enters claim → combat starts → raid triggered.

**Expected sequence:**
1. `clan_brain_quota_update` with `alert_level: "INTRUDER"`
2. `clan_brain_quota_update` with `alert_level: "SKIRMISH"`, higher defender_quota
3. `clan_brain_quota_update` with `alert_level: "RAID"`, defender_quota = all fighters

**Pass:** Alert levels escalate; quotas increase accordingly.

---

### 4.3 Alert decay

**Setup:** Clan at RAID alert, enemies eliminated.

**Stimulus:** Wait 10s per decay step.

**Expected:** RAID → SKIRMISH → INTRUDER → NONE in `clan_brain_quota_update` rows.

**Pass:** Alert decays correctly; defender_quota drops to baseline.

---

### 4.4 Minimum stock gate

**Setup:** Clan with < 10 wood, < 10 stone, or < 10 food; no alert.

**Stimulus:** ClanBrain evaluates.

**Expected:** `defender_quota: 0` until stock reaches threshold.

**Pass:** No defenders assigned when poor (unless alert overrides).

---

### 4.5 Single-caveman exception

**Setup:** Clan with exactly 1 caveman.

**Stimulus:** ClanBrain evaluates.

**Expected:** `defender_quota: 0`, `searcher_quota: 1` (if no women).

**Pass:** Lone caveman searches, doesn't defend (free to gather/herd).

---

### 4.6 Searcher / herd recruitment

**Setup:** Clan with searcher_quota > 0, wild woman nearby.

**Stimulus:** Searcher finds and herds woman.

**Expected:**
1. `herd_wildnpc_enter` with npc type
2. `herd_influence_*` events
3. `npc_joined_clan` with type="woman"

**Pass:** Woman joins clan; no spurious combat events.

---

### 4.7 Raid lifecycle

**Setup:** NPC clan (AGGRESSIVE state), weak neighbor clan in range.

**Stimulus:** ClanBrain evaluates raid opportunity.

**Expected sequence:**
1. `raid_evaluated` with `score >= 1.0`
2. `raid_started` with attacker/target clans
3. `party_formed` with source="raid"
4. `raid_joined` events for each raider
5. Eventually `raid_aborted` or raid completion rows

**Pass:** Full raid cycle observable; party forms and disbands correctly.

---

### 4.8 Hunt lifecycle (AoH prey only)

**Setup:** NPC clan, deer in Area of Hunt, meat/hide pressure.

**Stimulus:** ClanBrain evaluates hunt opportunity.

**Expected:**
1. `hunt_started` with **`prey`**: `"deer"` or `"mammoth"` only (never sheep/goat/woman)
2. `hunt_joined` events
3. `hunt_phase_changed` (FORMING → CHASING → KILLING → LOOTING → RETURNING)
4. `hunt_butcher_*` events
5. `hunt_completed` or `hunt_aborted`

**Pass:** Only PREY-role wildlife hunted; full pipeline completes.

**Oracle assertion:** No `hunt_started` where **`prey`** / **`prey_type`** names a herd animal or woman (`sheep`/`goat`/`woman`).

---

### 4.9 Combat stability

**Setup:** Two hostile clans near each other.

**Stimulus:** Let them fight for 2+ minutes.

**Analyzer:** `python3 scripts/logging/analyze_playtest.py --strict-stability <jsonl>`

**Pass criteria:**
- No FSM churn (< N combat/flee touches per 10s window)
- No agro ping-pong (< N threshold crossings per window)
- `friendly_fire_instrumented_hits == 0`

---

### 4.10 Reproduction milestone

**Setup:** Clan with woman in Living Hut, male clansman.

**Stimulus:** Wait for reproduction cycle.

**Expected:**
1. `baby_spawned` with mother/father names
2. After growth timer: `baby_grew_to_clansman`

**Pass:** Baby spawns and promotes correctly.

---

### 4.11 Player clan (ClanBrain skip)

**Setup:** Player-owned land claim.

**Stimulus:** ClanBrain evaluates.

**Expected:** No `raid_evaluated` or `hunt_started` for player clan.

**Pass:** Player drives hunting/raiding via RTS, not brain automation.

---

### 4.12 Economy sustainability (5-min stress test)

**Setup:** NPC-only world (`--npc-only-world --playtest-5min`), seeded spawn.

**Stimulus:** Let NPCs run for 5 minutes without player intervention.

**Expected JSONL:**
1. Multiple `npc_ate` events (≥10) — NPCs finding and eating food
2. Multiple `npc_hunger_threshold` crossings — hunger system active
3. Zero `npc_died` with `cause: "starvation"` — economy sustains population

**Pass criteria:**
- `--strict-economy --max-starvation-deaths 0 --min-eat-events 10`
- Proves hunger wiring works: NPCs drain hunger, eat, recover
- No death spiral from food shortage

**Run:**
```bash
ULTIMATE_ECONOMY_5MIN=1 bash tools/run_ultimate_npc_clanbrain_test.sh
# Or standalone:
bash tools/run_playtest_npc_only_5min_economy.sh
```

---

## 5. Test Scenarios — Multiplayer Readiness

These tests ensure systems will work when server is authoritative.

### 5.1 ClanBrain runs only on server

**Test type:** Code audit + runtime check.

**Requirement:** `clan_brain.update()` must only execute when `multiplayer.is_server()` or single-player.

**Check:** Add assert or guard:
```gdscript
if multiplayer and not multiplayer.is_server():
    return  # Clients don't run brain
```

**JSONL oracle:** In MP, only server produces `clan_brain_*` events.

---

### 5.2 Quota reads are deterministic

**Test type:** Invariant check.

**Requirement:** `land_claim.get_meta("defender_quota")` returns same value for all peers (since server writes it).

**Approach:** Log quota on server and verify clients see same value after sync.

---

### 5.3 FSM state transitions server-authoritative

**Test type:** Design + code audit.

**Requirement:** Combat, defend, raid, hunt states should be driven by server-side decisions replicated to clients.

**Gap today:** FSM runs locally per peer. Need to either:
- A) Run FSM only on server, replicate state to clients
- B) Run FSM everywhere but seed with server-authoritative inputs (quotas, targets)

---

### 5.4 RNG determinism for NPC decisions

**Test type:** Code audit.

**Requirement:** Any `randf()` / `randi()` in ClanBrain or NPC states must either:
- Use seeded RNG from `world_seed`
- Run only on server

**Files to audit:**
- `scripts/ai/clan_brain.gd`
- `scripts/npc/states/*.gd`
- `scripts/npc/fsm.gd`

---

### 5.5 Network ID stability for targets

**Test type:** Design check.

**Requirement:** Raid/hunt targets stored by ClanBrain must use network IDs (not instance_id) so they're valid across server/client.

**Current gap:** `raid_intent.target` is a node reference (local).

**Fix:** Store `network_id` in intent dict; resolve on each peer.

---

### 5.6 Alert propagation to clients

**Test type:** Integration.

**Requirement:** When server calls `clan_brain.on_alert(level)`, clients must see updated `alert_level` (via land_claim meta sync or RPC).

**Test:** Trigger alert on server; verify client-side defender behavior changes.

---

### 5.7 Party formation sync

**Test type:** Integration.

**Requirement:** `party_formed` / `party_disbanded` events must replicate so clients see correct formations.

**Approach:** Server forms party → broadcasts member list → clients update visuals.

---

### 5.8 Combat target validation

**Test type:** Robustness.

**Requirement:** Server validates all combat targets before hits register. Client-side targeting is cosmetic only.

**Guard:** `CombatComponent._on_hit()` must verify target is valid server-side before applying damage.

---

### 5.9 Bandwidth audit for brain events

**Test type:** Measurement.

**Requirement:** ClanBrain evaluates every 5s; quota updates should not spam network.

**Approach:** Only send quota deltas when values change. Log byte count per second in MP test.

---

### 5.10 Late-join state sync

**Test type:** Integration.

**Requirement:** When new peer joins mid-game, they receive:
- Current `alert_level` per clan
- Active `raid_intent` / `hunt_intent`
- `defender_quota` / `searcher_quota`
- NPC states (or enough to reconstruct)

**Test:** Start server with active raid → client joins → verify client sees raid in progress.

---

## 6. Automated Analysis

### 6.1 Strict mode

```bash
python3 scripts/logging/analyze_playtest.py --strict playtest_session.jsonl
```

Fails on:
- Herd invariant violations
- Coverage thresholds not met

### 6.1b ClanBrain strict mode (`--strict-clanbrain`)

```bash
python3 scripts/logging/analyze_playtest.py --strict-clanbrain [--min-clanbrain-eval-events N] \
  [--min-clanbrain-quota-updates N] [--allowed-ai-hunt-prey deer,mammoth] playtest_session.jsonl
```

Fails on:

- **`hunt_started`** with missing prey id, **`prey`** in `{sheep, goat, woman}`, or **`prey`** outside `--allowed-ai-hunt-prey` (default **`deer`,`mammoth`** — matches `NPCConfig.WildRole.PREY`).
- Instrumented **friendly-fire** markers: `friendly_fire_combat_started`, `combat_hit` with **`friendly_fire: true`**, `test_failed_friendly_fire`.
- Optional coverage: **`--min-clanbrain-eval-events`**, **`--min-clanbrain-quota-updates`**.

Combined with **`--strict`** / **`--strict-stability`** in one invocation when you want herd + combat + AoH gates together.

### 6.1c NPC world sim strict (`--strict-npc-sim`)

Use on captures run with **`--npc-only-world`** ( **`session_start`** includes **`npc_only_world: true`**). Pass **`--require-npc-only-session`** so generic JSONLs cannot accidentally pass.

```bash
python3 scripts/logging/analyze_playtest.py \
  --strict-npc-sim --require-npc-only-session \
  [--min-npc-gather-fsm N] [--min-npc-hunt-world N] [--min-npc-hunt-brain N] [--min-npc-growth-unique N] \
  [--min-npc-session-sec SEC] \
  playtest_session.jsonl
```

Fails when thresholds miss counts of:

- **`npc_fsm_transition`** for **`caveman`/`clansman`** touching **`gather`** states,
- **World hunt proxy:** **`deer`/`mammoth`** **`npc_fsm_transition`** rows touching **`flee_prey`** (prey under pressure — not always attributable to AoH alone).
- **Brain hunt telemetry:** **`hunt_started`** / **`hunt_joined`** / **`hunt_phase_changed`**, plus fighter **`hunt`** FSM transitions. For NPC-only **~120 s** captures, **`Main`** enables **`DebugConfig.npc_only_world_hunt_stress`** (timed **`--npc-only-world`** only) so clans still evaluate hunts when cupboards are stocked, which makes `hunt_started` appear **without lying in production saves**.
- **Growth:** count of **unique** keys (**`baby_spawned`**: **`clan`+`mother`+`father`+`slot_count`**; **`baby_grew_to_clansman`**: **`npc`+`clan`**) — ignores duplicate JSONL spam.

Bundled runners: **`bash tools/run_playtest_npc_only_2min_analyze.sh`** or **`powershell -File tools/run_playtest_npc_only_2min_analyze.ps1`**.

### 6.1d Economy sustainability (`--strict-economy`)

Use on longer captures (5+ min) to validate hunger/eat loop and starvation prevention.

```bash
python3 scripts/logging/analyze_playtest.py \
  --strict-economy \
  [--max-starvation-deaths N] [--min-eat-events N] \
  playtest_session.jsonl
```

Fails when:

- **`npc_died`** events with `cause: "starvation"` exceed `--max-starvation-deaths` (default -1 = off, set 0 for no starvation allowed)
- **`npc_ate`** events below `--min-eat-events` (hunger/eat loop must be active)

Bundled runner: **`bash tools/run_playtest_npc_only_5min_economy.sh`** (zero starvation, ≥10 eat events).

### 6.2 Stability mode

```bash
python3 scripts/logging/analyze_playtest.py --strict-stability playtest_session.jsonl
```

Fails on:
- Combat FSM churn
- Agro threshold ping-pong
- Frozen combat probes

### 6.3 CI gate suggestions

| Check | Condition |
|-------|-----------|
| Brain runs | ≥1 `clan_brain_eval` in 2min run |
| No friendly fire | `friendly_fire_instrumented_hits == 0` |
| Hunts valid | No bad **`hunt_started`** prey (**`--strict-clanbrain`**); NPC strict adds separate **world vs brain** hunt floors |
| Raids form | Heuristic stress only: after `raid_started`, expect **`party_formed`** shortly (not enforced by analyzer yet) |
|| No starvation | Zero `npc_died` with `cause: "starvation"` in 5-min run (`--strict-economy --max-starvation-deaths 0`) |
|| NPCs eating | ≥10 `npc_ate` events in 5-min run (`--strict-economy --min-eat-events 10`) |

### 6.4 Combined example

```bash
python3 scripts/logging/analyze_playtest.py \
  --strict --strict-clanbrain --min-clanbrain-eval-events 1 \
  Tests/logs/ultimate_npc_cb_*/clan_brain_main/playtest_session.jsonl
```

## 7. Failure Triage Playbook

| Symptom | Likely cause |
|---------|--------------|
| No `clan_brain_*` lines | Instrumentation off, clan too small, or wrong territory mode |
| Raids score but don't start | Thresholds, cooldown, strategic state gates, not enough available fighters |
| Hunts never start | No AoH prey, food pressure gates, defender drain, prey filter regression |
| FSM churn violations | Combat/agro hysteresis broken, target flickering |
| Friendly fire hits | `CombatAllyCheck` bug or missing call site |
| Quota never changes | Min-stock gate, single-caveman branch, or alert stuck |

---

## 8. Gaps / Backlog for "Ultimate" Test

- [ ] **Scripted deterministic scene:** Pre-spawn two NPC claims + prey + herdables at known positions (not random placement)
- [ ] **MP harness:** Automated server + client spin-up with JSONL capture on both
- [ ] **Raid completion events:** Add explicit `raid_completed` row (currently implicit via party disband + state clear)
- [ ] **Hunt kill event:** Add `hunt_prey_killed` before butcher phase
- [ ] **Network ID instrumentation:** Log network_id in JSONL rows for MP debugging
- [ ] **Chunk boundary test:** NPC near chunk edge during hunt/raid—verify no state loss on unload

---

## 9. Open Questions

### Q1: Should ClanBrain run on clients at all?

**Context:** Currently ClanBrain is a RefCounted owned by land claim. In MP, running it on clients means duplicate computation and potential desync.

**Recommended answer:** **No** simulation on clients. **`scripts/land_claim.gd`** `_process` already skips **`clan_brain.update(delta)`** when **`get_multiplayer().has_multiplayer_peer()`** and **`not multiplayer.is_server()`**. Replicating raid/hunt intents to clients cleanly is separate backlog.

---

### Q2: How do we replicate `raid_intent` / `hunt_intent` to clients?

**Context:** These are dictionaries on ClanBrain. Clients need them to show correct NPC behavior (raid markers, hunt animations).

**Recommended answer:** Serialize intent to land_claim meta (already partially done). On server quota update, call `rpc("_sync_intent", intent_dict)` to all clients. Clients store in local brain copy (read-only).

---

### Q3: What happens if hunt target despawns mid-hunt?

**Context:** Prey might migrate off-chunk or get killed by another clan.

**Recommended answer:** `hunt_state` should detect invalid target in `_physics_process` and emit `hunt_aborted` with reason "target_lost". ClanBrain clears intent. Already partially implemented—verify with test.

---

### Q4: Should FSM transitions be server-authoritative RPCs?

**Context:** FSM runs locally. In MP, NPC might enter different states on server vs client due to timing.

**Recommended answer:** **Yes, eventually.** For launch:
- Server runs FSM, determines state
- Server RPCs state to clients
- Clients run puppet logic (animation, movement interpolation) but don't evaluate `can_enter()`

This is significant refactor—flag for Phase 5 of MP roadmap.

---

### Q5: How do we test combat stability with network latency?

**Context:** Agro/combat decisions depend on perception queries. Latency might cause hits to register differently.

**Recommended answer:** 
1. Server is authoritative for all damage
2. Client shows hit locally for responsiveness
3. Server confirms/rejects hit; client reconciles
4. Add `--simulate-latency 100` flag for local testing

---

### Q6: What's the minimum viable MP test for ClanBrain?

**Context:** Full MP is a big lift. What's the smallest test that proves brain works in MP context?

**Recommended answer:**
1. Headless server with 2 NPC clans
2. One browser client as observer (no player clan)
3. Verify: `clan_brain_*` events only on server log
4. Verify: client sees defender NPCs at correct positions
5. Trigger raid → verify client sees raiders move

---

### Q7: Should we add a `--mp-brain-test` flag?

**Context:** Similar to `--raid-test`, a dedicated mode that spins up server + dummy client for brain validation.

**Recommended answer:** **Yes.** Add to `playtest_instrumentor.gd`:
- `--mp-brain-test`: Start as server, spawn test clans, log brain events
- Companion script spawns headless client that connects and logs received state
- Diff server vs client logs for desync detection

---

### Q8: How do we handle defender assignment desync?

**Context:** Server assigns defenders via quota. If client's `assigned_defenders` array differs, visuals are wrong.

**Recommended answer:** 
- `assigned_defenders` lives only on server (land_claim meta)
- Client receives list via RPC on change
- Client uses list for rendering defender positions
- Client never modifies the array

---

### Q9: What's the oracle for "hunt only targets PREY"?

**Context:** We fixed this today—want to prevent regression.

**Recommended answer:** **`analyze_playtest.py --strict-clanbrain`** — validates each **`hunt_started`** **`prey`** / **`prey_type`** against **`--allowed-ai-hunt-prey`** (default **`deer`,`mammoth`**) and fails on herdables (**`sheep`**, **`goat`**, **`woman`**).

---

### Q10: Should reproduction run on clients?

**Context:** `ReproductionComponent` timer ticks down; baby spawns.

**Recommended answer:** **Server-only.** Reproduction timer runs on server. When baby spawns, server creates NPC with network_id and replicates. Client receives spawn RPC. Client never runs reproduction logic.

---

## 10. Related Docs

- **`guides/ai_clan_brain.md`** — Full brain system reference
- **`guides/multiplayer.md`** — MP roadmap
- **`guides/Phase4/raiding_hunting.md`** — Hunt/raid design
- **`tools/README.md`** — Playtest tooling
- **`scripts/logging/playtest_instrumentor.gd`** — Event definitions
- **`scripts/logging/analyze_playtest.py`** — Automated analysis
