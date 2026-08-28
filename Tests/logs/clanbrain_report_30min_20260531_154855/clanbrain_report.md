# ClanBrain Report (standard)

## Session

- **Duration:** 1800.6s
- **JSONL:** `/Users/macbook/Desktop/stoneageclans/Tests/logs/clanbrain_report_30min_20260531_154855/playtest_session.jsonl`
- **NPC-only world:** yes
- **Timed run:** 30 min
- **AI clans with eval:** 4

## Summary

| Clan | Pop | Fight | Food (end) | Hunts | Hunt OK | Gath | Dep | G fail* | Quota fill | Surv | Clansmen | Bld | 1st hunt |
|------|-----|-------|------------|-------|---------|------|-----|---------|------------|------|----------|-----|----------|
| HA YIUK | 0→59 | 40 | 0.0 | 6 | 5 | 820 | 478 | 53 | 64% | 75.1s | 39 | 5 | 77.8s |
| LI JUAB | 0→10 | 6 | 0.0 | 6 | 2 | 108 | 80 | 3 | 77% | 180.1s | 5 | 3 | 181.8s |
| RU VEAK | 0→12 | 10 | 0.0 | 4 | 2 | 126 | 66 | 3 | 92% | 75.1s | 9 | 2 | 75.7s |
| XA MIUW | 0→71 | 54 | 0.0 | 3 | 3 | 1036 | 616 | 34 | 35% | 65.1s | 54 | 4 | 67.2s |

*G fail* = gather failures excluding `inventory_full` noise.

## Gates

- **ClanBrain invariant failures:** 0
- **Parties formed / disbanded:** 19 / 19
- **Stuck parties (rough):** 0

## ClanBrain health

| Clan | Def fill | Def under | Search fill | Search under (no breed) | Food min→max→end | Survival |
|------|----------|-----------|-------------|-------------------------|------------------|----------|
| HA YIUK | — | — | 64% | 20% | 0.0→1.0→0.0 | 75.1s |
| LI JUAB | — | — | 77% | 8% | 0.0→1.0→0.0 | 180.1s |
| RU VEAK | — | — | 92% | 25% | 0.0→1.0→0.0 | 75.1s |
| XA MIUW | — | — | 35% | 50% | 0.0→1.0→0.0 | 65.1s |

### Hunt lifecycle

| Clan | Started | Completed | Aborted | Prey killed | Prey escaped | Hunt deposits | Butcher done |
|------|---------|-----------|---------|-------------|--------------|---------------|--------------|
| HA YIUK | 6 | 5 | 1 | 5 | 0 | 5 | 0 |
| LI JUAB | 6 | 2 | 4 | 2 | 0 | 2 | 0 |
| RU VEAK | 4 | 2 | 2 | 2 | 0 | 2 | 0 |
| XA MIUW | 3 | 3 | 0 | 3 | 0 | 3 | 0 |

### Breeding pipeline

| Clan | Women joined | Babies spawned | Clansmen grown | 1st clansman |
|------|--------------|----------------|----------------|--------------|
| HA YIUK | 3 | 42 | 39 | 75.4s |
| LI JUAB | 3 | 5 | 5 | 180.5s |
| RU VEAK | 2 | 9 | 9 | 71.3s |
| XA MIUW | 5 | 54 | 54 | 63.6s |

## Worker efficiency

| Clan | Tasks OK | Tasks fail | Task rate | Gather no-res | Stuck escapes | Top FSM (fighters) |
|------|----------|------------|-----------|---------------|---------------|---------------------|
| HA YIUK | 0 | 0 | — | 0 | 55 | idle 60%, gather 23%, eat 5% |
| LI JUAB | 0 | 0 | — | 0 | 5 | idle 56%, combat 12%, gather 10% |
| RU VEAK | 0 | 0 | — | 0 | 11 | idle 73%, agro 8%, gather 8% |
| XA MIUW | 0 | 0 | — | 0 | 45 | idle 72%, gather 14%, eat 5% |

## Economy (session)

- **Items gathered:** 2090
- **Items deposited:** 1240
- **Deposit yield:** 59%
- **Gather failures (all):** 1554
- **Gather failures (actionable):** 93
- **Deposit failures:** 0

### Gather failures (actionable)

- **empty_switch:not_harvestable:** 102
- **not_harvestable:** 81
- **resource_invalid:** 10
- **moved_during_gather:** 2

### Items by resource

| Resource | Gathered | Deposited | Yield |
|----------|----------|-----------|-------|
| Berries | 129 | 69 | 53% |
| Bone | 0 | 34 | — |
| Fiber | 120 | 55 | 46% |
| Grain | 116 | 45 | 39% |
| Hide | 0 | 44 | — |
| Meat | 0 | 51 | — |
| Mushroom | 9 | 4 | 44% |
| Nuts | 299 | 105 | 35% |
| Spear | 0 | 73 | — |
| Stone | 154 | 96 | 62% |
| Wood | 1263 | 664 | 53% |

## Buildings (session)

- **Total placed:** 14

### By type

- **Living Hut:** 8
- **Dairy Farm:** 2
- **Farm:** 2
- **Oven:** 2

### By source

- **herder_hut:** 8
- **milestone:** 6

### Chronological

- t=31.1s **XA MIUW** — Living Hut (herder_hut) builder=LONU @ (-1997,-542)
- t=38.8s **RU VEAK** — Living Hut (herder_hut) builder=DOUZ @ (502,-2600)
- t=42.9s **HA YIUK** — Living Hut (herder_hut) builder=BERU @ (2294,791)
- t=148.0s **LI JUAB** — Living Hut (herder_hut) builder=JUNO @ (972,3357)
- t=207.3s **XA MIUW** — Farm (milestone) @ (-2033,-486)
- t=218.4s **HA YIUK** — Living Hut (herder_hut) builder=BERU @ (2071,710)
- t=327.4s **XA MIUW** — Dairy Farm (milestone) @ (-2222,-623)
- t=398.1s **HA YIUK** — Farm (milestone) @ (2268,845)
- t=429.2s **RU VEAK** — Living Hut (herder_hut) builder=DOUZ @ (432,-2514)
- t=503.1s **HA YIUK** — Dairy Farm (milestone) @ (2131,657)
- t=652.7s **XA MIUW** — Oven (milestone) @ (-2179,-675)
- t=862.2s **LI JUAB** — Living Hut (herder_hut) builder=REWE @ (1010,3302)
- t=946.7s **HA YIUK** — Oven (milestone) @ (2056,768)
- t=1360.4s **LI JUAB** — Living Hut (herder_hut) builder=JUNO @ (780,3232)

## Per-clan detail

### HA YIUK

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/10 (64% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 99 | 55 |
| Bone | 0 | 14 |
| Fiber | 54 | 20 |
| Grain | 42 | 8 |
| Hide | 0 | 19 |
| Meat | 0 | 21 |
| Mushroom | 3 | 3 |
| Nuts | 111 | 37 |
| Spear | 0 | 28 |
| Stone | 72 | 39 |
| Wood | 439 | 234 |

#### Failures

- **Gather:** inventory_full=329, not_harvestable=47, empty_switch:not_harvestable=21, resource_invalid=4, moved_during_gather=2

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BAUF | 0 | 0 | 1 | 16 | idle 70%, gather 17%, wander 5% |
| BEOX | 0 | 0 | 5 | 49 | idle 59%, gather 29%, craft 5% |
| BERU | 0 | 0 | 17 | 62 | gather 32%, wander 21%, agro 21% |
| BUHU | 0 | 0 | 2 | 17 | idle 61%, gather 29%, eat 5% |
| CICE | 0 | 0 | 0 | 4 | idle 80%, gather 9%, herd_wildnpc 5% |
| CUIZ | 0 | 0 | 1 | 15 | idle 72%, gather 20%, eat 5% |
| DAKE | 0 | 0 | 1 | 13 | idle 64%, gather 24%, herd_wildnpc 6% |
| DOKI | 0 | 0 | 0 | 4 | idle 82%, gather 9%, herd_wildnpc 6% |
| DOQA | 0 | 0 | 0 | 10 | idle 84%, gather 13%, eat 3% |
| DOZI | 0 | 0 | 1 | 8 | idle 74%, gather 14%, eat 6% |
| FIKA | 0 | 0 | 5 | 50 | gather 44%, idle 33%, wander 9% |
| GAAQ | 0 | 0 | 9 | 64 | gather 46%, idle 27%, wander 11% |
| GAUC | 0 | 0 | 0 | 12 | idle 71%, gather 9%, craft 9% |
| GURE | 0 | 0 | 4 | 11 | idle 61%, gather 17%, herd_wildnpc 8% |
| HUEN | 0 | 0 | 0 | 4 | idle 74%, gather 15%, herd_wildnpc 6% |
| JESE | 0 | 0 | 3 | 25 | idle 46%, gather 34%, wander 9% |
| KEEX | 0 | 0 | 0 | 5 | idle 86%, gather 10%, eat 3% |
| KIOK | 0 | 0 | 1 | 15 | idle 80%, gather 9%, eat 7% |
| KOIZ | 0 | 0 | 6 | 46 | idle 53%, gather 32%, eat 5% |
| LIER | 0 | 0 | 0 | 10 | idle 61%, gather 37%, eat 1% |
| LOZE | 0 | 0 | 6 | 55 | idle 44%, gather 37%, wander 10% |
| MOEY | 0 | 0 | 2 | 15 | idle 71%, gather 19%, eat 5% |
| PEUG | 0 | 0 | 1 | 15 | idle 80%, gather 11%, eat 8% |
| RAIN | 0 | 0 | 3 | 29 | idle 47%, gather 26%, herd_wildnpc 11% |
| ROED | 0 | 0 | 4 | 38 | idle 54%, gather 28%, combat 9% |
| RUSO | 0 | 0 | 4 | 23 | idle 61%, gather 20%, combat 9% |
| SOWA | 0 | 0 | 2 | 25 | idle 67%, gather 16%, eat 6% |
| SUHI | 0 | 0 | 0 | 10 | idle 76%, gather 16%, wander 4% |
| TIIP | 0 | 0 | 4 | 27 | idle 65%, gather 16%, herd_wildnpc 7% |
| TUAC | 0 | 0 | 0 | 10 | idle 74%, gather 12%, eat 9% |
| TUYE | 0 | 0 | 1 | 14 | idle 64%, gather 18%, herd_wildnpc 8% |
| VANE | 0 | 0 | 0 | 10 | idle 65%, gather 27%, wander 5% |
| VUEP | 0 | 0 | 1 | 11 | idle 57%, gather 39%, eat 3% |
| VUUG | 0 | 0 | 3 | 19 | gather 65%, wander 32%, eat 2% |
| WIUX | 0 | 0 | 0 | 10 | idle 53%, gather 35%, herd_wildnpc 10% |
| YUID | 0 | 0 | 0 | 4 | idle 80%, gather 18%, eat 2% |
| YUOB | 0 | 0 | 2 | 10 | idle 71%, gather 18%, eat 5% |
| YUZU | 0 | 0 | 1 | 6 | idle 72%, gather 17%, herd_wildnpc 5% |
| ZEMU | 0 | 0 | 4 | 38 | idle 47%, gather 37%, eat 6% |
| ZOUH | 0 | 0 | 1 | 11 | idle 66%, gather 26%, wander 5% |

#### Hunts

- start t=77.8s prey=deer quota=2
- start t=197.9s prey=deer quota=3
- start t=288.0s prey=deer quota=4
- start t=363.1s prey=deer quota=4
- start t=463.1s prey=deer quota=4
- start t=892.8s prey=deer quota=4
- hunt_aborted t=197.9s reason=active_timeout
- hunt_completed t=283.5s reason=loot_complete
- hunt_completed t=351.4s reason=loot_complete
- hunt_completed t=405.4s reason=loot_complete
- hunt_completed t=480.3s reason=loot_complete
- hunt_completed t=960.4s reason=loot_complete

#### Buildings

- t=42.9s **Living Hut** — herder_hut (builder: BERU)
- t=218.4s **Living Hut** — herder_hut (builder: BERU)
- t=398.1s **Farm** — milestone
- t=503.1s **Dairy Farm** — milestone
- t=946.7s **Oven** — milestone

### LI JUAB

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 1/2 (77% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 9 | 5 |
| Bone | 0 | 5 |
| Hide | 0 | 5 |
| Meat | 0 | 5 |
| Mushroom | 2 | 0 |
| Nuts | 19 | 5 |
| Spear | 0 | 5 |
| Stone | 10 | 9 |
| Wood | 68 | 41 |

#### Failures

- **Gather:** inventory_full=207, resource_invalid=2, not_harvestable=1

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BUNU | 0 | 0 | 1 | 18 | idle 65%, combat 20%, gather 10% |
| JUNO | 0 | 0 | 11 | 38 | agro 29%, wander 19%, gather 17% |
| NIAH | 0 | 0 | 1 | 10 | idle 75%, combat 9%, hunt 7% |
| REWE | 0 | 0 | 0 | 9 | idle 87%, gather 6%, herd_wildnpc 3% |
| WAVU | 0 | 0 | 2 | 15 | idle 64%, combat 15%, party 10% |
| ZEVA | 0 | 0 | 4 | 18 | idle 66%, combat 16%, gather 12% |

#### Hunts

- start t=181.8s prey=deer quota=2
- start t=301.9s prey=deer quota=3
- start t=422.0s prey=deer quota=4
- start t=542.1s prey=deer quota=4
- start t=662.2s prey=deer quota=4
- start t=692.3s prey=deer quota=4
- hunt_aborted t=301.8s reason=active_timeout
- hunt_aborted t=421.9s reason=active_timeout
- hunt_aborted t=542.0s reason=active_timeout
- hunt_aborted t=662.1s reason=active_timeout
- hunt_completed t=690.4s reason=loot_complete
- hunt_completed t=784.8s reason=loot_complete

#### Buildings

- t=148.0s **Living Hut** — herder_hut (builder: JUNO)
- t=862.2s **Living Hut** — herder_hut (builder: REWE)
- t=1360.4s **Living Hut** — herder_hut (builder: JUNO)

### RU VEAK

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 3/3 (92% fill)
- **Pressure:** defend 0.11 | search 0.3 | gather 0.59
- **Food days buffer:** 0.0 → 1.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 0 | 1 |
| Bone | 0 | 6 |
| Fiber | 12 | 4 |
| Grain | 5 | 0 |
| Hide | 0 | 8 |
| Meat | 0 | 10 |
| Nuts | 15 | 0 |
| Spear | 0 | 9 |
| Stone | 10 | 5 |
| Wood | 84 | 23 |

#### Failures

- **Gather:** inventory_full=321, empty_switch:not_harvestable=6, not_harvestable=3

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| DIEV | 0 | 0 | 2 | 11 | idle 90%, gather 9%, eat 1% |
| DOUZ | 0 | 0 | 6 | 14 | agro 71%, combat 10%, gather 6% |
| LEGU | 0 | 0 | 1 | 10 | idle 85%, craft 7%, gather 7% |
| POSA | 0 | 0 | 1 | 6 | idle 95%, gather 5%, eat 0% |
| PUCA | 0 | 0 | 5 | 13 | idle 71%, combat 12%, gather 9% |
| RUKO | 0 | 0 | 0 | 10 | idle 92%, gather 7%, eat 0% |
| TOOW | 0 | 0 | 2 | 20 | idle 74%, gather 13%, party 6% |
| WAIK | 0 | 0 | 1 | 10 | idle 88%, hunt 5%, gather 4% |
| XUCA | 0 | 0 | 1 | 10 | idle 82%, party 6%, combat 6% |
| ZEPE | 0 | 0 | 2 | 22 | idle 74%, gather 12%, combat 7% |

#### Hunts

- start t=75.7s prey=deer quota=2
- start t=195.8s prey=deer quota=4
- start t=250.9s prey=deer quota=4
- start t=396.0s prey=deer quota=4
- hunt_aborted t=195.8s reason=active_timeout
- hunt_completed t=247.2s reason=loot_complete
- hunt_aborted t=370.9s reason=active_timeout
- hunt_completed t=512.2s reason=loot_complete

#### Buildings

- t=38.8s **Living Hut** — herder_hut (builder: DOUZ)
- t=429.2s **Living Hut** — herder_hut (builder: DOUZ)

### XA MIUW

- **Brain:** PEACEFUL | alert NONE | hunt NONE | raid NONE | survival False
- **Quotas (end):** defenders 0/0 (— fill) | searchers 2/12 (35% fill)
- **Pressure:** defend 0.11 | search 0.28 | gather 0.61
- **Food days buffer:** 0.0 → 1.0 → 0.0

#### Economy

| Resource | Gathered | Deposited |
|----------|----------|-----------|
| Berries | 21 | 8 |
| Bone | 0 | 9 |
| Fiber | 54 | 31 |
| Grain | 69 | 37 |
| Hide | 0 | 12 |
| Meat | 0 | 15 |
| Mushroom | 4 | 1 |
| Nuts | 154 | 63 |
| Spear | 0 | 31 |
| Stone | 62 | 43 |
| Wood | 672 | 366 |

#### Failures

- **Gather:** inventory_full=502, empty_switch:not_harvestable=75, not_harvestable=30, resource_invalid=4

#### Fighter roster

| NPC | Tasks OK | Fail | Deposits | Gathered | Top states |
|-----|----------|------|----------|----------|------------|
| BEBI | 0 | 0 | 0 | 4 | idle 90%, gather 6%, eat 5% |
| BEUN | 0 | 0 | 4 | 35 | idle 52%, gather 38%, wander 6% |
| BIOP | 0 | 0 | 5 | 50 | idle 49%, gather 37%, wander 9% |
| BIUD | 0 | 0 | 0 | 16 | idle 82%, gather 12%, eat 5% |
| COUB | 0 | 0 | 0 | 5 | idle 87%, eat 7%, gather 5% |
| COWE | 0 | 0 | 0 | 4 | idle 91%, gather 6%, eat 4% |
| DAUW | 0 | 0 | 8 | 62 | idle 58%, gather 19%, wander 9% |
| DEBE | 0 | 0 | 0 | 4 | idle 86%, eat 8%, gather 7% |
| FAOC | 0 | 0 | 3 | 35 | idle 68%, gather 23%, wander 6% |
| FEBI | 0 | 0 | 1 | 11 | idle 82%, gather 15%, eat 3% |
| FOIY | 0 | 0 | 1 | 5 | idle 89%, gather 6%, eat 4% |
| GENE | 0 | 0 | 0 | 10 | idle 73%, gather 24%, eat 2% |
| GIIC | 0 | 0 | 0 | 10 | idle 75%, gather 22%, eat 2% |
| GUFI | 0 | 0 | 2 | 13 | idle 70%, gather 10%, craft 7% |
| HIEJ | 0 | 0 | 0 | 10 | idle 84%, gather 9%, eat 8% |
| JAHU | 0 | 0 | 0 | 10 | idle 85%, gather 12%, eat 3% |
| JEYO | 0 | 0 | 0 | 5 | idle 90%, gather 5%, eat 5% |
| JIIC | 0 | 0 | 4 | 32 | idle 69%, gather 13%, craft 8% |
| JOUM | 0 | 0 | 0 | 4 | idle 86%, gather 9%, eat 5% |
| KADU | 0 | 0 | 0 | 4 | idle 78%, gather 17%, eat 4% |
| KUZI | 0 | 0 | 11 | 77 | idle 41%, gather 30%, wander 12% |
| LEPI | 0 | 0 | 6 | 30 | idle 74%, gather 15%, eat 5% |
| LOBI | 0 | 0 | 3 | 30 | idle 74%, gather 21%, eat 5% |
| LONU | 0 | 0 | 41 | 147 | wander 42%, gather 35%, herd_wildnpc 8% |
| NEAH | 0 | 0 | 3 | 19 | idle 72%, herd_wildnpc 10%, gather 9% |
| NUAG | 0 | 0 | 0 | 10 | idle 83%, gather 14%, eat 3% |
| PENO | 0 | 0 | 0 | 10 | idle 77%, gather 20%, eat 3% |
| PEVI | 0 | 0 | 2 | 31 | idle 70%, gather 23%, eat 7% |
| POIT | 0 | 0 | 2 | 12 | idle 66%, gather 27%, wander 4% |
| POOB | 0 | 0 | 2 | 18 | idle 77%, gather 14%, eat 6% |
| QIJU | 0 | 0 | 0 | 4 | idle 90%, eat 5%, gather 4% |
| QIUS | 0 | 0 | 3 | 15 | idle 72%, herd_wildnpc 9%, eat 7% |
| QUZE | 0 | 0 | 3 | 20 | idle 77%, gather 9%, eat 6% |
| RALA | 0 | 0 | 1 | 21 | idle 67%, gather 24%, wander 6% |
| RAUC | 0 | 0 | 1 | 11 | idle 86%, gather 8%, eat 6% |
| ROAD | 0 | 0 | 0 | 4 | idle 80%, gather 18%, eat 2% |
| ROOL | 0 | 0 | 2 | 23 | idle 83%, gather 13%, eat 4% |
| SAAC | 0 | 0 | 0 | 10 | idle 78%, gather 16%, eat 3% |
| SAAW | 0 | 0 | 1 | 14 | idle 77%, gather 14%, eat 6% |
| SAXI | 0 | 0 | 1 | 2 | flee_combat 95%, gather 2%, herd_wildnpc 1% |
| SETE | 0 | 0 | 1 | 12 | idle 81%, gather 9%, eat 7% |
| SINA | 0 | 0 | 1 | 7 | idle 86%, eat 7%, gather 4% |
| VAUM | 0 | 0 | 5 | 40 | idle 73%, gather 21%, eat 5% |
| VORI | 0 | 0 | 0 | 10 | idle 73%, gather 25%, eat 2% |
| VOZE | 0 | 0 | 0 | 5 | idle 87%, eat 7%, herd_wildnpc 3% |
| WESU | 0 | 0 | 1 | 11 | idle 82%, gather 16%, eat 3% |
| WOFA | 0 | 0 | 4 | 29 | idle 71%, gather 13%, eat 7% |
| YEDE | 0 | 0 | 0 | 10 | idle 80%, gather 18%, eat 2% |
| YICI | 0 | 0 | 0 | 4 | idle 90%, gather 7%, eat 4% |
| YIQE | 0 | 0 | 0 | 8 | idle 70%, gather 28%, eat 2% |
| YUTA | 0 | 0 | 1 | 16 | idle 77%, gather 12%, eat 8% |
| ZAKA | 0 | 0 | 0 | 11 | idle 80%, gather 17%, eat 3% |
| ZIDU | 0 | 0 | 0 | 10 | idle 81%, gather 16%, eat 4% |
| ZIEL | 0 | 0 | 2 | 16 | idle 80%, gather 8%, eat 6% |
| ZUEQ | 0 | 0 | 1 | 10 | idle 82%, eat 8%, gather 7% |

#### Hunts

- start t=67.2s prey=deer quota=2
- start t=127.3s prey=deer quota=3
- start t=197.3s prey=deer quota=4
- hunt_completed t=123.7s reason=loot_complete
- hunt_completed t=151.1s reason=loot_complete
- hunt_completed t=258.2s reason=loot_complete

#### Buildings

- t=31.1s **Living Hut** — herder_hut (builder: LONU)
- t=207.3s **Farm** — milestone
- t=327.4s **Dairy Farm** — milestone
- t=652.7s **Oven** — milestone

