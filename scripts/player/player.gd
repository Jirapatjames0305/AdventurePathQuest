class_name Player
extends CharacterBody3D
## Simple test movement for the Phase 0 isometric world.
## Input is rotated by the camera yaw so "up" moves up-screen.

const MOVE_SPEED := 6.0
const CAMERA_YAW_DEGREES := 45.0


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).rotated(
		Vector3.UP, deg_to_rad(CAMERA_YAW_DEGREES)
	)

	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED

	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	if direction.length_squared() > 0.001:
		var target_yaw := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 0.2)
