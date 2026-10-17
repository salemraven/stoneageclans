# Natural selection & evolution — design lock (director interview)

**Status:** Design lock from director Q&A (**Oct 2026**), extended with Primer-inspired simulation goals. **Not implemented.**  
**Authority:** Extends [director_locks_2026_10.md](director_locks_2026_10.md) §4–§6 and [genetics.md](genetics.md). Where this file specifies evolution / Agro / MP hosting / wipe presentation, it wins over older scattered notes until merged into `director_locks_2026_10.md`.  
**Implementation spec:** [genetics.md](genetics.md) · deep math [future implementations/genetics.md](future%20implementations/genetics.md) · life records [story_data.md](story_data.md)

**Inspiration (concept only):** [Primer — Evolution playlist](https://www.youtube.com/playlist?list=PLKortajF2dPBWMIS6KF4RLtQiG6KQrTdB) (natural selection, selfish gene, aggression, kin sacrifice, green-beard altruism). We adapt **ideas**, not blob mechanics.

---

## 1. Goal in one sentence

**Populations change over generations** because **genes affect food and fight**, the **world kills or filters**, and **survivors reproduce** — so clans drift physically and culturally while the player reads it in **chronicle, Kin, and named lives**.

Individuals do **not** “evolve” mid-life in the biological sense. **Clans and bloodlines do.**

---

## 2. Interview locks (Round 7+, Oct 2026)

These were agreed in the director grill session; code is still mostly pending.

### 2.1 Agro, bravery, raids (one person bar)

| Lock | Detail |
|------|--------|
| **Agro bar** | Single per-person **fight-or-flight** meter (player-facing name **Agro**). Replaces separate “aggression bar” + “nerve bar” as **two person concepts**. |
| **Code today** | Flight uses `morale_bar` + bravery → flight line; UI still labels `agro_meter` separately — **merge toward one Agro over time**. |
| **Bravery** | Lasting stat (genes, age, kills, scars, buffs/debuffs). Shapes **break line** and calm **rest** on Agro; life events nudge bravery slowly. |
| **ClanBrain** | Owns **raid appetite** (how often / who to hit), not each man’s moment-to-moment Agro. |
| **AI raids** | **Volunteers** by bravery / Agro; timid men stay home (defend, hunt, build). |
| **Player raids** | **Player chooses** the squad (RTS, horn, Follow/Attack, clan menu) — same as [raid.md](raid.md) today. Volunteer rule is **AI-only**. |

### 2.2 Flag wipe & defense (immersion)

| Lock | Detail |
|------|--------|
| **Player** | Flag gone → **keep playing**, **no clansmen under your command** (solo restart for command). |
| **Normal case** | Most fighters **die defending** home, women, children — not instant despawn at the flag. |
| **Rare** | Man **breaks** (Agro/flight), **does not** stand defense → **wanders off** chunk → leaves sim. |
| **Wild / founder** | Only on that rare survival path (and AI wipe pipeline): **wild caveman** → optional **founder** if **clan slots** allow (see [clan_founding_and_exile.md](clan_founding_and_exile.md)). Default wipe is **graves**, not mass walk-off. |
| **Founder count** | **Recommended:** at most **one founder roll per wipe** (same as exile doc v1) unless director revises. |

### 2.3 Tools

| Lock | Detail |
|------|--------|
| **Tool chain** | Knapping, hafting, tar, bows, input quality — still planned per economy locks. |
| **Durability** | **Not spent in v1** of tool chain; wear/break **later** (no repair recipe remains locked out). |

### 2.4 Multiplayer

| Lock | Detail |
|------|--------|
| **Shipping target** | **Persistent dedicated server** — saved world, reconnect, **ClanBrain runs** player clans while offline (see [future implementations/island_mp.md](future%20implementations/island_mp.md)). |
| **Listen host** | **Dev / LAN only** — same server-authoritative code, not the long-term fantasy. |
| **Replaces** | Earlier one-line “host-a-world, stops when host quits” as **production** shape; listen host remains a **deployment**, not the architecture. |

### 2.5 Economy gates

| Lock | Detail |
|------|--------|
| **Claim tier only** | Hut tier gate unchanged. |
| **Old pop / food-day numbers** | **Tuning hints only** (design, AI staffing, balance) — **never** hard-block a hut the claim allows. |

---

## 3. The selection loop (what we build)

```text
VARIATION          →  PRESSURE              →  DIFFERENTIAL SURVIVAL  →  REPRODUCTION
(birth: parents    →  (food, fight,         →  (who dies, who starves,  →  (who fathers
 + noise)              climate, MP)            who breaks and runs)       / bears children)
```

| Step | System |
|------|--------|
| **Variation** | `BirthEngine.resolve(mother, father)` → genome ([genetics.md](genetics.md)) |
| **Expression** | Once at birth (and grow-up): genome → `Stats`, calories/day, bravery baseline, card bands |
| **Pressure** | Famine ladder, combat (defend vs raid), hunt injury, future climate windows, **other clans on island** |
| **Reproduction** | Only living housed women + mates; **mate prestige** (tallies, defense, hunt) biases **who passes genes** |

**Server** owns genealogy, births, death tags, and periodic **clan trait snapshots** (MP-safe). Clients display via [story_data.md](story_data.md).

---

## 4. Primer ideas → Stone Age Clans (priority tiers)

### Tier 1 — Ship first (best fit)

| Idea | In our game |
|------|-------------|
| **Natural selection** | Loci × food × fight × births; chronicle shows drift. |
| **Selfish gene** | Heirs, lines, raids for **your** stockpile; winning raid can still **cost bloodline**. |
| **Kin selection** | Die defending claim; deaths tagged **defending** vs **raiding**; mate prestige. |
| **Logistic competition** | ~30–60 peak, food-days, island + persistent server = shared food pressure. |
| **Trait tradeoffs** | metabolism ↔ food; body_size ↔ agility/target; cold ↔ heat; bold ↔ cohesion. |

### Tier 2 — Soon after Tier 1 works in playtest

| Idea | In our game |
|------|-------------|
| **Hawk / dove mix** | Clan raid appetite from **distribution** of bravery, not one stub temper. |
| **Clan-scoped altruism** | Horn, Guard, claim food — help **allies**, not strangers. |
| **Green-beard lite** | Shaman paint, scars, flag — **recognize us**; standoff + MP identity; mechanics optional v1. |
| **Risky resources** | Mammoth, hunt, caravan — perception + bravery. |

### Tier 3 — Later

Green-beard **impostors**, **herd domestication** genetics, **punctuated climate** eras, heavy allele graphs.

### Skip as player-facing systems

Pure stranger altruism, Hamilton’s rule in UI, anonymous blob sim.

---

## 5. Recommended v1 implementation path

Order aligns with [genetics.md](genetics.md) § Build order:

1. **Lineage** — `person_id`, `mother_id`, `father_id` ([story_data.md](story_data.md) phase).
2. **`LocusCatalog` + `BirthEngine`** — start with ~5 loci: `metabolism`, `body_size`, `bravery_baseline`, `perception`, species mix marker.
3. **Expression** — genome → daily calories + combat-relevant stats + card bands.
4. **Baby feeding + starvation** — claim-fed babies; **famine kills babies first**; metabolism matters.
5. **Death tags** — `selection_death` with cause: famine | combat_defend | combat_raid | hunt | climate (later).
6. **Mate scoring** — extend repro mate pick: prestige from tallies, not abstract “quality” only.
7. **Clan snapshots** — every N births: mean metabolism, body size, etc. → chronicle + JSONL.
8. **Agro merge** — one person bar in UI/docs; bravery → break line (already partial in `morale_bar.gd`).
9. **Hawk/dove** — wire ClanBrain raid frequency to fighter bravery distribution.
10. **Climate windows** — ice/drought select on resistance loci (after baseline works).

**Reliability gates** before coding: locus list, mutation rates, tradeoff pairs, save schema — see [future implementations/genetics.md](future%20implementations/genetics.md) § Reliability gates.

---

## 6. Player-visible evolution (keep readable)

| Level | v1 target |
|-------|-----------|
| **Character / Kin** | Bands: Slight / Burly, appetite hints, bravery, Agro. |
| **Chronicle** | Plain lines: *“After the lean years, fewer burly men.”* *“Raid culled the bold line.”* |
| **Later** | Clan trait % graph, hybridization timeline. |

No equations in UI. Causes must be readable: **starved baby**, **died defending**, **broke and fled**.

---

## 7. Scenes we design toward

1. **Post-raid:** Most defenders dead at claim; next generation fathered by younger, timid survivors.  
2. **Lean decade (persistent server):** Low-metabolism clans persist; oversized neighbor shrinks or raids more.  
3. **Long hybridization:** Captive / neighbor matings shift species mix in Kin tab over hundreds of in-game years.

---

## 8. Related docs

| Doc | Role |
|-----|------|
| [genetics.md](genetics.md) | Canonical genetics overview + code status |
| [future implementations/genetics.md](future%20implementations/genetics.md) | Loci schema, climate, ledger |
| [story_data.md](story_data.md) | Person record, tallies, timelines |
| [director_locks_2026_10.md](director_locks_2026_10.md) | Master locks index |
| [clan_founding_and_exile.md](clan_founding_and_exile.md) | Wild cavemen, founders, slots |
| [raid.md](raid.md) | Motives, player vs AI raid |
| [roadmap_2026.md](roadmap_2026.md) | Story data → MP → daughters/tools |

---

## 9. Open (fine-tune later)

- Exact founder count per wipe (one vs few if multiple slots).  
- Persistent server when **zero** humans online: slow sim vs pause vs full sim.  
- Timeline line cap, bloodline-end recap UI ([story_data.md](story_data.md) §6).  
- Save live Agro on logout vs bravery only.

---

*Promote rows into [director_locks_2026_10.md](director_locks_2026_10.md) when director says **save** to GitHub canon merge.*
