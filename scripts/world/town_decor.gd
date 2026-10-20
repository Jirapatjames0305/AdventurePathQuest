class_name TownDecor
extends RefCounted
## Procedural town decorations the KayKit packs don't include: fountain,
## lanterns, flower beds, forge glow and floating magic motes. Each builder
## returns a Node3D ready to add to the scene, built from primitive meshes.

const STONE := Color(0.82, 0.8, 0.76)
const STONE_DARK := Color(0.48, 0.5, 0.54)
const WATER := Color(0.3, 0.6, 0.85)
const WOOD := Color(0.36, 0.24, 0.15)
const LAMP_GLOW := Color(1.0, 0.72, 0.38)
const SOIL := Color(0.36, 0.25, 0.16)
const FLOWER_COLORS := [
	Color(0.95, 0.35, 0.4), Color(0.98, 0.8, 0.3), Color(0.75, 0.45, 0.9),
	Color(1.0, 0.6, 0.75), Color(0.95, 0.95, 0.9), Color(0.4, 0.6, 0.95),
]
const LEAF := Color(0.3, 0.55, 0.25)


static func flat_material(color: Color, roughness := 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


static func glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := flat_material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


static func _cylinder(top: float, bottom: float, height: float, material: Material, y: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 24
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position.y = y + height / 2.0
	return instance


static func _box(size: Vector3, material: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	return instance


## Two-tier stone fountain with water and a gentle spray. ~5.6 units wide.
static func fountain() -> Node3D:
	var root := Node3D.new()
	root.name = "Fountain"
	var stone := flat_material(STONE)
	var stone_dark := flat_material(STONE_DARK)
	var water := flat_material(WATER, 0.1)
	water.metallic = 0.3
	root.add_child(_cylinder(2.8, 3.0, 0.7, stone_dark, 0.0))   # outer basin wall
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 2.5
	rim_mesh.outer_radius = 3.1
	var rim := MeshInstance3D.new()
	rim.mesh = rim_mesh
	rim.material_override = stone
	rim.position.y = 0.72
	rim.scale.y = 0.5
	root.add_child(rim)                                          # basin rim
	root.add_child(_cylinder(2.5, 2.5, 0.05, water, 0.72))      # basin water
	root.add_child(_cylinder(0.45, 0.6, 1.8, stone_dark, 0.0))  # pillar
	root.add_child(_cylinder(1.3, 0.5, 0.4, stone, 1.8))        # upper bowl
	root.add_child(_cylinder(1.15, 1.15, 0.05, water, 2.15))    # bowl water
	root.add_child(_cylinder(0.15, 0.25, 0.9, stone_dark, 2.2)) # spout
	var spray := GPUParticles3D.new()
	spray.amount = 60
	spray.lifetime = 1.2
	spray.position.y = 3.1
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 25.0
	process.initial_velocity_min = 1.5
	process.initial_velocity_max = 2.2
	process.gravity = Vector3(0, -4.0, 0)
	spray.process_material = process
	var drop := SphereMesh.new()
	drop.radius = 0.06
	drop.height = 0.12
	drop.material = glow_material(Color(0.75, 0.9, 1.0), 0.6)
	spray.draw_pass_1 = drop
	root.add_child(spray)
	return root


## Wooden lantern post with a warm light. ~2.6 units tall.
static func lantern() -> Node3D:
	var root := Node3D.new()
	root.name = "Lantern"
	var wood := flat_material(WOOD)
	root.add_child(_box(Vector3(0.18, 2.3, 0.18), wood, Vector3(0, 1.15, 0)))
	root.add_child(_box(Vector3(0.6, 0.12, 0.12), wood, Vector3(0.2, 2.25, 0)))
	root.add_child(_box(Vector3(0.36, 0.42, 0.36), glow_material(LAMP_GLOW, 4.0), Vector3(0.42, 1.95, 0)))
	root.add_child(_box(Vector3(0.44, 0.08, 0.44), wood, Vector3(0.42, 2.2, 0)))
	var light := OmniLight3D.new()
	light.light_color = LAMP_GLOW
	light.light_energy = 1.4
	light.omni_range = 6.0
	light.position = Vector3(0.42, 1.9, 0)
	root.add_child(light)
	return root


## Soil bed covered with small colourful flowers and leaves.
static func flower_bed(size: Vector2, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "FlowerBed"
	root.add_child(_box(Vector3(size.x, 0.12, size.y), flat_material(SOIL), Vector3(0, 0.06, 0)))
	var bloom := SphereMesh.new()
	bloom.radius = 0.14
	bloom.height = 0.24
	bloom.radial_segments = 6
	bloom.rings = 3
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.8
	bloom.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = bloom
	var count := int(size.x * size.y * 7.0)
	multimesh.instance_count = count
	for i in count:
		var leaf := i % 3 == 0
		var at := Vector3(
			rng.randf_range(-size.x / 2.0 + 0.15, size.x / 2.0 - 0.15),
			0.2 if leaf else rng.randf_range(0.25, 0.4),
			rng.randf_range(-size.y / 2.0 + 0.15, size.y / 2.0 - 0.15))
		var s := rng.randf_range(1.0, 1.5) if leaf else rng.randf_range(0.7, 1.1)
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * s), at))
		multimesh.set_instance_color(i, LEAF if leaf else FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()])
	var flowers := MultiMeshInstance3D.new()
	flowers.multimesh = multimesh
	root.add_child(flowers)
	return root


## Flickering orange forge glow with drifting embers (attach FORGE_FLICKER).
static func forge_glow() -> Node3D:
	var root := Node3D.new()
	root.name = "ForgeGlow"
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.45, 0.12)
	light.light_energy = 3.0
	light.omni_range = 8.0
	light.position.y = 1.2
	root.add_child(light)
	var embers := GPUParticles3D.new()
	embers.amount = 24
	embers.lifetime = 2.0
	embers.position.y = 1.0
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 30.0
	process.initial_velocity_min = 0.6
	process.initial_velocity_max = 1.2
	process.gravity = Vector3.ZERO
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.6
	embers.process_material = process
	var ember := SphereMesh.new()
	ember.radius = 0.04
	ember.height = 0.08
	ember.material = glow_material(Color(1.0, 0.55, 0.15), 6.0)
	embers.draw_pass_1 = ember
	root.add_child(embers)
	return root


## Soft glowing motes drifting over the town — the "subtle magic" layer.
static func magic_motes(extent: float) -> GPUParticles3D:
	var motes := GPUParticles3D.new()
	motes.name = "MagicMotes"
	motes.amount = 90
	motes.lifetime = 8.0
	motes.preprocess = 8.0
	motes.visibility_aabb = AABB(Vector3(-extent, -2, -extent), Vector3(extent * 2, 8, extent * 2))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(extent, 1.5, extent)
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 0.1
	process.initial_velocity_max = 0.35
	process.gravity = Vector3.ZERO
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.3, Color(1, 1, 1, 1))
	fade.add_point(0.7, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	motes.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.09
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(1.0, 0.8, 0.35, 0.8)
	quad.material = material
	motes.draw_pass_1 = quad
	motes.position.y = 2.0
	return motes
