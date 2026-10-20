class_name RavenfallVillage
extends Node3D
## Builds Ravenfall, the starting hub city, from a data layout.
## Spec: docs/game_design.md → "Ravenfall city spec" (from the art prompt);
## visual reference: docs/reference/ravenfall_golden_town.png.
## Layout uses pointy-top hex axial coords (q, r) as a placement grid (5 units
## per cell; the KayKit hex pack is scaled ×2.5). The ground is one smooth
## terrain: flat inside the walls, rolling hills beyond, a river valley below.
## Screen directions (after ROAD_ALIGN): (0, -1) = up, (0, 1) = down,
## (1, 0) = right-down, (1, -1) = right-up, (-1, 0) = left-up, (-1, 1) = left-down.

const ASSET_PATH := "res://assets/environments/kaykit_medieval/%s.gltf"
const WORLD_SCALE := 2.5
## Circumradius of one scaled hex cell (pack tile is 1.155 from center to point).
const HEX_SIZE := 1.155 * WORLD_SCALE
## Turns the whole town so the main street runs straight up/down the screen
## (the hex axis is 15° off the isometric camera's "up").
const ROAD_ALIGN_DEGREES := 15.0

## The town wall sits on this ring; everything inside is walkable town.
const WALL_RING := 6
## Forest and hills are placed out to this ring.
const NATURE_RINGS := 14
const TERRAIN_SIZE := 320.0
const TERRAIN_STEP := 2.5
## Invisible boundary just inside the wall (its sides are ~26 units out).
const WALK_RADIUS := 24.5
const BOUNDARY_SEGMENTS := 32

## Rolling hills: flat out to FLAT_RADIUS, rising over HILL_RISE units.
const FLAT_RADIUS := 46.0
const HILL_RISE := 30.0
const HILL_HEIGHT := 11.0
const RIVER_ROW := 8
## The river valley stays flat this far either side of the river.
const RIVER_VALLEY := 6.0

## Buildings are drawn larger than map scale so the town feels dense
## (colliders scale with them).
const BUILDING_SCALE := 1.5
## Hex-pack props (barrels, crates…) are modelled at map scale; this makes
## them hero-sized.
const PROP_SCALE := 6.0
const FENCE_SCALE := 2.0
## Fixed seed so the scattered nature looks the same every visit.
const NATURE_SEED := 20261020

## Terrain colours; each surface blends two shades with soft noise.
const GRASS_COLORS := [Color(0.42, 0.62, 0.27), Color(0.6, 0.76, 0.33)]
const PAVING_COLORS := [Color(0.66, 0.6, 0.52), Color(0.8, 0.74, 0.64)]
const PATH_COLORS := [Color(0.6, 0.55, 0.48), Color(0.72, 0.67, 0.58)]
const DIRT_COLORS := [Color(0.62, 0.5, 0.36), Color(0.76, 0.64, 0.46)]
const BANK_COLORS := [Color(0.74, 0.68, 0.5), Color(0.84, 0.78, 0.6)]
const FIELD_COLORS := [Color(0.86, 0.7, 0.3), Color(0.95, 0.82, 0.42)]
const WATER_COLOR := Color(0.24, 0.52, 0.78)
## How many world units one noise texture repeat covers.
const NOISE_TILE := 24.0
const PLAZA_RADIUS := 7.5
const STREET_WIDTH := 4.5
const PATH_WIDTH := 2.6
const ROAD_WIDTH := 3.5
const RIVER_WIDTH := 4.5
const BANK_WIDTH := 6.5
const FIELD_SIZE := Vector2(4.4, 3.8)

## Axial neighbour directions; index k points at world angle -60°·k.
const DIRS := [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

## Main street: paved from the town hall (top) through the plaza to the gate.
const STREET_FROM := -3
## Winding road from the gate over the river and into the hills (axial points).
const ROAD_POINTS := [
	Vector2(0, 6), Vector2(0, 7), Vector2(0, 8), Vector2(0, 9),
	Vector2(0.9, 10.1), Vector2(0.6, 11.4), Vector2(-0.7, 12.4),
	Vector2(-1.3, 13.8), Vector2(-0.6, 15.4), Vector2(0.4, 17.0),
]

## Districts. Each entry: [q, r, model, collision radius, scale multiplier].
## Buildings turn to face the plaza.
const BUILDINGS := [
	# Civic (north)
	[0, -4, "building_castle_blue", 2.2, 0.85],      # Town hall
	[-1, -3, "building_home_A_blue", 1.4, 1.0],
	[1, -4, "building_home_B_blue", 1.4, 1.0],
	# Church district (north-east)
	[3, -4, "building_church_blue", 1.6, 1.3],       # Church with bell tower
	[4, -2, "building_home_A_blue", 1.4, 1.0],
	# Crafts district (north-west)
	[-3, -1, "building_blacksmith_blue", 1.6, 1.1],  # Blacksmith — glowing forge
	[-2, -3, "building_home_B_blue", 1.4, 1.0],
	[-3, -2, "building_home_A_blue", 1.4, 1.0],
	# Tavern (west)
	[-3, 1, "building_tavern_blue", 1.6, 1.1],       # Tavern — Rest
	# Shops around the plaza
	[2, -1, "building_market_blue", 1.6, 1.0],       # General goods shop
	[1, 1, "building_tower_A_blue", 1.4, 1.0],       # Potion shop (mage tower)
	# Residential east
	[4, -1, "building_home_B_blue", 1.4, 1.0],
	[3, 1, "building_home_A_blue", 1.4, 1.0],
	[4, 1, "building_home_B_blue", 1.4, 1.0],
	[5, -4, "building_home_A_blue", 1.4, 1.0],
	[2, 2, "building_home_B_blue", 1.4, 1.0],
	# Residential west
	[-4, 0, "building_home_B_blue", 1.4, 1.0],
	[-5, 1, "building_home_A_blue", 1.4, 1.0],
	[-4, 3, "building_home_A_blue", 1.4, 1.0],
	[-5, 3, "building_home_B_blue", 1.4, 1.0],
	[-2, 4, "building_home_A_blue", 1.4, 1.0],
	[-3, 4, "building_home_B_blue", 1.4, 1.0],
	[-5, 4, "building_destroyed", 1.4, 1.0],         # Abandoned house
	# Gate (south)
	[2, 3, "building_barracks_blue", 2.2, 1.0],
	[-1, 4, "building_home_B_blue", 1.4, 1.0],
]

## Stone paths from the plaza edge to each district (target cells).
const PATHS_TO := [
	Vector2i(-3, 1), Vector2i(-3, -1), Vector2i(3, -4), Vector2i(2, -1),
	Vector2i(1, 1), Vector2i(-4, 3), Vector2i(4, 0), Vector2i(-4, 0),
]

## Garden pond (between two cells) in the east residential district.
const POND := [Vector2i(3, 0), Vector2i(4, 0)]
## Wheat fields + windmill outside the walls, top-right.
const FIELDS := [Vector2i(3, -8), Vector2i(4, -8), Vector2i(3, -9), Vector2i(4, -9), Vector2i(2, -8)]
const WINDMILL := Vector2i(5, -9)

## Flower beds: [axial position (fractional ok), size (x, z), y rotation°].
const FLOWER_BEDS := [
	[Vector2(1.2, -1.6), Vector2(3.0, 1.2), 30.0],   # Plaza corners
	[Vector2(-1.6, 0.4), Vector2(3.0, 1.2), -30.0],
	[Vector2(-0.4, 1.6), Vector2(1.2, 1.2), 0.0],
	[Vector2(1.6, -0.2), Vector2(1.2, 1.2), 0.0],
	[Vector2(2.3, -3.2), Vector2(3.6, 2.0), 30.0],   # Church garden
	[Vector2(3.6, -2.9), Vector2(2.4, 1.6), -10.0],
	[Vector2(3.4, 0.6), Vector2(2.0, 1.0), 0.0],     # Pond garden
	[Vector2(-4.4, 2.1), Vector2(2.2, 1.0), 20.0],   # Cottages
	[Vector2(-1.9, -2.2), Vector2(2.0, 1.0), -20.0],
	[Vector2(4.6, -1.5), Vector2(1.8, 1.0), 10.0],
	[Vector2(-2.5, 3.4), Vector2(2.0, 1.0), 0.0],
]

## Wooden fences: lists of axial points joined into fence lines.
const FENCES := [
	[Vector2(1.7, -3.1), Vector2(2.2, -2.6), Vector2(3.4, -2.4), Vector2(4.1, -2.9)],  # Church garden
	[Vector2(-4.9, 2.6), Vector2(-4.2, 1.6), Vector2(-3.6, 1.7)],                      # West cottages
]

## Single trees inside the walls (with colliders). [q, r, offset (x, z)].
const GARDEN_TREES := [
	[-2, 2, Vector2(0.0, 0.0)], [-1, 2, Vector2(-1.0, -1.0)], [3, -3, Vector2(0.5, 0.5)],
	[-2, 0, Vector2(-1.5, 0.0)], [5, -3, Vector2(0.0, 0.0)], [-4, 5, Vector2(1.0, 0.0)],
	[-4, 4, Vector2(0.0, 0.0)], [1, 3, Vector2(0.0, 0.0)], [2, -4, Vector2(0.0, 0.0)],
	[-4, 1, Vector2(0.0, 0.0)], [5, -2, Vector2(0.0, 0.0)], [1, 2, Vector2(1.0, 0.0)],
	[-3, 3, Vector2(-1.0, 0.5)], [3, -5, Vector2(0.0, 0.0)], [-1, -2, Vector2(-1.0, 0.0)],
]
const GARDEN_TREE_MODELS := ["tree_single_A", "tree_single_B"]
const TREE_RADIUS := 0.7

## Nature outside the walls.
const OUTSKIRT_SCATTER := ["tree_single_A", "tree_single_B", "rock_single_A", "rock_single_B", "rock_single_C"]
const OUTSKIRT_SCATTER_CHANCE := 0.5
const FOREST := ["trees_A_large", "trees_A_medium", "trees_B_large", "trees_B_medium"]
## Forest grows in patches: cells whose noise value is above this.
const FOREST_THRESHOLD := -0.15

## Colourful market stalls on the plaza: [angle° around plaza, colour].
const STALLS := [
	[100.0, Color(0.95, 0.45, 0.4)], [140.0, Color(0.45, 0.65, 0.95)],
	[180.0, Color(0.98, 0.82, 0.4)], [300.0, Color(0.5, 0.82, 0.5)],
	[340.0, Color(0.95, 0.6, 0.85)], [20.0, Color(0.98, 0.7, 0.35)],
]
const STALL_RADIUS := 5.2

## Hand-placed props. Each entry: [q, r, model, offset (x, z) from cell, y rotation°].
const PROPS := [
	[-3, 1, "barrel", Vector2(2.2, 1.0), 0.0],          # Tavern
	[-3, 1, "barrel", Vector2(2.4, 1.8), 40.0],
	[-3, -1, "weaponrack", Vector2(2.4, 0.5), -60.0],   # Blacksmith
	[-3, -1, "crate_A_big", Vector2(1.2, 2.4), 10.0],
	[-3, -1, "barrel", Vector2(0.4, 2.8), 0.0],
	[2, -1, "crate_A_big", Vector2(-2.0, -1.0), 15.0],  # General goods
	[2, -1, "sack", Vector2(-2.4, 0.2), 0.0],
	[1, 1, "crate_B_small", Vector2(-1.8, -0.6), 30.0], # Potion shop
	[0, 4, "flag_blue", Vector2(-1.9, 0.0), 0.0],       # Banners along the main street
	[0, 4, "flag_blue", Vector2(1.9, 0.0), 0.0],
	[0, -2, "flag_blue", Vector2(-1.9, 0.0), 0.0],
	[0, -2, "flag_blue", Vector2(1.9, 0.0), 0.0],
	[5, -9, "wheelbarrow", Vector2(-2.0, 1.2), 120.0],  # Windmill farm
	[5, -9, "sack", Vector2(-1.2, 2.0), 0.0],
]

var _occupied := {}
var _colliders: StaticBody3D
var _height_noise := FastNoiseLite.new()
var _road_line := PackedVector3Array()
var _forge_light: OmniLight3D
var _flicker_time := 0.0


func _ready() -> void:
	rotation_degrees.y = ROAD_ALIGN_DEGREES
	_height_noise.seed = NATURE_SEED
	_height_noise.frequency = 0.025
	_colliders = StaticBody3D.new()
	_colliders.name = "Colliders"
	add_child(_colliders)
	_road_line = _smooth_line(ROAD_POINTS, 6)
	_plan_cells()
	_build_terrain()
	_build_streets()
	_build_water_and_fields()
	_build_town_wall()
	_build_buildings()
	_build_decor()
	_build_nature()
	_build_props()
	_build_boundary()


func _process(delta: float) -> void:
	if _forge_light:
		_flicker_time += delta
		_forge_light.light_energy = 2.6 + sin(_flicker_time * 11.0) * 0.4 + sin(_flicker_time * 23.0) * 0.3


static func axial_to_world(q: float, r: float) -> Vector3:
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


## Terrain height in village-local space: flat town, river valley, rolling hills.
func height_at(x: float, z: float) -> float:
	var distance := Vector2(x, z).length()
	var rise := smoothstep(FLAT_RADIUS, FLAT_RADIUS + HILL_RISE, distance)
	var river_z := axial_to_world(0, RIVER_ROW).z
	var valley := smoothstep(RIVER_VALLEY, RIVER_VALLEY + 10.0, absf(z - river_z))
	var bumps := 0.55 + 0.45 * _height_noise.get_noise_2d(x, z)
	return HILL_HEIGHT * rise * valley * bumps


func _place(asset: String, q: float, r: float, rotation_deg := 0.0) -> Node3D:
	var node: Node3D = load(ASSET_PATH % asset).instantiate()
	node.position = axial_to_world(q, r)
	node.position.y = height_at(node.position.x, node.position.z)
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


## Cells where trees must not grow: plaza, street, river, pond, fields, road.
func _plan_cells() -> void:
	_occupied[Vector2i.ZERO] = true
	for dir in DIRS:
		_occupied[dir] = true
	for r in range(STREET_FROM, WALL_RING + 1):
		_occupied[Vector2i(0, r)] = true
	for q in range(-NATURE_RINGS - 8, NATURE_RINGS + 1):
		_occupied[Vector2i(q, RIVER_ROW)] = true
	for cell in POND + FIELDS:
		_occupied[cell] = true
	_occupied[WINDMILL] = true


func _near_road(point: Vector3, distance: float) -> bool:
	for p in _road_line:
		if Vector2(p.x - point.x, p.z - point.z).length() < distance:
			return true
	return false


## Catmull-Rom through axial points → world-space polyline on the terrain.
func _smooth_line(points: Array, steps: int) -> PackedVector3Array:
	var world: Array[Vector3] = []
	for p in points:
		world.append(axial_to_world(p.x, p.y))
	var line := PackedVector3Array()
	for i in world.size() - 1:
		var p0: Vector3 = world[maxi(i - 1, 0)]
		var p1: Vector3 = world[i]
		var p2: Vector3 = world[i + 1]
		var p3: Vector3 = world[mini(i + 2, world.size() - 1)]
		for s in steps:
			var t := float(s) / steps
			var p := 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
			p.y = height_at(p.x, p.z)
			line.append(p)
	var last: Vector3 = world[-1]
	last.y = height_at(last.x, last.z)
	line.append(last)
	return line


func _build_terrain() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := int(TERRAIN_SIZE / TERRAIN_STEP)
	var half := TERRAIN_SIZE / 2.0
	for i in cells + 1:
		for j in cells + 1:
			var x := -half + i * TERRAIN_STEP
			var z := -half + j * TERRAIN_STEP
			tool.add_vertex(Vector3(x, height_at(x, z), z))
	for i in cells:
		for j in cells:
			var a := i * (cells + 1) + j
			var b := a + cells + 1
			tool.add_index(a)
			tool.add_index(b)
			tool.add_index(a + 1)
			tool.add_index(a + 1)
			tool.add_index(b)
			tool.add_index(b + 1)
	tool.generate_normals()
	var ground := MeshInstance3D.new()
	ground.name = "Terrain"
	ground.mesh = tool.commit()
	ground.material_override = _noise_material(GRASS_COLORS, NOISE_TILE * 2.0)
	add_child(ground)


func _build_streets() -> void:
	var paving := _noise_material(PAVING_COLORS, NOISE_TILE)
	_disc(Vector3.ZERO, PLAZA_RADIUS, paving, 0.03)
	_strip(axial_to_world(0, STREET_FROM), axial_to_world(0, WALL_RING), STREET_WIDTH, paving, 0.02)
	var path := _noise_material(PATH_COLORS, NOISE_TILE)
	for target in PATHS_TO:
		var end := axial_to_world(target.x, target.y)
		var dir := end.normalized()
		_strip(dir * (PLAZA_RADIUS - 1.0), end - dir * 2.5, PATH_WIDTH, path, 0.025)
	var dirt := _noise_material(DIRT_COLORS, NOISE_TILE)
	for i in _road_line.size() - 1:
		_strip(_road_line[i], _road_line[i + 1], ROAD_WIDTH, dirt, 0.04)


func _build_water_and_fields() -> void:
	var water := TownDecor.flat_material(WATER_COLOR, 0.15)
	water.metallic = 0.2
	var bank := _noise_material(BANK_COLORS, NOISE_TILE)
	var river_from := axial_to_world(-NATURE_RINGS - 8, RIVER_ROW)
	var river_to := axial_to_world(NATURE_RINGS + 2, RIVER_ROW)
	_strip(river_from, river_to, BANK_WIDTH, bank, 0.01)
	_strip(river_from, river_to, RIVER_WIDTH, water, 0.05)
	var bridge := _place("building_bridge_A", 0, RIVER_ROW, 30.0)
	bridge.scale = Vector3.ONE * 3.0

	var pond_center := (axial_to_world(POND[0].x, POND[0].y) + axial_to_world(POND[1].x, POND[1].y)) / 2.0
	_disc(pond_center, 4.0, bank, 0.01).scale.x = 1.7
	_disc(pond_center, 3.2, water, 0.025).scale.x = 1.8

	for i in FIELDS.size():
		var field := MeshInstance3D.new()
		var patch := PlaneMesh.new()
		patch.size = FIELD_SIZE
		field.mesh = patch
		field.material_override = _noise_material([FIELD_COLORS[i % 2], FIELD_COLORS[(i + 1) % 2]], NOISE_TILE / 2.0)
		field.position = axial_to_world(FIELDS[i].x, FIELDS[i].y) + Vector3.UP * 0.02
		field.rotation_degrees.y = 30.0
		add_child(field)
	var corners := []
	for field in FIELDS:
		corners.append(axial_to_world(field.x, field.y))
	_fence_around(corners, 3.4)
	_place("building_windmill_blue", WINDMILL.x, WINDMILL.y, 120.0)


## Stone wall on WALL_RING: straight pieces along each side, corner pieces
## (120° bends) at the six corners, a gate where the main street leaves town,
## and blue-roofed towers on the corners and either side of the gate.
func _build_town_wall() -> void:
	var gate := Vector2i(0, WALL_RING)
	var tiles := ring_tiles(WALL_RING)
	for index in tiles.size():
		var coord: Vector2i = tiles[index][0]
		var dir_in: int = tiles[index][1]
		var dir_out: int = tiles[index][2]
		if dir_in == dir_out:
			_place("wall_straight", coord.x, coord.y, 60.0 * dir_out)
		elif coord == gate:
			_place("wall_corner_A_gate", coord.x, coord.y, 60.0 * dir_in)
			for side in [-1, 1]:
				var beside: Vector2i = tiles[(index + side + tiles.size()) % tiles.size()][0]
				_place("building_tower_A_blue", beside.x, beside.y).scale *= 1.2
		else:
			_place("wall_corner_A_outside", coord.x, coord.y, 60.0 * dir_in)
			_place("building_tower_A_blue", coord.x, coord.y)


func _build_buildings() -> void:
	for building in BUILDINGS:
		var node := _place(building[2], building[0], building[1])
		node.scale *= BUILDING_SCALE * building[4]
		var to_plaza := -node.position
		node.rotation.y = atan2(to_plaza.x, to_plaza.z)
		_add_cylinder_collider(node.position, building[3] * BUILDING_SCALE * building[4])


## Fountain, market stalls, lanterns, flower beds, fences, forge glow, magic motes.
func _build_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = NATURE_SEED
	add_child(TownDecor.fountain())
	_add_cylinder_collider(Vector3.ZERO, 3.0)

	for stall in STALLS:
		var angle := deg_to_rad(stall[0])
		var at := Vector3(cos(angle), 0.0, sin(angle)) * STALL_RADIUS
		var tent := _place("tent", 0, 0, -stall[0] + 90.0)
		tent.position = at
		tent.scale = Vector3.ONE * PROP_SCALE
		_tint(tent, stall[1])
		var goods := _place(["crate_B_small", "sack", "barrel"][rng.randi() % 3], 0, 0, rng.randf_range(0, 360))
		goods.position = at * 1.25
		goods.scale = Vector3.ONE * PROP_SCALE

	for at in _lantern_spots():
		var lantern := TownDecor.lantern()
		lantern.position = at
		lantern.rotation.y = atan2(-at.x, -at.z) - PI / 2.0
		add_child(lantern)

	for bed in FLOWER_BEDS:
		var node := TownDecor.flower_bed(bed[1], rng)
		node.position = axial_to_world(bed[0].x, bed[0].y)
		node.rotation_degrees.y = bed[2]
		add_child(node)

	for line in FENCES:
		var points := []
		for p in line:
			points.append(axial_to_world(p.x, p.y))
		_fence_line(points)

	var smithy := axial_to_world(-3, -1)
	var forge := TownDecor.forge_glow()
	forge.position = smithy + (-smithy).normalized() * 2.4
	add_child(forge)
	_forge_light = forge.get_node("Light")

	add_child(TownDecor.magic_motes(WALK_RADIUS))


## Lanterns line the main street, ring the plaza, and light the gate and tavern.
func _lantern_spots() -> Array:
	var spots := []
	var street_dir := axial_to_world(0, 1).normalized()
	var side := Vector3(street_dir.z, 0.0, -street_dir.x)
	for r in [-2.2, 2.2, 3.4, 4.6, 5.6]:
		for s in [-1.0, 1.0]:
			spots.append(axial_to_world(0, r) + side * s * (STREET_WIDTH / 2.0 + 0.5))
	for angle in [0.0, 120.0, 180.0, 300.0]:
		var a := deg_to_rad(angle)
		spots.append(Vector3(cos(a), 0.0, sin(a)) * (PLAZA_RADIUS + 0.6))
	var tavern := axial_to_world(-3, 1)
	spots.append(tavern + (-tavern).normalized() * 3.2 + side * 1.5)
	return spots


func _tint(node: Node3D, color: Color) -> void:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D"):
		var material: StandardMaterial3D = mesh.mesh.surface_get_material(0).duplicate()
		material.albedo_color = color
		mesh.material_override = material


## Wooden fence along a polyline of world points.
func _fence_line(points: Array) -> void:
	for i in points.size() - 1:
		var from: Vector3 = points[i]
		var to: Vector3 = points[i + 1]
		var segment := 1.16 * FENCE_SCALE
		var count := maxi(1, ceili(from.distance_to(to) / segment))
		var dir := (to - from).normalized()
		var angle := atan2(dir.x, dir.z)
		for k in count:
			var center := from.lerp(to, (k + 0.5) / count)
			var fence: Node3D = load(ASSET_PATH % "fence_wood_straight").instantiate()
			fence.rotation.y = angle
			fence.scale = Vector3.ONE * FENCE_SCALE
			# The model sits on a hex edge at local x = -1; shift it onto the line.
			fence.position = center + Basis(Vector3.UP, angle).x * FENCE_SCALE
			fence.position.y = height_at(center.x, center.z)
			add_child(fence)


## Fence around a group of cells (axis-aligned box in village space + margin).
func _fence_around(centers: Array, margin: float) -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in centers:
		lo = Vector2(minf(lo.x, c.x), minf(lo.y, c.z))
		hi = Vector2(maxf(hi.x, c.x), maxf(hi.y, c.z))
	lo -= Vector2.ONE * margin
	hi += Vector2.ONE * margin
	_fence_line([Vector3(lo.x, 0, lo.y), Vector3(hi.x, 0, lo.y), Vector3(hi.x, 0, hi.y), Vector3(lo.x, 0, hi.y), Vector3(lo.x, 0, lo.y)])


func _build_nature() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = NATURE_SEED
	for tree in GARDEN_TREES:
		var node := _place(GARDEN_TREE_MODELS[rng.randi() % GARDEN_TREE_MODELS.size()], tree[0], tree[1], rng.randi_range(0, 5) * 60.0)
		node.position += Vector3(tree[2].x, 0.0, tree[2].y)
		_add_cylinder_collider(node.position, TREE_RADIUS)
	var patches := FastNoiseLite.new()
	patches.seed = NATURE_SEED + 1
	patches.frequency = 0.04
	for q in range(-NATURE_RINGS, NATURE_RINGS + 1):
		for r in range(-NATURE_RINGS, NATURE_RINGS + 1):
			var ring := hex_distance(q, r)
			if ring <= WALL_RING or ring > NATURE_RINGS or _occupied.has(Vector2i(q, r)):
				continue
			var at := axial_to_world(q, r)
			if _near_road(at, 5.0):
				continue
			var spin := rng.randi_range(0, 5) * 60.0
			if ring == WALL_RING + 1 or patches.get_noise_2d(at.x, at.z) < FOREST_THRESHOLD:
				if rng.randf() < OUTSKIRT_SCATTER_CHANCE:
					var node := _place(OUTSKIRT_SCATTER[rng.randi() % OUTSKIRT_SCATTER.size()], q, r, spin)
					node.position += Vector3(rng.randf_range(-1.5, 1.5), 0.0, rng.randf_range(-1.5, 1.5))
					node.position.y = height_at(node.position.x, node.position.z)
			else:
				_place(FOREST[rng.randi() % FOREST.size()], q, r, spin)


func _build_props() -> void:
	for prop in PROPS:
		var node := _place(prop[2], prop[0], prop[1], prop[4])
		node.position += Vector3(prop[3].x, 0.0, prop[3].y)
		node.scale = Vector3.ONE * PROP_SCALE


## Two-tone noise material; `tile_size` is the world size of one texture repeat.
func _noise_material(colors: Array, tile_size: float) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	var ramp := Gradient.new()
	ramp.set_color(0, colors[0])
	ramp.set_color(1, colors[1])
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.color_ramp = ramp
	texture.seamless = true
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 1.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / tile_size
	return material


## Flat strip on the terrain from `from` to `to` (tilts with slopes), rounded ends.
func _strip(from: Vector3, to: Vector3, width: float, material: Material, lift: float) -> void:
	from.y = height_at(from.x, from.z)
	to.y = height_at(to.x, to.z)
	var strip := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, from.distance_to(to))
	strip.mesh = plane
	strip.material_override = material
	var forward := (to - from).normalized()
	var right := Vector3.UP.cross(forward).normalized()
	strip.basis = Basis(right, forward.cross(right), forward)
	strip.position = (from + to) / 2.0 + Vector3.UP * lift
	add_child(strip)
	_disc(from, width / 2.0, material, lift)
	_disc(to, width / 2.0, material, lift)


func _disc(at: Vector3, radius: float, material: Material, lift: float) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.001
	cylinder.radial_segments = 48
	cylinder.rings = 1
	disc.mesh = cylinder
	disc.material_override = material
	disc.position = Vector3(at.x, height_at(at.x, at.z) + lift, at.z)
	add_child(disc)
	return disc


## Invisible ring just inside the town wall so the hero stays in town.
func _build_boundary() -> void:
	var segment_length := TAU * WALK_RADIUS / BOUNDARY_SEGMENTS * 1.1
	for i in BOUNDARY_SEGMENTS:
		var angle := TAU * i / BOUNDARY_SEGMENTS
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(segment_length, 4.0, 1.0)
		shape.shape = box
		shape.position = Vector3(cos(angle), 0.0, sin(angle)) * WALK_RADIUS + Vector3.UP * 2.0
		shape.rotation.y = -angle + PI / 2.0
		_colliders.add_child(shape)
