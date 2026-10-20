class_name BuildingPlanting
extends Node3D
## Plants shrubs (some flowering) along the base of every building in the
## "house" group — round the sides and back, plus the front corners — so
## buildings sit in the landscape. Spots on roads/plaza, inside another
## building, or outside the town wall are skipped. Runs deferred so buildings
## and roads exist first. All shrubs share two MultiMeshes (leaves, blooms).

const SPACING := 1.7
## Distance of the shrub line from the building's footprint edge.
const OFFSET := 0.75
## Front corners get shrubs this far in from each side.
const FRONT_CORNER := 1.6
const LEAVES := [Color(0.27, 0.5, 0.22), Color(0.33, 0.57, 0.26), Color(0.23, 0.45, 0.2), Color(0.38, 0.6, 0.3)]
const FLOWERS := [Color(0.95, 0.35, 0.4), Color(0.98, 0.8, 0.3), Color(0.75, 0.45, 0.9), Color(1.0, 0.6, 0.75), Color(0.95, 0.95, 0.9)]
const FLOWER_CHANCE := 0.35
const SEED := 3131

var _rng := RandomNumberGenerator.new()
var _leaves: Array[Transform3D] = []
var _leaf_colors: Array[Color] = []
var _blooms: Array[Transform3D] = []
var _bloom_colors: Array[Color] = []


func _ready() -> void:
	_rng.seed = SEED
	_plant.call_deferred()


func _plant() -> void:
	var houses := get_tree().get_nodes_in_group("house")
	var footprints := TownTrees.building_footprints(get_tree(), 0.2)
	var area := TownWall.BOUNDS.grow(-2.5)
	for house: Node3D in houses:
		var box := _local_bounds(house)
		var lo := Vector2(box.position.x, box.position.z) - Vector2.ONE * OFFSET
		var hi := Vector2(box.end.x, box.end.z) + Vector2.ONE * OFFSET
		var spots: Array[Vector3] = []
		_line(spots, Vector2(lo.x, lo.y), Vector2(hi.x, lo.y))  # back
		_line(spots, Vector2(lo.x, lo.y), Vector2(lo.x, hi.y))  # sides
		_line(spots, Vector2(hi.x, lo.y), Vector2(hi.x, hi.y))
		for x in [lo.x + FRONT_CORNER * 0.5, hi.x - FRONT_CORNER * 0.5]:
			spots.append(Vector3(x, 0, hi.y))  # front corners
		for spot in spots:
			var world := house.to_global(spot)
			world.y = 0.0
			if not area.has_point(Vector2(world.x, world.z)):
				continue
			if RoadKerbs.is_paved(get_tree(), world, null, 0.7):
				continue
			if _inside(world, footprints):
				continue
			_shrub(world)
	add_child(_multimesh(_leaves, _leaf_colors, 0.5))
	add_child(_multimesh(_blooms, _bloom_colors, 0.09))


## Building bounds in its own local space (ignores lights / particles).
func _local_bounds(house: Node3D) -> AABB:
	var to_local := house.global_transform.affine_inverse()
	var bounds := AABB()
	for mesh in house.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = to_local * mesh.global_transform * mesh.get_aabb()
		bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
	return bounds


func _line(spots: Array[Vector3], from: Vector2, to: Vector2) -> void:
	var count := maxi(1, roundi(from.distance_to(to) / SPACING))
	for i in count + 1:
		var p := from.lerp(to, float(i) / count)
		spots.append(Vector3(p.x + _rng.randf_range(-0.2, 0.2), 0, p.y + _rng.randf_range(-0.2, 0.2)))


func _inside(world: Vector3, footprints: Array[Rect2]) -> bool:
	for rect in footprints:
		if rect.has_point(Vector2(world.x, world.z)):
			return true
	return false


## One shrub = 2–3 overlapping leaf balls, sometimes dotted with flowers.
func _shrub(at: Vector3) -> void:
	var size := _rng.randf_range(0.8, 1.25)
	var color: Color = LEAVES[_rng.randi() % LEAVES.size()]
	for n in _rng.randi_range(2, 3):
		var offset := Vector3(_rng.randf_range(-0.3, 0.3), 0.4 + n * 0.15, _rng.randf_range(-0.3, 0.3)) * size
		var scale := Vector3.ONE * size * _rng.randf_range(0.8, 1.15)
		_leaves.append(Transform3D(Basis().scaled(scale), at + offset))
		_leaf_colors.append(color.lightened(_rng.randf_range(-0.05, 0.08)))
	if _rng.randf() < FLOWER_CHANCE:
		var bloom: Color = FLOWERS[_rng.randi() % FLOWERS.size()]
		for n in 6:
			var a := _rng.randf() * TAU
			var p := at + Vector3(cos(a) * 0.38, _rng.randf_range(0.55, 0.9), sin(a) * 0.38) * size
			_blooms.append(Transform3D(Basis(), p))
			_bloom_colors.append(bloom)


func _multimesh(transforms: Array[Transform3D], colors: Array[Color], radius: float) -> MultiMeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.7
	sphere.radial_segments = 8
	sphere.rings = 4
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	sphere.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = sphere
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
		multimesh.set_instance_color(i, colors[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	return instance
