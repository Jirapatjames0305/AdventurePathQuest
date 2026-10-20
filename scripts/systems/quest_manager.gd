extends Node
## QuestManager — autoload singleton.
## Guild hunting quests: accept at the guild NPC, kills in Blackwood count
## toward them automatically (GameManager.apply_victory_rewards), then come
## back to claim gold + EXP.

## Each: id, title, target enemy display_name, count, reward gold, reward EXP.
const QUESTS := [
	{"id": "wolf_cull", "title": "Wolf Cull", "target": "Forest Wolf", "count": 3, "gold": 25, "exp": 60},
	{"id": "boar_trouble", "title": "Boar Trouble", "target": "Wild Boar", "count": 2, "gold": 30, "exp": 80},
	{"id": "alpha_hunt", "title": "Hunt the Alpha", "target": "Alpha Wolf", "count": 1, "gold": 60, "exp": 150},
]

enum State { AVAILABLE, ACTIVE, READY, CLAIMED }

## quest id -> {"state": State, "progress": int}
var _quests := {}


func _ready() -> void:
	for quest in QUESTS:
		_quests[quest.id] = {"state": State.AVAILABLE, "progress": 0}


func state(id: String) -> State:
	return _quests[id].state


func progress(id: String) -> int:
	return _quests[id].progress


func accept(id: String) -> void:
	if state(id) == State.AVAILABLE:
		_quests[id].state = State.ACTIVE


## Called after every won battle.
func record_kill(enemy_name: String) -> void:
	for quest in QUESTS:
		var entry: Dictionary = _quests[quest.id]
		if entry.state == State.ACTIVE and quest.target == enemy_name:
			entry.progress = mini(entry.progress + 1, quest.count)
			if entry.progress >= quest.count:
				entry.state = State.READY


## Pays out a finished quest. Returns the number of level-ups it caused.
func claim(id: String) -> int:
	if state(id) != State.READY:
		return 0
	var quest := _quest(id)
	_quests[id].state = State.CLAIMED
	GameManager.player_data.gold += quest.gold
	return GameManager.player_data.gain_exp(quest.exp)


func _quest(id: String) -> Dictionary:
	for quest in QUESTS:
		if quest.id == id:
			return quest
	return {}
