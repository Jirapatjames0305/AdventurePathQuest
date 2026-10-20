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
## Hex-pack props (barrels, crates…) are modelled at map scale; this makes
## them hero-sized.
const PROP_SCALE := 6.0
## The pack's grass is quite yellow under warm light; tint ground tiles greener.
const GRASS_TINT := Color(0.72, 0.95, 0.62)
## Road tiles get a milder tint so the dirt path keeps its sandy colour.
const ROAD_TINT := Color(0.9, 0.98, 0.84)
## Fixed seed so the scattered nature looks the same every visit.
const NATURE_SEED := 20261020
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

## Ravenfall locations (README §9). Each entry: [q, r, model, collision radius].
## Buildings turn to face the town square.
const BUILDINGS := [
	[1, -1, "building_tavern_red", 1.6],      # Rest
	[-1, 0, "building_market_red", 1.6],      # Potion Shop
	[1, 0, "building_blacksmith_red", 1.6],   # Blacksmith
	[0, 1, "building_well_red", 0.9],         # Town Square well
	[-1, 1, "building_home_A_red", 1.4],
	[-2, 0, "building_church_red", 1.6],      # Old Chapel
	[2, 1, "building_destroyed", 1.4],        # Abandoned House
	[-2, 2, "building_home_B_red", 1.4],
	[1, 1, "building_home_A_red", 1.4],
	[2, -2, "building_windmill_red", 1.6],
]

## Nature by ring (distance from the square). Ring 3 is the walkable edge,
## rings 4–6 frame the town and hide the island's edge.
const EDGE_SCATTER := ["tree_single_A", "tree_single_B", "rock_single_A", "rock_single_B", "rock_single_C"]
const EDGE_SCATTER_CHANCE := 0.45
const EDGE_SCATTER_RADIUS := 0.7
const FOREST := ["trees_A_large", "trees_A_medium", "trees_B_large", "trees_B_medium"]
const HILLS := ["hills_A_trees", "hills_B_trees", "hills_C_trees", "trees_B_large"]
const MOUNTAINS := ["mountain_A_grass_trees", "mountain_B_grass_trees", "mountain_C_grass_trees"]

## Hand-placed props. Each entry: [q, r, model, offset (x, z) from tile center, y rotation°].
const PROPS := [
	[1, -1, "barrel", Vector2(-2.2, 1.4), 0.0],        # Tavern
	[1, -1, "barrel", Vector2(-1.6, 2.0), 40.0],
	[1, -1, "flag_red", Vector2(2.0, 1.8), 0.0],
	[-1, 0, "crate_A_big", Vector2(2.2, 1.2), 15.0],   # Market
	[-1, 0, "crate_B_small", Vector2(2.4, 0.2), 60.0],
	[-1, 0, "sack", Vector2(1.6, 2.0), 0.0],
	[1, 0, "weaponrack", Vector2(-2.0, -1.0), -60.0],  # Blacksmith
	[0, 1, "bucket_water", Vector2(1.4, -0.6), 0.0],   # Well
	[2, -2, "wheelbarrow", Vector2(-2.0, 1.2), 120.0], # Windmill
	[2, -2, "sack", Vector2(-1.2, 2.0), 0.0],
	[0, -2, "flag_red", Vector2(-1.8, 0.0), 0.0],      # Road to Blackwood
	[0, -2, "flag_red", Vector2(1.8, 0.0), 0.0],
]


func _ready() -> void:
	rotation_degrees.y = ROAD_ALIGN_DEGREES
	_build_ground()
	_build_buildings()
	_build_nature()
	_build_props()
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
	var grass_material: Material = null
	var road_material: Material = null
	var roads := {}
	for road in ROADS:
		roads[Vector2i(road[0], road[1])] = road
	for q in range(-GROUND_RINGS, GROUND_RINGS + 1):
		for r in range(-GROUND_RINGS, GROUND_RINGS + 1):
			if hex_distance(q, r) > GROUND_RINGS:
				continue
			var road: Array = roads.get(Vector2i(q, r), [])
			var tile := _place("hex_grass", q, r) if road.is_empty() else _place(road[2], q, r, road[3])
			var mesh: MeshInstance3D = tile.find_children("*", "MeshInstance3D")[0]
			if not grass_material:
				grass_material = mesh.mesh.surface_get_material(0).duplicate()
				grass_material.albedo_color = GRASS_TINT
				road_material = grass_material.duplicate()
				road_material.albedo_color = ROAD_TINT
			mesh.material_override = grass_material if road.is_empty() else road_material


func _build_buildings() -> void:
	var body := StaticBody3D.new()
	body.name = "BuildingColliders"
	add_child(body)
	for building in BUILDINGS:
		var node := _place(building[2], building[0], building[1])
		var to_square := -node.position
		node.rotation.y = atan2(to_square.x, to_square.z)
		_add_cylinder_collider(body, node.position, building[3])


func _build_nature() -> void:
	var body := StaticBody3D.new()
	body.name = "NatureColliders"
	add_child(body)
	var rng := RandomNumberGenerator.new()
	rng.seed = NATURE_SEED
	var blocked := {}
	for road in ROADS:
		blocked[Vector2i(road[0], road[1])] = true
	for q in range(-GROUND_RINGS, GROUND_RINGS + 1):
		for r in range(-GROUND_RINGS, GROUND_RINGS + 1):
			var ring := hex_distance(q, r)
			if ring < 3 or ring > GROUND_RINGS or blocked.has(Vector2i(q, r)):
				continue
			var spin := rng.randi_range(0, 5) * 60.0
			match ring:
				3:
					if rng.randf() < EDGE_SCATTER_CHANCE:
						var node := _place(EDGE_SCATTER[rng.randi() % EDGE_SCATTER.size()], q, r, spin)
						node.position += Vector3(rng.randf_range(-1.5, 1.5), 0.0, rng.randf_range(-1.5, 1.5))
						_add_cylinder_collider(body, node.position, EDGE_SCATTER_RADIUS)
				4:
					_place(FOREST[rng.randi() % FOREST.size()], q, r, spin)
				5:
					_place(HILLS[rng.randi() % HILLS.size()], q, r, spin)
				_:
					_place(MOUNTAINS[rng.randi() % MOUNTAINS.size()], q, r, spin)


func _build_props() -> void:
	for prop in PROPS:
		var node := _place(prop[2], prop[0], prop[1], prop[4])
		node.position += Vector3(prop[3].x, 0.0, prop[3].y)
		node.scale = Vector3.ONE * PROP_SCALE


func _add_cylinder_collider(body: StaticBody3D, at: Vector3, radius: float) -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 4.0
	shape.shape = cylinder
	shape.position = at + Vector3.UP * 2.0
	body.add_child(shape)


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
