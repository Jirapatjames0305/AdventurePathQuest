extends Node3D
## Isometric camera rig — fixed angle, smoothly follows a target.

@export var target_path: NodePath
@export var follow_speed := 5.0

var _target: Node3D


func _ready() -> void:
	rotation_degrees = Vector3(-30.0, 45.0, 0.0)
	if target_path != NodePath():
		_target = get_node_or_null(target_path)
	if _target:
		global_position = _target.global_position


func _process(delta: float) -> void:
	if _target:
		global_position = global_position.lerp(
			_target.global_position, minf(follow_speed * delta, 1.0)
		)
