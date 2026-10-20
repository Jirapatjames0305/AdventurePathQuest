class_name TreasureChest
extends Node3D
## Wooden treasure chest with gold bands and a hinged lid. open() swings the
## lid back (animated unless `instant`), revealing a glowing pile of coins.

const WOOD := Color(0.48, 0.3, 0.16)
const BAND := Color(0.92, 0.72, 0.28)

var _lid: Node3D
var _coins: MeshInstance3D
var is_open := false


func _ready() -> void:
	var wood := _material(WOOD)
	var band := _material(BAND, 0.8)
	_box(Vector3(1.2, 0.6, 0.8), wood, Vector3(0, 0.3, 0), self)
	for x in [-0.45, 0.45]:
		_box(Vector3(0.1, 0.62, 0.82), band, Vector3(x, 0.3, 0), self)
	_coins = _box(Vector3(1.0, 0.1, 0.6), _glow(BAND), Vector3(0, 0.58, 0), self)
	_coins.visible = false
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.6, -0.4)
	add_child(_lid)
	var top := CylinderMesh.new()
	top.top_radius = 0.4
	top.bottom_radius = 0.4
	top.height = 1.2
	top.radial_segments = 12
	var lid := MeshInstance3D.new()
	lid.mesh = top
	lid.material_override = wood
	lid.rotation.z = PI / 2.0
	lid.position = Vector3(0, 0, 0.4)
	lid.scale = Vector3(1.0, 1.0, 0.55)
	_lid.add_child(lid)
	for x in [-0.45, 0.45]:
		var strap := MeshInstance3D.new()
		var ring := CylinderMesh.new()
		ring.top_radius = 0.41
		ring.bottom_radius = 0.41
		ring.height = 0.1
		strap.mesh = ring
		strap.material_override = band
		strap.rotation.z = PI / 2.0
		strap.position = Vector3(x, 0, 0.4)
		strap.scale = Vector3(1.0, 1.0, 0.56)
		_lid.add_child(strap)
	_box(Vector3(0.18, 0.22, 0.06), band, Vector3(0, 0.02, 0.83), _lid)


func open(instant := false) -> void:
	if is_open:
		return
	is_open = true
	_coins.visible = true
	if instant:
		_lid.rotation.x = -1.9
	else:
		create_tween().tween_property(_lid, "rotation:x", -1.9, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.4 if metallic > 0.0 else 0.85
	return material


func _glow(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.6)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.5
	return material


func _box(size: Vector3, material: Material, at: Vector3, parent: Node3D) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = box
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance
