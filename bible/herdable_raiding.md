# Herdable raiding

**Status:** Design lock (2026-09-05). Not fully shipped.
**Depends on:** proximity herd (`bible/HERDING_SYSTEM_GUIDE.md`), raid flow (`bible/raid.md`), claim wipe (flag destroy).
**Not this system:** deer/mammoth (hunt prey), fighter FOLLOW/party, prisoner cages, rope item, right-click Herd.

Right-click does **not** herd. Right-click is a context menu. Herdables attach when a herder enters their influence bubble.

---

## Goal

A raid can steal women, sheep, and goats **without** destroying the flag.

Wipe still exists: **flag destroyed** → remaining herdables become stealable. Loot and leashes extracted *before* the smash are kept. Smash first and you lose what you did not extract.

---

## Who is herdable

| Can be herded / stolen | Cannot |
| ---------------------- | ------ |
| Woman, sheep, goat     | Deer, mammoth, caveman, clansman, player |

Same-clan herders cannot steal from each other. Ordered FOLLOW (`follow_is_ordered`) fighters cannot be stolen via herd contest.

---

## Status on each herdable

Add `herd_status` on woman / sheep / goat:

| Status     | Influence attach? | How they get here |
| ---------- | ----------------- | ----------------- |
| `wild`     | Yes               | Spawn, or dropped in the open |
| `claimed`  | **No**            | Joined a living campfire / claim |
| `broken`   | Yes               | Break hits, herder died, or flag destroyed |

After they join **your** claim they are `claimed` again (yours).

`HerdInfluenceArea` / `_try_herd_chance` must refuse attach unless status is `wild` or `broken`.

Peaceful walk-up on a living camp must not vacuum the flock.

---

## Existing herd numbers (do not invent new ones unless tuning)

From `HERDING_SYSTEM_GUIDE.md` / `npc_config.gd`:

- Influence radius: **250px**
- Follow: **50–150px**
- Break leash if herder farther than **300px**
- Join clan inside herder claim: **~400px** from center
- Max per herder: **8**
- Contest: closer herder can take a *wild/broken* leash; steal chance reduced if current herder is within 150px

---

## Break (how claimed units become stealable without a wipe)

1. Enemy melee hits a `claimed` herdable.
2. Hits apply **Break**, not clan join.
3. At threshold, status → `broken` (short stagger / panic is enough).
4. Threshold **(default, pending playtest):**
   - Animals: **2** connected hits
   - Women: **3** connected hits
5. Break hits deal **no HP** for now (capture, not butcher). Revisit when combat whiff rate is under control.

Hitting a claimed herdable in another clan’s radius **starts or joins a raid**. Defenders agro.

---

## Extract (when they become yours)

Default: they change clan when they **leave the enemy claim radius still leashed**.

| Moment                         | Result |
| ------------------------------ | ------ |
| Leashed inside enemy claim     | In transit, still contestable |
| Leave enemy claim, still leashed | `clan_name` → raider clan; status stays leashed until delivered |
| Enter *your* claim             | Existing `_try_join_clan_from_claim()`; status → `claimed` |
| Herder dies or leash > 300px   | `_clear_herd()`; unit stands `broken` or `wild` where they are |
| Flag smashed while still claimed | All remaining → `broken` (or `wild`); proximity herd works |

Do **not** flip clan on first leash inside their camp (messy mid-fight). Do **not** require the full walk home before ownership (too easy to lose the raid on the road with no credit).

---

## Player loop

1. Take a party in AGRO into the target claim (that is the raid).
2. Leave at least one man **not** on War Horn / ordered FOLLOW — that is the herder. Horn drops leashes (existing rule).
3. Herder (or any raider) hits claimed women/sheep/goats until `broken`.
4. Walk into the 250px bubble. Same attach code as wild herd.
5. Walk them **out of the enemy radius** (ownership), then home if you want them in the baby/production pool.
6. Smash the flag only after leashes and carried loot are clear.

Cap 8 per herder. More targets = more trips or more herders.

---

## ClanBrain loop (goal = STEAL)

Player directs *player* raid parties. ClanBrain directs AI clans and **picks a goal**: `KILL` / `LOOT` / `STEAL` / `WIPE`.

### STEAL behavior

- Recruit includes a `herd_wildnpc` slot (herder), plus fighters.
- Do **not** path to the flag.
- Engage: walk to claimed herdables → attack until `broken` → stand in influence → lead home when `herded_count > 0` (existing lead-home path).
- Retreat when leash is full, herder dead, or fighters collapse.
- Abort **WIPE** while `herded_count > 0` inside the enemy radius (combat + 300px break will dump the flock).

### Goal scoring (simple)

Pick the max:

- **STEAL** — enemy herdable count high, your herd slots free, enemy fighters not overwhelming
- **LOOT** — claim inventory value high, carry space free
- **KILL** — enemy fighter count is the problem
- **WIPE** — already extracted, *or* enemy fighters low and flag reachable

Numbers live in `BalanceConfig` / ClanBrain weights. Do not hardcode magic in three scripts.

---

## Flag wipe vs steal

| Action | Herdables | Stockpile |
| ------ | --------- | --------- |
| Extract then smash | Extracted stay yours | Carried items stay; rest die with flag |
| Smash first | Leftovers → `broken`/`wild`, anyone can herd | Uncarried pile gone |

Herdable scatter-on-wipe is **not** a separate system. `broken` + existing proximity herd is the scatter.

---

## Implementation checklist

1. `herd_status` on woman / sheep / goat. Set `claimed` on join, `wild` on spawn, `broken` on Break or flag destroy.
2. Gate `HerdInfluenceArea` / `_try_herd_chance` on `wild` or `broken` only.
3. Melee hit vs enemy `claimed` herdable: Break counter; at threshold set `broken`. No HP.
4. Flag destroyed: that claim’s herdables → `broken`.
5. Ownership flip when leashed unit exits enemy claim radius.
6. ClanBrain raid goal `STEAL` + scoring vs KILL/LOOT/WIPE.
7. Keep contest math for `wild`/`broken` only.
8. `bible/main.md` lines that say “right-click = herd” are stale. Do not copy them.

### Files likely touched

- `scripts/npc/components/herd_influence_area.gd`
- `scripts/npc/npc_base.gd` (`_try_herd_chance`, join, flag-death hook)
- `scripts/npc/states/herd_wildnpc_state.gd`
- `scripts/npc/states/herd_state.gd`
- ClanBrain raid intent / scoring
- Combat hit path vs herdable targets
- `scripts/config/npc_config.gd` — Break hit counts

---

## Defaults locked in this doc

- Break: 2 hits animals, 3 hits women.
- Ownership: leave enemy claim while leashed.
- Break deals no HP.
- No rope item. No prisoner state. No right-click Herd.

Change those here when playtest says so. Do not re-invent them in a side guide.
