class_name MapGrid
extends Node3D
## Design aid: a lat/long grid on the ground plus a compass and the hero's
## current coordinates, so map positions can be described exactly.
## Directions follow the screen (isometric camera yaw 45°):
##   North = up the screen, East = right on the screen.
## Origin (lat 0, long 0) is the town fountain; 1 unit = 1 world metre.
## Press G to toggle the grid.

## World directions that appear as straight up / right on screen.
const NORTH := Vector3(-0.70710678, 0.0, -0.70710678)
const EAST := Vector3(0.70710678, 0.0, -0.70710678)

const EXTENT := 60
const LINE_STEP := 5
const LABEL_STEP := 10
const LINE_HEIGHT := 0.09
const MINOR_COLOR := Color(1, 1, 1, 0.25)
const MAJOR_COLOR := Color(1, 1, 1, 0.55)
const LAT_AXIS_COLOR := Color(1.0, 0.35, 0.3, 0.9)   # lat 0 line (runs east–west)
const LONG_AXIS_COLOR := Color(0.35, 0.6, 1.0, 0.9)  # long 0 line (runs north–south)

@export var player_path: NodePath

var _player: Node3D
var _readout: Label


static func to_lat_long(world: Vector3) -> Vector2:
	return Vector2(world.dot(NORTH), world.dot(EAST))


static func to_world(lat: float, long: float) -> Vector3:
	return NORTH * lat + EAST * long


func _ready() -> void:
	_player = get_node_or_null(player_path)
	_build_lines()
	_build_labels()
	_build_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		visible = not visible


func _process(_delta: float) -> void:
	if _player and _readout:
		var at := to_lat_long(_player.global_position)
		_readout.text = "📍 lat %.1f   long %.1f" % [at.x, at.y]


func _build_lines() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(-EXTENT, EXTENT + 1, LINE_STEP):
		var color := MAJOR_COLOR if i % LABEL_STEP == 0 else MINOR_COLOR
		# Line of constant lat (runs east–west) and of constant long (north–south).
		_line(mesh, to_world(i, -EXTENT), to_world(i, EXTENT), LAT_AXIS_COLOR if i == 0 else color)
		_line(mesh, to_world(-EXTENT, i), to_world(EXTENT, i), LONG_AXIS_COLOR if i == 0 else color)
	mesh.surface_end()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var lines := MeshInstance3D.new()
	lines.name = "GridLines"
	lines.mesh = mesh
	lines.material_override = material
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lines)


func _line(mesh: ImmediateMesh, from: Vector3, to: Vector3, color: Color) -> void:
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(from + Vector3.UP * LINE_HEIGHT)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(to + Vector3.UP * LINE_HEIGHT)


## "lat,long" at every LABEL_STEP intersection; drawn on top of everything.
func _build_labels() -> void:
	for lat in range(-EXTENT, EXTENT + 1, LABEL_STEP):
		for long in range(-EXTENT, EXTENT + 1, LABEL_STEP):
			var label := Label3D.new()
			label.text = "%d,%d" % [lat, long]
			label.font_size = 40
			label.pixel_size = 0.012
			label.outline_size = 10
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.modulate = Color(1.0, 0.95, 0.4) if lat == 0 or long == 0 else Color(1, 1, 1, 0.9)
			label.position = to_world(lat, long) + Vector3.UP * 0.3
			add_child(label)


## Compass (top-right) and the hero's coordinates (top-center).
func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "MapHud"
	hud.layer = 10
	add_child(hud)

	var compass := Label.new()
	compass.text = "N\nW  ✛  E\nS"
	compass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compass.add_theme_font_size_override("font_size", 34)
	compass.add_theme_color_override("font_color", Color.WHITE)
	compass.add_theme_color_override("font_outline_color", Color.BLACK)
	compass.add_theme_constant_override("outline_size", 10)
	compass.anchor_left = 1.0
	compass.anchor_right = 1.0
	compass.offset_left = -190.0
	compass.offset_right = -40.0
	compass.offset_top = 30.0
	compass.offset_bottom = 190.0
	hud.add_child(compass)

	_readout = Label.new()
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.add_theme_font_size_override("font_size", 30)
	_readout.add_theme_color_override("font_color", Color.WHITE)
	_readout.add_theme_color_override("font_outline_color", Color.BLACK)
	_readout.add_theme_constant_override("outline_size", 10)
	_readout.anchor_left = 0.5
	_readout.anchor_right = 0.5
	_readout.offset_left = -300.0
	_readout.offset_right = 300.0
	_readout.offset_top = 24.0
	hud.add_child(_readout)

	var legend := Label.new()
	legend.text = "lat + = North (up)   long + = East (right)   0,0 = fountain   G = grid on/off"
	legend.add_theme_font_size_override("font_size", 18)
	legend.add_theme_color_override("font_color", Color.WHITE)
	legend.add_theme_color_override("font_outline_color", Color.BLACK)
	legend.add_theme_constant_override("outline_size", 8)
	legend.anchor_top = 1.0
	legend.anchor_bottom = 1.0
	legend.offset_left = 24.0
	legend.offset_top = -48.0
	hud.add_child(legend)
