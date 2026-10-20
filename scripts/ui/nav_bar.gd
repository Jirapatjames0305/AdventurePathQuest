extends CanvasLayer
## Bottom navbar: F1–F10 (or click) open everything that was hidden from the
## town screen — status, bag, rest, the old shops, the world map — and
## toggle the design/HUD layers (grid, coordinates, minimap, compass).
## Toggle buttons show as pressed while their layer is on.

const PANEL_BG := Color(0.12, 0.1, 0.08, 0.88)
const BORDER := Color(0.85, 0.68, 0.36)
const TEXT := Color(0.97, 0.93, 0.84)

## [key, icon + label, action, is_toggle]
const ITEMS := [
	[KEY_F1, "📊 Status", "status", true],
	[KEY_F2, "🎒 Bag", "bag", false],
	[KEY_F3, "🛏️ Rest", "rest", false],
	[KEY_F4, "🧪 Potions", "potion", false],
	[KEY_F5, "⚒️ Smith", "smith", false],
	[KEY_F6, "🗺️ World", "world", false],
	[KEY_F7, "🗺️ Grid", "grid", true],
	[KEY_F8, "📍 Coords", "coords", true],
	[KEY_F9, "🧭 Minimap", "minimap", true],
	[KEY_F10, "✴️ Compass", "compass", true],
]

@onready var _town_ui = get_node("../RavenfallUI")
@onready var _grid = get_node("../MapGrid")
@onready var _minimap: Control = get_node("../MinimapLayer/Minimap")
@onready var _compass: Control = get_node("../MinimapLayer/Compass")

var _buttons := {}
var _toast: Label
var _toast_time := 0.0


func _ready() -> void:
	layer = 15
	_build()
	_sync()


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time / 0.4, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	for item in ITEMS:
		if event.keycode == item[0]:
			_run(item[2])
			get_viewport().set_input_as_handled()
			return


func _run(action: String) -> void:
	match action:
		"status": _town_ui.toggle_status()
		"bag": _toggle_panel(_town_ui.open_bag)
		"potion": _toggle_panel(_town_ui.open_shop.bind("potion"))
		"smith": _toggle_panel(_town_ui.open_shop.bind("smith"))
		"rest":
			_town_ui.rest()
			var player := GameManager.player_data
			_show_toast("🛏️ Rested — HP %d/%d" % [player.hp, player.max_hp])
		"world": GameManager.goto_world_map()
		"grid": _grid.set_grid_visible(not _grid.visible)
		"coords": _grid.set_coords_visible(not _grid.coords_visible())
		"minimap": _minimap.visible = not _minimap.visible
		"compass": _compass.visible = not _compass.visible
	_sync()


## Opens a town panel, or closes it if it's already open.
func _toggle_panel(open: Callable) -> void:
	if _town_ui.panel_visible():
		_town_ui.close_panel()
	else:
		open.call()


## Pressed state of the toggle buttons follows what's actually on screen.
func _sync() -> void:
	var states := {
		"status": _town_ui.status_visible(),
		"grid": _grid.visible,
		"coords": _grid.coords_visible(),
		"minimap": _minimap.visible,
		"compass": _compass.visible,
	}
	for action in states:
		_buttons[action].set_pressed_no_signal(states[action])


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_time = 2.0


func _build() -> void:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	bar.add_theme_stylebox_override("panel", style)
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -14
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)
	for item in ITEMS:
		var button := Button.new()
		button.text = "%s\n%s" % [OS.get_keycode_string(item[0]), item[1]]
		button.toggle_mode = item[3]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(118, 62)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_run.bind(item[2]))
		row.add_child(button)
		_buttons[item[2]] = button
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_color", TEXT)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_left = -300
	_toast.offset_right = 300
	_toast.offset_top = -150
	_toast.modulate.a = 0.0
	add_child(_toast)
