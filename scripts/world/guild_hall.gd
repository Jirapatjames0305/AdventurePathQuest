class_name GuildHall
extends Node3D
## The Adventurers' Guild — a grand palace where heroes take on quests.
## Built from primitives: plinth and steps, columned portico, main hall,
## central keep with spire, side wings, round corner towers, lit windows,
## banners and a quest board. Local +Z is the front (faces the plaza).

const STONE := Color(0.84, 0.8, 0.72)
const STONE_DARK := Color(0.56, 0.53, 0.49)
const TRIM := Color(0.7, 0.66, 0.6)
const ROOF := Color(0.26, 0.36, 0.56)
const GOLD := Color(0.92, 0.74, 0.32)
const WOOD := Color(0.36, 0.23, 0.13)
const WINDOW_GLOW := Color(1.0, 0.8, 0.45)
const BANNER := Color(0.62, 0.14, 0.16)
const PAPER := [Color(0.96, 0.93, 0.82), Color(0.98, 0.88, 0.6), Color(0.9, 0.95, 0.85)]

const PLINTH := Vector3(18.0, 0.6, 13.0)
const HALL := Vector3(10.0, 6.5, 7.0)
const WING := Vector3(4.0, 4.8, 6.0)
const KEEP := Vector3(4.2, 12.0, 4.2)
const TOWER_RADIUS := 1.3
const TOWER_HEIGHT := 8.5

var _materials := {}


func _ready() -> void:
	var base := PLINTH.y
	# Plinth and the grand stairs down to the square.
	_box(PLINTH, "stone_dark", Vector3(0, base / 2.0, 0))
	for step in 3:
		var depth := 0.7
		_box(Vector3(7.0 - step * 0.4, base - step * 0.2, depth), "trim",
			Vector3(0, (base - step * 0.2) / 2.0, PLINTH.z / 2.0 + depth * (step + 0.5)))
	_build_hall(base)
	_build_wings(base)
	_build_keep(base)
	_build_towers(base)
	_build_portico(base)
	_build_quest_board(Vector3(5.2, base, PLINTH.z / 2.0 + 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for x in [-3.8, 3.8]:
		DecorProps.potted_plant(self, Vector3(x, 0, PLINTH.z / 2.0 + 2.1), rng, 1.3)
	_add_collision()


func _build_hall(base: float) -> void:
	var center := Vector3(0, base + HALL.y / 2.0, 0)
	_box(HALL, "stone", center)
	_box(Vector3(HALL.x + 0.3, 0.35, HALL.z + 0.3), "trim", Vector3(0, base + HALL.y, 0))
	_roof(Vector3(HALL.x + 0.6, 3.2, HALL.z + 0.8), Vector3(0, base + HALL.y + 1.6 + 0.17, 0))
	# Two rows of tall lit windows across the front, a banner on each side of the door.
	for row in 2:
		for x in [-3.8, -2.4, 2.4, 3.8]:
			_window(Vector3(x, base + 1.8 + row * 2.6, HALL.z / 2.0), Vector2(0.7, 1.4))
	for x in [-1.6, 1.6]:
		_banner(Vector3(x, base + HALL.y - 0.5, HALL.z / 2.0 + 0.05), 3.0)


func _build_wings(base: float) -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * (HALL.x / 2.0 + WING.x / 2.0)
		_box(WING, "stone", Vector3(x, base + WING.y / 2.0, 0.3))
		_box(Vector3(WING.x + 0.3, 0.3, WING.z + 0.3), "trim", Vector3(x, base + WING.y, 0.3))
		_roof(Vector3(WING.x + 0.5, 2.2, WING.z + 0.6), Vector3(x, base + WING.y + 1.1 + 0.15, 0.3), true)
		for wx in [-0.9, 0.9]:
			_window(Vector3(x + wx, base + 2.2, 0.3 + WING.z / 2.0), Vector2(0.6, 1.2))


func _build_keep(base: float) -> void:
	var z := -1.2
	_box(KEEP, "stone", Vector3(0, base + KEEP.y / 2.0, z))
	_box(Vector3(KEEP.x + 0.4, 0.4, KEEP.z + 0.4), "trim", Vector3(0, base + KEEP.y, z))
	for row in 2:
		_window(Vector3(0, base + 8.0 + row * 2.0, z + KEEP.z / 2.0), Vector2(0.8, 1.3))
	# Square spire with a gold finial and a flag.
	var spire := _cylinder(0.0, KEEP.x * 0.78, 4.5, "roof", Vector3(0, base + KEEP.y + 0.2, z), 4)
	spire.rotation.y = PI / 4.0
	var top := base + KEEP.y + 4.7
	_sphere(0.28, "gold", Vector3(0, top, z))
	_cylinder(0.05, 0.05, 2.2, "wood", Vector3(0, top, z), 6)
	_box(Vector3(1.2, 0.7, 0.04), "banner", Vector3(0.62, top + 1.8, z))


func _build_towers(base: float) -> void:
	var spots := [
		Vector2(-PLINTH.x / 2.0 + 1.4, PLINTH.z / 2.0 - 1.4), Vector2(PLINTH.x / 2.0 - 1.4, PLINTH.z / 2.0 - 1.4),
		Vector2(-PLINTH.x / 2.0 + 1.4, -PLINTH.z / 2.0 + 1.4), Vector2(PLINTH.x / 2.0 - 1.4, -PLINTH.z / 2.0 + 1.4),
	]
	for spot in spots:
		var at := Vector3(spot.x, base, spot.y)
		_cylinder(TOWER_RADIUS, TOWER_RADIUS + 0.1, TOWER_HEIGHT, "stone", at, 16)
		_cylinder(TOWER_RADIUS + 0.25, TOWER_RADIUS + 0.25, 0.35, "trim", at + Vector3.UP * TOWER_HEIGHT, 16)
		_cylinder(0.0, TOWER_RADIUS + 0.4, 3.4, "roof", at + Vector3.UP * (TOWER_HEIGHT + 0.35), 16)
		_sphere(0.16, "gold", at + Vector3.UP * (TOWER_HEIGHT + 3.8))
		var facing := Vector3(0, 0, 1) if spot.y > 0 else Vector3(signf(spot.x), 0, 0)
		_window(at + Vector3.UP * (TOWER_HEIGHT - 2.2) + facing * (TOWER_RADIUS + 0.02), Vector2(0.45, 0.9), facing)


## Columned porch over the entrance with a triangular pediment and big door.
func _build_portico(base: float) -> void:
	var front := HALL.z / 2.0
	var porch_z := front + 1.4
	_box(Vector3(5.6, 0.25, 2.8), "trim", Vector3(0, base + 0.12, front + 1.4))
	for x in [-2.3, -0.8, 0.8, 2.3]:
		_cylinder(0.28, 0.32, 4.4, "stone", Vector3(x, base + 0.25, porch_z + 0.9), 12)
	_box(Vector3(6.0, 0.5, 3.0), "trim", Vector3(0, base + 4.9, front + 1.4))
	# Pediment: triangle faces the front, so the ridge runs front-to-back.
	var pediment := PrismMesh.new()
	pediment.size = Vector3(6.2, 1.6, 3.1)
	_mesh(pediment, "roof", Vector3(0, base + 5.95, front + 1.4))
	_sphere(0.22, "gold", Vector3(0, base + 6.9, porch_z + 1.5))
	# Arched wooden door.
	_box(Vector3(2.0, 2.8, 0.15), "wood", Vector3(0, base + 1.4, front + 0.05))
	var arch := _cylinder(1.0, 1.0, 0.15, "wood", Vector3(0, base + 2.8, front + 0.05), 16)
	arch.rotation.x = PI / 2.0
	arch.position.y = base + 2.8
	_box(Vector3(0.08, 2.6, 0.18), "gold", Vector3(0, base + 1.35, front + 0.08))


## Wooden notice board with pinned quest papers, beside the steps.
func _build_quest_board(at: Vector3) -> void:
	for x in [-0.9, 0.9]:
		_box(Vector3(0.14, 2.2, 0.14), "wood", at + Vector3(x, 1.1, 0))
	_box(Vector3(2.2, 1.3, 0.12), "wood", at + Vector3(0, 1.45, 0))
	_prism(Vector3(2.5, 0.45, 0.4), "roof", at + Vector3(0, 2.32, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for n in 6:
		var paper := _box(Vector3(0.42, 0.52, 0.02), "paper%d" % (n % PAPER.size()),
			at + Vector3(-0.72 + (n % 3) * 0.72, 1.75 - (n / 3) * 0.62, 0.08))
		paper.rotation.z = rng.randf_range(-0.12, 0.12)


func _add_collision() -> void:
	var body := StaticBody3D.new()
	var shapes := [
		[Vector3(PLINTH.x, 4.0, PLINTH.z), Vector3(0, 2.0, 0)],
		[Vector3(5.6, 4.0, 2.4), Vector3(0, 2.0, HALL.z / 2.0 + 1.6)],
		[Vector3(2.4, 3.0, 0.6), Vector3(5.2, 1.5, PLINTH.z / 2.0 + 1.0)],
	]
	for entry in shapes:
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
		"trim": material.albedo_color = TRIM
		"roof":
			material.albedo_color = ROOF
			material.roughness = 0.6
		"gold":
			material.albedo_color = GOLD
			material.metallic = 0.8
			material.roughness = 0.3
		"wood": material.albedo_color = WOOD
		"banner": material.albedo_color = BANNER
		"window":
			material.albedo_color = WINDOW_GLOW
			material.emission_enabled = true
			material.emission = WINDOW_GLOW
			material.emission_energy_multiplier = 1.6
		_:
			material.albedo_color = PAPER[int(key.substr(5))]
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


## Cylinder (or cone when top = 0) standing on `at`.
func _cylinder(top: float, bottom: float, height: float, key: String, at: Vector3, sides: int) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = sides
	return _mesh(cylinder, key, at + Vector3.UP * height / 2.0)


func _sphere(radius: float, key: String, at: Vector3) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	return _mesh(sphere, key, at)


## Triangular prism; the ridge runs along X (left–right across the facade).
func _prism(size: Vector3, key: String, at: Vector3) -> MeshInstance3D:
	var prism := PrismMesh.new()
	prism.size = Vector3(size.z, size.y, size.x)
	var instance := _mesh(prism, key, at)
	instance.rotation.y = PI / 2.0
	return instance


## Gabled roof; ridge along X, or along Z when `ridge_along_z`.
func _roof(size: Vector3, at: Vector3, ridge_along_z := false) -> void:
	if ridge_along_z:
		var prism := PrismMesh.new()
		prism.size = size
		_mesh(prism, "roof", at)
	else:
		_prism(size, "roof", at)


func _window(at: Vector3, size: Vector2, facing := Vector3(0, 0, 1)) -> void:
	var window := _box(Vector3(size.x, size.y, 0.06), "window", at)
	window.rotation.y = atan2(facing.x, facing.z)
	var frame := _box(Vector3(size.x + 0.16, size.y + 0.16, 0.04), "trim", at - facing * 0.02)
	frame.rotation.y = window.rotation.y


func _banner(top: Vector3, length: float) -> void:
	_box(Vector3(0.9, length, 0.05), "banner", top - Vector3(0, length / 2.0, 0))
	_box(Vector3(1.0, 0.12, 0.08), "gold", top)
	_box(Vector3(0.9, 0.1, 0.06), "gold", top - Vector3(0, length - 0.05, 0))
