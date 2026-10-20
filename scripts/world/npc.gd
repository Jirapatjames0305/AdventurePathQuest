class_name Npc
extends Node3D
## A town NPC: a KayKit character playing its idle animation, a name plate
## (name + role) and a bobbing, spinning marker in the role's colour above
## its head. Turns to face the hero when they come close, then turns back.
## Has a capsule collider so the hero can't walk through.

const TALK_RANGE := 5.0
const TURN_SPEED := 6.0

@export var character_id := "knight"
@export var display_name := "Villager"
@export var role := ""
@export var marker_color := Color(0.95, 0.78, 0.3)
## Direction the NPC faces when the hero isn't near (radians around Y).
@export var rest_yaw := 0.0

var _player: Node3D
var _marker: Node3D
var _time := 0.0


func _ready() -> void:
	add_to_group("npc")
	rotation.y = rest_yaw
	var model := CharacterModel.new()
	model.character_id = character_id
	model.scale = Vector3.ONE * 0.7
	add_child(model)
	_build_nameplate()
	_build_marker()
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	body.add_child(shape)
	add_child(body)
	_player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	_time += delta
	_marker.position.y = 2.55 + sin(_time * 2.2) * 0.12
	_marker.rotation.y += delta * 1.6
	var target := rest_yaw
	if _player:
		var to_player := _player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() < TALK_RANGE:
			target = atan2(to_player.x, to_player.z)
	rotation.y = lerp_angle(rotation.y, target, minf(TURN_SPEED * delta, 1.0))


func _build_nameplate() -> void:
	var title := Label3D.new()
	title.text = display_name
	title.font_size = 44
	title.pixel_size = 0.006
	title.outline_size = 14
	title.modulate = Color.WHITE
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position.y = 2.05
	add_child(title)
	var subtitle := Label3D.new()
	subtitle.text = role
	subtitle.font_size = 34
	subtitle.pixel_size = 0.006
	subtitle.outline_size = 12
	subtitle.modulate = marker_color.lightened(0.25)
	subtitle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	subtitle.position.y = 1.8
	add_child(subtitle)


## Glowing diamond gem that floats above the name plate.
func _build_marker() -> void:
	_marker = Node3D.new()
	add_child(_marker)
	var gem := SphereMesh.new()
	gem.radius = 0.17
	gem.height = 0.46
	gem.radial_segments = 4
	gem.rings = 2
	var material := StandardMaterial3D.new()
	material.albedo_color = marker_color
	material.emission_enabled = true
	material.emission = marker_color
	material.emission_energy_multiplier = 1.6
	material.metallic = 0.4
	material.roughness = 0.3
	gem.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = gem
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marker.add_child(instance)
