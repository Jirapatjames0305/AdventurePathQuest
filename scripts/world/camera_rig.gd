extends Node3D
## Isometric camera rig — fixed angle, smoothly follows a target.
## Zoom with the on-screen +/- buttons, the mouse wheel, or the +/- keys.
## Starts fully zoomed in.

@export var target_path: NodePath
@export var follow_speed := 5.0
## Orthographic size range (smaller = closer).
@export var zoom_min := 10.0
@export var zoom_max := 60.0
@export var zoom_step := 1.2
@export var zoom_smooth := 8.0

var _target: Node3D
var _zoom_target := 60.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	rotation_degrees = Vector3(-30.0, 45.0, 0.0)
	if target_path != NodePath():
		_target = get_node_or_null(target_path)
	if _target:
		global_position = _target.global_position
	_zoom_target = zoom_min
	camera.size = zoom_min
	# Orthographic: distance doesn't change the view, but the camera must sit
	# far enough back that the ground at the bottom of a zoomed-out view isn't
	# behind it (clipped).
	camera.position.z = maxf(camera.position.z, zoom_max * 1.6)
	camera.far = maxf(camera.far, camera.position.z + zoom_max * 4.0)
	_build_zoom_buttons()


func _process(delta: float) -> void:
	if _target:
		global_position = global_position.lerp(
			_target.global_position, minf(follow_speed * delta, 1.0)
		)
	camera.size = lerpf(camera.size, _zoom_target, minf(zoom_smooth * delta, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				zoom_in()
			KEY_MINUS, KEY_KP_SUBTRACT:
				zoom_out()


func zoom_in() -> void:
	_zoom_target = clampf(_zoom_target / zoom_step, zoom_min, zoom_max)


func zoom_out() -> void:
	_zoom_target = clampf(_zoom_target * zoom_step, zoom_min, zoom_max)


func _build_zoom_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ZoomButtons"
	layer.layer = 10
	add_child(layer)
	var box := VBoxContainer.new()
	box.anchor_left = 1.0
	box.anchor_right = 1.0
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = -110.0
	box.offset_right = -30.0
	box.offset_top = -210.0
	box.offset_bottom = -60.0
	box.add_theme_constant_override("separation", 10)
	layer.add_child(box)
	for spec in [["+", zoom_in], ["-", zoom_out]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(80, 70)
		button.add_theme_font_size_override("font_size", 40)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(spec[1])
		box.add_child(button)
