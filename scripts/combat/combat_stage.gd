class_name CombatStage
extends Node3D
## The 3D battle stage (roadmap V9): a small forest clearing where the hero
## (KayKit character) faces the enemy (CreatureModel). CombatManager calls the
## methods below in step with the battle log; each plays the matching
## animation plus V10 effects (hit sparks, damage numbers, level-up burst).

const HERO_X := -2.4
const ENEMY_X := 2.4
const LUNGE := 1.0

var _hero: CharacterModel
var _enemy: CreatureModel
var _rng := RandomNumberGenerator.new()


func setup(character_id: String, enemy: EnemyData) -> void:
	_rng.seed = 51
	_build_world()
	_hero = CharacterModel.new()
	_hero.character_id = character_id
	_hero.position = Vector3(HERO_X, 0, 0)
	_hero.rotation.y = PI / 2.0
	_hero.scale = Vector3.ONE * 0.85
	add_child(_hero)
	_enemy = CreatureModel.new()
	_enemy.kind = enemy.model
	_enemy.position = Vector3(ENEMY_X, 0, 0)
	_enemy.rotation.y = -PI / 2.0
	add_child(_enemy)


func hero_attack() -> void:
	_hero.play("1H_Melee_Attack_Chop")
	_lunge(_hero, Vector3(HERO_X, 0, 0), Vector3(LUNGE, 0, 0))


func enemy_attack() -> void:
	_enemy.attack()


func enemy_hit(damage: int) -> void:
	_enemy.hit()
	var at := Vector3(ENEMY_X, 1.1, 0)
	Vfx.hit_spark(self, at)
	Vfx.damage_number(self, at + Vector3(0, 0.8, 0), "-%d" % damage)


func hero_hit(damage: int) -> void:
	_hero.play("Hit_A")
	var at := Vector3(HERO_X, 1.1, 0)
	Vfx.hit_spark(self, at, Color(1.0, 0.45, 0.35))
	Vfx.damage_number(self, at + Vector3(0, 0.8, 0), "-%d" % damage, Color(1.0, 0.35, 0.3))


func enemy_die() -> void:
	_enemy.die()


func hero_die() -> void:
	_hero.play("Death_A")


func victory(level_ups: int) -> void:
	_hero.play("Cheer")
	if level_ups > 0:
		Vfx.level_up(self, Vector3(HERO_X, 0, 0))


func _lunge(node: Node3D, home: Vector3, offset: Vector3) -> void:
	var tween := create_tween()
	tween.tween_property(node, "position", home + offset, 0.16).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", home, 0.3).set_ease(Tween.EASE_IN_OUT).set_delay(0.12)


## Clearing: mossy ground disc, a ring of trees behind, rocks, warm light.
func _build_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.32, 0.45, 0.4)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.8, 0.7)
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.4, 0.52, 0.45)
	environment.fog_density = 0.03
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -35, 0)
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.4, 7.2)
	camera.fov = 42.0
	add_child(camera)
	camera.look_at(Vector3(0, 1.0, 0))
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.3, 0.46, 0.24)
	ground_mat.roughness = 1.0
	var disc := CylinderMesh.new()
	disc.top_radius = 14.0
	disc.bottom_radius = 14.0
	disc.height = 0.1
	disc.radial_segments = 40
	var ground := MeshInstance3D.new()
	ground.mesh = disc
	ground.material_override = ground_mat
	ground.position.y = -0.05
	add_child(ground)
	var dirt := StandardMaterial3D.new()
	dirt.albedo_color = Color(0.46, 0.36, 0.24)
	var patch := CylinderMesh.new()
	patch.top_radius = 4.2
	patch.bottom_radius = 4.2
	patch.height = 0.02
	patch.radial_segments = 32
	var dirt_node := MeshInstance3D.new()
	dirt_node.mesh = patch
	dirt_node.material_override = dirt
	dirt_node.scale = Vector3(1.4, 1.0, 0.8)
	dirt_node.position.y = 0.01
	add_child(dirt_node)
	var body := StaticBody3D.new()
	add_child(body)
	var factory := TreeFactory.new()
	for i in 18:
		var a := PI + PI * (i + 0.5) / 18.0 + _rng.randf_range(-0.05, 0.05)
		var at := Vector3(cos(a) * _rng.randf_range(7.5, 10.0), 0, sin(a) * _rng.randf_range(5.5, 8.0) - 1.0)
		if _rng.randf() < 0.55:
			factory.pine(self, body, at, _rng.randf_range(1.0, 1.4), _rng)
		else:
			factory.round_tree(self, body, at, _rng.randf_range(0.9, 1.3), _rng)
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color(0.5, 0.5, 0.53)
	for spec in [[Vector3(-5.2, 0.15, 1.6), 0.5], [Vector3(5.6, 0.15, 1.2), 0.6], [Vector3(4.8, 0.1, -2.6), 0.4]]:
		var stone := SphereMesh.new()
		stone.radius = spec[1]
		stone.height = spec[1] * 1.3
		stone.radial_segments = 7
		stone.rings = 4
		var stone_node := MeshInstance3D.new()
		stone_node.mesh = stone
		stone_node.material_override = rock
		stone_node.position = spec[0]
		add_child(stone_node)
