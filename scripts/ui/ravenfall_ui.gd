extends CanvasLayer
## Ravenfall town UI overlay on the isometric 3D world.

@onready var stats_label: Label = %StatsLabel
@onready var rest_button: Button = %RestButton
@onready var forest_button: Button = %ForestButton


func _ready() -> void:
	rest_button.pressed.connect(_on_rest_pressed)
	forest_button.pressed.connect(GameManager.goto_blackwood)
	_refresh()


func _on_rest_pressed() -> void:
	GameManager.rest()
	_refresh()


func _refresh() -> void:
	var player := GameManager.player_data
	stats_label.text = "🧙 Hero  Lv.%d\n❤️ HP %d/%d\n⚔️ Power %d\n💨 Speed %d\n💰 Gold %d" % [
		player.level, player.hp, player.max_hp, player.power, player.speed, player.gold
	]
