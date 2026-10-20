class_name TownSquare
extends Node3D
## Ravenfall's town square: a stone fountain at the center of town, ringed by
## brick paving. The hero spawns beside the fountain.

const BRICK_SHADER := preload("res://shaders/brick_paving.gdshader")
const WATER_SHADER := preload("res://shaders/fountain_water.gdshader")

const PLAZA_RADIUS := 10.0
const STONE := Color(0.8, 0.77, 0.71)
const STONE_DARK := Color(0.6, 0.58, 0.54)
const BASIN_RADIUS := 3.0
const BASIN_HEIGHT := 0.75

## Market stalls just outside the brick plaza, in the top-left and
## bottom-right corners of the screen (world −X and +X with the isometric
## camera), facing the fountain.
## Each entry: [angle° around the fountain, awning colour, goods].
const STALL_RADIUS := 11.8
const STALLS := [
	[158.0, Color(0.85, 0.3, 0.28), MarketStall.Goods.FRUIT],
	[180.0, Color(0.3, 0.5, 0.85), MarketStall.Goods.CLOTH],
	[202.0, Color(0.95, 0.75, 0.3), MarketStall.Goods.POTTERY],
	[-22.0, Color(0.4, 0.7, 0.45), MarketStall.Goods.POTTERY],
	[0.0, Color(0.85, 0.45, 0.65), MarketStall.Goods.FRUIT],
	[22.0, Color(0.95, 0.55, 0.25), MarketStall.Goods.CLOTH],
]


func _ready() -> void:
	_build_plaza()
	_build_fountain()
	_build_stalls()


func _build_plaza() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = PLAZA_RADIUS
	disc.bottom_radius = PLAZA_RADIUS
	disc.height = 0.06
	disc.radial_segments = 96
	disc.rings = 1
	var material := ShaderMaterial.new()
	material.shader = BRICK_SHADER
	material.set_shader_parameter("inner_radius", BASIN_RADIUS + 0.2)
	material.set_shader_parameter("outer_radius", PLAZA_RADIUS)
	var plaza := MeshInstance3D.new()
	plaza.name = "BrickPlaza"
	plaza.mesh = disc
	plaza.material_override = material
	plaza.position.y = 0.03
	add_child(plaza)


func _build_fountain() -> void:
	var fountain := Node3D.new()
	fountain.name = "Fountain"
	add_child(fountain)
	var stone := _stone(STONE)
	var stone_dark := _stone(STONE_DARK)
	# Lower basin: wall, rounded rim, water.
	fountain.add_child(_cylinder(BASIN_RADIUS, BASIN_RADIUS + 0.15, BASIN_HEIGHT, stone_dark, 0.0, 12))
	fountain.add_child(_ring(BASIN_RADIUS - 0.3, BASIN_RADIUS + 0.12, stone, BASIN_HEIGHT))
	fountain.add_child(_water(BASIN_RADIUS - 0.3, BASIN_HEIGHT + 0.02))
	# Central column with an upper bowl and a small top bowl.
	fountain.add_child(_cylinder(0.55, 0.75, 0.3, stone, 0.0, 8))
	fountain.add_child(_cylinder(0.32, 0.42, 1.9, stone_dark, 0.3, 8))
	fountain.add_child(_cylinder(1.35, 0.45, 0.45, stone, 1.9, 12))
	fountain.add_child(_ring(1.15, 1.4, stone, 2.35))
	fountain.add_child(_water(1.15, 2.37))
	fountain.add_child(_cylinder(0.16, 0.22, 0.7, stone_dark, 2.35, 8))
	fountain.add_child(_cylinder(0.5, 0.18, 0.22, stone, 3.0, 10))
	fountain.add_child(_water(0.42, 3.24))
	fountain.add_child(_spray(Vector3(0, 3.25, 0), 1.6, 40))
	fountain.add_child(_spray(Vector3(0, 2.4, 0), 2.4, 60))

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = BASIN_RADIUS + 0.2
	cylinder.height = 3.0
	shape.shape = cylinder
	shape.position.y = 1.5
	body.add_child(shape)
	fountain.add_child(body)


func _build_stalls() -> void:
	for i in STALLS.size():
		var angle := deg_to_rad(STALLS[i][0])
		var stall := MarketStall.new()
		stall.name = "Stall%d" % i
		stall.awning_color = STALLS[i][1]
		stall.goods = STALLS[i][2]
		stall.seed = i
		stall.position = Vector3(cos(angle), 0.0, sin(angle)) * STALL_RADIUS
		# Customer side (+Z) faces the fountain.
		stall.rotation.y = atan2(-stall.position.x, -stall.position.z)
		add_child(stall)


func _stone(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material


func _cylinder(top: float, bottom: float, height: float, material: Material, y: float, sides: int) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position.y = y + height / 2.0
	return instance


func _ring(inner: float, outer: float, material: Material, y: float) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 48
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position.y = y
	instance.scale.y = 0.6
	return instance


func _water(radius: float, y: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	mesh.radial_segments = 48
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("radius", radius)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position.y = y
	return instance


## Water droplets arcing out and falling back into the bowl below.
func _spray(at: Vector3, speed: float, amount: int) -> GPUParticles3D:
	var spray := GPUParticles3D.new()
	spray.amount = amount
	spray.lifetime = 0.9
	spray.position = at
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 40.0
	process.initial_velocity_min = speed * 0.8
	process.initial_velocity_max = speed
	process.gravity = Vector3(0, -6.0, 0)
	spray.process_material = process
	var drop := SphereMesh.new()
	drop.radius = 0.05
	drop.height = 0.1
	drop.radial_segments = 6
	drop.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.92, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.6, 0.8, 1.0)
	material.emission_energy_multiplier = 0.4
	drop.material = material
	spray.draw_pass_1 = drop
	return spray
