extends Node
## Headless test: run one full auto-battle vs Forest Wolf and verify rewards.
## Run: Godot --headless res://tests/loop_test.tscn

func _ready() -> void:
	var enemy: EnemyData = load("res://data/enemies/forest_wolf.tres")
	GameManager.current_enemy = enemy
	var combat: Control = load("res://scenes/combat/combat.tscn").instantiate()
	add_child(combat)

	var return_button: Button = combat.get_node("%ReturnButton")
	var waited := 0.0
	while not return_button.visible and waited < 30.0:
		await get_tree().create_timer(0.5).timeout
		waited += 0.5

	var p: PlayerData = GameManager.player_data
	print("[TEST] After battle: Power=%d Gold=%d HP=%d/%d" % [p.power, p.gold, p.hp, p.max_hp])

	var ok := true
	if p.power != 115:
		printerr("[TEST] FAIL: expected Power 115 (100 + 30*50%%), got %d" % p.power)
		ok = false
	if p.gold != 18:
		printerr("[TEST] FAIL: expected Gold 18 (10 + 8), got %d" % p.gold)
		ok = false
	if p.hp != 91:
		printerr("[TEST] FAIL: expected HP 91 (3 wolf hits x 3 dmg), got %d" % p.hp)
		ok = false

	if ok:
		print("[TEST] PASS — core loop combat + reward works")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
