# Console Log Issues Report (console.md)

Audit of `guides/console.md` (~10,000 lines) — issues found and suggested fixes.

---

## 1. Log spam (high volume, impacts performance/readability)

### 1.1 `_is_mouse_over_ui` printed every frame
- **Volume:** Thousands of entries when mouse is NOT over UI
- **Source:** `scripts/main.gd` — `_is_mouse_over_ui()` prints on every call
- **Fix:** Remove or throttle debug prints; use DEBUG level only when needed
- **Impact:** Clutters console, may affect performance in dev

### 1.2 HERD_WILDNPC "intercept would exceed max distance" (~1005 occurrences)
- **Pattern:** `⚠️ HERD_WILDNPC: HUQU intercept would exceed max distance (2018.x px > 2000.0px) - leading to claim instead`
- **Source:** `scripts/npc/states/herd_wildnpc_state.gd:749` — printed every update when caveman is leading a wild woman near the 2000px limit
- **Behavior:** Caveman correctly leads to claim instead of intercept; logic is fine
- **Fix:** Throttle to once per second or remove (informational, not an error)
- **Impact:** Major console spam while leading women far from claim

### 1.3 HERD_WILDNPC "target is herded by X - invalidating" / "cannot steal"
- **Pattern:** Repeated when multiple cavemen target same woman
- **Fix:** Throttle or log only on state change
- **Impact:** Spam when several cavemen compete for same target

---

## 2. Combat: Hit validation failures (whiffs)

- **Pattern:** `❌ COMBAT: Hit validation failed` → `⚠️ COMBAT: Hit validation failed in WINDUP - transitioning to RECOVERY (whiff)`
- **Source:** `scripts/npc/components/combat_component.gd` — `_validate_hit()` returns false
- **Causes:** Target dead, out of range, or out of 90° attack arc (e.g. target moved)
- **Current behavior:** Intended — attacker enters RECOVERY (whiff), completes attack cycle
- **Question:** Are whiffs too frequent? If so, could widen `attack_arc`, add small range buffer, or re-evaluate facing (e.g. velocity vs sprite flip)

---

## 3. UI / textures

### 3.1 `_update_occupation_slot: Could not load woman texture` (~4300 occurrences)
- **Source:** `scripts/inventory/building_inventory_ui.gd:1549`
- **Path used:** `res://assets/sprites/woman.png`
- **File exists:** `assets/sprites/woman.png` and `woman.png.import` are present
- **Hypotheses:** (A) `load()` failing at runtime (timing/context) (B) Wrong path in some builds (C) Import error for woman.png (D) Called before filesystem/resources ready
- **Next step:** Add instrumentation to log `load()` result and call context; try `preload()` for compile-time check

### 3.2 `ANIMATION: Default texture is null, trying to restore from weapon component`
- **Source:** `scripts/npc/components/combat_component.gd` — combat sprite updates
- **Meaning:** Combat frame expects a base texture; NPC sprite texture is null
- **Fix:** Ensure NPCs have valid default texture before combat; weapon component fallback is a workaround
- **Impact:** Cosmetic — restore usually succeeds

---

## 4. Task system

### 4.1 `Task X/Y (pick_up_task.gd / gather_task.gd) FAILED - cancelling job`
- **Pattern:** Task fails immediately on start → job cancelled
- **Likely causes:** Target invalid, resource depleted, move blocked, or similar preconditions
- **Impact:** NPCs lose jobs and must re-find work
- **Next step:** Add logs in `pick_up_task` and `gather_task` to record failure reason

### 4.2 `generate_job returned null` (FEWE, LOER, etc.)
- **Pattern:** `Task System: FEWE found 3 same-clan building(s) but no job (generate_job returned null)`
- **Meaning:** NPCs see clan buildings but job generator returns no job
- **Possible causes:** All resources gathered, no gatherables, building not active, or job logic filters out valid work
- **Impact:** NPCs idle despite available buildings
- **Next step:** Log `generate_job` inputs/outputs to see why it returns null

---

## 5. Baby lineage

### 5.1 `BABY LINEAGE VERIFY: father='<null>', mother='<null>'`
- **Meaning:** Babies sometimes have null parent references
- **Impact:** Lineage/clan tracking incomplete for those babies
- **Fix:** Ensure parents are set when babies spawn; validate lineage before verify

---

## 6. Summary: suggested priority

| Priority | Issue                                | Action                                      | Effort |
|----------|--------------------------------------|---------------------------------------------|--------|
| High     | Woman texture load failure           | Instrument + fix path / preload              | Low    |
| High     | HERD_WILDNPC intercept spam         | Throttle or remove log                       | Low    |
| High     | `_is_mouse_over_ui` spam             | Remove or gate behind debug flag             | Low    |
| Medium   | Task FAILED (pick_up, gather)        | Add failure reason logs                      | Medium |
| Medium   | generate_job null                    | Instrument job generator                     | Medium |
| Medium   | Combat whiff frequency               | Tune only if gameplay feels wrong            | Low    |
| Low      | Baby lineage null                    | Fix parent assignment on spawn               | Low    |
| Low      | ANIMATION default texture null       | Ensure NPC default texture set               | Low    |

---

*Generated from console.md audit — Feb 11, 2026*
