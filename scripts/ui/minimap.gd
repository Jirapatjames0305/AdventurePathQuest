extends Control
## Top-left minimap. Rotated to match the isometric camera (up on the map =
## up on screen) and drawn from the live scene: town wall + gate, roads,
## plaza square + fountain, park pond, every building in the "house" group
## (shops labelled), and the hero as an arrow showing where they face.

const SIZE := Vector2(380, 380)
const MARGIN := 14.0
## World→screen axes for the isometric camera (yaw 45°).
const SCREEN_RIGHT := Vector2(0.70710678, -0.70710678)
const SCREEN_DOWN := Vector2(0.70710678, 0.70710678)

const BG := Color(0.13, 0.16, 0.12, 0.82)
const BORDER := Color(0.85, 0.72, 0.42)
const GRASS := Color(0.36, 0.52, 0.28)
const WALL := Color(0.62, 0.58, 0.52)
const ROAD := Color(0.72, 0.66, 0.56)
const SQUARE := Color(0.8, 0.72, 0.6)
const WATER := Color(0.35, 0.6, 0.88)
const HOUSE := Color(0.62, 0.55, 0.5)
const PLAYER := Color(1.0, 0.95, 0.3)

## Building node name -> [label, colour]. Unlisted buildings draw as plain houses.
const SHOPS := {
	"GuildHall": ["Guild", Color(0.95, 0.78, 0.3)],
	"Church": ["Church", Color(0.8, 0.85, 1.0)],
	"Blacksmith": ["Smith", Color(1.0, 0.55, 0.25)],
	"Tavern": ["Tavern", Color(0.95, 0.45, 0.35)],
	"GeneralStore": ["Store", Color(0.45, 0.8, 0.5)],
	"MagicShop": ["Magic", Color(0.75, 0.55, 1.0)],
}

@export var player_path: NodePath

var _player: Node3D
var _scale := 1.0
var _offset := Vector2.ZERO
var _wall := PackedVector2Array()
var _gates: Array[Vector2] = []
var _roads: Array = []  # [PackedVector2Array, width]
var _squares: Array[PackedVector2Array] = []
var _fountains: Array[Vector2] = []
var _ponds: Array[PackedVector2Array] = []
## Each: {"poly": PackedVector2Array, "center": Vector2, "label": String, "color": Color}
var _buildings: Array[Dictionary] = []
var _ready_to_draw := false


func _ready() -> void:
	position = Vector2(20, 20)
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = get_node_or_null(player_path)
	# Buildings and roads build themselves in _ready / deferred calls first.
	_collect.call_deferred()


func _process(_delta: float) -> void:
	if _ready_to_draw:
		queue_redraw()


func _to_map(world: Vector3) -> Vector2:
	var flat := Vector2(world.x, world.z)
	return _offset + Vector2(flat.dot(SCREEN_RIGHT), flat.dot(SCREEN_DOWN)) * _scale


func _collect() -> void:
	var bounds := TownWall.BOUNDS
	var corners := [
		Vector3(bounds.position.x, 0, bounds.position.y), Vector3(bounds.end.x, 0, bounds.position.y),
		Vector3(bounds.end.x, 0, bounds.end.y), Vector3(bounds.position.x, 0, bounds.end.y),
	]
	# Fit the walled town into the panel.
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in corners:
		var p := Vector2(Vector2(c.x, c.z).dot(SCREEN_RIGHT), Vector2(c.x, c.z).dot(SCREEN_DOWN))
		lo = lo.min(p)
		hi = hi.max(p)
	_scale = (SIZE.x - MARGIN * 2.0) / maxf(hi.x - lo.x, hi.y - lo.y)
	_offset = SIZE / 2.0 - (lo + hi) / 2.0 * _scale
	for c in corners:
		_wall.append(_to_map(c))
	for gate in TownWall.GATES:
		match gate[0]:
			"x+": _gates.append(_to_map(Vector3(bounds.end.x, 0, gate[1])))
			"x-": _gates.append(_to_map(Vector3(bounds.position.x, 0, gate[1])))
			"z+": _gates.append(_to_map(Vector3(gate[1], 0, bounds.end.y)))
			"z-": _gates.append(_to_map(Vector3(gate[1], 0, bounds.position.y)))

	for road in get_tree().get_nodes_in_group("roads"):
		var line := PackedVector2Array()
		for corner in road.corners:
			line.append(_to_map(road.to_global(corner)))
		_roads.append([line, maxf(road.width * _scale, 1.5)])

	for square in get_tree().get_nodes_in_group("paved_area"):
		var h: float = square.SQUARE_HALF_SIZE
		var poly := PackedVector2Array()
		for c in [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)]:
			poly.append(_to_map(square.to_global(c)))
		_squares.append(poly)
		_fountains.append(_to_map(square.global_position))

	for park in get_tree().get_nodes_in_group("park"):
		var pond := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pond.append(_to_map(park.to_global(Vector3(cos(a) * Park.POND_RADII.x, 0, sin(a) * Park.POND_RADII.y))))
		_ponds.append(pond)

	for house: Node3D in get_tree().get_nodes_in_group("house"):
		var box := _local_bounds(house)
		var poly := PackedVector2Array()
		for c in [Vector3(box.position.x, 0, box.position.z), Vector3(box.end.x, 0, box.position.z),
				Vector3(box.end.x, 0, box.end.z), Vector3(box.position.x, 0, box.end.z)]:
			poly.append(_to_map(house.to_global(c)))
		var shop: Array = SHOPS.get(String(house.name), ["", HOUSE])
		_buildings.append({
			"poly": poly,
			"center": _to_map(house.to_global(box.get_center())),
			"label": shop[0],
			"color": shop[1],
		})
	_ready_to_draw = true


## Building bounds in its own local space (meshes only).
func _local_bounds(house: Node3D) -> AABB:
	var to_local := house.global_transform.affine_inverse()
	var bounds := AABB()
	for mesh in house.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = to_local * mesh.global_transform * mesh.get_aabb()
		bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
	return bounds


func _draw() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = BG
	panel.border_color = BORDER
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(10)
	draw_style_box(panel, Rect2(Vector2.ZERO, SIZE))
	if not _ready_to_draw:
		return
	draw_colored_polygon(_wall, GRASS)
	for square in _squares:
		draw_colored_polygon(square, SQUARE)
	for road in _roads:
		draw_polyline(road[0], ROAD, road[1])
	for pond in _ponds:
		draw_colored_polygon(pond, WATER)
	for fountain in _fountains:
		draw_circle(fountain, 4.0, WATER)
	var closed := _wall.duplicate()
	closed.append(_wall[0])
	draw_polyline(closed, WALL, 3.0)
	for gate in _gates:
		draw_circle(gate, 4.5, BORDER)
	for building in _buildings:
		draw_colored_polygon(building.poly, building.color)
		var outline: PackedVector2Array = building.poly.duplicate()
		outline.append(building.poly[0])
		draw_polyline(outline, Color(0, 0, 0, 0.45), 1.0)
	var font := get_theme_default_font()
	for building in _buildings:
		if building.label != "":
			_label(font, building.label, building.center)
	_draw_player()
	_label(font, "Ravenfall", Vector2(SIZE.x / 2.0, 20), 18)


func _label(font: Font, text: String, at: Vector2, font_size := 16) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at + Vector2(-width / 2.0, font_size * 0.35)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## Arrow at the hero's position pointing along their facing direction.
func _draw_player() -> void:
	if not _player:
		return
	var at := _to_map(_player.global_position)
	var yaw := _player.rotation.y
	var ahead := _to_map(_player.global_position + Vector3(sin(yaw), 0, cos(yaw))) - at
	ahead = ahead.normalized() if ahead.length() > 0.001 else Vector2.UP
	var side := Vector2(-ahead.y, ahead.x)
	var tip := at + ahead * 13.0
	var arrow := PackedVector2Array([tip, at - ahead * 7.0 + side * 9.0, at - ahead * 3.0, at - ahead * 7.0 - side * 9.0])
	draw_circle(at, 13.0, Color(0, 0, 0, 0.35))
	draw_colored_polygon(arrow, PLAYER)
	arrow.append(tip)
	draw_polyline(arrow, Color(0, 0, 0, 0.8), 1.5)
