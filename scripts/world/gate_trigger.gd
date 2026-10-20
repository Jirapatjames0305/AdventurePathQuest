extends Area3D
## Invisible zone just outside the town gate: walking into it opens the world
## map. A floating sign above the road points the way.

@export var size := Vector3(4.0, 4.0, 10.0)


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2.0
	add_child(shape)
	body_entered.connect(_on_body_entered)
	var sign := Label3D.new()
	sign.text = "🗺️  World Map"
	sign.font_size = 56
	sign.pixel_size = 0.01
	sign.outline_size = 16
	sign.modulate = Color(1.0, 0.86, 0.5)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = Vector3(-2.0, 3.2, 0)
	add_child(sign)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameManager.goto_world_map.call_deferred()
