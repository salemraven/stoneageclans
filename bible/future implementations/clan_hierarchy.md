# Clan hierarchy (future)

**Status:** Idea, **2026-11-04**. Not built. Not a lock. The heir default in [director_locks_2026_10.md](../director_locks_2026_10.md) §1 still wins until this is promoted.
**Screen lives with:** the Leader’s Hut clan panel ([leader_hut.md](../leader_hut.md)).
**Numbers live with:** the planned clan identity on the brain ([ai_clan_brain.md](../ai_clan_brain.md) § Clan identity). This screen does not invent a second set of stats.

The player sees the clan as one character. A few named people at the top pull that character harder than the crowd. That character sheet is this same screen. There is not a second window for traits and buffs.

---

## One screen

Open it from the Leader’s Hut. Everything the player needs about the clan is here.

- **Left, or top:** the heir box and the high seats. Drag people in and out.
- **The law** sits next to the boxes (warriors, shamans, elders, and the later laws).
- **Clan traits** the weighted average produced. These update when a seat changes.
- **Buffs and debuffs** already on the clan: shrine, relics, shame, a rally, a famine step, and the feud swing (shame or emboldened). The same list the brain was going to show.
- **Clan morale**, bold versus brittle.
- **The feud list.** One stamped rival on top, the other neighbors under it, with the last three death pairs. Rules: [clan_feud.md](clan_feud.md).

Dropping a person into a seat should move those traits and buffs on this screen, so the player can see the lean before they close it. Roster and kin can be a tab on this same window later. They are not a separate menu.

---

## The boxes

One column, drag and drop, same drag the player already uses for people.

| Box | Who | What it does |
|-----|-----|----------------|
| **Top: Heir** | One man | Who you become when you die. |
| **Under him: high seats** | Filled by the player | They do not inherit. They color the clan while they sit there. |

Empty seats add nothing. If the player never fills them, the clan is only the plain average of its people.

**How many seats.** The law sets the count.

- A campfire clan: the heir plus **one** seat.
- A flag clan: the heir plus **three** seats.
- A later law may allow more or fewer. That is the only “bigger hierarchy” knob.

**Default heir.** Until the player drags someone into the top box, the heir is still the oldest living son, then the oldest clansman. Dragging a man in is the player naming the heir. Dragging him out returns the automatic heir. The top box stays a man unless a future succession law says otherwise.

---

## How the seats change the clan

The player clan does not need the raid brain for this. The clan still has traits and stats.

- Each stat on the clan is the **average** of the people, as already planned.
- A normal person counts **once**.
- A person in a high seat counts **more than once**. How many times is not chosen yet. Measure it in play before coding a number. The aim is: three strong captains can lean a camp, and they cannot erase everyone else.
- A trait the seats share is easier to put on the clan than the same trait scattered through the crowd, because those people are counted more than once. There is still one average. The seats are not a second brain.
- The pull works downward too. Timid or weak people in the seats make the clan easier to break and weaker at whatever that law cares about.

What the weighted clan actually touches, using systems that already exist or are already planned:

- The clan morale bar (bold versus brittle).
- How willing men are to step up when the **player** calls a hunt or a raid. The clan does not start raids on its own because of this screen.
- Shrine and rite buffs, when the law is shamans.
- This screen: traits, morale, buffs, and debuffs, in the same view as the seats.

High seats do not assign defend, hunt, or work. Those stay the drags onto the ground, the claim, and the buildings.

---

## Laws

The player picks the law at the Leader’s Hut, next to the succession switch (sons first, or oldest man). The law chooses who may be dropped in a seat, and which stats get the extra weight. It does not add a new buff list.

### First laws

| Law | Who may sit | Extra weight on | How the clan feels |
|-----|-------------|-----------------|--------------------|
| **Warriors** | Clansmen | Strength and bravery | Bolder. Men step up faster for a fight the player leads. No bonus to craft or birth. |
| **Shamans** | People tied to the shrine or the shaman hut. Women may sit. The heir box stays a man. | Rites and clan mood | Shrine buffs lean stronger. Fighters are less hungry to raid. |
| **Elders** | The oldest clansmen. The seat rejects a young man while an older one is available. | Endurance, and the scars and bravery that come with age | Steadier. Harder to panic. Slower to chase a raid. |

### More laws, later

These stay on the list so they are not forgotten. They are not the first three.

| Law | Who may sit | Extra weight on | How the clan feels |
|-----|-------------|-----------------|--------------------|
| **Hunters** | Clansmen with hunt tallies, or the best perception | Perception, animals killed | The camp finds prey sooner. Worse at holding a wall. |
| **Hearth** | Women with living children | Social, births | More babies, calmer mood. The fight line is thinner. |
| **Blood** | Kin of the heir (his brothers and sons) | The heir’s own traits, counted again through his kin | The clan looks like its leading family. A thin family means empty seats and no extra weight. |

A new law is only a filter plus a pair of stats. If it needs a brand new stat, it does not belong on this list yet.

---

## Not in this idea

- No code, no scene, no guessed seat-weight number.
- High seats are not the feud list and not the job roster. The nemesis is the stamped rival clan, on this same screen.
- AI clans can use the same weights later, from whoever their law would seat. That is not required to build the player screen.
