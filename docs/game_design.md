# THE FRONTIER — Game Design

See the full design in the root [Readme.md](../Readme.md) (Technical Roadmap v0.2).

This file will hold detailed game design notes as they evolve beyond the roadmap:

- Enemy roster & stats
- Node/map layouts for Blackwood
- Economy tuning (gold, potions, equipment prices)
- Event & treasure tables

---

## Direction change (2026-10-20): open world + real-time action combat

**Decision (user, 2026-10-20):** drop turn-based auto combat and node-based map
selection. THE FRONTIER becomes an **open world** where the hero walks out of
Ravenfall into the wild and **fights monsters in real time, right where they
stand** — no separate combat screen, no clicking an enemy card.

### What changes

| Area | Before (Prototype 0.2) | New direction |
|---|---|---|
| World | Town → world map → pick a region → node map | One continuous open world: Ravenfall's gate opens onto the wilderness; Blackwood is a region you walk into |
| Picking a fight | Click an enemy node / card | Walk up to a monster; it notices you and attacks |
| Combat | Automatic, turn order by Speed, battle log | Real-time action: you move, attack and dodge yourself |
| Combat screen | Separate scene (`scenes/combat/combat.tscn`) | Removed — fights happen in the world |
| Map progression | `MapManager` nodes + unlock rules | Regions and spawn zones; the boss lair opens when its condition is met |

### Real-time combat rules (first version)

- **Controls:** WASD move (existing), Shift sprint (existing), **left click / J = attack** (swing toward the mouse / facing), **Space = dodge roll** (short invulnerable dash, cooldown), **1 = drink potion**.
- **Stats carry over** from `PlayerData` / `EnemyData` so balance work isn't lost:
  - Damage per hit = attacker Power × 10% (same `DAMAGE_FACTOR`), weapon ATK still adds to the hero's Power.
  - Speed sets attack rate and move speed (higher Speed → shorter swing cooldown).
  - HP unchanged; level-up growth unchanged.
- **Monster AI:** idle / wander in its spawn zone → **aggro** when the hero comes within range → chase → wind-up (telegraphed) → attack → returns home if the hero runs too far (**leash**).
- **Feedback:** HP bar over each monster, hero HP in the HUD, hit sparks + damage numbers + hit-flash (existing `Vfx`), knock-back on hit.
- **Rewards:** on kill, gold + EXP as before (`GameManager.apply_victory_rewards`), Power reward kept, guild quest kills still count (`QuestManager.record_kill`). Gold/EXP pop as floating text; loot drops can come later.
- **Death:** hero at 0 HP faints and wakes in Ravenfall with 1 HP (same spirit as the old "escape with 1 HP" rule).
- **Respawn:** common monsters respawn in their zone after a delay; the boss doesn't.
- **Treasure:** chests sit in the world; walk up and press F (same interaction as NPCs).

### Open world layout (first version)

- Ravenfall (walled town, existing) → south gate → **road into the wilds** → **Blackwood** (pines, clearing, wolves + boars) → **Alpha Wolf's lair** deeper in (opens after the wolves and boars are thinned out — exact rule TBD).
- Same isometric camera that follows the hero; the minimap grows to show the region around the hero.
- Region edges and locked future areas (Crystal Caves, Ancient Ruins, Saltmere Harbor) are blocked by terrain or gates for now.

### Phased plan

| # | Step | Done when |
|---|---|---|
| ⬜ OW1 | **Seamless world:** extend the ground beyond the gate, road into a Blackwood region built in the same scene (reuse the 3D forest from V8) | Walk from the fountain to Blackwood without a loading screen |
| ⬜ OW2 | **Hero combat:** attack (click / J) with swing animation + hitbox, dodge roll, hero HP in HUD, potion hotkey | Hero can swing and dodge anywhere |
| ⬜ OW3 | **Monster AI:** wander, aggro, chase, telegraphed attack, leash, HP bars, hit reactions, death | A wolf notices you, attacks, and can be killed |
| ⬜ OW4 | **Rewards & death:** gold / EXP / Power / quest progress on kill, level-up burst, faint → wake in town, respawn timers | A full hunt loop works with the guild quests |
| ⬜ OW5 | **Boss & treasure:** Alpha Wolf lair with its unlock rule, boss attack pattern, world chests opened with F | Boss fight works; chests give their rewards once |
| ⬜ OW6 | **Clean-up:** remove the combat scene, node map logic and world-map travel that no longer apply; update tests to the new loop | Old turn-based code is gone; tests cover the real-time loop |

### Open questions

- Keep the painted world map as a **fast-travel / overview** screen (e.g. on M), or remove it?
- Hero attack style per class (Knight melee arc, Mage projectile…) or one melee attack for all for now?
- Boss lair unlock rule: "kill N wolves and N boars" or a guild quest?

---

## Ravenfall city spec

> 🗑️ **2026-10-20:** the first prompt-based town was removed at the user's request, and Ravenfall was then rebuilt step by step from the user's instructions (fountain plaza, Guild palace, church, blacksmith, terraced houses, tavern, general store, magic shop, park, town wall, roads, trees). The table below is kept only as a reference to the original prompt; the current town lives in `scenes/main.tscn` + `scripts/world/*`.

Broken down from the art prompt ([`reference/ravenfall_prompt.md`](reference/ravenfall_prompt.md)).
Built by `scripts/world/ravenfall_village.gd` (layout) + `scripts/world/town_decor.gd` (procedural decor).

| Prompt requirement | In game |
|---|---|
| Ancient stone walls, main entrance gate | Hex wall ring 6 with blue-cone towers at the corners and 2 big towers flanking the gate |
| Rolling green hills, dense forests | Terrain flat inside the walls, rising into hills ~11 units high beyond radius 46; forest grows in noise patches with open meadows |
| Winding road into the wilderness | Catmull-Rom dirt road from the gate, over the river bridge, curving up into the hills |
| Large central stone plaza + ancient fountain | Paved round plaza r=7.5; procedural 2-tier stone fountain with water spray |
| Grand town hall | Castle at the north end of the main street (civic district) |
| Blacksmith with glowing forge | North-west crafts district; flickering orange light + embers |
| Cozy tavern | West district, lanterns + barrels out front (Rest) |
| General goods shop / potion shop | Market building (general goods) and mage tower (potion shop) on the plaza edge |
| Small marketplace, colourful stalls | 6 tinted tents (red/blue/yellow/green/pink/orange) around the fountain with goods |
| Church with tall bell tower | North-east church district, fenced flower garden |
| Timber-frame cottages | East + west residential districts |
| Flower gardens | 11 procedural flower beds (MultiMesh blooms on soil) |
| Stone pathways, interconnected streets | Paved main street + stone paths from the plaza to every district |
| Wooden fences | Church garden, west cottages, around the wheat fields |
| Warm lanterns | 15 wooden lantern posts with real warm lights along the street, plaza, tavern |
| Subtle magical atmosphere | Faint golden motes drifting over the town |
| Soft AO, warm natural light | SSAO + low golden sun (see V5) |

**Not possible with current packs (later):** tavern balconies, detailed stone/wood textures, waterfall.

---

## Visual Design Roadmap

The game is moving from grey boxes to the "Cute Fantasy" look in README §2,
**one small step at a time**. Each step is one small change: run the game,
take a screenshot, review it, then decide on the next step. We never change
everything at once.

### Decisions so far

| Topic | Decision |
|---|---|
| Asset source | CC0 low-poly packs by KayKit (Kay Lousberg). Free for commercial use; credit is optional but nice to include |
| Hero / NPC pack | [KayKit Adventurers 1.0](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0): Knight, Mage, Rogue, Barbarian, with ~75 animations (Idle, Running_A, attacks, Hit, Death, Cheer) |
| Town / nature pack | [KayKit Medieval Hexagon 1.0](https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0): hex tiles, buildings (tavern, market, blacksmith, homes, well, windmill), trees, rocks, props. All models share one 16 KB texture atlas |
| Format | glTF (`.gltf` + `.bin`, or `.glb`) |
| Scale rule | Hex pack ×2.5 (one tile = 5 units across; tavern ≈ 3.5 tall). Characters ×0.7 (≈ 1.7 tall, matches the current player capsule) |
| Import rule | Copy only the models we use into `assets/`. Never the whole pack (the full packs are ~240 MB) |
| Ravenfall reference | [`docs/reference/ravenfall_golden_town.png`](reference/ravenfall_golden_town.png): a walled town in golden-hour light (supplied by the user) |
| Not in packs yet | Wolves / boar (Blackwood enemies). Choose the source in V8 (candidate: Quaternius animal packs, also CC0) |

### Steps

Each step has a **goal**, a **change**, and a **done check**. ⬜ = not started, ✅ = done.

| # | Step | Change | Done check |
|---|---|---|---|
| ✅ V1 (2026-10-20) | **Hero model + character select** | New first screen `scenes/ui/character_select.tscn`: pick Knight / Mage / Rogue / Barbarian from KayKit Adventurers (looks only, stats are the same). The orange capsule is replaced by the chosen hero (`CharacterModel`), which plays Idle / Running_A. Unused gear is hidden. *Note: we tried Knights from Quaternius / Vaporworks; none suited, so we stay with KayKit until a reference image or a model the user picks turns up* | Screenshot: the chosen hero walks around Ravenfall with WASD and looks the right size |
| 🗑️ V2 (removed 2026-10-20) | **Town ground** | `RavenfallVillage` (`scripts/world/ravenfall_village.gd`) builds the town from a data layout: 6 rings of hex grass plus a road from the square straight up toward Blackwood (the whole town is turned 15° to line up with the camera), and an invisible wall at radius 16 | Screenshot: a hex island with a road; the player can't walk off the edge |
| 🗑️ V3 (removed 2026-10-20) | **Town buildings** | Red-roof buildings around the square, following README §9: Tavern (Rest), Market (Potion Shop), Blacksmith, a well, Old Chapel, Abandoned House, 3 homes, a windmill. Each one faces the square and has a cylinder collider | Screenshot: each shop has a matching building |
| 🗑️ V4 (removed 2026-10-20) | **Nature & props** | Rings by distance: scattered single trees and rocks on the walkable edge (with colliders) → forest → hills → mountains (fixed seed so the layout is the same every visit). The road leaves a gap through the forest as the Blackwood entrance. Barrels, crates, sacks, flags and a weapon rack are placed by hand (props ×6 to match the hero). The 3 grey crates are gone | Screenshot: the town feels "cosy" and the edges are hidden |
| ✅ V5 (2026-10-20) | **Light & mood** | Warm sun with soft shadows, a sky with a warm horizon, ACES tonemap, light fog, faint glow, stronger SSAO. Ground tiles are tinted greener (`GRASS_TINT`), and road tiles get a milder tint so the path keeps its sandy colour (the pack's grass turns yellow under warm light) | Before/after screenshots compared side by side |
| 🗑️ V5b (removed 2026-10-20) | **Ravenfall big town (from reference)** | Rebuilt the town to match the reference image: hex wall ring 6 (corners + gate + 5 blue-cone towers), paved plaza with a well in the middle and market stalls, paved main street from the gate up to the manor (castle), blue-roof buildings ×1.5 (cathedral, tavern, blacksmith, market, mage tower, barracks, 20 homes), a garden pond, a river and road bridge outside the gate, wheat fields and a windmill top-right, then forest and hills out to ring 10. Low golden-hour sun with long shadows; camera size 18 | Overview and gameplay screenshots look close to the reference |
| 🗑️ V5c (removed 2026-10-20) | **Smooth ground (no hex tiles)** | Per user feedback: dropped the hex ground tiles. The ground is now one large terrain with two-tone noise. The plaza is a round stone disc, the main street a paved strip, the outer road a dirt strip; the river is a water strip with sandy banks and a real bridge model; the pond is an oval; the fields are rectangles. Hills with hex bases were replaced by forest. Hex coords are still used as the placement grid | No hex shapes visible on the ground |
| 🗑️ V5d (removed 2026-10-20) | **Ravenfall city spec from the art prompt** | Rebuilt the town from the prompt breakdown (table above): districts, fountain, colourful stalls, lanterns, flower beds, fences, forge glow, magic motes, stone paths, winding road, rolling hills | Every prompt item maps to something visible in the game |
| ✅ V6 (2026-10-20) | **UI theme** | User picked "Dark glass, gold rim" with the default font (compared 4 styles × 4 fonts on a live preview). One project-wide Theme, `themes/frontier_theme.tres`, built by `scripts/tools/build_theme.gd` and set as `gui/theme/custom`: translucent dark-brown panels with a gold border and shadow, dark buttons with gold rims (gold fill when toggled on, faded when disabled), cream text with a thin outline, gold separators, red HP bars. Combat background warmed to match | Town, Blackwood, combat and character select all use the same look |
| ✅ V7 (2026-10-20) | **Walk-up interaction** | Four NPCs round the fountain; within 3 m a "[F] Name — Role" prompt appears and F opens their shop or the guild quest board (`scripts/ui/npc_interaction.gd`) | Walk up to Borin, press F, the weapon shop opens |
| ✅ V8 (2026-10-20) | **World map + Blackwood map** | Walking out of the town gate opens a painted world map (`scenes/world/world_map.tscn`): Ravenfall, Blackwood, and three locked future regions; click to travel (the pin walks the road). Blackwood is now a 3D forest clearing (`scripts/world/blackwood_map.gd`) with the real monsters (procedural `CreatureModel`: wolf, boar, Alpha Wolf) and a treasure chest on stone-ringed spots along dirt trails. Hover for a card, click to fight (confirm panel) or open the chest; the boss waits in mist behind a lock until wolf + boar are beaten. Same MapManager logic as before | Click the wolf on the map, confirm, and the fight starts |
| ✅ V9 (2026-10-20) | **Combat stage** | A 3D clearing in the combat screen (`scripts/combat/combat_stage.gd`): hero and monster face off; attack (chop + lunge), hit, death and victory-cheer animations play in step with the battle log | One fight plays out with animation |
| ✅ V10 (2026-10-20) | **VFX** | `scripts/vfx/vfx.gd`: hit sparks + floating damage numbers in combat, golden level-up burst (combat and quest rewards), green heal glow (potions, rest), coin burst + sparkle when opening the chest | Each effect appears at the right moment |

### Working rules

- Do one step at a time, and only move on after reviewing the screenshot.
- Every step must keep `tests/loop_test.tscn` passing.
- When a step is done, tick ✅ in this table and add the date.
- Any step can be tweaked or reordered after review.
