extends Node
## MapManager — autoload singleton
## Node-based map progression per README section 10.
## Each node: id, type (enemy/treasure/boss), data, requires (node ids), completed state.

## Blackwood tree map:
##        Entrance
##     ┌─────┼─────┐
##    wolf  boar  treasure
##     └──┬──┘
##      alpha (boss — requires wolf AND boar)
const BLACKWOOD_NODES: Array[Dictionary] = [
	{
		"id": "wolf",
		"type": "enemy",
		"enemy": "res://data/enemies/forest_wolf.tres",
		"requires": [],
	},
	{
		"id": "boar",
		"type": "enemy",
		"enemy": "res://data/enemies/wild_boar.tres",
		"requires": [],
	},
	{
		"id": "treasure",
		"type": "treasure",
		"gold": 50,
		"power": 80,
		"requires": [],
	},
	{
		"id": "alpha",
		"type": "boss",
		"enemy": "res://data/enemies/alpha_wolf.tres",
		"requires": ["wolf", "boar"],
	},
]

## node id -> true once completed (saved to disk in Phase 6)
var completed: Dictionary = {}

## Node the player is currently fighting; marked complete on victory.
var current_node_id: String = ""


func get_nodes() -> Array[Dictionary]:
	return BLACKWOOD_NODES


func is_unlocked(node: Dictionary) -> bool:
	for req in node.requires:
		if not completed.get(req, false):
			return false
	return true


func is_completed(node_id: String) -> bool:
	return completed.get(node_id, false)


func is_map_cleared() -> bool:
	for node in BLACKWOOD_NODES:
		if not is_completed(node.id):
			return false
	return true


func complete_current() -> void:
	if current_node_id != "":
		completed[current_node_id] = true
		current_node_id = ""


## Opens a treasure node: applies rewards once and marks it completed.
func open_treasure(node: Dictionary) -> Dictionary:
	if is_completed(node.id):
		return {}
	var reward := {
		"gold": int(node.get("gold", 0)),
		"power": int(node.get("power", 0)),
	}
	GameManager.player_data.gold += reward.gold
	GameManager.player_data.power += reward.power
	completed[node.id] = true
	return reward
