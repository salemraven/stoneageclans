# Story data — what the game remembers about each life

**Status:** Design lock, agreed with the director on **2026-10-13**. **Not implemented.** This is the next build phase (see [director_locks_2026_10.md](director_locks_2026_10.md) §6).
**Builds on:** [lineage.md](future%20implementations/lineage.md) (person ids and parents). That doc is a prerequisite and now sits inside this phase.
**Shows in:** the character info (Info, Body, Kin and Story tabs, see [UI.md](UI.md)).

---

## Goal

Every person's life becomes a short story the player can read: who they came from, what they were born with, what they did, what hurt them, and how they died. The clan has its own chronicle too. The game must be able to do this for hundreds of people over a long game without bloating saves or lagging.

**The trick:** tallies (counters) are almost free. Long dated event lists are the expensive part. So everyone gets tallies, and only some people get long lists.

---

## 1. Per-person record (kept for everyone)

Small and fixed in size. Alive or dead, on-screen or off-screen.

| Group | What is kept |
|-------|--------------|
| **Identity** | A stable person id (not the name). Name, sex, species mix, birth time, birth clan. |
| **Lineage** | Mother id, father id, children ids. Lets the Kin tab and inbreeding work. |
| **Born with** | Genes (the genetics profile), starting traits. |
| **Mind** | Bravery, and the current aggression bar (see [director_locks_2026_10.md](director_locks_2026_10.md) §4). |
| **Skills and state** | Skills, current buffs and debuffs. |
| **Scars** | One line per lasting injury: what hurt them (a person or an animal type), when, and what it left behind. |
| **Tallies** | See below. |
| **Fate** | When, where and how they died. Who or what killed them. Or "still living". |

### Tallies

Each is one number, bumped at the moment it happens.

| Tally | Counts |
|-------|--------|
| **People killed defending** | A person killed while the killer's clan was defending its own claim. |
| **People killed raiding** | A person killed while the killer was in a raid party. |
| **People killed otherwise** | Duels, standoffs, and anything that is neither of the above. |
| **Animals killed hunting** | One count **per kind of animal** (deer, mammoth, wolf, and so on), while in a hunt party. |
| **Animals killed otherwise** | Self-defense and the like. |
| **Raids joined** | Number of raid parties joined, with how many ended well or ended in a break. |
| **Hunts joined** | Number of hunt parties joined. |
| **Times broke** | Number of times the person fled a fight. |
| **Children** | Count, alongside the list of ids above. |

**How a kill gets its label:** at the moment of the kill, the game checks what the killer was doing (defending at home, in a raid party, in a hunt party, or none) and writes that one label. It is never worked out later.

---

## 2. Timeline (kept for some people)

A dated list of notable events: first kill, a big hunt, a wound and where it happened, a child saved or lost, leading a raid, breaking in a fight, atoning afterward, taking a wife, dying.

**Who gets the full timeline:**
- Everyone in the **player's clan**.
- Any AI person who **crossed paths with the player**: killed or was killed by a member of the player's clan, raided or was raided by it, stole from it or was stolen from.

**Everyone else** keeps only tallies, genes, lineage and scars, plus a **one-line fate** ("died in a raid on the Ugaru camp, age 41").

**Promotion:** if an AI person crosses paths with the player later, their timeline starts from then. What happened earlier stays as tallies.

**Cap:** each timeline keeps at most a fixed number of lines. When it is full, the least important line goes first. Birth, first kill, scars, children and death are never dropped. The cap is a tuning number, to be measured.

---

## 3. Clan chronicle

One list per clan, kept after the clan is gone.

- Founding, and who founded it.
- Every leader and heir, and how each one ended.
- Famines and each step of the famine ladder.
- Raids made, raids suffered, and how each ended.
- Camps moved, flags raised and flags lost.
- Wipes (the flag falls and the clansmen are lost).

The chronicle is what makes a "legend" screen or a recap possible later.

---

## 4. Ancestors

Dead people are **kept forever** in the record. Their timeline and tallies stay as they were at death. Names are never keys, so two people called "Unga" never merge.

---

## 5. Performance and multiplayer

- **Server owns the record.** Clients send nothing about it.
- **Counters are bumped on events**, not by looping over everyone.
- **Dormant clans** keep their people as records. Kills and deaths in off-screen fights bump the same tallies from the sim tick.
- **Network:** do not broadcast timelines. A client asks for one person's record when the player opens that person's character info. Tallies ride along with normal state only when they change.
- **Saves:** the registry saves ids, tallies, genes, scars and the timelines that exist. Timelines for people who never met the player are not created at all.

---

## 6. Not decided yet

- The exact cap on timeline lines.
- Whether a player sees a clan-level "legends" screen, or only the chronicle in the clan info.
- What the recap shows when the player's whole bloodline ends.
- Whether the aggression bar is saved, or only bravery.
