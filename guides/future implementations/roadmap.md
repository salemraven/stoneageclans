# Stone Age Clans — Roadmap to Beta

**Target:** Playable beta with a complete early→mid game loop. Late game is placeholder/scaffold only.

**Current state (per bible.md):** ~40% GDD alignment. Core gameplay solid; mid game and late game largely undesigned.

**Implementation plans:** See `guides/dev_resources.md` for Cursor plans location (`C:\Users\mxz\.cursor\plans`).

---

## Phase 1: Early Game Lockdown (Alpha-Stable)

*Goal: No crashes, no blockers. Early game loop feels complete.*

### 1.1 Critical Fixes
- [ ] Minimum 200px between land claims (build_state.gd)
- [ ] Area-of-agro (AOA) for cavemen — trigger combat when others enter personal space, not just claim
- [ ] Deposit trigger with herd size — 2+ herded NPCs → deposit even below 80% inv

### 1.2 Missing Core Systems
- [ ] **War Horn (H key)** — idle clansmen sprint to player, auto-herd
- [ ] **Medic Hut** — wounded NPCs auto-path here when berries stocked
- [ ] **Wounds** — HealthComponent tracks wound state; Medic heals over time

### 1.3 Polish & Balance
- [ ] Bread/Oven balance pass (1 Wood + 1 Grain → 1 Bread, 15s)
- [ ] Cheese/Butter from Dairy (woman-assigned)
- [ ] Wool/Milk from Farm (sheep/goats herded in)

### 1.4 Performance
- [ ] FSM priority caching (avoid recalc every 0.1s)
- [ ] Distance-based NPC update scaling

---

## Phase 2: Mid Game Design & Implementation

*Goal: Define and build the mid game. This is the biggest gap.*

### 2.1 Design Work (Do First)
- [ ] **Mid game loop doc** — What does "mid game" mean? (e.g., 2–3 claims, 10+ clansmen, first raids)
- [ ] **Flag upgrades** — Flag → Tower → Keep → Castle (radius, storage, relic requirements)
- [ ] **Building progression** — Unlock order, costs, woman requirements
- [ ] **Relic system** — Spawn locations, buffs, shrine integration

### 2.2 Buildings (GDD Alignment)
| Building | Woman | Status | Notes |
|----------|-------|--------|-------|
| Living Hut | 0 | ✅ | +5 baby pool |
| Supply Hut | 0 | ✅ | 6 slots |
| Shrine | 0 | ✅ | Relics → buffs |
| Dairy Farm | 1 | ✅ | Cheese, butter |
| Oven | 0 | ✅ | Bread |
| Farm | 1 | ❌ | Wool, milk — herd animals in |
| Spinner | 1 | ❌ | Cloth from wool |
| Armory | 1 | ❌ | Weapons |
| Tailor | 1 | ❌ | Armor, backpacks, travois |
| Medic Hut | 1 | ❌ | Heals wounds |
| Storage Hut | 0 | ❌ | Extra storage (or merge with Supply Hut) |

### 2.3 Raiding
- [ ] ClanBrain raid_intent → NPCs self-assign to Raid state
- [ ] Raid flow: move to enemy claim → loot buildings → destroy flag = total wipe
- [ ] War Horn + Herd = instant war party formation

### 2.4 New NPCs & Items
- [ ] **Horses** — riding, travois (extended carry)
- [ ] **Predators** — dire wolves, mammoths; hostile, loot drops
- [ ] **Spear** — extended melee range
- [ ] **Meat** — from animals/predators, 10% hunger

### 2.5 Hominid Species (5 Types)
- [ ] Species selection at bloodline start
- [ ] 50/50 trait inheritance per baby
- [ ] Stat blending from parents
- [ ] Species: sapiens, neanderthal, heidelbergensis, denisovan, floresiensis

---

## Phase 3: Generational Permadeath & Late Game Scaffold

*Goal: Core fantasy works. Late game is minimal placeholder.*

### 3.1 Generational Loop
- [ ] Player death at 101 (or combat) → succession to oldest clansman
- [ ] Baby growth timer: 90s test / 13 years design
- [ ] Bloodline tracking — species mix, hybrid bonuses
- [ ] Stats panel (Tab): clansmen, baby pool, raids won, bread baked, etc.

### 3.2 Late Game (Placeholder)
*Per lategame.md: "governments religions trade" — not designed. Scaffold only.*

- [ ] **Governments** — Placeholder: claim "type" (tribe/chiefdom) — no mechanics yet
- [ ] **Religions** — Placeholder: shrine relic count → "faith level" — no mechanics yet
- [ ] **Trade** — Placeholder: future NPC type "trader" — no mechanics yet

*Do not build full systems. Add hooks and UI placeholders so beta testers see "coming later."*

---

## Phase 4: Beta Readiness

### 4.1 Content & Balance
- [ ] Wild wheat spawns only outside claim radius
- [ ] Relic spawns (finite, non-respawning)
- [ ] Balance pass: gather rates, combat, reproduction, food values

### 4.2 UX & Onboarding
- [ ] Tutorial or first-time hints (optional)
- [ ] Stats panel (Tab) complete
- [ ] Clan symbol + color picker on first flag placement

### 4.3 Stability
- [ ] No known crash paths
- [ ] Save/load (if not already present)
- [ ] 15–30 min playtest without critical bugs

### 4.4 Art & Audio
- [ ] 16-color palette consistency
- [ ] 64×64 pixel art pass
- [ ] SFX for combat, building, herding (minimal)

---

## Summary: What Exists vs What's Needed

| Area | Current | Beta Target |
|------|---------|-------------|
| Early game | Solid | Locked, polished |
| Mid game | ~20% | Full loop: buildings, raids, horses, predators |
| Late game | 0% | Placeholder hooks only |
| Generational permadeath | Not wired | Working succession |
| Hominid species | Not implemented | All 5 + hybridization |
| War Horn | Not implemented | Working |
| Medic / Wounds | Not implemented | Working |

---

## Recommended Order

1. **Phase 1** — Fix critical bugs, add War Horn + Medic. Early game feels done.
2. **Phase 2.1** — Write mid game design doc. Don't code until loop is clear.
3. **Phase 2.2–2.5** — Implement buildings, raiding, horses, predators, hominids.
4. **Phase 3.1** — Wire generational permadeath.
5. **Phase 3.2** — Add late game placeholders (1–2 days max).
6. **Phase 4** — Polish, balance, beta test.

---

*Sources: bible.md, gdd.md, lategame.md, IMPLEMENTATION_CHECKLIST.md, future implementations/*
