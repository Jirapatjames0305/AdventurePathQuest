extends Node3D
## The four service NPCs standing round the plaza fountain, one at each
## diagonal (= up / left / down / right on screen), each facing out toward
## its own part of town.

const RADIUS := 6.2

## [direction (world x, z), character, name, role, marker colour, service]
const NPCS := [
	[Vector2(-1, -1), "knight", "Captain Aldric", "Guild Quests", Color(0.98, 0.8, 0.3), "quests"],
	[Vector2(-1, 1), "rogue", "Mira", "General Store", Color(0.45, 0.85, 0.5), "store"],
	[Vector2(1, 1), "mage", "Elowen", "Magic Shop", Color(0.75, 0.55, 1.0), "magic"],
	[Vector2(1, -1), "barbarian", "Borin", "Weapon Upgrades", Color(1.0, 0.55, 0.28), "smith"],
]


func _ready() -> void:
	for entry in NPCS:
		var dir: Vector2 = entry[0].normalized()
		var npc := Npc.new()
		npc.name = String(entry[2]).replace(" ", "")
		npc.character_id = entry[1]
		npc.display_name = entry[2]
		npc.role = entry[3]
		npc.marker_color = entry[4]
		npc.service = entry[5]
		npc.position = Vector3(dir.x, 0.0, dir.y) * RADIUS
		npc.rest_yaw = atan2(dir.x, dir.y)
		add_child(npc)
