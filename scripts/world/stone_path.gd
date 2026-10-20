class_name StonePath
extends MeshInstance3D
## A brick path drawn as one continuous ribbon along a quadratic curve:
## leaves `start` heading along `start_direction`, then bends to `end`.
## Positions are in world space on the ground (y is ignored).

const SHADER := preload("res://shaders/path_bricks.gdshader")

@export var start := Vector3.ZERO
@export var start_direction := Vector3.RIGHT
@export var end := Vector3.ZERO
## How far the path runs straight out of `start` before bending.
@export var straight_length := 6.0
@export var width := 4.0
@export var height := 0.04
@export var segments := 32


func _ready() -> void:
	var control := start + start_direction.normalized() * straight_length
	var points := PackedVector3Array()
	for i in segments + 1:
		var t := float(i) / segments
		points.append(start.lerp(control, t).lerp(control.lerp(end, t), t))
	mesh = _ribbon(points)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("width", width)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _ribbon(points: PackedVector3Array) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var distance := 0.0
	for i in points.size():
		var ahead := points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]
		var side := Vector3(ahead.z, 0.0, -ahead.x).normalized() * width / 2.0
		if i > 0:
			distance += points[i].distance_to(points[i - 1])
		var center := Vector3(points[i].x, height, points[i].z)
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2(0.0, distance))
		tool.add_vertex(center + side)
		tool.set_normal(Vector3.UP)
		tool.set_uv(Vector2(1.0, distance))
		tool.add_vertex(center - side)
	for i in points.size() - 1:
		var a := i * 2
		tool.add_index(a)
		tool.add_index(a + 2)
		tool.add_index(a + 1)
		tool.add_index(a + 1)
		tool.add_index(a + 2)
		tool.add_index(a + 3)
	return tool.commit()
