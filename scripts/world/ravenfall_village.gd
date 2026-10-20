class_name RavenfallVillage
extends Node3D
## Builds Ravenfall from KayKit Medieval Hexagon tiles (CC0) using a data layout.
## Visual target: docs/reference/ravenfall_golden_town.png — a walled town with a
## paved plaza, main street to a manor, cathedral, river and fields outside.
## Tiles use pointy-top axial coords (q, r); the hex pack is scaled ×2.5 so
## one tile is 5 units across and buildings sit at chibi-hero scale.
## Screen directions (after ROAD_ALIGN): (0, -1) = up, (0, 1) = down,
## (1, 0) = right-down, (1, -1) = right-up, (-1, 0) = left-up, (-1, 1) = left-down.

const ASSET_PATH := "res://assets/environments/kaykit_medieval/%s.gltf"
const WORLD_SCALE := 2.5
## Circumradius of one scaled tile (pack tile is 1.155 from center to point).
const HEX_SIZE := 1.155 * WORLD_SCALE
## Turns the whole town so the main street runs straight up/down the screen
## (the hex axis is 15° off the isometric camera's "up").
const ROAD_ALIGN_DEGREES := 15.0

## The town wall sits on this ring; everything inside is walkable town.
const WALL_RING := 6
## Ground is laid this far out so the camera never sees the island's edge.
const GROUND_RINGS := 10
## Invisible boundary just inside the wall (its sides are ~26 units out).
const WALK_RADIUS := 24.5
const WALL_SEGMENTS := 32

## Buildings are drawn larger than map scale so the town feels dense like the
## reference (colliders scale with them).
const BUILDING_SCALE := 1.5
## Hex-pack props (barrels, crates…) are modelled at map scale; this makes
## them hero-sized.
const PROP_SCALE := 6.0
## The pack's grass is quite yellow under warm light; tint ground tiles greener.
const GRASS_TINT := Color(0.72, 0.95, 0.62)
## Road tiles get a milder tint so the dirt path keeps its sandy colour.
const ROAD_TINT := Color(0.9, 0.98, 0.84)
## Plaza and main street are paved with plain stone-coloured tiles.
const PAVING_COLOR := Color(0.78, 0.72, 0.62)
## Fixed seed so the scattered nature looks the same every visit.
const NATURE_SEED := 20261020

## Axial neighbour directions; index k points at world angle -60°·k.
const DIRS := [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

## Main street: paved from the manor (top) through the plaza to the gate (bottom).
const STREET_FROM := -3
const STREET_TO := 5
## Dirt road outside the gate, crossing the river on a bridge tile.
const OUTER_ROAD_TO := GROUND_RINGS
const RIVER_ROW := 8

## Each entry: [q, r, model, collision radius, scale multiplier].
## Buildings turn to face the plaza.
const BUILDINGS := [
	[0, 0, "building_well_blue", 1.0, 1.0],          # Plaza fountain (well)
	[0, -4, "building_castle_blue", 2.2, 0.8],       # Manor / town hall
	[3, -4, "building_church_blue", 1.6, 1.2],       # Cathedral (Old Chapel)
	[-3, 1, "building_tavern_blue", 1.6, 1.0],       # Tavern — Rest
	[-3, -1, "building_blacksmith_blue", 1.6, 1.0],  # Blacksmith
	[2, 0, "building_market_blue", 1.6, 1.0],        # Market — Potion Shop
	[-2, 4, "building_tower_A_blue", 1.4, 1.0],      # Mage tower
	[3, 2, "building_barracks_blue", 2.2, 1.0],      # Gate barracks
	[-5, 4, "building_destroyed", 1.4, 1.0],         # Abandoned House
	[-1, -3, "building_home_A_blue", 1.4, 1.0],
	[1, -3, "building_home_B_blue", 1.4, 1.0],
	[-2, -2, "building_home_B_blue", 1.4, 1.0],
	[2, -3, "building_home_A_blue", 1.4, 1.0],
	[4, -1, "building_home_B_blue", 1.4, 1.0],
	[-4, 0, "building_home_B_blue", 1.4, 1.0],
	[-4, 3, "building_home_A_blue", 1.4, 1.0],
	[-1, 4, "building_home_B_blue", 1.4, 1.0],
	[1, 4, "building_home_A_blue", 1.4, 1.0],
	[4, -3, "building_home_A_blue", 1.4, 1.0],
	[-5, 1, "building_home_A_blue", 1.4, 1.0],
	[-3, -2, "building_home_A_blue", 1.4, 1.0],
	[-2, -3, "building_home_B_blue", 1.4, 1.0],
	[3, -5, "building_home_B_blue", 1.4, 1.0],
	[5, -4, "building_home_A_blue", 1.4, 1.0],
	[5, -2, "building_home_B_blue", 1.4, 1.0],
	[4, 1, "building_home_A_blue", 1.4, 1.0],
	[2, 1, "building_home_B_blue", 1.4, 1.0],
	[-2, 3, "building_home_B_blue", 1.4, 1.0],
	[-3, 5, "building_home_A_blue", 1.4, 1.0],
	[-4, 1, "building_home_A_blue", 1.4, 1.0],
]

## Garden pond tiles inside the walls.
const PONDS := [Vector2i(3, 0), Vector2i(4, 0)]
## Wheat fields + windmill outside the walls, top-right like the reference.
const FIELDS := [Vector2i(3, -8), Vector2i(4, -8), Vector2i(3, -9), Vector2i(4, -9), Vector2i(2, -8)]
const WINDMILL := Vector2i(5, -9)

## Single trees inside the walls (with colliders). [q, r, offset (x, z)].
const GARDEN_TREES := [
	[-2, 2, Vector2(0.0, 0.0)], [2, -2, Vector2(0.5, 0.5)], [-3, 3, Vector2(-1.0, 0.5)],
	[1, 2, Vector2(1.0, 0.0)], [3, -2, Vector2(-1.0, 1.0)], [-2, 0, Vector2(-1.5, 0.0)],
	[4, -2, Vector2(1.0, -0.5)], [-5, 2, Vector2(0.0, 0.0)], [2, 2, Vector2(-0.5, 0.5)],
	[5, -3, Vector2(0.0, 0.0)], [-4, 5, Vector2(1.0, 0.0)], [-1, 2, Vector2(-1.0, -1.0)],
	[3, -3, Vector2(0.0, 0.0)], [-4, 4, Vector2(0.0, 0.0)], [3, 1, Vector2(0.5, 0.5)],
	[-1, 3, Vector2(0.0, 0.0)], [1, 3, Vector2(0.0, 0.0)], [2, -4, Vector2(0.0, 0.0)],
]
const GARDEN_TREE_MODELS := ["tree_single_A", "tree_single_B"]
const TREE_RADIUS := 0.7

## Nature outside the walls, by ring.
const OUTSKIRT_SCATTER := ["tree_single_A", "tree_single_B", "rock_single_A", "rock_single_B", "rock_single_C"]
const OUTSKIRT_SCATTER_CHANCE := 0.5
const FOREST := ["trees_A_large", "trees_A_medium", "trees_B_large", "trees_B_medium"]
const HILLS := ["hills_A_trees", "hills_B_trees", "hills_C_trees", "trees_B_large"]

## Hand-placed props. Each entry: [q, r, model, offset (x, z) from tile center, y rotation°].
const PROPS := [
	# Market stalls around the plaza
	[1, -1, "tent", Vector2(-0.5, 0.0), 0.0],
	[1, -1, "crate_A_big", Vector2(1.6, 1.0), 20.0],
	[1, 0, "tent", Vector2(0.0, -0.5), 30.0],
	[1, 0, "sack", Vector2(1.6, 1.0), 0.0],
	[-1, 0, "tent", Vector2(0.5, 0.0), -20.0],
	[-1, 0, "barrel", Vector2(-1.4, 1.2), 0.0],
	[-1, 1, "tent", Vector2(0.0, 0.5), 10.0],
	[-1, 1, "crate_B_small", Vector2(1.4, -0.8), 45.0],
	# Tavern
	[-3, 1, "barrel", Vector2(2.2, 1.0), 0.0],
	[-3, 1, "barrel", Vector2(2.4, 1.8), 40.0],
	# Blacksmith
	[-3, -1, "weaponrack", Vector2(2.2, 0.5), -60.0],
	# Market
	[2, 0, "crate_A_big", Vector2(-2.0, -1.0), 15.0],
	# Banners along the main street
	[0, 3, "flag_blue", Vector2(-1.9, 0.0), 0.0],
	[0, 3, "flag_blue", Vector2(1.9, 0.0), 0.0],
	[0, -2, "flag_blue", Vector2(-1.9, 0.0), 0.0],
	[0, -2, "flag_blue", Vector2(1.9, 0.0), 0.0],
	# Windmill farm
	[5, -9, "wheelbarrow", Vector2(-2.0, 1.2), 120.0],
	[5, -9, "sack", Vector2(-1.2, 2.0), 0.0],
]

var _grass_material: Material
var _road_material: Material
var _paving_material: StandardMaterial3D
## Ground overrides: Vector2i -> [tile model, y rotation°, material kind].
var _ground := {}
## Tiles where nature must not grow.
var _occupied := {}
var _colliders: StaticBody3D


func _ready() -> void:
	rotation_degrees.y = ROAD_ALIGN_DEGREES
	_colliders = StaticBody3D.new()
	_colliders.name = "Colliders"
	add_child(_colliders)
	_plan_ground()
	_build_ground()
	_build_town_wall()
	_build_buildings()
	_build_nature()
	_build_props()
	_build_boundary()


static func axial_to_world(q: int, r: int) -> Vector3:
	return Vector3(sqrt(3.0) * HEX_SIZE * (q + r / 2.0), 0.0, 1.5 * HEX_SIZE * r)


static func hex_distance(q: int, r: int) -> int:
	return (absi(q) + absi(r) + absi(q + r)) / 2


## Tiles of one ring, walked in order: [coord, incoming dir index, outgoing dir index].
static func ring_tiles(radius: int) -> Array:
	var tiles := []
	var hex: Vector2i = DIRS[4] * radius
	for side in 6:
		for step in radius:
			tiles.append([hex, side if step > 0 else (side + 5) % 6, side])
			hex += DIRS[side]
	return tiles


func _place(asset: String, q: int, r: int, rotation_deg := 0.0) -> Node3D:
	var node: Node3D = load(ASSET_PATH % asset).instantiate()
	node.position = axial_to_world(q, r)
	node.rotation_degrees.y = rotation_deg
	node.scale = Vector3.ONE * WORLD_SCALE
	add_child(node)
	return node


func _add_cylinder_collider(at: Vector3, radius: float) -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 4.0
	shape.shape = cylinder
	shape.position = at + Vector3.UP * 2.0
	_colliders.add_child(shape)


func _plan_ground() -> void:
	# Plaza: the center tile and its ring.
	_ground[Vector2i.ZERO] = ["hex_grass", 0.0, "paving"]
	for dir in DIRS:
		_ground[dir] = ["hex_grass", 0.0, "paving"]
	# Main street (paved), gate tile (dirt road under the gate arch).
	for r in range(STREET_FROM, STREET_TO + 1):
		_ground[Vector2i(0, r)] = ["hex_grass", 0.0, "paving"]
	# Dirt road out of the gate, bridging the river.
	for r in range(WALL_RING, OUTER_ROAD_TO + 1):
		_ground[Vector2i(0, r)] = ["hex_road_A", -60.0, "road"]
	# River across the bottom, outside the walls.
	for q in range(-GROUND_RINGS, GROUND_RINGS + 1):
		if hex_distance(q, RIVER_ROW) <= GROUND_RINGS:
			_ground[Vector2i(q, RIVER_ROW)] = ["hex_river_A", 0.0, "water"]
	_ground[Vector2i(0, RIVER_ROW)] = ["hex_river_crossing_A", 0.0, "road"]
	for pond in PONDS:
		_ground[pond] = ["hex_water", 0.0, "water"]
	for coord in _ground:
		_occupied[coord] = true
	for field in FIELDS:
		_occupied[field] = true
	_occupied[WINDMILL] = true


func _build_ground() -> void:
	_paving_material = StandardMaterial3D.new()
	_paving_material.albedo_color = PAVING_COLOR
	_paving_material.roughness = 1.0
	for q in range(-GROUND_RINGS, GROUND_RINGS + 1):
		for r in range(-GROUND_RINGS, GROUND_RINGS + 1):
			if hex_distance(q, r) > GROUND_RINGS:
				continue
			var plan: Array = _ground.get(Vector2i(q, r), ["hex_grass", 0.0, "grass"])
			var tile := _place(plan[0], q, r, plan[1])
			var mesh: MeshInstance3D = tile.find_children("*", "MeshInstance3D")[0]
			if not _grass_material:
				_grass_material = mesh.mesh.surface_get_material(0).duplicate()
				_grass_material.albedo_color = GRASS_TINT
				_road_material = _grass_material.duplicate()
				_road_material.albedo_color = ROAD_TINT
			match plan[2]:
				"grass":
					mesh.material_override = _grass_material
				"road":
					mesh.material_override = _road_material
				"paving":
					mesh.material_override = _paving_material
	for field in FIELDS:
		_place("building_grain", field.x, field.y)
	_place("building_windmill_blue", WINDMILL.x, WINDMILL.y, 120.0)


## Stone wall on WALL_RING: straight pieces along each side, corner pieces
## (120° bends) at the six corners, a gate where the main street leaves town,
## and blue-roofed towers on the other corners.
func _build_town_wall() -> void:
	var gate := Vector2i(0, WALL_RING)
	for entry in ring_tiles(WALL_RING):
		var coord: Vector2i = entry[0]
		var dir_in: int = entry[1]
		var dir_out: int = entry[2]
		_occupied[coord] = true
		if dir_in == dir_out:
			_place("wall_straight", coord.x, coord.y, 60.0 * dir_out)
		elif coord == gate:
			_place("wall_corner_A_gate", coord.x, coord.y, 60.0 * dir_in)
		else:
			_place("wall_corner_A_outside", coord.x, coord.y, 60.0 * dir_in)
			_place("building_tower_A_blue", coord.x, coord.y)


func _build_buildings() -> void:
	for building in BUILDINGS:
		var coord := Vector2i(building[0], building[1])
		_occupied[coord] = true
		var node := _place(building[2], coord.x, coord.y)
		node.scale *= BUILDING_SCALE * building[4]
		if coord != Vector2i.ZERO:
			var to_plaza := -node.position
			node.rotation.y = atan2(to_plaza.x, to_plaza.z)
		_add_cylinder_collider(node.position, building[3] * BUILDING_SCALE * building[4])


func _build_nature() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = NATURE_SEED
	for tree in GARDEN_TREES:
		var node := _place(GARDEN_TREE_MODELS[rng.randi() % GARDEN_TREE_MODELS.size()], tree[0], tree[1], rng.randi_range(0, 5) * 60.0)
		node.position += Vector3(tree[2].x, 0.0, tree[2].y)
		_add_cylinder_collider(node.position, TREE_RADIUS)
	for q in range(-GROUND_RINGS, GROUND_RINGS + 1):
		for r in range(-GROUND_RINGS, GROUND_RINGS + 1):
			var ring := hex_distance(q, r)
			if ring <= WALL_RING or ring > GROUND_RINGS or _occupied.has(Vector2i(q, r)):
				continue
			var spin := rng.randi_range(0, 5) * 60.0
			if ring == WALL_RING + 1:
				if rng.randf() < OUTSKIRT_SCATTER_CHANCE:
					var node := _place(OUTSKIRT_SCATTER[rng.randi() % OUTSKIRT_SCATTER.size()], q, r, spin)
					node.position += Vector3(rng.randf_range(-1.5, 1.5), 0.0, rng.randf_range(-1.5, 1.5))
			elif ring < GROUND_RINGS:
				_place(FOREST[rng.randi() % FOREST.size()], q, r, spin)
			else:
				_place(HILLS[rng.randi() % HILLS.size()], q, r, spin)


func _build_props() -> void:
	for prop in PROPS:
		var node := _place(prop[2], prop[0], prop[1], prop[4])
		node.position += Vector3(prop[3].x, 0.0, prop[3].y)
		node.scale = Vector3.ONE * PROP_SCALE


## Invisible ring just inside the town wall so the hero stays in town.
func _build_boundary() -> void:
	var segment_length := TAU * WALK_RADIUS / WALL_SEGMENTS * 1.1
	for i in WALL_SEGMENTS:
		var angle := TAU * i / WALL_SEGMENTS
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(segment_length, 4.0, 1.0)
		shape.shape = box
		shape.position = Vector3(cos(angle), 0.0, sin(angle)) * WALK_RADIUS + Vector3.UP * 2.0
		shape.rotation.y = -angle + PI / 2.0
		_colliders.add_child(shape)
