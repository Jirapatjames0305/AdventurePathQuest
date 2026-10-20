class_name TownTrees
extends Node3D
## Scatters trees over the open grass inside the town wall, keeping clear of
## roads and the plaza (via the "roads" / "paved_area" groups), buildings and
## wall pieces (the "fade_occluder" group), the park (it has its own trees),
## and the gate. Runs deferred so everything it avoids is already built.
## Positions are world space (this node sits at the origin, unrotated).

const COUNT := 70
const SPACING := 5.5
## Keep this far inside the wall line.
const WALL_INSET := 4.5
## Clear space around roads and around building footprints.
const ROAD_CLEARANCE := 1.8
const BUILDING_CLEARANCE := 2.0
const SEED := 7070

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = SEED
	_scatter.call_deferred()


func _scatter() -> void:
	var footprints := building_footprints(get_tree(), BUILDING_CLEARANCE)
	var parks := get_tree().get_nodes_in_group("park")
	var area := TownWall.BOUNDS.grow(-WALL_INSET)
	var body := StaticBody3D.new()
	add_child(body)
	var factory := TreeFactory.new()
	var placed: Array[Vector3] = []
	var tries := 0
	while placed.size() < COUNT and tries < 6000:
		tries += 1
		var at := Vector3(_rng.randf_range(area.position.x, area.end.x), 0.0, _rng.randf_range(area.position.y, area.end.y))
		if RoadKerbs.is_paved(get_tree(), at, null, ROAD_CLEARANCE):
			continue
		if _in_footprint(at, footprints):
			continue
		var in_park := false
		for park in parks:
			if park.contains(at):
				in_park = true
		if in_park:
			continue
		var crowded := false
		for other in placed:
			if other.distance_to(at) < SPACING:
				crowded = true
				break
		if crowded:
			continue
		placed.append(at)
		factory.random_tree(self, body, at, _rng)


## Ground rectangles (x/z) of every building and wall piece, grown by `clearance`.
static func building_footprints(tree: SceneTree, clearance: float) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for node in tree.get_nodes_in_group("fade_occluder"):
		var bounds := AABB()
		for mesh in node.find_children("*", "MeshInstance3D", true, false):
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
		if bounds.size != Vector3.ZERO:
			rects.append(Rect2(bounds.position.x, bounds.position.z, bounds.size.x, bounds.size.z).grow(clearance))
	return rects


func _in_footprint(at: Vector3, footprints: Array[Rect2]) -> bool:
	for rect in footprints:
		if rect.has_point(Vector2(at.x, at.z)):
			return true
	return false
