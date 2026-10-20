class_name Blacksmith
extends Node3D
## A big blacksmith's workshop built from primitives: stone ground floor,
## timber-framed upper floor, steep roof, tall stone chimney with smoke, and
## an open forge yard at the front under a lean-to — glowing forge with
## flickering light and embers, anvil, quench barrel, grindstone, weapon rack.
## Local +Z is the front (forge yard).

const STONE := Color(0.55, 0.53, 0.5)
const STONE_DARK := Color(0.4, 0.38, 0.36)
const WALL := Color(0.9, 0.84, 0.72)
const BEAM := Color(0.33, 0.21, 0.13)
const ROOF := Color(0.38, 0.3, 0.26)
const IRON := Color(0.22, 0.22, 0.24)
const WOOD := Color(0.5, 0.34, 0.2)
const COALS := Color(1.0, 0.45, 0.12)
const WINDOW_GLOW := Color(1.0, 0.75, 0.4)

const BODY := Vector3(10.0, 3.6, 7.0)
const UPPER := 3.0
const ROOF_HEIGHT := 3.4
const YARD_DEPTH := 4.5

var _materials := {}
var _forge_light: OmniLight3D
var _time := 0.0


func _ready() -> void:
	var half := BODY / 2.0
	_box(Vector3(BODY.x + 0.3, 0.3, BODY.z + YARD_DEPTH + 0.3), "stone_dark", Vector3(0, 0.15, YARD_DEPTH / 2.0))
	_box(BODY, "stone", Vector3(0, 0.3 + half.y, 0))
	_box(Vector3(BODY.x, UPPER, BODY.z), "wall", Vector3(0, 0.3 + BODY.y + UPPER / 2.0, 0))
	_build_frame(half)
	var roof := PrismMesh.new()
	roof.size = Vector3(BODY.z + 1.0, ROOF_HEIGHT, BODY.x + 0.8)
	var roof_node := _mesh(roof, "roof", Vector3(0, 0.3 + BODY.y + UPPER + ROOF_HEIGHT / 2.0, 0))
	roof_node.rotation.y = PI / 2.0
	_build_chimney(Vector3(-half.x + 1.4, 0.3, -0.5))
	for x in [-2.8, 2.8]:
		_window(Vector3(x, 0.3 + BODY.y + 1.5, half.z), Vector2(1.2, 1.1))
	# Big double doors into the workshop.
	_box(Vector3(2.6, 2.8, 0.15), "beam", Vector3(2.2, 0.3 + 1.4, half.z + 0.02))
	_box(Vector3(0.08, 2.7, 0.18), "iron", Vector3(2.2, 0.3 + 1.4, half.z + 0.08))
	DecorProps.wall_lantern(self, Vector3(4.0, 0.3 + 2.6, half.z), Vector3(0, 0, 1))
	_build_yard(half)
	_add_collision(half)


func _process(delta: float) -> void:
	_time += delta
	_forge_light.light_energy = 2.8 + sin(_time * 11.0) * 0.5 + sin(_time * 23.0) * 0.3


func _build_frame(half: Vector3) -> void:
	var y := 0.3 + BODY.y + UPPER / 2.0
	for x in [-half.x, -half.x / 2.0, 0.0, half.x / 2.0, half.x]:
		for z in [-half.z, half.z]:
			_box(Vector3(0.22, UPPER, 0.22), "beam", Vector3(x, y, z))
	for z in [-half.z, half.z]:
		_box(Vector3(BODY.x + 0.1, 0.22, 0.24), "beam", Vector3(0, 0.3 + BODY.y, z))
		_box(Vector3(BODY.x + 0.1, 0.2, 0.24), "beam", Vector3(0, 0.3 + BODY.y + UPPER, z))
	for x in [-half.x, half.x]:
		_box(Vector3(0.24, 0.22, BODY.z + 0.1), "beam", Vector3(x, 0.3 + BODY.y, 0))
		_box(Vector3(0.24, 0.2, BODY.z + 0.1), "beam", Vector3(x, 0.3 + BODY.y + UPPER, 0))


func _build_chimney(at: Vector3) -> void:
	var height := BODY.y + UPPER + ROOF_HEIGHT + 2.5
	_box(Vector3(1.6, height, 1.6), "stone", at + Vector3.UP * height / 2.0)
	_box(Vector3(1.9, 0.4, 1.9), "stone_dark", at + Vector3.UP * height)
	var smoke := GPUParticles3D.new()
	smoke.amount = 30
	smoke.lifetime = 4.0
	smoke.position = at + Vector3.UP * (height + 0.3)
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 12.0
	process.initial_velocity_min = 0.8
	process.initial_velocity_max = 1.3
	process.gravity = Vector3(0.25, 0.1, 0.0)
	process.scale_min = 0.6
	process.scale_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, Color(0.6, 0.6, 0.6, 0.55))
	fade.set_color(1, Color(0.8, 0.8, 0.8, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	smoke.process_material = process
	var puff := SphereMesh.new()
	puff.radius = 0.45
	puff.height = 0.9
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = material
	smoke.draw_pass_1 = puff
	add_child(smoke)


## Open forge yard: lean-to roof on posts, forge, anvil, barrel, grindstone, rack.
func _build_yard(half: Vector3) -> void:
	var front := half.z + YARD_DEPTH
	for x in [-half.x + 0.3, -0.6]:
		_box(Vector3(0.3, 3.3, 0.3), "beam", Vector3(x, 0.3 + 1.65, front - 0.3))
	var lean := _box(Vector3(half.x + 0.4, 0.2, YARD_DEPTH + 0.6), "roof", Vector3(-half.x / 2.0 - 0.3, 0.3 + 3.75, half.z + YARD_DEPTH / 2.0))
	lean.rotation.x = deg_to_rad(-12.0)
	# Forge: stone hearth with glowing coals and a hood.
	var forge := Vector3(-3.4, 0.3, half.z + 1.4)
	_box(Vector3(2.4, 1.0, 1.6), "stone", forge + Vector3.UP * 0.5)
	_box(Vector3(1.8, 0.12, 1.1), "coals", forge + Vector3.UP * 1.04)
	var hood := PrismMesh.new()
	hood.size = Vector3(2.4, 1.2, 1.6)
	_mesh(hood, "stone_dark", forge + Vector3.UP * 2.6)
	_forge_light = OmniLight3D.new()
	_forge_light.light_color = COALS
	_forge_light.light_energy = 3.0
	_forge_light.omni_range = 7.0
	_forge_light.position = forge + Vector3.UP * 1.6
	add_child(_forge_light)
	add_child(_embers(forge + Vector3.UP * 1.2))
	# Anvil on a stump.
	var anvil := Vector3(-1.4, 0.3, half.z + 2.8)
	_cylinder(0.4, 0.45, 0.6, "wood", anvil, 10)
	_box(Vector3(0.9, 0.3, 0.4), "iron", anvil + Vector3(0, 0.75, 0))
	_box(Vector3(0.4, 0.18, 0.3), "iron", anvil + Vector3(0.55, 0.8, 0))
	# Quench barrel, grindstone, weapon rack.
	var barrel := Vector3(-4.4, 0.3, front - 0.9)
	_cylinder(0.5, 0.45, 1.0, "wood", barrel, 12)
	_cylinder(0.42, 0.42, 0.04, "water", barrel + Vector3.UP * 0.92, 12)
	var wheel := _cylinder(0.55, 0.55, 0.2, "stone", Vector3.ZERO, 16)
	wheel.rotation.z = PI / 2.0
	wheel.position = Vector3(1.0, 0.3 + 0.75, front - 0.8)
	_box(Vector3(0.6, 0.5, 0.5), "wood", Vector3(1.0, 0.3 + 0.25, front - 0.8))
	_box(Vector3(2.4, 0.12, 0.15), "beam", Vector3(half.x - 1.6, 0.3 + 1.6, half.z + 0.3))
	_box(Vector3(2.4, 0.12, 0.15), "beam", Vector3(half.x - 1.6, 0.3 + 0.5, half.z + 0.3))
	for n in 4:
		_box(Vector3(0.08, 1.6, 0.06), "iron", Vector3(half.x - 2.5 + n * 0.6, 0.3 + 1.15, half.z + 0.42))


func _embers(at: Vector3) -> GPUParticles3D:
	var embers := GPUParticles3D.new()
	embers.amount = 24
	embers.lifetime = 1.8
	embers.position = at
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 30.0
	process.initial_velocity_min = 0.6
	process.initial_velocity_max = 1.3
	process.gravity = Vector3.ZERO
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.8, 0.1, 0.5)
	embers.process_material = process
	var spark := SphereMesh.new()
	spark.radius = 0.04
	spark.height = 0.08
	spark.material = _material("coals")
	embers.draw_pass_1 = spark
	return embers


func _window(at: Vector3, size: Vector2) -> void:
	_box(Vector3(size.x + 0.2, size.y + 0.2, 0.08), "beam", at + Vector3(0, 0, 0.01))
	_box(Vector3(size.x, size.y, 0.08), "window", at + Vector3(0, 0, 0.04))


func _add_collision(half: Vector3) -> void:
	var body := StaticBody3D.new()
	for entry in [
		[Vector3(BODY.x + 0.3, 4.0, BODY.z + 0.3), Vector3(0, 2.0, 0)],
		[Vector3(2.6, 3.0, 1.8), Vector3(-3.4, 1.5, half.z + 1.4)],
		[Vector3(1.4, 2.0, 1.4), Vector3(-4.4, 1.0, half.z + YARD_DEPTH - 0.9)],
	]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = entry[0]
		shape.shape = box
		shape.position = entry[1]
		body.add_child(shape)
	add_child(body)


## Roof / plaster / stone / timber surfaces get the shared detailed shader.
func _detailed(key: String) -> Material:
	match key:
		"stone": return BuildingMaterials.stone(STONE)
		"stone_dark": return BuildingMaterials.stone(STONE_DARK)
		"wall": return BuildingMaterials.plaster(WALL)
		"beam": return BuildingMaterials.timber(BEAM)
		"roof": return BuildingMaterials.roof(ROOF)
	return null


func _material(key: String) -> Material:
	if _materials.has(key):
		return _materials[key]
	var detailed := _detailed(key)
	if detailed:
		_materials[key] = detailed
		return detailed
	var material := StandardMaterial3D.new()
	material.roughness = 0.85
	match key:
		"stone": material.albedo_color = STONE
		"stone_dark": material.albedo_color = STONE_DARK
		"wall": material.albedo_color = WALL
		"beam": material.albedo_color = BEAM
		"roof": material.albedo_color = ROOF
		"wood": material.albedo_color = WOOD
		"iron":
			material.albedo_color = IRON
			material.metallic = 0.7
			material.roughness = 0.4
		"water":
			material.albedo_color = Color(0.2, 0.4, 0.55)
			material.roughness = 0.1
		"coals", "window":
			var glow := COALS if key == "coals" else WINDOW_GLOW
			material.albedo_color = glow
			material.emission_enabled = true
			material.emission = glow
			material.emission_energy_multiplier = 3.0 if key == "coals" else 1.4
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
