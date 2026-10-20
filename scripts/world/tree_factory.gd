class_name TreeFactory
extends RefCounted
## Builds the town's low-poly trees (round-crowned and pine) from primitives,
## each with a trunk collider. Shared by the park and the town scatter so all
## trees match. Materials are cached per factory.

const TRUNK := Color(0.42, 0.28, 0.17)
const LEAVES := [Color(0.3, 0.55, 0.25), Color(0.38, 0.62, 0.28), Color(0.25, 0.48, 0.22), Color(0.45, 0.65, 0.3)]
const PINE := Color(0.2, 0.42, 0.25)
const PINE_CHANCE := 0.3

var _materials := {}


## A random tree at `at` (parent-local) with a size in [min_size, max_size].
func random_tree(parent: Node3D, body: StaticBody3D, at: Vector3, rng: RandomNumberGenerator, min_size := 0.8, max_size := 1.35) -> void:
	var size := rng.randf_range(min_size, max_size)
	if rng.randf() < PINE_CHANCE:
		pine(parent, body, at, size)
	else:
		round_tree(parent, body, at, size, rng)


func round_tree(parent: Node3D, body: StaticBody3D, at: Vector3, size: float, rng: RandomNumberGenerator) -> void:
	_cylinder(parent, 0.18 * size, 0.26 * size, 2.2 * size, _material(TRUNK), at)
	var leaves := _material(LEAVES[rng.randi() % LEAVES.size()])
	for n in 3:
		var crown := SphereMesh.new()
		crown.radius = (1.3 - n * 0.2) * size
		crown.height = crown.radius * 1.8
		crown.radial_segments = 10
		crown.rings = 5
		var offset := Vector3(rng.randf_range(-0.5, 0.5), 2.6 + n * 0.7, rng.randf_range(-0.5, 0.5)) * size
		_mesh(parent, crown, leaves, at + offset)
	_trunk_collider(body, at, 0.35 * size)


func pine(parent: Node3D, body: StaticBody3D, at: Vector3, size: float) -> void:
	_cylinder(parent, 0.16 * size, 0.22 * size, 1.2 * size, _material(TRUNK), at)
	for n in 3:
		var radius := (1.5 - n * 0.4) * size
		_cylinder(parent, 0.0, radius, 1.8 * size, _material(PINE), at + Vector3.UP * (0.9 + n * 1.1) * size)
	_trunk_collider(body, at, 0.3 * size)


func _trunk_collider(body: StaticBody3D, at: Vector3, radius: float) -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 3.0
	shape.shape = cylinder
	shape.position = at + Vector3.UP * 1.5
	body.add_child(shape)


func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.9
		_materials[color] = material
	return _materials[color]


func _mesh(parent: Node3D, mesh: Mesh, material: Material, at: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)


## Cylinder (or cone when top = 0) standing on `at`.
func _cylinder(parent: Node3D, top: float, bottom: float, height: float, material: Material, at: Vector3) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = 10 if top == 0.0 else 8
	_mesh(parent, cylinder, material, at + Vector3.UP * height / 2.0)
