class_name Tavern
extends Node3D
## A big three-storey tavern built from primitives. What makes it read as a
## tavern rather than housing: a stone ground floor with a wide arched double
## door and big arched windows, a porch roof with lanterns, a large hanging
## sign with a foaming mug, outdoor tables with stools, stacked barrels, and a
## smoking chimney. Upper floors are jettied timber framing with only a few
## shuttered windows. Local +Z is the front (entrance).

const STONE := Color(0.58, 0.55, 0.5)
const WALL := Color(0.94, 0.88, 0.74)
const BEAM := Color(0.32, 0.2, 0.12)
const ROOF := Color(0.45, 0.22, 0.18)
const WOOD := Color(0.52, 0.35, 0.2)
const SHUTTER := Color(0.25, 0.45, 0.32)
const GOLD := Color(0.92, 0.74, 0.32)
const FOAM := Color(0.98, 0.96, 0.9)
const WINDOW_GLOW := Color(1.0, 0.72, 0.36)
const FLOWERS := [Color(0.95, 0.35, 0.4), Color(0.98, 0.8, 0.3), Color(0.75, 0.45, 0.9)]

const BASE := Vector3(12.0, 3.4, 9.0)
const FLOOR_HEIGHT := 3.0
## Each upper floor sticks out this much further on the front and back.
const JETTY := 0.5
const ROOF_HEIGHT := 4.5
const PORCH_DEPTH := 2.6

var _materials := {}


func _ready() -> void:
	_box(Vector3(BASE.x + 0.4, 0.3, BASE.z + 0.4), "stone", Vector3(0, 0.15, 0))
	_box(BASE, "stone", Vector3(0, 0.3 + BASE.y / 2.0, 0))
	var top := 0.3 + BASE.y
	var depth := BASE.z
	for floor_index in 2:
		depth += JETTY * 2.0
		_upper_floor(top, depth)
		top += FLOOR_HEIGHT
	_roof(top, depth)
	_ground_floor()
	_porch()
	_sign()
	_beer_garden()
	_add_collision()


## Stone ground floor: arched double door, two big arched windows, side windows.
func _ground_floor() -> void:
	var front := BASE.z / 2.0
	_arch_opening(Vector3(0, 0.3, front), 2.8, 2.6, "beam")
	_box(Vector3(0.08, 2.6, 0.2), "gold", Vector3(0, 0.3 + 1.3, front + 0.1))
	_box(Vector3(3.4, 0.2, 1.2), "stone", Vector3(0, 0.1, front + 0.6))
	for x in [-3.8, 3.8]:
		_arch_opening(Vector3(x, 0.3 + 0.7, front), 2.4, 1.6, "window")
		_box(Vector3(2.6, 0.18, 0.35), "stone", Vector3(x, 0.3 + 0.62, front + 0.12))
	for side in [-1.0, 1.0]:
		_window(Vector3(side * BASE.x / 2.0, 0.3 + 1.8, 0), Vector3(side, 0, 0), false)


## A rectangle topped with a half-disc, flush on the front wall.
func _arch_opening(base: Vector3, width: float, height: float, key: String) -> void:
	_box(Vector3(width + 0.3, height + 0.15, 0.1), "stone_dark", base + Vector3(0, height / 2.0, 0.02))
	_box(Vector3(width, height, 0.12), key, base + Vector3(0, height / 2.0, 0.05))
	var arch := _cylinder(width / 2.0, width / 2.0, 0.12, key, Vector3.ZERO, 20)
	arch.rotation.x = PI / 2.0
	arch.position = base + Vector3(0, height, 0.05)


## One jettied timber-framed storey with a few shuttered, flower-boxed windows.
func _upper_floor(bottom: float, depth: float) -> void:
	var y := bottom + FLOOR_HEIGHT / 2.0
	_box(Vector3(BASE.x, FLOOR_HEIGHT, depth), "wall", Vector3(0, y, 0))
	var half_z := depth / 2.0
	_box(Vector3(BASE.x + 0.2, 0.28, depth + 0.2), "beam", Vector3(0, bottom + 0.14, 0))
	for x in [-6.0, -2.0, 2.0, 6.0]:
		for z in [-half_z, half_z]:
			_box(Vector3(0.22, FLOOR_HEIGHT, 0.22), "beam", Vector3(x, y, z))
	for z in [-half_z, half_z]:
		for x in [-4.0, 4.0]:
			var brace := _box(Vector3(0.16, FLOOR_HEIGHT * 1.2, 0.18), "beam", Vector3(x, y, z))
			brace.rotation.z = deg_to_rad(38.0 if x < 0 else -38.0)
		_window(Vector3(0, bottom + 1.5, z), Vector3(0, 0, signf(z)), true)
	for side in [-1.0, 1.0]:
		_window(Vector3(side * BASE.x / 2.0, bottom + 1.5, 0), Vector3(side, 0, 0), true)


func _roof(bottom: float, depth: float) -> void:
	var roof := PrismMesh.new()
	roof.size = Vector3(depth + 1.2, ROOF_HEIGHT, BASE.x + 1.0)
	var node := _mesh(roof, "roof", Vector3(0, bottom + ROOF_HEIGHT / 2.0, 0))
	node.rotation.y = PI / 2.0
	# One big central dormer on the front slope.
	var at := Vector3(0, bottom + 1.3, depth / 4.0 + 0.2)
	_box(Vector3(2.2, 1.8, 1.6), "wall", at)
	var cap := PrismMesh.new()
	cap.size = Vector3(2.6, 1.0, 1.8)
	_mesh(cap, "roof", at + Vector3(0, 1.4, 0))
	_box(Vector3(1.2, 1.0, 0.1), "window", at + Vector3(0, 0.0, 0.82))
	var chimney := Vector3(4.6, bottom + ROOF_HEIGHT - 0.4, -1.2)
	_box(Vector3(1.2, 3.4, 1.2), "stone", chimney)
	add_child(_smoke(chimney + Vector3.UP * 1.9))


## Wooden porch roof across the front with posts and two hanging lanterns.
func _porch() -> void:
	var front := BASE.z / 2.0
	var roof := _box(Vector3(BASE.x - 0.6, 0.18, PORCH_DEPTH + 0.4), "roof", Vector3(0, 0.3 + 3.25, front + PORCH_DEPTH / 2.0))
	roof.rotation.x = deg_to_rad(14.0)
	for x in [-5.4, -1.8, 1.8, 5.4]:
		_box(Vector3(0.24, 3.0, 0.24), "beam", Vector3(x, 0.3 + 1.5, front + PORCH_DEPTH - 0.1))
	for x in [-1.8, 1.8]:
		var lamp := Vector3(x, 0.3 + 2.55, front + PORCH_DEPTH - 0.1)
		_box(Vector3(0.34, 0.44, 0.34), "window", lamp)
		_box(Vector3(0.42, 0.08, 0.42), "beam", lamp + Vector3.UP * 0.26)
		var light := OmniLight3D.new()
		light.light_color = WINDOW_GLOW
		light.light_energy = 1.6
		light.omni_range = 6.0
		light.position = lamp + Vector3(0, -0.2, 0.3)
		add_child(light)


## Big sign board on an iron bracket off the front corner, with a foaming mug.
func _sign() -> void:
	var front := BASE.z / 2.0
	var anchor := Vector3(BASE.x / 2.0 - 0.3, 0.3 + BASE.y + 1.6, front + JETTY)
	_box(Vector3(0.12, 0.12, 2.0), "iron", anchor + Vector3(0, 0, 1.0))
	for z in [0.5, 1.6]:
		_box(Vector3(0.03, 0.5, 0.03), "iron", anchor + Vector3(0, -0.25, z))
	var board := anchor + Vector3(0, -1.3, 1.05)
	_box(Vector3(0.12, 1.8, 2.0), "beam", board)
	_box(Vector3(0.16, 1.6, 1.8), "wood", board)
	# Mug on both faces of the board.
	for side in [-1.0, 1.0]:
		var mug := board + Vector3(side * 0.14, -0.1, 0)
		_cylinder(0.32, 0.3, 0.8, "gold", mug + Vector3(0, -0.4, 0), 14)
		var foam := SphereMesh.new()
		foam.radius = 0.36
		foam.height = 0.42
		_mesh(foam, "foam", mug + Vector3(0, 0.42, 0))
		var handle := TorusMesh.new()
		handle.inner_radius = 0.12
		handle.outer_radius = 0.22
		var handle_node := _mesh(handle, "gold", mug + Vector3(0, 0.0, -0.4))
		handle_node.rotation.x = PI / 2.0
		handle_node.rotation.y = PI / 2.0


## Outdoor tables and stools either side of the entrance, stacked barrels, a keg cart.
func _beer_garden() -> void:
	var front := BASE.z / 2.0 + PORCH_DEPTH + 1.6
	for x in [-4.6, 4.6]:
		var table := Vector3(x, 0, front)
		_cylinder(0.12, 0.18, 0.9, "wood", table, 8)
		_cylinder(0.75, 0.75, 0.1, "wood", table + Vector3.UP * 0.9, 16)
		_cylinder(0.12, 0.12, 0.1, "foam", table + Vector3(0.25, 1.0, 0.1), 8)
		_cylinder(0.1, 0.1, 0.22, "gold", table + Vector3(0.25, 1.0, 0.1), 8)
		for angle in [0.0, PI / 2.0, PI, PI * 1.5]:
			var stool := table + Vector3(cos(angle), 0, sin(angle)) * 1.2
			_cylinder(0.25, 0.25, 0.55, "wood", stool, 10)
	# Barrel pyramid 3-2-1 against the side wall.
	var stack := Vector3(-BASE.x / 2.0 - 0.6, 0, 1.5)
	for row in 3:
		for n in 3 - row:
			var barrel := _cylinder(0.42, 0.42, 0.95, "wood", Vector3.ZERO, 12)
			barrel.rotation.x = PI / 2.0
			barrel.position = stack + Vector3(0, 0.42 + row * 0.8, (n - (2 - row) / 2.0) * 0.86)
			_cylinder(0.43, 0.43, 0.08, "iron", Vector3.ZERO, 12).position = barrel.position + Vector3(0, 0, 0.3)
	_cylinder(0.45, 0.4, 1.0, "wood", Vector3(5.4, 0.3, BASE.z / 2.0 + 0.6), 12)
	_cylinder(0.45, 0.4, 1.0, "wood", Vector3(4.5, 0.3, BASE.z / 2.0 + 0.6), 12)


func _smoke(at: Vector3) -> GPUParticles3D:
	var smoke := GPUParticles3D.new()
	smoke.amount = 24
	smoke.lifetime = 4.0
	smoke.position = at
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 12.0
	process.initial_velocity_min = 0.7
	process.initial_velocity_max = 1.1
	process.gravity = Vector3(0.2, 0.1, 0.0)
	process.scale_min = 0.6
	process.scale_max = 1.3
	var fade := Gradient.new()
	fade.set_color(0, Color(0.65, 0.65, 0.65, 0.5))
	fade.set_color(1, Color(0.85, 0.85, 0.85, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	smoke.process_material = process
	var puff := SphereMesh.new()
	puff.radius = 0.4
	puff.height = 0.8
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = material
	smoke.draw_pass_1 = puff
	return smoke


## Lit window; upper-floor windows get green shutters and a flower box.
func _window(at: Vector3, facing: Vector3, shutters: bool) -> void:
	var yaw := atan2(facing.x, facing.z)
	var right := Vector3(facing.z, 0, -facing.x)
	_rotated_box(Vector3(1.2, 1.4, 0.1), "beam", at + facing * 0.02, yaw)
	_rotated_box(Vector3(0.95, 1.15, 0.1), "window", at + facing * 0.05, yaw)
	_rotated_box(Vector3(0.06, 1.15, 0.12), "beam", at + facing * 0.08, yaw)
	if not shutters:
		return
	for side in [-1.0, 1.0]:
		_rotated_box(Vector3(0.5, 1.3, 0.08), "shutter", at + right * side * 0.88 + facing * 0.06, yaw)
	_rotated_box(Vector3(1.3, 0.25, 0.35), "wood", at + Vector3.DOWN * 0.8 + facing * 0.2, yaw)
	for n in 5:
		var bloom := SphereMesh.new()
		bloom.radius = 0.12
		bloom.height = 0.24
		_mesh(bloom, "flower%d" % (n % FLOWERS.size()), at + Vector3.DOWN * 0.6 + facing * 0.22 + right * (n - 2) * 0.24)


func _rotated_box(size: Vector3, key: String, at: Vector3, yaw: float) -> MeshInstance3D:
	var node := _box(size, key, at)
	node.rotation.y = yaw
	return node


func _add_collision() -> void:
	var body := StaticBody3D.new()
	for entry in [
		[Vector3(BASE.x + 0.6, 4.0, BASE.z + PORCH_DEPTH + 0.4), Vector3(0, 2.0, PORCH_DEPTH / 2.0)],
		[Vector3(1.8, 3.0, 3.0), Vector3(-BASE.x / 2.0 - 0.6, 1.5, 1.5)],
	]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = entry[0]
		shape.shape = box
		shape.position = entry[1]
		body.add_child(shape)
	add_child(body)


func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.roughness = 0.85
	match key:
		"stone": material.albedo_color = STONE
		"stone_dark": material.albedo_color = STONE.darkened(0.25)
		"wall": material.albedo_color = WALL
		"beam": material.albedo_color = BEAM
		"roof": material.albedo_color = ROOF
		"wood": material.albedo_color = WOOD
		"shutter": material.albedo_color = SHUTTER
		"foam": material.albedo_color = FOAM
		"iron":
			material.albedo_color = Color(0.2, 0.2, 0.22)
			material.metallic = 0.7
			material.roughness = 0.4
		"gold":
			material.albedo_color = GOLD
			material.metallic = 0.8
			material.roughness = 0.3
		"window":
			material.albedo_color = WINDOW_GLOW
			material.emission_enabled = true
			material.emission = WINDOW_GLOW
			material.emission_energy_multiplier = 1.8
		_:
			material.albedo_color = FLOWERS[int(key.substr(6))]
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
