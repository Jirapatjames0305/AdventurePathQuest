class_name CreatureModel
extends Node3D
## Low-poly monsters built from primitives, in the same chunky style as the
## town. Kinds: wolf, alpha (bigger, darker, red eyes, mane), boar, slime,
## shroom (walking mushroom), spider, bear, treant, bat, beetle.
## Faces +Z. Idle breathing / head bob (slimes squash, bats hover and flap),
## plus tween-driven attack (lunge), hit (recoil + red flash) and death
## (topple + sink) for the combat stage.

@export var kind := "wolf"

const KINDS := {
	"wolf": {"fur": Color(0.55, 0.55, 0.6), "belly": Color(0.82, 0.8, 0.78), "eye": Color(0.12, 0.1, 0.08), "scale": 1.0},
	"alpha": {"fur": Color(0.26, 0.25, 0.3), "belly": Color(0.6, 0.58, 0.6), "eye": Color(1.0, 0.25, 0.15), "scale": 1.45},
	"boar": {"fur": Color(0.45, 0.3, 0.2), "belly": Color(0.62, 0.45, 0.32), "eye": Color(0.1, 0.07, 0.05), "scale": 1.05},
	"slime": {"fur": Color(0.45, 0.85, 0.4), "belly": Color(0.75, 1.0, 0.7), "eye": Color(0.08, 0.12, 0.08), "scale": 1.0},
	"shroom": {"fur": Color(0.85, 0.22, 0.2), "belly": Color(0.95, 0.9, 0.8), "eye": Color(0.1, 0.07, 0.05), "scale": 1.0},
	"spider": {"fur": Color(0.22, 0.2, 0.26), "belly": Color(0.5, 0.2, 0.55), "eye": Color(1.0, 0.25, 0.2), "scale": 1.1},
	"bear": {"fur": Color(0.4, 0.27, 0.17), "belly": Color(0.62, 0.47, 0.33), "eye": Color(0.08, 0.06, 0.05), "scale": 1.5},
	"treant": {"fur": Color(0.42, 0.3, 0.19), "belly": Color(0.32, 0.55, 0.25), "eye": Color(1.0, 0.85, 0.3), "scale": 1.3},
	"bat": {"fur": Color(0.3, 0.24, 0.32), "belly": Color(0.5, 0.38, 0.45), "eye": Color(1.0, 0.85, 0.3), "scale": 0.9},
	"beetle": {"fur": Color(0.18, 0.45, 0.32), "belly": Color(0.15, 0.15, 0.17), "eye": Color(0.9, 0.9, 0.5), "scale": 1.1},
}

var _body: Node3D
var _head: Node3D
var _materials: Array[StandardMaterial3D] = []
var _time := 0.0
var _dead := false
var _wings: Array[Node3D] = []


func _ready() -> void:
	var data: Dictionary = KINDS.get(kind, KINDS.wolf)
	_body = Node3D.new()
	add_child(_body)
	match kind:
		"boar": _build_boar(data)
		"slime": _build_slime(data)
		"shroom": _build_shroom(data)
		"spider": _build_spider(data)
		"bear": _build_bear(data)
		"treant": _build_treant(data)
		"bat": _build_bat(data)
		"beetle": _build_beetle(data)
		_: _build_wolf(data)
	_body.scale = Vector3.ONE * data.scale
	_time = randf() * TAU


func _process(delta: float) -> void:
	if _dead:
		return
	_time += delta
	var base: float = KINDS.get(kind, KINDS.wolf).scale
	match kind:
		"slime":
			var squash := sin(_time * 3.2) * 0.12
			_body.scale = Vector3(base * (1.0 - squash * 0.5), base * (1.0 + squash), base * (1.0 - squash * 0.5))
		"bat":
			_body.position.y = sin(_time * 2.6) * 0.15
			for i in _wings.size():
				_wings[i].rotation.z = sin(_time * 14.0) * 0.6 * (1.0 if i == 0 else -1.0)
		_:
			_body.scale.y = base * (1.0 + sin(_time * 2.4) * 0.025)
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


func _build_slime(data: Dictionary) -> void:
	var goo := _material(data.fur)
	goo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	goo.albedo_color.a = 0.85
	goo.roughness = 0.15
	_part(_sphere(0.6), goo, Vector3(0, 0.45, 0), _body, Vector3.ZERO, Vector3(1.0, 0.75, 1.0))
	_part(_sphere(0.3), _material(data.belly), Vector3(0, 0.38, 0), _body, Vector3.ZERO, Vector3(1.0, 0.7, 1.0))
	_part(_sphere(0.12), _material(Color(1, 1, 1), true), Vector3(-0.25, 0.75, 0.25), _body)
	for x in [-0.18, 0.18]:
		_part(_sphere(0.08), _material(data.eye), Vector3(x, 0.55, 0.5), _body)


func _build_shroom(data: Dictionary) -> void:
	var stem := _material(data.belly)
	var cap := _material(data.fur)
	var spot := _material(Color(0.98, 0.96, 0.9))
	var eye := _material(data.eye)
	for x in [-0.15, 0.15]:
		_part(_capsule(0.08, 0.3), stem, Vector3(x, 0.15, 0), _body)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.24
	trunk.bottom_radius = 0.3
	trunk.height = 0.55
	_part(trunk, stem, Vector3(0, 0.55, 0), _body)
	_head = Node3D.new()
	_head.position = Vector3(0, 0.85, 0)
	_body.add_child(_head)
	var dome := SphereMesh.new()
	dome.radius = 0.55
	dome.height = 0.55
	dome.is_hemisphere = true
	_part(dome, cap, Vector3.ZERO, _head)
	for a in [0.3, 1.6, 2.9, 4.2, 5.4]:
		_part(_sphere(0.08), spot, Vector3(cos(a) * 0.32, 0.36, sin(a) * 0.32), _head)
	for x in [-0.1, 0.1]:
		_part(_sphere(0.05), eye, Vector3(x, -0.15, 0.27), _head)


func _build_spider(data: Dictionary) -> void:
	var shell := _material(data.fur)
	var mark := _material(data.belly)
	var eye := _material(data.eye, true)
	_part(_sphere(0.5), shell, Vector3(0, 0.65, -0.35), _body, Vector3.ZERO, Vector3(1.0, 0.85, 1.1))
	_part(_sphere(0.18), mark, Vector3(0, 0.98, -0.35), _body, Vector3.ZERO, Vector3(1.0, 0.4, 1.4))
	_head = Node3D.new()
	_head.position = Vector3(0, 0.6, 0.25)
	_body.add_child(_head)
	_part(_sphere(0.3), shell, Vector3.ZERO, _head)
	for i in 4:
		var x := -0.12 + (i % 2) * 0.24
		_part(_sphere(0.05), eye, Vector3(x, 0.1 + (i / 2) * 0.08, 0.26), _head)
	for side in [-1.0, 1.0]:
		for i in 4:
			var z := 0.2 - i * 0.22
			var upper := _part(_capsule(0.05, 0.7), shell, Vector3(side * 0.42, 0.75, z), _body, Vector3(0, 0, side * 1.0))
			upper.rotation.y = (i - 1.5) * 0.25 * side
			_part(_capsule(0.045, 0.75), shell, Vector3(side * 0.82, 0.38, z * 1.2), _body, Vector3(0, 0, side * -0.35))


func _build_bear(data: Dictionary) -> void:
	var fur := _material(data.fur)
	var belly := _material(data.belly)
	var eye := _material(data.eye)
	_legs(fur, Vector2(0.3, 0.38), 0.5, 0.15)
	_part(_sphere(0.6), fur, Vector3(0, 0.95, 0), _body, Vector3.ZERO, Vector3(0.95, 0.9, 1.25))
	_part(_sphere(0.42), belly, Vector3(0, 0.8, 0.15), _body, Vector3.ZERO, Vector3(0.9, 0.8, 1.0))
	_head = Node3D.new()
	_head.position = Vector3(0, 1.15, 0.72)
	_body.add_child(_head)
	_part(_sphere(0.34), fur, Vector3.ZERO, _head)
	_part(_sphere(0.16), belly, Vector3(0, -0.08, 0.28), _head, Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	_part(_sphere(0.06), _material(Color(0.08, 0.06, 0.05)), Vector3(0, -0.04, 0.43), _head)
	for x in [-0.22, 0.22]:
		_part(_sphere(0.1), fur, Vector3(x, 0.28, -0.02), _head)
		_part(_sphere(0.045), eye, Vector3(x * 0.55, 0.08, 0.29), _head)


func _build_treant(data: Dictionary) -> void:
	var bark := _material(data.fur)
	var leaves := _material(data.belly)
	var eye := _material(data.eye, true)
	for x in [-0.22, 0.22]:
		_part(_capsule(0.14, 0.6), bark, Vector3(x, 0.3, 0), _body)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.3
	trunk.bottom_radius = 0.42
	trunk.height = 1.2
	_part(trunk, bark, Vector3(0, 1.1, 0), _body)
	for side in [-1.0, 1.0]:
		_part(_capsule(0.09, 0.9), bark, Vector3(side * 0.5, 1.25, 0.1), _body, Vector3(0.4, 0, side * 0.9))
		_part(_sphere(0.25), leaves, Vector3(side * 0.85, 1.5, 0.25), _body)
	_head = Node3D.new()
	_head.position = Vector3(0, 1.9, 0)
	_body.add_child(_head)
	_part(_sphere(0.6), leaves, Vector3(0, 0.25, 0), _head)
	_part(_sphere(0.4), leaves, Vector3(0.35, 0.45, -0.1), _head)
	_part(_sphere(0.4), leaves, Vector3(-0.3, 0.5, 0.05), _head)
	for x in [-0.13, 0.13]:
		_part(_sphere(0.06), eye, Vector3(x, -0.3, 0.33), _head)


func _build_bat(data: Dictionary) -> void:
	var fur := _material(data.fur)
	var wing := _material(data.belly)
	var eye := _material(data.eye, true)
	var hover := Node3D.new()
	hover.position.y = 1.4
	_body.add_child(hover)
	_part(_sphere(0.3), fur, Vector3.ZERO, hover, Vector3.ZERO, Vector3(1.0, 1.0, 1.1))
	for x in [-0.14, 0.14]:
		_part(_cone(0.08, 0.22), fur, Vector3(x, 0.3, 0), hover, Vector3(0, PI / 4.0, 0))
		_part(_sphere(0.05), eye, Vector3(x * 0.8, 0.06, 0.26), hover)
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * 0.25, 0.05, 0)
		hover.add_child(pivot)
		var membrane := BoxMesh.new()
		membrane.size = Vector3(0.75, 0.04, 0.45)
		_part(membrane, wing, Vector3(side * 0.38, 0, -0.05), pivot)
		_wings.append(pivot)


func _build_beetle(data: Dictionary) -> void:
	var shell := _material(data.fur)
	shell.metallic = 0.6
	shell.roughness = 0.25
	var dark := _material(data.belly)
	var eye := _material(data.eye)
	for side in [-1.0, 1.0]:
		for i in 3:
			_part(_capsule(0.05, 0.5), dark, Vector3(side * 0.45, 0.25, 0.3 - i * 0.3), _body, Vector3(0, 0, side * 0.8))
	var dome := SphereMesh.new()
	dome.radius = 0.55
	dome.height = 0.55
	dome.is_hemisphere = true
	_part(dome, shell, Vector3(0, 0.3, -0.05), _body, Vector3.ZERO, Vector3(1.0, 1.2, 1.3))
	_part(_sphere(0.04), dark, Vector3(0, 0.95, -0.05), _body, Vector3.ZERO, Vector3(1.0, 1.0, 14.0))
	_head = Node3D.new()
	_head.position = Vector3(0, 0.38, 0.62)
	_body.add_child(_head)
	_part(_sphere(0.22), dark, Vector3.ZERO, _head)
	_part(_cone(0.07, 0.5), shell, Vector3(0, 0.2, 0.15), _head, Vector3(0.6, 0, 0))
	for x in [-0.1, 0.1]:
		_part(_sphere(0.04), eye, Vector3(x, 0.06, 0.19), _head)
