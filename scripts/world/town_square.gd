class_name TownSquare
extends Node3D
## Ravenfall's town square: a stone fountain at the center of town, ringed by
## brick paving. The hero spawns beside the fountain.

const BRICK_SHADER := preload("res://shaders/brick_paving.gdshader")
const WATER_SHADER := preload("res://shaders/fountain_water.gdshader")
const SQUARE_SHADER := preload("res://shaders/brick_square.gdshader")

const PLAZA_RADIUS := 10.0
## Square brick floor (different brick colour) under the plaza and stalls.
const SQUARE_HALF_SIZE := 16.0
const STONE := Color(0.8, 0.77, 0.71)
const STONE_DARK := Color(0.6, 0.58, 0.54)
const BASIN_RADIUS := 3.0
const BASIN_HEIGHT := 0.75

## Market stalls just outside the brick plaza, in the top-left and
## bottom-right corners of the screen (world −X and +X with the isometric
## camera), facing the fountain.
## Each entry: [angle° around the fountain, awning colour, goods].
const STALL_RADIUS := 11.8
## Extra turn for every stall (counter-clockwise seen from above = to the left).
const STALL_TURN_DEGREES := 0.0
## Space a stall (with its crate) needs, as a radius around its centre.
const STALL_CLEARANCE := 2.2
## Extra clear space either side of a road's lane into the square.
const LANE_MARGIN := 0.8
## A stall that blocks a lane slides round the square in steps of this many degrees.
const STALL_NUDGE_DEGREES := 3.0
const STALLS := [
	[158.0, Color(0.85, 0.3, 0.28), MarketStall.Goods.FRUIT],
	[180.0, Color(0.3, 0.5, 0.85), MarketStall.Goods.CLOTH],
	[202.0, Color(0.95, 0.75, 0.3), MarketStall.Goods.POTTERY],
	# Bottom-right group leaves a gap at 0° for the road out of town.
	[-42.0, Color(0.4, 0.7, 0.45), MarketStall.Goods.POTTERY],
	[-24.0, Color(0.85, 0.45, 0.65), MarketStall.Goods.FRUIT],
	[24.0, Color(0.95, 0.55, 0.25), MarketStall.Goods.CLOTH],
]


func _ready() -> void:
	add_to_group("paved_area")
	_build_square_floor()
	_build_plaza()
	_build_fountain()
	# Stalls keep road entrances clear, so they need every road registered first.
	_build_stalls.call_deferred()
	# Raised kerb round the square, open where roads come in (needs roads registered).
	_build_kerb.call_deferred()


## World-space test used by road kerbs: is `point` on the brick square?
func covers(point: Vector3, margin: float) -> bool:
	var local := to_local(point)
	return absf(local.x) < SQUARE_HALF_SIZE + margin and absf(local.z) < SQUARE_HALF_SIZE + margin


func _build_kerb() -> void:
	var r := SQUARE_HALF_SIZE + RoadKerbs.BLOCK.x / 2.0 - 0.05
	var line := PackedVector3Array([Vector3(-r, 0, -r), Vector3(r, 0, -r), Vector3(r, 0, r), Vector3(-r, 0, r), Vector3(-r, 0, -r)])
	add_child(RoadKerbs.make_instance(RoadKerbs.blocks_along(self, line, 0.0), 99))


func _build_square_floor() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * SQUARE_HALF_SIZE * 2.0
	var material := ShaderMaterial.new()
	material.shader = SQUARE_SHADER
	material.set_shader_parameter("half_size", SQUARE_HALF_SIZE)
	var square := MeshInstance3D.new()
	square.name = "BrickSquare"
	square.mesh = plane
	square.material_override = material
	square.position.y = 0.015
	add_child(square)


func _build_plaza() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = PLAZA_RADIUS
	disc.bottom_radius = PLAZA_RADIUS
	disc.height = 0.06
	disc.radial_segments = 96
	disc.rings = 1
	var material := ShaderMaterial.new()
	material.shader = BRICK_SHADER
	material.set_shader_parameter("inner_radius", BASIN_RADIUS + 0.2)
	material.set_shader_parameter("outer_radius", PLAZA_RADIUS)
	var plaza := MeshInstance3D.new()
	plaza.name = "BrickPlaza"
	plaza.mesh = disc
	plaza.material_override = material
	plaza.position.y = 0.03
	add_child(plaza)


func _build_fountain() -> void:
	var fountain := Node3D.new()
	fountain.name = "Fountain"
	add_child(fountain)
	var stone := _stone(STONE)
	var stone_dark := _stone(STONE_DARK)
	# Lower basin: wall, rounded rim, water.
	fountain.add_child(_cylinder(BASIN_RADIUS, BASIN_RADIUS + 0.15, BASIN_HEIGHT, stone_dark, 0.0, 12))
	fountain.add_child(_ring(BASIN_RADIUS - 0.3, BASIN_RADIUS + 0.12, stone, BASIN_HEIGHT))
	fountain.add_child(_water(BASIN_RADIUS - 0.3, BASIN_HEIGHT + 0.02))
	# Central column with an upper bowl and a small top bowl.
	fountain.add_child(_cylinder(0.55, 0.75, 0.3, stone, 0.0, 8))
	fountain.add_child(_cylinder(0.32, 0.42, 1.9, stone_dark, 0.3, 8))
	fountain.add_child(_cylinder(1.35, 0.45, 0.45, stone, 1.9, 12))
	fountain.add_child(_ring(1.15, 1.4, stone, 2.35))
	fountain.add_child(_water(1.15, 2.37))
	fountain.add_child(_cylinder(0.16, 0.22, 0.7, stone_dark, 2.35, 8))
	fountain.add_child(_cylinder(0.5, 0.18, 0.22, stone, 3.0, 10))
	fountain.add_child(_water(0.42, 3.24))
	fountain.add_child(_spray(Vector3(0, 3.25, 0), 1.6, 40))
	fountain.add_child(_spray(Vector3(0, 2.4, 0), 2.4, 60))

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = BASIN_RADIUS + 0.2
	cylinder.height = 3.0
	shape.shape = cylinder
	shape.position.y = 1.5
	body.add_child(shape)
	fountain.add_child(body)


func _build_stalls() -> void:
	var lanes := _road_lanes()
	var placed: Array[Vector3] = []
	for i in STALLS.size():
		var angle := _free_angle(STALLS[i][0], lanes, placed)
		placed.append(Vector3(cos(angle), 0.0, sin(angle)) * STALL_RADIUS)
		var stall := MarketStall.new()
		stall.name = "Stall%d" % i
		stall.awning_color = STALLS[i][1]
		stall.goods = STALLS[i][2]
		stall.seed = i
		stall.position = Vector3(cos(angle), 0.0, sin(angle)) * STALL_RADIUS
		# Customer side (+Z) faces the fountain.
		stall.rotation.y = atan2(-stall.position.x, -stall.position.z) + deg_to_rad(STALL_TURN_DEGREES)
		add_child(stall)


## Lanes into the square: for each road ending at the square's edge, the
## strip continuing straight in toward the fountain. Each lane is
## [start, end, half width] in this node's local space.
func _road_lanes() -> Array:
	var lanes := []
	for road in get_tree().get_nodes_in_group("roads"):
		var corners: PackedVector3Array = road.corners
		for end_index in [0, corners.size() - 1]:
			var neighbour := 1 if end_index == 0 else corners.size() - 2
			var tip := to_local(road.to_global(corners[end_index]))
			var before := to_local(road.to_global(corners[neighbour]))
			var edge_distance := maxf(absf(tip.x), absf(tip.z))
			if absf(edge_distance - SQUARE_HALF_SIZE) > 1.5:
				continue
			var inward := (tip - before).normalized()
			var reach := edge_distance - PLAZA_RADIUS + 1.0
			lanes.append([tip, tip + inward * reach, road.width / 2.0 + LANE_MARGIN])
	return lanes


## The angle (radians) nearest `degrees` where a stall clears every lane and
## every stall already placed.
func _free_angle(degrees: float, lanes: Array, placed: Array[Vector3]) -> float:
	for step in 61:
		for direction in [1.0, -1.0]:
			var angle := deg_to_rad(degrees + direction * step * STALL_NUDGE_DEGREES)
			var at := Vector3(cos(angle), 0.0, sin(angle)) * STALL_RADIUS
			if _stall_fits(at, lanes, placed):
				return angle
			if step == 0:
				break
	return deg_to_rad(degrees)


func _stall_fits(at: Vector3, lanes: Array, placed: Array[Vector3]) -> bool:
	var flat := Vector2(at.x, at.z)
	for lane in lanes:
		var a := Vector2(lane[0].x, lane[0].z)
		var b := Vector2(lane[1].x, lane[1].z)
		if flat.distance_to(Geometry2D.get_closest_point_to_segment(flat, a, b)) < lane[2] + STALL_CLEARANCE:
			return false
	for other in placed:
		if other.distance_to(at) < STALL_CLEARANCE * 1.6:
			return false
	return true


func _stone(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


func _cylinder(top: float, bottom: float, height: float, material: Material, y: float, sides: int) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position.y = y + height / 2.0
	return instance


func _ring(inner: float, outer: float, material: Material, y: float) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 48
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position.y = y
	instance.scale.y = 0.6
	return instance


func _water(radius: float, y: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	mesh.radial_segments = 48
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("radius", radius)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position.y = y
	return instance


## Water droplets arcing out and falling back into the bowl below.
func _spray(at: Vector3, speed: float, amount: int) -> GPUParticles3D:
	var spray := GPUParticles3D.new()
	spray.amount = amount
	spray.lifetime = 0.9
	spray.position = at
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 40.0
	process.initial_velocity_min = speed * 0.8
	process.initial_velocity_max = speed
	process.gravity = Vector3(0, -6.0, 0)
	spray.process_material = process
	var drop := SphereMesh.new()
	drop.radius = 0.05
	drop.height = 0.1
	drop.radial_segments = 6
	drop.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.92, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.6, 0.8, 1.0)
	material.emission_energy_multiplier = 0.4
	drop.material = material
	spray.draw_pass_1 = drop
	return spray
