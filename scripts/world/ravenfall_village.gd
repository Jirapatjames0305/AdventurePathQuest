class_name RavenfallVillage
extends Node3D
## Builds Ravenfall from KayKit Medieval Hexagon tiles (CC0) using a data layout.
## Tiles use pointy-top axial coords (q, r); the hex pack is scaled ×2.5 so
## one tile is 5 units across and buildings sit at chibi-hero scale.

const ASSET_PATH := "res://assets/environments/kaykit_medieval/%s.gltf"
const WORLD_SCALE := 2.5
## Circumradius of one scaled tile (pack tile is 1.155 from center to point).
const HEX_SIZE := 1.155 * WORLD_SCALE

## How many rings of ground to lay (beyond the walkable area so edges stay hidden).
const GROUND_RINGS := 6
## The player can walk this far from the town center.
const WALK_RADIUS := 16.0
const WALL_SEGMENTS := 24
## Turns the whole town so the Blackwood road points straight up the screen
## (the hex road axis is 15° off the isometric camera's "up").
const ROAD_ALIGN_DEGREES := 15.0

## Road from the town square (0, 0) out to Blackwood, toward the top of the screen.
## Each entry: [q, r, tile, y rotation in degrees].
const ROADS := [
	[0, 0, "hex_road_M", -60.0],
	[0, -1, "hex_road_A", -60.0],
	[0, -2, "hex_road_A", -60.0],
	[0, -3, "hex_road_A", -60.0],
	[0, -4, "hex_road_A", -60.0],
	[0, -5, "hex_road_A", -60.0],
	[0, -6, "hex_road_A", -60.0],
]


func _ready() -> void:
	rotation_degrees.y = ROAD_ALIGN_DEGREES
	_build_ground()
	_build_walls()


static func axial_to_world(q: int, r: int) -> Vector3:
	return Vector3(sqrt(3.0) * HEX_SIZE * (q + r / 2.0), 0.0, 1.5 * HEX_SIZE * r)


static func hex_distance(q: int, r: int) -> int:
	return (absi(q) + absi(r) + absi(q + r)) / 2


func _place(asset: String, q: int, r: int, rotation_deg := 0.0) -> Node3D:
	var node: Node3D = load(ASSET_PATH % asset).instantiate()
	node.position = axial_to_world(q, r)
	node.rotation_degrees.y = rotation_deg
	node.scale = Vector3.ONE * WORLD_SCALE
	add_child(node)
	return node


func _build_ground() -> void:
	var roads := {}
	for road in ROADS:
		roads[Vector2i(road[0], road[1])] = road
	for q in range(-GROUND_RINGS, GROUND_RINGS + 1):
		for r in range(-GROUND_RINGS, GROUND_RINGS + 1):
			if hex_distance(q, r) > GROUND_RINGS:
				continue
			var road: Array = roads.get(Vector2i(q, r), [])
			if road.is_empty():
				_place("hex_grass", q, r)
			else:
				_place(road[2], q, r, road[3])


## Invisible ring of walls so the hero can't walk off the edge of town.
func _build_walls() -> void:
	var body := StaticBody3D.new()
	body.name = "TownWalls"
	add_child(body)
	var segment_length := TAU * WALK_RADIUS / WALL_SEGMENTS * 1.1
	for i in WALL_SEGMENTS:
		var angle := TAU * i / WALL_SEGMENTS
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(segment_length, 4.0, 1.0)
		shape.shape = box
		shape.position = Vector3(cos(angle), 0.0, sin(angle)) * WALK_RADIUS + Vector3.UP * 2.0
		shape.rotation.y = -angle + PI / 2.0
		body.add_child(shape)
