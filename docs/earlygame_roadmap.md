# Early game roadmap — Stone Age Clans

_Last updated: 2026-04-26 (§5: I3 stats/traits + character sheet UI; §5.1 detail; §4 C2 unchanged)_

## Purpose

**Early game** (this document) = the foundation phase: every core system must be **implemented end-to-end**, **debugged**, **edge-cased**, and **agreed** between design and implementation before we treat mid/late content as safe to build on.

**Current focus (project phase):** Core **mechanics and logic largely exist**; the priority is **not** inventing new features—it is making existing systems **reliable, debuggable, and “bulletproof”** (fewer heisenbugs, clear failure modes, regression protection). New content waits on that.

**Test–fix loop priority (this phase):** **NPC behavior and simulation** — FSM, `ClanBrain`, tasks/jobs, herd/gather/combat as **driven by AI**, territory evaluation, and structured JSONL/headless evidence. **Player input, UI, and drag/RTS feel** are **out of scope for the core loop** unless they block observing or reproducing NPC bugs (smoke still boots Main; we are **not** optimizing for manual play skill or input latency). Track player-facing issues separately or under **I2** / **I3** (inventory vs stats sheet) when needed.

This file **does not** duplicate `bible.md`. It tracks **delivery state**: what exists, what’s half-built, what’s broken, and what “done” means.

**How to use**

- Add rows as you discover gaps; tighten “done criteria” when something ships.
- **`Agreed`** = both you and implementation partner align on behavior (one line in the row or linked doc section).
- **`Status`**: `not started` | `in progress` | `blocked` | `needs debug` | `done` (use consistently).

**Related**

- Canonical design: **`bible.md`**
- Mechanics deltas / checklist: **`AGREED_MECHANICS_TODO.md`**
- Player-facing early loop (feel, milestones): **`stoneageclans/guides/earlygame.md`**
- Movement + formation plumbing (locomotion, herd vs party debuff, links to RTS): **`stoneageclans/guides/movement.md`**
- RTS commands / stances / formations: **`stoneageclans/guides/rts.md`**
- Stats / hominid traits (design reference): **`stoneageclans/guides/traits.md`** (`Stats` in `scripts/npc/stats.gd`; NPC `traits` on `NPCBase`)
- Character menu (NPC inspect / traits table today): **`stoneageclans/scripts/ui/character_menu_ui.gd`**
- Game repo: **`stoneageclans`** (Godot project root)
- Test–fix bug log (gates, IDs, fixed/open): **`earlygame_test_fix_plan.md`**

---

## Why early game is heavier than later phases

Later phases assume **stable contracts**: inventory authority, spatial queries, FSM transitions, gather costs, combat scheduling, saves, etc. If those are fuzzy, everything built on top multiplies bugs. This roadmap keeps **early** work explicit until those contracts are **bulletproof** (within agreed scope).

---

## 1. World / space / performance

| ID | Area | Current condition (snapshot) | Work to flesh out / finish | Edge cases / risks | Status | Agreed |
|----|------|-------------------------------|----------------------------|--------------------|--------|--------|
| W1 | Chunk grid & docs | `ChunkUtils` autoload: `scripts/world/chunk_utils.gd`. **Verified snapshot (paste into docs when editing):** `TILE_SIZE` 64, `CHUNK_TILES` 32, `CHUNK_SIZE` 2048, `ROAM_RADIUS` 1638.4 (= chunk × 0.8), `HOME_UPDATE_TIME` 30, `CLAN_AVOID_RADIUS` 600, `WOMAN_CLAN_AVOID_RADIUS` 800. | Keep code + `AGREED_MECHANICS_TODO` + `bible.md` in sync; verify `ResourceIndex` / interest assumptions match | Off-by-chunk desync, wrong culling, “global scan” perf traps | `in progress` | [ ] |
| W2 | Spatial queries | Many `get_nodes_in_group` call sites (`npc_base.gd`, `clan_brain.gd`, `fsm.gd`, land claim) | Identify **hot paths** per tick; replace with chunk/spatial queries where engineering plan requires; measure before/after | Large NPC counts, stutter, wrong neighbors | `not started` | [ ] |

---

## 2. NPC / AI / tasks

| ID | Area | Current condition (snapshot) | Work to flesh out / finish | Edge cases / risks | Status | Agreed |
|----|------|-------------------------------|----------------------------|--------------------|--------|--------|
| N1 | Steering + FSM | FSM + `SteeringAgent` + `ClanBrain` architecture per bible | Finish **NATURAL_MOVEMENT_IMPROVEMENTS** / feel items when core stability is green; avoid new states until base paths solid | Stuck states, transition spam, wander vs task conflict | `in progress` | [ ] |
| N2 | Agro recover | `agro_state.gd` logs recover attempts; logs can spam when targets invalid / herd state changes | Define **when recover is legal**; exit cleanly if animal no longer recoverable; reduce noisy `print` / gate behind debug | Stale `lost_wildnpc`, repeated enter/exit, task cancel loops | `needs debug` | [ ] |
| N3 | Prisoner / capture | Not specified in bible as full flow (`AGREED_MECHANICS_TODO` §3) | **Design intent paragraph** + authority model; then FSM/UI checklist | N/A until scoped | `not started` | [ ] |
| N4 | Hunt pipeline (clan) | `hunt_state.gd`: phases FORMING → CHASING → KILLING → LOOTING → RETURNING; ClanBrain pull (`npc_join_hunt` / `npc_leave_hunt`); mirrors `raid_state` pattern | Wire targets/animal types consistently; replace noisy `print` with leveled logger; headless / playtest coverage when herd + prey list stabilize | Empty hunt target, phase stuck, friendly fire vs wildlife rules | `in progress` | [ ] |

---

## 3. Economy / gather / jobs

| ID | Area | Current condition (snapshot) | Work to flesh out / finish | Edge cases / risks | Status | Agreed |
|----|------|-------------------------------|----------------------------|--------------------|--------|--------|
| E1 | Clan spread cost | `ResourceIndex.query_near()` + soft cost + `clan_spread_penalty` per bible / `AGREED_MECHANICS_TODO` §4 | Tune penalty + definition of “nearby clan mates”; multi-clan contest same band | Starvation of clans, odd job picking, exploits | `in progress` | [ ] |
| E2 | Balance sync | `NPCConfig` / `BalanceConfig` drive many timers | Keep gather/deposit leases and cooldowns **consistent** with job generation when E1 changes | Desync between UI expectation and sim | `in progress` | [ ] |
| E3 | Territory job generation | **BUG-20260415-02 fixed in repo:** `find_nearest_available_resource()` called `claim.get_tree()` without ensuring the claim was in the scene tree → engine error `Parameter "data.tree" is null` when callers passed orphan nodes (e.g. tests). Guard: `if not claim.is_inside_tree(): return null` and reuse single `tree` reference. **`tools/territory_job_service_verify.gd`** loads service at runtime (not `preload`) so autoloads exist during compile. | Ensure every territory tier that should grant jobs routes through this (or documented exception); tests for “campfire vs flag” parity | Campfire omitted from job path, wrong clan match | `in progress` | [ ] |

---

## 4. Combat / scheduling

| ID | Area | Current condition (snapshot) | Work to flesh out / finish | Edge cases / risks | Status | Agreed |
|----|------|-------------------------------|----------------------------|--------------------|--------|--------|
| C1 | Combat pipeline | `CombatComponent` + `CombatScheduler` / `CombatTick` per project rules | Confirm **all** attack paths respect locks, windup, friendly-fire rules; trim **dev `print` flood** → logger + levels | Double hits, cancel races, unreadable logs hiding real errors | `needs debug` | [ ] |
| C2 | **Early-game weapons (spear + ranged pipeline)** | Today: melee + `ResourceType` tools (axe, pick, wood club) via `WeaponComponent` / player hotbar. **Implementation target:** `SPEAR`, thrust + throw, then bow/sling + craftable arrows — **full agreed behavior in §4.1** (two-hand slots, inventory spear **count** throw gate, NPC preference). **Also:** bow/sling data-driven; pooled projectiles; **server-authoritative** hits. Refs: `stoneageclans/guides/earlygame.md`, `ResourceData`, `combat_component.gd`, `player_inventory_ui.gd` (hands). | Double-remove spear, throw when count ≤ 1, two-slot desync, client-only hit detection | `not started` | [ ] |

### §4.1 — C2 agreed rules (spear, hands, throw, NPCs)

These are **design locks** for implementation (player + eventual MP authority).

**Spear is two-handed**

- Occupies **both** quick-access hand slots: **slot 1 + slot 2** (`RIGHT_HAND_SLOT_INDEX` = 0, `LEFT_HAND_SLOT_INDEX` = 1 in `stoneageclans/scripts/inventory/player_inventory_ui.gd`).
- While a spear is equipped, **no separate off-hand item** (club, torch, etc.). Implement as a **linked pair** (one logical weapon clears/locks both indices) or equivalent so drag-drop cannot leave an illegal state.

**Thrust vs throw**

- **Thrust:** same melee pipeline as other weapons, **longer `attack_range`** than basic club (stab).
- **Throw:** **projectile** (pooled body / shared projectile service, **fixed sim tick**). On a **committed** throw: **remove 1 spear** from **authoritative inventory**, update hotbar (both hand slots if linked), and **`set_equipment(NONE)`** if nothing remains in hand — player must equip another weapon.

**Inventory spear count — never accidentally throw the last spear**

- Maintain **`count_spears`** = total **`SPEAR`** in **authoritative inventory** for that actor (player or NPC), counting stacks **once** with a single helper used everywhere.
- **Allow throw iff `count_spears > 1`.** If **`count_spears == 1`**, **do not throw** (thrust only). Applies to **player and NPCs** so nobody loses their only spear by mis-input or AI.
- **Enforcement layers:** (1) **Simulation / server:** before spawning projectile or consuming ammo, reject throw if `count_spears <= 1`. (2) **Player input:** throw action **no-ops** when disallowed (same check). (3) **UI (optional):** hide or disable throw hint when `count_spears <= 1`. (4) **NPC AI:** use the same **`can_throw_spear()`** (or equivalent) — no duplicate logic.

**NPC / clansmen**

- If a **spear is available** in inventory, **prefer spear over basic club** (`ResourceType.WOOD` club stand-in) for combat loadout / visibility (`WeaponComponent`-style equip).
- **Throw** only when **`count_spears > 1`** passes the shared gate above (same as player).

**Bow / sling / arrows (same roadmap row, later slice)**

- Craftable **arrow** stacks, ammo consumption on validated fire; **object pooling** for many in-flight shots; **server-authoritative** hit resolution; clients **FX only**.

---

## 5. Inventory / authority / UI

| ID | Area | Current condition (snapshot) | Work to flesh out / finish | Edge cases / risks | Status | Agreed |
|----|------|-------------------------------|----------------------------|--------------------|--------|--------|
| I1 | Server validation | `inventory_action_bridge.gd`: `TODO` validate op (clan, distance, slot rules) before emit on server | **Implement validation** for MP; single-player path stays deterministic | Dupes, cross-clan theft, distance cheats | `not started` | [ ] |
| I2 | Player inventory UI | `main.gd` warns if `add_to_inventory` when UI missing | Ensure drag/inventory init order can’t drop items on floor silently in real flows | Startup race, missing `PlayerInventoryUI` | `needs debug` | [ ] |
| I3 | **Stats, traits & character sheet UI** | **NPCs:** `Stats` (`scripts/npc/stats.gd`), `NPCBase.traits` (`Array[String]`), bravery, hominid/species hooks; **`character_menu_ui.gd`** lists stats via `_get_traits_list()` (aligned with **`guides/traits.md`**). **Player:** stats/traits not yet first-class the same way — combat/inventory paths partially assume implicit player. | **Parity:** decide single **character profile contract** (numeric stats + trait ids + buff/debuff display rules) for **player + NPC**. **Gameplay:** wire agreed stats into combat/craft/carry when numbers matter (avoid decorative-only bars). **UI — figure out:** dedicated **Character / Stats screen** vs tab inside inventory; **inspect self** (hotkey) vs **inspect selected follower / RTS unit** (click portrait or context); mobile-safe layout; what is **read-only** vs editable later. **MP:** server-owned stats; UI reads replicated or polled subset; no client-trusted edits. **Deliverable:** short **UI mock decision** (wireframe or bullet flow) + minimal **player** stats surface (even placeholder) reusing `character_menu_ui` patterns where possible. | Two stat systems (player vs NPC), trait drift vs `traits.md`, RTS selection vs modal stack, replication bandwidth | `not started` | [ ] |

### §5.1 — I3 notes (stats / traits / character UI)

**Already in repo (reuse)**

- Numeric **`Stats`** node and **`stat_changed`** on **`NPCBase`**; trait strings on **`NPCBase`**; canonical write-up **`stoneageclans/guides/traits.md`**.
- **`character_menu_ui.gd`** maps display rows → stat properties (and bravery); extend cautiously so new stats stay one list.

**Early-game scope**

- **Unify** “who has stats”: player should use the **same schema** as NPCs (component on `Player`, shared resource, or thin adapter) so combat/economy/UI don’t fork.
- **Traits:** persistent ids (not only display strings); optional link to hominid/species modifiers per **`traits.md`**.
- **Character screen:** decide **entry points** (e.g. **C** for self, click unit + **Inspect**, merge with **I2** inventory panel); **tabs**: Stats | Traits | Equipment | (later) Relations.
- **Done cue:** player can open **self** stats; selecting **one clan NPC** shows same sheet pattern; empty/disabled state when no selection.

---

## 6. World objects / claims / buildings

| ID | Area | Current condition (snapshot) | Work to flesh out / finish | Edge cases / risks | Status | Agreed |
|----|------|-------------------------------|----------------------------|--------------------|--------|--------|
| B1 | Land claim health UI | **BUG-20260415-01 fixed in repo:** mixed `PRESET_*` + explicit `.size` on health bar children caused “non-equal opposite anchors” warnings. Replaced with explicit symmetric anchors/offsets + `offset_right` for fill width. | Resize/regression: re-run smoke and confirm no anchor warnings in log | Wrong bar size, layout on resize | `in progress` | [ ] |
| B2 | Land claim radius **visual** vs gameplay | **Gameplay:** `LandClaim.radius` matches **EnemiesInClaim** zone and point geometry for `_radius_circle` / drawer. **Visual:** `land_claim_circles_drawer.gd` draws **one** `draw_polyline` ring (same `radius`); stroke uses **`YSortUtils.WORLD_OVERLAY_*`** (white, matched width/alpha to herd lines). AOH / click hitbox use **different** radii by design. | If ring still “looks” off vs `Line2D` herd lines, consider unifying to one draw path (polyline vs Line2D caveat) | Double ring if `_radius_circle` toggled visible + drawer; AOH confused with claim border | `in progress` | [ ] |

---

## 7. Observability / tests (early phase hardening)

| ID | Area | Current condition (snapshot) | Work to flesh out / finish | Edge cases / risks | Status | Agreed |
|----|------|-------------------------------|----------------------------|--------------------|--------|--------|
| T1 | Headless smoke | **`tools/run_exhaustive_earlygame_verify.sh`** (stoneageclans): base smoke + ChunkUtils + territory JSONL + ClanBrain JSONL + `territory_job_service_verify.gd` + long Main capture + **`scripts/logging/analyze_playtest.py --strict`**. **`analyze_playtest.py`** now supports `--strict` (exit 1 on herd invariant violations). **Primary signals:** `clan_brain_eval`, `herd_*`, `raid_*` / `hunt_*` where present, periodic **`snapshot`** NPC/claim fields — not player action telemetry. | Add **NPC-focused** headless scripts (FSM/ClanBrain invariants) as mechanics stabilize; herd strict needs JSONL with herd events (`--playtest-2min`/`4min`, long Main, or NPC-only harness scene) | Flaky tests, false greens | `in progress` | [ ] |
| T2 | Log hygiene | `CONSOLE_LOG.md` can be dominated by combat prints | Policy: debug gated; errors visible | Missing real failures | `in progress` | [ ] |

---

## 8. QA & bug discovery (industry practices — **required**)

| ID | Practice | Work to implement | Status | Agreed |
|----|----------|-------------------|--------|--------|
| Q1 | Automated regression | Unit tests on pure logic; integration / headless scenes (`-s res://tools/...`); expand beyond smoke as mechanics lock | `not started` | [ ] |
| Q2 | Determinism checks | Same seed + fixed inputs → same state hash / snapshot (fixed sim tick); catch order-of-ops bugs | `not started` | [ ] |
| Q3 | Property / fuzz tests | Random **valid** inputs to inventory, jobs, combat targets; assert invariants (no dup items, HP bounds, etc.) | `not started` | [ ] |
| Q4 | Replay or golden files | Record inputs + tick; replay in CI; diff checksums on agreed state slices | `not started` | [ ] |
| Q5 | Dev assertions | `assert` / invariant `push_error` on impossible states (clan, entity id, authority path) in dev builds | `in progress` | [ ] |
| Q6 | Telemetry (dev builds) | Lightweight counters / breadcrumbs for rare paths (combat apply, job assign) — not full analytics yet | `not started` | [ ] |
| Q7 | Manual playtests | Scripted + free play; **repro template** (steps, save, build/commit id) for every external bug | `in progress` | [ ] |

---

## 9. Performance engineering (industry practices — **required**)

| ID | Practice | Work to implement | Status | Agreed |
|----|----------|-------------------|--------|--------|
| P1 | Frame budgets | Target ms per bucket (physics, AI, render); track regressions on reference scenes | `not started` | [ ] |
| P2 | Profiling discipline | Regular CPU/GPU passes (engine profiler + external where needed) on **worst** scenes, not only happy path | `not started` | [ ] |
| P3 | Stress scenes | Max NPCs, max buildings, worst gather — long runs to find stutter and leaks | `not started` | [ ] |
| P4 | Allocation / pooling | Kill hot-path `new`/alloc in GDScript loops; pool where proven | `not started` | [ ] |
| P5 | Spatial work tied to perf | Deliver **W2** with measurable before/after (ties to chunk/grid) | `not started` | [ ] |
| P6 | Soak / load tests | Multi-hour or long unattended runs; memory growth, GC spikes | `not started` | [ ] |

---

## 10. System hardening (industry practices — **required**)

| ID | Practice | Work to implement | Status | Agreed |
|----|----------|-------------------|--------|--------|
| H1 | Explicit contracts | Document + enforce “only server mutates X”; single entry points for sensitive state | `in progress` | [ ] |
| H2 | Input validation | Every command RPC/inventory op: range, ownership, cooldown, distance — **I1** is part of this. **Early test–fix loop** emphasizes **server/sim validation of NPC and job paths** first; full player RPC hardening can trail without blocking NPC milestone gates. | `not started` | [ ] |
| H3 | Fail-safe defaults | On error: reject op, log, **no partial world corruption** | `in progress` | [ ] |
| H4 | Chaos / fault injection | Test builds: random latency, dropped RPCs, mid-action disconnect | `not started` | [ ] |
| H5 | Observability | Structured logs; **correlation id** per user action where useful; error rates visible | `in progress` | [ ] |
| H6 | Feature flags | Toggle risky subsystems without full redeploy (even if crude at first) | `not started` | [ ] |
| H7 | “Done” checklists | This roadmap + **Agreed** column — no shipping a row as done without criteria met | `in progress` | [ ] |

---

## 11. Multiplayer readiness (industry practices — **required**)

| ID | Practice | Work to implement | Status | Agreed |
|----|----------|-------------------|--------|--------|
| M1 | Authoritative simulation | Server owns gameplay state; clients send **intents** only — align with project engineering rules | `in progress` | [ ] |
| M2 | Interest management | Updates only to who needs them; align with **W1** chunk / culling story | `not started` | [ ] |
| M3 | Serialization versioning | Network + save formats versioned; migration path documented | `not started` | [ ] |
| M4 | Reconciliation / prediction | If any client prediction: server corrections bounded and tested | `not started` | [ ] |
| M5 | Network stress tests | Artificial delay/loss/jitter; min/max RTT soak; document tool (`tc`, clumsy, or engine sim) | `not started` | [ ] |
| M6 | Desync detection | Periodic hash or state subset compare; alert when clients diverge | `not started` | [ ] |
| M7 | Security baseline | Rate limits; no trust in client position/inventory for authoritative rules; validate every RPC | `not started` | [ ] |

---

## 12. Stabilization procedures (industry-style — **no new mechanics**, reliability only)

Use this when the game is a **working but buggy mess**: focus is **process + verification**, not scope creep.

| ID | Procedure | What to do | Status | Agreed |
|----|-----------|------------|--------|--------|
| S1 | **Bug triage discipline** | Every bug gets: **severity** (crash/data loss / soft-lock / wrong behavior / cosmetic), **one system owner**, **repro steps**, **build/commit id**. No infinite “it sometimes breaks” without a path to repro. | `in progress` | [ ] |
| S2 | **Regression lock** | After fixing a bug, add **at least one** automated or scripted check that would have failed before (headless script, unit test, or checklist step in `Tests/`). | `in progress` | [ ] |
| S3 | **Exploratory charters** | Time-boxed (e.g. 30–45 min) with **one mission**. **Priority order (current phase):** (1) herd/agro + wild NPC, (2) gather/jobs + territory, (3) combat/raid/hunt, (4) inventory/UI/drag **only if** needed to unblock NPC observation. Note **first failure** and stop—file bug, don’t hero-fix mid-session. | `in progress` | [ ] |
| S4 | **Pairwise / matrix spots** | Pick **pairs** of conditions (e.g. combat + tab open, gather + claim decay, MP + inventory)—not full Cartesian product—to catch interaction bugs cheaply. | `not started` | [ ] |
| S5 | **Soak & stability runs** | Long unattended or low-attention runs (30–120+ min) with **assertions on**; watch memory, FPS floor, log error rate. Goal: **no silent corruption**. | `not started` | [ ] |
| S6 | **Bisection when regressions appear** | If something **used to work**: `git bisect` (or binary search between builds) to find the breaking change—don’t pile fixes on unknown base. | `in progress` | [ ] |
| S7 | **Error-path audit** | Code pass: every **`return` early**, **`else`**, **`push_error`**, RPC failure—**document intended behavior**; remove dead branches or make them impossible via types. | `not started` | [ ] |
| S8 | **Save / load torture** | Save at weird moments (mid-combat, mid-drag, mid-gather); load; assert invariants (inventory counts, claim ownership, NPC state). | `not started` | [ ] |
| S9 | **Log contract** | Agree: **ERROR** = must investigate; **WARNING** = track; spammy **print** → gated behind debug. Keeps `CONSOLE_LOG` usable. | `in progress` | [ ] |
| S10 | **Definition of “stable” per system** | One short checklist per pillar (e.g. Combat: no double-hit, cancel rules consistent; Inventory: no dupes). **Early NPC phase:** concrete **NPC gate** bullets in **§14** (automated suite + JSONL/analyzer rules). **Stable** = checklist green under S3/S4/S5. | `not started` | [ ] |
| S11 | **Weekly stability slice** | Each week: **one** system gets “done” per S10 + S2; avoid fixing everything shallowly. | `in progress` | [ ] |
| S12 | **Static / lint pass** | Turn on strictest practical GDScript/engine warnings; fix or **explicitly waive** with comment—reduces dumb bugs. | `not started` | [ ] |

**Related:** §8–§11 remain the **toolbox** (automation, perf, MP, etc.); §12 is **how you run the project** while the build is unstable.

---

## “Done” bar for early game (draft — edit when ready)

Early game is **ready to graduate** when:

**Core systems (sections 1–7)**

- [ ] **W1** numbers documented and match runtime.
- [ ] **I1** validation done or explicitly deferred with MP off.
- [ ] **I3** stats/traits **contract** for player + NPC agreed; **character/stats UI** flow chosen (self + inspect unit); minimal player-facing sheet landed or explicitly deferred with doc mock.
- [ ] **E1** tuned with agreed playtest notes + multi-clan case handled or documented.
- [ ] **E3** territory job paths consistent for campfire + flag (or exceptions documented).
- [ ] **N2** recover behavior + logging agreed and stable under stress.
- [ ] **N4** hunt flow stable under playtest (targets, phases, leave/join).
- [ ] **C1** combat invariants tested; logs usable.
- [ ] **C2** early weapon slice shipped or explicitly deferred: **spear** thrust + throw + **two-hand** hotbar (slots 0–1 linked); **throw only if authoritative `count_spears > 1`** (player + NPC); **NPC/clansmen prefer spear over club** when available; shared **`can_throw_spear()`**; bow/sling/arrows as follow-on in same projectile/inventory contract.
- [ ] **B1** no recurring engine warnings for land claim bars.
- [ ] **T1** minimal automated checks pass in CI/local script (**NPC-centric**: JSONL/headless gates; not player-input suites).

**QA & bugs (§8)** — minimum: **Q1** + **Q2** or **Q4** in place; **Q5** on critical paths; **Q7** repro discipline (prefer **NPC/sim repro** scripts over “I clicked X” when possible).

**Performance (§9)** — minimum: **P1** + **P2** on a stress scene; **P3** + **P6** once content allows.

**Hardening (§10)** — minimum: **H1**–**H3** + **H5** for ops you care about; **H4** before MP beta.

**Multiplayer (§11)** — minimum: **M1** + **M3** + **M7**; **M2** + **M5** + **M6** before external MP playtests.

**Stabilization process (§12)** — while the build is messy: **S1** + **S9** always; **S2** on every important fix; **S10** + **S11** to avoid thrash; **S5** / **S8** before calling a milestone “stable.”

(Adjust thresholds — this is a starting contract.)

---

## 13. Bug registry (evidence-backed; tie to §S1 / §S2)

Use this for **automation-found** or **repro-filed** bugs: symptom, **where the evidence lives**, root cause, fix location, how re-verified.

| Bug ID | Row | Symptom | Evidence | Root cause | Fix | Re-verified |
|--------|-----|---------|----------|------------|-----|-------------|
| BUG-20260415-01 | B1 | Godot **Control** warnings: non-equal opposite anchors; backtrace `_setup_health_bar` | Headless Main log (`land_claim.gd` ~765–774 before fix) | `PRESET_CENTER_TOP` / `PRESET_FULL_RECT` / `PRESET_LEFT_WIDE` combined with explicit `size` on same nodes | [`land_claim.gd`](file:///Users/macbook/Desktop/stoneageclans/scripts/land_claim.gd) `_setup_health_bar` / `_update_health_bar`: explicit anchors + offsets; fill width via `offset_right` | Smoke: `grep` shows no `non-equal opposite anchors` |
| BUG-20260415-02 | E3 | Engine **ERROR**: `Parameter "data.tree" is null` at `get_tree` from `territory_job_service.gd` | `tools/territory_job_service_verify.gd` calling `generate_gather_job` with in-tree-free nodes; Godot log | `find_nearest_available_resource` assumed claim always in scene tree | [`territory_job_service.gd`](file:///Users/macbook/Desktop/stoneageclans/scripts/systems/territory_job_service.gd) early `is_inside_tree()` return; verify script uses `load()` not `preload` | `godot --headless --script res://tools/territory_job_service_verify.gd` — no `SCRIPT ERROR`, prints `TERRITORY_JOB_SERVICE_VERIFY_OK` |

**Observation (not a bug closure):** Long Main JSONL may contain **no periodic `snapshot`** events if the run ends before the instrumentor’s first snapshot tick or if `PlaytestInstrumentor` is not processing long enough—increase `LONG_MAIN_SEC` or use `--playtest-2min` flows for herd snapshot density (roadmap **T1**).

---

## 14. Test–fix loop (NPC behavior first)

**Goal:** Close bugs in **NPC logic** (states, priorities, ClanBrain, jobs, herd, combat scheduling) with **measurable** before/after (JSONL invariants, headless scripts, log scans).

**In scope**

- Headless/long captures that exercise **AI-driven** activity: `--playtest-capture`, `--playtest-2min` / `--playtest-4min`, `--raid-test`, `--clan-brain-debug`, optional `--rts-playtest-spawn` / agro tests when `DebugConfig` allows — evaluated for **NPC event density**, not player dexterity.
- `analyze_playtest.py --strict` and future analyzers on **`herd_*`, `clan_brain_*`, combat/raid events**, snapshot NPC summaries.
- Regression locks (**§S2**) tied to **NPC/regression rows** (N*, E*, C1, B1 engine warnings, etc.).

**Explicitly lower priority for this loop**

- Player inventory UI drag order, hotkeys, RTS box-select feel (**I2** unless blocking NPC observation).
- Polishing player gathering “feel” vs **NPC gather/job correctness** (optimize the latter first).

**Handoff:** When NPC gates are stable, widen to **I1/H2** player intent validation for MP — see **§11**.

### NPC milestone “done” (gate checklist — all must be true for this phase)

Use this as the **contract** before widening scope to player RPC/UI (**I1/I2**).

- [ ] **`bash tools/run_exhaustive_earlygame_verify.sh`** exits **0** on a clean tree (same `GODOT` as documented in [`tools/README.md`](file:///Users/macbook/Desktop/stoneageclans/tools/README.md)).
- [ ] **Headless hard-error scan** in the bundled logs: no `SCRIPT ERROR`, `Parse Error`, `Compile Error`, or `Failed to load script` (as defined in the exhaustive script).
- [ ] **ClanBrain signal:** at least one capture documents **`clan_brain_eval`** in JSONL (e.g. `run_clan_brain_test.sh` or long Main with `--playtest-capture`).
- [ ] **Herd strict check:** `python3 scripts/logging/analyze_playtest.py --strict <jsonl>` exits **0** when the capture is **herd-relevant** (see **“`--strict` vs empty herd data”** below).
- [ ] **Regression locks (§S2)** exist for fixes landed during the phase (scripts or documented steps under `Tests/`).

### `analyze_playtest.py --strict` vs empty herd data

- **`--strict` exit 0** means: **no herd invariant violations** detected (flicker / `herd_count_change` inconsistency).
- **Exit 0 with almost no `herd_*` / `herd_count_change` events** is **not** proof of herd quality — it means **insufficient NPC/herd activity in that capture**. Do not treat as herd “stable.”
- **Remediation:** increase **`LONG_MAIN_SEC`**, use **`--playtest-2min`** / **`--playtest-4min`** on Main, or add a **dedicated NPC/herd harness** scene when ready (**T1**).

### Coverage gates (machine-checkable “herd-relevant” proof)

Use **`analyze_playtest.py`** optional thresholds with **`--strict`** so a passing run is not silently vacuous:

| Flag | Meaning |
|------|--------|
| **`--min-herd-wildnpc-enters N`** | Fail if fewer than **`N`** `herd_wildnpc_enter` lines in JSONL (`N=0` disables). |
| **`--min-session-sec SEC`** | Fail if **`max(t)`** over all events is **&lt; SEC** (approximate simulated session length; `0` disables). |

**Bundled defaults (game repo):**

- **`bash tools/run_exhaustive_earlygame_verify.sh`** — long Main uses **`--playtest-2min`** (or **`EXHAUSTIVE_PLAYTEST_4MIN=1`** for **`--playtest-4min`**) + capture — **wall-clock** ~120s / ~240s. Do **not** use engine **`--quit-after`** for “long run” duration: in **Godot 4.x** it is **main-loop iterations**, not seconds. **`MIN_HERD_WILDNPC_ENTERS`** default **1**; **`MIN_SESSION_SEC_FOR_ANALYZE`** default **90** (set either to **`0`** to disable).
- **`bash tools/run_playtest_2min_analyze.sh`** — defaults **`MIN_HERD_WILDNPC_ENTERS=3`**, **`MIN_SESSION_SEC_FOR_ANALYZE=90`** for a ~120s playtest.

**Fast CI** may omit coverage by using **`SKIP_LONG_MAIN=1`** on exhaustive or by running only `run_earlygame_verify.sh`; **full NPC gate** should keep coverage enabled so **`--strict` exit 0** implies both **no violations** and **enough herd signal** (per thresholds above).

### DebugConfig prerequisites (game repo)

- **`--agro-combat-test`** and **`--party-test`** are ignored unless **`DebugConfig.allow_agro_combat_test_from_cli`** is **true** (inspector on autoload or project resource). Set before expecting JSONL from those modes.
- **`--raid-test`** does **not** require that flag (see [`debug_config.gd`](file:///Users/macbook/Desktop/stoneageclans/scripts/config/debug_config.gd) / CLI parsing).

### Artifact contract (every serious run or CI job)

Store together under `Tests/logs/<run_id>/` (or CI artifacts):

| Artifact | Why |
|----------|-----|
| `playtest_session.jsonl` | Structured NPC/herd/ClanBrain events |
| Full **Godot stdout/stderr** (tee’d `.log`) | Engine errors, load failures, warnings not in JSONL |
| **`git rev-parse HEAD`** (commit hash in filename, header, or sidecar `commit.txt`) | §S1 repro and bisect (**§S6**) |

### CI vs local (recommended policy)

| Tier | When | Command / env |
|------|------|----------------|
| **Fast** | Every push / quick feedback | `run_earlygame_verify.sh` with **`SKIP_CLAN_BRAIN_TEST=1`** and/or **`SKIP_LONG_MAIN=1`** on exhaustive — **document which** your pipeline uses |
| **Full NPC gate** | `main` merge, nightly, or before milestone | **`run_exhaustive_earlygame_verify.sh`** with default **`LONG_MAIN_SEC`** (or agreed value); **`SKIP_*` unset** |

Adjust names when you add CI YAML; the **policy** is: don’t block every commit on a 5+ minute run unless the team wants that.

### Optional: cadence & ownership

- **Cadence:** e.g. **full exhaustive weekly** (or nightly); **fast** tier on every change to `scripts/npc/`, `scripts/ai/clan_brain.gd`, `scripts/systems/territory_job_service.gd`, or FSM states.
- **Owner:** one **default assignee** for triaging failing gate (rotate weekly if a team).

### Optional: flaky failures

- **CI:** allow **one automatic retry** on the same commit for infra noise (Godot launch flake).
- **Same failure twice:** treat as real; use **`git bisect`** (**§S6**) if it used to pass — don’t silently bump timeouts without a hypothesis.

### Game repo entrypoint

- Commands, env vars, and smoke/exhaustive behavior: **[`stoneageclans/tools/README.md`](file:///Users/macbook/Desktop/stoneageclans/tools/README.md)**.

---

## 15. RTS / formations / Break / world overlays (delivered — Apr 2026)

**Scope:** Player-led squads, formation geometry, dismissing follow (**Break**), and **consistent** world line styling (herd vs party vs claim). Implementation lives in **`stoneageclans`** unless noted.

### Formations

| Item | Behavior | Key files |
|------|----------|-----------|
| **ATTACK** | Line **ahead** of leader along **facing**, lateral spread **perpendicular** (not world ±X only). | `FormationUtils.compute_formation_slots`, `rts_formation_config.gd` (`attack_formation_*`) |
| **FOLLOW** | **Rear arc** behind leader (facing-relative); removed player party **east/west flank-only** layout. | Same + `follow_formation_*` |
| **GUARD** | Ring (unchanged). | `FormationUtils` |

### Player speed

- **`formation_speed_mult`** still slows the player for **GUARD/ATTACK** when ordered followers use those stances.
- **Herd leader ×0.97** applies only when **`HerdManager.get_herd_animal_count(player) > 0`** (animals). **Clansmen-only** ordered warbands **do not** get that debuff.

### Break → walk home

- On **Break**, followers get **`returning_from_break`** + **`returning_from_break_expire`** (default **`RTS_CONFIG.break_return_max_sec`** ~300 s), **`invalidate_land_claim_cache()`**, FSM → **wander**.
- **Caveman + clansman** (not clansman-only): steer to **`get_my_land_claim()`** until ~**120 px** or timeout; high **wander** priority so gather/herd don’t steal the return leg immediately.

### World line consistency (`YSortUtils`)

Shared constants: **`WORLD_OVERLAY_LINE_WIDTH_PX`**, **`WORLD_OVERLAY_LINE_HERD_COLOR`** (white), **`WORLD_OVERLAY_LINE_PARTY_COLOR`** (red, **same alpha** as herd). Used by **player** leader line pool, **NPC** `follow_line` + leader lines, **land claim** `Line2D` ring, **`land_claim_circles_drawer`** (single polyline), **campfire** ring (width + alpha; orange tint retained).

### Session / repro

- **`run_session_instrument.sh`**: **`--session-quickstart`** — player claim, 2 Living Huts, 2 women, shortened preg/baby timers for reproduction/SESSION logging (see script header).

### Documentation touched

- **`stoneageclans/guides/movement.md`** — player modifiers, formation summary, Break return pointer.
- **`stoneageclans/guides/rts.md`** §6 **Break** (meta shape + caveman/clansman return).
- **`stoneageclans/guides/game_dictionary.md`** — **Break** row.

**Follow-up (optional):** §**W2** / formation collection still relevant for **NPC-led** parties scanning `npcs` group; §**B2** if visual polyline vs `Line2D` mismatch bothers playtests.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-04-12 | Initial roadmap: areas W/N/E/C/I/B/T, snapshot from repo + `AGREED_MECHANICS_TODO`, done-bar draft. |
| 2026-04-12 | Added §8–§11: industry-standard QA, performance, hardening, multiplayer practices as required trackable rows; extended done-bar. |
| 2026-04-12 | Purpose: stabilization focus (mechanics exist, reliability first). Added §12 stabilization procedures (S1–S12); done-bar ties to §12. |
| 2026-04-14 | W1: embedded verified `ChunkUtils` constants. Related: `guides/earlygame.md`. New rows N4 (hunt), E3 (territory jobs); done-bar includes E3, N4. |
| 2026-04-15 | §13 Bug registry; T1 exhaustive harness (`run_exhaustive_earlygame_verify.sh`, `analyze_playtest.py --strict`); BUG-20260415-01 (B1 health bar layout), BUG-20260415-02 (E3 `get_tree` on orphan claim). |
| 2026-04-16 | **`earlygame_test_fix_plan.md`** (bug log BUG-20260416-01–05, open items, verify commands). **NPC-centric test–fix loop** + **§14**: NPC gate checklist, `--strict`/empty-herd, artifacts, CI, coverage gates (`--min-herd-wildnpc-enters` / `--min-session-sec`), exhaustive **`--playtest-2min`** (Godot 4 **`--quit-after`** = iterations, not seconds); link `stoneageclans/tools/README.md`; **S10** → §14. |
| 2026-04-22 | **§15** — RTS/formations (ATTACK ahead, FOLLOW rear arc), player herd debuff vs animals-only, **Break** return-home (caveman+clansman, claim cache, timeout metas), **`YSortUtils` world line** standard (herd white / party red / claim white, single claim ring polyline). **B2** row (claim visual vs gameplay). Related links: **`movement.md`**, **`rts.md`**. Session repro: **`run_session_instrument.sh`** quickstart. |
| 2026-04-26 | **§4** — **C2** row + **§4.1** detail: two-handed spear (hotbar indices 0–1), thrust vs throw, remove spear + clear equip on committed throw, **`count_spears > 1`** throw gate (sim/server + input + optional UI + NPC same helper), **NPC prefer spear over club**, bow/sling/arrows note. Done-bar **C2** updated. |
| 2026-04-26 | **§5** — **I3** (stats, traits, character sheet UI): parity player/NPC, UI discovery (self vs RTS inspect, tabs), MP read-only stats; **§5.1** notes + Related links (`traits.md`, `character_menu_ui.gd`). Done-bar **I3**. |

---

## Notes / freeform (paste findings)

_Use this section to drop console patterns, repro steps, or “we decided X on date Y” without editing tables yet._

- _Template:_ `YYYY-MM-DD` — system — observation — link to commit or scene.
- `2026-04-22` — RTS / overlays — §15 summarizes chat delivery; verify in-game polyline vs Line2D if “consistent” still fails perceptually.
