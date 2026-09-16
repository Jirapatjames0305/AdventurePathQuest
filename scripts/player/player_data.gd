class_name PlayerData
extends Resource
## Player state. Initial values per README Phase 1; growth per Phase 2.

const LEVEL_UP_HP := 20
const LEVEL_UP_POWER := 10
const LEVEL_UP_SPEED := 2

@export var level: int = 1
@export var power: int = 100
@export var hp: int = 100
@export var max_hp: int = 100
@export var speed: int = 50
@export var gold: int = 10
@export var experience: int = 0

## item id -> {"item": ItemData, "qty": int}
var inventory: Dictionary = {}
## slot ("weapon") -> ItemData
var equipment: Dictionary = {}


func is_alive() -> bool:
	return hp > 0


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)


## Power used in combat = base power + equipped weapon ATK.
func attack_power() -> int:
	var weapon: ItemData = equipment.get("weapon")
	return power + (weapon.value if weapon else 0)


func exp_to_next() -> int:
	return level * 100


## Adds EXP, applies level-ups. Returns how many levels were gained.
func gain_exp(amount: int) -> int:
	experience += amount
	var level_ups := 0
	while experience >= exp_to_next():
		experience -= exp_to_next()
		level += 1
		level_ups += 1
		max_hp += LEVEL_UP_HP
		power += LEVEL_UP_POWER
		speed += LEVEL_UP_SPEED
		hp = max_hp
	return level_ups


# --- Inventory ---

func add_item(item: ItemData) -> void:
	if inventory.has(item.id):
		inventory[item.id].qty += 1
	else:
		inventory[item.id] = {"item": item, "qty": 1}


func item_qty(item_id: String) -> int:
	return inventory[item_id].qty if inventory.has(item_id) else 0


func has_item(item_id: String) -> bool:
	return item_qty(item_id) > 0


## Uses one potion by id. Returns true if consumed.
func use_potion(item_id: String = "small_potion") -> bool:
	if not has_item(item_id):
		return false
	var item: ItemData = inventory[item_id].item
	if item.type != "potion" or hp >= max_hp:
		return false
	heal(item.value)
	inventory[item_id].qty -= 1
	if inventory[item_id].qty <= 0:
		inventory.erase(item_id)
	return true


# --- Equipment ---

func equip_weapon(item: ItemData) -> void:
	if item.type == "weapon":
		equipment["weapon"] = item


func equipped_weapon() -> ItemData:
	return equipment.get("weapon")
