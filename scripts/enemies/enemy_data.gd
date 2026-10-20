class_name EnemyData
extends Resource
## Data for one enemy type (Phase 1 / Phase 3 data-driven content).

@export var display_name: String = "Enemy"
@export var emoji: String = "👾"
## CreatureModel kind used on the Blackwood map and the combat stage.
@export_enum("wolf", "alpha", "boar", "slime", "shroom", "spider", "bear", "treant", "bat", "beetle") var model: String = "wolf"
@export var power: int = 10
@export var max_hp: int = 30
@export var speed: int = 20
@export var gold_reward: int = 5
@export var exp_reward: int = 20
@export_multiline var description: String = ""


## README rule: default Power reward = Enemy Power × 50%
func power_reward() -> int:
	return int(power * 0.5)
