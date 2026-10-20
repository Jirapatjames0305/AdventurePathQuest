class_name Park
extends Node3D
## A large public park built from primitives: lawn inside a clipped hedge
## border, a loop footpath around an oval pond (stone rim, lily pads), entrance
## paths, benches facing the pond, lamp posts, flower beds and trees.
## Coordinates are local to the park centre, axis-aligned with the town.
## SIZE.x runs along local X, SIZE.y along local Z.

const SIZE := Vector2(34.0, 28.0)
const LOOP_RADII := Vector2(11.0, 8.5)
const POND_RADII := Vector2(6.0, 4.2)
const PATH_WIDTH := 2.6
const HEDGE_HEIGHT := 1.0
const HEDGE_WIDTH := 0.9
## Entrance gaps in the hedge: [side ("x-", "x+", "z-", "z+"), offset along that side].
const ENTRANCES := [["z+", -12.0], ["z+", 10.0]]
const TREE_COUNT := 30
const SEED := 4242

const LAWN := Color(0.5, 0.72, 0.36)
const HEDGE := Color(0.22, 0.45, 0.22)
const STONE := Color(0.7, 0.68, 0.63)
const WOOD := Color(0.5, 0.33, 0.2)
const IRON := Color(0.15, 0.15, 0.17)
const TRUNK := Color(0.42, 0.28, 0.17)
const LEAVES := [Color(0.3, 0.55, 0.25), Color(0.38, 0.62, 0.28), Color(0.25, 0.48, 0.22), Color(0.45, 0.65, 0.3)]
const PINE := Color(0.2, 0.42, 0.25)
const LILY := Color(0.3, 0.6, 0.3)
const BLOSSOM := Color(1.0, 0.75, 0.85)
const LAMP_GLOW := Color(1.0, 0.75, 0.4)
const FLOWERS := [Color(0.95, 0.35, 0.4), Color(0.98, 0.8, 0.3), Color(0.75, 0.45, 0.9), Color(1.0, 0.6, 0.75), Color(0.95, 0.95, 0.9)]
const WATER_SHADER := preload("res://shaders/fountain_water.gdshader")

var _materials := {}
var _rng := RandomNumberGenerator.new()
var _body: StaticBody3D


func _ready() -> void:
	_rng.seed = SEED
	_body = StaticBody3D.new()
	add_child(_body)
	_lawn()
	_hedges()
	_paths()
	_pond()
	_benches_and_lamps()
	_flower_beds()
	_trees()


func _lawn() -> void:
	var plane := PlaneMesh.new()
	plane.size = SIZE
	_mesh(plane, "lawn", Vector3(0, 0.01, 0))


## Hedge boxes around the edge, leaving gaps where the entrances are.
func _hedges() -> void:
	var half := SIZE / 2.0
	var gap := PATH_WIDTH + 1.0
	for side in ["x-", "x+", "z-", "z+"]:
		var along_x: bool = side.begins_with("z")
		var length: float = SIZE.x if along_x else SIZE.y
		var cuts := [-length / 2.0]
		for entrance in ENTRANCES:
			if entrance[0] == side:
				cuts.append(entrance[1] - gap / 2.0)
				cuts.append(entrance[1] + gap / 2.0)
		cuts.append(length / 2.0)
		for i in range(0, cuts.size(), 2):
			var from: float = cuts[i]
			var to: float = cuts[i + 1]
			var center := (from + to) / 2.0
			var at: Vector3
			var size: Vector3
			if along_x:
				at = Vector3(center, HEDGE_HEIGHT / 2.0, half.y * (1.0 if side == "z+" else -1.0))
				size = Vector3(to - from, HEDGE_HEIGHT, HEDGE_WIDTH)
			else:
				at = Vector3(half.x * (1.0 if side == "x+" else -1.0), HEDGE_HEIGHT / 2.0, center)
				size = Vector3(HEDGE_WIDTH, HEDGE_HEIGHT, to - from)
			_box(size, "hedge", at)
			_collider(size, at)


## Loop path around the pond plus one straight path in from each entrance.
func _paths() -> void:
	var loop := PackedVector3Array()
	for i in 33:
		var a := TAU * i / 32.0
		loop.append(Vector3(cos(a) * LOOP_RADII.x, 0, sin(a) * LOOP_RADII.y))
	_path(loop)
	var half := SIZE / 2.0
	for entrance in ENTRANCES:
		var offset: float = entrance[1]
		match entrance[0]:
			"z+":
				var join_z := LOOP_RADII.y * sqrt(maxf(0.0, 1.0 - pow(offset / LOOP_RADII.x, 2.0)))
				_path(PackedVector3Array([Vector3(offset, 0, half.y), Vector3(offset, 0, join_z)]))
			"x-":
				_path(PackedVector3Array([Vector3(-half.x, 0, offset), Vector3(-LOOP_RADII.x, 0, offset)]))


func _path(corners: PackedVector3Array) -> void:
	var path := StonePath.new()
	path.corners = corners
	path.width = PATH_WIDTH
	add_child(path)


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
	var water_node := _mesh(water, "", Vector3(0, 0.05, 0))
	water_node.material_override = material
	water_node.scale = Vector3(POND_RADII.x, 1.0, POND_RADII.y)
	var rim := TorusMesh.new()
	rim.inner_radius = 1.0
	rim.outer_radius = 1.0 + 0.6 / POND_RADII.y
	rim.rings = 48
	var rim_node := _mesh(rim, "stone", Vector3(0, 0.08, 0))
	rim_node.scale = Vector3(POND_RADII.x, 0.35, POND_RADII.y)
	for i in 9:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(0.3, 0.8)
		var at := Vector3(cos(a) * POND_RADII.x * r, 0.08, sin(a) * POND_RADII.y * r)
		_cylinder(0.45, 0.45, 0.03, "lily", at, 10)
		if i % 3 == 0:
			var bloom := SphereMesh.new()
			bloom.radius = 0.14
			bloom.height = 0.2
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
	for i in 6:
		var a := TAU * (i + 0.5) / 6.0
		var at := Vector3(cos(a) * (LOOP_RADII.x + 2.4), 0, sin(a) * (LOOP_RADII.y + 2.4))
		if _near_entrance_path(at, 2.5):
			continue
		_bench(at, atan2(-at.x, -at.z))
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		_lamp(Vector3(cos(a) * (LOOP_RADII.x + 2.2), 0, sin(a) * (LOOP_RADII.y + 2.2)))


func _bench(at: Vector3, facing: float) -> void:
	var bench := Node3D.new()
	bench.position = at
	bench.rotation.y = facing
	add_child(bench)
	_box(Vector3(2.0, 0.12, 0.6), "wood", Vector3(0, 0.5, 0), bench)
	_box(Vector3(2.0, 0.5, 0.1), "wood", Vector3(0, 0.85, -0.28), bench)
	for x in [-0.85, 0.85]:
		_box(Vector3(0.1, 0.5, 0.55), "iron", Vector3(x, 0.25, 0), bench)
	_collider(Vector3(2.0, 1.0, 0.7), at + Vector3.UP * 0.5)


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


## Flower beds either side of each entrance.
func _flower_beds() -> void:
	var half := SIZE / 2.0
	for entrance in ENTRANCES:
		var offset: float = entrance[1]
		var spots := []
		match entrance[0]:
			"z+":
				for side in [-1.0, 1.0]:
					spots.append(Vector3(offset + side * 3.0, 0, half.y - 2.0))
			"x-":
				for side in [-1.0, 1.0]:
					spots.append(Vector3(-half.x + 2.0, 0, offset + side * 3.0))
		for spot in spots:
			_flower_bed(spot, Vector2(2.0, 2.0))


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
	multimesh.instance_count = 28
	for i in multimesh.instance_count:
		var leaf := i % 3 == 0
		var p := at + Vector3(_rng.randf_range(-size.x / 2.0 + 0.2, size.x / 2.0 - 0.2), 0.25 if leaf else 0.32, _rng.randf_range(-size.y / 2.0 + 0.2, size.y / 2.0 - 0.2))
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (1.4 if leaf else 1.0)), p))
		multimesh.set_instance_color(i, LEAVES[0] if leaf else FLOWERS[_rng.randi() % FLOWERS.size()])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	add_child(instance)


## Round-crowned and pine trees scattered in the lawn, clear of paths and pond.
func _trees() -> void:
	var half := SIZE / 2.0 - Vector2.ONE * 2.0
	var placed: Array[Vector3] = []
	var tries := 0
	while placed.size() < TREE_COUNT and tries < 2000:
		tries += 1
		var at := Vector3(_rng.randf_range(-half.x, half.x), 0, _rng.randf_range(-half.y, half.y))
		var loop_d := Vector2(at.x / LOOP_RADII.x, at.z / LOOP_RADII.y).length()
		if absf(loop_d - 1.0) < 0.28 or loop_d < 1.0:
			continue  # on the loop path, or inside it (pond area)
		if _near_entrance_path(at, 2.8):
			continue
		var crowded := false
		for other in placed:
			if other.distance_to(at) < 3.6:
				crowded = true
				break
		if crowded:
			continue
		placed.append(at)
		if _rng.randf() < 0.3:
			_pine(at, _rng.randf_range(0.9, 1.3))
		else:
			_round_tree(at, _rng.randf_range(0.8, 1.3))


func _round_tree(at: Vector3, size: float) -> void:
	_cylinder(0.18 * size, 0.26 * size, 2.2 * size, "trunk", at, 8)
	var leaves := "leaves%d" % (_rng.randi() % LEAVES.size())
	for n in 3:
		var crown := SphereMesh.new()
		crown.radius = (1.3 - n * 0.2) * size
		crown.height = crown.radius * 1.8
		crown.radial_segments = 10
		crown.rings = 5
		var offset := Vector3(_rng.randf_range(-0.5, 0.5), 2.6 + n * 0.7, _rng.randf_range(-0.5, 0.5)) * size
		_mesh(crown, leaves, at + offset)
	_trunk_collider(at, 0.35 * size)


func _pine(at: Vector3, size: float) -> void:
	_cylinder(0.16 * size, 0.22 * size, 1.2 * size, "trunk", at, 8)
	for n in 3:
		var radius := (1.5 - n * 0.4) * size
		_cylinder(0.0, radius, 1.8 * size, "pine", at + Vector3.UP * (0.9 + n * 1.1) * size, 10)
	_trunk_collider(at, 0.3 * size)


func _trunk_collider(at: Vector3, radius: float) -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 3.0
	shape.shape = cylinder
	shape.position = at + Vector3.UP * 1.5
	_body.add_child(shape)


func _near_entrance_path(at: Vector3, distance: float) -> bool:
	for entrance in ENTRANCES:
		var offset: float = entrance[1]
		match entrance[0]:
			"z+":
				if absf(at.x - offset) < distance and at.z > 0.0:
					return true
			"x-":
				if absf(at.z - offset) < distance and at.x < 0.0:
					return true
	return false


func _collider(size: Vector3, at: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	_body.add_child(shape)


func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.roughness = 0.9
	if key.begins_with("leaves"):
		material.albedo_color = LEAVES[int(key.substr(6))]
	else:
		match key:
			"lawn": material.albedo_color = LAWN
			"hedge": material.albedo_color = HEDGE
			"stone": material.albedo_color = STONE
			"wood": material.albedo_color = WOOD
			"trunk": material.albedo_color = TRUNK
			"pine": material.albedo_color = PINE
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
