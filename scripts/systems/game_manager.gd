extends Node
## GameManager — autoload singleton
## Holds global game state for THE FRONTIER prototype.

var player_data: PlayerData


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
