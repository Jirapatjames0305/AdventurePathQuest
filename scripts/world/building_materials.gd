class_name BuildingMaterials
extends RefCounted
## Shared detailed surface materials for town buildings (see
## shaders/building_surface.gdshader). Cached per mode + colour so every
## building with the same colour shares one material.

const SHADER := preload("res://shaders/building_surface.gdshader")

enum Mode { PLASTER, STONE, ROOF, TIMBER }

static var _cache := {}


static func plaster(color: Color) -> ShaderMaterial:
	return _cached(Mode.PLASTER, color)


static func stone(color: Color) -> ShaderMaterial:
	return _cached(Mode.STONE, color)


static func roof(color: Color) -> ShaderMaterial:
	return _cached(Mode.ROOF, color)


static func timber(color: Color) -> ShaderMaterial:
	return _cached(Mode.TIMBER, color)


static func _cached(mode: Mode, color: Color) -> ShaderMaterial:
	var key := "%d:%s" % [mode, color.to_html()]
	if not _cache.has(key):
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("mode", mode)
		material.set_shader_parameter("base_color", color)
		_cache[key] = material
	return _cache[key]
