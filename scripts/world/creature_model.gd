class_name CreatureModel
extends Node3D
## Low-poly monsters built from primitives, in the same chunky style as the
## town. Kinds: "wolf", "alpha" (bigger, darker, red eyes, mane) and "boar"
## (round body, tusks, bristle ridge). Faces +Z. Idle breathing / head bob,
## plus tween-driven attack (lunge), hit (recoil + red flash) and death
## (topple + sink) for the combat stage.

@export var kind := "wolf"

const KINDS := {
	"wolf": {"fur": Color(0.55, 0.55, 0.6), "belly": Color(0.82, 0.8, 0.78), "eye": Color(0.12, 0.1, 0.08), "scale": 1.0},
	"alpha": {"fur": Color(0.26, 0.25, 0.3), "belly": Color(0.6, 0.58, 0.6), "eye": Color(1.0, 0.25, 0.15), "scale": 1.45},
	"boar": {"fur": Color(0.45, 0.3, 0.2), "belly": Color(0.62, 0.45, 0.32), "eye": Color(0.1, 0.07, 0.05), "scale": 1.05},
}

var _body: Node3D
var _head: Node3D
var _materials: Array[StandardMaterial3D] = []
var _time := 0.0
var _dead := false


func _ready() -> void:
	var data: Dictionary = KINDS.get(kind, KINDS.wolf)
	_body = Node3D.new()
	add_child(_body)
	if kind == "boar":
		_build_boar(data)
	else:
		_build_wolf(data)
	_body.scale = Vector3.ONE * data.scale
	_time = randf() * TAU


func _process(delta: float) -> void:
	if _dead:
		return
	_time += delta
	var breathe := 1.0 + sin(_time * 2.4) * 0.025
	_body.scale.y = KINDS.get(kind, KINDS.wolf).scale * breathe
	if _head:
		_head.rotation.x = sin(_time * 1.3) * 0.08


## Lunge toward +Z and back.
func attack() -> void:
	var tween := create_tween()
	tween.tween_property(_body, "position:z", 0.9, 0.14).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "position:z", 0.0, 0.22).set_ease(Tween.EASE_IN_OUT)


## Recoil and flash red.
func hit() -> void:
	var tween := create_tween()
	tween.tween_property(_body, "position:z", -0.35, 0.08)
	tween.tween_property(_body, "position:z", 0.0, 0.2)
	for material in _materials:
		material.emission_enabled = true
		material.emission = Color(1.0, 0.15, 0.1)
		material.emission_energy_multiplier = 1.4
	get_tree().create_timer(0.16).timeout.connect(func():
		for material in _materials:
			material.emission_enabled = false)


## Topple onto its side and sink a little.
func die() -> void:
	_dead = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_body, "rotation:z", PI / 2.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_body, "position:y", -0.15, 0.5)


func _material(color: Color, emissive := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0
	else:
		_materials.append(material)
	return material


func _part(mesh: Mesh, material: Material, at: Vector3, parent: Node3D, rot := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.rotation = rot
	instance.scale = scale
	parent.add_child(instance)
	return instance


func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	return mesh


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	return mesh


func _cone(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 4
	return mesh


func _legs(fur: StandardMaterial3D, spread: Vector2, length: float, thickness: float) -> void:
	for x in [-spread.x, spread.x]:
		for z in [-spread.y, spread.y]:
			_part(_capsule(thickness, length), fur, Vector3(x, length / 2.0, z), _body)


func _build_wolf(data: Dictionary) -> void:
	var fur := _material(data.fur)
	var belly := _material(data.belly)
	var eye := _material(data.eye, kind == "alpha")
	_legs(fur, Vector2(0.22, 0.42), 0.62, 0.09)
	_part(_capsule(0.3, 1.25), fur, Vector3(0, 0.78, 0), _body, Vector3(PI / 2.0, 0, 0))
	_part(_capsule(0.24, 0.9), belly, Vector3(0, 0.66, 0.05), _body, Vector3(PI / 2.0, 0, 0))
	# Tail sweeping up and back.
	_part(_capsule(0.09, 0.7), fur, Vector3(0, 0.95, -0.7), _body, Vector3(-0.9, 0, 0))
	if kind == "alpha":
		_part(_sphere(0.36), fur, Vector3(0, 0.98, 0.45), _body, Vector3.ZERO, Vector3(1.0, 1.0, 0.8))  # mane
	_head = Node3D.new()
	_head.position = Vector3(0, 1.08, 0.62)
	_body.add_child(_head)
	_part(_sphere(0.26), fur, Vector3.ZERO, _head)
	_part(_capsule(0.11, 0.42), belly, Vector3(0, -0.06, 0.28), _head, Vector3(PI / 2.0, 0, 0))
	_part(_sphere(0.06), _material(Color(0.08, 0.07, 0.07)), Vector3(0, -0.04, 0.5), _head)  # nose
	for x in [-0.13, 0.13]:
		_part(_cone(0.1, 0.24), fur, Vector3(x, 0.26, -0.02), _head, Vector3(0, PI / 4.0, 0))
		_part(_sphere(0.045), eye, Vector3(x * 0.8, 0.07, 0.21), _head)


func _build_boar(data: Dictionary) -> void:
	var fur := _material(data.fur)
	var belly := _material(data.belly)
	var snout := _material(Color(0.85, 0.6, 0.55))
	var tusk := _material(Color(0.96, 0.93, 0.85))
	var eye := _material(data.eye)
	_legs(fur, Vector2(0.28, 0.38), 0.45, 0.1)
	_part(_sphere(0.55), fur, Vector3(0, 0.82, 0), _body, Vector3.ZERO, Vector3(0.95, 0.85, 1.25))
	_part(_sphere(0.42), belly, Vector3(0, 0.66, 0.05), _body, Vector3.ZERO, Vector3(0.9, 0.6, 1.1))
	# Bristle ridge down the back.
	for i in 5:
		_part(_cone(0.08, 0.22), _material(data.fur.darkened(0.35)), Vector3(0, 1.28 - abs(i - 2) * 0.04, -0.4 + i * 0.2), _body)
	_part(_capsule(0.05, 0.3), fur, Vector3(0, 0.95, -0.7), _body, Vector3(-0.6, 0, 0))
	_head = Node3D.new()
	_head.position = Vector3(0, 0.85, 0.68)
	_body.add_child(_head)
	_part(_sphere(0.32), fur, Vector3.ZERO, _head, Vector3.ZERO, Vector3(1.0, 0.9, 1.05))
	var nose := CylinderMesh.new()
	nose.top_radius = 0.13
	nose.bottom_radius = 0.16
	nose.height = 0.22
	_part(nose, snout, Vector3(0, -0.06, 0.34), _head, Vector3(PI / 2.0, 0, 0))
	for x in [-0.12, 0.12]:
		_part(_cone(0.04, 0.22), tusk, Vector3(x, -0.08, 0.36), _head, Vector3(-0.5, 0, x * -2.0))
		_part(_cone(0.09, 0.2), fur, Vector3(x * 1.4, 0.28, -0.05), _head, Vector3(0, PI / 4.0, 0))
		_part(_sphere(0.04), eye, Vector3(x * 1.1, 0.1, 0.24), _head)
