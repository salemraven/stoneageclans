# AI Intent, Tasks, Modes, Aggro, and UI Guide  
**Stoneage Clans**

---

## Purpose

Authoritative **AI control architecture** for Stoneage Clans. Unifies:

- Tasks & Jobs (execution)
- NPC Modes (intent)
- Aggro & combat interruption
- Player control (HUD, **right-click context menu**, **left-click confirm / drag**)
- Role-specific behavior (clansmen, clanswomen, wild NPCs)

Keeps implementation **consistent**, **scalable** (50+ NPCs), **maintainable**, and free of special-case AI.

---

## Core Design Rules (Non-Negotiable)

1. **Player commands NEVER assign tasks** — UI sets intent (mode, follow, defend); AI decides behavior.
2. **Modes define intent; tasks define execution.**
3. **Aggro interrupts work** but does not replace it.
4. **Buildings never control NPCs** — they may expose jobs; they never assign, change mode, or inject tasks.
5. **Everything must be cancelable.**

---

## Canonical Terminology

| Term | Meaning |
|------|---------|
| **Task** | One atomic action (MoveTo, PickUp, Attack, Wait, …) |
| **Job** | Ordered list of tasks |
| **Mode** | High-level intent (WORKING, HOSTILE, DEFEND) — **NPC only** |
| **AOP** | Area of Perception (enemy detection radius) |
| **LCA** | Landclaim Area |
| **Ordered Follow** | Explicit player command to follow (unbreakable until canceled) |

---

## Player (Not an NPC)

The player has **no** WORKING mode. WORKING is NPC-only.

**Player states:**

- **Neutral** (default) — normal play, gather, build, etc.
- **HOSTILE** — raid leader; followers mirror.

**HOSTILE** is toggled **only** via **HUD button**. No automatic triggers (no auto-hostile in enemy LCA, no weapon-based hostility) for now.

---

## NPC Roles

### Clansmen

- **WORKING** by default.
- Have aggro meter.
- Can enter **HOSTILE** (raid, agro response).
- Can **DEFEND** (border defense).
- Can **SEARCH** when local resources exhausted.

### Clanswomen

- Always **WORKING**.
- No aggro meter; never auto-hostile; cannot RAID.
- Can **FOLLOW** (non-hostile only).
- No Defend / Hostile options in context menu.

### Wild NPCs, Predators, Prey

- **Wander** + survival/hunt jobs; different job generators (e.g. `SurvivalJobGenerator`, `HuntJobGenerator`).
- No village logic. Same FSM + task framework.
- **No** wild babies; **no** sleep/rest.

---

## NPC Modes (Intent Layer)

Modes are **NPC-only**. They **gate** the existing FSM: mode decides which states are allowed; FSM stays.

### WORKING (Default)

- “Permission to run role-specific autonomous behavior.”
- **Not** a button or stance — default AI permission set.

**Clansmen sub-behaviors (priority order):**

1. **Defending** — if assigned to DEFEND (see Role model below).
2. **Gathering / Herding** — if resources or herdable animals available.
3. **Searching** — when nothing left locally; move outward into wilderness to find resources or animals to herd. Risk scales with distance.

**Clanswomen:** supply chains, transporting resources, occupying production buildings, returning products to landclaim.

**Village NPCs:** no wandering (except optional edge cases). **Wild NPCs & babies** may wander.

### HOSTILE

- Raids, player-led attacks, agro response (temporary).
- Attacks hostiles in AOP; ignores work; may follow leader.
- **Clansmen only.**

### DEFEND

- Guard landclaim border (or position).
- Position along border; move slightly within guard band; engage hostiles in AOP; return to guard after combat.
- **Clansmen only.**

---

## Role Model (Clansmen)

**Role pools** — defaults only when unassigned; **player overrides via context menu** (no sliders).

| Role | Default | Player override |
|------|---------|------------------|
| **DEFENDING** | 20% | Assign / remove via **context menu** (right-click → menu → left-click option) |
| **SEARCHING** | 20% | Assign / remove via **context menu** (right-click → menu → left-click option) |
| **WORKING** | Rest | Automatic |

**Selection logic:**

1. If **player-assigned** role → use it.
2. Else if landclaim needs defenders → **DEFENDING**.
3. Else if landclaim needs searchers → **SEARCHING**.
4. Else → **WORKING**.

**Future:** Crafting as WORKING fallback (e.g. 20% Defend, 20% Search, 60% Working). When no gather/search/defend capacity, clansmen at landclaim craft (knap stone, carve wood, etc.) using land claim resources and deposit tools/weapons in storage.

---

## Defending & Searching (Clansmen)

### Defending

- **Border defense**: station at landclaim border; patrol within guard band; deterrence + first-contact combat.
- Assigned via **context menu** (right-click → menu → left-click Defend) or **drag clansman → land claim** (left-click hold when menu closed). System fills default % when unassigned.

### Searching

- **Escalation** when local resources depleted: move outward (local → outer → deep); higher distance = higher risk.
- Search for resources and herdable animals; report intel to landclaim (see Intel, below).
- **Future:** Searching clansmen communicate finds; other clansmen use intel to gather (ant-like behavior).

---

## Jobs & Tasks

### Jobs

- **Generated** by buildings (and other sources); **never assigned** by buildings.
- **NPC-pull model:** WORKING NPCs ask nearby/relevant buildings “Do you have work?” (e.g. `generate_job(worker)`). Buildings expose; NPCs decide.
- **Drag woman → building** (left-click hold when menu closed): biases job search (“prefer jobs from this building”); does **not** assign tasks.

### Tasks

- **Dumb, reusable, atomic.** `start(actor)`, `tick(actor, delta)`, `cancel(actor)`; return RUNNING / SUCCESS / FAILED.
- Tasks **do not** know mode, issuer, or intent. They may take **parameters** (target, resource, building) — e.g. `Follow(player)` OK; “because player ordered” ❌.

### Core Task Types

- MoveTo, Follow, PickUp, DropOff, Occupy, Wait, Attack, GuardArea, ReturnTo, Flee.

---

## Task System Plan

*How the Job/Task system runs, why we use it, and how to integrate it. This is the authoritative plan for “work as a sequence of reusable TASKS.”*

### Philosophy

> **Treat work as a sequence of reusable TASKS, not building-specific scripts.**

- **Tasks** = atomic actions (MoveTo, PickUp, DropOff, Occupy, Wait, …). Reusable across all work.
- **Jobs** = ordered lists of tasks. Data only; no logic.
- **Buildings** describe work via `generate_job(worker)`; they never assign, control, or inject.
- **Same framework** for clansmen, clanswomen, wild NPCs, etc. Different **job generators** per type (village, survival, hunt).

### How It Runs (Execution Flow)

1. **NPC in WORKING** (or a job-doing FSM state) has a **TaskRunner** component.
2. **Idle:** NPC has no current job. It **pulls** one: queries nearby/relevant buildings (or land claim, intel) via `generate_job(worker)`. Picks a job (e.g. by distance, bias from drag-to-building).
3. **TaskRunner** holds `current_job` and `current_task`. Each frame (or throttled):
   - If no `current_task`, pop next from job → `task.start(actor)`.
   - Call `task.tick(actor, delta)` → RUNNING / SUCCESS / FAILED.
   - **SUCCESS** → advance job; repeat or clear job if done.
   - **FAILED** → `task.cancel(actor)`; clear job.
4. **Interrupts:** Mode switch (e.g. → HOSTILE, DEFEND) or **agro** → `cancel_current_job()`. No task injection; just cancel. NPC exits job-doing state; FSM picks new state from mode.
5. **Completion:** Job done → clear job; NPC is idle again and can pull another.

### Architecture (Components)

| Component | Role |
|-----------|------|
| **Task** | Base type. `start(actor)`, `tick(actor, delta)` → status, `cancel(actor)`. Concrete types: MoveTo, PickUp, DropOff, Occupy, Wait, Gather, Attack, … |
| **Job** | Ordered `Array` of tasks. Metadata optional (e.g. `building`, `is_claimed`). Data only. |
| **TaskRunner** | NPC child node. Holds `current_job`, `current_task`. Runs tick loop; advances job; `cancel_current_job()` on interrupt. |
| **Building interface** | `generate_job(worker) -> Job \| null`. Buildings implement; never call `npc.set_job()` or push tasks. |

**NPC-pull:** NPCs call `generate_job(self)` on buildings they consider. They **choose** whether to take a job. Drag woman → building only **biases** that choice.

### Performance Benefits

- **Bounded work:** TaskRunner runs **one** `tick` per NPC per frame, and only when a job is active. Idle NPCs do no task work.
- **Event-driven job pull:** NPCs query for jobs when entering WORKING / job-doing state or when idle, **not** every frame. Optional: throttle (e.g. every 1–2 s) or cache job availability.
- **No extra global scans:** Job sources are spatial (nearby buildings, land claim). Use existing proximity checks / Area2D; avoid per-frame `get_nodes_in_group` in hot paths.
- **ModeController / FSM:** Mode checks and state evaluation are already throttled (e.g. 0.1 s). Task system adds a single tick per active job.
- **Less duplication:** Shared tasks replace per-state logic. Easier to optimize one code path (e.g. MoveTo, PickUp) than many.
- **Scale-friendly:** With job caching, LOD (e.g. distant NPCs tick less), and batched logic, 50+ NPCs stay viable. See *Optimization* below.

### UX Benefits

- **Consistent behavior:** All work is “do task A, then B, then C.” Player sees predictable loops (e.g. fetch → craft → deposit).
- **Everything cancelable:** Agro, mode switch, Break Follow → job cancels cleanly. No stuck “building script” forever.
- **Extensible:** New work = new job definitions + optional new generators. No new FSM state scripts for every building.
- **World-as-UI preserved:** Drag-to-building biases jobs; no micromanagement panels. Aligns with context menu + role model.

### Integration with Modes & FSM

- **Modes gate FSM.** Job execution happens **inside** job-doing states (e.g. gather, work_at_building, or a generic “work” state).
- **When entering** such a state: if no current job, pull one; assign to TaskRunner. State `update` delegates to TaskRunner (or runs alongside for non-task behavior).
- **Mode switch or agro:** Cancel current job; exit state. FSM picks mode-appropriate state. No tasks pushed by mode or agro.
- **Mapping:** WORKING allows job-doing states; HOSTILE / DEFEND do not. TaskRunner is used only in WORKING-related states.

### What Changes vs Today

- **Today:** `gather_state`, `work_at_building_state`, etc. embed move/pickup/deposit logic. New work = new state or big state changes.
- **After:** States use TaskRunner + jobs. New work = new Job + `generate_job` (and maybe new task types). States stay generic.

### Conventions & Constraints

- **Deposit range:** 50 px standard for drop-off / deposit. Use consistently in DropOff, Deposit, and similar tasks.
- **Resource locking:** When an NPC starts a PickUp from a **world resource** (node, etc.), lock it briefly (e.g. 5 s). Others skip locked resources. Prevents stampedes. Lock expires if task fails or cancels.
- **One job per NPC:** An NPC has at most one current job. No hoarding.

### Hybrid Approach (Optional During Migration)

- **Phase 1:** Use tasks for **building work** (supply chains, oven, production). Keep **gather** / **herd** as existing FSM states if that’s simpler.
- **Phase 2:** Migrate gather/herd to tasks (GatherTask, herding-related tasks) when ready. Same TaskRunner, same rules.

### Optimization (50+ NPCs)

- **Job caching:** Cache “building has work” for 1–2 s. Reduce `generate_job` calls.
- **LOD:** NPCs far from camera run task tick less often (e.g. every 2–3 frames) or skip when off-screen.
- **Batch processing:** Process task ticks in batches (e.g. 10 NPCs per frame) to smooth frame time.
- **Spatial partitioning:** Only consider buildings/land claims in same region as NPC for job pull.

### Implementation Order (Integration Plan)

The Task system is **Phase G** in the integration plan (after dropdown, follow, defend, HUD, NPC drag, roles). Suggested order:

1. **Task base** — `Task` class; `start` / `tick` / `cancel`; status enum.
2. **TaskRunner** — NPC component; run current job; `cancel_current_job`.
3. **Job** — container for task list; `advance`, `is_complete`.
4. **Concrete tasks** — MoveTo, PickUp, DropOff, Occupy, Wait (then Gather, etc. as needed).
5. **Building `generate_job`** — e.g. Oven bake-bread job; land claim as source/sink.
6. **NPC-pull wiring** — job-doing state pulls job when idle; assigns to TaskRunner.
7. **Interrupt wiring** — mode switch / agro cancel job.

See `integration_plan.md` for where Phase G sits relative to dropdown, follow, defend, etc.

---

## Aggro (Interrupt Layer)

**Clansmen only.**

- Agro fills: enemy in AOP; faster if enemy in LCA. AOP + LCA **stack**.
- At threshold → NPC **temporarily** HOSTILE; current job interrupted safely.
- **Resolution:** threat gone → if **following** → stay HOSTILE; if **not following** → return to prior role (WORKING/DEFEND), agro drains.

**Clanswomen:** no agro; never auto-hostile.

---

## UI & Input

### Context Menu (Mac / Windows Style)

**Right-click** on NPC, building, or land claim → **context menu opens** at target. **NPC freezes** while menu is open. Player **hovers** over options → **highlight**; **left-click** highlighted option → **confirm** action; close menu. **ESC** or click outside → close without action.

| Step | Input | Result |
|------|--------|--------|
| 1 | **Right-click** on target | **Open** menu; **NPC freezes** |
| 2 | **Hover** over options | **Highlight** option under cursor |
| 3 | **Left-click** highlighted option | **Confirm** action; close menu |

- **Character menu:** Opened **only** via menu **Info** (right-click → menu → hover → left-click Info). Never by click alone.
- **Buildings / land claims:** **Right-click** → menu → **left-click** **Open Inventory** (or Info, when added).

### Context Menu (Precision Control)

**Single-target** precision. Options depend on target.

#### Clan NPCs (same clan as player)

| Option | Effect |
|--------|--------|
| **Follow** | Ordered follow (unbreakable; player = leader) |
| **Defend** | DEFEND mode (border defense at landclaim) |
| **Assign DEFEND** | Put in defender pool (role override) |
| **Assign SEARCHING** | Put in searcher pool (role override) |
| **Work** | Return to normal WORKING (default role logic) |
| **Info** | **Open character menu** (stats, inventory) |

**Clanswomen:** Follow, Info only; no Defend / Hostile / Assign.

#### Buildings / Land Claims

| Option | Effect |
|--------|--------|
| **Open Inventory** | Land claim inventory + build menu; building inventory if applicable |
| **Info** (future) | Building-specific status |

### Drag & Drop (When Menu Closed)

When the **context menu is closed**, **left-click hold** on clansman (or item, etc.) → **drag** → drop on **player** (follow) or **land claim** (defend). When the menu **is** open, **left-click** is used only to **confirm** a menu option.

| Drag | Drop | Result |
|------|------|--------|
| **Clansman** | **Player** | Ordered follow |
| **Clansman** | **Land claim** | DEFEND |
| NPC(s) | Ground | Guard / hold (future) |
| NPC(s) | Enemy area | RAID target (future) |
| Items, buildings | (inventory, world) | Item/building drag (left-click hold when menu closed) |

**Player → NPC** drag disabled.

**Clansmen** can be **dragged** (left-click hold, menu closed) to **player** (follow) or **land claim** (defend). Same as choosing Follow / Defend from the menu. **Info** / character menu is **only** via menu **Info**; never from click or drag.

### HUD (Left of Hotbar)

| Control | Effect |
|---------|--------|
| **Hostile** | Player becomes raid leader (toggle) |
| **Break Follow** | Clear ordered follow from all followers |
| **Hunt** (future) | Hunting party; same machinery as raid, different target filter (wild NPCs) |

**No** Defend slider; defender assignment via **context menu** (right-click → menu → left-click Defend) or **drag clansman → land claim** (left-click hold when menu closed).

---

## Mode vs FSM (Implementation)

- **Modes layer on top of FSM.** We do **not** replace FSM with mode + tasks.
- **Mode** gates which FSM states are allowed; mode switch cancels current job and forces re-entry via mode-appropriate state.
- **Example mapping:**

| Mode | Allowed FSM states |
|------|--------------------|
| WORKING | wander, gather, herd, occupy_building, work_at_building, search, … |
| HOSTILE | agro, combat, chase |
| DEFEND | defend_idle, agro, combat |

- **TaskRunner** runs jobs (task sequences) when NPC is in job-doing states. Mode switch → cancel current job. GDScript sketches (ModeController, TaskRunner, etc.) are **conceptual**; we **adapt** them into the existing FSM, not drop-in replace.

---

## Ordered Follow

- **Trigger:** Context menu **Follow** (right-click → menu → hover → left-click Follow) or **drag clansman → player** (left-click hold when menu closed).
- **Effect:** `follow_target = player`, `follow_is_ordered = true`. Unbreakable until **Break Follow** or explicit Stop Follow or NPC death.
- **Mirroring:** Followers mirror player HOSTILE when applicable.

---

## DEFEND Orders

- **Trigger:** Context menu **Defend** (right-click → menu → hover → left-click Defend) or **drag clansman → land claim** (left-click hold when menu closed).
- **Effect:** `mode = DEFEND`, `defend_target = landclaim` (or position); follow cleared.

---

## Buildings & Land Claims

- **Expose** jobs (`generate_job(worker)`); **never** assign, change mode, or inject tasks.
- Land claims track defender/searcher quotas and assignment; they set **intent** (who is DEFEND/SEARCH), not tasks.

---

## Performance & Global Scans

- **No unbounded per-frame global scans** in gameplay logic. One-off scans (click, debug, setup, rare UI) are OK.
- Use **Area2D** for detection (AOP, LCA); avoid per-frame `get_nodes_in_group("npcs")` in hot paths. Keep a TODO of global scans; refactor those that run every frame or scale with NPC count.

---

## Locked Decisions (All Former Questions Resolved)

| # | Question | Answer |
|---|----------|--------|
| 1 | Who assigns jobs? | **NPC-pull.** Buildings expose jobs; WORKING NPCs pull when idle. **Drag** woman → building (left-click hold, menu closed) = bias, not assign. |
| 2 | Modes vs FSM? | **Modes gate FSM.** FSM stays; mode is authority. |
| 3 | Player HOSTILE? | **Explicit HUD toggle only.** No auto-hostile (for now). |
| 4 | Global scans? | **Avoid per-frame.** Occasional (click, debug, etc.) OK. |
| 5 | GDScript sketch? | **Conceptual only.** Adapt into FSM; do not replace. |
| 6 | Tasks know targets? | **Parameters OK** (e.g. Follow(player)). **Intent/issuer** ❌. |
| 7 | Character menu? | **Context menu Info only.** Right-click NPC → menu → hover → left-click **Info** → character menu. Not opened by click or drag. |

---

## Minimal NPC Data Model

```
mode (WORKING | HOSTILE | DEFEND)
current_job, current_task
follow_target, follow_is_ordered
defend_target
assigned_role (DEFEND | SEARCH | none → auto)
aggro_meter   # clansmen only
```

---

## Golden Rule

**UI changes intent. AI decides behavior.**

---

## Future (Not Yet Implemented)

- **Hunt** button (same machinery as Raid; target wild NPCs).
- **Intel sharing:** searching clansmen report resources to land claim; workers use intel (ant-like).
- **Crafting** as WORKING fallback (knapping, carving, tool/weapon storage).
- **Predator/prey** strength & pack logic (e.g. pack power vs target; dire wolves vs mammoth).
- **Guard/hold** (drag NPC → ground) and **RAID target** (drag NPC → enemy area).

---

*This document is the single source of truth for AI control, tasks, modes, aggro, and UI.*

**See also:**
- `dropdownmenu.md` — context menu (right-click dropdown) UI, hover highlight, and option semantics.
- `integration_plan.md` — **ordered integration steps** (Phases A–F: context menu → follow → defend → HUD → NPC drag → roles; **Phase G:** Task system, Steps 12–18).


This is a *very* solid report. You’re not “missing the task system” — you’re hitting a **classic job-generation trap** that shows up the moment you integrate jobs with an FSM.

I’m going to do this in the **most useful way possible**:

1. **Short diagnosis (what’s actually wrong)**
2. **The real root cause (not the symptoms)**
3. **Concrete fixes (code-level, minimal changes)**
4. **Structural correction you should apply now (to avoid future pain)**
5. **Checklist to confirm it’s fixed**

No theory, no redesigning the whole system.

---

## 1️⃣ Short diagnosis (plain English)

> **Your task system is fine.
> Your FSM → job query boundary is wrong.**

Specifically:

* `generate_job()` is being called **too early and too often**
* It is doing **destructive / exclusive checks** (occupied, resources, recipe)
* Because it returns `null`, your FSM **never raises priority**, so women never leave `reproduction`

This is *not* a bug in tasks or TaskRunner.

---

## 2️⃣ The real root cause (this is the key insight)

### ❌ You are using `generate_job()` for two different purposes

Right now, `generate_job()` is doing **both**:

1. **Availability check**

   > “Is there work here for this NPC?”
2. **Job construction**

   > “Create a concrete Job with tasks”

That is the core mistake.

---

### Why this breaks things

Your FSM calls:

* `_has_available_job()`
* `get_priority()`
* `can_enter()`

Each of these calls `generate_job()`.

But `generate_job()`:

* Checks resources
* Checks output space
* Checks occupation
* Potentially *reserves* the building conceptually

So when called as a *probe*, it correctly returns `null`.

Then:

* Priority never bumps to 9.0
* `work_at_building` never wins
* NPC stays in `reproduction`

---

## 3️⃣ The correct fix (minimal, surgical)

### ✅ Split job logic into TWO functions

This is **mandatory**, not optional.

---

### A) `has_available_job(worker)` — **cheap, non-destructive**

Used by:

* FSM priority
* FSM `can_enter()`

This function should ONLY check:

* Correct building type
* Same clan
* Has production component
* Recipe exists

**DO NOT** check:

* Input availability
* Output space
* Occupied state

Example:

```gdscript
func has_available_job(worker: NPCBase) -> bool:
    if building_type != ResourceData.ResourceType.OVEN:
        return false

    if clan_name != worker.clan_name:
        return false

    if not production_component:
        return false

    if not production_component.recipe:
        return false

    return true
```

That’s it.

---

### B) `generate_job(worker)` — **real job creation**

Used **only once**, when NPC actually enters `work_at_building`.

This function:

* Re-checks everything
* May return `null`
* Creates tasks
* Is allowed to fail

```gdscript
func generate_job(worker: NPCBase) -> Job:
    if not has_available_job(worker):
        return null

    if is_occupied():
        return null

    var land_claim := _find_land_claim()
    if not land_claim:
        return null

    if not _inputs_available(land_claim):
        return null

    if not _output_space_available():
        return null

    return _build_bake_bread_job(worker, land_claim)
```

---

## 4️⃣ FSM fix (this is why women are stuck)

### ❌ Current behavior (broken)

```
get_priority()
  → _has_available_job()
      → generate_job() ❌
          → returns null
```

### ✅ Correct behavior

```
get_priority()
  → building.has_available_job(worker)
      → true
  → priority = 9.0
```

---

### Concrete FSM change

In `work_at_building_state.gd`:

```gdscript
func _has_available_job() -> bool:
    for building in get_tree().get_nodes_in_group("buildings"):
        if building.has_available_job(npc):
            return true
    return false
```

And **ONLY** in `enter()`:

```gdscript
func enter():
    var job := _pull_job()
    if job:
        npc.task_runner.assign_job(job)
```

---

## 5️⃣ Why reproduction is “winning” (explained cleanly)

This part of your report is correct:

> reproduction = 8.0
> work_at_building = 7.0 / 9.0

But because `generate_job()` returns `null`:

* `get_priority()` never returns 9.0
* `reproduction` stays dominant
* Women never even *try* to pull a job

This is **expected behavior** given the current wiring.

---

## 6️⃣ Debugging advice (important but secondary)

You’re right to add logs — but **logging won’t fix this**.

You could log forever and never see:

```
DEBUG generate_job: missing grain
```

Because the function is being used in the wrong context.

Once you split:

* `has_available_job()`
* `generate_job()`

Your existing logs will suddenly make sense.

---

## 7️⃣ One more subtle issue you will hit next (warning)

### ❗ Occupancy must be reserved **on job assignment**, not job generation

When you fix the above, the *next* bug will be:

> Two women pull the same oven job simultaneously

Fix (later in Phase G):

```gdscript
func generate_job(worker):
    if is_reserved:
        return null
    is_reserved = true
```

And clear `is_reserved`:

* On job completion
* On job cancel

Don’t do this yet — just be aware.

---

## 8️⃣ Final checklist (do these in order)

### MUST DO (to unblock you)

* [ ] Add `has_available_job(worker)` to BuildingBase
* [ ] Stop calling `generate_job()` from priority / can_enter
* [ ] Use `has_available_job()` for priority bump
* [ ] Only call `generate_job()` inside `enter()`

### SHOULD DO (next hour)

* [ ] Log inside `has_available_job()` (cheap checks)
* [ ] Log inside `generate_job()` (expensive checks)
* [ ] Confirm women leave reproduction

---

## Bottom line

You did **not** mess up the task system.

You hit the exact boundary bug that *every* job-based AI hits the first time:

> **“Availability” and “Instantiation” must be separate.**

Fix that, and:

* Jobs will appear
* Priority will work
* TaskRunner will start immediately
* Phase G will unblock cleanly

If you want, next I can:

* Review your actual `generate_job()` code line-by-line
* Help you add reservation + cancellation safely
* Or help you wire interrupts without race conditions

You’re very close — this is the right kind of problem to be stuck on.
 
 **Short answer:**
**Yes — but only as a *parallel path*, not a full migration yet.**
Create **`GatherTask` + `GatherJob` first**, wire them in **behind a feature flag**, and let **only idle WORKING clansmen pull gather jobs**. Do **not** delete or replace `gather_state` yet.

---

Now the clean, scalable way to do this without breaking your game 👇

---

## The correct migration strategy (this matters)

You are at a **dangerous-but-good point**:
Your Job system works for **structured logistics** (women, ovens), but clansmen gathering is:

* Reactive (resources deplete)
* Spatial (nearest node)
* Interruptible (aggro, defend, follow)
* Performance-sensitive (many NPCs)

So we migrate **in layers**, not a flip-the-switch rewrite.

---

## Phase 1 — Add Gather as a Job (no removals)

### What you add

### 1️⃣ `GatherTask` (atomic)

This is a **single-resource action**, not “the whole gathering behavior”.

```gdscript
# GatherTask.gd
class_name GatherTask
extends Task

var resource_node
var tool_required

func start():
    worker.move_to(resource_node.global_position)

func tick(delta):
    if not resource_node.is_valid():
        return FAIL
    if worker.is_in_range(resource_node):
        resource_node.harvest(worker)
        return SUCCESS
    return RUNNING
```

> ❗ No searching logic here
> ❗ No job logic here
> ❗ No inventory routing here

Just: *walk → harvest*

---

### 2️⃣ `GatherJob` (small, explicit)

A GatherJob is **not infinite**.

```text
GatherJob:
  1. MoveTo(resource_node)
  2. GatherTask(resource_node)
  3. MoveTo(land_claim)
  4. DropOff(resource)
```

That’s it.

If the node is empty → job fails → NPC goes idle.

This matches your **ant behavior** perfectly.

---

### 3️⃣ Job generator (NOT in the resource node)

Do **not** put this in trees / rocks.

Put it in:

* `LandClaim`
* or `VillageEconomySystem`

Example (LandClaim):

```gdscript
func generate_gather_job(worker):
    var node = find_nearest_available_resource(worker)
    if not node:
        return null
    return GatherJob.new(node, self)
```

✔ Centralized
✔ Cacheable
✔ Ratio-aware (search / defend / work)

---

## Phase 2 — Let clansmen *optionally* pull gather jobs

### Modify `work_state` / `working_mode`

Instead of:

```gdscript
enter gather_state
```

You do:

```gdscript
if task_runner.is_idle():
    var job = land_claim.generate_gather_job(self)
    if job:
        task_runner.assign(job)
        return
```

**Important:**
If no job is returned → fall back to existing logic (idle / craft / wait).

---

## Phase 3 — Feature flag the migration

Add a flag:

```gdscript
USE_GATHER_JOBS = true
```

And gate it:

```gdscript
if USE_GATHER_JOBS:
    try_pull_gather_job()
else:
    fsm.change_state("gather_state")
```

This lets you:

* Compare behaviors
* Debug performance
* Roll back instantly

---

## Phase 4 — Remove `gather_state` (later)

Only remove `gather_state` when:

✔ Gather jobs handle:

* Empty nodes
* Returning to base
* Aggro interruption
* Tool usage (later)

✔ Searchers feed discoveries
✔ Ratios are stable
✔ Performance is profiled

---

## Why this order is correct (and safe)

### If you migrate too early:

❌ You lose working behavior
❌ FSM priority bugs explode
❌ You debug 10 systems at once

### This approach gives you:

✅ One new task
✅ One new job
✅ One integration point
✅ Zero regressions

---

## How this supports tools later (your axe example)

Later, `GatherJob.generate()` can do:

```gdscript
if land_claim.has_tool("axe"):
    job.requires_tool = AXE
    job.speed_multiplier = 1.5
```

And the job prepends:

```text
PickUpTool(axe)
```

No FSM changes needed.
No special casing in GatherTask.

This is **exactly why Jobs are good here**.

---

## Final rule for your project (write this down)

> **States decide *when* an NPC wants to act.
> Jobs decide *what* they want to finish.
> Tasks decide *how* the action is performed.**

You are on the right path.

---

### Recommendation summary

✔ Create `GatherTask`
✔ Create `GatherJob`
✔ Add job generator (LandClaim-level)
✔ Let WORKING clansmen *pull* gather jobs
❌ Do NOT delete `gather_state` yet

---

If you want next, I can:

* Design **Search → Discover → Broadcast → Gather** exactly like ants
* Help you refactor `search_state` to feed job generators
* Show how to batch gather jobs for performance (50+ NPCs)
* Or help you decide the exact moment to kill `gather_state`

Just tell me 👍
