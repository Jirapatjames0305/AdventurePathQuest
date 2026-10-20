class_name CharacterModel
extends Node3D
## Visual model for a playable character (KayKit Adventurers, CC0).
## Loads the .glb, hides unused gear, and plays looping/one-shot animations.

const BASE_PATH := "res://assets/characters/kaykit_adventurers/"

## id -> display data + which gear meshes to hide (each .glb ships every weapon).
const CHARACTERS := {
	"knight": {
		"name": "Knight",
		"emoji": "🛡️",
		"blurb": "A steady guardian with sword and shield.",
		"model": "Knight.glb",
		"hide": ["1H_Sword_Offhand", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "2H_Sword"],
	},
	"mage": {
		"name": "Mage",
		"emoji": "🔮",
		"blurb": "A curious scholar of arcane staves.",
		"model": "Mage.glb",
		"hide": ["Spellbook", "Spellbook_open", "1H_Wand"],
	},
	"rogue": {
		"name": "Rogue",
		"emoji": "🗡️",
		"blurb": "A quick shadow with twin knives.",
		"model": "Rogue.glb",
		"hide": ["1H_Crossbow", "2H_Crossbow", "Throwable"],
	},
	"barbarian": {
		"name": "Barbarian",
		"emoji": "🪓",
		"blurb": "A cheerful brute with axe and shield.",
		"model": "Barbarian.glb",
		"hide": ["1H_Axe_Offhand", "2H_Axe", "Mug"],
	},
}

const LOOPING := ["Idle", "Running_A", "Running_B", "Walking_A", "2H_Melee_Idle"]
const BLEND_TIME := 0.2

@export var character_id := "knight"

var _anim: AnimationPlayer


func _ready() -> void:
	set_character(character_id)


static func ids() -> Array:
	return CHARACTERS.keys()


static func info(id: String) -> Dictionary:
	return CHARACTERS.get(id, CHARACTERS.knight)


func set_character(id: String) -> void:
	character_id = id if CHARACTERS.has(id) else "knight"
	for child in get_children():
		child.queue_free()
	var data := info(character_id)
	var model: Node3D = load(BASE_PATH + data.model).instantiate()
	add_child(model)
	for gear_name in data.hide:
		var gear := model.find_child(gear_name, true, false)
		if gear:
			gear.visible = false
	_anim = model.find_child("AnimationPlayer", true, false)
	for anim_name in LOOPING:
		if _anim.has_animation(anim_name):
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	play("Idle")


## Plays an animation; if it isn't looping, returns to Idle when it ends.
func play(anim_name: String) -> void:
	if not _anim or not _anim.has_animation(anim_name):
		return
	if _anim.current_animation == anim_name and anim_name in LOOPING:
		return
	_anim.play(anim_name, BLEND_TIME)
	if anim_name not in LOOPING:
		_anim.queue("Idle")
