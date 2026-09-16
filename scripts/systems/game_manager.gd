extends Node
## GameManager — autoload singleton
## Holds global game state and drives the core loop:
## Ravenfall -> Blackwood -> Enemy Selection -> Auto Combat -> Reward -> Ravenfall

const SCENE_RAVENFALL := "res://scenes/main.tscn"
const SCENE_BLACKWOOD := "res://scenes/world/forest/blackwood.tscn"
const SCENE_COMBAT := "res://scenes/combat/combat.tscn"

var player_data: PlayerData

## Enemy chosen in Blackwood, consumed by the combat scene.
var current_enemy: EnemyData


func _ready() -> void:
	player_data = PlayerData.new()
	print("[GameManager] Ready — Player Lv.%d | Power %d | HP %d/%d | Speed %d | Gold %d" % [
		player_data.level,
		player_data.power,
		player_data.hp,
		player_data.max_hp,
		player_data.speed,
		player_data.gold,
	])


func goto_ravenfall() -> void:
	get_tree().change_scene_to_file(SCENE_RAVENFALL)


func goto_blackwood() -> void:
	get_tree().change_scene_to_file(SCENE_BLACKWOOD)


func start_combat(enemy: EnemyData, node_id: String = "") -> void:
	current_enemy = enemy
	MapManager.current_node_id = node_id
	get_tree().change_scene_to_file(SCENE_COMBAT)


## README rule: Power reward = Enemy Power × 50%, plus gold and EXP.
func apply_victory_rewards(enemy: EnemyData) -> Dictionary:
	var reward := {
		"power": enemy.power_reward(),
		"gold": enemy.gold_reward,
		"exp": enemy.exp_reward,
	}
	player_data.power += reward.power
	player_data.gold += reward.gold
	reward["level_ups"] = player_data.gain_exp(enemy.exp_reward)
	return reward


func rest() -> void:
	player_data.heal(player_data.max_hp)
