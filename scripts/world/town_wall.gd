class_name TownWall
extends Node3D
## Stone wall around the whole town: crenellated wall segments, round towers
## with cone roofs at the corners and along each side, and a gatehouse where
## the road leaves town. Every segment / tower is its own node in the
## "fade_occluder" group so only the piece hiding the hero fades.
## Coordinates are world-space (this node sits at the origin, unrotated).

const STONE_SHADER := preload("res://shaders/stone_wall.gdshader")

## Wall line as a rectangle in world X/Z: position = (min x, min z).
const BOUNDS := Rect2(-52, -72, 114, 128)
const HEIGHT := 5.0
const THICKNESS := 1.6
const MERLON := Vector3(0.9, 0.8, 0.5)
const MERLON_SPACING := 1.8
const TOWER_SPACING := 32.0
const TOWER_RADIUS := 2.4
const TOWER_HEIGHT := 8.0
## Gates: [side, centre along that side (world coord), opening width].
## Sides: "x-" / "x+" run along Z at min/max X; "z-" / "z+" run along X.
const GATES := [["x+", 0.0, 7.0]]
const GATE_TOWER := Vector3(4.2, 9.5, 4.2)

const ROOF := Color(0.32, 0.36, 0.58)
const WOOD := Color(0.38, 0.25, 0.15)
const IRON := Color(0.16, 0.16, 0.18)
const BANNER := Color(0.62, 0.14, 0.16)
const GOLD := Color(0.92, 0.74, 0.32)

var _stone: ShaderMaterial
var _materials := {}


func _ready() -> void:
	_stone = ShaderMaterial.new()
	_stone.shader = STONE_SHADER
	var x0 := BOUNDS.position.x
	var z0 := BOUNDS.position.y
	var x1 := BOUNDS.end.x
	var z1 := BOUNDS.end.y
	_side("z-", Vector3(x0, 0, z0), Vector3(x1, 0, z0))
	_side("x+", Vector3(x1, 0, z0), Vector3(x1, 0, z1))
	_side("z+", Vector3(x1, 0, z1), Vector3(x0, 0, z1))
	_side("x-", Vector3(x0, 0, z1), Vector3(x0, 0, z0))


## One side: towers at even spacing (corners included, none crowding a
## gate), a gatehouse at each gate, and wall running between consecutive
## anchors (tower ↔ tower, tower ↔ gate tower).
func _side(side: String, from: Vector3, to: Vector3) -> void:
	var length := from.distance_to(to)
	var dir := (to - from) / length
	var spans := ceili(length / TOWER_SPACING)
	var gates := []
	for gate in GATES:
		if gate[0] == side:
			gates.append([_along(side, from, gate[1]), gate[2]])
	# Anchors: [distance along side, trim at that end, is a gate's near edge].
	var anchors := []
	for i in spans + 1:
		var at := length * i / spans
		var near_gate := false
		for gate in gates:
			if absf(at - gate[0]) < gate[1] / 2.0 + GATE_TOWER.x + TOWER_RADIUS * 2.0:
				near_gate = true
		if not near_gate:
			anchors.append([at, TOWER_RADIUS * 0.6, false])
			if i < spans:  # the far corner belongs to the next side
				_tower(from + dir * at)
	for gate in gates:
		var half: float = gate[1] / 2.0 + GATE_TOWER.x
		anchors.append([gate[0] - half, 0.0, true])
		anchors.append([gate[0] + half, 0.0, false])
		_gatehouse(from + dir * gate[0], dir, gate[1])
	anchors.sort_custom(func(a, b): return a[0] < b[0])
	for i in anchors.size() - 1:
		if anchors[i][2]:
			continue  # this span is the gate opening
		var a: float = anchors[i][0] + anchors[i][1]
		var b: float = anchors[i + 1][0] - anchors[i + 1][1]
		if b - a > 0.5:
			_segment(from + dir * a, from + dir * b)


## Distance along a side to the world coordinate `coord` (X or Z, by side).
func _along(side: String, from: Vector3, coord: float) -> float:
	match side:
		"z-": return coord - from.x
		"z+": return from.x - coord
		"x+": return coord - from.z
		_: return from.z - coord


func _piece(name_prefix: String) -> Node3D:
	var node := Node3D.new()
	node.name = name_prefix
	node.add_to_group("fade_occluder")
	add_child(node, true)
	return node


## Straight wall between two points: stone body, walkway cap, merlons both edges.
func _segment(from: Vector3, to: Vector3) -> void:
	var piece := _piece("Wall")
	var length := from.distance_to(to)
	var dir := (to - from) / length
	var yaw := atan2(dir.x, dir.z)
	var center := (from + to) / 2.0
	var body := _box(Vector3(THICKNESS, HEIGHT, length), _stone, center + Vector3.UP * HEIGHT / 2.0, piece)
	body.rotation.y = yaw
	var cap := _box(Vector3(THICKNESS + 0.3, 0.25, length), _stone, center + Vector3.UP * (HEIGHT + 0.12), piece)
	cap.rotation.y = yaw
	var merlon := BoxMesh.new()
	merlon.size = MERLON
	merlon.material = _stone
	var count := maxi(1, floori(length / MERLON_SPACING))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = merlon
	multimesh.instance_count = count * 2
	var side := Vector3(dir.z, 0, -dir.x) * (THICKNESS / 2.0 - MERLON.z / 2.0 + 0.1)
	var basis := Basis(Vector3.UP, yaw + PI / 2.0)
	for i in count:
		var along := from + dir * (length * (i + 0.5) / count) + Vector3.UP * (HEIGHT + 0.25 + MERLON.y / 2.0)
		multimesh.set_instance_transform(i * 2, Transform3D(basis, along + side))
		multimesh.set_instance_transform(i * 2 + 1, Transform3D(basis, along - side))
	var merlons := MultiMeshInstance3D.new()
	merlons.multimesh = multimesh
	piece.add_child(merlons)
	_collider(Vector3(THICKNESS, HEIGHT, length), center + Vector3.UP * HEIGHT / 2.0, yaw, piece)


## Round tower with a ring of merlons and a cone roof.
func _tower(at: Vector3) -> void:
	var piece := _piece("Tower")
	_cylinder(TOWER_RADIUS, TOWER_RADIUS + 0.2, TOWER_HEIGHT, _stone, at, 18, piece)
	_cylinder(TOWER_RADIUS + 0.3, TOWER_RADIUS + 0.3, 0.4, _stone, at + Vector3.UP * TOWER_HEIGHT, 18, piece)
	_cylinder(0.0, TOWER_RADIUS + 0.5, 4.0, _material("roof"), at + Vector3.UP * (TOWER_HEIGHT + 0.4), 18, piece)
	var tip := SphereMesh.new()
	tip.radius = 0.2
	tip.height = 0.4
	_mesh(tip, _material("gold"), at + Vector3.UP * (TOWER_HEIGHT + 4.5), piece)
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var window := _box(Vector3(0.45, 0.9, 0.1), _material("dark"), at + Vector3(cos(a), 0, sin(a)) * (TOWER_RADIUS + 0.01) + Vector3.UP * (TOWER_HEIGHT - 2.0), piece)
		window.rotation.y = atan2(cos(a), sin(a))
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = TOWER_RADIUS + 0.2
	cylinder.height = HEIGHT
	shape.shape = cylinder
	shape.position = at + Vector3.UP * HEIGHT / 2.0
	_body(piece).add_child(shape)


## Two square gate towers either side of the opening, an arch bridge across
## the top, open wooden doors and red banners facing out of town.
func _gatehouse(center: Vector3, dir: Vector3, width: float) -> void:
	var piece := _piece("Gatehouse")
	var outward := Vector3(dir.z, 0, -dir.x)
	if outward.dot(center - Vector3(BOUNDS.get_center().x, 0, BOUNDS.get_center().y)) < 0.0:
		outward = -outward
	var yaw := atan2(dir.x, dir.z)
	for s in [-1.0, 1.0]:
		var at: Vector3 = center + dir * s * (width / 2.0 + GATE_TOWER.x / 2.0)
		var tower := _box(GATE_TOWER, _stone, at + Vector3.UP * GATE_TOWER.y / 2.0, piece)
		tower.rotation.y = yaw
		var roof := PrismMesh.new()
		roof.size = Vector3(GATE_TOWER.x + 0.6, 3.0, GATE_TOWER.z + 0.6)
		var roof_node := _mesh(roof, _material("roof"), at + Vector3.UP * (GATE_TOWER.y + 1.5), piece)
		roof_node.rotation.y = yaw
		var banner := _box(Vector3(0.05, 3.2, 1.4), _material("banner"), at + outward * (GATE_TOWER.z / 2.0 + 0.05) + Vector3.UP * 6.0, piece)
		banner.rotation.y = yaw + PI / 2.0
		_box(Vector3(0.1, 0.12, 1.6), _material("gold"), at + outward * (GATE_TOWER.z / 2.0 + 0.08) + Vector3.UP * 7.6, piece).rotation.y = yaw + PI / 2.0
		_collider(GATE_TOWER, at + Vector3.UP * GATE_TOWER.y / 2.0, yaw, piece)
	# Bridge over the opening (clear height ~4.6 m) with merlons on the outside.
	var bridge := _box(Vector3(THICKNESS + 0.8, 2.6, width), _stone, center + Vector3.UP * (HEIGHT + 0.9), piece)
	bridge.rotation.y = yaw
	for i in 4:
		var m := _box(MERLON, _stone, center + dir * (-width / 2.0 + (i + 0.5) * width / 4.0) + outward * (THICKNESS / 2.0 + 0.2) + Vector3.UP * (HEIGHT + 2.4), piece)
		m.rotation.y = yaw
	# Open doors swung back against the inside of the towers.
	for s in [-1.0, 1.0]:
		var hinge: Vector3 = center + dir * s * (width / 2.0) - outward * (THICKNESS / 2.0)
		var door := _box(Vector3(0.2, HEIGHT - 0.8, width / 2.0), _material("wood"), hinge - outward * (width / 4.0) + Vector3.UP * (HEIGHT - 0.8) / 2.0, piece)
		door.rotation.y = yaw + PI / 2.0
		for y in [1.0, 3.0]:
			var strap := _box(Vector3(0.24, 0.12, width / 2.0), _material("iron"), hinge - outward * (width / 4.0) + Vector3.UP * y, piece)
			strap.rotation.y = yaw + PI / 2.0


func _body(piece: Node3D) -> StaticBody3D:
	var body: StaticBody3D = piece.get_node_or_null("Body")
	if not body:
		body = StaticBody3D.new()
		body.name = "Body"
		piece.add_child(body)
	return body


func _collider(size: Vector3, at: Vector3, yaw: float, piece: Node3D) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	shape.rotation.y = yaw
	_body(piece).add_child(shape)


func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.roughness = 0.85
	match key:
		"roof":
			material.albedo_color = ROOF
			material.roughness = 0.6
		"wood": material.albedo_color = WOOD
		"iron":
			material.albedo_color = IRON
			material.metallic = 0.6
		"banner": material.albedo_color = BANNER
		"dark": material.albedo_color = Color(0.12, 0.11, 0.1)
		"gold":
			material.albedo_color = GOLD
			material.metallic = 0.8
			material.roughness = 0.3
	_materials[key] = material
	return material


func _mesh(mesh: Mesh, material: Material, at: Vector3, parent: Node3D) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance


func _box(size: Vector3, material: Material, at: Vector3, parent: Node3D) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	return _mesh(box, material, at, parent)


## Cylinder (or cone when top = 0) standing on `at`.
func _cylinder(top: float, bottom: float, height: float, material: Material, at: Vector3, sides: int, parent: Node3D) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = sides
	return _mesh(cylinder, material, at + Vector3.UP * height / 2.0, parent)
