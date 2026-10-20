class_name StonePath
extends MeshInstance3D
## A brick path through `corners` — straight segments with sharp (mitered)
## corners. Paving bricks are laid in world space by the shader so they stay
## square-cut everywhere; kerbstones run along both edges as separate meshes.
## Positions are in world space on the ground (y is ignored).

const SHADER := preload("res://shaders/path_bricks.gdshader")
const KERB_COLOR := Color(0.52, 0.5, 0.47)

@export var corners := PackedVector3Array()
@export var width := 4.0
@export var height := 0.04
@export var kerb_width := 0.35
@export var kerb_height := 0.1


func _ready() -> void:
	mesh = _ribbon(_offset_line(width / 2.0), _offset_line(-width / 2.0))
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var kerb := StandardMaterial3D.new()
	kerb.albedo_color = KERB_COLOR
	kerb.roughness = 0.9
	var inset := width / 2.0 - kerb_width / 2.0
	_build_kerb(_offset_line(inset), kerb)
	_build_kerb(_offset_line(-inset), kerb)


## The centre line shifted sideways by `offset`, with mitered corners.
func _offset_line(offset: float) -> PackedVector3Array:
	var line := PackedVector3Array()
	var last := corners.size() - 1
	for i in corners.size():
		var normal_in := _normal(corners[i - 1], corners[i]) if i > 0 else _normal(corners[0], corners[1])
		var normal_out := _normal(corners[i], corners[i + 1]) if i < last else normal_in
		var miter := (normal_in + normal_out).normalized()
		var point := corners[i] + miter * offset / maxf(miter.dot(normal_in), 0.3)
		line.append(Vector3(point.x, height, point.z))
	return line


func _ribbon(left: PackedVector3Array, right: PackedVector3Array) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in left.size():
		tool.set_normal(Vector3.UP)
		tool.add_vertex(left[i])
		tool.set_normal(Vector3.UP)
		tool.add_vertex(right[i])
	for i in left.size() - 1:
		var a := i * 2
		for index in [a, a + 2, a + 1, a + 1, a + 2, a + 3]:
			tool.add_index(index)
	return tool.commit()


## One box per segment, lengthened by a kerb width so corners close up.
func _build_kerb(line: PackedVector3Array, material: Material) -> void:
	for i in line.size() - 1:
		var from := line[i]
		var to := line[i + 1]
		var box := BoxMesh.new()
		box.size = Vector3(kerb_width, kerb_height, from.distance_to(to) + kerb_width)
		var stone := MeshInstance3D.new()
		stone.mesh = box
		stone.material_override = material
		stone.position = (from + to) / 2.0 + Vector3.UP * (kerb_height / 2.0 - height)
		var dir := to - from
		stone.rotation.y = atan2(dir.x, dir.z)
		add_child(stone)


func _normal(from: Vector3, to: Vector3) -> Vector3:
	var dir := to - from
	return Vector3(dir.z, 0.0, -dir.x).normalized()
