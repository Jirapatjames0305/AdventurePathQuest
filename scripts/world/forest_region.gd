class_name ForestRegion
extends Node3D
## Blackwood as part of the open world (OW1): the wilderness beyond Ravenfall's
## south gate, about twice the town's size. A darker forest floor, the road
## from the gate, dirt trails out to clearings, and in each clearing a camp of
## one monster type (10 types, weaker near town, stronger deeper in, the Alpha
## Wolf's lair at the far end). Trees are drawn with MultiMeshes so ~1,500 of
## them stay cheap. Positions are world space (this node sits at the origin).

## The forest's extent in world X (south) / Z.
const BOUNDS := Rect2(70, -115, 225, 230)
## Everything the hero may walk in: town + forest (invisible walls outside).
const WORLD := Rect2(-62, -118, 360, 236)
const SEED := 9090
const TREE_TARGET := 1500
const TREE_SPACING := 3.0
const CLEARING_RADIUS := 9.0
const TRAIL_CLEARANCE := 3.2
## The cobbled road from the gate runs along z = 0 up to here.
const ROAD_END_X := 140.0

## [enemy file, camp centre (x, z), count]. Ordered roughly by distance.
const CAMPS := [
	["green_slime", Vector2(92, -42), 5],
	["forest_bat", Vector2(96, 48), 4],
	["green_slime", Vector2(112, 96), 4],
	["shroomling", Vector2(124, -78), 4],
	["forest_wolf", Vector2(152, 34), 4],
	["thorn_beetle", Vector2(166, -36), 3],
	["shroomling", Vector2(150, -100), 3],
	["wild_boar", Vector2(186, 72), 3],
	["giant_spider", Vector2(200, -84), 3],
	["forest_wolf", Vector2(206, 104), 3],
	["treant_sapling", Vector2(228, 40), 3],
	["brown_bear", Vector2(242, -46), 2],
	["forest_bat", Vector2(232, -100), 4],
	["alpha_wolf", Vector2(276, 0), 1],
]
## Trails: from a point on the road / another camp to a camp (indices into CAMPS).
const TRAILS := [
	[Vector2(92, 0), 0], [Vector2(96, 0), 1], [1, 2], [0, 3], [Vector2(140, 0), 4],
	[Vector2(140, 0), 5], [3, 6], [4, 7], [5, 8], [7, 9], [4, 10], [5, 11], [8, 12], [10, 13], [11, 13],
]

const FLOOR := [Color(0.22, 0.36, 0.18), Color(0.3, 0.45, 0.22)]
const DIRT := Color(0.46, 0.35, 0.23)
const TRUNK := Color(0.4, 0.27, 0.16)
const LEAVES := [Color(0.24, 0.45, 0.2), Color(0.3, 0.52, 0.24), Color(0.2, 0.4, 0.19), Color(0.36, 0.56, 0.27)]
const PINES := [Color(0.16, 0.34, 0.2), Color(0.2, 0.4, 0.24), Color(0.14, 0.3, 0.18)]
const MUSHROOM := [Color(0.55, 0.85, 1.0), Color(0.85, 0.6, 1.0), Color(1.0, 0.7, 0.45)]

## Every tree: [world position, TreeFactory.Kind] — read by the minimap.
var trees: Array = []
## Every camp: {"enemy": EnemyData, "center": Vector3, "monsters": Array[CreatureModel]}
var camps: Array = []
## Trail segments [from, to] in world XZ — read by the minimap.
var trails: Array = []

var _rng := RandomNumberGenerator.new()
## Tree materials that cut a see-through hole round the hero.
var _foliage: Array[ShaderMaterial] = []
var _player: Node3D
var _body: StaticBody3D



func _ready() -> void:
	add_to_group("tree_source")
	add_to_group("forest_region")
	_rng.seed = SEED
	_body = StaticBody3D.new()
	_body.name = "ForestColliders"
	add_child(_body)
	_build_floor()
	_build_trails()
	_build_camps()
	_build_trees()
	_build_undergrowth()
	_build_boundary()


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if not _player:
			return
	for material in _foliage:
		material.set_shader_parameter("focus_point", _player.global_position + Vector3.UP * 0.6)


func _camp_point(ref) -> Vector2:
	return ref if ref is Vector2 else CAMPS[ref][1]


# --- Ground and trails ---

func _build_floor() -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	var ramp := Gradient.new()
	ramp.set_color(0, FLOOR[0])
	ramp.set_color(1, FLOOR[1])
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.color_ramp = ramp
	texture.seamless = true
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 1.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / 48.0
	var plane := PlaneMesh.new()
	plane.size = BOUNDS.size + Vector2(30, 30)
	var floor := MeshInstance3D.new()
	floor.mesh = plane
	floor.material_override = material
	floor.position = Vector3(BOUNDS.get_center().x + 8, 0.006, BOUNDS.get_center().y)
	add_child(floor)


## Dirt trails as rows of flattened discs, gently curved.
func _build_trails() -> void:
	var dirt := StandardMaterial3D.new()
	dirt.albedo_color = DIRT
	dirt.roughness = 1.0
	var disc := CylinderMesh.new()
	disc.top_radius = 1.6
	disc.bottom_radius = 1.6
	disc.height = 0.02
	disc.radial_segments = 28
	var transforms: Array[Transform3D] = []
	for trail in TRAILS:
		var a := _camp_point(trail[0])
		var b := _camp_point(trail[1])
		trails.append([a, b])
		var length := a.distance_to(b)
		var normal := Vector2(b.y - a.y, a.x - b.x).normalized()
		var steps := maxi(2, int(length / 2.0))
		for i in steps + 1:
			var t := float(i) / steps
			var p := a.lerp(b, t) + normal * sin(t * PI) * minf(length * 0.08, 6.0)
			transforms.append(Transform3D(Basis().scaled(Vector3(1.0, 1.0, 1.2)), Vector3(p.x, 0.012, p.y)))
	for camp in CAMPS:
		var c: Vector2 = camp[1]
		var r := CLEARING_RADIUS * (1.5 if camp[0] == "alpha_wolf" else 1.0) / 1.6
		transforms.append(Transform3D(Basis().scaled(Vector3(r, 1.0, r)), Vector3(c.x, 0.011, c.y)))
	add_child(_multimesh(disc, dirt, transforms))


# --- Camps ---

func _build_camps() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.56, 0.54, 0.5)
	for camp in CAMPS:
		var enemy: EnemyData = load("res://data/enemies/%s.tres" % camp[0])
		var center := Vector3(camp[1].x, 0, camp[1].y)
		var boss: bool = camp[0] == "alpha_wolf"
		var monsters: Array[CreatureModel] = []
		var spots := _camp_spots(camp[2], 4.5 if not boss else 0.0)
		for i in camp[2]:
			var creature := CreatureModel.new()
			creature.kind = enemy.model
			creature.position = center + spots[i]
			creature.rotation.y = _rng.randf() * TAU
			creature.scale = Vector3.ONE * (1.4 if boss else 1.0)
			add_child(creature)
			monsters.append(creature)
			_collider_cylinder(creature.position, 0.7 * (1.6 if boss else 1.0))
		if boss:
			# Guards and a ring of standing stones round the lair.
			for g in 2:
				var guard := CreatureModel.new()
				guard.kind = "wolf"
				guard.position = center + Vector3(-4.0, 0, (g * 2 - 1) * 5.0)
				guard.rotation.y = -PI / 2.0
				add_child(guard)
				_collider_cylinder(guard.position, 0.7)
			for i in 12:
				var a := TAU * i / 12.0
				var rock := BoxMesh.new()
				rock.size = Vector3(1.0, _rng.randf_range(2.0, 3.4), 0.8)
				var piece := MeshInstance3D.new()
				piece.mesh = rock
				piece.material_override = stone
				piece.position = center + Vector3(cos(a), 0, sin(a)) * 14.0 + Vector3(0, rock.size.y / 2.0, 0)
				piece.rotation.y = -a
				add_child(piece)
		_camp_sign(enemy, center, camp[2], boss)
		camps.append({"enemy": enemy, "center": center, "monsters": monsters})


## Loose cluster offsets inside a camp, kept apart from each other.
func _camp_spots(count: int, spread: float) -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var tries := 0
	while spots.size() < count and tries < 200:
		tries += 1
		var p := Vector3(_rng.randf_range(-spread, spread), 0, _rng.randf_range(-spread, spread))
		var ok := true
		for other in spots:
			if other.distance_to(p) < 2.2:
				ok = false
		if ok:
			spots.append(p)
	while spots.size() < count:
		spots.append(Vector3.ZERO)
	return spots


func _camp_sign(enemy: EnemyData, center: Vector3, count: int, boss: bool) -> void:
	var sign := Label3D.new()
	sign.text = "%s %s%s" % [enemy.emoji, enemy.display_name, "" if boss else "  ×%d" % count]
	sign.font_size = 64 if boss else 48
	sign.pixel_size = 0.012
	sign.outline_size = 16
	sign.modulate = Color(1.0, 0.55, 0.45) if boss else Color(1.0, 0.92, 0.75)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = center + Vector3(0, 6.0 if boss else 4.2, 0)
	add_child(sign)


# --- Trees ---

func _blocked(p: Vector2, clearance: float) -> bool:
	if p.x < BOUNDS.position.x - 4.0:
		return true
	if p.x < ROAD_END_X + 6.0 and absf(p.y) < 7.0:
		return true  # the road from the gate
	for camp in CAMPS:
		var r := CLEARING_RADIUS * (1.6 if camp[0] == "alpha_wolf" else 1.0)
		if p.distance_to(camp[1]) < r + clearance:
			return true
	for seg in trails:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1])) < TRAIL_CLEARANCE + clearance:
			return true
	return false


func _build_trees() -> void:
	var placed := {}  # grid cell -> positions, for fast spacing checks
	var count := 0
	var tries := 0
	var trunk_xf: Array[Transform3D] = []
	var ball_xf: Array[Transform3D] = []
	var ball_col: Array[Color] = []
	var cone_xf: Array[Transform3D] = []
	var cone_col: Array[Color] = []
	while count < TREE_TARGET and tries < TREE_TARGET * 8:
		tries += 1
		var p := Vector2(_rng.randf_range(BOUNDS.position.x, BOUNDS.end.x), _rng.randf_range(BOUNDS.position.y, BOUNDS.end.y))
		if _blocked(p, 1.0) or _crowded(placed, p):
			continue
		var cell := Vector2i(floori(p.x / 6.0), floori(p.y / 6.0))
		if not placed.has(cell):
			placed[cell] = []
		placed[cell].append(p)
		count += 1
		var at := Vector3(p.x, 0, p.y)
		var size := _rng.randf_range(0.9, 1.5)
		if _rng.randf() < 0.55:
			_pine(at, size, trunk_xf, cone_xf, cone_col)
			trees.append([at, TreeFactory.Kind.PINE])
		else:
			_leafy(at, size, trunk_xf, ball_xf, ball_col)
			trees.append([at, TreeFactory.Kind.LEAFY])
		_collider_cylinder(at, 0.35 * size)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.6
	trunk.bottom_radius = 1.0
	trunk.height = 1.0
	trunk.radial_segments = 7
	add_child(_multimesh(trunk, _foliage_material(TRUNK), trunk_xf))
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 1.75
	ball.radial_segments = 9
	ball.rings = 5
	add_child(_multimesh(ball, _foliage_material(), ball_xf, ball_col))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.18
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 9
	add_child(_multimesh(cone, _foliage_material(), cone_xf, cone_col))


func _crowded(placed: Dictionary, p: Vector2) -> bool:
	var cell := Vector2i(floori(p.x / 6.0), floori(p.y / 6.0))
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for other in placed.get(cell + Vector2i(dx, dy), []):
				if other.distance_to(p) < TREE_SPACING:
					return true
	return false


func _pine(at: Vector3, size: float, trunk_xf: Array[Transform3D], cone_xf: Array[Transform3D], cone_col: Array[Color]) -> void:
	trunk_xf.append(Transform3D(Basis().scaled(Vector3(0.24, 1.3, 0.24) * size), at + Vector3.UP * 0.65 * size))
	var base: Color = PINES[_rng.randi() % PINES.size()]
	for n in 4:
		var radius := (1.6 - n * 0.32) * size
		var height := (1.5 - n * 0.12) * size
		var basis := Basis(Vector3.UP, n * 0.4).scaled(Vector3(radius, height, radius))
		cone_xf.append(Transform3D(basis, at + Vector3.UP * ((0.9 + n * 0.85) * size + height / 2.0)))
		cone_col.append(base.darkened(0.12) if n % 2 == 0 else base.lightened(0.08))


func _leafy(at: Vector3, size: float, trunk_xf: Array[Transform3D], ball_xf: Array[Transform3D], ball_col: Array[Color]) -> void:
	var trunk_h := 2.3 * size
	trunk_xf.append(Transform3D(Basis().scaled(Vector3(0.26, trunk_h, 0.26) * Vector3(size, 1.0, size)), at + Vector3.UP * trunk_h / 2.0))
	var base: Color = LEAVES[_rng.randi() % LEAVES.size()]
	var crown := at + Vector3.UP * (trunk_h + 0.75 * size)
	var radius := 1.2 * size
	ball_xf.append(Transform3D(Basis().scaled(Vector3.ONE * radius), crown))
	ball_col.append(base)
	var spin := _rng.randf() * TAU
	for i in 5:
		var a := spin + TAU * i / 5.0
		var rise := _rng.randf_range(-0.4, 0.6)
		var out := Vector3(cos(a), rise, sin(a)).normalized()
		ball_xf.append(Transform3D(Basis().scaled(Vector3.ONE * radius * _rng.randf_range(0.5, 0.68)), crown + out * radius * 0.78))
		ball_col.append(base.lightened(0.14) if rise > 0.25 else (base.darkened(0.2) if rise < -0.1 else base))
	ball_xf.append(Transform3D(Basis().scaled(Vector3.ONE * radius * 0.55), crown + Vector3.UP * radius * 0.75))
	ball_col.append(base.lightened(0.2))


## Rocks and glowing mushroom clusters on the forest floor.
func _build_undergrowth() -> void:
	var rock_xf: Array[Transform3D] = []
	var cap_xf: Array[Transform3D] = []
	var cap_col: Array[Color] = []
	for i in 260:
		var p := Vector2(_rng.randf_range(BOUNDS.position.x, BOUNDS.end.x), _rng.randf_range(BOUNDS.position.y, BOUNDS.end.y))
		if _blocked(p, -2.0):
			continue
		var at := Vector3(p.x, 0, p.y)
		if i % 2 == 0:
			var r := _rng.randf_range(0.3, 0.8)
			rock_xf.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(r, r * 0.65, r * 0.85)), at + Vector3.UP * 0.1))
		else:
			var color: Color = MUSHROOM[_rng.randi() % MUSHROOM.size()]
			for n in _rng.randi_range(1, 3):
				var offset := Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.18, 0.32), _rng.randf_range(-0.3, 0.3))
				cap_xf.append(Transform3D(Basis().scaled(Vector3(0.15, 0.09, 0.15)), at + offset))
				cap_col.append(color)
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 2.0
	rock.radial_segments = 7
	rock.rings = 4
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.5, 0.5, 0.52)
	add_child(_multimesh(rock, rock_mat, rock_xf))
	var cap := SphereMesh.new()
	cap.radius = 1.0
	cap.height = 2.0
	cap.radial_segments = 8
	cap.rings = 4
	var cap_mat := _vertex_color_material()
	cap_mat.emission_enabled = true
	cap_mat.emission_energy_multiplier = 1.4
	cap_mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	cap_mat.emission = Color(1, 1, 1)
	add_child(_multimesh(cap, cap_mat, cap_xf, cap_col))


## Invisible walls round the whole walkable world (town + forest).
func _build_boundary() -> void:
	var walls := [
		[Vector3(WORLD.size.x, 6, 2), Vector3(WORLD.get_center().x, 3, WORLD.position.y)],
		[Vector3(WORLD.size.x, 6, 2), Vector3(WORLD.get_center().x, 3, WORLD.end.y)],
		[Vector3(2, 6, WORLD.size.y), Vector3(WORLD.position.x, 3, WORLD.get_center().y)],
		[Vector3(2, 6, WORLD.size.y), Vector3(WORLD.end.x, 3, WORLD.get_center().y)],
	]
	for wall in walls:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall[0]
		shape.shape = box
		shape.position = wall[1]
		_body.add_child(shape)


# --- Helpers ---

func _collider_cylinder(at: Vector3, radius: float) -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 3.0
	shape.shape = cylinder
	shape.position = at + Vector3.UP * 1.5
	_body.add_child(shape)


## Flat `color`, or the per-instance colour when none is given.
func _foliage_material(color := Color(0, 0, 0, 0)) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/forest_foliage.gdshader")
	if color.a > 0.0:
		material.set_shader_parameter("albedo", color)
	else:
		material.set_shader_parameter("use_instance_color", true)
	_foliage.append(material)
	return material


func _vertex_color_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	return material


func _multimesh(mesh: Mesh, material: Material, transforms: Array[Transform3D], colors: Array[Color] = []) -> MultiMeshInstance3D:
	mesh.surface_set_material(0, material)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = not colors.is_empty()
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
		if not colors.is_empty():
			multimesh.set_instance_color(i, colors[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	return instance
