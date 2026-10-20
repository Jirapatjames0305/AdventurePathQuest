extends CanvasLayer
## Talk to NPCs: when the hero is within INTERACT_RANGE of an NPC, a prompt
## shows "[F] Name — Role". Pressing F opens that NPC's window — a shop
## (general store / weapon upgrades / magic shop) or the guild quest board.
## While a window is open the hero can't move; F, Esc or Close shut it.

const INTERACT_RANGE := 3.0
const PANEL_BG := Color(0.12, 0.1, 0.08, 0.92)
const PANEL_BORDER := Color(0.85, 0.68, 0.36)
const TEXT := Color(0.97, 0.93, 0.84)
const MUTED := Color(0.75, 0.7, 0.6)

## NPC service -> shop key for ShopManager.get_stock().
const SHOPS := {"store": "potion", "magic": "magic", "smith": "smith"}

@export var player_path: NodePath

var _player: Node3D
var _nearest: Npc
var _open_npc: Npc
var _prompt: PanelContainer
var _prompt_key: Label
var _prompt_text: Label
var _dialog: PanelContainer
var _dialog_title: Label
var _dialog_sub: Label
var _dialog_list: VBoxContainer


func _ready() -> void:
	layer = 20
	_player = get_node(player_path)
	_build_prompt()
	_build_dialog()


func _process(_delta: float) -> void:
	_nearest = _find_nearest()
	_prompt.visible = _nearest != null and _open_npc == null
	if _prompt.visible:
		_prompt_text.text = "%s  —  %s" % [_nearest.display_name, _nearest.role]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _open_npc:
			_close()
		elif _nearest:
			_open(_nearest)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and _open_npc:
		_close()
		get_viewport().set_input_as_handled()


func _find_nearest() -> Npc:
	var best: Npc = null
	var best_distance := INTERACT_RANGE
	for npc: Npc in get_tree().get_nodes_in_group("npc"):
		var flat := npc.global_position - _player.global_position
		flat.y = 0.0
		if flat.length() < best_distance:
			best_distance = flat.length()
			best = npc
	return best


func _open(npc: Npc) -> void:
	_open_npc = npc
	Player.input_locked = true
	_dialog_title.text = "%s's %s" % [npc.display_name, npc.role]
	_dialog_title.add_theme_color_override("font_color", npc.marker_color.lightened(0.3))
	_refresh()
	_dialog.show()


func _close() -> void:
	_open_npc = null
	Player.input_locked = false
	_dialog.hide()


func _refresh() -> void:
	for child in _dialog_list.get_children():
		child.queue_free()
	var player := GameManager.player_data
	var weapon: ItemData = player.equipped_weapon()
	_dialog_sub.text = "💰 %d gold     ❤️ %d/%d HP     ⚔️ %s     Lv.%d" % [
		player.gold, player.hp, player.max_hp, weapon.display_name if weapon else "No weapon", player.level]
	if _open_npc.service == "quests":
		_fill_quests()
	else:
		_fill_shop(SHOPS[_open_npc.service])


func _fill_shop(shop: String) -> void:
	var player := GameManager.player_data
	for item in ShopManager.get_stock(shop):
		var details := "%s   ·   %d gold" % [item.effect_text(), item.price]
		var action := "Buy"
		var enabled := ShopManager.can_buy(item)
		if item.type == "potion" and player.has_item(item.id):
			details += "   ·   own %d" % player.item_qty(item.id)
		if item.type == "weapon" and player.has_item(item.id):
			var equipped: bool = player.equipped_weapon() == player.inventory[item.id].item
			action = "Equipped" if equipped else "Equip"
			enabled = not equipped
		_dialog_list.add_child(_row("%s %s" % [item.emoji, item.display_name], details, action, enabled, _on_item.bind(item)))


func _on_item(item: ItemData) -> void:
	var player := GameManager.player_data
	if item.type == "weapon" and player.has_item(item.id):
		player.equip_weapon(player.inventory[item.id].item)
	elif ShopManager.buy(item) and item.type == "weapon":
		player.equip_weapon(item)  # weapon upgrades are equipped straight away
	_refresh()


func _fill_quests() -> void:
	for quest in QuestManager.QUESTS:
		var state := QuestManager.state(quest.id)
		var details := "Defeat %d × %s   ·   %d gold, %d EXP" % [quest.count, quest.target, quest.gold, quest.exp]
		var action := "Accept"
		var enabled := true
		match state:
			QuestManager.State.ACTIVE:
				details = "In Blackwood: %d / %d %s defeated" % [QuestManager.progress(quest.id), quest.count, quest.target]
				action = "In progress"
				enabled = false
			QuestManager.State.READY:
				details = "Complete! Reward: %d gold, %d EXP" % [quest.gold, quest.exp]
				action = "Claim"
			QuestManager.State.CLAIMED:
				details = "Done — thank you, adventurer."
				action = "Claimed"
				enabled = false
		_dialog_list.add_child(_row("📜 %s" % quest.title, details, action, enabled, _on_quest.bind(quest.id)))


func _on_quest(id: String) -> void:
	match QuestManager.state(id):
		QuestManager.State.AVAILABLE:
			QuestManager.accept(id)
		QuestManager.State.READY:
			QuestManager.claim(id)
	_refresh()


# --- UI building ---

func _panel_style(radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _label(text: String, font_size: int, color := TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Bottom-centre "[F] Name — Role" prompt.
func _build_prompt() -> void:
	_prompt = PanelContainer.new()
	_prompt.add_theme_stylebox_override("panel", _panel_style(14))
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_bottom = -110
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_prompt.add_child(row)
	var key := PanelContainer.new()
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = PANEL_BORDER
	key_style.set_corner_radius_all(8)
	key_style.content_margin_left = 14
	key_style.content_margin_right = 14
	key_style.content_margin_top = 2
	key_style.content_margin_bottom = 2
	key.add_theme_stylebox_override("panel", key_style)
	row.add_child(key)
	_prompt_key = _label("F", 30, Color(0.15, 0.1, 0.05))
	key.add_child(_prompt_key)
	_prompt_text = _label("", 28)
	_prompt_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_prompt_text)
	_prompt.hide()


## Centred window: title, player status line, list of rows, close button.
func _build_dialog() -> void:
	_dialog = PanelContainer.new()
	_dialog.add_theme_stylebox_override("panel", _panel_style(18))
	_dialog.anchor_left = 0.5
	_dialog.anchor_right = 0.5
	_dialog.anchor_top = 0.5
	_dialog.anchor_bottom = 0.5
	_dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dialog.grow_vertical = Control.GROW_DIRECTION_BOTH
	_dialog.custom_minimum_size = Vector2(820, 0)
	add_child(_dialog)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_dialog.add_child(box)
	_dialog_title = _label("", 34)
	_dialog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_dialog_title)
	_dialog_sub = _label("", 20, MUTED)
	_dialog_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_dialog_sub)
	box.add_child(HSeparator.new())
	_dialog_list = VBoxContainer.new()
	_dialog_list.add_theme_constant_override("separation", 10)
	box.add_child(_dialog_list)
	box.add_child(HSeparator.new())
	var close := Button.new()
	close.text = "Close  [F / Esc]"
	close.custom_minimum_size = Vector2(0, 50)
	close.add_theme_font_size_override("font_size", 22)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close)
	box.add_child(close)
	_dialog.hide()


func _row(title: String, details: String, action: String, enabled: bool, on_press: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 2)
	text.add_child(_label(title, 24))
	text.add_child(_label(details, 18, MUTED))
	row.add_child(text)
	var button := Button.new()
	button.text = action
	button.custom_minimum_size = Vector2(170, 52)
	button.add_theme_font_size_override("font_size", 22)
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not enabled
	button.pressed.connect(on_press)
	row.add_child(button)
	return row
