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

	# --- Phase 2: EXP / shop / inventory / equipment / level up ---
	if p.experience != 40:
		printerr("[TEST] FAIL: expected 40 EXP from wolf, got %d" % p.experience)
		ok = false

	# Buy a potion (5 gold) and drink it (HP 91 -> capped at 100)
	var potion: ItemData = load("res://data/items/small_potion.tres")
	var gold_before_potion: int = p.gold
	if not ShopManager.buy(potion) or p.gold != gold_before_potion - 5 or p.item_qty("small_potion") != 1:
		printerr("[TEST] FAIL: buying a potion should cost 5 gold and add 1 to bag")
		ok = false
	if not p.use_potion() or p.hp != p.max_hp or p.item_qty("small_potion") != 0:
		printerr("[TEST] FAIL: potion should heal to full (91+30 capped) and be consumed")
		ok = false
	if p.use_potion():
		printerr("[TEST] FAIL: cannot drink a potion you don't have / at full HP")
		ok = false

	# Buy + equip the rusty sword: attack = base power + 10
	var sword: ItemData = load("res://data/equipment/rusty_sword.tres")
	if not ShopManager.buy(sword):
		printerr("[TEST] FAIL: should afford rusty sword (10 gold)")
		ok = false
	if ShopManager.buy(sword):
		printerr("[TEST] FAIL: weapons can only be owned once")
		ok = false
	p.equip_weapon(sword)
	if p.attack_power() != p.power + 10:
		printerr("[TEST] FAIL: equipped sword should add +10 ATK, got %d vs base %d" % [p.attack_power(), p.power])
		ok = false

	# Level up: 40 EXP + 60 more = 100 -> Lv.2, +20 max HP, +10 power, +2 speed, full heal
	var power_before_level: int = p.power
	var speed_before_level: int = p.speed
	var ups: int = p.gain_exp(60)
	if ups != 1 or p.level != 2 or p.experience != 0:
		printerr("[TEST] FAIL: 100 EXP should reach exactly Lv.2 (got Lv.%d, %d EXP, %d ups)" % [p.level, p.experience, ups])
		ok = false
	if p.max_hp != 120 or p.hp != 120 or p.power != power_before_level + 10 or p.speed != speed_before_level + 2:
		printerr("[TEST] FAIL: level-up growth wrong (HP %d/%d, Power %d, Speed %d)" % [p.hp, p.max_hp, p.power, p.speed])
		ok = false

	if ok:
		print("[TEST] PASS — combat, map, shop, inventory, equipment, and level-up all work")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
