# THE FRONTIER — Game Design

See the full design in the root [Readme.md](../Readme.md) (Technical Roadmap v0.2).

This file will hold detailed game design notes as they evolve beyond the roadmap:

- Enemy roster & stats
- Node/map layouts for Blackwood
- Economy tuning (gold, potions, equipment prices)
- Event & treasure tables

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
| ✅ V2 (2026-10-20) | **Town ground** | `RavenfallVillage` (`scripts/world/ravenfall_village.gd`) builds the town from a data layout: 6 rings of hex grass plus a road from the square straight up toward Blackwood (the whole town is turned 15° to line up with the camera), and an invisible wall at radius 16 | Screenshot: a hex island with a road; the player can't walk off the edge |
| ✅ V3 (2026-10-20) | **Town buildings** | Red-roof buildings around the square, following README §9: Tavern (Rest), Market (Potion Shop), Blacksmith, a well, Old Chapel, Abandoned House, 3 homes, a windmill. Each one faces the square and has a cylinder collider | Screenshot: each shop has a matching building |
| ✅ V4 (2026-10-20) | **Nature & props** | Rings by distance: scattered single trees and rocks on the walkable edge (with colliders) → forest → hills → mountains (fixed seed so the layout is the same every visit). The road leaves a gap through the forest as the Blackwood entrance. Barrels, crates, sacks, flags and a weapon rack are placed by hand (props ×6 to match the hero). The 3 grey crates are gone | Screenshot: the town feels "cosy" and the edges are hidden |
| ✅ V5 (2026-10-20) | **Light & mood** | Warm sun with soft shadows, a sky with a warm horizon, ACES tonemap, light fog, faint glow, stronger SSAO. Ground tiles are tinted greener (`GRASS_TINT`), and road tiles get a milder tint so the path keeps its sandy colour (the pack's grass turns yellow under warm light) | Before/after screenshots compared side by side |
| ✅ V5b (2026-10-20) | **Ravenfall big town (from reference)** | Rebuilt the town to match the reference image: hex wall ring 6 (corners + gate + 5 blue-cone towers), paved plaza with a well in the middle and market stalls, paved main street from the gate up to the manor (castle), blue-roof buildings ×1.5 (cathedral, tavern, blacksmith, market, mage tower, barracks, 20 homes), a garden pond, a river and road bridge outside the gate, wheat fields and a windmill top-right, then forest and hills out to ring 10. Low golden-hour sun with long shadows; camera size 18 | Overview and gameplay screenshots look close to the reference |
| ⬜ V6 | **UI theme** | One project-wide Godot Theme: rounded font (Fredoka, OFL), parchment-coloured panels, wood/gold buttons. This changes every screen at once without touching layouts | Screenshots of Ravenfall, Blackwood and Combat with the theme |
| ⬜ V7 | **Walk-up interaction** *(optional)* | Walking to a building opens its shop. The bottom buttons stay as a shortcut | Walk to the blacksmith and the shop opens |
| ⬜ V8 | **Blackwood map look** | Pick the enemy model source, then turn the enemy list into a forest map with nodes (ties into Phase 3 maps) | Screenshot of the Blackwood map |
| ⬜ V9 | **Combat stage** | A small 3D stage: the Knight faces the enemy, with attack, Hit and Death animations synced to the battle log | One fight plays out with animation |
| ⬜ V10 | **VFX** | Hit spark, heal glow, level-up burst, chest sparkle | Each effect appears at the right moment |

### Working rules

- Do one step at a time, and only move on after reviewing the screenshot.
- Every step must keep `tests/loop_test.tscn` passing.
- When a step is done, tick ✅ in this table and add the date.
- Any step can be tweaked or reordered after review.
