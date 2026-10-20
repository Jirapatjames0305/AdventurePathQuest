class_name Vfx
extends RefCounted
## One-shot visual effects (roadmap V10). Each spawns under `parent` at a
## local position and frees itself when done.
## hit_spark · damage_number · heal_glow · level_up · chest_sparkle

const SPARK := Color(1.0, 0.85, 0.45)
const HEAL := Color(0.45, 1.0, 0.55)
const GOLD := Color(1.0, 0.8, 0.3)


## Burst of bright sparks, e.g. where a blow lands.
static func hit_spark(parent: Node, at: Vector3, color := SPARK) -> void:
	_burst(parent, at, color, 26, 0.45, 3.5, 6.0, 0.07, Vector3(0, -9.0, 0), 180.0)


## Number that floats up and fades, e.g. "-12".
static func damage_number(parent: Node, at: Vector3, text: String, color := Color(1.0, 0.55, 0.3)) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 72
	label.pixel_size = 0.008
	label.outline_size = 18
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = at
	parent.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", at + Vector3(0, 1.4, 0), 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.45)
	tween.chain().tween_callback(label.queue_free)


## Green motes spiralling up around a character, plus a soft light pulse.
static func heal_glow(parent: Node, at: Vector3) -> void:
	_burst(parent, at + Vector3(0, 0.2, 0), HEAL, 40, 1.2, 0.8, 1.6, 0.06, Vector3(0, 1.5, 0), 25.0, 0.6)
	_flash_light(parent, at + Vector3(0, 1.0, 0), HEAL, 3.0, 1.0)
	_ring(parent, at + Vector3(0, 0.05, 0), HEAL, 0.4, 1.6, 0.8)


## Golden ring + rising sparks + "LEVEL UP!" text.
static func level_up(parent: Node, at: Vector3) -> void:
	_ring(parent, at + Vector3(0, 0.05, 0), GOLD, 0.3, 3.0, 0.9)
	_burst(parent, at + Vector3(0, 0.3, 0), GOLD, 60, 1.4, 2.0, 4.5, 0.07, Vector3(0, 1.0, 0), 35.0, 0.5)
	_flash_light(parent, at + Vector3(0, 1.2, 0), GOLD, 5.0, 1.2)
	damage_number(parent, at + Vector3(0, 2.3, 0), "LEVEL UP!", GOLD)


## Gold coins popping out plus twinkles, for opening a chest.
static func chest_sparkle(parent: Node, at: Vector3) -> void:
	_burst(parent, at, GOLD, 30, 1.0, 3.0, 5.0, 0.09, Vector3(0, -7.0, 0), 35.0)
	_burst(parent, at + Vector3(0, 0.4, 0), Color(1, 1, 0.85), 24, 1.6, 0.4, 1.2, 0.05, Vector3(0, 0.6, 0), 180.0, 0.9)
	_flash_light(parent, at + Vector3(0, 0.8, 0), GOLD, 4.0, 1.0)


static func _burst(parent: Node, at: Vector3, color: Color, amount: int, lifetime: float,
		speed_min: float, speed_max: float, size: float, gravity: Vector3, spread: float, emit_radius := 0.15) -> void:
	var particles := GPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = amount
	particles.lifetime = lifetime
	particles.position = at
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = spread
	process.initial_velocity_min = speed_min
	process.initial_velocity_max = speed_max
	process.gravity = gravity
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = emit_radius
	process.scale_min = 0.6
	process.scale_max = 1.3
	var fade := Gradient.new()
	fade.set_color(0, Color(color, 1.0))
	fade.set_color(1, Color(color, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	particles.process_material = process
	var dot := SphereMesh.new()
	dot.radius = size
	dot.height = size * 2.0
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = _glow_material()
	particles.draw_pass_1 = dot
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


static func _ring(parent: Node, at: Vector3, color: Color, from_radius: float, to_radius: float, time: float) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 48
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = color
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = material
	ring.position = at
	ring.scale = Vector3(from_radius, 0.15, from_radius)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(to_radius, 0.15, to_radius), time).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, time)
	tween.chain().tween_callback(ring.queue_free)


static func _flash_light(parent: Node, at: Vector3, color: Color, energy: float, time: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 5.0
	light.position = at
	parent.add_child(light)
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, time)
	tween.tween_callback(light.queue_free)


static func _glow_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return material
