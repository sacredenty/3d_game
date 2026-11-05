extends Node3D

const PLAYER_SCENE := preload("res://scripts/three_d_player.gd")
const ENEMY_SCRIPT := preload("res://scripts/three_d_enemy.gd")
const BATTLE_SCENE := preload("res://scenes/battle.tscn")
const SAVE_PATH := "user://three_d_progress.json"
const PLAYER_MAX_HP := 100
const STARTING_MP := 30
const SHOP_ITEMS := ["Potion", "Iron Sword", "Oak Staff", "Leather Armor", "Chain Vest", "Leather Cap", "Iron Helm", "Bracers", "Knight's Gauntlets", "Work Gloves", "Silk Gloves", "Traveler's Trousers", "Iron Greaves", "Trail Boots", "Swift Boots"]
const EQUIPMENT_SLOTS := ["weapon", "armor", "head", "arms", "hands", "legs", "feet"]
const ITEM_CATALOG := {
	"Potion": {"type": "consumable", "price": 20, "sell_price": 10, "description": "Restores HP in battle."},
	"Traveler's Blade": {"type": "weapon", "attack": 0, "magic": 0, "defense": 0, "price": 0, "sell_price": 0, "description": "A reliable starting weapon."},
	"Wanderer's Coat": {"type": "armor", "attack": 0, "magic": 0, "defense": 0, "price": 0, "sell_price": 0, "description": "Light travel clothes."},
	"Iron Sword": {"type": "weapon", "attack": 7, "magic": 0, "defense": 0, "price": 90, "sell_price": 45, "description": "+7 physical damage."},
	"Oak Staff": {"type": "weapon", "attack": 4, "magic": 8, "defense": 0, "price": 100, "sell_price": 50, "description": "+4 physical, +8 Ember damage."},
	"Leather Armor": {"type": "armor", "attack": 0, "magic": 0, "defense": 3, "price": 80, "sell_price": 40, "description": "Reduces each hit by 3."},
	"Chain Vest": {"type": "armor", "attack": 0, "magic": 0, "defense": 5, "price": 150, "sell_price": 75, "description": "Reduces each hit by 5."},
	"Leather Cap": {"type": "head", "attack": 0, "magic": 0, "defense": 1, "price": 35, "sell_price": 17, "description": "A simple protective cap."},
	"Iron Helm": {"type": "head", "attack": 0, "magic": 0, "defense": 3, "price": 85, "sell_price": 42, "description": "A sturdy helmet."},
	"Bracers": {"type": "arms", "attack": 1, "magic": 0, "defense": 1, "price": 45, "sell_price": 22, "description": "+1 physical damage, +1 defense."},
	"Knight's Gauntlets": {"type": "arms", "attack": 2, "magic": 0, "defense": 2, "price": 100, "sell_price": 50, "description": "+2 physical damage, +2 defense."},
	"Work Gloves": {"type": "hands", "attack": 1, "magic": 0, "defense": 0, "price": 30, "sell_price": 15, "description": "+1 physical damage."},
	"Silk Gloves": {"type": "hands", "attack": 0, "magic": 3, "defense": 0, "price": 65, "sell_price": 32, "description": "+3 Ember damage."},
	"Traveler's Trousers": {"type": "legs", "attack": 0, "magic": 0, "defense": 1, "price": 40, "sell_price": 20, "description": "Comfortable traveling gear."},
	"Iron Greaves": {"type": "legs", "attack": 0, "magic": 0, "defense": 3, "price": 90, "sell_price": 45, "description": "Heavy leg protection."},
	"Trail Boots": {"type": "feet", "attack": 0, "magic": 0, "defense": 1, "price": 35, "sell_price": 17, "description": "Reliable boots for rough paths."},
	"Swift Boots": {"type": "feet", "attack": 1, "magic": 0, "defense": 1, "price": 70, "sell_price": 35, "description": "+1 physical damage, +1 defense."}
}

class CampaignMap extends Control:
	var game: Node

	func _draw() -> void:
		var map_rect := Rect2(Vector2(12, 12), size - Vector2(24, 24))
		draw_rect(map_rect, Color("536f49"), true)
		draw_rect(map_rect, Color("c5b07d"), false, 3.0)
		var cave_origin := _map_position(Vector3(-16, 0, 3), map_rect)
		var cave_end := _map_position(Vector3(-6, 0, 17), map_rect)
		var cave_rect := Rect2(cave_origin, cave_end - cave_origin)
		draw_rect(cave_rect, Color("323735"), true)
		draw_polyline(PackedVector2Array([
			_map_position(Vector3(0, 0, -17), map_rect),
			_map_position(Vector3(0, 0, -13), map_rect),
			_map_position(Vector3(0, 0, 0), map_rect),
			_map_position(Vector3(7, 0, 0), map_rect),
			_map_position(Vector3(10, 0, 7), map_rect),
			_map_position(Vector3(14, 0, 11), map_rect),
			_map_position(Vector3(-13, 0, 5), map_rect)
		]), Color("c5a577"), 5.0, true)
		for marker in game.call("_get_campaign_map_markers"):
			var point: Vector2 = _map_position(marker["position"], map_rect)
			var marker_color: Color = marker["color"]
			draw_circle(point, 6.0 if marker["status"] == "active" else 4.0, marker_color)
			draw_string(ThemeDB.fallback_font, point + Vector2(7, 4), str(marker["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fff0d0"))
		var player: Node3D = game.get("player")
		var player_point := _map_position(player.global_position, map_rect)
		draw_circle(player_point, 7.0, Color("75d8f0"))
		draw_arc(player_point, 10.0, 0.0, TAU, 24, Color("152228"), 2.0)
		draw_string(ThemeDB.fallback_font, player_point + Vector2(8, -7), "You", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b7efff"))

	func _map_position(world_position: Vector3, map_rect: Rect2) -> Vector2:
		var normalized := Vector2((world_position.x + 21.0) / 42.0, (world_position.z + 21.0) / 42.0)
		return map_rect.position + Vector2(normalized.x * map_rect.size.x, normalized.y * map_rect.size.y)

var player: CharacterBody3D
var camera: Camera3D
var objective_label: Label
var status_label: Label
var inventory_label: Label
var shrine: Node3D
var npc: Node3D
var merchant: Node3D
var village_hut_a: Node3D
var village_hut_b: Node3D
var crystals: Array = []
var enemies: Array = []
var crystals_needed := 3
var defeated_enemies := 0
var total_enemies := 3
var quest_started := false
var quest_finished := false
var status_message: String = ""
var status_message_timer: float = 0.0
var health_bar: ProgressBar
var defeated_enemy_ids: Array[int] = []
var collected_crystal_ids: Array[int] = []
var save_timer: float = 0.0
var saved_player_position := Vector3.ZERO
var saved_player_health := 100.0
var saved_potions := 2
var saved_gems := 0
var saved_coins := 0
var quest_step := 0
var hunter_contract_stage := 0
var northern_tracks_found := false
var southern_tracks_found := false
var salve_collected := false
var cache_opened := false
var waystone_discovered := false
var cave_guardian_defeated := false
var cave_treasure_claimed := false
var in_cave := false
var encounter_started := false
var active_encounter := ""
var battle_instance: Node
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var dialogue_active := false
var player_hp := PLAYER_MAX_HP
var player_mp := STARTING_MP
var player_level := 1
var player_experience := 0
var hero_name := "Adventurer"
var hero_class := "Warrior"
var hero_vitality := 13
var hero_strength := 10
var hero_spirit := 12
var hero_agility := 10
var gold := 0
var equipment_inventory: Array[String] = ["Traveler's Blade", "Wanderer's Coat", "Traveler's Trousers", "Trail Boots"]
var equipped_slots: Dictionary = {
	"weapon": "Traveler's Blade", "armor": "Wanderer's Coat", "head": "",
	"arms": "", "hands": "", "legs": "Traveler's Trousers", "feet": "Trail Boots"
}
var progress_save_path := SAVE_PATH
var startup_load_only := false
var initial_mode := "new_game"
var prompt_label: Label
var dialogue_panel: PanelContainer
var dialogue_label: Label
var dialogue_hint: Label
var quest_objects: Dictionary = {}
var shop_panel: CanvasLayer
var inventory_panel: CanvasLayer
var map_panel: CanvasLayer
var slot_panel: CanvasLayer
var title_panel: CanvasLayer
var save_slot_action := "load"
var hero_name_edit: LineEdit
var hero_class_option: OptionButton
var hero_stats_label: Label
var map_canvas: CampaignMap
var map_page: Control
var journal_page: Control
var map_tab_button: Button
var journal_tab_button: Button

func _ready() -> void:
	if initial_mode == "continue":
		_load_progress(progress_save_path)
	AudioDirector.play_greenvale_theme()
	_build_environment()
	_build_village()
	_build_player()
	_build_campaign_markers()
	_build_npc()
	_build_camera()
	_build_hud()
	_update_objective()
	if initial_mode == "new_game":
		_show_hero_creation()
	elif initial_mode == "load_slots":
		_show_save_slots()

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var world_environment := Environment.new()
	world_environment.background_mode = Environment.BG_SKY
	world_environment.sky = Sky.new()
	world_environment.sky.sky_material = ProceduralSkyMaterial.new()
	world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_environment.ambient_light_color = Color(0.58, 0.68, 0.76)
	world_environment.ambient_light_energy = 0.65
	world_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = world_environment
	add_child(environment_node)

	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(42.0, 42.0)
	ground.mesh = ground_mesh
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.31, 0.48, 0.25)
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	light.light_color = Color(1.0, 0.91, 0.75)
	light.light_energy = 1.8
	light.shadow_enabled = true
	add_child(light)

	var floor_body := StaticBody3D.new()
	floor_body.name = "GroundCollision"
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(42.0, 1.0, 42.0)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.5
	floor_body.add_child(floor_shape)
	add_child(floor_body)

	var path := MeshInstance3D.new()
	var path_mesh := BoxMesh.new()
	path_mesh.size = Vector3(3.2, 0.04, 31.0)
	path.mesh = path_mesh
	var path_material := StandardMaterial3D.new()
	path_material.albedo_color = Color(0.65, 0.51, 0.32)
	path_material.roughness = 1.0
	path.material_override = path_material
	path.position = Vector3(0.0, 0.03, 1.0)
	add_child(path)

	var tree_positions := [
		Vector3(-8.0, 0.0, -8.0), Vector3(-11.0, 0.0, 3.0), Vector3(-2.0, 0.0, 10.0),
		Vector3(8.5, 0.0, -7.0), Vector3(10.5, 0.0, 5.0), Vector3(3.5, 0.0, 12.5),
		Vector3(-12.5, 0.0, -2.0), Vector3(12.5, 0.0, -3.0)
	]

	for offset in tree_positions:
		var tree_body := StaticBody3D.new()
		tree_body.position = offset
		var trunk_collision := CollisionShape3D.new()
		var trunk_shape := CylinderShape3D.new()
		trunk_shape.radius = 0.55
		trunk_shape.height = 2.8
		trunk_collision.shape = trunk_shape
		trunk_collision.position.y = 1.4
		tree_body.add_child(trunk_collision)
		add_child(tree_body)

		var trunk := MeshInstance3D.new()
		var trunk_mesh := BoxMesh.new()
		trunk_mesh.size = Vector3(0.7, 2.5, 0.7)
		trunk.mesh = trunk_mesh
		trunk.position = offset + Vector3(0.0, 1.25, 0.0)
		var trunk_material := StandardMaterial3D.new()
		trunk_material.albedo_color = Color(0.45, 0.28, 0.12)
		trunk.material_override = trunk_material
		add_child(trunk)

		var leaves := MeshInstance3D.new()
		var leaves_mesh := SphereMesh.new()
		leaves_mesh.radius = 1.5
		leaves_mesh.height = 2.9
		leaves.mesh = leaves_mesh
		leaves.position = offset + Vector3(0.0, 3.7, 0.0)
		var leaves_material := StandardMaterial3D.new()
		leaves_material.albedo_color = Color(0.14, 0.52, 0.22)
		leaves.material_override = leaves_material
		add_child(leaves)

	var wall_positions := [
		Vector3(0.0, 1.0, -20.5), Vector3(0.0, 1.0, 20.5),
		Vector3(-20.5, 1.0, 0.0), Vector3(20.5, 1.0, 0.0)
	]
	for index in range(wall_positions.size()):
		var offset: Vector3 = wall_positions[index]
		var wall := MeshInstance3D.new()
		var wall_mesh := BoxMesh.new()
		wall_mesh.size = Vector3(42.0, 2.0, 1.2)
		if index >= 2:
			wall_mesh.size = Vector3(1.2, 2.0, 42.0)
		wall.mesh = wall_mesh
		wall.position = offset
		var wall_material := StandardMaterial3D.new()
		wall_material.albedo_color = Color(0.38, 0.28, 0.18)
		wall.material_override = wall_material
		add_child(wall)

		var wall_body := StaticBody3D.new()
		wall_body.position = offset
		var wall_collision := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		wall_box.size = wall_mesh.size
		wall_collision.shape = wall_box
		wall_body.add_child(wall_collision)
		add_child(wall_body)

func _build_village() -> void:
	var house_material := StandardMaterial3D.new()
	house_material.albedo_color = Color(0.64, 0.48, 0.29)

	village_hut_a = Node3D.new()
	village_hut_a.position = Vector3(-12.0, 0.0, -15.0)
	var hut_a_base := MeshInstance3D.new()
	var hut_a_mesh := BoxMesh.new()
	hut_a_mesh.size = Vector3(4.0, 2.5, 4.0)
	hut_a_base.mesh = hut_a_mesh
	hut_a_base.material_override = house_material
	hut_a_base.position = Vector3(0.0, 1.25, 0.0)
	village_hut_a.add_child(hut_a_base)
	_add_box_collider(village_hut_a, Vector3(4.2, 2.7, 4.2), Vector3(0.0, 1.25, 0.0))
	add_child(village_hut_a)

	village_hut_b = Node3D.new()
	village_hut_b.position = Vector3(12.0, 0.0, -15.0)
	var hut_b_base := MeshInstance3D.new()
	var hut_b_mesh := BoxMesh.new()
	hut_b_mesh.size = Vector3(4.0, 2.5, 4.0)
	hut_b_base.mesh = hut_b_mesh
	hut_b_base.material_override = house_material
	hut_b_base.position = Vector3(0.0, 1.25, 0.0)
	village_hut_b.add_child(hut_b_base)
	_add_box_collider(village_hut_b, Vector3(4.2, 2.7, 4.2), Vector3(0.0, 1.25, 0.0))
	add_child(village_hut_b)

	var campfire := Node3D.new()
	campfire.position = Vector3(0.0, 0.0, -15.0)
	var log1 := MeshInstance3D.new(); var log_mesh := BoxMesh.new(); log_mesh.size = Vector3(0.6,0.2,1.8); log1.mesh = log_mesh; log1.position = Vector3(0.0,0.25,0.0); log1.material_override = StandardMaterial3D.new(); log1.material_override.albedo_color = Color(0.47,0.35,0.18); campfire.add_child(log1)
	var log2 := MeshInstance3D.new(); var log_mesh2 := BoxMesh.new(); log_mesh2.size = Vector3(1.8,0.2,0.6); log2.mesh = log_mesh2; log2.position = Vector3(0.0,0.25,0.0); log2.material_override = log1.material_override; campfire.add_child(log2)
	var flame := OmniLight3D.new(); flame.position = Vector3(0.0,1.0,0.0); flame.light_energy = 0.9; flame.omni_range = 4.0; campfire.add_child(flame)
	add_child(campfire)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0.0, 1.0, 0.0)
	player.collision_layer = 1
	player.collision_mask = 3
	player.set_script(PLAYER_SCENE)
	player.max_health = max_hp()
	player.health = player_hp
	player.potions = saved_potions
	player.gems = saved_gems
	player.coins = saved_coins
	if saved_player_position != Vector3.ZERO:
		player.position = saved_player_position

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 1.2
	collision.shape = capsule
	collision.position.y = -0.4
	player.add_child(collision)

	var tunic := StandardMaterial3D.new()
	tunic.albedo_color = Color(0.78, 0.25, 0.12)
	var trousers := StandardMaterial3D.new()
	trousers.albedo_color = Color(0.13, 0.2, 0.35)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.94, 0.68, 0.45)
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.32, 0.18, 0.1)

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.34
	torso_mesh.height = 0.95
	torso.mesh = torso_mesh
	torso.material_override = tunic
	torso.position = Vector3(0.0, 0.0, 0.0)
	player.add_child(torso)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.27
	head_mesh.height = 0.54
	head.mesh = head_mesh
	head.material_override = skin
	head.position = Vector3(0.0, 0.68, 0.0)
	player.add_child(head)

	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.28
	hair_mesh.height = 0.27
	hair.mesh = hair_mesh
	hair.material_override = leather
	hair.position = Vector3(0.0, 0.88, 0.0)
	player.add_child(hair)

	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.12
		arm_mesh.height = 0.7
		arm.mesh = arm_mesh
		arm.material_override = tunic
		arm.position = Vector3(side * 0.43, -0.08, 0.0)
		arm.rotation.z = side * -0.18
		player.add_child(arm)

		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.15
		leg_mesh.height = 0.66
		leg.mesh = leg_mesh
		leg.material_override = trousers
		leg.position = Vector3(side * 0.19, -0.55, 0.0)
		player.add_child(leg)

		var boot := MeshInstance3D.new()
		var boot_mesh := BoxMesh.new()
		boot_mesh.size = Vector3(0.32, 0.18, 0.44)
		boot.mesh = boot_mesh
		boot.material_override = leather
		boot.position = Vector3(side * 0.19, -0.83, -0.07)
		player.add_child(boot)

	for child in player.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(player)

func _build_enemies() -> void:
	var enemy_positions := [
		Vector3(10.5, 1.0, -9.0),
		Vector3(-9.0, 1.0, 9.5),
		Vector3(13.5, 1.0, 8.5)
	]

	for index in range(enemy_positions.size()):
		if defeated_enemy_ids.has(index):
			defeated_enemies += 1
			continue
		var enemy := CharacterBody3D.new()
		enemy.name = "Enemy"
		enemy.position = enemy_positions[index]
		enemy.set_script(ENEMY_SCRIPT)
		enemy.enemy_id = index
		enemy.collision_layer = 2
		enemy.collision_mask = 1
		enemy.connect("defeated", _on_enemy_defeated)
		var enemy_collision := CollisionShape3D.new()
		var enemy_capsule := CapsuleShape3D.new()
		enemy_capsule.radius = 0.45
		enemy_capsule.height = 1.2
		enemy_collision.shape = enemy_capsule
		enemy_collision.position.y = -0.4
		enemy.add_child(enemy_collision)
		enemies.append(enemy)
		add_child(enemy)

func _build_collectibles() -> void:
	var crystal_positions := [
		Vector3(-12.0, 1.0, -10.0),
		Vector3(12.0, 1.0, -4.5),
		Vector3(-3.0, 1.0, 12.0)
	]

	for index in range(crystal_positions.size()):
		if collected_crystal_ids.has(index):
			continue
		var crystal := MeshInstance3D.new()
		var crystal_mesh := PrismMesh.new()
		crystal_mesh.size = Vector3(0.8, 1.6, 0.8)
		crystal.mesh = crystal_mesh
		var crystal_material := StandardMaterial3D.new()
		crystal_material.albedo_color = Color(0.2, 0.9, 1.0)
		crystal.material_override = crystal_material
		crystal.position = crystal_positions[index]
		crystal.set_meta("crystal_id", index)
		crystal.add_to_group("collectible")
		crystals.append(crystal)
		add_child(crystal)

func _build_shrine() -> void:
	shrine = Node3D.new()
	shrine.position = Vector3(-13.5, 0.0, 12.0)

	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(2.4, 1.5, 2.4)
	base.mesh = base_mesh
	var base_material := StandardMaterial3D.new()
	base_material.albedo_color = Color(0.35, 0.32, 0.5)
	base.material_override = base_material
	base.position = Vector3(0.0, 0.75, 0.0)
	shrine.add_child(base)

	var gem := MeshInstance3D.new()
	var gem_mesh := SphereMesh.new()
	gem_mesh.radius = 0.75
	gem_mesh.height = 1.5
	gem.mesh = gem_mesh
	var gem_material := StandardMaterial3D.new()
	gem_material.albedo_color = Color(0.84, 0.74, 0.25)
	gem.material_override = gem_material
	gem.position = Vector3(0.0, 2.0, 0.0)
	shrine.add_child(gem)

	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 3.0, 0.0)
	glow.light_energy = 0.6
	glow.omni_range = 8.0
	shrine.add_child(glow)
	shrine.set_meta("glow", glow)
	add_child(shrine)

func _build_npc() -> void:
	npc = Node3D.new()
	npc.position = Vector3(-7.0, 0.0, -13.0)
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.5
	body_mesh.height = 1.3
	body.mesh = body_mesh
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.25, 0.52, 0.9)
	body.material_override = body_material
	body.position.y = 0.65
	npc.add_child(body)
	var npc_body := StaticBody3D.new()
	var npc_collision := CollisionShape3D.new()
	var npc_capsule := CapsuleShape3D.new()
	npc_capsule.radius = 0.5
	npc_capsule.height = 1.3
	npc_collision.shape = npc_capsule
	npc_collision.position.y = 0.65
	npc_body.add_child(npc_collision)
	npc.add_child(npc_body)
	_add_world_name(npc, "Mira")
	add_child(npc)

	merchant = Node3D.new()
	merchant.position = Vector3(7.0, 0.0, -13.0)
	var merchant_body := MeshInstance3D.new()
	var merchant_mesh := CapsuleMesh.new()
	merchant_mesh.radius = 0.5
	merchant_mesh.height = 1.3
	merchant_body.mesh = merchant_mesh
	var merchant_material := StandardMaterial3D.new()
	merchant_material.albedo_color = Color(0.82, 0.65, 0.25)
	merchant_body.position.y = 0.65
	merchant_body.material_override = merchant_material
	merchant.add_child(merchant_body)
	var merchant_collision_body := StaticBody3D.new()
	var merchant_collision := CollisionShape3D.new()
	var merchant_capsule := CapsuleShape3D.new()
	merchant_capsule.radius = 0.5
	merchant_capsule.height = 1.3
	merchant_collision.shape = merchant_capsule
	merchant_collision.position.y = 0.65
	merchant_collision_body.add_child(merchant_collision)
	merchant.add_child(merchant_collision_body)
	_add_world_name(merchant, "Rowan")
	add_child(merchant)

func _build_campaign_markers() -> void:
	_add_quest_marker("northern_tracks", Vector3(5.0, 0.1, -6.0), "Broken Branches", Color(0.7, 0.48, 0.26))
	_add_quest_marker("southern_tracks", Vector3(6.0, 0.1, 6.0), "Wolf Tracks", Color(0.56, 0.39, 0.25))
	_add_quest_marker("scorch_marks", Vector3(13.0, 0.1, 0.0), "Scorch Marks", Color(0.9, 0.32, 0.12))
	_add_quest_marker("stone_tracks", Vector3(11.0, 0.1, 10.0), "Stone Tracks", Color(0.67, 0.69, 0.72))
	_add_quest_marker("salve", Vector3(2.0, 0.1, -3.0), "Healing Potion", Color(0.35, 0.9, 0.48))
	_add_quest_marker("cache", Vector3(9.0, 0.1, -8.0), "Supply Cache", Color(0.65, 0.38, 0.16))
	_add_quest_marker("waystone", Vector3(4.0, 0.1, 3.0), "Waystone", Color(0.48, 0.72, 0.88))
	_add_quest_marker("campfire", Vector3(10.0, 0.1, 6.0), "Campfire", Color(0.95, 0.52, 0.2))
	_add_quest_marker("cave_entrance", Vector3(-13.0, 0.1, 5.0), "Cave Entrance", Color(0.55, 0.57, 0.6))
	_add_quest_marker("cave_exit", Vector3(-13.0, 0.1, 8.0), "Cave Exit", Color(0.55, 0.57, 0.6))
	_add_quest_marker("cave_guardian", Vector3(-7.0, 1.0, 10.0), "Cave Sentinel", Color(0.55, 0.5, 0.43))
	_add_quest_marker("cave_treasure", Vector3(-10.0, 0.1, 13.0), "Crystal Heart", Color(0.2, 0.9, 1.0))

func _add_quest_marker(marker_id: String, position: Vector3, marker_name: String, color: Color) -> void:
	var marker := Node3D.new()
	marker.position = position
	var object_mesh := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.45
	mesh.height = 0.9
	object_mesh.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.35
	object_mesh.material_override = material
	object_mesh.position.y = 0.55
	marker.add_child(object_mesh)
	_add_world_name(marker, marker_name)
	quest_objects[marker_id] = marker
	add_child(marker)

func _add_world_name(parent: Node3D, display_name: String) -> void:
	var name_label := Label3D.new()
	name_label.text = display_name
	name_label.font_size = 48
	name_label.pixel_size = 0.008
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.position = Vector3(0.0, 1.8, 0.0)
	name_label.modulate = Color(1.0, 0.91, 0.65)
	parent.add_child(name_label)

func _show_hero_creation() -> void:
	player.movement_enabled = false
	title_panel = _make_menu_panel("Create Your Hero")
	var content: VBoxContainer = title_panel.get_meta("content")
	hero_name_edit = LineEdit.new()
	hero_name_edit.placeholder_text = "Hero name"
	hero_name_edit.text = ""
	hero_name_edit.max_length = 16
	content.add_child(hero_name_edit)
	hero_class_option = OptionButton.new()
	for hero_type in ["Warrior", "Mage", "Rogue"]:
		hero_class_option.add_item(hero_type)
	hero_class_option.select(0)
	hero_class_option.item_selected.connect(_on_hero_class_selected)
	content.add_child(hero_class_option)
	var traits := Label.new()
	traits.text = "Warriors endure and brace better. Mages amplify Ember. Rogues can evade enemy attacks."
	traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(traits)
	hero_stats_label = Label.new()
	hero_stats_label.custom_minimum_size.y = 68.0
	content.add_child(hero_stats_label)
	var roll_button := Button.new()
	roll_button.text = "Roll Stats"
	roll_button.pressed.connect(_roll_hero_stats)
	content.add_child(roll_button)
	var begin_button := Button.new()
	begin_button.text = "Begin Adventure"
	begin_button.pressed.connect(_confirm_hero_creation)
	content.add_child(begin_button)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_cancel_hero_creation)
	content.add_child(cancel_button)
	_roll_hero_stats()

func _confirm_hero_creation() -> void:
	hero_name = hero_name_edit.text.strip_edges()
	if hero_name.is_empty():
		hero_name_edit.placeholder_text = "Please enter a name"
		return
	hero_class = hero_class_option.get_item_text(hero_class_option.selected)
	player_hp = max_hp()
	player_mp = max_mp()
	player.max_health = max_hp()
	player.health = player_hp
	player.movement_enabled = true
	title_panel.queue_free()
	title_panel = null
	_update_hud()
	_save_progress()

func _on_hero_class_selected(index: int) -> void:
	hero_class = hero_class_option.get_item_text(index)
	_roll_hero_stats()

func _roll_hero_stats() -> void:
	var ranges: Dictionary
	match hero_class_option.get_item_text(hero_class_option.selected) if hero_class_option != null else hero_class:
		"Mage":
			ranges = {
				"vitality": Vector2i(8, 12), "strength": Vector2i(5, 9),
				"spirit": Vector2i(14, 18), "agility": Vector2i(8, 12)
			}
		"Rogue":
			ranges = {
				"vitality": Vector2i(10, 14), "strength": Vector2i(10, 14),
				"spirit": Vector2i(8, 12), "agility": Vector2i(14, 18)
			}
		_:
			ranges = {
				"vitality": Vector2i(14, 18), "strength": Vector2i(13, 17),
				"spirit": Vector2i(6, 10), "agility": Vector2i(6, 10)
			}
	hero_vitality = randi_range(ranges["vitality"].x, ranges["vitality"].y)
	hero_strength = randi_range(ranges["strength"].x, ranges["strength"].y)
	hero_spirit = randi_range(ranges["spirit"].x, ranges["spirit"].y)
	hero_agility = randi_range(ranges["agility"].x, ranges["agility"].y)
	if hero_stats_label != null:
		hero_stats_label.text = "%s  ·  HP %d  ·  MP %d\nVitality %d    Strength %d    Spirit %d    Agility %d" % [
			hero_class, max_hp(), max_mp(), hero_vitality, hero_strength, hero_spirit, hero_agility
		]

func _cancel_hero_creation() -> void:
	var title_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var title_menu: Node = title_scene.instantiate()
	get_tree().root.add_child(title_menu)
	get_tree().current_scene = title_menu
	queue_free()

func _show_save_slots(action: String = "load") -> void:
	if slot_panel != null:
		slot_panel.queue_free()
		slot_panel = null
	player.movement_enabled = false
	save_slot_action = action
	slot_panel = _make_menu_panel("Save Adventure" if action == "save" else "Load Adventure")
	var overlay := slot_panel
	var content: VBoxContainer = overlay.get_meta("content")
	for slot_index in range(3):
		var path := _save_slot_path(slot_index)
		var button := Button.new()
		if action == "save":
			button.text = "Save to Slot %d%s" % [slot_index + 1, "  ·  Overwrite" if FileAccess.file_exists(path) else "  ·  Empty"]
			button.pressed.connect(_request_slot_save.bind(path))
		else:
			button.text = "Load Save Slot %d%s" % [slot_index + 1, "" if FileAccess.file_exists(path) else "  ·  Empty"]
			button.disabled = not FileAccess.file_exists(path)
			button.pressed.connect(_load_slot_scene.bind(path))
		content.add_child(button)
	var close_button := Button.new()
	close_button.text = "Back to Adventure"
	close_button.pressed.connect(func() -> void:
		_close_overlay("slots")
		player.movement_enabled = true
	)
	content.add_child(close_button)

func _request_slot_save(path: String) -> void:
	if FileAccess.file_exists(path):
		var confirmation := ConfirmationDialog.new()
		confirmation.title = "Overwrite save?"
		confirmation.dialog_text = "Replace this save slot with your current adventure?"
		confirmation.confirmed.connect(_save_to_slot.bind(path))
		confirmation.canceled.connect(confirmation.queue_free)
		add_child(confirmation)
		confirmation.confirmed.connect(confirmation.queue_free)
		confirmation.popup_centered()
	else:
		_save_to_slot(path)

func _save_to_slot(path: String) -> void:
	progress_save_path = path
	_save_progress()
	_set_status_message("Adventure saved.")
	_close_overlay("slots")

func _save_slot_path(slot_index: int) -> String:
	return "user://three_d_progress_slot_%d.json" % (slot_index + 1)

func _load_slot_scene(path: String) -> void:
	var scene: PackedScene = load("res://scenes/3d_main.tscn")
	var next_game: Node = scene.instantiate()
	next_game.initial_mode = "continue"
	next_game.progress_save_path = path
	get_tree().root.add_child(next_game)
	get_tree().current_scene = next_game
	queue_free()

func _make_menu_panel(title: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.04, 0.03, 0.86)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700.0, 500.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.18, 0.14, 0.98)))
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	layer.set_meta("content", content)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", Color(1.0, 0.87, 0.61))
	content.add_child(heading)
	layer.add_child(screen)
	return layer

func _open_inventory() -> void:
	if title_panel != null or slot_panel != null or battle_instance != null or inventory_panel != null \
		or shop_panel != null or map_panel != null or dialogue_active:
		return
	player.movement_enabled = false
	inventory_panel = _make_menu_panel("%s  ·  Bag & Equipment" % hero_name)
	var content: VBoxContainer = inventory_panel.get_meta("content")
	var stats := Label.new()
	stats.text = "Level %d   HP %d/%d   MP %d/%d   Potions %d   Gold %d G" % [
		player_level, player_hp, max_hp(), player_mp, max_mp(), player.potions, gold
	]
	content.add_child(stats)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var items := VBoxContainer.new()
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items)
	_add_menu_section(items, "EQUIPPED GEAR")
	for slot in EQUIPMENT_SLOTS:
		var item_name: String = equipped_slots[slot]
		var row := VBoxContainer.new()
		items.add_child(row)
		var label := Label.new()
		label.text = "%s: %s%s" % [
			slot.capitalize(),
			item_name if not item_name.is_empty() else "(empty)",
			"\n" + _describe_equipment(item_name) if not item_name.is_empty() else ""
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		if not item_name.is_empty():
			var unequip_button := Button.new()
			unequip_button.text = "Unequip %s" % slot.capitalize()
			unequip_button.pressed.connect(_unequip_slot.bind(slot))
			row.add_child(unequip_button)

	_add_menu_section(items, "BAG CONTENTS")
	if player.potions > 0:
		var potion_row := HBoxContainer.new()
		items.add_child(potion_row)
		var potion_label := Label.new()
		potion_label.text = "Potion ×%d  ·  Restores HP in battle." % player.potions
		potion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		potion_row.add_child(potion_label)
		var discard_potion := Button.new()
		discard_potion.text = "Discard 1"
		discard_potion.pressed.connect(_discard_potion)
		potion_row.add_child(discard_potion)

	var listed_items: Dictionary = {}
	for item_name in equipment_inventory:
		if listed_items.has(item_name) or not ITEM_CATALOG.has(item_name):
			continue
		listed_items[item_name] = true
		var item: Dictionary = ITEM_CATALOG[item_name]
		var slot: String = item["type"]
		if not EQUIPMENT_SLOTS.has(slot):
			continue
		var is_equipped: bool = equipped_slots[slot] == item_name
		var row := VBoxContainer.new()
		items.add_child(row)
		var item_label := Label.new()
		item_label.text = "%s  ·  %s ×%d%s\n%s\n%s" % [
			slot.capitalize(), item_name, equipment_inventory.count(item_name),
			"  ·  EQUIPPED" if is_equipped else "",
			_describe_equipment(item_name), _compare_equipment(item_name)
		]
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(item_label)
		var actions := HBoxContainer.new()
		row.add_child(actions)
		if not is_equipped:
			var equip_button := Button.new()
			equip_button.text = "Equip %s" % slot.capitalize()
			equip_button.pressed.connect(_equip_item.bind(item_name))
			actions.add_child(equip_button)
		var discard_button := Button.new()
		discard_button.text = "Discard 1"
		discard_button.disabled = not _can_discard_equipment(item_name)
		discard_button.pressed.connect(_discard_equipment.bind(item_name))
		actions.add_child(discard_button)
	var close_button := Button.new()
	close_button.text = "Close Bag"
	close_button.pressed.connect(_close_overlay.bind("inventory"))
	content.add_child(close_button)

func _add_menu_section(parent: VBoxContainer, title: String) -> void:
	var heading := Label.new()
	heading.text = title
	heading.add_theme_color_override("font_color", Color(1.0, 0.87, 0.61))
	heading.add_theme_font_size_override("font_size", 17)
	parent.add_child(heading)

func _compare_equipment(item_name: String) -> String:
	var item: Dictionary = ITEM_CATALOG[item_name]
	var slot: String = item["type"]
	var current_name: String = equipped_slots[slot]
	var current: Dictionary = ITEM_CATALOG[current_name] if not current_name.is_empty() else {}
	return "Compared with %s: Physical %+d  Ember %+d  Defense %+d" % [
		current_name if not current_name.is_empty() else "Empty",
		int(item.get("attack", 0)) - int(current.get("attack", 0)),
		int(item.get("magic", 0)) - int(current.get("magic", 0)),
		int(item.get("defense", 0)) - int(current.get("defense", 0))
	]

func _describe_equipment(item_name: String) -> String:
	var item: Dictionary = ITEM_CATALOG[item_name]
	return "%s   Physical +%d   Ember +%d   Defense +%d" % [
		item["description"], int(item.get("attack", 0)),
		int(item.get("magic", 0)), int(item.get("defense", 0))
	]

func _can_discard_equipment(item_name: String) -> bool:
	if not ITEM_CATALOG.has(item_name):
		return false
	var slot: String = ITEM_CATALOG[item_name]["type"]
	return equipment_inventory.count(item_name) > int(equipped_slots.get(slot, "") == item_name)

func _discard_potion() -> void:
	if player.potions <= 0:
		return
	player.potions -= 1
	_save_progress()
	_set_status_message("Discarded one Potion.")
	_close_overlay("inventory")
	_open_inventory()

func _discard_equipment(item_name: String) -> void:
	if not _can_discard_equipment(item_name):
		return
	equipment_inventory.erase(item_name)
	_save_progress()
	_set_status_message("Discarded one %s." % item_name)
	_close_overlay("inventory")
	_open_inventory()

func _open_shop() -> void:
	if title_panel != null or slot_panel != null or battle_instance != null or shop_panel != null \
		or inventory_panel != null or map_panel != null or dialogue_active:
		return
	player.movement_enabled = false
	shop_panel = _make_menu_panel("Rowan's Trading Post")
	var content: VBoxContainer = shop_panel.get_meta("content")
	var gold_text := Label.new()
	gold_text.text = "Gold: %d G   ·   Buy stock or sell unequipped gear" % gold
	content.add_child(gold_text)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 340.0
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var stock_list := VBoxContainer.new()
	stock_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stock_list)
	for item_name in SHOP_ITEMS:
		var item: Dictionary = ITEM_CATALOG[item_name]
		var buy_button := Button.new()
		buy_button.text = "Buy %s  ·  %d G" % [item_name, item["price"]]
		buy_button.pressed.connect(_buy_item.bind(item_name))
		stock_list.add_child(buy_button)
	for item_name in equipment_inventory:
		if _can_sell_item(item_name):
			var sell_button := Button.new()
			sell_button.text = "Sell %s  ·  +%d G" % [item_name, ITEM_CATALOG[item_name]["sell_price"]]
			sell_button.pressed.connect(_sell_item.bind(item_name))
			stock_list.add_child(sell_button)
	var close_button := Button.new()
	close_button.text = "Leave Shop"
	close_button.pressed.connect(_close_overlay.bind("shop"))
	content.add_child(close_button)

func _close_overlay(kind: String) -> void:
	if kind == "inventory" and inventory_panel != null:
		inventory_panel.queue_free()
		inventory_panel = null
	elif kind == "shop" and shop_panel != null:
		shop_panel.queue_free()
		shop_panel = null
	elif kind == "map" and map_panel != null:
		map_panel.queue_free()
		map_panel = null
	elif kind == "slots" and slot_panel != null:
		slot_panel.queue_free()
		slot_panel = null
	player.movement_enabled = true

func _equip_item(item_name: String) -> void:
	if not equipment_inventory.has(item_name):
		return
	var slot: String = ITEM_CATALOG[item_name]["type"]
	equipped_slots[slot] = item_name
	_save_progress()
	_set_status_message("Equipped %s." % item_name)
	_close_overlay("inventory")
	_open_inventory()

func _unequip_slot(slot: String) -> void:
	equipped_slots[slot] = ""
	_save_progress()
	_close_overlay("inventory")
	_open_inventory()

func _buy_item(item_name: String) -> void:
	var item: Dictionary = ITEM_CATALOG[item_name]
	var price := int(item["price"])
	if gold < price:
		_set_status_message("Not enough gold.")
		return
	gold -= price
	if item["type"] == "consumable":
		player.potions += 1
	else:
		equipment_inventory.append(item_name)
	_save_progress()
	_close_overlay("shop")
	_open_shop()

func _can_sell_item(item_name: String) -> bool:
	if not ITEM_CATALOG.has(item_name):
		return false
	var copies := 0
	for owned_item in equipment_inventory:
		if owned_item == item_name:
			copies += 1
	for slot in equipped_slots:
		if equipped_slots[slot] == item_name:
			return copies > 1 and int(ITEM_CATALOG[item_name]["sell_price"]) > 0
	return int(ITEM_CATALOG[item_name]["sell_price"]) > 0

func _sell_item(item_name: String) -> void:
	if not _can_sell_item(item_name):
		return
	gold += int(ITEM_CATALOG[item_name]["sell_price"])
	equipment_inventory.erase(item_name)
	_save_progress()
	_close_overlay("shop")
	_open_shop()

func _open_map_journal() -> void:
	if title_panel != null or slot_panel != null or battle_instance != null or map_panel != null \
		or shop_panel != null or inventory_panel != null or dialogue_active:
		return
	player.movement_enabled = false
	map_panel = _make_menu_panel("Greenvale  ·  Map & Journal")
	var content: VBoxContainer = map_panel.get_meta("content")
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(tabs)
	map_tab_button = Button.new()
	map_tab_button.text = "World Map"
	map_tab_button.pressed.connect(_show_map_page)
	tabs.add_child(map_tab_button)
	journal_tab_button = Button.new()
	journal_tab_button.text = "Quest Journal"
	journal_tab_button.pressed.connect(_show_journal_page)
	tabs.add_child(journal_tab_button)

	map_page = VBoxContainer.new()
	map_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(map_page)
	map_canvas = CampaignMap.new()
	map_canvas.game = self
	map_canvas.custom_minimum_size = Vector2(640, 320)
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_page.add_child(map_canvas)
	var legend := Label.new()
	legend.text = "Blue: You are here   Gold: Current objective   Green: Village   Gray: Cave"
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_page.add_child(legend)

	journal_page = ScrollContainer.new()
	journal_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var journal_entries := VBoxContainer.new()
	journal_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_entries.add_theme_constant_override("separation", 8)
	journal_page.add_child(journal_entries)
	content.add_child(journal_page)
	_refresh_campaign_journal(journal_entries)
	var close_button := Button.new()
	close_button.text = "Close  ·  M / Esc"
	close_button.pressed.connect(_close_overlay.bind("map"))
	content.add_child(close_button)
	_show_map_page()

func _show_map_page() -> void:
	if map_page == null or journal_page == null:
		return
	map_page.show()
	journal_page.hide()
	map_tab_button.disabled = true
	journal_tab_button.disabled = false

func _show_journal_page() -> void:
	if map_page == null or journal_page == null:
		return
	map_page.hide()
	journal_page.show()
	map_tab_button.disabled = false
	journal_tab_button.disabled = true

func _refresh_campaign_journal(entries: VBoxContainer) -> void:
	_add_campaign_journal_section(entries, "MAIN ADVENTURE", [
		["Speak with Mira", quest_step >= 1, quest_step == 0],
		["Examine the northern trail evidence", northern_tracks_found or quest_step >= 2, quest_step == 1 and not northern_tracks_found],
		["Defeat the Forest Shade", quest_step >= 2, quest_step == 1 and northern_tracks_found],
		["Report to Mira", quest_step >= 3, quest_step == 2],
		["Study tracks on the southern trail", southern_tracks_found or quest_step >= 4, quest_step == 3 and not southern_tracks_found],
		["Defeat the Bramble Wolf", quest_step >= 4, quest_step == 3 and southern_tracks_found],
		["Report to Mira and open the cave path", quest_step >= 5, quest_step == 4]
	])
	_add_campaign_journal_section(entries, "OPTIONAL HUNTER CONTRACT", [
		["Accept Mira's contract", hunter_contract_stage >= 1, quest_step >= 5 and hunter_contract_stage == 0],
		["Investigate the scorched earth", hunter_contract_stage >= 2, hunter_contract_stage == 1],
		["Defeat Ashwing and Forest Shade", hunter_contract_stage >= 3, hunter_contract_stage == 2],
		["Inspect the stone tracks", hunter_contract_stage >= 4, hunter_contract_stage == 3],
		["Defeat Thornback and Bramble Wolf", hunter_contract_stage >= 5, hunter_contract_stage == 4],
		["Report the cleared trails to Mira", hunter_contract_stage >= 6, hunter_contract_stage == 5]
	])
	_add_campaign_journal_section(entries, "OPTIONAL CAVE", [
		["Unlock and enter the cave", quest_step >= 5, quest_step < 5],
		["Defeat the Cave Sentinel", cave_guardian_defeated, quest_step >= 5 and not cave_guardian_defeated],
		["Claim the Crystal Heart", cave_treasure_claimed, cave_guardian_defeated and not cave_treasure_claimed]
	])

func _add_campaign_journal_section(parent: VBoxContainer, title: String, entries: Array) -> void:
	_add_menu_section(parent, title)
	for entry in entries:
		var complete: bool = entry[1]
		var active: bool = entry[2]
		var marker := "✓" if complete else "›" if active else "·"
		var status := "COMPLETE" if complete else "ACTIVE" if active else "NOT STARTED"
		var line := Label.new()
		line.text = "%s  %s  —  %s" % [marker, status, entry[0]]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_color_override("font_color",
			Color("9bd18c") if complete else Color("f3d890") if active else Color("98a297"))
		parent.add_child(line)

func _get_campaign_map_markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = [
		{"name": "Greenvale", "position": Vector3(0, 0, -13), "color": Color("83c77b"), "status": "landmark"},
		{"name": "Mira", "position": npc.global_position, "color": Color("83c77b"), "status": "landmark"},
		{"name": "Rowan", "position": merchant.global_position, "color": Color("83c77b"), "status": "landmark"}
	]
	if quest_step >= 1:
		markers.append(_campaign_map_marker("North clue", quest_objects["northern_tracks"].global_position,
			"active" if quest_step == 1 and not northern_tracks_found else "complete"))
		markers.append(_campaign_map_marker("Forest Shade", Vector3(11, 0, -7),
			"active" if quest_step == 1 and northern_tracks_found else "complete" if quest_step >= 2 else "locked"))
	if quest_step >= 3:
		markers.append(_campaign_map_marker("South tracks", quest_objects["southern_tracks"].global_position,
			"active" if quest_step == 3 and not southern_tracks_found else "complete"))
		markers.append(_campaign_map_marker("Bramble Wolf", Vector3(13, 0, 8),
			"active" if quest_step == 3 and southern_tracks_found else "complete" if quest_step >= 4 else "locked"))
	if hunter_contract_stage >= 1:
		markers.append(_campaign_map_marker("Scorch clue", quest_objects["scorch_marks"].global_position,
			"active" if hunter_contract_stage == 1 else "complete"))
	if hunter_contract_stage >= 2:
		markers.append(_campaign_map_marker("Ashwing", Vector3(14, 0, 0),
			"active" if hunter_contract_stage == 2 else "complete"))
	if hunter_contract_stage >= 3:
		markers.append(_campaign_map_marker("Stone tracks", quest_objects["stone_tracks"].global_position,
			"active" if hunter_contract_stage == 3 else "complete"))
	if hunter_contract_stage >= 4:
		markers.append(_campaign_map_marker("Thornback", Vector3(14, 0, 10),
			"active" if hunter_contract_stage == 4 else "complete"))
	if quest_step >= 5:
		markers.append(_campaign_map_marker("Cave", quest_objects["cave_entrance"].global_position,
			"complete" if cave_guardian_defeated else "active"))
	if waystone_discovered:
		markers.append(_campaign_map_marker("Waystone", quest_objects["waystone"].global_position, "complete"))
	return markers

func _campaign_map_marker(marker_name: String, marker_position: Vector3, marker_status: String) -> Dictionary:
	var color := Color("f3d890") if marker_status == "active" \
		else Color("93bd80") if marker_status == "complete" else Color("a6aaa0")
	return {"name": marker_name, "position": marker_position, "color": color, "status": marker_status}

func _close_map() -> void:
	_close_overlay("map")

func _add_box_collider(parent: Node3D, size: Vector3, offset: Vector3) -> void:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	collision.position = offset
	body.add_child(collision)
	parent.add_child(body)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 7.5, 10.0)
	camera.fov = 58.0
	camera.current = true
	add_child(camera)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	objective_label = Label.new()
	objective_label.position = Vector2(18.0, 18.0)
	objective_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	objective_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(objective_label)

	status_label = Label.new()
	status_label.position = Vector2(18.0, 52.0)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.8))
	status_label.add_theme_font_size_override("font_size", 15)
	canvas.add_child(status_label)

	inventory_label = Label.new()
	inventory_label.position = Vector2(18.0, 82.0)
	inventory_label.add_theme_color_override("font_color", Color(0.98, 0.85, 0.6))
	inventory_label.add_theme_font_size_override("font_size", 15)
	canvas.add_child(inventory_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(18.0, 112.0)
	health_bar.custom_minimum_size = Vector2(240.0, 20.0)
	health_bar.show_percentage = false
	health_bar.max_value = 100.0
	var health_style := StyleBoxFlat.new()
	health_style.bg_color = Color(0.12, 0.08, 0.07)
	health_style.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("background", health_style)
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color(0.82, 0.16, 0.12)
	health_fill.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	canvas.add_child(health_bar)

	var controls_background := ColorRect.new()
	controls_background.anchor_left = 0.0
	controls_background.anchor_top = 1.0
	controls_background.anchor_right = 1.0
	controls_background.anchor_bottom = 1.0
	controls_background.offset_top = -52.0
	controls_background.offset_bottom = 0.0
	controls_background.color = Color(0.035, 0.055, 0.05, 0.96)
	controls_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(controls_background)

	var controls_label := Label.new()
	controls_label.text = "WASD Move   E Interact   1 Attack   2 Ember   3 Guard   4 Potion   5 Flee   I Bag   M Map"
	controls_label.anchor_top = 1.0
	controls_label.anchor_bottom = 1.0
	controls_label.offset_left = 18.0
	controls_label.offset_top = -44.0
	controls_label.offset_right = -18.0
	controls_label.offset_bottom = -8.0
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	controls_label.add_theme_font_size_override("font_size", 15)
	canvas.add_child(controls_label)

	prompt_label = Label.new()
	prompt_label.anchor_left = 0.5
	prompt_label.anchor_right = 0.5
	prompt_label.anchor_top = 1.0
	prompt_label.anchor_bottom = 1.0
	prompt_label.offset_left = -220.0
	prompt_label.offset_right = 220.0
	prompt_label.offset_top = -96.0
	prompt_label.offset_bottom = -60.0
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.65))
	prompt_label.add_theme_font_size_override("font_size", 18)
	canvas.add_child(prompt_label)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.anchor_left = 0.08
	dialogue_panel.anchor_right = 0.92
	dialogue_panel.anchor_top = 0.68
	dialogue_panel.anchor_bottom = 0.94
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.08, 0.07, 0.96)))
	var dialogue_content := VBoxContainer.new()
	dialogue_panel.add_child(dialogue_content)
	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 18)
	dialogue_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82))
	dialogue_content.add_child(dialogue_label)
	dialogue_hint = Label.new()
	dialogue_hint.text = "E to continue"
	dialogue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogue_hint.add_theme_color_override("font_color", Color(0.8, 0.86, 0.77))
	dialogue_content.add_child(dialogue_hint)
	dialogue_panel.visible = false
	canvas.add_child(dialogue_panel)

	var menu_row := HBoxContainer.new()
	menu_row.position = Vector2(18.0, 148.0)
	canvas.add_child(menu_row)
	var bag_button := Button.new()
	bag_button.text = "Bag (I)"
	bag_button.pressed.connect(_open_inventory)
	menu_row.add_child(bag_button)
	var journal_button := Button.new()
	journal_button.text = "Map / Journal (M)"
	journal_button.pressed.connect(_open_map_journal)
	menu_row.add_child(journal_button)
	var save_button := Button.new()
	save_button.text = "Save Slot"
	save_button.pressed.connect(_show_save_slots.bind("save"))
	menu_row.add_child(save_button)

func _process(_delta: float) -> void:
	if player == null or camera == null or battle_instance != null:
		return

	if status_message_timer > 0.0:
		status_message_timer = max(0.0, status_message_timer - _delta)
		if status_message_timer <= 0.0:
			status_message = ""

	if player.movement_enabled:
		_check_campaign_encounters()
	_update_prompt()

	var desired_camera_position := Vector3(player.position.x, player.position.y + 6.5, player.position.z + 8.5)
	camera.global_position = camera.global_position.lerp(desired_camera_position, 0.12)
	camera.look_at(player.position + Vector3(0.0, 1.2, 0.0), Vector3.UP)
	camera.near = 0.1
	camera.far = 100.0
	_update_hud()
	save_timer += _delta
	if save_timer >= 2.0 and initial_mode != "load_slots" and title_panel == null:
		_save_progress()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return
	if dialogue_active:
		_advance_dialogue()
	elif inventory_panel != null:
		_close_overlay("inventory")
	elif shop_panel != null:
		_close_overlay("shop")
	elif map_panel != null:
		_close_overlay("map")
	elif slot_panel != null:
		_close_overlay("slots")

func _handle_player_interaction() -> void:
	if title_panel != null or slot_panel != null or battle_instance != null:
		return
	if dialogue_active:
		_advance_dialogue()
		return
	if inventory_panel != null or shop_panel != null or map_panel != null:
		return
	if npc != null and npc.global_position.distance_to(player.global_position) < 2.5:
		_talk_to_mira()
		return
	if merchant != null and merchant.global_position.distance_to(player.global_position) < 2.5:
		_open_shop()
		return
	for object_name in quest_objects:
		var object: Node3D = quest_objects[object_name]
		if object == null or not is_instance_valid(object):
			continue
		if object.global_position.distance_to(player.global_position) < 2.2:
			_interact_with_quest_object(object_name)
			return

	for crystal in crystals:
		if crystal == null or not is_instance_valid(crystal):
			continue
		if crystal.global_position.distance_to(player.global_position) < 2.0:
			crystals.erase(crystal)
			collected_crystal_ids.append(crystal.get_meta("crystal_id"))
			crystal.queue_free()
			player.heal(15.0)
			player.gems += 1
			status_message = "Crystal recovered. The shrine is stronger."
			status_message_timer = 2.5
			_update_objective()
			_save_progress()
			return

	if in_cave and quest_objects.has("cave_treasure") \
		and quest_objects["cave_treasure"].global_position.distance_to(player.global_position) < 2.2 \
		and cave_guardian_defeated and not cave_treasure_claimed:
		cave_treasure_claimed = true
		hero_spirit = mini(hero_spirit + 2, 30)
		player_mp = mini(player_mp + 4, max_mp())
		status_message = "The Crystal Heart increases Spirit by 2."
		status_message_timer = 3.0
		_save_progress()
		return

	if _near_campfire():
		player_hp = max_hp()
		player_mp = max_mp()
		status_message = "You rest and recover at the campfire."
		status_message_timer = 2.5
		_save_progress()
		return
	status_message = "Nothing useful is nearby."
	status_message_timer = 2.0

func _update_prompt() -> void:
	if dialogue_active or battle_instance != null or inventory_panel != null \
		or shop_panel != null or map_panel != null or slot_panel != null or title_panel != null:
		prompt_label.text = ""
		return
	var message := ""
	if npc != null and npc.global_position.distance_to(player.global_position) < 2.5:
		message = "E  Talk to Mira"
	elif merchant != null and merchant.global_position.distance_to(player.global_position) < 2.5:
		message = "E  Trade with Rowan"
	elif _near_marker("northern_tracks") and quest_step == 1 and not northern_tracks_found:
		message = "E  Examine the broken branches"
	elif _near_marker("southern_tracks") and quest_step == 3 and not southern_tracks_found:
		message = "E  Study the tracks in the mud"
	elif _near_marker("scorch_marks") and hunter_contract_stage == 1:
		message = "E  Examine the scorched earth"
	elif _near_marker("stone_tracks") and hunter_contract_stage == 3:
		message = "E  Inspect the claw marks"
	elif _near_marker("salve") and not salve_collected:
		message = "E  Pick up a healing potion"
	elif _near_marker("cache") and not cache_opened:
		message = "E  Open the old supply cache"
	elif _near_marker("waystone") and not waystone_discovered:
		message = "E  Read the ancient waystone"
	elif _near_campfire():
		message = "E  Rest at the campfire"
	elif _near_marker("cave_treasure") and in_cave and cave_guardian_defeated and not cave_treasure_claimed:
		message = "E  Claim the Crystal Heart"
	elif _near_marker("cave_exit") and in_cave:
		message = "E  Leave the cave"
	elif _near_marker("cave_entrance") and not in_cave:
		message = "E  Enter the cave" if quest_step >= 5 else "The cave is sealed until Greenvale is safe."
	prompt_label.text = message

func _near_marker(marker_id: String) -> bool:
	return quest_objects.has(marker_id) and quest_objects[marker_id].global_position.distance_to(player.global_position) < 2.2

func _near_campfire() -> bool:
	return _near_marker("campfire")

func _interact_with_quest_object(marker_id: String) -> void:
	match marker_id:
		"northern_tracks":
			if quest_step == 1 and not northern_tracks_found:
				northern_tracks_found = true
				_show_notice("The broken branches point east. A heavy, ash-scented presence waits in the clearing.")
		"southern_tracks":
			if quest_step == 3 and not southern_tracks_found:
				southern_tracks_found = true
				_show_notice("The deep pawprints turn toward the southern glade. Whatever made them is close.")
		"scorch_marks":
			if hunter_contract_stage == 1:
				hunter_contract_stage = 2
				_show_notice("The scorch marks are fresh. Ashwing is close, and a Forest Shade guards the nest.")
		"stone_tracks":
			if hunter_contract_stage == 3:
				hunter_contract_stage = 4
				_show_notice("The claw marks lead to Thornback and a Bramble Wolf.")
		"salve":
			if not salve_collected:
				salve_collected = true
				player.potions += 1
				_show_notice("You found a healing potion.")
		"cache":
			if not cache_opened:
				cache_opened = true
				gold += 35
				player.potions += 1
				_show_notice("The cache held 35 G and a potion.")
		"waystone":
			waystone_discovered = true
			_show_notice("The waystone marks the old trail to a sealed cave.")
		"cave_entrance":
			if quest_step >= 5:
				in_cave = true
				player.global_position = Vector3(-9.0, 1.0, 7.0)
				_show_notice("You enter the old cave.")
			else:
				_show_notice("The cave seal will only open after Greenvale is safe.")
		"cave_exit":
			if in_cave:
				in_cave = false
				player.global_position = Vector3(-11.0, 1.0, 5.0)
				_show_notice("You leave the cave and return to the forest trail.")
		"campfire":
			player_hp = max_hp()
			player_mp = max_mp()
			_show_notice("You rest and recover at the campfire.")
		"cave_treasure":
			if cave_guardian_defeated and not cave_treasure_claimed:
				cave_treasure_claimed = true
				hero_spirit = mini(hero_spirit + 2, 30)
				player_mp = mini(player_mp + 4, max_mp())
				_show_notice("The Crystal Heart increases Spirit by 2.")
	_save_progress()
	_update_objective()

func _talk_to_mira() -> void:
	match quest_step:
		0:
			dialogue_lines = ["Mira: The Forest Shade has been stalking the northern trail. Examine the broken branches, then drive it away."]
			quest_step = 1
		2:
			dialogue_lines = ["Mira: You faced the Shade bravely. Take 75 gold. Now follow the tracks south and find the creature behind them."]
			gold += 75
			quest_step = 3
		4:
			dialogue_lines = ["Mira: The Bramble Wolf is gone! Take 125 gold and 110 XP. Greenvale is safe again."]
			gold += 125
			_award_experience(110)
			quest_step = 5
		_:
			if hunter_contract_stage == 0 and quest_step >= 5:
				dialogue_lines = ["Mira: Two new creatures have appeared near the old trail. Examine the scorch marks, then follow the stone tracks."]
				hunter_contract_stage = 1
			elif hunter_contract_stage == 5:
				dialogue_lines = ["Mira: You cleared both trails! Take 200 gold and 140 XP. Greenvale owes you much."]
				hunter_contract_stage = 6
				gold += 200
				_award_experience(140)
			elif hunter_contract_stage == 1:
				dialogue_lines = ["Mira: Find the scorch marks east of the cave path. Something is nesting nearby."]
			elif hunter_contract_stage == 2:
				dialogue_lines = ["Mira: Ashwing and its guardian are near the scorched earth."]
			elif hunter_contract_stage == 3:
				dialogue_lines = ["Mira: Follow the heavy claw marks along the lower trail."]
			elif hunter_contract_stage == 4:
				dialogue_lines = ["Mira: Thornback and a Bramble Wolf are waiting at the end of the stone trail."]
			else:
				dialogue_lines = ["Mira: Greenvale is peaceful again. Thank you, friend."]
	_begin_dialogue()
	_save_progress()

func _begin_dialogue() -> void:
	dialogue_index = 0
	dialogue_active = not dialogue_lines.is_empty()
	if dialogue_active:
		dialogue_panel.show()
		_show_dialogue_line()
		player.movement_enabled = false

func _show_dialogue_line() -> void:
	dialogue_label.text = dialogue_lines[dialogue_index]
	dialogue_hint.text = "E  Continue  (%d/%d)" % [dialogue_index + 1, dialogue_lines.size()]

func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		dialogue_active = false
		dialogue_panel.hide()
		player.movement_enabled = true
	else:
		_show_dialogue_line()

func _show_notice(message: String) -> void:
	status_message = message
	status_message_timer = 3.5

func _check_campaign_encounters() -> void:
	if encounter_started:
		return
	if quest_step == 1 and northern_tracks_found and _distance_to(Vector3(11.0, 1.0, -7.0)) < 2.4:
		_start_battle("shade")
	elif quest_step == 3 and southern_tracks_found and _distance_to(Vector3(13.0, 1.0, 8.0)) < 2.4:
		_start_battle("wolf")
	elif hunter_contract_stage == 2 and _distance_to(Vector3(14.0, 1.0, 0.0)) < 2.4:
		_start_battle("hunt_ashwing")
	elif hunter_contract_stage == 4 and _distance_to(Vector3(14.0, 1.0, 10.0)) < 2.4:
		_start_battle("hunt_thornback")
	elif in_cave and not cave_guardian_defeated and _distance_to(Vector3(-7.0, 1.0, 10.0)) < 2.4:
		_start_battle("guardian")

func _on_enemy_defeated(_enemy_id: int = -1) -> void:
	defeated_enemies += 1
	gold += 10
	_save_progress()

func _distance_to(position: Vector3) -> float:
	return player.global_position.distance_to(position)

func _start_battle(encounter: String) -> void:
	encounter_started = true
	active_encounter = encounter
	player.movement_enabled = false
	var enemy: Dictionary
	var additional_enemy: Dictionary = {}
	match encounter:
		"wolf":
			enemy = {"name": "Bramble Wolf", "hp": 164, "damage": Vector2i(13, 19), "xp": 130, "gold": 22, "color": Color("a96f58"), "weakness": "physical", "intents": PackedStringArray(["Quick bite", "Heavy pounce", "Quick bite"])}
		"hunt_ashwing":
			enemy = {"name": "Ashwing", "hp": 92, "damage": Vector2i(7, 11), "xp": 80, "gold": 16, "color": Color("c97548"), "weakness": "physical", "intents": PackedStringArray(["Cinder bolt", "Wing rush", "Cinder bolt"])}
			additional_enemy = {"name": "Forest Shade", "hp": 76, "damage": Vector2i(6, 9), "xp": 40, "gold": 8, "color": Color("647b9a"), "weakness": "fire", "intents": PackedStringArray(["Shadow swipe", "Heavy strike"])}
		"hunt_thornback":
			enemy = {"name": "Thornback", "hp": 174, "damage": Vector2i(10, 15), "xp": 100, "gold": 24, "color": Color("66834c"), "weakness": "fire", "intents": PackedStringArray(["Shell guard", "Heavy charge", "Raking swipe"])}
			additional_enemy = {"name": "Bramble Wolf", "hp": 108, "damage": Vector2i(9, 13), "xp": 65, "gold": 14, "color": Color("a96f58"), "weakness": "physical", "intents": PackedStringArray(["Quick bite", "Heavy pounce"])}
		"guardian":
			enemy = {"name": "Cave Sentinel", "hp": 148, "damage": Vector2i(12, 17), "xp": 115, "gold": 30, "color": Color("817f74"), "weakness": "fire", "intents": PackedStringArray(["Heavy slam", "Stone ward", "Shard throw"])}
		_:
			enemy = {"name": "Forest Shade", "hp": 112, "damage": Vector2i(10, 15), "xp": 80, "gold": 12, "color": Color("647b9a"), "weakness": "fire", "intents": PackedStringArray(["Heavy strike", "Shadow swipe", "Shadow swipe"])}
	battle_instance = BATTLE_SCENE.instantiate()
	add_child(battle_instance)
	battle_instance.connect("finished", _on_battle_finished)
	battle_instance.call("start_battle",
		enemy["name"], enemy["hp"], enemy["damage"], enemy["xp"], enemy["color"],
		enemy["weakness"], enemy["intents"], player_hp, player_mp, player_level,
		player.potions, hero_name, hero_class, hero_vitality, hero_strength,
		hero_spirit, hero_agility, _equipment_stat("attack"), _equipment_stat("magic"),
		_equipment_stat("defense"), additional_enemy, int(enemy.get("gold", 0))
	)

func _on_battle_finished(outcome: String, hp: int, mp: int, potion_count: int, experience: int, gold_reward: int) -> void:
	AudioDirector.play_greenvale_theme()
	player_hp = hp
	player_mp = mp
	player.potions = potion_count
	player.health = hp
	encounter_started = false
	player.movement_enabled = true
	if outcome == "victory":
		gold += gold_reward
		match active_encounter:
			"shade": quest_step = 2
			"wolf": quest_step = 4
			"guardian": cave_guardian_defeated = true
			"hunt_ashwing": hunter_contract_stage = 3
			"hunt_thornback": hunter_contract_stage = 5
		_award_experience(experience)
	elif outcome == "flee":
		if active_encounter == "guardian":
			player.global_position = quest_objects["cave_exit"].global_position + Vector3(0.0, 1.0, 0.0)
		else:
			player.global_position = Vector3(0.0, 1.0, 0.0)
	else:
		player_hp = max_hp()
		player_mp = max_mp()
		player.health = player_hp
		player.global_position = Vector3(0.0, 1.0, 0.0)
	active_encounter = ""
	_update_objective()
	_update_hud()
	_save_progress()
	battle_instance.queue_free()
	battle_instance = null

func _equipment_stat(stat: String) -> int:
	var total := 0
	for slot in EQUIPMENT_SLOTS:
		var item_name: String = equipped_slots[slot]
		if not item_name.is_empty():
			total += int(ITEM_CATALOG[item_name].get(stat, 0))
	return total

func max_hp() -> int:
	return 48 + hero_vitality * 4 + (player_level - 1) * 20

func max_mp() -> int:
	return 6 + hero_spirit * 2 + (player_level - 1) * 6

func experience_to_next_level() -> int:
	return 60 + (player_level - 1) * 35

func _award_experience(amount: int) -> void:
	player_experience += amount
	while player_level < 99 and player_experience >= experience_to_next_level():
		player_experience -= experience_to_next_level()
		player_level += 1
		_show_notice("Level up! You reached level %d." % player_level)

func _update_objective() -> void:
	match hunter_contract_stage:
		1: objective_label.text = "Objective: Examine the scorched earth east of the cave path."
		2: objective_label.text = "Objective: Defeat the creatures near the scorched earth."
		3: objective_label.text = "Objective: Follow the stone tracks on the lower trail."
		4: objective_label.text = "Objective: Defeat the creatures at the end of the tracks."
		5: objective_label.text = "Objective: Return to Mira with the trail cleared."
		6: objective_label.text = "Hunt complete: Both trails are safe. Explore Greenvale!"
		_:
			match quest_step:
				0: objective_label.text = "Objective: Speak with Mira near the village gate."
				1:
					objective_label.text = "Objective: Examine the broken branches." if not northern_tracks_found else "Objective: Defeat the Forest Shade."
				2: objective_label.text = "Objective: Return to Mira for your reward."
				3:
					objective_label.text = "Objective: Study the tracks near the southern trail." if not southern_tracks_found else "Objective: Defeat the Bramble Wolf."
				4: objective_label.text = "Objective: Return to Mira and report the wolf encounter."
				_: objective_label.text = "Adventure complete: The forest is safe. Explore Greenvale!"

func _update_hud() -> void:
	if player == null:
		return
	var health_percent := int(float(player_hp) / float(max_hp()) * 100.0)
	status_label.text = status_message if status_message != "" else "HP %d/%d   MP %d/%d   LV %d" % [
		player_hp, max_hp(), player_mp, max_mp(), player_level
	]
	inventory_label.text = "Gold: %d G   Potions: %d   XP: %d/%d" % [
		gold, player.potions, player_experience, experience_to_next_level()
	]
	health_bar.value = health_percent
	health_bar.max_value = 100.0
	_update_objective()

func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.72, 0.6, 0.39)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _set_status_message(message: String) -> void:
	status_message = message
	status_message_timer = 2.5

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_progress()
		get_tree().quit()

func _load_progress(path: String = SAVE_PATH) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open 3D progress save for reading: %s" % FileAccess.get_open_error())
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("3D progress save is invalid JSON data.")
		return
	var data: Dictionary = parsed
	if int(data.get("version", 0)) not in [1, 2]:
		push_error("Unsupported 3D progress save version.")
		return
	var position_data: Variant = data.get("player_position", [])
	if position_data is Array and position_data.size() == 3:
		saved_player_position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
	saved_player_health = clampf(float(data.get("health", 100.0)), 1.0, 100.0)
	saved_potions = maxi(0, int(data.get("potions", 2)))
	saved_gems = maxi(0, int(data.get("gems", 0)))
	saved_coins = maxi(0, int(data.get("coins", 0)))
	hero_name = str(data.get("hero_name", "Adventurer"))
	hero_class = str(data.get("hero_class", "Warrior"))
	hero_vitality = int(data.get("hero_vitality", 13))
	hero_strength = int(data.get("hero_strength", 10))
	hero_spirit = int(data.get("hero_spirit", 12))
	hero_agility = int(data.get("hero_agility", 10))
	player_level = clampi(int(data.get("player_level", 1)), 1, 99)
	player_experience = maxi(0, int(data.get("player_experience", 0)))
	player_hp = clampi(int(data.get("player_hp", max_hp())), 1, max_hp())
	player_mp = clampi(int(data.get("player_mp", max_mp())), 0, max_mp())
	gold = maxi(0, int(data.get("gold", 0)))
	quest_step = clampi(int(data.get("quest_step", 0)), 0, 5)
	hunter_contract_stage = clampi(int(data.get("hunter_contract_stage", 0)), 0, 6)
	northern_tracks_found = bool(data.get("northern_tracks_found", false))
	southern_tracks_found = bool(data.get("southern_tracks_found", false))
	salve_collected = bool(data.get("salve_collected", false))
	cache_opened = bool(data.get("cache_opened", false))
	waystone_discovered = bool(data.get("waystone_discovered", false))
	in_cave = bool(data.get("in_cave", false))
	cave_guardian_defeated = bool(data.get("cave_guardian_defeated", false))
	cave_treasure_claimed = bool(data.get("cave_treasure_claimed", false))
	var saved_inventory: Variant = data.get("equipment_inventory", equipment_inventory)
	if saved_inventory is Array:
		equipment_inventory.clear()
		for item_name in saved_inventory:
			if ITEM_CATALOG.has(item_name) and ITEM_CATALOG[item_name]["type"] in EQUIPMENT_SLOTS:
				equipment_inventory.append(item_name)
	var saved_equipped: Variant = data.get("equipped_slots", equipped_slots)
	if saved_equipped is Dictionary:
		for slot in EQUIPMENT_SLOTS:
			var item_name := str(saved_equipped.get(slot, ""))
			if item_name.is_empty() or (ITEM_CATALOG.has(item_name) and ITEM_CATALOG[item_name]["type"] == slot and equipment_inventory.has(item_name)):
				equipped_slots[slot] = item_name
	for enemy_id in data.get("defeated_enemy_ids", []):
		var id := int(enemy_id)
		if id >= 0 and id < total_enemies and not defeated_enemy_ids.has(id):
			defeated_enemy_ids.append(id)
	for crystal_id in data.get("collected_crystal_ids", []):
		var id := int(crystal_id)
		if id >= 0 and id < crystals_needed and not collected_crystal_ids.has(id):
			collected_crystal_ids.append(id)

func _save_progress() -> void:
	if title_panel != null or player == null or not is_instance_valid(player) or not player.is_inside_tree():
		return
	var data := {
		"version": 2,
		"player_position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"health": player_hp,
		"potions": player.potions,
		"gems": player.gems,
		"coins": gold,
		"hero_name": hero_name,
		"hero_class": hero_class,
		"hero_vitality": hero_vitality,
		"hero_strength": hero_strength,
		"hero_spirit": hero_spirit,
		"hero_agility": hero_agility,
		"player_hp": player_hp,
		"player_mp": player_mp,
		"player_level": player_level,
		"player_experience": player_experience,
		"gold": gold,
		"quest_step": quest_step,
		"hunter_contract_stage": hunter_contract_stage,
		"northern_tracks_found": northern_tracks_found,
		"southern_tracks_found": southern_tracks_found,
		"salve_collected": salve_collected,
		"cache_opened": cache_opened,
		"waystone_discovered": waystone_discovered,
		"in_cave": in_cave,
		"cave_guardian_defeated": cave_guardian_defeated,
		"cave_treasure_claimed": cave_treasure_claimed,
		"equipment_inventory": equipment_inventory,
		"equipped_slots": equipped_slots,
		"defeated_enemy_ids": defeated_enemy_ids,
		"collected_crystal_ids": collected_crystal_ids
	}
	var file := FileAccess.open(progress_save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open 3D progress save for writing: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data))
	file.close()
	saved_player_position = player.global_position
	save_timer = 0.0
