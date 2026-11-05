# Stone Age Clans — dev update (Nov 5, 2026)

*Paste-friendly version for Discord is below the line.*

---

## Discord paste

**Stone Age Clans — what landed in this update**

**AI camps keep up while you’re away**
- Sleeping clans still grow people, herd wives, and run huts on real time (no double-counting in the 30s settlement tick).
- Herding is done by **grown sons**, not the old “one herder per six people” cap.
- Edible stock from abstract gather is capped so food stays near **~1 day per mouth**; wood/stone/fiber still pile up.
- Off-screen herd trips use measured walk time (chase + depart wait), so dormant camps stay close to live pace in the pace arena.

**Sandbox**
- **AI productivity** slider (0.5–2.0) in `SandboxSettings`; pace arena forces 1.0 for fair tests.
- New scripts: `tools/launch_pace_arena.sh`, `tools/test_ai_camp_parity.gd`.

**Party & RTS (design + docs)**
- **Next party UI:** press **H** → horn animation/sound → circle **Follow / Raid / Hunt** → second menu for stances, **Break** on every submenu. Old dock/pile/short-horn plan is **scrap**.
- **Before we build that menu:** fix formation behavior on the **existing bottom-left bar** (standing speed for Guard/Stalk; Hide/Ambush facing prey/enemy, not the leader). See `bible/party_ui.md`.
- RTS bible now matches code (Arc speed, when formations break under agro, ambush release).

**Combat & hunt**
- Player-led hunt party flow (`player_party_hunt.gd`) and related FSM hooks.
- Raid design docs refreshed (motives/goals, feud target, odds gate — see `bible/raid.md`).

**Characters & tools**
- Genetics / phenotype and character-card layer work; limb tuner and animation receipt updates.
- `PlayerB.png` removed; layered character assets expanded.

**Not in this build**
- Horn **radial menu** UI (design only).
- Story/lineage/memory UI (still design).
- Full player raid verbs (STEAL/LOOT/KILL/WIPE) — design lock still ahead of code.

**Try it**
- Game: `bash tools/launch_game_mac.sh`
- Pace arena (headless-friendly): `bash tools/launch_pace_arena.sh`

Questions and playtest notes welcome in Discord — especially party formations on the current HUD.

---

## Repo pointers

| Topic | Doc |
|-------|-----|
| Party UI (next + formation fixes) | [party_ui.md](../party_ui.md) |
| RTS as shipped | [rts.md](../rts.md) |
| Dormancy & pacing | [dormancy.md](../dormancy.md) |
| Raid design | [raid.md](../raid.md) |
| Changelog | [CHANGELOG.md](../CHANGELOG.md) |
