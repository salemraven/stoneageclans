# RTS Melee Test — Root Cause Analysis

**Last updated:** 2026-02-20  
**Symptom:** Only 2 `combat_started` per run (target ≥10). Test fails on engagement.

---

## Executive Summary

**Primary root cause:** `npc.is_hostile` is never set for agro combat test followers. The raid path in `combat_state.can_enter()` requires `npc.is_hostile == true` to enter combat without waiting for agro. It stays `false` because only player followers get `is_hostile` synced via `_update_followers_hostile()` / `_apply_command_context_to_followers()`; agro combat followers use NPC leaders and are not in `_follower_cache`.

**Secondary factor:** With raid path blocked, all 18 followers must use the agro path (`agro_meter >= 70`). Agro path also requires a target from `DetectionArea` (300px) or legacy search. Formation geometry + movement limits who gets enemies in DetectionArea in time.

---

## 1. Combat Entry Flow

### Two paths in `combat_state.can_enter()`:

| Path | Condition | Target source |
|------|-----------|---------------|
| **Agro path** | `agro_meter >= 70` | DetectionArea (300px) or legacy (450px in test) |
| **Raid path** | `hostile && herder && ordered && raid_allow` | DetectionArea or legacy |

### Raid path conditions (line 507):

```gdscript
var hostile: bool = npc.get("is_hostile") as bool if npc.get("is_hostile") != null else false
var raid_ok: bool = hostile and h != null and is_instance_valid(h) and ordered and raid_allow
```

- `hostile` = `npc.is_hostile` — **never set** for agro combat followers
- `h` = herder (leader) — ✅ set
- `ordered` = `follow_is_ordered` — ✅ true
- `raid_allow` = player OR (agro test + `allow_raid_without_player`) — ✅ true

**Result:** `raid_ok = false` because `hostile = false`.

---

## 2. Where `is_hostile` Is Set

| Location | When | Who |
|----------|------|-----|
| `main._apply_command_context_to_followers()` | Player toggles FOLLOW/GUARD | `_follower_cache` (player followers only) |
| `main._update_followers_hostile()` | Every 0.2s | `_follower_cache` (player followers only) |
| `main._set_ordered_follow()` | Player orders follow | New follower added to `_follower_cache` |
| `main._setup_agro_combat_test_environment()` | Spawn | ❌ Sets `command_context.is_hostile` but **never** `npc.is_hostile` |
| `raid_state.enter()` | Enter raid | Sets true |
| `agro_state` | Wild cavemen agro | Based on `agro_level >= threshold` |

Agro combat followers: herder = NPC leader, never in `_follower_cache`, so no code ever calls `npc.set("is_hostile", true)`.

---

## 3. Agro Path — Why Only 2 Succeed

With raid path blocked, followers must reach `agro >= 70` first, then have a target in DetectionArea.

### Proximity agro (380px)

- Rate: 75 agro/sec in GUARD
- ~1 second to hit 70 when enemy within 380px
- `agro_threshold_crossed: 31` → 31 times NPCs crossed 70

### DetectionArea (300px)

- `body_entered` populates `nearby_enemies`
- Only bodies overlapping the 300px circle are tracked
- Formation: clansmen in arc 32–45px in front of leader
- When formations cross: mainly front-center NPCs get enemies within 300px

### Timing

- Leaders move toward enemy claim (~60 px/s)
- Formations approach at ~120 px/s relative
- Overlap window when front NPCs have enemies in 300px is limited
- FSM evaluates combat every 0.1s

**Conclusion:** Most NPCs hit `agro >= 70` (31 crosses), but only 2 also have an enemy in DetectionArea when FSM evaluates combat. Others either:
- Never have an enemy in 300px (formation geometry), or
- FSM evaluation happens before or after the overlap window

---

## 4. Fix

**In `_setup_agro_combat_test_environment()`, after setting `command_context` for followers:**

```gdscript
npc.set("command_context", ctx_a)
npc.set("is_hostile", true)  # Enable raid path for agro combat test
```

Same for Clan B followers.

**Effect:** Raid path becomes valid. Followers enter combat as soon as DetectionArea has an enemy (300px), with no need for `agro >= 70` first. Expected result: many more `combat_started` events.

---

## 5. Verification Checklist

After fix:

1. [ ] `combat_started >= 10` per run
2. [ ] `combat_ended == combat_started` (no dangling combats)
3. [ ] `peak in_combat >= 4`
4. [ ] Visual: formations engage in melee, not passing through
