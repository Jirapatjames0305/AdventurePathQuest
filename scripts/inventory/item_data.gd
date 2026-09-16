class_name ItemData
extends Resource
## Data for one item (potion, weapon, ...). Phase 2 data-driven items.

@export var id: String = ""
@export var display_name: String = "Item"
@export var emoji: String = "🎒"
@export_enum("potion", "weapon") var type: String = "potion"
## potion: heal amount. weapon: ATK bonus.
@export var value: int = 0
@export var price: int = 0
@export_multiline var description: String = ""


func effect_text() -> String:
	match type:
		"potion":
			return "❤️ +%d HP" % value
		"weapon":
			return "⚔️ ATK +%d" % value
	return ""
