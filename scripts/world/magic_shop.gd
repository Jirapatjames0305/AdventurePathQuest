class_name MagicShop
extends Node3D
## A two-storey magic supplies shop, same footprint as the general store
## (upper floor narrower). Magical cues: indigo walls and a purple roof, a
## corner tower with a tilted wizard-hat roof and gold star, a crescent-moon
## sign, a display window of glowing potion bottles, crystal clusters, a
## bubbling cauldron, orbs orbiting the tower and drifting sparkles.
## Local +Z is the front (entrance).

const STONE := Color(0.42, 0.4, 0.48)
const WALL := Color(0.36, 0.32, 0.55)
const TRIM := Color(0.22, 0.17, 0.32)
const ROOF := Color(0.45, 0.22, 0.6)
const GOLD := Color(0.95, 0.78, 0.3)
const WOOD := Color(0.35, 0.24, 0.18)
const WINDOW_GLOW := Color(0.7, 0.55, 1.0)
const CRYSTAL := [Color(0.35, 0.9, 1.0), Color(0.8, 0.45, 1.0), Color(1.0, 0.45, 0.8)]
const POTIONS := [Color(0.3, 1.0, 0.5), Color(1.0, 0.35, 0.4), Color(0.4, 0.6, 1.0), Color(1.0, 0.85, 0.3), Color(0.85, 0.4, 1.0)]
const CAULDRON_GLOW := Color(0.45, 1.0, 0.4)

const BASE := Vector3(13.0, 3.6, 9.5)
const UPPER := Vector2(10.0, 7.0)
const FLOOR_HEIGHT := 3.0
const ROOF_HEIGHT := 4.5
const TOWER_RADIUS := 2.0
const TOWER_HEIGHT := 11.0
const ORB_COUNT := 3

var _materials := {}
var _orbs: Array[Node3D] = []
var _time := 0.0


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
	_build_tower(Vector3(-BASE.x / 2.0 + 0.6, 0.3, -BASE.z / 2.0 + 1.0))
	_shop_front()
	_sign()
	_yard()
	add_child(_sparkles())
	_add_collision()


func _process(delta: float) -> void:
	_time += delta
	for i in _orbs.size():
		var angle := _time * 0.8 + TAU * i / _orbs.size()
		var tower := Vector3(-BASE.x / 2.0 + 0.6, 0.0, -BASE.z / 2.0 + 1.0)
		_orbs[i].position = tower + Vector3(cos(angle) * 3.0, 8.0 + sin(_time * 1.6 + i) * 0.5, sin(angle) * 3.0)


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


## Round stone tower with a tilted wizard-hat roof, gold band and star.
func _build_tower(at: Vector3) -> void:
	_cylinder(TOWER_RADIUS, TOWER_RADIUS + 0.15, TOWER_HEIGHT, "stone", at, 18)
	for y in [4.0, 7.5]:
		_round_window(at + Vector3(0, y, TOWER_RADIUS + 0.01), Vector3(0, 0, 1), 0.45)
	var hat := Node3D.new()
	hat.position = at + Vector3.UP * TOWER_HEIGHT
	hat.rotation = Vector3(deg_to_rad(-8.0), 0, deg_to_rad(10.0))
	add_child(hat)
	_cylinder(TOWER_RADIUS + 0.9, TOWER_RADIUS + 0.9, 0.2, "roof", Vector3.ZERO, 20, hat)
	_cylinder(0.0, TOWER_RADIUS + 0.2, 5.5, "roof", Vector3.UP * 0.2, 20, hat)
	_cylinder(TOWER_RADIUS - 0.2, TOWER_RADIUS, 0.4, "gold", Vector3.UP * 0.6, 20, hat)
	var star := SphereMesh.new()
	star.radius = 0.35
	star.height = 0.7
	star.radial_segments = 5
	star.rings = 2
	_mesh(star, "star", Vector3.UP * 5.9, hat)
	for i in ORB_COUNT:
		var orb := SphereMesh.new()
		orb.radius = 0.28
		orb.height = 0.56
		var node := _mesh(orb, "crystal%d" % (i % CRYSTAL.size()), Vector3.ZERO)
		var light := OmniLight3D.new()
		light.light_color = CRYSTAL[i % CRYSTAL.size()]
		light.light_energy = 0.8
		light.omni_range = 3.0
		node.add_child(light)
		_orbs.append(node)


## Arched door, display window of glowing potion bottles, two crystal clusters.
func _shop_front() -> void:
	var front := BASE.z / 2.0
	_box(Vector3(2.0, 2.6, 0.15), "trim", Vector3(0, 0.3 + 1.3, front + 0.03))
	var arch := _cylinder(1.0, 1.0, 0.15, "trim", Vector3.ZERO, 16)
	arch.rotation.x = PI / 2.0
	arch.position = Vector3(0, 0.3 + 2.6, front + 0.03)
	_box(Vector3(0.1, 0.1, 0.08), "gold", Vector3(0.6, 0.3 + 1.3, front + 0.12))
	_box(Vector3(2.8, 0.25, 1.0), "stone", Vector3(0, 0.12, front + 0.5))
	for x in [-3.8, 3.8]:
		_box(Vector3(3.6, 2.0, 0.1), "trim", Vector3(x, 0.3 + 1.7, front + 0.02))
		_box(Vector3(3.3, 1.75, 0.1), "window", Vector3(x, 0.3 + 1.7, front + 0.05))
		for shelf in 2:
			_box(Vector3(3.3, 0.06, 0.3), "wood", Vector3(x, 0.3 + 1.0 + shelf * 0.8, front + 0.14))
			for n in 6:
				var bottle := Vector3(x - 1.3 + n * 0.52, 0.3 + 1.03 + shelf * 0.8, front + 0.16)
				_cylinder(0.12, 0.14, 0.32, "potion%d" % ((n + shelf * 2) % POTIONS.size()), bottle, 8)
				_cylinder(0.04, 0.05, 0.14, "trim", bottle + Vector3.UP * 0.32, 6)
	for x in [-2.1, 2.1]:
		_crystals(Vector3(x, 0.3, front + 0.8), int(x > 0))


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


## Cauldron with glowing brew and rising bubbles; more crystals by the wall.
func _yard() -> void:
	var cauldron := Vector3(4.8, 0.0, BASE.z / 2.0 + 1.6)
	_cylinder(0.75, 0.55, 0.9, "iron", cauldron, 16)
	_cylinder(0.65, 0.65, 0.06, "brew", cauldron + Vector3.UP * 0.86, 16)
	for leg in 3:
		var a := TAU * leg / 3.0
		_box(Vector3(0.1, 0.35, 0.1), "iron", cauldron + Vector3(cos(a) * 0.5, 0.1, sin(a) * 0.5))
	var glow := OmniLight3D.new()
	glow.light_color = CAULDRON_GLOW
	glow.light_energy = 1.5
	glow.omni_range = 4.0
	glow.position = cauldron + Vector3.UP * 1.3
	add_child(glow)
	var bubbles := GPUParticles3D.new()
	bubbles.amount = 16
	bubbles.lifetime = 1.4
	bubbles.position = cauldron + Vector3.UP * 0.9
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 20.0
	process.initial_velocity_min = 0.4
	process.initial_velocity_max = 0.8
	process.gravity = Vector3.ZERO
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.4
	bubbles.process_material = process
	var bubble := SphereMesh.new()
	bubble.radius = 0.08
	bubble.height = 0.16
	bubble.material = _material("brew")
	bubbles.draw_pass_1 = bubble
	add_child(bubbles)
	_crystals(Vector3(-BASE.x / 2.0 - 0.6, 0.0, 2.0), 2)
	_crystals(Vector3(-4.6, 0.0, BASE.z / 2.0 + 1.4), 0)


func _crystals(at: Vector3, palette: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x * 10.0 + at.z)
	for n in 5:
		var shard := PrismMesh.new()
		var height := rng.randf_range(0.5, 1.2)
		shard.size = Vector3(0.28, height, 0.28)
		var node := _mesh(shard, "crystal%d" % ((palette + n) % CRYSTAL.size()), at + Vector3(rng.randf_range(-0.35, 0.35), height / 2.0, rng.randf_range(-0.35, 0.35)))
		node.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0, TAU), rng.randf_range(-0.4, 0.4))


func _sparkles() -> GPUParticles3D:
	var sparkles := GPUParticles3D.new()
	sparkles.amount = 40
	sparkles.lifetime = 3.0
	sparkles.position = Vector3(0, 3.0, 1.0)
	sparkles.visibility_aabb = AABB(Vector3(-10, -4, -10), Vector3(20, 14, 20))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(BASE.x / 2.0 + 1.0, 3.0, BASE.z / 2.0 + 1.5)
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 0.1
	process.initial_velocity_max = 0.3
	process.gravity = Vector3.ZERO
	sparkles.process_material = process
	var dot := SphereMesh.new()
	dot.radius = 0.05
	dot.height = 0.1
	dot.material = _material("star")
	sparkles.draw_pass_1 = dot
	return sparkles


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
	for entry in [
		[Vector3(BASE.x + 0.6, 4.0, BASE.z + 0.6), Vector3(0, 2.0, 0)],
		[Vector3(1.8, 2.0, 1.8), Vector3(4.8, 1.0, BASE.z / 2.0 + 1.6)],
	]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = entry[0]
		shape.shape = box
		shape.position = entry[1]
		body.add_child(shape)
	var tower := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = TOWER_RADIUS + 0.2
	cylinder.height = 4.0
	tower.shape = cylinder
	tower.position = Vector3(-BASE.x / 2.0 + 0.6, 2.0, -BASE.z / 2.0 + 1.0)
	body.add_child(tower)
	add_child(body)


func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.roughness = 0.85
	var glow := Color.BLACK
	if key.begins_with("crystal"):
		glow = CRYSTAL[int(key.substr(7))]
	elif key.begins_with("potion"):
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
			"brew": glow = CAULDRON_GLOW
	if glow != Color.BLACK:
		material.albedo_color = glow
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = 1.8
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
