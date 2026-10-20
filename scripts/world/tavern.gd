class_name Tavern
extends Node3D
## A big three-storey tavern built from primitives: stone ground floor,
## jettied timber-framed upper floors (each overhangs the one below), wooden
## balconies on the front, steep roof with dormers and chimneys, lit windows
## on every side, a hanging mug sign, lanterns, barrels and benches.
## Local +Z is the front (entrance).

const STONE := Color(0.58, 0.55, 0.5)
const WALL := Color(0.94, 0.88, 0.74)
const BEAM := Color(0.32, 0.2, 0.12)
const ROOF := Color(0.45, 0.22, 0.18)
const WOOD := Color(0.52, 0.35, 0.2)
const GOLD := Color(0.92, 0.74, 0.32)
const WINDOW_GLOW := Color(1.0, 0.76, 0.4)

const BASE := Vector3(12.0, 3.4, 9.0)
const FLOOR_HEIGHT := 3.0
## Each upper floor sticks out this much further on the front and back.
const JETTY := 0.5
const ROOF_HEIGHT := 4.5

var _materials := {}


func _ready() -> void:
	_box(Vector3(BASE.x + 0.4, 0.3, BASE.z + 0.4), "stone", Vector3(0, 0.15, 0))
	_box(BASE, "stone", Vector3(0, 0.3 + BASE.y / 2.0, 0))
	var top := 0.3 + BASE.y
	var depth := BASE.z
	for floor_index in 2:
		depth += JETTY * 2.0
		_upper_floor(top, depth, floor_index)
		top += FLOOR_HEIGHT
	_roof(top, depth)
	_ground_floor_front()
	_windows_around(0.3 + 1.7, BASE.z, 3)
	_add_collision()


## One jettied timber-framed storey with a balcony across the front.
func _upper_floor(bottom: float, depth: float, floor_index: int) -> void:
	var y := bottom + FLOOR_HEIGHT / 2.0
	_box(Vector3(BASE.x, FLOOR_HEIGHT, depth), "wall", Vector3(0, y, 0))
	var half_z := depth / 2.0
	_box(Vector3(BASE.x + 0.2, 0.28, depth + 0.2), "beam", Vector3(0, bottom + 0.14, 0))
	for x in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		for z in [-half_z, half_z]:
			_box(Vector3(0.22, FLOOR_HEIGHT, 0.22), "beam", Vector3(x, y, z))
	for z in [-half_z, half_z]:
		# Cross braces between posts.
		for x in [-4.5, 4.5]:
			var brace := _box(Vector3(0.16, FLOOR_HEIGHT * 1.15, 0.18), "beam", Vector3(x, y, z))
			brace.rotation.z = deg_to_rad(42.0 if x < 0 else -42.0)
	_windows_around(bottom + 1.6, depth, 4)
	# Balcony: floorboards, posts and a railing along the front.
	var front := half_z + 0.9
	_box(Vector3(BASE.x - 1.0 - floor_index, 0.18, 1.8), "wood", Vector3(0, bottom + 0.1, half_z + 0.9))
	_box(Vector3(BASE.x - 1.0 - floor_index, 0.12, 0.12), "wood", Vector3(0, bottom + 1.05, front + 0.85))
	for n in 9 - floor_index:
		var x := -(BASE.x - 1.0 - floor_index) / 2.0 + n * (BASE.x - 1.0 - floor_index) / (8 - floor_index)
		_box(Vector3(0.1, 1.0, 0.1), "wood", Vector3(x, bottom + 0.6, front + 0.85))
	for x in [-(BASE.x - 1.0 - floor_index) / 2.0, (BASE.x - 1.0 - floor_index) / 2.0]:
		_box(Vector3(0.16, 1.0, 1.8), "wood", Vector3(x, bottom + 0.6, half_z + 0.9))


func _roof(bottom: float, depth: float) -> void:
	var roof := PrismMesh.new()
	roof.size = Vector3(depth + 1.2, ROOF_HEIGHT, BASE.x + 1.0)
	var node := _mesh(roof, "roof", Vector3(0, bottom + ROOF_HEIGHT / 2.0, 0))
	node.rotation.y = PI / 2.0
	# Dormers on the front slope.
	for x in [-3.5, 3.5]:
		var at := Vector3(x, bottom + 1.2, depth / 4.0 + 0.3)
		_box(Vector3(1.6, 1.6, 1.4), "wall", at)
		var cap := PrismMesh.new()
		cap.size = Vector3(1.9, 0.9, 1.6)
		_mesh(cap, "roof", at + Vector3(0, 1.25, 0))
		_box(Vector3(0.9, 0.9, 0.1), "window", at + Vector3(0, 0.0, 0.72))
	for x in [-4.8, 4.8]:
		_box(Vector3(1.0, 3.2, 1.0), "stone", Vector3(x, bottom + ROOF_HEIGHT - 0.6, -1.0))


## Door, hanging sign, lanterns, barrels and benches at street level.
func _ground_floor_front() -> void:
	var front := BASE.z / 2.0
	_box(Vector3(2.2, 2.6, 0.15), "beam", Vector3(0, 0.3 + 1.3, front + 0.03))
	_box(Vector3(0.08, 0.08, 0.06), "gold", Vector3(0.6, 0.3 + 1.3, front + 0.12))
	_box(Vector3(2.8, 0.2, 1.0), "stone", Vector3(0, 0.1, front + 0.5))
	# Sign bracket with a hanging board and a golden mug.
	_box(Vector3(0.12, 0.12, 1.6), "beam", Vector3(-2.2, 0.3 + 3.0, front + 0.8))
	_box(Vector3(1.2, 0.9, 0.08), "wood", Vector3(-2.2, 0.3 + 2.4, front + 1.4))
	_cylinder(0.18, 0.16, 0.42, "gold", Vector3(-2.2, 0.3 + 2.2, front + 1.46), 10)
	for x in [-1.6, 1.6]:
		var lamp := Vector3(x, 0.3 + 2.6, front + 0.25)
		_box(Vector3(0.3, 0.4, 0.3), "window", lamp)
		var light := OmniLight3D.new()
		light.light_color = WINDOW_GLOW
		light.light_energy = 1.2
		light.omni_range = 5.0
		light.position = lamp + Vector3(0, 0, 0.3)
		add_child(light)
	for x in [-5.2, -4.4, 4.6]:
		_cylinder(0.42, 0.38, 0.95, "wood", Vector3(x, 0.3, front + 0.6), 12)
	for x in [-3.6, 3.4]:
		_box(Vector3(1.8, 0.12, 0.45), "wood", Vector3(x, 0.3 + 0.45, front + 0.55))
		for leg in [-0.75, 0.75]:
			_box(Vector3(0.12, 0.45, 0.4), "wood", Vector3(x + leg, 0.3 + 0.22, front + 0.55))


## Evenly spaced lit windows on the front and back, and on both ends.
func _windows_around(y: float, depth: float, per_side: int) -> void:
	var half_z := depth / 2.0
	var half_x := BASE.x / 2.0
	for n in per_side:
		var x := -half_x + (n + 0.5) * BASE.x / per_side
		if per_side == 3 and n == 1:
			continue  # front door goes here on the ground floor
		for side in [-1.0, 1.0]:
			_window(Vector3(x, y, side * half_z), Vector3(0, 0, side))
	for side in [-1.0, 1.0]:
		_window(Vector3(side * half_x, y, 0), Vector3(side, 0, 0))


func _window(at: Vector3, facing: Vector3) -> void:
	var frame := _box(Vector3(1.1, 1.3, 0.1), "beam", at + facing * 0.02)
	frame.rotation.y = atan2(facing.x, facing.z)
	var pane := _box(Vector3(0.85, 1.05, 0.1), "window", at + facing * 0.05)
	pane.rotation.y = frame.rotation.y


func _add_collision() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BASE.x + 0.6, 4.0, BASE.z + 2.2)
	shape.shape = box
	shape.position = Vector3(0, 2.0, 0.6)
	body.add_child(shape)
	add_child(body)


func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.roughness = 0.85
	match key:
		"stone": material.albedo_color = STONE
		"wall": material.albedo_color = WALL
		"beam": material.albedo_color = BEAM
		"roof": material.albedo_color = ROOF
		"wood": material.albedo_color = WOOD
		"gold":
			material.albedo_color = GOLD
			material.metallic = 0.8
			material.roughness = 0.3
		"window":
			material.albedo_color = WINDOW_GLOW
			material.emission_enabled = true
			material.emission = WINDOW_GLOW
			material.emission_energy_multiplier = 1.5
	_materials[key] = material
	return material


func _mesh(mesh: Mesh, key: String, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(key)
	instance.position = at
	add_child(instance)
	return instance


func _box(size: Vector3, key: String, at: Vector3) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(box, key, at)


## Cylinder standing on `at`.
func _cylinder(top: float, bottom: float, height: float, key: String, at: Vector3, sides: int) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = sides
	return _mesh(cylinder, key, at + Vector3.UP * height / 2.0)
