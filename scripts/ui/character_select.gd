extends Node3D
## Character select — first screen. Shows every hero in a row; the chosen one
## cheers on a glowing ring. Choice is stored in PlayerData.character_id.

const SPACING := 2.0

var _models: Array[CharacterModel] = []
var _index := 0

@onready var lineup: Node3D = $Lineup
@onready var ring: MeshInstance3D = $Ring
@onready var name_label: Label = %NameLabel
@onready var blurb_label: Label = %BlurbLabel
@onready var choice_bar: HBoxContainer = %ChoiceBar
@onready var start_button: Button = %StartButton


func _ready() -> void:
	var ids := CharacterModel.ids()
	for i in ids.size():
		var model := CharacterModel.new()
		model.character_id = ids[i]
		model.position.x = (i - (ids.size() - 1) / 2.0) * SPACING
		lineup.add_child(model)
		_models.append(model)

		var info := CharacterModel.info(ids[i])
		var button := Button.new()
		button.text = "%s %s" % [info.emoji, info.name]
		button.custom_minimum_size = Vector2(200, 56)
		button.add_theme_font_size_override("font_size", 22)
		button.toggle_mode = true
		button.pressed.connect(_select.bind(i))
		choice_bar.add_child(button)

	start_button.pressed.connect(_on_start_pressed)
	_select(ids.find(GameManager.player_data.character_id))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		_select(wrapi(_index - 1, 0, _models.size()))
	elif event.is_action_pressed("move_right"):
		_select(wrapi(_index + 1, 0, _models.size()))
	elif event.is_action_pressed("ui_accept"):
		_on_start_pressed()


func _select(index: int) -> void:
	_index = maxi(index, 0)
	var model := _models[_index]
	model.play("Cheer")
	ring.position.x = model.position.x
	for i in choice_bar.get_child_count():
		(choice_bar.get_child(i) as Button).set_pressed_no_signal(i == _index)
	var info := CharacterModel.info(model.character_id)
	name_label.text = "%s %s" % [info.emoji, info.name]
	blurb_label.text = info.blurb


func _on_start_pressed() -> void:
	GameManager.player_data.character_id = _models[_index].character_id
	GameManager.goto_ravenfall()
