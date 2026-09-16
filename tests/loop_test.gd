extends Node
## Headless test: full auto-battle vs Forest Wolf via the map flow,
## then verify rewards, node completion, and boss unlock rules.
## Run: Godot --headless res://tests/loop_test.tscn

func _ready() -> void:
	var nodes := MapManager.get_nodes()
	var wolf_node: Dictionary = nodes[0]
	var boar_node: Dictionary = nodes[1]
	var treasure_node: Dictionary = nodes[2]
	var alpha_node: Dictionary = nodes[3]

	var ok := true
	if not MapManager.is_unlocked(wolf_node):
		printerr("[TEST] FAIL: wolf node should start unlocked")
		ok = false
	if MapManager.is_unlocked(alpha_node):
		printerr("[TEST] FAIL: alpha (boss) node should start locked")
		ok = false

	# Fight the wolf through its map node
	var enemy: EnemyData = load(wolf_node.enemy)
	GameManager.current_enemy = enemy
	MapManager.current_node_id = wolf_node.id
	var combat: Control = load("res://scenes/combat/combat.tscn").instantiate()
	add_child(combat)

	var return_button: Button = combat.get_node("%ReturnButton")
	var waited := 0.0
	while not return_button.visible and waited < 30.0:
		await get_tree().create_timer(0.5).timeout
		waited += 0.5

	var p: PlayerData = GameManager.player_data
	print("[TEST] After battle: Power=%d Gold=%d HP=%d/%d" % [p.power, p.gold, p.hp, p.max_hp])

	if p.power != 115:
		printerr("[TEST] FAIL: expected Power 115 (100 + 30*50%%), got %d" % p.power)
		ok = false
	if p.gold != 18:
		printerr("[TEST] FAIL: expected Gold 18 (10 + 8), got %d" % p.gold)
		ok = false
	if p.hp != 91:
		printerr("[TEST] FAIL: expected HP 91 (3 wolf hits x 3 dmg), got %d" % p.hp)
		ok = false

	# Map progression checks
	if not MapManager.is_completed("wolf"):
		printerr("[TEST] FAIL: wolf node should be completed after victory")
		ok = false
	if MapManager.is_unlocked(alpha_node):
		printerr("[TEST] FAIL: alpha should still be locked (boar not beaten)")
		ok = false
	MapManager.completed["boar"] = true
	if not MapManager.is_unlocked(alpha_node):
		printerr("[TEST] FAIL: alpha should unlock after wolf + boar")
		ok = false

	# Treasure: opens once, applies +50 gold / +80 power, then stays opened
	var gold_before: int = p.gold
	var power_before: int = p.power
	var reward: Dictionary = MapManager.open_treasure(treasure_node)
	if reward.is_empty() or p.gold != gold_before + 50 or p.power != power_before + 80:
		printerr("[TEST] FAIL: treasure should grant +50 gold / +80 power")
		ok = false
	if not MapManager.open_treasure(treasure_node).is_empty():
		printerr("[TEST] FAIL: treasure should only open once")
		ok = false

	if ok:
		print("[TEST] PASS — combat, rewards, and tree-map progression all work")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
