# Lineage records (future)

**Status:** Design draft — **not implemented.**  
**Prerequisite for:** [female_baby.md](female_baby.md) (inbreeding), [genetics.md](../genetics.md), domination panel trait mix  
**Drafted:** September 2026

---

## Why

Today babies store **`mother_name` / `father_name`** strings only. Off-screen roster, genetics, inbreeding penalties, and MP sync need **stable ids** and a **Person** record that survives dormant claims and wake-up.

---

## Person record (authoritative)

One row per individual (wild NPC, clansman, woman, baby, dead ancestor if we keep history).

| Field | Type | Notes |
|-------|------|--------|
| `person_id` | `String` or `int` | Server-assigned; never reused in a session |
| `display_name` | `String` | UI / logs |
| `sex` | `"male" \| "female"` | Set at birth for babies; wild women = female |
| `mother_id` | `PersonId \| null` | |
| `father_id` | `PersonId \| null` | |
| `birth_claim_id` | `String \| null` | Claim where born |
| `birth_tick` | `int` | Sim tick |
| `trait_ids` | `Array[String]` | From genetics roll |
| `alive` | `bool` | |
| `npc_node_path` | `NodePath \| null` | When on-screen; null when roster-only |

**Names are not keys.** Two “Unga” entries must not merge lineage.

---

## Where it lives

| Layer | Owner |
|-------|--------|
| **Server** | `LineageRegistry` autoload or `ClanBrain` sub-resource |
| **On-screen** | NPC meta: `person_id` → lookup in registry |
| **Off-screen** | `SettlementRoster` members reference `person_id` only |
| **Save / MP** | Serialize registry + roster ids; clients get **display subset** |

---

## Birth flow (target)

1. Mate pair chosen (server) — store `father_id`, `mother_id` on pregnancy.
2. At birth: allocate `person_id`, roll **sex** ([female_baby.md](female_baby.md)), roll traits.
3. Write Person row; spawn baby NPC or roster baby entry with same `person_id`.
4. Growth: promote using stored `sex` → `woman` or `clansman`.

---

## Inbreeding (uses lineage)

From [female_baby.md](female_baby.md):

- **Mate filter:** optional soft penalty, not hard ban — compute **coefficient** from `mother_id` / `father_id` graph.
- **Trait roll:** worse outcomes when parents share recent ancestors.
- **UI:** genetics panel shows relation hint (“cousin”) when ids overlap within N generations.

**Requires:** walk ancestor chain via `mother_id` / `father_id` only — no name matching.

---

## Wild NPCs

- Wild women / herdables: `person_id` at spawn; `mother_id`/`father_id` null or procedurally generated for flavor.
- Herded into claim: same id — **steal** moves the entity + id, not a clone.

---

## Death

- Mark `alive = false`; keep row for domination / family tree UI.
- Optional cap: prune ancestors beyond K generations for save size.

---

## Migration from today

| Today | Target |
|-------|--------|
| `mother_name` on baby | Copy to `display_name` lookup; set `mother_id` when mother has id |
| No sex field | Add at next birth only; legacy babies default male until promoted |
| Roster strings | One-time import pass assigning ids to living roster |

---

## MP rules

- Only **server** creates `person_id`.
- Birth and death events replicate as **events** (`person_id`, deltas), not full registry each tick.
- Reconnect: client receives registry slice for own clan + visible NPCs.

---

## Build order

1. `PersonId` allocator on server.
2. NPC + roster `person_id` field; babies get `mother_id` / `father_id`.
3. Replace name-only parent refs in `_spawn_baby` / settlement birth.
4. Inbreeding coefficient helper (read-only).
5. Genetics UI reads Person rows.

---

## Related

- [female_baby.md](female_baby.md)
- [genetics.md](../genetics.md)
- [settlement_sim.md](../settlement_sim.md)
- [earlygame_vision.md](../earlygame_vision.md) §8
