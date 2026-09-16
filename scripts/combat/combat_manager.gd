extends Control
## CombatManager — runs the automatic battle per README rules:
## 1. Compare Speed — higher Speed attacks first (tie: player first)
## 2. Apply damage, check HP immediately
## 3. HP 0 = dead, dead unit cannot counterattack
## 4. Repeat until one side reaches 0 HP

const TURN_DELAY := 0.7
## Damage per attack = Power × 10% (min 1). Tune here.
const DAMAGE_FACTOR := 0.1

var _player: PlayerData
var _enemy: EnemyData
var _enemy_hp: int

@onready var player_name_label: Label = %PlayerName
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var player_stats_label: Label = %PlayerStats
@onready var enemy_name_label: Label = %EnemyName
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var enemy_stats_label: Label = %EnemyStats
@onready var battle_log: RichTextLabel = %BattleLog
@onready var return_button: Button = %ReturnButton


func _ready() -> void:
	_player = GameManager.player_data
	_enemy = GameManager.current_enemy
	if _enemy == null:
		push_warning("No enemy selected — returning to Ravenfall.")
		GameManager.goto_ravenfall()
		return
	_enemy_hp = _enemy.max_hp

	player_name_label.text = "🧙 Hero"
	enemy_name_label.text = "%s %s" % [_enemy.emoji, _enemy.display_name]
	player_hp_bar.max_value = _player.max_hp
	enemy_hp_bar.max_value = _enemy.max_hp
	return_button.visible = false
	return_button.pressed.connect(GameManager.goto_ravenfall)
	_refresh()

	_run_battle()


func _damage_of(power: int) -> int:
	return maxi(1, roundi(power * DAMAGE_FACTOR))


func _refresh() -> void:
	player_hp_bar.value = _player.hp
	player_stats_label.text = "HP %d/%d   ⚔️ %d   💨 %d" % [
		_player.hp, _player.max_hp, _player.power, _player.speed
	]
	enemy_hp_bar.value = _enemy_hp
	enemy_stats_label.text = "HP %d/%d   ⚔️ %d   💨 %d" % [
		_enemy_hp, _enemy.max_hp, _enemy.power, _enemy.speed
	]


func _log(text: String) -> void:
	battle_log.append_text(text + "\n")


func _run_battle() -> void:
	_log("[b]⚔️ Battle start![/b]  %s %s appears!" % [_enemy.emoji, _enemy.display_name])
	var player_first := _player.speed >= _enemy.speed
	_log("💨 %s is faster and attacks first!" % ("Hero" if player_first else _enemy.display_name))

	var round_number := 1
	while _player.is_alive() and _enemy_hp > 0:
		_log("\n[b]— Round %d —[/b]" % round_number)
		if player_first:
			await _player_attack()
			if _enemy_hp <= 0:
				break
			await _enemy_attack()
		else:
			await _enemy_attack()
			if not _player.is_alive():
				break
			await _player_attack()
		round_number += 1

	await get_tree().create_timer(TURN_DELAY).timeout
	if _enemy_hp <= 0:
		_on_victory()
	else:
		_on_defeat()
	return_button.visible = true


func _player_attack() -> void:
	await get_tree().create_timer(TURN_DELAY).timeout
	var dmg := _damage_of(_player.power)
	_enemy_hp = maxi(_enemy_hp - dmg, 0)
	_log("🗡️ Hero hits %s for [color=orange]%d[/color] damage!" % [_enemy.display_name, dmg])
	if _enemy_hp <= 0:
		_log("💀 %s is defeated — it cannot counterattack!" % _enemy.display_name)
	_refresh()


func _enemy_attack() -> void:
	await get_tree().create_timer(TURN_DELAY).timeout
	var dmg := _damage_of(_enemy.power)
	_player.take_damage(dmg)
	_log("🩸 %s hits Hero for [color=red]%d[/color] damage!" % [_enemy.display_name, dmg])
	if not _player.is_alive():
		_log("💀 Hero has fallen!")
	_refresh()


func _on_victory() -> void:
	var reward := GameManager.apply_victory_rewards(_enemy)
	_log("\n[b][color=gold]🏆 VICTORY![/color][/b]")
	_log("✨ Reward: [color=orange]+%d Power[/color], [color=yellow]+%d Gold[/color]" % [
		reward.power, reward.gold
	])
	_refresh()
	return_button.text = "🏰 Return to Ravenfall"


func _on_defeat() -> void:
	# Prototype defeat rule: you barely escape with 1 HP. Rest in town to recover.
	_player.hp = 1
	_log("\n[b][color=red]☠️ DEFEAT...[/color][/b]")
	_log("You barely escape back to Ravenfall with 1 HP. Rest to recover!")
	_refresh()
	return_button.text = "🏰 Limp back to Ravenfall"
