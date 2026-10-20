class_name GeneralStore
extends Node3D
## A big two-storey general store built from primitives. Same footprint as the
## tavern; the upper floor is narrower than the ground floor, with a roof
## ledge at the step. Shop-front cues: wide display windows full of goods, a
## striped awning, a hanging sign with a coin pouch, crates, sacks, barrels and
## a cart outside. Local +Z is the front (entrance).

const STONE := Color(0.62, 0.58, 0.52)
const WALL := Color(0.96, 0.9, 0.78)
const BEAM := Color(0.4, 0.26, 0.15)
const ROOF := Color(0.28, 0.42, 0.55)
const WOOD := Color(0.6, 0.42, 0.25)
const AWNING := [Color(0.85, 0.3, 0.28), Color(0.97, 0.94, 0.86)]
const GOLD := Color(0.92, 0.74, 0.32)
const SACK := Color(0.78, 0.68, 0.48)
const WINDOW_GLOW := Color(1.0, 0.78, 0.45)
const GOODS := [Color(0.85, 0.25, 0.2), Color(0.95, 0.75, 0.25), Color(0.4, 0.65, 0.35), Color(0.35, 0.5, 0.85), Color(0.7, 0.45, 0.25)]

const BASE := Vector3(13.0, 3.6, 9.5)
const UPPER := Vector2(10.0, 7.0)
const FLOOR_HEIGHT := 3.0
const ROOF_HEIGHT := 4.0

var _materials := {}


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	_box(Vector3(BASE.x + 0.4, 0.3, BASE.z + 0.4), "stone", Vector3(0, 0.15, 0))
	_box(BASE, "wall", Vector3(0, 0.3 + BASE.y / 2.0, 0))
	_frame(Vector2(BASE.x, BASE.z), 0.3, BASE.y)
	var top := 0.3 + BASE.y
	# Step-in ledge, then the narrower upper floor.
	_box(Vector3(BASE.x + 0.5, 0.3, BASE.z + 0.5), "roof", Vector3(0, top + 0.15, 0))
	_box(Vector3(UPPER.x, FLOOR_HEIGHT, UPPER.y), "wall", Vector3(0, top + FLOOR_HEIGHT / 2.0, 0))
	_frame(UPPER, top, FLOOR_HEIGHT)
	for x in [-2.6, 2.6]:
		_window(Vector3(x, top + 1.6, UPPER.y / 2.0), Vector3(0, 0, 1), Vector2(1.1, 1.3))
		_window(Vector3(x, top + 1.6, -UPPER.y / 2.0), Vector3(0, 0, -1), Vector2(1.1, 1.3))
	for side in [-1.0, 1.0]:
		_window(Vector3(side * UPPER.x / 2.0, top + 1.6, 0), Vector3(side, 0, 0), Vector2(1.1, 1.3))
	top += FLOOR_HEIGHT
	var roof := PrismMesh.new()
	roof.size = Vector3(UPPER.y + 1.2, ROOF_HEIGHT, UPPER.x + 1.0)
	_mesh(roof, "roof", Vector3(0, top + ROOF_HEIGHT / 2.0, 0)).rotation.y = PI / 2.0
	_box(Vector3(1.0, 3.0, 1.0), "stone", Vector3(-UPPER.x / 2.0 + 1.2, top + ROOF_HEIGHT - 0.6, -0.8))
	_shop_front(rng)
	_sign()
	_outside_goods(rng)
	_add_collision()


## Timber frame on one storey: corner and mid posts, top and bottom rails.
func _frame(size: Vector2, bottom: float, height: float) -> void:
	var half := size / 2.0
	var y := bottom + height / 2.0
	for x in [-half.x, -half.x / 3.0, half.x / 3.0, half.x]:
		for z in [-half.y, half.y]:
			_box(Vector3(0.22, height, 0.22), "beam", Vector3(x, y, z))
	for z in [-half.y, half.y]:
		_box(Vector3(size.x + 0.1, 0.22, 0.24), "beam", Vector3(0, bottom + height - 0.11, z))
	for x in [-half.x, half.x]:
		_box(Vector3(0.24, 0.22, size.y + 0.1), "beam", Vector3(x, bottom + height - 0.11, 0))


## Door between two wide display windows full of goods, under a striped awning.
func _shop_front(rng: RandomNumberGenerator) -> void:
	var front := BASE.z / 2.0
	_box(Vector3(2.0, 2.6, 0.15), "beam", Vector3(0, 0.3 + 1.3, front + 0.03))
	_box(Vector3(0.08, 0.08, 0.08), "gold", Vector3(0.6, 0.3 + 1.3, front + 0.12))
	_box(Vector3(2.8, 0.25, 1.0), "stone", Vector3(0, 0.12, front + 0.5))
	for x in [-3.8, 3.8]:
		_window(Vector3(x, 0.3 + 1.6, front), Vector3(0, 0, 1), Vector2(3.4, 1.8))
		# Goods on a shelf behind the glass.
		for n in 7:
			var item := BoxMesh.new()
			item.size = Vector3(0.32, rng.randf_range(0.25, 0.55), 0.2)
			_mesh(item, "goods%d" % (n % GOODS.size()), Vector3(x - 1.35 + n * 0.45, 0.3 + 1.05 + item.size.y / 2.0, front + 0.12))
		_box(Vector3(3.4, 0.08, 0.3), "wood", Vector3(x, 0.3 + 1.02, front + 0.12))
	# Striped awning across the front, tilted down toward the street.
	var awning := Node3D.new()
	awning.position = Vector3(0, 0.3 + 3.1, front + 0.9)
	awning.rotation.x = deg_to_rad(20.0)
	add_child(awning)
	var stripes := 13
	for i in stripes:
		var x := -BASE.x / 2.0 + (i + 0.5) * BASE.x / stripes
		var cloth := "awning%d" % (i % 2)
		_box(Vector3(BASE.x / stripes, 0.06, 2.0), cloth, Vector3(x, 0, 0), awning)
		_box(Vector3(BASE.x / stripes, 0.3, 0.05), cloth, Vector3(x, -0.15, 1.0), awning)


## Hanging sign off the front corner with a golden coin pouch.
func _sign() -> void:
	var anchor := Vector3(BASE.x / 2.0 - 0.3, 0.3 + BASE.y - 0.1, BASE.z / 2.0)
	_box(Vector3(0.1, 0.1, 1.8), "beam", anchor + Vector3(0, 0, 0.9))
	var board := anchor + Vector3(0, -0.9, 1.0)
	_box(Vector3(0.12, 1.3, 1.5), "beam", board)
	_box(Vector3(0.16, 1.15, 1.35), "wood", board)
	for side in [-1.0, 1.0]:
		var pouch := SphereMesh.new()
		pouch.radius = 0.36
		pouch.height = 0.62
		_mesh(pouch, "gold", board + Vector3(side * 0.16, -0.1, 0))
		_cylinder(0.12, 0.2, 0.22, "gold", board + Vector3(side * 0.16, 0.18, 0), 10)


## Crates, sacks, barrels and a hand cart beside the entrance.
func _outside_goods(rng: RandomNumberGenerator) -> void:
	var front := BASE.z / 2.0
	for spot in [Vector3(-5.2, 0, front + 0.9), Vector3(-4.3, 0, front + 1.3), Vector3(5.6, 0, front + 0.8)]:
		var crate := _box(Vector3(0.9, 0.8, 0.9), "wood", spot + Vector3(0, 0.4, 0))
		crate.rotation.y = rng.randf_range(-0.4, 0.4)
	_box(Vector3(0.7, 0.6, 0.7), "wood", Vector3(-5.0, 1.1, front + 1.0)).rotation.y = 0.3
	for x in [3.0, 3.6, 4.2]:
		var sack := SphereMesh.new()
		sack.radius = 0.38
		sack.height = 0.85
		_mesh(sack, "sack", Vector3(x, 0.42, front + 1.2))
	for x in [-6.0, 6.1]:
		_cylinder(0.42, 0.38, 0.95, "wood", Vector3(x, 0.3, front - 0.5 + 1.8), 12)
	# Hand cart.
	var cart := Vector3(-2.6, 0, front + 2.6)
	_box(Vector3(1.6, 0.5, 1.0), "wood", cart + Vector3(0, 0.75, 0))
	for z in [-0.55, 0.55]:
		var wheel := _cylinder(0.45, 0.45, 0.1, "beam", Vector3.ZERO, 12)
		wheel.rotation.x = PI / 2.0
		wheel.position = cart + Vector3(0.3, 0.45, z)
	for n in 3:
		_box(Vector3(0.35, 0.3, 0.35), "goods%d" % n, cart + Vector3(-0.45 + n * 0.45, 1.15, 0))


func _window(at: Vector3, facing: Vector3, size: Vector2) -> void:
	var yaw := atan2(facing.x, facing.z)
	var frame := _box(Vector3(size.x + 0.2, size.y + 0.2, 0.1), "beam", at + facing * 0.02)
	frame.rotation.y = yaw
	var pane := _box(Vector3(size.x, size.y, 0.1), "window", at + facing * 0.05)
	pane.rotation.y = yaw


func _add_collision() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BASE.x + 0.6, 4.0, BASE.z + 2.2)
	shape.shape = box
	shape.position = Vector3(0, 2.0, 0.8)
	body.add_child(shape)
	add_child(body)


func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.roughness = 0.85
	if key.begins_with("goods"):
		material.albedo_color = GOODS[int(key.substr(5))]
	elif key.begins_with("awning"):
		material.albedo_color = AWNING[int(key.substr(6))]
	else:
		match key:
			"stone": material.albedo_color = STONE
			"wall": material.albedo_color = WALL
			"beam": material.albedo_color = BEAM
			"roof": material.albedo_color = ROOF
			"wood": material.albedo_color = WOOD
			"sack": material.albedo_color = SACK
			"gold":
				material.albedo_color = GOLD
				material.metallic = 0.8
				material.roughness = 0.3
			"window":
				material.albedo_color = WINDOW_GLOW
				material.emission_enabled = true
				material.emission = WINDOW_GLOW
				material.emission_energy_multiplier = 1.4
	_materials[key] = material
	return material


func _mesh(mesh: Mesh, key: String, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(key)
	instance.position = at
	(parent if parent else self).add_child(instance)
	return instance


func _box(size: Vector3, key: String, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(box, key, at, parent)


## Cylinder standing on `at`.
func _cylinder(top: float, bottom: float, height: float, key: String, at: Vector3, sides: int) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = sides
	return _mesh(cylinder, key, at + Vector3.UP * height / 2.0)
