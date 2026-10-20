class_name Church
extends Node3D
## A large stone church built from primitives: long nave with a steep roof,
## buttresses and tall stained-glass windows, a rounded apse at the back, and
## a tall bell tower with a spire over the arched entrance.
## Local +Z is the front (entrance).

const STONE := Color(0.82, 0.79, 0.73)
const STONE_DARK := Color(0.6, 0.57, 0.53)
const ROOF := Color(0.34, 0.36, 0.42)
const WOOD := Color(0.36, 0.23, 0.13)
const GOLD := Color(0.92, 0.74, 0.32)
const BELL := Color(0.75, 0.55, 0.25)
const GLASS := [Color(0.35, 0.55, 0.95), Color(0.95, 0.4, 0.35), Color(0.98, 0.82, 0.35), Color(0.45, 0.8, 0.5)]

const NAVE := Vector3(8.0, 7.5, 16.0)
const NAVE_ROOF := 4.5
const TOWER := Vector3(4.6, 15.0, 4.6)
const SPIRE := 8.0
const FOOTING := 0.5

var _materials := {}


func _ready() -> void:
	var half := NAVE / 2.0
	_box(Vector3(NAVE.x + 1.2, FOOTING, NAVE.z + 6.0), "stone_dark", Vector3(0, FOOTING / 2.0, -0.6))
	_build_nave(half)
	_build_apse(half)
	_build_tower(half)
	_add_collision(half)


func _build_nave(half: Vector3) -> void:
	_box(NAVE, "stone", Vector3(0, FOOTING + half.y, 0))
	_box(Vector3(NAVE.x + 0.3, 0.35, NAVE.z + 0.3), "stone_dark", Vector3(0, FOOTING + NAVE.y, 0))
	var roof := PrismMesh.new()
	roof.size = Vector3(NAVE.x + 1.0, NAVE_ROOF, NAVE.z + 0.6)
	_mesh(roof, "roof", Vector3(0, FOOTING + NAVE.y + NAVE_ROOF / 2.0 + 0.17, 0))
	# Buttresses between tall pointed stained-glass windows, both sides.
	for side in [-1.0, 1.0]:
		for i in 5:
			var z := -half.z + 1.0 + i * (NAVE.z - 2.0) / 4.0
			_box(Vector3(0.8, NAVE.y * 0.8, 0.7), "stone_dark", Vector3(side * (half.x + 0.4), FOOTING + NAVE.y * 0.4, z))
			_box(Vector3(0.5, 0.9, 0.5), "stone_dark", Vector3(side * (half.x + 0.3), FOOTING + NAVE.y * 0.8 + 0.3, z))
		for i in 4:
			var z := -half.z + 1.0 + (i + 0.5) * (NAVE.z - 2.0) / 4.0
			_tall_window(Vector3(side * (half.x + 0.02), FOOTING + 3.6, z), Vector3(side, 0, 0), i)


## Half-round apse behind the altar end.
func _build_apse(half: Vector3) -> void:
	var at := Vector3(0, FOOTING, -half.z)
	var wall := _cylinder(half.x - 0.4, half.x - 0.4, NAVE.y * 0.85, "stone", at, 20)
	wall.scale.z = 0.8
	var cap := _cylinder(0.0, half.x - 0.1, 3.4, "roof", at + Vector3.UP * NAVE.y * 0.85, 20)
	cap.scale.z = 0.8


## Bell tower centred on the front, with entrance, rose window, open belfry
## with a bell, corner pinnacles, spire and a gold cross.
func _build_tower(half: Vector3) -> void:
	var z := half.z + TOWER.z / 2.0 - 0.6
	var base := FOOTING
	_box(TOWER, "stone", Vector3(0, base + TOWER.y / 2.0, z))
	for y in [5.0, 10.0]:
		_box(Vector3(TOWER.x + 0.3, 0.3, TOWER.z + 0.3), "stone_dark", Vector3(0, base + y, z))
	var front := z + TOWER.z / 2.0
	# Entrance steps, arched double door.
	for step in 3:
		_box(Vector3(3.6 - step * 0.4, 0.5 - step * 0.15, 0.6), "stone_dark", Vector3(0, (0.5 - step * 0.15) / 2.0, front + 0.3 + (2 - step) * 0.6))
	_box(Vector3(2.0, 3.0, 0.15), "wood", Vector3(0, base + 1.5, front + 0.05))
	var arch := _cylinder(1.0, 1.0, 0.15, "wood", Vector3.ZERO, 16)
	arch.rotation.x = PI / 2.0
	arch.position = Vector3(0, base + 3.0, front + 0.05)
	_box(Vector3(0.06, 2.9, 0.18), "gold", Vector3(0, base + 1.45, front + 0.1))
	# Rose window.
	var rose := _cylinder(0.95, 0.95, 0.1, "glass0", Vector3.ZERO, 16)
	rose.rotation.x = PI / 2.0
	rose.position = Vector3(0, base + 7.4, front + 0.04)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.9
	rim.outer_radius = 1.15
	var rim_node := _mesh(rim, "stone_dark", Vector3(0, base + 7.4, front + 0.06))
	rim_node.rotation.x = PI / 2.0
	# Belfry: openings on all four sides and a bell inside.
	for facing in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var opening := _box(Vector3(1.6, 2.4, 0.2), "dark", Vector3(0, base + 12.2, z) + facing * (TOWER.x / 2.0 + 0.01))
		opening.rotation.y = atan2(facing.x, facing.z)
	_cylinder(0.25, 0.75, 1.1, "bell", Vector3(0, base + 11.4, z), 14)
	# Pinnacles at the tower corners, spire, cross.
	for x in [-1.0, 1.0]:
		for zz in [-1.0, 1.0]:
			_cylinder(0.0, 0.35, 1.6, "stone_dark", Vector3(x * (TOWER.x / 2.0 - 0.2), base + TOWER.y, z + zz * (TOWER.z / 2.0 - 0.2)), 6)
	var spire := _cylinder(0.0, TOWER.x * 0.62, SPIRE, "roof", Vector3(0, base + TOWER.y, z), 8)
	spire.rotation.y = PI / 8.0
	var top := base + TOWER.y + SPIRE
	_box(Vector3(0.12, 1.4, 0.12), "gold", Vector3(0, top + 0.6, z))
	_box(Vector3(0.7, 0.12, 0.12), "gold", Vector3(0, top + 0.9, z))


func _tall_window(at: Vector3, facing: Vector3, index: int) -> void:
	var frame := _box(Vector3(1.3, 3.4, 0.1), "stone_dark", at + facing * 0.01)
	frame.rotation.y = atan2(facing.x, facing.z)
	var pane := _box(Vector3(1.0, 3.0, 0.1), "glass%d" % (index % GLASS.size()), at + facing * 0.04)
	pane.rotation.y = frame.rotation.y
	var point := PrismMesh.new()
	point.size = Vector3(1.3, 0.8, 0.12)
	var tip := _mesh(point, "stone_dark", at + Vector3.UP * 2.1 + facing * 0.01)
	tip.rotation.y = frame.rotation.y


func _add_collision(half: Vector3) -> void:
	var body := StaticBody3D.new()
	var tower_z := half.z + TOWER.z / 2.0 - 0.6
	for entry in [
		[Vector3(NAVE.x + 1.6, 4.0, NAVE.z + 1.0), Vector3(0, 2.0, -0.6)],
		[Vector3(TOWER.x, 4.0, TOWER.z + 1.2), Vector3(0, 2.0, tower_z + 0.4)],
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
		"stone_dark": material.albedo_color = STONE_DARK
		"roof":
			material.albedo_color = ROOF
			material.roughness = 0.6
		"wood": material.albedo_color = WOOD
		"dark": material.albedo_color = Color(0.12, 0.11, 0.1)
		"gold", "bell":
			material.albedo_color = GOLD if key == "gold" else BELL
			material.metallic = 0.8
			material.roughness = 0.3
		_:
			var glass: Color = GLASS[int(key.substr(5))]
			material.albedo_color = glass
			material.emission_enabled = true
			material.emission = glass
			material.emission_energy_multiplier = 1.2
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
