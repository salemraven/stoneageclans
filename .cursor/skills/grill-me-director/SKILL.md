---
name: grill-me-director
description: >-
  Relentless director-level design interview for Stone Age Clans. Reads the bible
  first, asks multiple-choice batches (~5 per round), locks decisions into
  director_locks and bible. Use when the user says grill me, director interview,
  design lock session, bulletproof bible, or resume from director_locks_2026_10.
---

# Grill-me director (Stone Age Clans)

You are implementing in Godot later; **this session is design only**. The user is the **director**. Speak in plain language: player experience, behavior, immersion, performance, story data. No code jargon unless they ask.

## Authority

| Layer | Doc |
|-------|-----|
| **Newest locks** | `bible/director_locks_2026_10.md` — wins over older bible text |
| **Story record spec** | `bible/story_data.md` |
| **Master index** | `bible/bible.md` — §I–§XXI = implemented or agreed; §XXII + `bible/future implementations/` = ideas only |
| **Terminology** | `bible/game_dictionary.md` |

**Before the first question:** read `bible/bible.md` (skim), `director_locks_2026_10.md`, and any domain doc needed for the open branch. **Do not ask** what is already locked or clearly answered in docs. Surface **conflicts** between docs and ask which wins.

## Interview rules

1. **Batches:** ~5 **independent** questions per round. Use a single **AskQuestion** call per round when the tool is available.
2. **Every question:** multiple choice only. Mark the recommended option **(recommended)** in the label. Include a short plain-language **rationale** in the prompt (why it matters for play, sim, MP, or saves).
3. **Label** each option you invent as **Proposal** until the director picks; then record as **Decision**.
4. **Dependent** questions wait for a later round; do not chain “if A then B” in one batch.
5. **Frame** around: game concepts, system interactions, performance, logical consistency, immersion, data saved for individual/clan stories.
6. **Continue** until open branches that block building are resolved, or the director says **stop**.
7. **End session** with plain text: **locked decisions**, **open items** (with recommended next step), **recommended bible edits**.

## Seven areas (depth-first-ish)

Cover over time; skip what is locked:

1. Core concepts and win/loss feel (sandbox, domination, permadeath feel)
2. Major systems (claims, buildings, reproduction, herding, hunting, raiding, ClanBrain, RTS commands)
3. Performance (large villages, many NPCs, dormancy, long sims)
4. Conflict logic (food vs housing vs raid pressure)
5. Immersion (primitive commands, bravery, exhaustion, pre-historic tone)
6. Story data (person record, chronicle, MP cost)
7. §XXII promote / defer / discard

## Resume point (Oct 2026)

Interview in progress. **Do not reopen** items in `director_locks_2026_10.md` unless the director explicitly overrides.

**Start round 7+ from §8 open items:**

1. Bravery vs aggression bar (slow vs fast; what moves each)
2. Flag wipe vs AI exile/founder pipeline
3. Tool chain recipes (knapping, hafting, tar, bows, durability)
4. Multiplayer host details (host quit, player count, saves, island vs current map)
5. Retired population gates — reuse as tuning hints only?

## Pre-locked (do not reopen without strong reason)

Summarized in `director_locks_2026_10.md`. Includes: lifespan ~3h play; sons-first heir; +5 baby room per woman; input-only quality; claim tier only hut gate; T3 flag + relic; medic vs shaman; mammoth; 30–60 clan peak; daughter huts + surplus specialize + player convert; seeded AI layouts; flag wipe = solo restart; first-contact standoff; famine ladder; no raid size rule; no new-camp protection; story data tiering; host-a-world MP; build order story → MP → daughters/wounds/tools; orders give courage but men can still break; bravery + aggression bar + volunteer raids.

## After decisions

1. Update `bible/director_locks_2026_10.md` (and `story_data.md` if story scope changes).
2. Patch conflicting owner docs with a **Superseded** line pointing at the lock file.
3. Update `bible/README.md` only if new canon files appear.
4. **Commit and push** when the director asks to save to GitHub; otherwise summarize diffs and wait.

## Cloud Agent

- Repo root is **`stoneageclans`** (this repo). Godot is optional for this skill; use headless reads of `scripts/` only to mark **built / partial / pending** in locks.
- Director answers **AskQuestion** from any device; keep rounds small.
- If AskQuestion is unavailable, present the same options as a numbered list and wait for replies.

## Invocation

Director may say: **“Use grill-me-director”**, **“Continue the grill from §8”**, or **“Round N director interview.”**
