extends Control
## Blackwood Forest — enemy selection (node-based map comes in a later phase).

const ENEMY_PATHS: Array[String] = [
	"res://data/enemies/forest_wolf.tres",
	"res://data/enemies/wild_boar.tres",
	"res://data/enemies/alpha_wolf.tres",
]

@onready var enemy_list: VBoxContainer = %EnemyList
@onready var player_stats_label: Label = %PlayerStats
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(GameManager.goto_ravenfall)
	var player := GameManager.player_data
	player_stats_label.text = "🧙 Hero — HP %d/%d   ⚔️ Power %d   💨 Speed %d   💰 %d Gold" % [
		player.hp, player.max_hp, player.power, player.speed, player.gold
	]

	for path in ENEMY_PATHS:
		var enemy: EnemyData = load(path)
		var button := Button.new()
		button.text = "%s  %s   —   HP %d | ⚔️ %d | 💨 %d" % [
			enemy.emoji, enemy.display_name, enemy.max_hp, enemy.power, enemy.speed
		]
		button.tooltip_text = enemy.description
		button.custom_minimum_size = Vector2(0, 56)
		button.pressed.connect(GameManager.start_combat.bind(enemy))
		enemy_list.add_child(button)
