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

## Phase 2 — Progression ⬅ NEXT

EXP, Level Up, stat growth, shop/blacksmith, equipment, gold economy
