class_name Player
extends CharacterBody3D
## Simple test movement for the Phase 0 isometric world.
## Input is rotated by the camera yaw so "up" moves up-screen.

const MOVE_SPEED := 6.0
## Hold Shift (the "sprint" action) to run faster.
const SPRINT_MULTIPLIER := 1.8
const CAMERA_YAW_DEGREES := 45.0

## Set while a shop / quest window is open so the hero stands still.
static var input_locked := false

@onready var model: CharacterModel = $Model


func _ready() -> void:
	add_to_group("player")


func _enter_tree() -> void:
	# Set before Model's _ready so it loads the chosen hero only once.
	$Model.character_id = GameManager.player_data.character_id


func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO if input_locked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).rotated(
		Vector3.UP, deg_to_rad(CAMERA_YAW_DEGREES)
	)

	var sprinting := Input.is_action_pressed("sprint") and not input_locked
	var speed := MOVE_SPEED * (SPRINT_MULTIPLIER if sprinting else 1.0)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	var moving := direction.length_squared() > 0.001
	model.play(("Running_B" if sprinting else "Running_A") if moving else "Idle")
	if moving:
		var target_yaw := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 0.2)
