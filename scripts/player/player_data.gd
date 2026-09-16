class_name PlayerData
extends Resource
## Player state per README Phase 1 initial values.

@export var level: int = 1
@export var power: int = 100
@export var hp: int = 100
@export var max_hp: int = 100
@export var speed: int = 50
@export var gold: int = 10
@export var inventory: Array = []
@export var equipment: Dictionary = {}


func is_alive() -> bool:
	return hp > 0


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
