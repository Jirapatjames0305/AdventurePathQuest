extends Control
## The world map shown when the hero leaves Ravenfall. A painted overland map
## (drawn procedurally: coast, hills, mountains, forests, a river) with
## locations joined by dashed roads. Hover a location for its card; click an
## unlocked one and the hero pin walks the road there, then the scene loads.
## Drawn in the 1920×1080 design space (canvas_items stretch).

const SIZE := Vector2(1920, 1080)
const SEED := 1207

const SEA := Color(0.36, 0.55, 0.66)
const SEA_DEEP := Color(0.27, 0.44, 0.56)
const SHORE := Color(0.87, 0.8, 0.6)
const LAND := Color(0.6, 0.71, 0.43)
const LAND_LIGHT := Color(0.68, 0.77, 0.5)
const HILL := Color(0.53, 0.64, 0.38)
const FOREST := Color(0.25, 0.42, 0.25)
const FOREST_DARK := Color(0.16, 0.3, 0.18)
const MOUNTAIN := Color(0.56, 0.52, 0.5)
const SNOW := Color(0.95, 0.95, 0.97)
const RIVER := Color(0.42, 0.62, 0.78)
const ROAD := Color(0.42, 0.3, 0.18)
const INK := Color(0.2, 0.14, 0.08)
const GOLD := Color(0.85, 0.68, 0.36)

## id -> name, position, blurb, scene action, locked.
const LOCATIONS := {
	"ravenfall": {"name": "Ravenfall", "pos": Vector2(640, 600), "blurb": "Your home town. Shops, the Adventurers' Guild and a warm bed.", "locked": false},
	"blackwood": {"name": "Blackwood Forest", "pos": Vector2(1120, 470), "blurb": "Wolves and boars roam the dark pines. The Alpha Wolf rules its heart.", "locked": false},
	"caves": {"name": "Crystal Caves", "pos": Vector2(1500, 300), "blurb": "Glittering tunnels under the mountains. Coming in a future update.", "locked": true},
	"ruins": {"name": "Ancient Ruins", "pos": Vector2(1420, 790), "blurb": "Broken towers of a forgotten kingdom. Coming in a future update.", "locked": true},
	"harbor": {"name": "Saltmere Harbor", "pos": Vector2(330, 840), "blurb": "A fishing port on the western sea. Coming in a future update.", "locked": true},
}
const ROADS := [["ravenfall", "blackwood"], ["blackwood", "caves"], ["blackwood", "ruins"], ["ravenfall", "harbor"]]

var _rng := RandomNumberGenerator.new()
var _land := PackedVector2Array()
var _trees: Array = []      # [pos, radius, dark]
var _mountains: Array = []  # [pos, size]
var _hills: Array = []      # [pos, size]
var _river := PackedVector2Array()
var _hover := ""
var _pin := Vector2.ZERO
var _travelling := false
var _card: PanelContainer
var _card_title: Label
var _card_text: Label
var _card_hint: Label
var _time := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.seed = SEED
	_pin = LOCATIONS.ravenfall.pos
	_build_terrain()
	_build_ui()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if _travelling:
		return
	if event is InputEventMouseMotion:
		_set_hover(_location_at(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id := _location_at(event.position)
		if id != "" and not LOCATIONS[id].locked:
			_travel(id)


func _location_at(point: Vector2) -> String:
	for id in LOCATIONS:
		if point.distance_to(LOCATIONS[id].pos) < 60.0:
			return id
	return ""


func _set_hover(id: String) -> void:
	if id == _hover:
		return
	_hover = id
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if id != "" and not LOCATIONS[id].locked else Control.CURSOR_ARROW
	_card.visible = id != ""
	if id == "":
		return
	var loc: Dictionary = LOCATIONS[id]
	_card_title.text = ("🔒 " if loc.locked else "") + loc.name
	_card_text.text = loc.blurb
	_card_hint.text = "Not yet reachable" if loc.locked else ("You are here — click to enter" if loc.pos == _pin else "Click to travel")
	_card.reset_size()
	var at: Vector2 = loc.pos + Vector2(70, -60)
	if at.x + _card.size.x > SIZE.x - 20:
		at.x = loc.pos.x - 70 - _card.size.x
	_card.position = at


## Walk the pin along the road, then load the destination.
func _travel(id: String) -> void:
	_travelling = true
	_card.hide()
	var target: Vector2 = LOCATIONS[id].pos
	var tween := create_tween()
	tween.tween_property(self, "_pin", target, clampf(_pin.distance_to(target) / 500.0, 0.25, 1.2)).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.2)
	tween.tween_callback(_arrive.bind(id))


func _arrive(id: String) -> void:
	match id:
		"ravenfall":
			GameManager.goto_ravenfall("gate")
		"blackwood":
			GameManager.goto_blackwood()


# --- Terrain ---

func _build_terrain() -> void:
	# Coastline: a wobbly blob covering most of the map, sea in the corners.
	var center := Vector2(980, 560)
	for i in 72:
		var a := TAU * i / 72.0
		var r := Vector2(820, 470) * (1.0 + 0.07 * sin(a * 3.0 + 1.1) + 0.05 * sin(a * 7.0) + _rng.randf_range(-0.02, 0.02))
		_land.append(center + Vector2(cos(a) * r.x, sin(a) * r.y))
	# River from the northern mountains past Ravenfall to the south-west sea.
	var p := Vector2(1240, 160)
	for i in 26:
		_river.append(p)
		p += Vector2(-36 + sin(i * 0.7) * 24, 34 + cos(i * 0.5) * 10)
	# Mountain range along the north-east.
	for i in 16:
		_mountains.append([Vector2(1260 + i * 42 + _rng.randf_range(-20, 20), 230 + sin(i * 0.9) * 60 + _rng.randf_range(-15, 15)), _rng.randf_range(55, 95)])
	_mountains.sort_custom(func(a, b): return a[0].y < b[0].y)
	# Rolling hills.
	for i in 22:
		var at := center + Vector2(_rng.randf_range(-650, 650), _rng.randf_range(-350, 380))
		if Geometry2D.is_point_in_polygon(at, _land) and at.distance_to(LOCATIONS.blackwood.pos) > 220:
			_hills.append([at, _rng.randf_range(40, 80)])
	# Blackwood: a dense forest blob, plus scattered woods elsewhere.
	for i in 170:
		var at: Vector2 = LOCATIONS.blackwood.pos + Vector2(_rng.randf_range(-230, 230), _rng.randf_range(-150, 170))
		if Vector2((at.x - LOCATIONS.blackwood.pos.x) / 230.0, (at.y - LOCATIONS.blackwood.pos.y) / 160.0).length() < 1.0:
			_trees.append([at, _rng.randf_range(12, 19), true])
	for i in 90:
		var at := center + Vector2(_rng.randf_range(-700, 700), _rng.randf_range(-380, 400))
		if Geometry2D.is_point_in_polygon(at, _land) and at.distance_to(LOCATIONS.ravenfall.pos) > 120 and at.y > 330:
			_trees.append([at, _rng.randf_range(9, 14), false])
	_trees.sort_custom(func(a, b): return a[0].y < b[0].y)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), SEA)
	for i in 6:
		draw_arc(Vector2(980, 560), 1100.0 + i * 40.0 + sin(_time + i) * 6.0, 0, TAU, 96, Color(SEA_DEEP, 0.25), 6.0)
	var shore := PackedVector2Array()
	for point in _land:
		shore.append(Vector2(980, 560) + (point - Vector2(980, 560)) * 1.03)
	draw_colored_polygon(shore, SHORE)
	draw_colored_polygon(_land, LAND)
	for hill in _hills:
		draw_circle(hill[0] + Vector2(0, 6), hill[1], HILL)
		draw_circle(hill[0], hill[1] * 0.8, LAND_LIGHT)
	draw_polyline(_river, RIVER, 14.0, true)
	draw_polyline(_river, Color(RIVER.lightened(0.3), 0.6), 4.0, true)
	for road in ROADS:
		_dashed(LOCATIONS[road[0]].pos, LOCATIONS[road[1]].pos, LOCATIONS[road[1]].locked)
	for mountain in _mountains:
		_mountain(mountain[0], mountain[1])
	for tree in _trees:
		_tree(tree[0], tree[1], tree[2])
	for id in LOCATIONS:
		_location(id)
	_draw_pin(_pin + Vector2(0, -8 + sin(_time * 3.0) * 4.0))
	_compass(Vector2(150, 160))
	_title()


func _dashed(from: Vector2, to: Vector2, faded: bool) -> void:
	var length := from.distance_to(to)
	var dir := (to - from) / length
	var normal := Vector2(-dir.y, dir.x)
	var color := Color(ROAD, 0.4 if faded else 0.9)
	var t := 0.0
	while t < length:
		var bend := sin(t / length * PI) * 40.0
		var a := from + dir * t + normal * bend
		var b := from + dir * minf(t + 18.0, length) + normal * sin(minf(t + 18.0, length) / length * PI) * 40.0
		draw_line(a, b, color, 6.0, true)
		t += 34.0


func _mountain(at: Vector2, size: float) -> void:
	var peak := at + Vector2(0, -size)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-size * 0.75, 0), peak, at + Vector2(size * 0.75, 0)]), MOUNTAIN)
	draw_colored_polygon(PackedVector2Array([peak, at + Vector2(size * 0.75, 0), at + Vector2(0, 0)]), MOUNTAIN.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([peak, peak + Vector2(-size * 0.22, size * 0.3), peak + Vector2(0, size * 0.22), peak + Vector2(size * 0.22, size * 0.3)]), SNOW)


func _tree(at: Vector2, radius: float, dark: bool) -> void:
	draw_circle(at + Vector2(3, 4), radius, Color(0, 0, 0, 0.15))
	draw_circle(at, radius, FOREST_DARK if dark else FOREST)
	draw_circle(at + Vector2(-radius * 0.3, -radius * 0.3), radius * 0.5, (FOREST_DARK if dark else FOREST).lightened(0.15))


func _location(id: String) -> void:
	var loc: Dictionary = LOCATIONS[id]
	var at: Vector2 = loc.pos
	var hovered := id == _hover
	var locked: bool = loc.locked
	var ring := 44.0 + (6.0 if hovered else 0.0) + (sin(_time * 3.0) * 3.0 if hovered and not locked else 0.0)
	draw_circle(at + Vector2(0, 6), ring, Color(0, 0, 0, 0.25))
	draw_circle(at, ring, Color(0.14, 0.11, 0.08, 0.92))
	draw_arc(at, ring, 0, TAU, 48, Color(GOLD, 0.45) if locked else GOLD, 4.0, true)
	match id:
		"ravenfall": _icon_castle(at)
		"blackwood": _icon_pines(at)
		"caves": _icon_crystal(at)
		"ruins": _icon_ruins(at)
		"harbor": _icon_boat(at)
	if locked:
		draw_circle(at, ring, Color(0.1, 0.08, 0.06, 0.55))
		_text("🔒", at + Vector2(0, 12), 30, Color.WHITE)
	_text(loc.name, at + Vector2(0, ring + 34), 26, Color(1, 0.96, 0.88) if not locked else Color(1, 0.96, 0.88, 0.6), true)


func _icon_castle(at: Vector2) -> void:
	var wall := Color(0.95, 0.94, 0.9)
	var roof := Color(0.3, 0.38, 0.62)
	draw_rect(Rect2(at + Vector2(-18, -6), Vector2(36, 26)), wall)
	for x in [-24, 16]:
		draw_rect(Rect2(at + Vector2(x, -14), Vector2(8, 34)), wall)
		draw_colored_polygon(PackedVector2Array([at + Vector2(x - 3, -14), at + Vector2(x + 4, -28), at + Vector2(x + 11, -14)]), roof)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-20, -6), at + Vector2(0, -24), at + Vector2(20, -6)]), roof)
	draw_rect(Rect2(at + Vector2(-5, 8), Vector2(10, 12)), Color(0.36, 0.24, 0.14))


func _icon_pines(at: Vector2) -> void:
	for offset in [Vector2(-14, 6), Vector2(14, 8), Vector2(0, -4)]:
		var base: Vector2 = at + offset
		draw_colored_polygon(PackedVector2Array([base + Vector2(-12, 14), base + Vector2(0, -20), base + Vector2(12, 14)]), Color(0.25, 0.5, 0.3))


func _icon_crystal(at: Vector2) -> void:
	for spec in [[Vector2(-10, 10), 26.0, Color(0.55, 0.85, 1.0)], [Vector2(10, 12), 20.0, Color(0.8, 0.6, 1.0)], [Vector2(0, 14), 32.0, Color(0.7, 0.95, 1.0)]]:
		var base: Vector2 = at + spec[0]
		var h: float = spec[1]
		draw_colored_polygon(PackedVector2Array([base + Vector2(-7, 0), base + Vector2(0, -h), base + Vector2(7, 0)]), spec[2])


func _icon_ruins(at: Vector2) -> void:
	var stone := Color(0.8, 0.76, 0.68)
	for spec in [[-18, 28], [-4, 18], [10, 32]]:
		draw_rect(Rect2(at + Vector2(spec[0], 18 - spec[1]), Vector2(9, spec[1])), stone)
	draw_rect(Rect2(at + Vector2(-20, 18), Vector2(40, 5)), stone.darkened(0.2))


func _icon_boat(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(-22, 6), at + Vector2(22, 6), at + Vector2(14, 18), at + Vector2(-14, 18)]), Color(0.5, 0.32, 0.18))
	draw_line(at + Vector2(0, 6), at + Vector2(0, -22), Color(0.4, 0.26, 0.14), 3.0)
	draw_colored_polygon(PackedVector2Array([at + Vector2(2, -20), at + Vector2(18, 2), at + Vector2(2, 2)]), Color(0.96, 0.94, 0.88))


func _draw_pin(at: Vector2) -> void:
	draw_circle(at + Vector2(0, 30), 10, Color(0, 0, 0, 0.3))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-14, -36), at + Vector2(14, -36), at + Vector2(0, 0)]), Color(0.86, 0.22, 0.18))
	draw_circle(at + Vector2(0, -40), 16, Color(0.86, 0.22, 0.18))
	draw_circle(at + Vector2(0, -40), 7, Color(1, 0.95, 0.85))


func _compass(at: Vector2) -> void:
	draw_circle(at, 70, Color(0.14, 0.11, 0.08, 0.85))
	draw_arc(at, 70, 0, TAU, 48, GOLD, 4.0, true)
	for i in 4:
		var dir := Vector2.UP.rotated(i * PI / 2.0)
		var side := Vector2(-dir.y, dir.x) * 10.0
		draw_colored_polygon(PackedVector2Array([at, at + side, at + dir * 52]), Color(0.86, 0.22, 0.18) if i == 0 else Color(0.97, 0.94, 0.86))
		draw_colored_polygon(PackedVector2Array([at, at + dir * 52, at - side]), Color(0.55, 0.12, 0.1) if i == 0 else Color(0.62, 0.58, 0.5))
	_text("N", at + Vector2(0, -78), 24, Color(1, 0.9, 0.7))


func _title() -> void:
	var rect := Rect2(Vector2(SIZE.x / 2.0 - 260, 26), Vector2(520, 84))
	draw_rect(Rect2(rect.position + Vector2(0, 6), rect.size), Color(0, 0, 0, 0.25))
	draw_rect(rect, Color(0.14, 0.11, 0.08, 0.92))
	draw_rect(rect, GOLD, false, 4.0)
	_text("The Frontier", rect.get_center() + Vector2(0, 4), 44, Color(0.95, 0.78, 0.42))
	_text("Choose where to travel", rect.get_center() + Vector2(0, 66), 22, Color(1, 0.96, 0.88), true)


func _text(text: String, center: Vector2, font_size: int, color: Color, outline := false) -> void:
	var font := get_theme_default_font()
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := center + Vector2(-size.x / 2.0, font_size * 0.35)
	if outline:
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color(0, 0, 0, 0.8))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


# --- Hover card and buttons ---

func _build_ui() -> void:
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(380, 0)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_card.add_child(box)
	_card_title = Label.new()
	_card_title.add_theme_font_size_override("font_size", 28)
	_card_title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	box.add_child(_card_title)
	_card_text = Label.new()
	_card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_text.custom_minimum_size = Vector2(340, 0)
	_card_text.add_theme_font_size_override("font_size", 20)
	box.add_child(_card_text)
	_card_hint = Label.new()
	_card_hint.add_theme_font_size_override("font_size", 18)
	_card_hint.add_theme_color_override("font_color", Color(0.79, 0.73, 0.63))
	box.add_child(_card_hint)
	_card.hide()
	var back := Button.new()
	back.text = "🏰  Back to Ravenfall"
	back.add_theme_font_size_override("font_size", 24)
	back.custom_minimum_size = Vector2(300, 60)
	back.focus_mode = Control.FOCUS_NONE
	back.anchor_left = 1.0
	back.anchor_right = 1.0
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_left = -340
	back.offset_right = -40
	back.offset_top = -100
	back.offset_bottom = -40
	back.pressed.connect(func(): if not _travelling: _travel("ravenfall"))
	add_child(back)
