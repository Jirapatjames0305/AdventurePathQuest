extends Node
## ShopManager — autoload singleton
## Shop stock and purchase rules for Ravenfall (Phase 2 gold economy).

const POTION_SHOP_STOCK: Array[String] = [
	"res://data/items/small_potion.tres",
]

const BLACKSMITH_STOCK: Array[String] = [
	"res://data/equipment/rusty_sword.tres",
	"res://data/equipment/reinforced_sword.tres",
]

const MAGIC_SHOP_STOCK: Array[String] = [
	"res://data/items/greater_potion.tres",
	"res://data/items/elixir.tres",
]


## shop: "potion" (general store), "smith" (weapons) or "magic".
func get_stock(shop: String) -> Array[ItemData]:
	var paths: Array[String] = BLACKSMITH_STOCK
	match shop:
		"potion": paths = POTION_SHOP_STOCK
		"magic": paths = MAGIC_SHOP_STOCK
	var stock: Array[ItemData] = []
	for path in paths:
		stock.append(load(path))
	return stock


## A weapon can only be owned once; potions stack.
func can_buy(item: ItemData) -> bool:
	var player := GameManager.player_data
	if player.gold < item.price:
		return false
	if item.type == "weapon" and player.has_item(item.id):
		return false
	return true


func buy(item: ItemData) -> bool:
	if not can_buy(item):
		return false
	var player := GameManager.player_data
	player.gold -= item.price
	player.add_item(item)
	return true
