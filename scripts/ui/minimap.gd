extends Control
## Round minimap (top-left) that follows the hero. Rotated to match the
## isometric camera (up on the map = up on screen) and drawn from the live
## scene: town wall + gate, roads, plaza + fountain, park pond, every building
## in the "house" group (shops coloured and labelled). The hero is the arrow
## in the middle. A gold ring frames it with a small north marker.

const DIAMETER := 230.0
## World metres from the centre to the edge of the map.
const VIEW_RADIUS := 55.0
## World→screen axes for the isometric camera (yaw 45°).
const SCREEN_RIGHT := Vector2(0.70710678, -0.70710678)
const SCREEN_DOWN := Vector2(0.70710678, 0.70710678)
## Town north in map space (world -X).
const NORTH := Vector2(-0.70710678, -0.70710678)

const OUTSIDE := Color(0.42, 0.5, 0.32)
const GRASS := Color(0.58, 0.72, 0.42)
const WALL := Color(0.45, 0.4, 0.36)
const ROAD := Color(0.92, 0.86, 0.72)
const SQUARE := Color(0.95, 0.89, 0.76)
const WATER := Color(0.36, 0.64, 0.9)
const HOUSE := Color(0.72, 0.56, 0.46)
const GOLD := Color(0.93, 0.76, 0.36)
const GOLD_DARK := Color(0.55, 0.4, 0.16)
const PLAYER := Color(1.0, 0.97, 0.85)

## Building node name -> [label, colour]. Unlisted buildings draw as plain houses.
const SHOPS := {
	"GuildHall": ["Guild", Color(0.98, 0.8, 0.3)],
	"Church": ["Church", Color(0.78, 0.84, 1.0)],
	"Blacksmith": ["Smith", Color(1.0, 0.56, 0.28)],
	"Tavern": ["Tavern", Color(0.95, 0.42, 0.36)],
	"GeneralStore": ["Store", Color(0.45, 0.82, 0.52)],
	"MagicShop": ["Magic", Color(0.76, 0.56, 1.0)],
}

@export var player_path: NodePath

var _player: Node3D
var _scale := DIAMETER / 2.0 / VIEW_RADIUS
var _map: Control
## Map geometry in metres along the screen axes.
var _wall := PackedVector2Array()
var _gates: Array[Vector2] = []
var _roads: Array = []  # [PackedVector2Array, width in metres]
var _squares: Array[PackedVector2Array] = []
var _fountains: Array[Vector2] = []
var _ponds: Array[PackedVector2Array] = []
## Each: {"poly": PackedVector2Array, "center": Vector2, "label": String, "color": Color}
var _buildings: Array[Dictionary] = []
var _ready_to_draw := false


func _ready() -> void:
	position = Vector2(18, 18)
	size = Vector2.ONE * DIAMETER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = get_node_or_null(player_path)
	# Circle mask: everything drawn by its child is clipped to the disc.
	var mask := Control.new()
	mask.size = size
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	mask.draw.connect(func(): mask.draw_circle(size / 2.0, DIAMETER / 2.0 - 4.0, OUTSIDE))
	add_child(mask)
	_map = Control.new()
	_map.size = size
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.draw.connect(_draw_map)
	mask.add_child(_map)
	var frame := Control.new()
	frame.size = size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.draw.connect(_draw_frame.bind(frame))
	add_child(frame)
	# Buildings and roads build themselves in _ready / deferred calls first.
	_collect.call_deferred()


func _process(_delta: float) -> void:
	if _ready_to_draw:
		_map.queue_redraw()


static func _uv(world: Vector3) -> Vector2:
	var flat := Vector2(world.x, world.z)
	return Vector2(flat.dot(SCREEN_RIGHT), flat.dot(SCREEN_DOWN))


func _collect() -> void:
	var bounds := TownWall.BOUNDS
	for c in [Vector3(bounds.position.x, 0, bounds.position.y), Vector3(bounds.end.x, 0, bounds.position.y),
			Vector3(bounds.end.x, 0, bounds.end.y), Vector3(bounds.position.x, 0, bounds.end.y)]:
		_wall.append(_uv(c))
	for gate in TownWall.GATES:
		match gate[0]:
			"x+": _gates.append(_uv(Vector3(bounds.end.x, 0, gate[1])))
			"x-": _gates.append(_uv(Vector3(bounds.position.x, 0, gate[1])))
			"z+": _gates.append(_uv(Vector3(gate[1], 0, bounds.end.y)))
			"z-": _gates.append(_uv(Vector3(gate[1], 0, bounds.position.y)))
	for road in get_tree().get_nodes_in_group("roads"):
		var line := PackedVector2Array()
		for corner in road.corners:
			line.append(_uv(road.to_global(corner)))
		_roads.append([line, road.width])
	for square in get_tree().get_nodes_in_group("paved_area"):
		var h: float = square.SQUARE_HALF_SIZE
		var poly := PackedVector2Array()
		for c in [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)]:
			poly.append(_uv(square.to_global(c)))
		_squares.append(poly)
		_fountains.append(_uv(square.global_position))
	for park in get_tree().get_nodes_in_group("park"):
		var pond := PackedVector2Array()
		for i in 28:
			var a := TAU * i / 28.0
			pond.append(_uv(park.to_global(Vector3(cos(a) * Park.POND_RADII.x, 0, sin(a) * Park.POND_RADII.y))))
		_ponds.append(pond)
	for house: Node3D in get_tree().get_nodes_in_group("house"):
		var box := _local_bounds(house)
		var poly := PackedVector2Array()
		for c in [Vector3(box.position.x, 0, box.position.z), Vector3(box.end.x, 0, box.position.z),
				Vector3(box.end.x, 0, box.end.z), Vector3(box.position.x, 0, box.end.z)]:
			poly.append(_uv(house.to_global(c)))
		var shop: Array = SHOPS.get(String(house.name), ["", HOUSE])
		_buildings.append({"poly": poly, "center": _uv(house.to_global(box.get_center())), "label": shop[0], "color": shop[1]})
	_ready_to_draw = true


## Building bounds in its own local space (meshes only).
func _local_bounds(house: Node3D) -> AABB:
	var to_local := house.global_transform.affine_inverse()
	var bounds := AABB()
	for mesh in house.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = to_local * mesh.global_transform * mesh.get_aabb()
		bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
	return bounds


## Map contents, centred on the hero (drawn in metres via a canvas transform).
func _draw_map() -> void:
	if not _ready_to_draw or not _player:
		return
	var center := size / 2.0
	var hero := _uv(_player.global_position)
	_map.draw_set_transform(center - hero * _scale, 0.0, Vector2.ONE * _scale)
	_map.draw_colored_polygon(_wall, GRASS)
	for square in _squares:
		_map.draw_colored_polygon(square, SQUARE)
	for road in _roads:
		_map.draw_polyline(road[0], ROAD, road[1])
	for pond in _ponds:
		_map.draw_colored_polygon(pond, WATER)
	for fountain in _fountains:
		_map.draw_circle(fountain, 3.0, WATER)
	for building in _buildings:
		var shadow: PackedVector2Array = building.poly.duplicate()
		for i in shadow.size():
			shadow[i] += Vector2(0.9, 1.2)
		_map.draw_colored_polygon(shadow, Color(0, 0, 0, 0.25))
		_map.draw_colored_polygon(building.poly, building.color)
	var outline := _wall.duplicate()
	outline.append(_wall[0])
	_map.draw_polyline(outline, WALL, 2.2)
	for gate in _gates:
		_map.draw_circle(gate, 2.6, GOLD)
	_map.draw_set_transform(Vector2.ZERO)
	var font := get_theme_default_font()
	for building in _buildings:
		if building.label == "":
			continue
		var at: Vector2 = center + (building.center - hero) * _scale
		if at.distance_to(center) < DIAMETER / 2.0 - 18.0:
			_label(font, building.label, at)


## Gold ring, north tab and the hero arrow (drawn above the clipped map).
func _draw_frame(frame: Control) -> void:
	var center := size / 2.0
	var radius := DIAMETER / 2.0
	frame.draw_arc(center, radius - 4.0, 0.0, TAU, 96, GOLD_DARK, 9.0, true)
	frame.draw_arc(center, radius - 4.0, 0.0, TAU, 96, GOLD, 5.0, true)
	frame.draw_arc(center, radius - 9.5, 0.0, TAU, 96, Color(0, 0, 0, 0.35), 2.0, true)
	var tab := center + NORTH * (radius - 4.0)
	frame.draw_circle(tab, 12.0, GOLD_DARK)
	frame.draw_circle(tab, 10.0, Color(0.78, 0.18, 0.16))
	var font := get_theme_default_font()
	var text_size := font.get_string_size("N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	frame.draw_string(font, tab + Vector2(-text_size.x / 2.0, 5.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	_draw_player(frame, center)
	frame.queue_redraw()


## Arrow pointing the way the hero faces.
func _draw_player(canvas: Control, at: Vector2) -> void:
	if not _player:
		return
	var yaw := _player.rotation.y
	var ahead := _uv(Vector3(sin(yaw), 0, cos(yaw)))
	ahead = ahead.normalized() if ahead.length() > 0.001 else Vector2.UP
	var side := Vector2(-ahead.y, ahead.x)
	var arrow := PackedVector2Array([at + ahead * 11.0, at - ahead * 6.0 + side * 7.5, at - ahead * 2.5, at - ahead * 6.0 - side * 7.5])
	canvas.draw_circle(at, 12.0, Color(0, 0, 0, 0.3))
	canvas.draw_colored_polygon(arrow, PLAYER)
	arrow.append(arrow[0])
	canvas.draw_polyline(arrow, Color(0.15, 0.1, 0.05), 1.6, true)


func _label(font: Font, text: String, at: Vector2) -> void:
	var font_size := 13
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at + Vector2(-width / 2.0, font_size * 0.35)
	_map.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0.1, 0.08, 0.05, 0.9))
	_map.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
