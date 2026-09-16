extends Control
## Blackwood Forest — node-based map (README section 10).
## Nodes unlock along the tree; after combat the player returns here.

@onready var enemy_list: VBoxContainer = %EnemyList
@onready var player_stats_label: Label = %PlayerStats
@onready var potion_button: Button = %PotionButton
@onready var cleared_label: Label = %ClearedLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(GameManager.goto_ravenfall)
	potion_button.pressed.connect(_on_potion_pressed)
	_refresh()


func _on_potion_pressed() -> void:
	GameManager.player_data.use_potion()
	_refresh()


func _refresh() -> void:
	var player := GameManager.player_data
	player_stats_label.text = "🧙 Hero Lv.%d — HP %d/%d   ⚔️ %d   💨 %d   💰 %d Gold" % [
		player.level, player.hp, player.max_hp,
		player.attack_power(), player.speed, player.gold
	]
	var potions: int = player.item_qty("small_potion")
	potion_button.visible = potions > 0
	potion_button.text = "🧪 Use Small Potion (×%d) — +30 HP" % potions
	potion_button.disabled = player.hp >= player.max_hp
	cleared_label.visible = MapManager.is_map_cleared()

	for child in enemy_list.get_children():
		child.queue_free()
	for node in MapManager.get_nodes():
		enemy_list.add_child(_build_node_button(node))


func _build_node_button(node: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 56)
	var unlocked: bool = MapManager.is_unlocked(node)
	var done: bool = MapManager.is_completed(node.id)

	if not unlocked:
		button.text = "🔒 ???   —   defeat Wolf and Boar to unlock"
		button.disabled = true
		return button

	match node.type:
		"treasure":
			if done:
				button.text = "✅ 💰 Treasure Chest — opened"
				button.disabled = true
			else:
				button.text = "💰 Treasure Chest — open it!"
				button.pressed.connect(_on_treasure_pressed.bind(node))
		"enemy", "boss":
			var enemy: EnemyData = load(node.enemy)
			var prefix := "✅ " if done else ""
			var boss_tag := "👑 BOSS  " if node.type == "boss" else ""
			button.text = "%s%s%s  %s   —   HP %d | ⚔️ %d | 💨 %d" % [
				prefix, boss_tag, enemy.emoji, enemy.display_name,
				enemy.max_hp, enemy.power, enemy.speed
			]
			button.tooltip_text = enemy.description
			if node.type == "boss" and done:
				button.text = "✅ 👑 %s — defeated!" % enemy.display_name
				button.disabled = true
			else:
				button.pressed.connect(GameManager.start_combat.bind(enemy, node.id))
	return button


func _on_treasure_pressed(node: Dictionary) -> void:
	var reward: Dictionary = MapManager.open_treasure(node)
	if not reward.is_empty():
		print("[Blackwood] Treasure opened: +%d Gold, +%d Power" % [reward.gold, reward.power])
	_refresh()
