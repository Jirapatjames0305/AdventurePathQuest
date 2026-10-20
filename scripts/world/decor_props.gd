class_name DecorProps
extends RefCounted
## Small shared decorations buildings add near their doors: potted plants
## and wall lanterns. Positions are in the parent's local space.

const POT := Color(0.66, 0.38, 0.26)
const LEAVES := [Color(0.3, 0.55, 0.25), Color(0.38, 0.62, 0.28), Color(0.27, 0.5, 0.24)]
const FLOWERS := [Color(0.95, 0.35, 0.4), Color(0.98, 0.8, 0.3), Color(0.75, 0.45, 0.9), Color(1.0, 0.6, 0.75)]
const IRON := Color(0.15, 0.15, 0.17)
const GLOW := Color(1.0, 0.75, 0.4)

static var _materials := {}


## Clay pot with a round shrub, optionally flowering.
static func potted_plant(parent: Node3D, at: Vector3, rng: RandomNumberGenerator, size := 1.0) -> void:
	_cylinder(parent, 0.32 * size, 0.24 * size, 0.5 * size, _flat(POT), at)
	_cylinder(parent, 0.34 * size, 0.34 * size, 0.06 * size, _flat(POT.darkened(0.2)), at + Vector3.UP * 0.47 * size)
	var leaves := _flat(LEAVES[rng.randi() % LEAVES.size()])
	_sphere(parent, 0.42 * size, leaves, at + Vector3.UP * 0.85 * size)
	_sphere(parent, 0.3 * size, leaves, at + Vector3(0.15, 1.15, -0.05) * size)
	if rng.randf() < 0.6:
		var bloom := _flat(FLOWERS[rng.randi() % FLOWERS.size()])
		for n in 5:
			var a := TAU * n / 5.0 + rng.randf()
			_sphere(parent, 0.08 * size, bloom, at + Vector3(cos(a) * 0.32, 1.0 + rng.randf_range(0.0, 0.25), sin(a) * 0.32) * size)


## Iron bracket lantern on a wall; `facing` points out of the wall.
static func wall_lantern(parent: Node3D, at: Vector3, facing: Vector3) -> void:
	var yaw := atan2(facing.x, facing.z)
	var arm := _box(parent, Vector3(0.06, 0.06, 0.45), _flat(IRON), at + facing * 0.22)
	arm.rotation.y = yaw
	var lamp_at := at + facing * 0.42 + Vector3.DOWN * 0.25
	_box(parent, Vector3(0.26, 0.34, 0.26), _glow(), lamp_at).rotation.y = yaw
	_box(parent, Vector3(0.34, 0.06, 0.34), _flat(IRON), lamp_at + Vector3.UP * 0.2).rotation.y = yaw
	var light := OmniLight3D.new()
	light.light_color = GLOW
	light.light_energy = 0.9
	light.omni_range = 4.5
	light.position = lamp_at + facing * 0.2
	parent.add_child(light)


static func _flat(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.85
		_materials[color] = material
	return _materials[color]


static func _glow() -> StandardMaterial3D:
	if not _materials.has("glow"):
		var material := StandardMaterial3D.new()
		material.albedo_color = GLOW
		material.emission_enabled = true
		material.emission = GLOW
		material.emission_energy_multiplier = 3.0
		_materials["glow"] = material
	return _materials["glow"]


static func _mesh(parent: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance


static func _box(parent: Node3D, size: Vector3, material: Material, at: Vector3) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(parent, box, material, at)


static func _sphere(parent: Node3D, radius: float, material: Material, at: Vector3) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.8
	sphere.radial_segments = 10
	sphere.rings = 5
	_mesh(parent, sphere, material, at)


## Cylinder standing on `at`.
static func _cylinder(parent: Node3D, top: float, bottom: float, height: float, material: Material, at: Vector3) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = 12
	_mesh(parent, cylinder, material, at + Vector3.UP * height / 2.0)
