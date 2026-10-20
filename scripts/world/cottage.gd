class_name Cottage
extends Node3D
## A timber-framed cottage built from primitives: stone footing, cream walls
## with dark beams, gabled roof, chimney, door, warmly lit windows and a
## flower box. Local +Z is the front (door side).

const WALL := Color(0.93, 0.88, 0.76)
const BEAM := Color(0.36, 0.24, 0.15)
const STONE := Color(0.6, 0.58, 0.54)
const ROOF := Color(0.62, 0.3, 0.22)
const WINDOW_GLOW := Color(1.0, 0.8, 0.45)
const FLOWERS := [Color(0.95, 0.35, 0.4), Color(0.98, 0.8, 0.3), Color(0.75, 0.45, 0.9)]

## Footprint (x = width, z = depth) and wall height.
const SIZE := Vector3(6.0, 3.2, 5.0)
const FOOTING := 0.4
const ROOF_HEIGHT := 2.6
const ROOF_OVERHANG := 0.5

@export var wall_color := WALL
@export var roof_color := ROOF

var _materials := {}


func _ready() -> void:
	var half := SIZE / 2.0
	_box(Vector3(SIZE.x + 0.2, FOOTING, SIZE.z + 0.2), _flat(STONE), Vector3(0, FOOTING / 2.0, 0))
	_box(SIZE, _flat(wall_color), Vector3(0, FOOTING + half.y, 0))
	_build_beams(half)
	# Gabled roof: ridge runs left–right, so the gable ends face the sides.
	var roof := PrismMesh.new()
	roof.size = Vector3(SIZE.z + ROOF_OVERHANG * 2.0, ROOF_HEIGHT, SIZE.x + ROOF_OVERHANG * 2.0)
	var roof_node := _mesh(roof, _flat(roof_color), Vector3(0, FOOTING + SIZE.y + ROOF_HEIGHT / 2.0, 0))
	roof_node.rotation.y = PI / 2.0
	_box(Vector3(0.8, 2.6, 0.8), _flat(STONE), Vector3(half.x - 1.1, FOOTING + SIZE.y + 1.4, -0.9))
	# Front: door, two windows, flower box, step.
	_box(Vector3(1.1, 2.0, 0.12), _flat(BEAM), Vector3(0, FOOTING + 1.0, half.z + 0.02))
	_box(Vector3(0.08, 0.08, 0.06), _flat(Color(0.9, 0.75, 0.35)), Vector3(0.35, FOOTING + 1.0, half.z + 0.1))
	for x in [-1.9, 1.9]:
		_window(Vector3(x, FOOTING + 1.7, half.z))
		_box(Vector3(1.2, 0.25, 0.35), _flat(BEAM), Vector3(x, FOOTING + 1.05, half.z + 0.18))
		for n in 5:
			var bloom := SphereMesh.new()
			bloom.radius = 0.11
			bloom.height = 0.22
			_mesh(bloom, _flat(FLOWERS[n % FLOWERS.size()]), Vector3(x - 0.45 + n * 0.22, FOOTING + 1.25, half.z + 0.2))
	_box(Vector3(1.6, 0.25, 0.7), _flat(STONE), Vector3(0, 0.12, half.z + 0.45))
	# Side windows.
	for side in [-1.0, 1.0]:
		_window(Vector3(side * half.x, FOOTING + 1.7, 0), Vector3(side, 0, 0))

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(SIZE.x + 0.4, 4.0, SIZE.z + 0.4)
	shape.shape = box
	shape.position.y = 2.0
	body.add_child(shape)
	add_child(body)


## Dark timber frame: corner posts, a mid rail and a top plate on every side.
func _build_beams(half: Vector3) -> void:
	var beam := _flat(BEAM)
	var top := FOOTING + SIZE.y
	for x in [-half.x, half.x]:
		for z in [-half.z, half.z]:
			_box(Vector3(0.22, SIZE.y, 0.22), beam, Vector3(x, FOOTING + half.y, z))
	for z in [-half.z, half.z]:
		_box(Vector3(SIZE.x + 0.1, 0.18, 0.2), beam, Vector3(0, top - 0.09, z))
		_box(Vector3(SIZE.x + 0.1, 0.14, 0.18), beam, Vector3(0, FOOTING + 1.1, z))
		for x in [-1.0, 1.0]:
			_box(Vector3(0.16, SIZE.y, 0.18), beam, Vector3(x * 1.0, FOOTING + half.y, z))
	for x in [-half.x, half.x]:
		_box(Vector3(0.2, 0.18, SIZE.z + 0.1), beam, Vector3(x, top - 0.09, 0))
		_box(Vector3(0.18, 0.14, SIZE.z + 0.1), beam, Vector3(x, FOOTING + 1.1, 0))


func _window(at: Vector3, facing := Vector3(0, 0, 1)) -> MeshInstance3D:
	var glow := StandardMaterial3D.new()
	glow.albedo_color = WINDOW_GLOW
	glow.emission_enabled = true
	glow.emission = WINDOW_GLOW
	glow.emission_energy_multiplier = 1.4
	var frame := _box(Vector3(1.1, 1.0, 0.1), _flat(BEAM), at + facing * 0.01)
	frame.rotation.y = atan2(facing.x, facing.z)
	var pane := _box(Vector3(0.85, 0.75, 0.1), glow, at + facing * 0.04)
	pane.rotation.y = frame.rotation.y
	return pane


func _flat(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.85
		_materials[color] = material
	return _materials[color]


func _mesh(mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	add_child(instance)
	return instance


func _box(size: Vector3, material: Material, at: Vector3) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(box, material, at)
