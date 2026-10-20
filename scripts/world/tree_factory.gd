class_name TreeFactory
extends RefCounted
## Builds the town's low-poly trees from primitives, each with a trunk
## collider. Shared by the park and the town scatter so all trees match.
## Kinds: leafy (lumpy crown of clustered balls, lit lighter on top and darker
## underneath, trunk with root flare and branches), pine (stacked, slightly
## twisted tiers with a tip) and blossom (pink / white flowering crown).
## Materials are cached per colour.

const TRUNK := Color(0.42, 0.28, 0.17)
const TRUNK_DARK := Color(0.32, 0.21, 0.13)
const LEAVES := [Color(0.3, 0.55, 0.25), Color(0.38, 0.62, 0.28), Color(0.25, 0.48, 0.22), Color(0.45, 0.65, 0.3)]
const PINES := [Color(0.2, 0.42, 0.25), Color(0.17, 0.37, 0.22), Color(0.24, 0.46, 0.28)]
const BLOSSOMS := [Color(1.0, 0.72, 0.8), Color(0.98, 0.84, 0.88), Color(0.96, 0.6, 0.72)]
const PINE_CHANCE := 0.28
const BLOSSOM_CHANCE := 0.1
## Crown shading: top lumps lighter, bottom lumps darker (fake ambient light).
const TOP_LIGHT := 0.14
const BOTTOM_DARK := 0.2

var _materials := {}


## A random tree at `at` (parent-local) with a size in [min_size, max_size].
func random_tree(parent: Node3D, body: StaticBody3D, at: Vector3, rng: RandomNumberGenerator, min_size := 0.8, max_size := 1.35) -> void:
	var size := rng.randf_range(min_size, max_size)
	var roll := rng.randf()
	if roll < PINE_CHANCE:
		pine(parent, body, at, size, rng)
	elif roll < PINE_CHANCE + BLOSSOM_CHANCE:
		round_tree(parent, body, at, size * 0.85, rng, BLOSSOMS)
	else:
		round_tree(parent, body, at, size, rng, LEAVES)


## Leafy tree: tapered trunk with root flare and two branches, crown of a big
## central ball ringed by smaller lumps.
func round_tree(parent: Node3D, body: StaticBody3D, at: Vector3, size: float, rng: RandomNumberGenerator, palette := LEAVES) -> void:
	var spin := rng.randf() * TAU
	var trunk_height := 2.3 * size
	_cylinder(parent, 0.0, 0.42 * size, 0.45 * size, _material(TRUNK_DARK), at, 7)  # root flare
	_cylinder(parent, 0.15 * size, 0.26 * size, trunk_height, _material(TRUNK), at, 8)
	for i in 2:
		var a := spin + i * PI * 0.9
		var branch := _cylinder(parent, 0.05 * size, 0.1 * size, 1.1 * size, _material(TRUNK), Vector3.ZERO, 6)
		branch.position = at + Vector3(cos(a) * 0.3, trunk_height * 0.72, sin(a) * 0.3) * Vector3(size, 1.0, size)
		branch.rotation = Vector3(sin(a) * 0.9, 0.0, -cos(a) * 0.9)
	var base: Color = palette[rng.randi() % palette.size()]
	var crown := at + Vector3.UP * (trunk_height + 0.75 * size)
	var radius := 1.2 * size
	_ball(parent, crown, radius, base)
	var lumps := rng.randi_range(5, 7)
	for i in lumps:
		var a := spin + TAU * i / lumps + rng.randf_range(-0.3, 0.3)
		var rise := rng.randf_range(-0.45, 0.65)
		var out := Vector3(cos(a), rise, sin(a)).normalized()
		var lump_radius := radius * rng.randf_range(0.5, 0.7)
		var shade := base.lightened(TOP_LIGHT) if rise > 0.25 else (base.darkened(BOTTOM_DARK) if rise < -0.1 else base)
		_ball(parent, crown + out * radius * 0.78, lump_radius, shade)
	_ball(parent, crown + Vector3.UP * radius * 0.75, radius * 0.55, base.lightened(TOP_LIGHT * 1.4))
	_trunk_collider(body, at, 0.35 * size)


## Pine: short trunk, four stacked cone tiers (each turned a little and
## alternating shade) and a narrow tip.
func pine(parent: Node3D, body: StaticBody3D, at: Vector3, size: float, rng: RandomNumberGenerator = null) -> void:
	var base: Color = PINES[rng.randi() % PINES.size()] if rng else PINES[0]
	_cylinder(parent, 0.14 * size, 0.24 * size, 1.3 * size, _material(TRUNK), at, 7)
	var tiers := 4
	for n in tiers:
		var radius := (1.6 - n * 0.32) * size
		var height := (1.5 - n * 0.12) * size
		var shade := base.darkened(BOTTOM_DARK * 0.6) if n % 2 == 0 else base.lightened(TOP_LIGHT * 0.6)
		var tier := _cylinder(parent, radius * 0.18, radius, height, _material(shade), at + Vector3.UP * (0.9 + n * 0.85) * size, 9)
		tier.rotation.y = n * 0.4
	_cylinder(parent, 0.0, 0.32 * size, 0.9 * size, _material(base.lightened(TOP_LIGHT)), at + Vector3.UP * (0.9 + tiers * 0.85) * size, 7)
	_trunk_collider(body, at, 0.3 * size)


func _ball(parent: Node3D, at: Vector3, radius: float, color: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.75
	sphere.radial_segments = 9
	sphere.rings = 5
	_mesh(parent, sphere, _material(color), at)


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


func _mesh(parent: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance


## Cylinder (or cone when top = 0) standing on `at`.
func _cylinder(parent: Node3D, top: float, bottom: float, height: float, material: Material, at: Vector3, sides: int) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = sides
	return _mesh(parent, cylinder, material, at + Vector3.UP * height / 2.0)
