# THE FRONTIER — Technical Design

## Current Architecture (Phase 0)

| Piece | File | Notes |
| --- | --- | --- |
| Autoload singleton | `scripts/systems/game_manager.gd` | Registered as `GameManager` in project.godot; owns `PlayerData` |
| Player state | `scripts/player/player_data.gd` | `Resource` with level/power/hp/max_hp/speed/gold/inventory/equipment |
| Player controller | `scripts/player/player.gd` | `CharacterBody3D`, camera-relative WASD/arrow movement |
| Camera | `scripts/world/camera_rig.gd` | Fixed isometric angle (pitch −30°, yaw 45°), lerp-follows player |
| Main scene | `scenes/main.tscn` | Orthographic camera (size 14), sun w/ shadows, 40×40 test floor, props |

## Conventions

- GDScript, tabs, `class_name` for shared types
- Data-driven content goes in `data/` (JSON or `.tres`) starting Phase 3
- One manager per system under `scripts/systems/`
