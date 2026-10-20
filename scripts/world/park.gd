class_name Park
extends Node3D
## A large public park that blends into the town: no border, no separate
## lawn — trees thin out toward the edges, and its paths join the plaza
## square and the church path. A loop footpath circles an oval pond (stone
## rim, lily pads); benches face the pond; lamps and flower beds line the
## paths. Coordinates are local to the park centre, axis-aligned with the town.

## Trees are scattered inside this ellipse, densest in the middle.
const TREE_AREA := Vector2(27.0, 23.0)
const TREE_COUNT := 60
const TREE_SPACING := 3.4
const LOOP_RADII := Vector2(15.0, 11.0)
const POND_RADII := Vector2(9.0, 6.0)
const PATH_WIDTH := 2.8
## Footpaths besides the loop, in local coords (straight segments, square corners).
## The first joins the plaza square's edge.
const PATHS := [
	[Vector3(-18, 0, 24), Vector3(-18, 0, 0), Vector3(-15, 0, 0)],
	[Vector3(15, 0, 0), Vector3(28, 0, 0)],
]
## World-space boxes (x, z min/max) kept clear of trees: plaza square, church,
## and everything beyond the town wall behind the church (z < -53).
const KEEP_CLEAR := [Rect2(-17, -17, 34, 34), Rect2(-8, -48, 12, 28), Rect2(-200, -400, 400, 347)]
const SEED := 4242

const STONE := Color(0.7, 0.68, 0.63)
const WOOD := Color(0.5, 0.33, 0.2)
const IRON := Color(0.15, 0.15, 0.17)
const LEAVES := [Color(0.3, 0.55, 0.25), Color(0.38, 0.62, 0.28), Color(0.25, 0.48, 0.22), Color(0.45, 0.65, 0.3)]
const LILY := Color(0.3, 0.6, 0.3)
const BLOSSOM := Color(1.0, 0.75, 0.85)
const LAMP_GLOW := Color(1.0, 0.75, 0.4)
const FLOWERS := [Color(0.95, 0.35, 0.4), Color(0.98, 0.8, 0.3), Color(0.75, 0.45, 0.9), Color(1.0, 0.6, 0.75), Color(0.95, 0.95, 0.9)]
const WATER_SHADER := preload("res://shaders/fountain_water.gdshader")

var _materials := {}
var _tree_factory := TreeFactory.new()
var _rng := RandomNumberGenerator.new()
var _body: StaticBody3D
## All path polylines (loop included), for keeping trees and props off them.
var _path_lines: Array[PackedVector3Array] = []


func _ready() -> void:
	add_to_group("park")
	_rng.seed = SEED
	_body = StaticBody3D.new()
	add_child(_body)
	_paths()
	_pond()
	_benches_and_lamps()
	_flower_beds()
	_trees()


func _paths() -> void:
	var loop := PackedVector3Array()
	for i in 41:
		var a := TAU * i / 40.0
		loop.append(Vector3(cos(a) * LOOP_RADII.x, 0, sin(a) * LOOP_RADII.y))
	_path(loop)
	for corners in PATHS:
		_path(PackedVector3Array(corners))


func _path(corners: PackedVector3Array) -> void:
	_path_lines.append(corners)
	var path := StonePath.new()
	path.corners = corners
	path.width = PATH_WIDTH
	add_child(path)


func _distance_to_paths(at: Vector3) -> float:
	var best := INF
	var flat := Vector2(at.x, at.z)
	for line in _path_lines:
		for i in line.size() - 1:
			var closest := Geometry2D.get_closest_point_to_segment(flat, Vector2(line[i].x, line[i].z), Vector2(line[i + 1].x, line[i + 1].z))
			best = minf(best, flat.distance_to(closest))
	return best


## Oval pond: water, rounded stone rim, lily pads with a few blossoms.
func _pond() -> void:
	var water := CylinderMesh.new()
	water.top_radius = 1.0
	water.bottom_radius = 1.0
	water.height = 0.02
	water.radial_segments = 48
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("radius", 1.0)
	material.set_shader_parameter("ripple_density", 3.0)
	material.set_shader_parameter("ripple_speed", 0.0)  # still pond surface
	var water_node := _mesh(water, "", Vector3(0, 0.05, 0))
	water_node.material_override = material
	water_node.scale = Vector3(POND_RADII.x, 1.0, POND_RADII.y)
	var rim := TorusMesh.new()
	rim.inner_radius = 1.0
	rim.outer_radius = 1.0 + 0.6 / POND_RADII.y
	rim.rings = 64
	var rim_node := _mesh(rim, "stone", Vector3(0, 0.08, 0))
	rim_node.scale = Vector3(POND_RADII.x, 0.35, POND_RADII.y)
	for i in 14:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(0.3, 0.82)
		var at := Vector3(cos(a) * POND_RADII.x * r, 0.08, sin(a) * POND_RADII.y * r)
		_cylinder(0.5, 0.5, 0.03, "lily", at, 10)
		if i % 3 == 0:
			var bloom := SphereMesh.new()
			bloom.radius = 0.15
			bloom.height = 0.22
			_mesh(bloom, "blossom", at + Vector3.UP * 0.1)
	var pond_shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.0
	cylinder.height = 2.0
	pond_shape.shape = cylinder
	pond_shape.scale = Vector3(POND_RADII.x + 0.3, 1.0, POND_RADII.y + 0.3)
	pond_shape.position.y = 1.0
	_body.add_child(pond_shape)


## Benches just outside the loop facing the pond; lamp posts between them.
func _benches_and_lamps() -> void:
	for i in 10:
		var a := TAU * (i + 0.5) / 10.0
		var at := Vector3(cos(a) * (LOOP_RADII.x + 2.5), 0, sin(a) * (LOOP_RADII.y + 2.5))
		if _crosses_spoke(at, 2.6):
			continue
		_bench(at, atan2(-at.x, -at.z))
	for i in 6:
		var a := TAU * i / 6.0 + PI / 6.0
		var at := Vector3(cos(a) * (LOOP_RADII.x + 2.3), 0, sin(a) * (LOOP_RADII.y + 2.3))
		if not _crosses_spoke(at, 2.0):
			_lamp(at)


## True if `at` is near one of the straight paths (not the loop).
func _crosses_spoke(at: Vector3, distance: float) -> bool:
	var flat := Vector2(at.x, at.z)
	for line in PATHS:
		for i in line.size() - 1:
			var closest := Geometry2D.get_closest_point_to_segment(flat, Vector2(line[i].x, line[i].z), Vector2(line[i + 1].x, line[i + 1].z))
			if flat.distance_to(closest) < distance:
				return true
	return false


func _bench(at: Vector3, facing: float) -> void:
	var bench := Node3D.new()
	bench.position = at
	bench.rotation.y = facing
	add_child(bench)
	_box(Vector3(2.0, 0.12, 0.6), "wood", Vector3(0, 0.5, 0), bench)
	_box(Vector3(2.0, 0.5, 0.1), "wood", Vector3(0, 0.85, -0.28), bench)
	for x in [-0.85, 0.85]:
		_box(Vector3(0.1, 0.5, 0.55), "iron", Vector3(x, 0.25, 0), bench)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 1.0, 0.7)
	shape.shape = box
	shape.position = at + Vector3.UP * 0.5
	shape.rotation.y = facing
	_body.add_child(shape)


func _lamp(at: Vector3) -> void:
	_cylinder(0.08, 0.1, 2.6, "iron", at, 8)
	_box(Vector3(0.36, 0.42, 0.36), "lamp", at + Vector3.UP * 2.75)
	_box(Vector3(0.48, 0.08, 0.48), "iron", at + Vector3.UP * 3.0)
	var light := OmniLight3D.new()
	light.light_color = LAMP_GLOW
	light.light_energy = 1.2
	light.omni_range = 6.0
	light.position = at + Vector3.UP * 2.6
	add_child(light)


## Small flower beds dotted beside the paths.
func _flower_beds() -> void:
	var placed := 0
	var tries := 0
	while placed < 8 and tries < 500:
		tries += 1
		var at := Vector3(_rng.randf_range(-TREE_AREA.x, TREE_AREA.x) * 0.8, 0, _rng.randf_range(-TREE_AREA.y, TREE_AREA.y) * 0.8)
		var d := _distance_to_paths(at)
		if d < PATH_WIDTH / 2.0 + 1.2 or d > PATH_WIDTH / 2.0 + 2.5 or _in_pond_lawn(at) or _blocked(at):
			continue
		_flower_bed(at, Vector2(_rng.randf_range(1.6, 2.6), _rng.randf_range(1.2, 1.8)))
		placed += 1


func _flower_bed(at: Vector3, size: Vector2) -> void:
	_box(Vector3(size.x, 0.15, size.y), "soil", at + Vector3.UP * 0.075)
	var bloom := SphereMesh.new()
	bloom.radius = 0.13
	bloom.height = 0.22
	bloom.radial_segments = 6
	bloom.rings = 3
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	bloom.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = bloom
	multimesh.instance_count = int(size.x * size.y * 7.0)
	for i in multimesh.instance_count:
		var leaf := i % 3 == 0
		var p := at + Vector3(_rng.randf_range(-size.x / 2.0 + 0.2, size.x / 2.0 - 0.2), 0.25 if leaf else 0.32, _rng.randf_range(-size.y / 2.0 + 0.2, size.y / 2.0 - 0.2))
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (1.4 if leaf else 1.0)), p))
		multimesh.set_instance_color(i, LEAVES[0] if leaf else FLOWERS[_rng.randi() % FLOWERS.size()])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	add_child(instance)


## Trees scattered with density fading toward the edge (no hard boundary),
## clear of paths, the open lawn round the pond, the square and the church.
func _trees() -> void:
	var placed: Array[Vector3] = []
	var tries := 0
	while placed.size() < TREE_COUNT and tries < 4000:
		tries += 1
		var at := Vector3(_rng.randf_range(-TREE_AREA.x, TREE_AREA.x) * 1.1, 0, _rng.randf_range(-TREE_AREA.y, TREE_AREA.y) * 1.1)
		var edge := Vector2(at.x / TREE_AREA.x, at.z / TREE_AREA.y).length()
		if _rng.randf() > 1.0 - smoothstep(0.55, 1.1, edge):
			continue
		if _in_pond_lawn(at) or _distance_to_paths(at) < PATH_WIDTH / 2.0 + 1.3 or _blocked(at):
			continue
		var crowded := false
		for other in placed:
			if other.distance_to(at) < TREE_SPACING:
				crowded = true
				break
		if crowded:
			continue
		placed.append(at)
		_tree_factory.random_tree(self, _body, at, _rng)


## World-space test used by the town tree scatter: is `point` in the park?
func contains(point: Vector3) -> bool:
	var local := to_local(point)
	return Vector2(local.x / TREE_AREA.x, local.z / TREE_AREA.y).length() < 1.15


## Open lawn between the pond and the loop path stays clear.
func _in_pond_lawn(at: Vector3) -> bool:
	return Vector2(at.x / LOOP_RADII.x, at.z / LOOP_RADII.y).length() < 1.0


## World-space keep-clear zones (square, church).
func _blocked(at: Vector3) -> bool:
	var world := global_transform * at
	for zone: Rect2 in KEEP_CLEAR:
		if zone.has_point(Vector2(world.x, world.z)):
			return true
	return false


func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.roughness = 0.9
	match key:
		"stone": material.albedo_color = STONE
		"wood": material.albedo_color = WOOD
		"lily": material.albedo_color = LILY
		"blossom": material.albedo_color = BLOSSOM
		"soil": material.albedo_color = Color(0.36, 0.25, 0.16)
		"iron":
			material.albedo_color = IRON
			material.metallic = 0.6
			material.roughness = 0.45
		"lamp":
			material.albedo_color = LAMP_GLOW
			material.emission_enabled = true
			material.emission = LAMP_GLOW
			material.emission_energy_multiplier = 3.0
	_materials[key] = material
	return material


func _mesh(mesh: Mesh, key: String, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	if key != "":
		instance.material_override = _material(key)
	instance.position = at
	(parent if parent else self).add_child(instance)
	return instance


func _box(size: Vector3, key: String, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(box, key, at, parent)


## Cylinder (or cone when top = 0) standing on `at`.
func _cylinder(top: float, bottom: float, height: float, key: String, at: Vector3, sides: int) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = sides
	return _mesh(cylinder, key, at + Vector3.UP * height / 2.0)
