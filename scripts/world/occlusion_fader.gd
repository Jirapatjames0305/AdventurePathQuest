extends Node
## Fades buildings that hide the hero from the camera.
## Every node in the "fade_occluder" group is checked each frame: if any of
## its larger parts is between the camera and the hero and that part's
## on-screen outline (projected bounding box) covers the hero, all of the
## building's meshes fade to FADED. Tests run coarse to fine: whole-building
## box, then each part's box, then (only if that passes) the part's actual
## vertices, so tilted or pointy shapes don't fade the building too early.

const GROUP := "fade_occluder"
## GeometryInstance3D.transparency when faded (0 = solid, 1 = invisible).
const FADED := 0.7
const FADE_SPEED := 5.0
## Points on the hero (above the feet) that must stay visible.
const HERO_POINTS := [0.3, 1.0, 1.7]
## Parts smaller than this (longest side, metres) are ignored for the test.
const MIN_PART_SIZE := 0.8

@export var camera_path: NodePath
@export var player_path: NodePath

var _camera: Camera3D
var _player: Node3D
## Each: {"meshes": Array[GeometryInstance3D], "alpha": float,
##        "whole": part, "parts": Array[part]}
## where a part is {"corners": PackedVector3Array, "center": Vector3,
## "points": PackedVector3Array (world-space vertices; empty for the whole)}.
var _occluders: Array[Dictionary] = []


func _ready() -> void:
	_camera = get_node(camera_path)
	_player = get_node(player_path)
	# Buildings build their meshes in their own _ready; collect after them.
	_collect.call_deferred()


func _collect() -> void:
	for node in get_tree().get_nodes_in_group(GROUP):
		var meshes: Array[GeometryInstance3D] = []
		var parts: Array[Dictionary] = []
		var bounds := AABB()
		for child in node.find_children("*", "GeometryInstance3D", true, false):
			meshes.append(child)
			if child is MeshInstance3D:
				var box: AABB = child.global_transform * child.get_aabb()
				bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
				if box.get_longest_axis_size() >= MIN_PART_SIZE:
					parts.append(_part(box, child.global_transform * child.mesh.get_faces()))
		_occluders.append({"meshes": meshes, "alpha": 0.0, "whole": _part(bounds), "parts": parts})


static func _part(box: AABB, points := PackedVector3Array()) -> Dictionary:
	var corners := PackedVector3Array()
	for i in 8:
		corners.append(box.get_endpoint(i))
	return {"corners": corners, "center": box.get_center(), "points": points}


func _process(delta: float) -> void:
	if _occluders.is_empty():
		return
	var forward := -_camera.global_basis.z
	var hero_depth := (_player.global_position - _camera.global_position).dot(forward)
	var hero_points := PackedVector2Array()
	for height in HERO_POINTS:
		hero_points.append(_camera.unproject_position(_player.global_position + Vector3.UP * height))
	for occluder in _occluders:
		var target := FADED if _hides_hero(occluder, forward, hero_depth, hero_points) else 0.0
		if is_equal_approx(occluder.alpha, target):
			continue
		occluder.alpha = move_toward(occluder.alpha, target, FADE_SPEED * delta)
		for mesh: GeometryInstance3D in occluder.meshes:
			mesh.transparency = occluder.alpha


func _hides_hero(occluder: Dictionary, forward: Vector3, hero_depth: float, hero_points: PackedVector2Array) -> bool:
	if not _part_covers(occluder.whole, forward, hero_depth, hero_points):
		return false
	for part in occluder.parts:
		if _part_covers(part, forward, hero_depth, hero_points):
			return true
	return false


## True if the part is nearer the camera than the hero and its outline covers a hero point.
func _part_covers(part: Dictionary, forward: Vector3, hero_depth: float, hero_points: PackedVector2Array) -> bool:
	if (part.center - _camera.global_position).dot(forward) >= hero_depth:
		return false
	if not _outline_covers(part.corners, hero_points):
		return false
	return part.points.is_empty() or _outline_covers(part.points, hero_points)


func _outline_covers(points: PackedVector3Array, hero_points: PackedVector2Array) -> bool:
	var screen := PackedVector2Array()
	for point in points:
		screen.append(_camera.unproject_position(point))
	var outline := Geometry2D.convex_hull(screen)
	for point in hero_points:
		if Geometry2D.is_point_in_polygon(point, outline):
			return true
	return false
