# Memory system — what the game remembers

**Status:** Design lock. Person records agreed **2026-10-13**. Ties, calls, showings, dawn lines, proto-words, moodles, and thin AI rivalries agreed **2026-10-31**. Clan feuds and **eight core attributes** agreed **2026-11-04** ([director_locks_2026_10.md](director_locks_2026_10.md) §11, §4). **Not implemented.**
**Wins with:** [director_locks_2026_10.md](director_locks_2026_10.md) §5 (updated the same day). If an older sentence in that file still gives an AI person a full story, §5 wins.
**Builds on:** [lineage.md](future%20implementations/lineage.md) (person ids and parents).
**Shows in:** the character info (Info, Body, Kin, and Story tabs) and the wheels in [UI.md](UI.md) and [party_ui.md](party_ui.md).
**Raid pressure:** when a blood or theft grudge clears is owned by [raid.md](raid.md). This file owns the names that stay after the pressure clears.

The sim still does the work. Memory writes down what it cost. Nobody writes dialogue, and a sentence never changes a job, a kill, or a birth.

---

## Goal

Your own clan's lives become short stories: who they came from, what they were born with, what they did, what hurt them, who they leaned toward, and how they died. The clan has a chronicle too.

AI clans do not get that. A crossing stores the clan and the names of the people who killed or stole. Those names stay after death. Everyone else in that clan is not a story.

**The trick:** tallies are almost free. Long dated lists are the expensive part. Own clans get the lists. AI clans do not.

---

## 1. Who gets what

| | Own clan, and each human friend's clan on the host | AI clan |
|--|--|--|
| Person id, lineage, genes, scars, tallies, one-line fate | Yes | Yes. The sim needs this. It is not a diary. |
| Dated story, ties, moodles, dawn lines | Yes | No |
| Jokes, showings, passed news saved as text | Yes, when they cross a line (below) | No |
| Player-facing memory of them | The Story tab | Only deed-doers: name, clan, deed, when, and whether they are still alive |

A human friend's clan remembers **its own** people. It does not get a copy of your ties.

**Dormant AI clans** do not grow stories. Kills and deaths in off-screen fights still bump tallies.

---

## 2. Per-person record

Small and fixed in size. Alive or dead, on-screen or off-screen. Kept for people the sim is tracking, including AI.

| Group | What is kept |
|-------|--------------|
| **Identity** | A stable person id (not the name). Name, sex, species mix, birth time, birth clan. |
| **Lineage** | Mother id, father id, children ids. Lets the Kin tab and inbreeding work. |
| **Born with** | Genes, perk ids (`traits[]`, max 6), and a **birth snapshot** of the eight cores ([character_attributes.md](future%20implementations/character_attributes.md), [traits.md](traits.md)). |
| **Mind** | Current **Bravery core** (drift). Fight state (attack ↔ flee, nerve bar) computed in combat unless §13 saves it. |
| **Skills and state** | Skills, current buffs and debuffs. |
| **Scars** | One line per lasting injury: what hurt them (a person or an animal type), when, and what it left behind. |
| **Tallies** | See below. |
| **Fate** | When, where and how they died. Who or what killed them. Or "still living". |

Names are never keys. Two people called "Unga" never merge.

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
| **Times picked on** | Times this person was the target of dominance or displeasure again on the same day. |

**How a kill gets its label:** at the moment of the kill, the game checks what the killer was doing (defending at home, in a raid party, in a hunt party, or none) and writes that one label. It is never worked out later.

**Bravery core** moves slowly over a life: kills raise it, scars and lost kin lower it, and a sticking **times picked on** tally can lower it. One shove does not. Fight state is fast. A showing may nudge fight state; it does not rewrite the core in one act. Full attribute rules: [character_attributes.md](future%20implementations/character_attributes.md).

---

## 3. Story timeline (own clans only)

A dated list of life beats. AI people do not get one, even when they raid, kill, or steal. That crossing is a rivalry mark (§8), not a promotion into this list.

**Life beats** (if it is not on this list, it is a tally or it is forgotten):

- Born, or old enough to work
- Paired, or a child lost
- A scar, and what left it
- A hunt or raid that changed a tally (a kill, a loss, or someone broke and ran)
- Died, and how
- The camp moved, a famine step, the flag fell
- Shamed in the ring, a friend who heard a danger call and did not come, or picking-on that has stuck
- A mourning

**Cap:** each timeline keeps at most a fixed number of lines. When it is full, the least important line goes first. Birth, first kill, scars, children, and death are never dropped. The cap is a tuning number, to be measured.

Ordinary hauling, a come-call everyone answered, and a joke at a quiet fire never become lines.

### Dawn note

At dawn the game reads that day's life beats and writes:

- one line per person who had a life beat
- one clan line
- at most about eight lines on the note the player sees

The rest wait on the Story tab. The line is filled in from the record. If a nicer sentence ever disagrees with a tally, the tally wins. A quiet dawn writes nothing. That means the camp held.

---

## 4. Clan chronicle

One list per **own** clan, kept after the clan is gone. AI clans do not get one.

- Founding, and who founded it.
- Every leader and heir, and how each one ended.
- Famines and each step of the famine ladder.
- Offerings to the Land, omens, curses, and a baby bargain ([the_land.md](the_land.md)).
- A capture, a kin sacrifice, and a captive war rite ([the_land.md](the_land.md) §9).
- The ice age reaching the camp, or the island delaying it.
- Raids made, raids suffered, and how each ended.
- Camps moved, flags raised and flags lost.
- Wipes (the flag falls and the clansmen are lost).
- A baby's death, and a fighter's death. These are chronicle lines, not only hidden counters.

The chronicle is what makes a legend screen or a recap possible later.

---

## 5. Ancestors

Dead people in an own clan are **kept forever**. Their timeline and tallies stay as they were at death.

---

## 6. Ties

A tie is how one person in your clan leans toward another. AI clans do not keep ties.

Each person holds at most **four** ties. Each tie is:

- the other person's id
- a lean: warm or sour
- the last act (laughed with, backed up, shoved, ignored a warning, praised, shared, comforted)

A new act replaces the last act on that tie. If they need a fifth person, the weakest lean drops. A tie to the dead can stay until a living person crowds it out. The Story tab shows a tie only when a life beat already fired from it.

Most acts only move the lean. They become a story line only when:

- someone was shamed in front of the ring
- a friend heard the danger call and did not come
- the same person has been picked on enough that the tally sticks

---

## 7. Calls and the ring

The ring is the hearing distance, the same short distance as the horn (about one camp, target ~400 px, see [party_ui.md](party_ui.md)). People outside it do not hear and do not react.

### Barks

A bark is two beats, then it stops. The speaker has a reason. One adult in the ring may answer: come, stay, or no answer.

Closed meanings: danger, found (meat, stone, water), come, no, hurt, baby, dead.

Babies only cry. The day they are old enough to work, the story can say they spoke the clan word for fire.

Three barks can nudge someone already in the ring. They do not hand out jobs:

- **Danger.** One idle person nearby turns toward it.
- **Found.** One nearby worker may walk over.
- **Baby.** The mother, or the nearest woman, biases toward the child.

One bark per person per stretch of time, and one bark in the camp at a time. A danger bark cuts off a joke.

### One carried fact

A person carries **one** fact: kind (danger, meat, stone, or water), place, and who saw it. They tell one adult in the ring. That person may pass it once more. Then it dies. A newer danger replaces an older find.

The fact can give the clan brain a place to point a hunt. The words do not choose the hunt. A sentence is written only if nobody came to a danger call, or the fact led to a hunt.

### Horn calls

Come, At ease, Spook, and Taunt are horn calls ([party_ui.md](party_ui.md)). They are remembered only when a life beat follows: a hunt lost, a fight started, a death. A normal "come here" that people answered is not a story.

---

## 8. Rivals

When an AI (or another) clan kills your people or steals a woman or an animal, store a **rival mark** on the clan brain. One line per neighbor clan. The clan is the rival, not one man. Full feud rules: [future implementations/clan_feud.md](future%20implementations/clan_feud.md) and [director_locks_2026_10.md](director_locks_2026_10.md) §11.

- their clan
- kill counts both ways
- the last **3** death pairs (victim, killer). Older pairs drop. The counts stay.
- the deed (`killed` or `stole`) and whether that pressure is still open
- whether the named people are still alive

Deed-doers only. Not every fighter who walked along. Names stay after that person dies, and they stay after the raid pressure clears. The worst open score (their kills of us minus ours of them) is the one stamped rival on the clan screen.

The killer also keeps **one** personal fact: the rival clan, and the victim’s name. A newer rival kill replaces it. That is recognition, not a seat and not a diary. In the player’s clan the same fact is also a life beat. His raid-kill tally still goes up either way.

Several deeds can be open at once. One returned death answers the oldest blood. Taking the prize back, or them no longer holding it, answers that theft. The 60-second gap between raids stays. Full rules for when the pressure clears: [raid.md](raid.md).

While a grudge is open, first contact is a straight fight (already locked).

This list is the player's memory of enemies. It is not a diary of their camp.

**Strongest per category.** Memories of the same kind do not pile up. Killed is one category. Stole is another. A joke, a wound, and a death are different categories. Inside one category, only the strongest memory is kept. A second, weaker death does not take another slot. This is the same idea as the rivalry list: the deed-doers, not every person who walked past. Raid pressure can still have more than one open deed. The rules for when blood or theft clears stay in [raid.md](raid.md). The story and the face use the strongest memory in that category.

---

## 9. Showings

A showing is a social act. The player does it from the **G** wheel. Clanspeople do the same acts to each other inside the ring. The wheel's look and keys live in [UI.md](UI.md). This section is what a showing does to memory and mood.

Showings do not change jobs, follow orders, or start a raid.

| Showing | Who it hits | What moves |
|---------|-------------|------------|
| **Praise** | That person, and a smaller lift for the ring | Morale up. Tie warms. |
| **Dominance** | That person, and fighters in the ring | Their morale dips. Aggression nudges toward attack. Tie sours. Bravery stays put. |
| **Displeasure** | That person | Morale down. Tie sours. A story line if the ring saw it. |
| **Joke** | Everyone in the ring | A small morale lift, gone by next dawn. |
| **Share** | That person | Costs the food in hand. A stronger warm tie than praise. |
| **Comfort** | A wounded person | Morale pulls back up. Tie warms. |
| **Mourn** | The clan, near a clan death | Clan mood stops sinking for a stretch. One chronicle line. |
| **Boast** | Fighters in the ring | Aggression nudge. Nobody is the victim. |

On the campfire, praise and joke hit the ring and have no single victim. Dominance and displeasure need a person.

Praise, joke, share, comfort, and boast are a bond nudge. They become a story line the first time they matter, or at a mourning. Dominance or displeasure once is only the sour tie and the mood dip. The same dominance or displeasure on that person again the same day stops giving a boost and increments **times picked on**.

One showing fills the camp's social slot for a stretch, same as their own joke or shove. A danger call cuts it off.

Later showings appear from camp life, not from a research list: Share when you are holding food, Comfort when they have a wound, Mourn when a clan death is there, Boast after a kill. The wheel holds at most eight slices.

Exact nudge sizes are measured in play. This doc does not guess them.

---

## 10. Proto-words

Every clan, including AI clans, has a word list made from its seed. The same clan always gets the same words. Two clans do not share a tongue.

- A **4-letter** word is the thing: wolf, meat, stone, water, come, fire, and the other closed meanings.
- A **2-letter** word is the feeling, matched to the strongest moodle.
- Both can show above a head during a bark or a showing. The color is the moodle's color.
- Under your own clan's word, a short plain gloss shows ("wolf") until you have seen that word a few times. Then the gloss drops.
- An enemy word stays glossed.
- AI words exist so a shout in range sounds like their clan. Their talks are not saved.
- Babies have no words until they are old enough to work.

The list is data from the seed plus the meaning. It is not written by a language model.

---

## 11. Moodles

Moodles are the face of a cause. They do not decide jobs. If a moodle and a tally disagree, the tally wins.

They stack. Different feelings can be true at once. The same feeling does not multiply forever: a repeat refreshes the time, and each extra copy counts for less than the one before, so a clan does not drown in copies of one moodle. The Info tab shows at most **12**, strongest first. The face shows only the strongest one (hero LOD); near LOD uses an above-head icon fallback. The others stay on the Info tab. Build spec: [emotion.md](../emotion.md) (lock 2026-11-04).

Each moodle has a cause, an icon, a color, and a small nudge to morale or aggression. They fade by the next dawn unless a tally made them last (picked-on, grief). Exact amounts for a weaker repeat are measured in play. This doc does not guess them.

Starter causes (more can be added only when a real cause exists):

- Praised, laughing, shamed, picked on, afraid, bold, grieving, comforted, fed
- Hunger and a wound may share this same row. Those causes belong to their own systems. Memory does not invent a second hunger rule.

The floating 2-letter word uses the color of the strongest moodle at that moment.

---

## 12. Performance and multiplayer

- **Server owns the record.** Clients send nothing about it.
- **Counters are bumped on events**, not by looping over everyone.
- **Network:** do not broadcast timelines, ties, or moodle lists. A client asks for one person's record when the player opens that person's character info. Tallies ride along with normal state only when they change.
- **Saves:** ids, tallies, genes, scars, own-clan timelines, ties, the chronicle, the word list per clan (or the seed that rebuilds it), and rival marks. AI timelines are not created.

---

## 13. Not decided yet

- The exact cap on timeline lines.
- Whether a player sees a clan-level legends screen, or only the chronicle in the clan info.
- What the recap shows when the player's whole bloodline ends.
- Whether the aggression bar is saved, or only bravery.
- The measured size of each moodle nudge.
