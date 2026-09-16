extends CanvasLayer
## Ravenfall town UI overlay — stats, rest, shops, bag, forest entrance.

@onready var stats_label: Label = %StatsLabel
@onready var rest_button: Button = %RestButton
@onready var potion_shop_button: Button = %PotionShopButton
@onready var blacksmith_button: Button = %BlacksmithButton
@onready var bag_button: Button = %BagButton
@onready var forest_button: Button = %ForestButton
@onready var shop_panel: PanelContainer = %ShopPanel
@onready var shop_title: Label = %ShopTitle
@onready var shop_gold: Label = %ShopGold
@onready var shop_list: VBoxContainer = %ShopList
@onready var close_shop_button: Button = %CloseShopButton


func _ready() -> void:
	rest_button.pressed.connect(_on_rest_pressed)
	potion_shop_button.pressed.connect(_open_shop.bind("potion"))
	blacksmith_button.pressed.connect(_open_shop.bind("smith"))
	bag_button.pressed.connect(_open_bag)
	forest_button.pressed.connect(GameManager.goto_blackwood)
	close_shop_button.pressed.connect(shop_panel.hide)
	shop_panel.hide()
	_refresh()


func _on_rest_pressed() -> void:
	GameManager.rest()
	_refresh()


func _refresh() -> void:
	var player := GameManager.player_data
	var weapon: ItemData = player.equipped_weapon()
	var weapon_text: String = "%s %s" % [weapon.emoji, weapon.display_name] if weapon else "—"
	stats_label.text = "🧙 Hero  Lv.%d  (EXP %d/%d)\n❤️ HP %d/%d\n⚔️ Power %d (base %d)\n💨 Speed %d\n💰 Gold %d\n🗡️ Weapon: %s\n🧪 Potions: %d" % [
		player.level, player.experience, player.exp_to_next(),
		player.hp, player.max_hp,
		player.attack_power(), player.power,
		player.speed, player.gold,
		weapon_text,
		player.item_qty("small_potion"),
	]


func _clear_shop_list() -> void:
	for child in shop_list.get_children():
		child.queue_free()


func _make_row(text: String, action_text: String, enabled: bool, on_press: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 44)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var button := Button.new()
	button.text = action_text
	button.custom_minimum_size = Vector2(120, 0)
	button.disabled = not enabled
	button.pressed.connect(on_press)
	row.add_child(button)
	return row


func _open_shop(shop: String) -> void:
	var player := GameManager.player_data
	shop_title.text = "🧪 Potion Shop" if shop == "potion" else "⚒️ Blacksmith"
	shop_gold.text = "💰 Your gold: %d" % player.gold
	_clear_shop_list()
	for item in ShopManager.get_stock(shop):
		var owned := item.type == "weapon" and player.has_item(item.id)
		var text := "%s %s   %s   —   %d Gold" % [
			item.emoji, item.display_name, item.effect_text(), item.price
		]
		if owned:
			text += "   (owned)"
		shop_list.add_child(_make_row(
			text,
			"Buy",
			ShopManager.can_buy(item),
			_on_buy_pressed.bind(item, shop)
		))
	shop_panel.show()


func _on_buy_pressed(item: ItemData, shop: String) -> void:
	if ShopManager.buy(item):
		print("[Shop] Bought %s for %d gold" % [item.display_name, item.price])
	_refresh()
	_open_shop(shop)


func _open_bag() -> void:
	var player := GameManager.player_data
	shop_title.text = "🎒 Bag"
	shop_gold.text = "💰 Gold: %d" % player.gold
	_clear_shop_list()
	if player.inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Your bag is empty. Visit the shops!"
		shop_list.add_child(empty_label)
	for item_id in player.inventory:
		var entry: Dictionary = player.inventory[item_id]
		var item: ItemData = entry.item
		match item.type:
			"potion":
				shop_list.add_child(_make_row(
					"%s %s ×%d   %s" % [item.emoji, item.display_name, entry.qty, item.effect_text()],
					"Use",
					player.hp < player.max_hp,
					_on_use_potion_pressed.bind(item)
				))
			"weapon":
				var equipped := player.equipped_weapon() == item
				shop_list.add_child(_make_row(
					"%s %s   %s%s" % [
						item.emoji, item.display_name, item.effect_text(),
						"   ✅ equipped" if equipped else ""
					],
					"Equip",
					not equipped,
					_on_equip_pressed.bind(item)
				))
	shop_panel.show()


func _on_use_potion_pressed(item: ItemData) -> void:
	GameManager.player_data.use_potion(item.id)
	_refresh()
	_open_bag()


func _on_equip_pressed(item: ItemData) -> void:
	GameManager.player_data.equip_weapon(item)
	_refresh()
	_open_bag()
