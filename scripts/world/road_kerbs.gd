class_name RoadKerbs
extends RefCounted
## Shared helpers for raised kerbstones along roads and paved areas.
## Kerbs are laid as individual blocks (one MultiMesh per road) and skip any
## stretch that falls inside another road or paved area, which leaves clean
## openings at every junction.
##
## Roads register in the "roads" group and paved areas (the plaza square) in
## "paved_area"; both implement `covers(world_point: Vector3, margin: float) -> bool`.

const BLOCK := Vector3(0.42, 0.18, 0.85)
const GAP := 0.06
const COLORS := [Color(0.72, 0.7, 0.66), Color(0.66, 0.64, 0.6), Color(0.77, 0.75, 0.7), Color(0.61, 0.59, 0.56)]


## True if `point` (world space) is on any road or paved area other than `exclude`.
static func is_paved(tree: SceneTree, point: Vector3, exclude: Node, margin: float) -> bool:
	for group in ["roads", "paved_area"]:
		for node in tree.get_nodes_in_group(group):
			if node != exclude and node.covers(point, margin):
				return true
	return false


## Block transforms (in `owner` local space) along a local-space polyline,
## skipping blocks whose centre lies on another road / paved area.
static func blocks_along(owner: Node3D, line: PackedVector3Array, height: float) -> Array[Transform3D]:
	var blocks: Array[Transform3D] = []
	var step := BLOCK.z + GAP
	for i in line.size() - 1:
		var from := line[i]
		var to := line[i + 1]
		var length := from.distance_to(to)
		if length < 0.01:
			continue
		var dir := (to - from) / length
		var basis := Basis(Vector3.UP, atan2(dir.x, dir.z))
		var count := maxi(1, roundi(length / step))
		for k in count:
			var center := from.lerp(to, (k + 0.5) / count)
			center.y = height + BLOCK.y / 2.0
			if is_paved(owner.get_tree(), owner.to_global(center), owner, BLOCK.x * 0.6):
				continue
			var scale := Vector3(1.0, 1.0, (length / count - GAP) / BLOCK.z)
			blocks.append(Transform3D(basis.scaled(scale), center))
	return blocks


static func make_instance(blocks: Array[Transform3D], seed: int) -> MultiMeshInstance3D:
	var box := BoxMesh.new()
	box.size = BLOCK
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	box.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = box
	multimesh.instance_count = blocks.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in blocks.size():
		multimesh.set_instance_transform(i, blocks[i])
		multimesh.set_instance_color(i, COLORS[rng.randi() % COLORS.size()])
	var instance := MultiMeshInstance3D.new()
	instance.name = "Kerbs"
	instance.multimesh = multimesh
	return instance
