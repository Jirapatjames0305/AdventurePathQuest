extends Control
## Round minimap (top-left) showing the whole walled town — or, once the hero
## walks out of the gate, the whole forest beyond it with its monster camps. Rotated to match the
## isometric camera (up on the map = up on screen) and drawn from the live
## scene: town wall + gate, roads, plaza + fountain, park pond, every building
## in the "house" group (shops coloured and labelled). The hero is an arrow
## moving over the map. A gold ring frames it with a small north marker.

const DIAMETER := 230.0
## Empty space (pixels) between the town's corners and the gold ring.
const FIT_MARGIN := 14.0
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
## Tree dots by TreeFactory.Kind (leafy, pine, blossom) and their radius in metres.
const TREE_COLORS := [Color(0.27, 0.5, 0.22), Color(0.16, 0.36, 0.2), Color(0.96, 0.66, 0.76)]
const TREE_RADIUS := 1.6
const FOREST := Color(0.3, 0.44, 0.26)
const DIRT := Color(0.66, 0.54, 0.38)
const CAMP := Color(0.95, 0.35, 0.3)
const BOSS := Color(0.75, 0.15, 0.55)

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
var _scale := 1.0
## Map-space point shown at the centre of the disc (the town's centre).
var _focus := Vector2.ZERO
## [focus, scale] fitting the town and the forest; _focus/_scale ease between them.
var _town_view := []
var _forest_view := []
var _forest := PackedVector2Array()
var _trails: Array = []  # [Vector2, Vector2] map space
## Each: {"at": Vector2, "label": String, "boss": bool}
var _camps: Array[Dictionary] = []
var _map: Control
## The hero arrow on its own layer, so the (static) map only redraws when the view moves.
var _marker: Control
## Map geometry in metres along the screen axes.
var _wall := PackedVector2Array()
var _gates: Array[Vector2] = []
var _roads: Array = []  # [PackedVector2Array, width in metres]
var _squares: Array[PackedVector2Array] = []
var _fountains: Array[Vector2] = []
var _ponds: Array[PackedVector2Array] = []
var _trees: Array = []  # [map position, TreeFactory.Kind]
## Each: {"poly": PackedVector2Array, "center": Vector2, "label": String, "color": Color}
var _buildings: Array[Dictionary] = []
var _ready_to_draw := false
var _drawn := false


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
	_marker = Control.new()
	_marker.size = size
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.draw.connect(func(): _draw_player(_marker, size / 2.0 + (_uv(_player.global_position) - _focus) * _scale) if _player and _ready_to_draw else null)
	mask.add_child(_marker)
	var frame := Control.new()
	frame.size = size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.draw.connect(_draw_frame.bind(frame))
	add_child(frame)
	# Buildings and roads build themselves in _ready / deferred calls first.
	_collect.call_deferred()


func _process(delta: float) -> void:
	if not _ready_to_draw:
		return
	var outside := _player != null and not _forest_view.is_empty() and _player.global_position.x > TownWall.BOUNDS.end.x + 2.0
	var view: Array = _forest_view if outside else _town_view
	var k := 1.0 - exp(-delta * 6.0)
	var focus: Vector2 = _focus.lerp(view[0], k)
	var zoom := lerpf(_scale, view[1], k)
	if focus.distance_to(_focus) > 0.01 or absf(zoom - _scale) > 0.0001 or not _drawn:
		_focus = focus
		_scale = zoom
		_drawn = true
		_map.queue_redraw()
	_marker.queue_redraw()


## [focus, scale] that fits a world-space rectangle inside the disc.
func _fit(rect: Rect2) -> Array:
	var focus := _uv(Vector3(rect.get_center().x, 0, rect.get_center().y))
	var reach := 0.0
	for c in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		reach = maxf(reach, _uv(Vector3(c.x, 0, c.y)).distance_to(focus))
	return [focus, (DIAMETER / 2.0 - FIT_MARGIN) / reach]


static func _uv(world: Vector3) -> Vector2:
	var flat := Vector2(world.x, world.z)
	return Vector2(flat.dot(SCREEN_RIGHT), flat.dot(SCREEN_DOWN))


func _collect() -> void:
	var bounds := TownWall.BOUNDS
	for c in [Vector3(bounds.position.x, 0, bounds.position.y), Vector3(bounds.end.x, 0, bounds.position.y),
			Vector3(bounds.end.x, 0, bounds.end.y), Vector3(bounds.position.x, 0, bounds.end.y)]:
		_wall.append(_uv(c))
	# Fit the whole town inside the disc.
	_town_view = _fit(bounds)
	_focus = _town_view[0]
	_scale = _town_view[1]
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
	for forest in get_tree().get_nodes_in_group("forest_region"):
		var r: Rect2 = forest.BOUNDS
		_forest_view = _fit(r.grow_individual(-2, 2, 2, 2))
		for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			_forest.append(_uv(Vector3(c.x, 0, c.y)))
		for seg in forest.trails:
			_trails.append([_uv(Vector3(seg[0].x, 0, seg[0].y)), _uv(Vector3(seg[1].x, 0, seg[1].y))])
		for camp in forest.camps:
			var enemy: EnemyData = camp.enemy
			_camps.append({"at": _uv(camp.center), "label": enemy.display_name, "boss": enemy.model == "alpha"})
	for source in get_tree().get_nodes_in_group("tree_source"):
		for tree in source.trees:
			_trees.append([_uv(tree[0]), tree[1]])
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


## Map contents, centred on the town (drawn in metres via a canvas transform).
func _draw_map() -> void:
	if not _ready_to_draw:
		return
	var center := size / 2.0
	_map.draw_set_transform(center - _focus * _scale, 0.0, Vector2.ONE * _scale)
	if not _forest.is_empty():
		_map.draw_colored_polygon(_forest, FOREST)
	for trail in _trails:
		_map.draw_line(trail[0], trail[1], DIRT, 3.0)
	_map.draw_colored_polygon(_wall, GRASS)
	for square in _squares:
		_map.draw_colored_polygon(square, SQUARE)
	for road in _roads:
		_map.draw_polyline(road[0], ROAD, road[1])
	for pond in _ponds:
		_map.draw_colored_polygon(pond, WATER)
	for fountain in _fountains:
		_map.draw_circle(fountain, 3.0, WATER)
	for tree in _trees:
		_map.draw_circle(tree[0] + Vector2(0.4, 0.6), TREE_RADIUS, Color(0, 0, 0, 0.22))
	for tree in _trees:
		_map.draw_circle(tree[0], TREE_RADIUS * (0.8 if tree[1] == TreeFactory.Kind.PINE else 1.0), TREE_COLORS[tree[1]])
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
	for camp in _camps:
		var r := 7.0 if camp.boss else 4.5
		_map.draw_circle(camp.at, r + 1.2, Color(0.1, 0.05, 0.05, 0.8))
		_map.draw_circle(camp.at, r, BOSS if camp.boss else CAMP)
	_map.draw_set_transform(Vector2.ZERO)
	var font := get_theme_default_font()
	for building in _buildings:
		if building.label == "":
			continue
		_label(font, building.label, center + (building.center - _focus) * _scale)
	for camp in _camps:
		if camp.boss:
			_label(font, "Lair", center + (camp.at - _focus) * _scale + Vector2(0, -13))


## Gold ring and north tab (drawn above the clipped map).
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


## Arrow pointing the way the hero faces.
func _draw_player(canvas: Control, at: Vector2) -> void:
	if not _player:
		return
	var yaw := _player.rotation.y
	var ahead := _uv(Vector3(sin(yaw), 0, cos(yaw)))
	ahead = ahead.normalized() if ahead.length() > 0.001 else Vector2.UP
	var side := Vector2(-ahead.y, ahead.x)
	var arrow := PackedVector2Array([at + ahead * 9.0, at - ahead * 5.0 + side * 6.0, at - ahead * 2.0, at - ahead * 5.0 - side * 6.0])
	canvas.draw_circle(at, 10.0, Color(0, 0, 0, 0.3))
	canvas.draw_colored_polygon(arrow, PLAYER)
	arrow.append(arrow[0])
	canvas.draw_polyline(arrow, Color(0.15, 0.1, 0.05), 1.6, true)


func _label(font: Font, text: String, at: Vector2) -> void:
	var font_size := 11
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := at + Vector2(-width / 2.0, font_size * 0.35)
	_map.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0.1, 0.08, 0.05, 0.9))
	_map.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
