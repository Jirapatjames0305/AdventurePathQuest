class_name MagicShop
extends Node3D
## A two-storey magic supplies shop, same footprint as the general store
## (upper floor narrower). Built like the other town houses (cream walls,
## dark timber) with only two hints of magic: a crescent-moon sign and a
## display window of potion bottles. Local +Z is the front (entrance).

const STONE := Color(0.6, 0.57, 0.53)
const WALL := Color(0.94, 0.89, 0.78)
const TRIM := Color(0.36, 0.24, 0.15)
const ROOF := Color(0.42, 0.37, 0.48)
const GOLD := Color(0.95, 0.78, 0.3)
const WOOD := Color(0.35, 0.24, 0.18)
const WINDOW_GLOW := Color(1.0, 0.8, 0.5)
const POTIONS := [Color(0.3, 1.0, 0.5), Color(1.0, 0.35, 0.4), Color(0.4, 0.6, 1.0), Color(1.0, 0.85, 0.3), Color(0.85, 0.4, 1.0)]

const BASE := Vector3(13.0, 3.6, 9.5)
const UPPER := Vector2(10.0, 7.0)
const FLOOR_HEIGHT := 3.0
const ROOF_HEIGHT := 4.5

var _materials := {}


func _ready() -> void:
	_box(Vector3(BASE.x + 0.4, 0.3, BASE.z + 0.4), "stone", Vector3(0, 0.15, 0))
	_box(BASE, "wall", Vector3(0, 0.3 + BASE.y / 2.0, 0))
	_frame(Vector2(BASE.x, BASE.z), 0.3, BASE.y)
	var top := 0.3 + BASE.y
	_box(Vector3(BASE.x + 0.5, 0.3, BASE.z + 0.5), "roof", Vector3(0, top + 0.15, 0))
	_box(Vector3(UPPER.x, FLOOR_HEIGHT, UPPER.y), "wall", Vector3(0, top + FLOOR_HEIGHT / 2.0, 0))
	_frame(UPPER, top, FLOOR_HEIGHT)
	for x in [-2.6, 2.6]:
		_round_window(Vector3(x, top + 1.6, UPPER.y / 2.0), Vector3(0, 0, 1), 0.6)
		_round_window(Vector3(x, top + 1.6, -UPPER.y / 2.0), Vector3(0, 0, -1), 0.6)
	top += FLOOR_HEIGHT
	var roof := PrismMesh.new()
	roof.size = Vector3(UPPER.y + 1.2, ROOF_HEIGHT, UPPER.x + 1.0)
	_mesh(roof, "roof", Vector3(0, top + ROOF_HEIGHT / 2.0, 0)).rotation.y = PI / 2.0
	_box(Vector3(1.0, 3.0, 1.0), "stone", Vector3(UPPER.x / 2.0 - 1.2, top + ROOF_HEIGHT - 0.6, -0.8))
	_shop_front()
	_sign()
	_add_collision()


func _frame(size: Vector2, bottom: float, height: float) -> void:
	var half := size / 2.0
	var y := bottom + height / 2.0
	for x in [-half.x, half.x]:
		for z in [-half.y, half.y]:
			_box(Vector3(0.26, height, 0.26), "trim", Vector3(x, y, z))
	for z in [-half.y, half.y]:
		_box(Vector3(size.x + 0.1, 0.24, 0.26), "trim", Vector3(0, bottom + height - 0.12, z))
	for x in [-half.x, half.x]:
		_box(Vector3(0.26, 0.24, size.y + 0.1), "trim", Vector3(x, bottom + height - 0.12, 0))


## Arched door and a display window of potion bottles either side.
func _shop_front() -> void:
	var front := BASE.z / 2.0
	_box(Vector3(2.0, 2.6, 0.15), "trim", Vector3(0, 0.3 + 1.3, front + 0.03))
	var arch := _cylinder(1.0, 1.0, 0.15, "trim", Vector3.ZERO, 16)
	arch.rotation.x = PI / 2.0
	arch.position = Vector3(0, 0.3 + 2.6, front + 0.03)
	_box(Vector3(0.1, 0.1, 0.08), "gold", Vector3(0.6, 0.3 + 1.3, front + 0.12))
	_box(Vector3(2.8, 0.25, 1.0), "stone", Vector3(0, 0.12, front + 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	for x in [-1.75, 1.75]:
		DecorProps.potted_plant(self, Vector3(x, 0, front + 0.6), rng)
		DecorProps.wall_lantern(self, Vector3(x * 0.8, 0.3 + 2.5, front), Vector3(0, 0, 1))
	for x in [-3.8, 3.8]:
		_box(Vector3(3.6, 2.0, 0.1), "trim", Vector3(x, 0.3 + 1.7, front + 0.02))
		_box(Vector3(3.3, 1.75, 0.1), "window", Vector3(x, 0.3 + 1.7, front + 0.05))
		for shelf in 2:
			_box(Vector3(3.3, 0.06, 0.3), "wood", Vector3(x, 0.3 + 1.0 + shelf * 0.8, front + 0.14))
			for n in 6:
				var bottle := Vector3(x - 1.3 + n * 0.52, 0.3 + 1.03 + shelf * 0.8, front + 0.16)
				_cylinder(0.12, 0.14, 0.32, "potion%d" % ((n + shelf * 2) % POTIONS.size()), bottle, 8)
				_cylinder(0.04, 0.05, 0.14, "trim", bottle + Vector3.UP * 0.32, 6)


## Hanging sign with a golden crescent moon and star.
func _sign() -> void:
	var anchor := Vector3(BASE.x / 2.0 - 0.3, 0.3 + BASE.y - 0.1, BASE.z / 2.0)
	_box(Vector3(0.1, 0.1, 1.8), "trim", anchor + Vector3(0, 0, 0.9))
	var board := anchor + Vector3(0, -0.9, 1.0)
	_box(Vector3(0.14, 1.4, 1.4), "trim", board)
	_box(Vector3(0.18, 1.2, 1.2), "wall", board)
	for side in [-1.0, 1.0]:
		var moon := TorusMesh.new()
		moon.inner_radius = 0.28
		moon.outer_radius = 0.42
		var ring := _mesh(moon, "gold", board + Vector3(side * 0.12, 0.05, -0.1))
		ring.rotation.z = PI / 2.0
		var cut := SphereMesh.new()
		cut.radius = 0.34
		cut.height = 0.68
		_mesh(cut, "wall", board + Vector3(side * 0.13, 0.12, 0.08))
		var star := SphereMesh.new()
		star.radius = 0.1
		star.height = 0.2
		_mesh(star, "star", board + Vector3(side * 0.12, -0.3, 0.32))


func _round_window(at: Vector3, facing: Vector3, radius: float) -> void:
	var rim := TorusMesh.new()
	rim.inner_radius = radius
	rim.outer_radius = radius + 0.14
	var ring := _mesh(rim, "trim", at + facing * 0.02)
	ring.rotation = Vector3(PI / 2.0, atan2(facing.x, facing.z), 0)
	var pane := _cylinder(radius, radius, 0.08, "window", Vector3.ZERO, 16)
	pane.rotation = Vector3(PI / 2.0, 0, 0)
	pane.rotation.y = atan2(facing.x, facing.z)
	pane.position = at + facing * 0.04


func _add_collision() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BASE.x + 0.6, 4.0, BASE.z + 0.6)
	shape.shape = box
	shape.position = Vector3(0, 2.0, 0)
	body.add_child(shape)
	add_child(body)


## Roof / plaster / stone / timber surfaces get the shared detailed shader.
func _detailed(key: String) -> Material:
	match key:
		"stone": return BuildingMaterials.stone(STONE)
		"wall": return BuildingMaterials.plaster(WALL)
		"trim": return BuildingMaterials.timber(TRIM)
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
	var glow := Color.BLACK
	if key.begins_with("potion"):
		glow = POTIONS[int(key.substr(6))]
	else:
		match key:
			"stone": material.albedo_color = STONE
			"wall": material.albedo_color = WALL
			"trim": material.albedo_color = TRIM
			"roof":
				material.albedo_color = ROOF
				material.roughness = 0.6
			"wood": material.albedo_color = WOOD
			"iron":
				material.albedo_color = Color(0.18, 0.18, 0.2)
				material.metallic = 0.6
				material.roughness = 0.45
			"gold":
				material.albedo_color = GOLD
				material.metallic = 0.8
				material.roughness = 0.3
			"star": glow = GOLD
			"window": glow = WINDOW_GLOW
	if glow != Color.BLACK:
		material.albedo_color = glow
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = 1.2
	_materials[key] = material
	return material


func _mesh(mesh: Mesh, key: String, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(key)
	instance.position = at
	(parent if parent else self).add_child(instance)
	return instance


func _box(size: Vector3, key: String, at: Vector3) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(box, key, at)


## Cylinder (or cone when top = 0) standing on `at`.
func _cylinder(top: float, bottom: float, height: float, key: String, at: Vector3, sides: int, parent: Node3D = null) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = sides
	return _mesh(cylinder, key, at + Vector3.UP * height / 2.0, parent)
