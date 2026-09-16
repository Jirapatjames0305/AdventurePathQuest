# ⚔️ THE FRONTIER

## Technical Roadmap v0.2

> Cute Fantasy Isometric 2.5D RPG

---

# 1. Project Overview

**Genre:** Cute Fantasy RPG
**Platform:** PC First
**Mode:** Offline Prototype
**Perspective:** Isometric 2.5D
**Camera:** Orthographic Camera
**Engine:** Godot 4.x
**Language:** GDScript
**Core Gameplay:** Node-based Exploration + Automatic Combat

### Core Loop

```text
🏰 Ravenfall
     ↓
🌲 Explore
     ↓
🗺️ Select Node
     ↓
⚔️ Automatic Combat / Event
     ↓
💰 Reward
     ↓
🏰 Return to Ravenfall
     ↓
🛠️ Rest / Shop / Upgrade
     ↓
🌲 Explore Again
```

---

# 2. Visual Direction

## Art Style

**Cute Fantasy RPG**

* Cute stylized characters
* Slightly oversized heads
* Large expressive eyes
* Small body proportions
* Medieval fantasy clothing
* Magical weapons
* Fantasy creatures
* Enchanted forests
* Glowing mushrooms
* Magical crystals
* Ancient ruins
* Runes
* Soft magical particles
* Charming but adventurous atmosphere

### Avoid

* Pixel Art
* Photorealism
* Modern objects
* Sci-Fi
* Horror
* Grimdark
* Excessively realistic medieval design

---

# 3. Camera & World

## Isometric 2.5D

The game uses a 3D world presented through an isometric-style camera.

```text
        🌲       🌲
           🏠
      🌲       🧙
           🛤️
       💰      🐺

          ↙
       Camera
```

### Camera

* Godot 4.x 3D Camera
* Orthographic Projection
* Fixed Isometric Angle
* Camera follows player when appropriate
* No camera rotation in the initial prototype
* No free camera
* No open-world streaming

### Why 3D + Orthographic?

Using Godot 3D allows:

* Better lighting
* Real-time shadows
* Depth
* Ambient occlusion
* Easier environment composition
* Better VFX
* Easier camera control
* More natural height/depth
* Easier reuse of 3D assets

The orthographic camera provides the desired isometric visual style.

---

# 4. Technology Stack

| Category        | Technology               | Purpose                          |
| --------------- | ------------------------ | -------------------------------- |
| Game Engine     | Godot 4.x                | Game Runtime                     |
| World           | Godot 3D                 | Isometric Environment            |
| Camera          | Orthographic Camera      | Isometric View                   |
| Language        | GDScript                 | Game Logic                       |
| Version Control | Git + GitHub             | Source Control                   |
| IDE             | VS Code / Cursor         | Development                      |
| Data            | JSON / Godot Resources   | Game Data                        |
| Save System     | JSON / Godot Resources   | Save / Load                      |
| Planning        | Markdown                 | Documentation                    |
| Game Design AI  | Claude                   | Ideas / Design / Content         |
| Coding AI       | ChatGPT / Claude         | Code / Debug / Architecture      |
| Image AI        | Image Generation AI      | Character / Environment Concepts |
| Animation       | Godot + AI Tools         | Character Animation              |
| Music           | Suno / AI Audio          | Music                            |
| SFX             | AI Audio / Generated SFX | Sound Effects                    |

---

# 5. Development Architecture

```text
THE FRONTIER
│
├── GameManager
│
├── Player
│   ├── PlayerData
│   ├── Stats
│   ├── Inventory
│   └── Equipment
│
├── World
│   ├── Village
│   ├── Forest
│   ├── Dungeon
│   └── Boss Areas
│
├── MapManager
│   ├── Nodes
│   ├── Routes
│   ├── Unlocks
│   └── Events
│
├── CombatManager
│   ├── Turn Order
│   ├── Speed
│   ├── Damage
│   ├── HP
│   ├── Win
│   └── Lose
│
├── InventoryManager
│
├── EquipmentManager
│
├── ShopManager
│
├── SaveManager
│
└── UIManager
```

---

# 6. Folder Architecture

```text
THE_FRONTIER/
│
├── project.godot
│
├── scenes/
│   ├── world/
│   │   ├── village/
│   │   ├── forest/
│   │   ├── dungeon/
│   │   └── boss/
│   │
│   ├── characters/
│   ├── enemies/
│   ├── combat/
│   └── ui/
│
├── scripts/
│   ├── player/
│   ├── combat/
│   ├── enemies/
│   ├── inventory/
│   ├── equipment/
│   ├── map/
│   ├── world/
│   ├── ui/
│   └── systems/
│
├── data/
│   ├── enemies/
│   ├── items/
│   ├── equipment/
│   ├── maps/
│   └── characters/
│
├── assets/
│   ├── characters/
│   ├── enemies/
│   ├── environments/
│   ├── buildings/
│   ├── props/
│   ├── ui/
│   ├── icons/
│   ├── vfx/
│   └── materials/
│
├── audio/
│   ├── music/
│   ├── sfx/
│   └── ambience/
│
└── docs/
    ├── game_design.md
    ├── technical_design.md
    └── roadmap.md
```

---

# 7. PHASE 0 — Project Setup

## Goal

Create the basic Godot project and Isometric 3D environment.

### Tasks

* Install Godot 4.x
* Create THE FRONTIER project
* Initialize Git
* Create GitHub repository
* Create folder structure
* Configure project resolution
* Configure input system
* Create Main Scene
* Create GameManager
* Create basic PlayerData
* Create 3D World
* Create Orthographic Camera
* Configure Isometric Camera angle
* Create test floor
* Create basic lighting
* Test camera movement

### Output

```text
Godot Project
      +
Git Repository
      +
Basic Isometric World
      +
Camera
```

---

# 8. PHASE 1 — Core Gameplay Prototype

## Goal

Build the complete playable gameplay loop.

```text
Ravenfall
   ↓
Blackwood
   ↓
Enemy Selection
   ↓
Automatic Combat
   ↓
Reward
   ↓
Ravenfall
```

---

## Player System

Player data:

* Level
* Power
* HP
* Max HP
* Speed
* Gold
* Inventory
* Equipment

Initial values:

```text
Level: 1
Power: 100
HP: 100
Max HP: 100
Speed: 50
Gold: 10
```

---

# 9. World System

## Ravenfall

Initial locations:

* Town Square
* Blacksmith
* Potion Shop
* Old Chapel
* Abandoned House
* Forest Entrance

Functions:

* Rest
* Shop
* Upgrade
* Inventory
* Equipment
* Enter Forest

---

# 10. Map System

Use a Node-based progression system.

```text
             🌲
              │
        ┌─────┼─────┐
        ↓     ↓     ↓
       🐺    🐗    💰
        │     │
        └──┬──┘
           ↓
          👑
```

Node types:

* Enemy
* Treasure
* Event
* Rest
* Shop
* Mini Boss
* Boss
* Story

Each node can contain:

```text
Node
├── Type
├── Enemy
├── Reward
├── Requirement
├── Next Nodes
└── Completed State
```

---

# 11. Combat System

## Automatic Combat

Once the player chooses an enemy, combat runs automatically.

### Combat Rules

1. Compare Speed
2. Higher Speed attacks first
3. Apply damage
4. Immediately check HP
5. If HP reaches 0 → character loses
6. Dead character cannot counterattack
7. Continue until one side reaches 0 HP

### Example

```text
Player Speed = 50
Enemy Speed = 35

Player attacks first
↓
Enemy HP decreases
↓
Enemy HP = 0
↓
Enemy dies
↓
Enemy does NOT counterattack
```

---

# 12. Combat Stats

Initial player:

```text
Power: 100
HP: 100
Speed: 50
```

Equipment modifies combat stats.

Example:

```text
Rusty Sword
ATK +10

Reinforced Sword
ATK +25
```

---

# 13. Reward System

Enemy rewards can include:

* Power
* Gold
* Items
* Equipment
* Potions

Current default Power reward:

```text
Enemy Power × 50%
```

Example:

```text
Enemy Power = 300

Reward = +150 Power
```

---

# 14. Potion System

Example:

```text
Small Potion
Heal: +30 HP
```

Rules:

* Can be used before combat
* Can be used during appropriate combat states if later enabled
* Quantity tracked in Inventory
* Gold required to purchase
* Save/load supported

---

# 15. Treasure System

Treasure can contain:

* Gold
* Power
* Potion
* Equipment
* Rare Item

Example:

```text
Chest
├── +50 Gold
├── +80 Power
└── Potion ×1
```

Chest state must be saved.

---

# 16. Equipment System

Initial equipment:

```text
Rusty Sword
ATK +10
Cost: 10 Gold
```

Upgrade:

```text
Reinforced Sword
ATK +25
Cost: 20 Gold
```

Future:

* Weapons
* Armor
* Accessories
* Equipment rarity
* Equipment sets
* Magical equipment

---

# 17. PHASE 2 — Progression

Add:

* EXP
* Level Up
* Stat Growth
* HP Growth
* Power Growth
* Speed Growth
* Equipment Slots
* Inventory
* Item Rarity
* Blacksmith
* Equipment Upgrade
* Gold Economy

### Milestone

**Prototype 0.2**

---

# 18. PHASE 3 — Data-Driven Content

The game should allow new content without rewriting core systems.

## EnemyData

```text
Name
Power
HP
Speed
Reward
Sprite / Model
DropTable
```

## ItemData

```text
Name
Type
Value
Effect
Icon
Rarity
```

## MapNode

```text
Type
Enemy
Reward
NextNodes
Requirement
```

### Target Content

* 20+ Enemies
* 20+ Items
* 10+ Equipment
* 5+ Maps
* 5+ Bosses
* Treasure Events
* Random Events

### Milestone

**Prototype 0.3**

---

# 19. PHASE 4 — Visual Production

## Characters

* Main Character
* NPCs
* Enemies
* Bosses
* Character animations
* Attack animations
* Hit animations
* Death animations

## Environments

* Ravenfall
* Blackwood
* Cave
* Ruins
* Fantasy Village
* Boss Area
* Magical Forest

## Props

* Houses
* Trees
* Rocks
* Barrels
* Fences
* Signs
* Lanterns
* Crystals
* Mushrooms
* Statues
* Chests

## UI

* HUD
* Inventory
* Equipment
* Combat
* Map
* Shop
* Dialogue
* Settings

## VFX

* Hit
* Critical
* Heal
* Level Up
* Magic
* Chest
* Death
* Environmental particles

### Milestone

**Prototype 0.4 — Visual Vertical Slice**

---

# 20. PHASE 5 — Audio

## Music

* Village
* Forest
* Dungeon
* Boss
* Victory
* Defeat

## SFX

* Sword
* Hit
* Critical
* Monster
* Chest
* Button
* Potion
* Level Up
* Magic

## Ambient

* Forest
* Village
* Wind
* Birds
* Magic ambience

### Milestone

**Prototype 0.5**

---

# 21. PHASE 6 — Save / Load

Save:

* Player Level
* Power
* HP
* Gold
* Inventory
* Equipment
* Map Progress
* Completed Nodes
* Chest State
* Boss State

Features:

* Auto Save
* Manual Save
* Load Game

### Milestone

**Prototype 0.6**

---

# 22. PHASE 7 — UX / Polish

Add:

* Scene transitions
* Animations
* Button feedback
* Loading
* Error handling
* Tutorial
* First-time guidance
* Combat speed control
* Skip Animation
* Confirmations
* Settings
* Volume
* Resolution

### Milestone

**Prototype 0.7**

---

# 23. PHASE 8 — Balance

Balance through actual playtesting.

Areas:

* Early Game
* Mid Game
* Boss
* Economy
* Equipment
* Enemy Difficulty
* Reward Progression
* Potion Economy
* Speed Balance

Do not balance only from theoretical calculations.

---

# 24. PHASE 9 — Vertical Slice

Create one complete polished section:

```text
Ravenfall
    ↓
Blackwood
    ↓
10–15 Nodes
    ↓
Enemies
    ↓
Treasure
    ↓
Mini Boss
    ↓
Boss
```

Should include:

* Final-ish Characters
* Environment
* Isometric Camera
* UI
* Combat
* Animation
* VFX
* Sound
* Save
* Progression

### Milestone

# THE FRONTIER — Vertical Slice

---

# 25. PHASE 10 — Full Game

Only begin after the Vertical Slice works.

Possible future content:

* Multiple Regions
* Multiple Villages
* More Enemies
* More Bosses
* Equipment Sets
* Skills
* Quests
* NPCs
* Story
* Events
* Dungeons
* Rare Items
* Secret Areas

---

# 26. Future MMORPG Architecture

Do NOT build online multiplayer during the prototype.

Future architecture:

```text
            Internet
               │
        ┌──────┴──────┐
        │             │
     Client        Server
      Godot        Backend
        │             │
        └──────┬──────┘
               │
           Database
```

Would eventually require:

* Authentication
* Game Server
* Database
* Network Synchronization
* Persistent Character Data
* Server Authority
* Anti-Cheat
* Security
* Match / Session Management

---

# 27. Technical Priority

```text
1. Gameplay
2. Data Architecture
3. Progression
4. UI / UX
5. Content
6. Isometric World
7. Art
8. Animation
9. VFX
10. Audio
11. Polish
12. Online
```

---

# 28. Definition of Done

## Combat

* [ ] Select enemy
* [ ] Speed determines attack order
* [ ] Damage works
* [ ] HP works
* [ ] HP = 0 means loss
* [ ] Dead unit cannot attack
* [ ] Win condition works
* [ ] Lose condition works
* [ ] Rewards work
* [ ] UI updates correctly

## Inventory

* [ ] Add item
* [ ] Remove item
* [ ] Use item
* [ ] Quantity correct
* [ ] Save / Load

## Equipment

* [ ] Equip
* [ ] Unequip
* [ ] Stats change
* [ ] Save / Load

## Map

* [ ] Select node
* [ ] Unlock node
* [ ] Travel
* [ ] Event
* [ ] Reward
* [ ] Return
* [ ] Save progress

## Isometric World

* [ ] Orthographic camera
* [ ] Correct camera angle
* [ ] Player movement
* [ ] Depth sorting
* [ ] Collision
* [ ] Lighting
* [ ] Shadows
* [ ] Environment props
* [ ] Camera follow

---

# 29. Sprint 01

## Goal

Build:

```text
Ravenfall
    ↓
Blackwood
    ↓
Choose Enemy
    ↓
Auto Battle
    ↓
Reward
    ↓
Ravenfall
```

## Tasks

### Project

* [ ] Create Godot project
* [ ] Setup Git
* [ ] Create folders
* [ ] Create Main Scene

### World

* [ ] Create 3D test environment
* [ ] Create Orthographic Camera
* [ ] Setup Isometric angle
* [ ] Create Ravenfall test scene
* [ ] Create Blackwood test scene

### Systems

* [ ] GameManager
* [ ] PlayerData
* [ ] EnemyData
* [ ] MapManager
* [ ] CombatManager
* [ ] Reward System

### Combat

* [ ] Enemy selection
* [ ] Speed system
* [ ] Damage system
* [ ] HP system
* [ ] Win
* [ ] Lose
* [ ] Reward

### Result

The first playable build should allow:

```text
Open Game
    ↓
Ravenfall
    ↓
Enter Blackwood
    ↓
Choose Wolf
    ↓
Automatic Battle
    ↓
Win
    ↓
Receive Power / Gold
    ↓
Return Ravenfall
```

---

# 30. Current Project Status

## Completed Design

* [x] Game Concept
* [x] Cute Fantasy Direction
* [x] Isometric 2.5D Direction
* [x] Node-Based Map
* [x] Automatic Combat
* [x] Speed-Based Combat
* [x] Immediate Death Rule
* [x] Power
* [x] HP
* [x] Gold
* [x] Potion
* [x] Treasure
* [x] Equipment
* [x] Blacksmith
* [x] Ravenfall
* [x] Blackwood
* [x] Core Gameplay Loop
* [x] Technical Stack

## In Progress / Done

* [x] Godot Project (Godot 4.7.2, PHASE 0 complete — see docs/roadmap.md)
* [x] 3D Scenes (test world)
* [x] Isometric Camera

## Not Started

* [ ] Code Architecture (managers beyond GameManager)
* [ ] Combat Implementation
* [ ] UI
* [ ] Data System
* [ ] Save System
* [ ] Character Assets
* [ ] Environment Assets
* [ ] Animation
* [ ] VFX
* [ ] Audio

---

# 31. Immediate Next Step

## PHASE 0

Start with:

```text
1. Install / Open Godot 4.x
        ↓
2. Create THE FRONTIER
        ↓
3. Create Git Repository
        ↓
4. Create Folder Structure
        ↓
5. Create Main Scene
        ↓
6. Create GameManager
        ↓
7. Create PlayerData
        ↓
8. Create 3D Test World
        ↓
9. Setup Orthographic Camera
        ↓
10. Test Isometric View
```

After the camera and test world look correct:

**→ Start PHASE 1: Gameplay Prototype**

---

# 32. Core Philosophy

> **Build the game before building the MMO.**

The first goal is not a huge world.

The first goal is:

**Is THE FRONTIER actually fun to play?**

If the core loop is fun, expand it.

If it is not fun, change the gameplay before spending time on massive content, art, networking, or infrastructure.
