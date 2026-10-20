extends Node3D
## Blackwood Forest as a real 3D map (roadmap V8). Same game logic as before
## (MapManager nodes, unlock rules, treasure, boss) — but each node is a spot
## in a forest clearing with the actual monster / chest standing on it.
## Hover a spot to see its card; click it to fight (or open the chest).
## Locked spots sit in grey mist with a lock sign; beaten monsters leave a
## marker stone. The hero waits at the trail entrance.

const RING_RADIUS := 2.4
## Trees stay outside this ellipse (x, z radii around CLEARING_CENTER) so the
## clearing, spots and hero are never hidden; the rim is a dense forest wall.
const CLEARING_CENTER := Vector3(0.5, 0, -3.0)
const CLEARING := Vector2(19.0, 15.5)
## Monsters on the map are drawn a bit larger than life so they read at this zoom.
const MODEL_SCALE := 1.6
const PICK_LAYER := 2
const SEED := 3301

## Spot positions for each MapManager node id (world x, z).
const SPOTS := {
	"wolf": Vector3(-9.0, 0, -2.0),
	"boar": Vector3(1.5, 0, -6.5),
	"treasure": Vector3(10.0, 0, 1.0),
	"alpha": Vector3(-3.0, 0, -15.5),
}
const ENTRANCE := Vector3(1.0, 0, 9.5)
## Dirt trails: entrance to each first-tier spot, then wolf + boar to the boss.
const TRAILS := [["entrance", "wolf"], ["entrance", "boar"], ["entrance", "treasure"], ["wolf", "alpha"], ["boar", "alpha"]]

const GROUND := [Color(0.22, 0.38, 0.18), Color(0.31, 0.47, 0.22)]
const DIRT := Color(0.47, 0.36, 0.24)
const RING_IDLE := Color(0.95, 0.8, 0.45)
const RING_LOCKED := Color(0.55, 0.55, 0.6)
const RING_DONE := Color(0.5, 0.85, 0.55)
const MUSHROOM := [Color(0.55, 0.85, 1.0), Color(0.85, 0.6, 1.0), Color(1.0, 0.7, 0.45)]

@onready var camera: Camera3D = $Camera3D
@onready var hud: CanvasLayer = $Hud

## node id -> {"node": Dictionary, "root": Node3D, "ring": MeshInstance3D, "ring_mat": StandardMaterial3D, "model": Node3D}
var _spots := {}
var _hero: CharacterModel
var _hover := ""
var _selected := ""
var _rng := RandomNumberGenerator.new()
var _time := 0.0

var _card: PanelContainer
var _card_title: Label
var _card_body: Label
var _card_hint: Label
var _confirm: PanelContainer
var _confirm_title: Label
var _confirm_body: Label
var _confirm_go: Button
var _stats: Label
var _potion: Button
var _banner: Label
var _toast: Label
var _toast_time := 0.0


func _ready() -> void:
	_rng.seed = SEED
	_build_ground()
	for trail in TRAILS:
		_trail(_spot_pos(trail[0]), _spot_pos(trail[1]))
	_build_forest()
	_build_spots()
	_hero = CharacterModel.new()
	_hero.character_id = GameManager.player_data.character_id
	_hero.position = ENTRANCE
	_hero.rotation.y = PI
	_hero.scale = Vector3.ONE * 0.9
	add_child(_hero)
	_build_hud()
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	for id in _spots:
		var spot: Dictionary = _spots[id]
		var target := 1.12 if id == _hover else 1.0
		spot.ring.scale = spot.ring.scale.lerp(Vector3(target, 1.0, target), minf(delta * 10.0, 1.0))
		spot.ring_mat.emission_energy_multiplier = 1.2 + (0.8 + sin(_time * 5.0) * 0.4 if id == _hover else 0.0)
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time / 0.5, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if _confirm.visible:
		return
	if event is InputEventMouseMotion:
		_set_hover(_pick(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id := _pick(event.position)
		if id != "":
			_select(id)


func _spot_pos(id: String) -> Vector3:
	return ENTRANCE if id == "entrance" else SPOTS[id]


## Which spot (if any) is under the mouse — ray against each spot's pick area.
func _pick(screen: Vector2) -> String:
	var from := camera.project_ray_origin(screen)
	var to := from + camera.project_ray_normal(screen) * 500.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 << (PICK_LAYER - 1))
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return String(hit.collider.get_meta("spot")) if hit else ""


# --- Interaction ---

func _set_hover(id: String) -> void:
	if id == _hover:
		return
	_hover = id
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if id != "" and _can_use(id) else Input.CURSOR_ARROW)
	_card.visible = id != ""
	if id == "":
		return
	var info := _describe(id)
	_card_title.text = info.title
	_card_body.text = info.body
	_card_hint.text = info.hint
	_card.reset_size()
	var screen := camera.unproject_position(SPOTS[id] + Vector3(0, 3.0, 0))
	var view := get_viewport().get_visible_rect().size
	_card.position = Vector2(clampf(screen.x - _card.size.x / 2.0, 20, view.x - _card.size.x - 20), clampf(screen.y - _card.size.y - 20, 110, view.y - _card.size.y - 140))


func _can_use(id: String) -> bool:
	var node: Dictionary = _spots[id].node
	if not MapManager.is_unlocked(node):
		return false
	if node.type == "treasure" or node.type == "boss":
		return not MapManager.is_completed(id)
	return true


func _describe(id: String) -> Dictionary:
	var node: Dictionary = _spots[id].node
	if not MapManager.is_unlocked(node):
		return {"title": "🔒 ???", "body": "Something big waits in the mist.", "hint": "Defeat the Forest Wolf and the Wild Boar to unlock"}
	if node.type == "treasure":
		if MapManager.is_completed(id):
			return {"title": "💰 Treasure Chest", "body": "Already opened.", "hint": ""}
		return {"title": "💰 Treasure Chest", "body": "+%d Gold   ·   +%d Power" % [node.gold, node.power], "hint": "Click to open"}
	var enemy: EnemyData = load(node.enemy)
	var title := ("👑 " if node.type == "boss" else "") + enemy.display_name
	var body := "%s\n❤️ HP %d    ⚔️ %d    💨 %d\nReward: %d gold · %d EXP" % [enemy.description, enemy.max_hp, enemy.power, enemy.speed, enemy.gold_reward, enemy.exp_reward]
	var hint := "Click to fight"
	if MapManager.is_completed(id):
		hint = "Defeated" if node.type == "boss" else "Defeated — click to fight again"
	return {"title": title, "body": body, "hint": hint}


func _select(id: String) -> void:
	if not _can_use(id):
		return
	var node: Dictionary = _spots[id].node
	if node.type == "treasure":
		_open_treasure(id)
		return
	_selected = id
	var enemy: EnemyData = load(node.enemy)
	_confirm_title.text = "Fight the %s?" % enemy.display_name
	var player := GameManager.player_data
	_confirm_body.text = "You:  ❤️ %d/%d   ⚔️ %d   💨 %d\nFoe:  ❤️ %d   ⚔️ %d   💨 %d\n%s" % [
		player.hp, player.max_hp, player.attack_power(), player.speed,
		enemy.max_hp, enemy.power, enemy.speed,
		"It is faster — it strikes first!" if enemy.speed > player.speed else "You are faster — you strike first."]
	_card.hide()
	_confirm.show()
	_set_hover("")


func _fight() -> void:
	var node: Dictionary = _spots[_selected].node
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	GameManager.start_combat(load(node.enemy), node.id)


func _open_treasure(id: String) -> void:
	var reward := MapManager.open_treasure(_spots[id].node)
	if reward.is_empty():
		return
	var chest: TreasureChest = _spots[id].model
	chest.open()
	Vfx.chest_sparkle(self, SPOTS[id] + Vector3(0, 0.7, 0))
	_show_toast("💰 +%d Gold   ⚔️ +%d Power" % [reward.gold, reward.power])
	_set_hover("")
	_refresh()


func _use_potion() -> void:
	if GameManager.player_data.use_potion():
		Vfx.heal_glow(self, ENTRANCE)
		_refresh()


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_time = 2.5


## Updates every spot's look and the HUD from MapManager / PlayerData.
func _refresh() -> void:
	for id in _spots:
		var spot: Dictionary = _spots[id]
		var node: Dictionary = spot.node
		var unlocked := MapManager.is_unlocked(node)
		var done := MapManager.is_completed(id)
		var color := RING_IDLE
		if not unlocked:
			color = RING_LOCKED
		elif done:
			color = RING_DONE
		spot.ring_mat.albedo_color = color
		spot.ring_mat.emission = color
		spot.root.get_node("Mist").visible = not unlocked
		spot.root.get_node("Lock").visible = not unlocked
		spot.root.get_node("Done").visible = done and node.type != "treasure"
		if spot.model is CreatureModel:
			# Common monsters respawn for more fights; the boss stays down.
			spot.model.visible = unlocked and not (done and node.type == "boss")
		if spot.model is TreasureChest and done:
			spot.model.open(true)
	var player := GameManager.player_data
	_stats.text = "Lv.%d   ❤️ %d/%d   ⚔️ %d   💨 %d   💰 %d" % [player.level, player.hp, player.max_hp, player.attack_power(), player.speed, player.gold]
	var potions := player.item_qty("small_potion")
	_potion.visible = potions > 0
	_potion.text = "🧪 Small Potion ×%d  (+30 HP)" % potions
	_potion.disabled = player.hp >= player.max_hp
	_banner.visible = MapManager.is_map_cleared()


# --- World building ---

func _build_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	var ramp := Gradient.new()
	ramp.set_color(0, GROUND[0])
	ramp.set_color(1, GROUND[1])
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.color_ramp = ramp
	texture.seamless = true
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 1.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE / 40.0
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = material
	add_child(ground)


func _trail(from: Vector3, to: Vector3) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = DIRT
	material.roughness = 1.0
	var steps := 10
	var normal := Vector3(to.z - from.z, 0, from.x - to.x).normalized()
	for i in steps:
		var t := (i + 0.5) / steps
		var at := from.lerp(to, t) + normal * sin(t * PI) * 1.2
		var disc := CylinderMesh.new()
		disc.top_radius = 1.25
		disc.bottom_radius = 1.25
		disc.height = 0.02
		disc.radial_segments = 16
		var patch := MeshInstance3D.new()
		patch.mesh = disc
		patch.material_override = material
		patch.position = at + Vector3(0, 0.01, 0)
		patch.scale = Vector3(1.0, 1.0, 1.25)
		patch.rotation.y = atan2(to.x - from.x, to.z - from.z)
		add_child(patch)


## Dense pines and leafy trees around the clearing, rocks, glowing mushrooms,
## fireflies. Keeps clear of the spots and trails.
func _build_forest() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var factory := TreeFactory.new()
	var placed: Array[Vector3] = []
	var tries := 0
	while placed.size() < 150 and tries < 6000:
		tries += 1
		var at := Vector3(_rng.randf_range(-40, 40), 0, _rng.randf_range(-36, 26))
		var rim := Vector2((at.x - CLEARING_CENTER.x) / CLEARING.x, (at.z - CLEARING_CENTER.z) / CLEARING.y).length()
		if rim < 1.0 or _near_paths(at, 4.2):
			continue
		var crowded := false
		for other in placed:
			if other.distance_to(at) < 3.2:
				crowded = true
				break
		if crowded:
			continue
		placed.append(at)
		if _rng.randf() < 0.6:
			factory.pine(self, body, at, _rng.randf_range(1.0, 1.6), _rng)
		else:
			factory.round_tree(self, body, at, _rng.randf_range(0.9, 1.4), _rng)
	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color(0.5, 0.5, 0.52)
	for i in 30:
		var at := Vector3(_rng.randf_range(-22, 22), 0, _rng.randf_range(-22, 14))
		if _near_paths(at, 2.8):
			continue
		var stone := SphereMesh.new()
		stone.radius = _rng.randf_range(0.3, 0.7)
		stone.height = stone.radius * 1.3
		stone.radial_segments = 7
		stone.rings = 4
		_mesh(stone, rock, at + Vector3(0, 0.1, 0))
	for i in 40:
		var at := Vector3(_rng.randf_range(-24, 24), 0, _rng.randf_range(-24, 16))
		if _near_paths(at, 2.6):
			continue
		_mushroom(at, MUSHROOM[_rng.randi() % MUSHROOM.size()])
	var fireflies := GPUParticles3D.new()
	fireflies.amount = 80
	fireflies.lifetime = 6.0
	fireflies.preprocess = 6.0
	fireflies.position = Vector3(0, 1.5, -4)
	fireflies.visibility_aabb = AABB(Vector3(-30, -3, -30), Vector3(60, 8, 60))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(22, 1.2, 16)
	process.spread = 180.0
	process.initial_velocity_min = 0.1
	process.initial_velocity_max = 0.4
	process.gravity = Vector3.ZERO
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 0.95, 0.5, 0))
	fade.add_point(0.5, Color(1, 0.95, 0.5, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 0.95, 0.5, 0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	fireflies.process_material = process
	var dot := SphereMesh.new()
	dot.radius = 0.05
	dot.height = 0.1
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.vertex_color_use_as_albedo = true
	glow.vertex_color_is_srgb = true
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dot.material = glow
	fireflies.draw_pass_1 = dot
	add_child(fireflies)


func _near_paths(at: Vector3, distance: float) -> bool:
	var flat := Vector2(at.x, at.z)
	for trail in TRAILS:
		var a := _spot_pos(trail[0])
		var b := _spot_pos(trail[1])
		if flat.distance_to(Geometry2D.get_closest_point_to_segment(flat, Vector2(a.x, a.z), Vector2(b.x, b.z))) < distance:
			return true
	for id in SPOTS:
		var offset := flat - Vector2(SPOTS[id].x, SPOTS[id].z)
		if offset.length() < distance + (3.0 if id == "alpha" else 1.5):
			return true
		# Nothing between a spot and the camera (which looks from +x +z).
		if offset.x + offset.y > 0.0 and offset.length() < 8.0:
			return true
	return flat.distance_to(Vector2(ENTRANCE.x, ENTRANCE.z)) < distance + 1.0


func _mushroom(at: Vector3, color: Color) -> void:
	var stem := StandardMaterial3D.new()
	stem.albedo_color = Color(0.92, 0.9, 0.84)
	var cap := StandardMaterial3D.new()
	cap.albedo_color = color
	cap.emission_enabled = true
	cap.emission = color
	cap.emission_energy_multiplier = 1.6
	for n in _rng.randi_range(1, 3):
		var offset := Vector3(_rng.randf_range(-0.25, 0.25), 0, _rng.randf_range(-0.25, 0.25))
		var h := _rng.randf_range(0.18, 0.35)
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.04
		cylinder.bottom_radius = 0.06
		cylinder.height = h
		_mesh(cylinder, stem, at + offset + Vector3(0, h / 2.0, 0))
		var dome := SphereMesh.new()
		dome.radius = 0.14
		dome.height = 0.14
		dome.is_hemisphere = true
		_mesh(dome, cap, at + offset + Vector3(0, h, 0))


## One spot per MapManager node: stone ring, glowing selection ring, the
## monster or chest, mist + lock sign for locked spots, a marker for beaten
## ones, and an Area3D for mouse picking.
func _build_spots() -> void:
	for node in MapManager.get_nodes():
		var id: String = node.id
		var root := Node3D.new()
		root.position = SPOTS[id]
		add_child(root)
		var radius := RING_RADIUS * (1.5 if node.type == "boss" else 1.0)
		var stone := StandardMaterial3D.new()
		stone.albedo_color = Color(0.58, 0.56, 0.52)
		for i in 10:
			var a := TAU * i / 10.0
			var block := BoxMesh.new()
			block.size = Vector3(0.5, 0.25, 0.35)
			var piece := _mesh(block, stone, Vector3(cos(a), 0.12, sin(a)) * (radius + 0.45), root)
			piece.rotation.y = -a
		var ring_mat := StandardMaterial3D.new()
		ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring_mat.albedo_color = RING_IDLE
		ring_mat.emission_enabled = true
		ring_mat.emission = RING_IDLE
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.12
		torus.outer_radius = radius
		torus.rings = 48
		var ring := _mesh(torus, ring_mat, Vector3(0, 0.05, 0), root)
		ring.scale.y = 0.2
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var model: Node3D
		if node.type == "treasure":
			model = TreasureChest.new()
		else:
			var creature := CreatureModel.new()
			creature.kind = load(node.enemy).model
			model = creature
		model.rotation.y = atan2(ENTRANCE.x - SPOTS[id].x, ENTRANCE.z - SPOTS[id].z)
		model.scale = Vector3.ONE * MODEL_SCALE
		root.add_child(model)
		var label := Label3D.new()
		label.text = ("👑 " if node.type == "boss" else "") + ("Treasure" if node.type == "treasure" else load(node.enemy).display_name)
		label.font_size = 48
		label.pixel_size = 0.012
		label.outline_size = 14
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position.y = 3.2 if node.type != "boss" else 4.4
		root.add_child(label)
		_build_mist(root, radius)
		var lock := Label3D.new()
		lock.name = "Lock"
		lock.text = "🔒"
		lock.font_size = 96
		lock.pixel_size = 0.014
		lock.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lock.position.y = 1.4
		root.add_child(lock)
		var done := Label3D.new()
		done.name = "Done"
		done.text = "✔ Defeated"
		done.font_size = 40
		done.pixel_size = 0.012
		done.outline_size = 12
		done.modulate = RING_DONE.lightened(0.3)
		done.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		done.position.y = 2.0 if node.type != "boss" else 2.8
		root.add_child(done)
		var area := Area3D.new()
		area.collision_layer = 1 << (PICK_LAYER - 1)
		area.collision_mask = 0
		area.set_meta("spot", id)
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = radius + 0.4
		cylinder.height = 3.0
		shape.shape = cylinder
		shape.position.y = 1.5
		area.add_child(shape)
		root.add_child(area)
		_spots[id] = {"node": node, "root": root, "ring": ring, "ring_mat": ring_mat, "model": model}


func _build_mist(root: Node3D, radius: float) -> void:
	var mist := GPUParticles3D.new()
	mist.name = "Mist"
	mist.amount = 40
	mist.lifetime = 4.0
	mist.preprocess = 4.0
	mist.position.y = 0.6
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = radius
	process.spread = 180.0
	process.initial_velocity_min = 0.05
	process.initial_velocity_max = 0.2
	process.gravity = Vector3(0, 0.05, 0)
	process.scale_min = 1.0
	process.scale_max = 2.0
	var fade := Gradient.new()
	fade.set_color(0, Color(0.62, 0.6, 0.72, 0))
	fade.add_point(0.5, Color(0.62, 0.6, 0.72, 0.32))
	fade.set_color(fade.get_point_count() - 1, Color(0.62, 0.6, 0.72, 0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	process.color_ramp = ramp
	mist.process_material = process
	var puff := SphereMesh.new()
	puff.radius = 0.7
	puff.height = 1.4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff.material = material
	mist.draw_pass_1 = puff
	root.add_child(mist)


func _mesh(mesh: Mesh, material: Material, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	(parent if parent else self).add_child(instance)
	return instance


# --- HUD ---

func _label(text: String, font_size: int, color := Color(0.965, 0.933, 0.863)) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _build_hud() -> void:
	var top := PanelContainer.new()
	top.anchor_left = 0.5
	top.anchor_right = 0.5
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.offset_top = 18
	hud.add_child(top)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 2)
	top.add_child(top_box)
	var title := _label("🌲 Blackwood Forest", 36, Color(0.95, 0.78, 0.42))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(title)
	_stats = _label("", 20)
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(_stats)
	var hint := _label("Click a monster to fight · click the chest to open it", 16, Color(0.79, 0.73, 0.63))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(hint)

	var bottom := HBoxContainer.new()
	bottom.anchor_left = 0.5
	bottom.anchor_right = 0.5
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_bottom = -26
	bottom.add_theme_constant_override("separation", 16)
	hud.add_child(bottom)
	_potion = _button("", _use_potion)
	bottom.add_child(_potion)
	bottom.add_child(_button("🗺️  World Map", GameManager.goto_world_map))

	_banner = _label("🏆 Blackwood cleared! New lands await in a future update.", 28, Color(0.95, 0.78, 0.42))
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.anchor_top = 1.0
	_banner.anchor_bottom = 1.0
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.offset_top = -150
	hud.add_child(_banner)

	_toast = _label("", 34, Color(1.0, 0.86, 0.45))
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.anchor_top = 0.5
	_toast.anchor_bottom = 0.5
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = -260
	_toast.modulate.a = 0.0
	hud.add_child(_toast)

	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.custom_minimum_size = Vector2(380, 0)
	hud.add_child(_card)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 4)
	_card.add_child(card_box)
	_card_title = _label("", 28, Color(0.95, 0.78, 0.42))
	card_box.add_child(_card_title)
	_card_body = _label("", 19)
	card_box.add_child(_card_body)
	_card_hint = _label("", 17, Color(0.79, 0.73, 0.63))
	card_box.add_child(_card_hint)
	_card.hide()

	_confirm = PanelContainer.new()
	_confirm.anchor_left = 0.5
	_confirm.anchor_right = 0.5
	_confirm.anchor_top = 0.5
	_confirm.anchor_bottom = 0.5
	_confirm.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_confirm.grow_vertical = Control.GROW_DIRECTION_BOTH
	_confirm.custom_minimum_size = Vector2(560, 0)
	hud.add_child(_confirm)
	var confirm_box := VBoxContainer.new()
	confirm_box.add_theme_constant_override("separation", 12)
	_confirm.add_child(confirm_box)
	_confirm_title = _label("", 32, Color(0.95, 0.78, 0.42))
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_box.add_child(_confirm_title)
	_confirm_body = _label("", 21)
	_confirm_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_box.add_child(_confirm_body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	confirm_box.add_child(row)
	_confirm_go = _button("⚔️  Fight!", _fight)
	row.add_child(_confirm_go)
	row.add_child(_button("Not now", func(): _confirm.hide()))
	_confirm.hide()


func _button(text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 58)
	button.add_theme_font_size_override("font_size", 22)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_press)
	return button
