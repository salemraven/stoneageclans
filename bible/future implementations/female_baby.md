# Female babies — design & implementation plan (future)

**Status:** **Planned — not implemented.** Collect ideas here before coding.  
**Last updated:** 2026-08-30  
**Decision:** Female babies **will** be added in a future phase. Current shipped behavior stays **all babies → male clansmen**.

**See also:** [earlygame_vision.md](../earlygame_vision.md) · [reproduction_guide.md](../reproduction_guide.md) · [genetics.md](../genetics.md) · [settlement_sim.md](../settlement_sim.md) · [Phase4/women4.md](../Phase4/women4.md) · [bible.md §VII–VIII](../bible.md)

---

## Why we want this

Stone Age Clans is moving toward a **simulation-first** settlement model: clans should grow through **generations**, not only by herding strangers from the wilderness.

Today:

| Source | Role |
|--------|------|
| **Wild women** (herd in) | First mothers, genetics from outside |
| **Babies** | Always become **clansmen** (fighters / gatherers) |

Future:

| Source | Role |
|--------|------|
| **Wild women** | Still valuable — outside bloodlines, expansion, hybrid genetics |
| **Female babies** | Grow into **clanswomen** — reproduction, production buildings, settlement growth from within |
| **Male babies** | Still grow into **clansmen** — army, gather, herd |

That makes families feel real and lets **off-screen settlement sim** (Phase 7+) produce population growth without the player standing at the claim.

---

## Current behavior (baseline — do not break until this ships)

- Birth: `main._spawn_baby()` → `npc_type = "baby"`, no sex field.
- Growth: `BabyGrowthComponent._grow_to_clansman()` → always `clansman`, father’s card sprite, spear, combat, gather/herd FSM.
- Off-screen: `SettlementRoster.promote_baby_to_clansman()` only.
- Women: only from **wild spawn + herd**; documented in [women4.md](../Phase4/women4.md).
- **No** gender/sex property on NPCs or roster members today.
- **No** hard mate filters (parent/child/sibling) — any eligible male in claim can be father.

---

## Design goals

1. **Deterministic** — sex decided at **birth** (server / seeded), stored on baby + roster, same result after dormant/wake and multiplayer sync.
2. **Two adult paths** — female → `woman` (clanswoman); male → `clansman` (unchanged role).
3. **Simulation-safe** — off-screen roster and wake-up must promote to the correct adult type with correct components.
4. **Genetics-forward** — inbreeding is **not** banned by UI fiat; it is a **biological cost/benefit** via traits and continuous stats (see [Inbreeding](#inbreeding-genetics-not-a-hard-ban)).
5. **Housing-aware** — new clanswomen need a **Living Hut** (or explicit household rule) before reproduction works, same as today’s women.
6. **Wild herding still matters** — internal daughters reduce reliance on map spawns but do not remove them.

---

## Sex assignment at birth

**When:** At spawn (on-screen birth or off-screen `settlement_birth`), **not** at growth timer finish.

**Why:**

- Growth may complete while claim is **dormant** — roster must already know adult type.
- Multiplayer needs one authoritative roll per baby id.
- Wake sync can apply the correct promotion path immediately.

**Suggested config** (`ReproductionConfig` / `BalanceConfig`):

| Key | Default | Meaning |
|-----|---------|---------|
| `female_birth_chance` | `0.5` | Probability baby is female (tune per species/trait later) |
| `sex_roll_seed_salt` | stable string | Mixed with `world_seed + clan + mother_id + birth_index` for deterministic RNG |

**Roster / NPC fields (planned):**

```gdscript
"sex": "female" | "male"   # or is_female: bool — pick one convention in implementation PR
"adult_type": "woman" | "clansman"  # derived at promotion, cached for sim
```

**Lineage (needed for inbreeding + genetics):**

- Store `mother_id`, `father_id` on roster (names alone are not enough off-screen).
- Already partially present as `mother_name` / `father_name` on babies; extend with network ids.

---

## Adult promotion — two paths

### Male → clansman (existing)

Keep current `BabyGrowthComponent` behavior:

- `npc_type = "clansman"`, age 13
- Father’s placeholder card (or configured inheritance rule)
- Hotbar, spear, Health / Combat / Weapon
- FSM: gather, deposit, herd_wildnpc, defend, etc.

### Female → clanswoman (new)

On promotion:

- `npc_type = "woman"`, age 13
- **Female** sprite / card (not father’s clansman card)
- Add `ReproductionComponent` (see [npc_base.gd](../../scripts/npc/npc_base.gd) woman init)
- **No** default spear/combat kit (matches existing clanswomen)
- FSM: reproduction, occupy_building, production_work, wander, eat
- **Not** herdable wild behavior — she already has `clan_name`; never went through wild pipeline

**Shared helper (implementation note):** Refactor growth into something like `BabyGrowthUtils.promote_to_adult(npc, sex, roster_data)` used by:

- `BabyGrowthComponent` (on-screen timer)
- `npc_base.apply_sleep_data()` / wake sync (roster already adult)
- Off-screen `SettlementRoster.promote_baby_to_adult()`

---

## Living Hut & household rules

**Today:** Pregnancy requires woman assigned to a Living Hut (`OccupationSystem.get_home_living_hut`).

**Problem:** A daughter who grows up has no hut unless the player assigns one — breaks off-screen sim and feels broken on return.

**Options (pick one primary rule in implementation PR):**

| Option | Pros | Cons |
|--------|------|------|
| **A. Auto-assign empty hut** | Simple; sim works off-screen | Needs free hut + build pressure |
| **B. Stay in mother’s hut until moved** | Lore-friendly “children in home” | 1 hut = 1 reproducing woman — need rule for when daughter can take slot |
| **C. ClanBrain assigns on growth event** | AI-driven | More code in brain + occupation |
| **D. Manual only (RTS)** | Player control | Off-screen reproduction for new women **disabled** until assigned |

**Recommendation:** **A + B hybrid** — try mother’s hut as “home” for display; reproduction only if she is the **assigned** occupant OR gets auto-assigned to any empty Living Hut on growth (config flag).

**Off-screen:** `_tick_new_conceptions` must skip women with no hut (already does via fertile list + hut checks) **or** gain roster-aware hut assignment in the settlement tick.

---

## Inbreeding: genetics, not a hard ban

**Design stance (project owner):** Incest occurred in nature and in small Paleolithic bands. It is not removed from the game as “impossible.” Like **dog breeding**, close matings can ** concentrate traits**; harm appears when inbreeding is ** excessive** over generations — not from a single pairing.

**Do not implement:** a flat “cannot mate with relative” blocker as the only system.

**Do implement (future, tied to [genetics.md](../genetics.md)):**

| Mechanism | Purpose |
|-----------|---------|
| **`inbreeding_coefficient` (continuous)** | Per-child or per-person metric from pedigree (parent–child, full/half sibling matings increase it) |
| **Trait: e.g. `Inbred` / `Linebred`** | Stacked at high coefficient — malformation, lower fertility, illness susceptibility (Floresiensis “Compact” + fertility tradeoff is precedent) |
| **Trait: e.g. `Linebred Strength`** | Optional benefit at **low** coefficient — concentrated hunter/builder stats (the “breeder strengthened line” fantasy) |
| **Fertility locus** | Continuous gene — high inbreeding depression reduces conception weight off-screen and on-screen |
| **Visibility** | Character menu / genetics ledger — player sees risk, not a moral popup |

**Mate selection:**

- **Default:** All eligible males in claim remain valid (including father/brother) unless player systems later add social rules.
- **ClanBrain / AI:** May *prefer* unrelated males when available (reduces accidental extinction from debuffs) — optional, not required for v1 female babies.
- **Off-screen `_pick_father_id`:** Same eligibility; apply conception **weight** modifiers from genetics when that system exists.

**Pedigree requirement:** `mother_id`, `father_id`, and ideally `generation` or ancestry bitset on roster for coefficient without scanning whole tree every tick.

---

## Impact on other systems

### Reproduction (on-screen)

- `_spawn_baby()` — roll sex; store on NPC + meta; pass ids to lineage.
- `BabyGrowthComponent` — branch on sex at promotion.
- `ReproductionComponent` — no change to “who can get pregnant” (still `woman` only).

### Settlement sim (off-screen)

- `settlement_roster.gd` — sex on `add_baby_member`; `promote_baby_to_adult()` replaces `promote_baby_to_clansman`.
- `settlement_sim_tick.gd` — `_tick_baby_growth` promotes to woman or clansman; **tick order:** pregnancies → **baby growth** → conceptions (see Phase 7 fix — grown sons must exist before conception pass).
- Wake: `spawn_npcs_from_roster` + `apply_sleep_data` must promote visual type if roster says adult but node is still baby.

### ClanBrain

- `breeding_females` increases when daughters become women → less herd-search pressure over time.
- Tune: wild woman spawn rates, searcher quotas, so map herding stays relevant early game.

### Baby cap (`BabyPoolManager`)

- Capacity counts **babies**, not adults — unchanged.
- More women → more `baby_cap_bonus` from fertility meta → **positive feedback**; monitor in balance.

### Wild women & herding

- Clanswomen born in clan **never** use wild herd/steal pipeline while they keep `clan_name`.
- Claim destroyed → existing `become_wild()` path still applies.

### UI

- Living Hut panel (“children of …”) — daughters listed; gender label.
- Character menu — sex, inbreeding coefficient (when genetics ships).
- Instrumentation: rename `baby_grew_to_clansman` → `baby_grew_to_adult` with `sex` / `npc_type`.

### Multiplayer

- Server authoritative birth + sex roll.
- Roster snapshot includes sex; clients apply on wake.

### Docs to update when implemented

- [bible.md §VII–VIII](../bible.md) — “babies → clansman only” / “women from wilderness only”
- [reproduction_guide.md](../reproduction_guide.md)
- [settlement_sim_phases.md](settlement_sim_phases.md) if Phase 7+ extended
- [women4.md](../Phase4/women4.md) — clanswomen from birth vs herd

---

## Files likely touched (checklist)

| Area | Files |
|------|--------|
| Config | `scripts/config/reproduction_config.gd`, `balance_config.gd` |
| Birth | `scripts/main.gd` (`_spawn_baby`) |
| On-screen growth | `scripts/npc/components/baby_growth_component.gd` |
| NPC setup | `scripts/npc/npc_base.gd` (`apply_sleep_data`, component init) |
| Off-screen | `scripts/systems/settlement_roster.gd`, `settlement_sim_tick.gd` |
| Wake | `scripts/main.gd` (`spawn_npcs_from_roster`), `scripts/ai/clan_brain.gd` |
| Occupation | `scripts/systems/occupation_system.gd`, building assign on growth |
| Genetics (later) | `BirthEngine`, pedigree / inbreeding coefficient per [genetics.md](../genetics.md) |
| Logging | `scripts/logging/playtest_instrumentor.gd`, summarize scripts |
| Tests | `tools/test_settlement_pregnancy.gd`, `tools/test_session_quickstart_huts.gd`, new `tools/test_baby_sex_growth.gd` |
| Assets | Female sprite/card path for promoted daughters (PlaceholderCardService / AssetRegistry) |

---

## Suggested implementation phases

**Prerequisite (separate from female babies):** Phase 7 wake sync + tick order + player-as-off-screen-father — so dormant clans already grow and reproduce correctly for **male** babies.

### Phase F1 — Sex at birth + branched on-screen growth

- Roll and store sex at spawn.
- Promote to `woman` or `clansman` on timer.
- Female path: sprite, ReproductionComponent, no spear.
- Headless tests: deterministic sex roll; both promotion paths.

### Phase F2 — Roster + off-screen + wake

- Roster sex + ids; `promote_baby_to_adult`.
- Wake sync promotes live baby to match roster adult type.
- Extend settlement pregnancy tests for “daughter in roster” (not reproducing without hut).

### Phase F3 — Living Hut assignment for new women

- Auto-assign or mother-hut rule so off-screen conception can include grown daughters when huts allow.

### Phase F4 — Genetics & inbreeding (can parallel later)

- Pedigree ids, inbreeding coefficient, trait expression, conception/fertility weights.
- No hard mate ban unless we add optional “clan law” feature later.

### Phase F5 — Balance & AI pass

- Wild woman spawn vs internal growth; ClanBrain herd pressure; baby cap feedback loops.

---

## Open questions (resolve before F1 PR)

1. **Exact sex ratio** — flat 50/50 or species/trait modifiers (e.g. Floresiensis fertility flavor)?
2. **Mother’s hut** — can two reproducing women share one hut ever, or strict 1:1 forever?
3. **Minimum age** — reproduce at 13 immediately on growth, or add `fertile_age`?
4. **Name generation** — same pool for all babies, or woman-name generator at promotion for females?
5. **Player notification** — toast when daughter vs son grows up?
6. **Save migration** — existing saves: all current babies default to `male` / `clansman` path?

---

## Testing plan (when implemented)

1. **Determinism:** same seed + same birth → same sex across headless runs.
2. **On-screen:** birth → wait growth → verify woman has ReproductionComponent + female art; son has spear + gather.
3. **Off-screen:** dormant tick promotes daughter to `woman` in roster; son to `clansman`; conceptions after growth in same tick if hut + food OK.
4. **Wake:** return to claim — daughters and sons visually match roster types (no 12s baby lag).
5. **Hut:** daughter without hut does not conceive; after assign/auto-assign, does.
6. **Regression:** wild women still herd/reproduce; baby cap unchanged; repro harness still passes for male path.

---

## Explicit non-goals for first female-baby PR

- Full genetics / BirthEngine shipping
- Inbreeding debuffs (document hooks only until genetics phase)
- Player “clan law” toggles banning kin marriage
- Female clansmen or male women — sex maps to existing `woman` / `clansman` types only
- Changing wild woman spawn to zero

---

## Changelog

| Date | Note |
|------|------|
| 2026-08-30 | Initial planning doc — **not implemented** |
