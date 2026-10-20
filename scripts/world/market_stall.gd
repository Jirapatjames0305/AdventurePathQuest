class_name MarketStall
extends Node3D
## A wooden market stall built from primitives: counter, corner posts, a
## striped sloping awning, goods on the counter and a crate beside it.
## Local +Z is the customer side.

enum Goods { FRUIT, CLOTH, POTTERY }

const WIDTH := 2.6
const DEPTH := 1.4
const COUNTER_HEIGHT := 1.0
const POST_HEIGHT := 2.5
const WOOD := Color(0.45, 0.3, 0.18)
const WOOD_LIGHT := Color(0.62, 0.45, 0.28)
const CANVAS := Color(0.95, 0.92, 0.84)
const STRIPES := 7

@export var awning_color := Color(0.85, 0.3, 0.28)
@export var goods := Goods.FRUIT
@export var seed := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var wood := _material(WOOD)
	var wood_light := _material(WOOD_LIGHT)
	# Counter with a lighter top board and a front skirt in the awning colour.
	_box(Vector3(WIDTH, COUNTER_HEIGHT - 0.08, DEPTH * 0.6), wood, Vector3(0, (COUNTER_HEIGHT - 0.08) / 2.0, 0.2))
	_box(Vector3(WIDTH + 0.1, 0.08, DEPTH * 0.7), wood_light, Vector3(0, COUNTER_HEIGHT - 0.04, 0.2))
	_box(Vector3(WIDTH - 0.2, 0.5, 0.02), _material(awning_color.darkened(0.15)), Vector3(0, 0.55, 0.52))
	# Corner posts — back posts taller so the awning slopes toward customers.
	for x in [-WIDTH / 2.0 + 0.06, WIDTH / 2.0 - 0.06]:
		_box(Vector3(0.1, POST_HEIGHT, 0.1), wood, Vector3(x, POST_HEIGHT / 2.0, -DEPTH / 2.0))
		_box(Vector3(0.1, POST_HEIGHT - 0.35, 0.1), wood, Vector3(x, (POST_HEIGHT - 0.35) / 2.0, DEPTH / 2.0))
	_build_awning()
	_build_goods(rng)
	var crate := _box(Vector3(0.6, 0.5, 0.6), wood_light, Vector3(WIDTH / 2.0 + 0.45, 0.25, 0.1))
	crate.rotation.y = rng.randf_range(-0.4, 0.4)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WIDTH + 1.0, 2.0, DEPTH)
	shape.shape = box
	shape.position.y = 1.0
	body.add_child(shape)
	add_child(body)


## Alternating coloured and canvas stripes, tilted down toward the front,
## with a short valance hanging off the front edge.
func _build_awning() -> void:
	var color := _material(awning_color)
	var canvas := _material(CANVAS)
	var awning := Node3D.new()
	awning.position = Vector3(0, POST_HEIGHT - 0.15, 0)
	awning.rotation.x = deg_to_rad(14.0)
	add_child(awning)
	var stripe_width := (WIDTH + 0.4) / STRIPES
	for i in STRIPES:
		var x := -(WIDTH + 0.4) / 2.0 + stripe_width * (i + 0.5)
		var cloth := color if i % 2 == 0 else canvas
		_box(Vector3(stripe_width, 0.05, DEPTH + 0.5), cloth, Vector3(x, 0, 0), awning)
		_box(Vector3(stripe_width, 0.28, 0.04), cloth, Vector3(x, -0.14, (DEPTH + 0.5) / 2.0), awning)


func _build_goods(rng: RandomNumberGenerator) -> void:
	var top := COUNTER_HEIGHT
	match goods:
		Goods.FRUIT:
			var fruit_colors := [Color(0.85, 0.2, 0.15), Color(0.95, 0.65, 0.15), Color(0.55, 0.75, 0.2), Color(0.6, 0.25, 0.55)]
			for basket in 3:
				var bx := -0.8 + basket * 0.8
				_cylinder(0.3, 0.24, 0.18, _material(WOOD_LIGHT), Vector3(bx, top, 0.2))
				var fruit := _material(fruit_colors[rng.randi() % fruit_colors.size()])
				for n in 7:
					var ball := SphereMesh.new()
					ball.radius = 0.09
					ball.height = 0.18
					ball.radial_segments = 8
					ball.rings = 4
					_mesh(ball, fruit, Vector3(bx + rng.randf_range(-0.16, 0.16), top + 0.2 + rng.randf_range(0, 0.08), 0.2 + rng.randf_range(-0.16, 0.16)))
		Goods.CLOTH:
			var cloth_colors := [Color(0.3, 0.45, 0.8), Color(0.85, 0.75, 0.3), Color(0.7, 0.3, 0.4), Color(0.35, 0.65, 0.5), Color(0.9, 0.9, 0.85)]
			for n in 5:
				var bolt := _cylinder(0.11, 0.11, 0.7, _material(cloth_colors[n % cloth_colors.size()]), Vector3(-0.95 + n * 0.47, top + 0.11, 0.2))
				bolt.rotation.x = PI / 2.0
				bolt.position.y = top + 0.11
		Goods.POTTERY:
			var clay := [Color(0.72, 0.42, 0.28), Color(0.6, 0.35, 0.25), Color(0.8, 0.6, 0.45)]
			for n in 6:
				var height := rng.randf_range(0.25, 0.45)
				_cylinder(rng.randf_range(0.08, 0.12), rng.randf_range(0.12, 0.16), height, _material(clay[n % clay.size()]), Vector3(-1.0 + n * 0.4, top, 0.2 + rng.randf_range(-0.1, 0.1)))


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


func _mesh(mesh: Mesh, material: Material, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	(parent if parent else self).add_child(instance)
	return instance


func _box(size: Vector3, material: Material, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(box, material, at, parent)


## Cylinder standing on `at` (its base sits at at.y).
func _cylinder(top: float, bottom: float, height: float, material: Material, at: Vector3) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = 12
	return _mesh(cylinder, material, at + Vector3.UP * height / 2.0)
