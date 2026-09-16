# THE FRONTIER — Roadmap Progress

Full roadmap: [Readme.md](../Readme.md)

## Phase 0 — Project Setup ✅ (2026-09-16)

- [x] Install Godot 4.x (4.7.2 stable, /Applications/Godot.app)
- [x] Create Godot project (`project.godot`)
- [x] Git repository (GitHub: AdventurePathQuest)
- [x] Folder structure per roadmap
- [x] Resolution 1920×1080, canvas_items stretch
- [x] Input map (WASD + arrows)
- [x] Main Scene (`scenes/main.tscn`)
- [x] GameManager autoload
- [x] PlayerData (Lv1 / Power 100 / HP 100 / Speed 50 / Gold 10)
- [x] 3D test world (floor + props + lighting + shadows)
- [x] Orthographic isometric camera (pitch −30°, yaw 45°)
- [x] Camera follow + player test movement

## Phase 1 — Core Gameplay Prototype ✅ Sprint 01 (2026-09-16)

Ravenfall → Blackwood → Enemy Selection → Auto Combat → Reward → Ravenfall

- [x] EnemyData resource (`scripts/enemies/enemy_data.gd`)
- [x] 3 enemies as `.tres` data: Forest Wolf, Wild Boar, Alpha Wolf (`data/enemies/`)
- [x] Auto combat per README rules — speed order, immediate death, no counterattack (`scripts/combat/combat_manager.gd`)
- [x] Damage formula: Power × 10% per hit (min 1) — tune `DAMAGE_FACTOR`
- [x] Reward: +50% enemy Power, +gold
- [x] Defeat rule (prototype): escape with 1 HP
- [x] Ravenfall UI overlay on 3D world — stats, Rest (full heal), Enter Blackwood
- [x] Blackwood enemy-selection scene
- [x] Combat scene with HP bars + battle log
- [x] Headless test `tests/loop_test.tscn` — full battle vs Wolf verifies Power/Gold/HP

## Phase 2 — Progression ✅ (2026-09-16) — Prototype 0.2

- [x] EXP + Level Up: enemies grant EXP (Wolf 40 / Boar 60 / Alpha 150), need = level × 100
- [x] Level-up growth: +20 Max HP, +10 Power, +2 Speed, full heal
- [x] ItemData resource; items as `.tres` (`data/items/`, `data/equipment/`)
- [x] Potion Shop: Small Potion +30 HP, 5 gold
- [x] Blacksmith: Rusty Sword ATK+10 (10g), Reinforced Sword ATK+25 (20g) — weapons own-once
- [x] Inventory + Bag UI (use potions, equip weapons); combat uses Power + weapon ATK
- [x] ShopManager autoload; quick potion use on the Blackwood map screen
- [x] Tests extended: buy/use/equip/level-up all verified headless

## Phase 3 — Data-Driven Content ⬅ NEXT

Maps as data files, Blackwood expanded to 10–15 nodes with branching routes,
more enemies/items, events
