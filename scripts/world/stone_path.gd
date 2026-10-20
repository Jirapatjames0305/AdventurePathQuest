class_name StonePath
extends MeshInstance3D
## A cobbled road through `corners` — straight segments with sharp (mitered)
## corners; a closed loop if the last corner repeats the first. The surface
## shader lays cobbles in world space with gutters along both edges; raised
## kerbstones run along both sides and open up wherever the road meets
## another road or the plaza square (see RoadKerbs).
## Corners are in this node's local space (the scene root or a parent like Park).

const SHADER := preload("res://shaders/road_cobble.gdshader")

@export var corners := PackedVector3Array()
@export var width := 4.0
@export var height := 0.04


func _ready() -> void:
	add_to_group("roads")
	mesh = _ribbon(_offset_line(width / 2.0), _offset_line(-width / 2.0))
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("width", width)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Kerbs need every other road registered first.
	_build_kerbs.call_deferred()


## World-space test used by other roads' kerbs: is `point` on this road?
func covers(point: Vector3, margin: float) -> bool:
	var local := to_local(point)
	var flat := Vector2(local.x, local.z)
	for i in corners.size() - 1:
		var a := Vector2(corners[i].x, corners[i].z)
		var b := Vector2(corners[i + 1].x, corners[i + 1].z)
		if flat.distance_to(Geometry2D.get_closest_point_to_segment(flat, a, b)) < width / 2.0 + margin:
			return true
	return false


func _build_kerbs() -> void:
	var offset := width / 2.0 + RoadKerbs.BLOCK.x / 2.0 - 0.05
	var blocks: Array[Transform3D] = []
	blocks.append_array(RoadKerbs.blocks_along(self, _offset_line(offset), 0.0))
	blocks.append_array(RoadKerbs.blocks_along(self, _offset_line(-offset), 0.0))
	add_child(RoadKerbs.make_instance(blocks, int(absf(corners[0].x * 31.0 + corners[0].z * 17.0))))


func _is_closed() -> bool:
	return corners.size() > 2 and corners[0].distance_to(corners[-1]) < 0.01


## The centre line shifted sideways by `offset`, with mitered corners.
func _offset_line(offset: float) -> PackedVector3Array:
	var line := PackedVector3Array()
	var last := corners.size() - 1
	var closed := _is_closed()
	for i in corners.size():
		var normal_in: Vector3
		var normal_out: Vector3
		if i > 0:
			normal_in = _normal(corners[i - 1], corners[i])
		elif closed:
			normal_in = _normal(corners[last - 1], corners[0])
		else:
			normal_in = _normal(corners[0], corners[1])
		if i < last:
			normal_out = _normal(corners[i], corners[i + 1])
		elif closed:
			normal_out = _normal(corners[0], corners[1])
		else:
			normal_out = normal_in
		var miter := (normal_in + normal_out).normalized()
		var point := corners[i] + miter * offset / maxf(miter.dot(normal_in), 0.3)
		line.append(Vector3(point.x, height, point.z))
	return line


## Surface strip; UV.x runs 0 (left edge) → 1 (right edge) for the gutters.
func _ribbon(left: PackedVector3Array, right: PackedVector3Array) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in left.size():
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2(0.0, 0.0))
		tool.add_vertex(left[i])
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2(1.0, 0.0))
		tool.add_vertex(right[i])
	for i in left.size() - 1:
		var a := i * 2
		for index in [a, a + 2, a + 1, a + 1, a + 2, a + 3]:
			tool.add_index(index)
	return tool.commit()


func _normal(from: Vector3, to: Vector3) -> Vector3:
	var dir := to - from
	return Vector3(dir.z, 0.0, -dir.x).normalized()
