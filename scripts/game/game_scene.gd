extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/systems/overworld/player_controller.gd")
const BATTLE_SCENE = preload("res://scenes/battle.tscn")
const WORLD_SIZE := Vector2(1600.0, 960.0)
const TILE_SIZE := 32
const VILLAGE_EDGE := 640.0
const FOREST_GATE := 720.0
const CLEARING_POSITION := Vector2(1330.0, 448.0)
const WOLF_CLEARING_POSITION := Vector2(1360.0, 704.0)
const SALVE_POSITION := Vector2(880.0, 448.0)
const CACHE_POSITION := Vector2(1210.0, 390.0)
const WAYSTONE_POSITION := Vector2(1150.0, 570.0)
const CAMPFIRE_POSITION := Vector2(1220.0, 660.0)
const CAVE_ENTRANCE_POSITION := Vector2(1120.0, 800.0)
const CAVE_EXIT_POSITION := Vector2(1080.0, 800.0)
const CAVE_GUARDIAN_POSITION := Vector2(920.0, 800.0)
const CAVE_TREASURE_POSITION := Vector2(840.0, 800.0)
const PLAYER_MAX_HP := 100
const PROGRESS_SAVE_PATH := "user://greenvale_progress.json"
const SAVE_VERSION := 7
const SAVE_SLOT_COUNT := 3
const STARTING_MP := 30
const DEFAULT_HERO_NAME := "Adventurer"
const DEFAULT_HERO_CLASS := "Warrior"

var player: CharacterBody2D
var npc: StaticBody2D
var cave_seal: CollisionShape2D
var world_tiles: TileMapLayer
var tree_positions: Array[Vector2] = []
var tree_texture: Texture2D
var quest_step: int = 0
var dialogue_lines: Array[String] = []
var dialogue_index: int = 0
var dialogue_active: bool = false
var battle_active: bool = false
var encounter_started: bool = false
var player_hp: int = PLAYER_MAX_HP
var player_mp: int = STARTING_MP
var player_level: int = 1
var player_experience: int = 0
var hero_name: String = DEFAULT_HERO_NAME
var hero_class: String = DEFAULT_HERO_CLASS
var hero_vitality: int = 13
var hero_strength: int = 10
var hero_spirit: int = 12
var hero_agility: int = 10
var potions: int = 0
var gold: int = 0
var salve_collected: bool = false
var cache_opened: bool = false
var waystone_discovered: bool = false
var in_cave: bool = false
var cave_guardian_defeated: bool = false
var cave_treasure_claimed: bool = false
var progress_save_path: String = PROGRESS_SAVE_PATH
var battle_instance: Node
var active_encounter: String = ""
var exploration_markers: Dictionary = {}
var save_slot_prefix: String = ""

var hud_layer: CanvasLayer
var objective_label: Label
var hero_identity_label: Label
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var experience_bar: ProgressBar
var progression_label: Label
var gold_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var dialogue_panel: PanelContainer
var dialogue_label: Label
var dialogue_hint: Label
var new_game_button: Button
var new_game_dialog: ConfirmationDialog
var creation_layer: CanvasLayer
var hero_name_input: LineEdit
var hero_class_picker: OptionButton
var hero_stats_label: Label
var begin_adventure_button: Button
var save_load_layer: CanvasLayer
var save_load_title: Label
var save_slot_rows: Array[HBoxContainer] = []
var save_slot_labels: Array[Label] = []
var save_slot_load_buttons: Array[Button] = []
var save_overwrite_dialog: ConfirmationDialog
var pending_save_slot: int = -1

func _ready() -> void:
	save_slot_prefix = progress_save_path.get_basename()
	_build_world()
	_build_player()
	_build_npc()
	_build_interface()
	if FileAccess.file_exists(progress_save_path):
		load_progress(progress_save_path)
		_update_player_appearance()
	else:
		_begin_hero_creation()
	_sync_exploration_markers()
	_update_hud()

func _build_world() -> void:
	y_sort_enabled = true
	world_tiles = TileMapLayer.new()
	world_tiles.name = "Ground"
	world_tiles.z_index = -1
	world_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_tiles.tile_set = _make_world_tileset()
	add_child(world_tiles)
	_paint_world()

	tree_positions.clear()
	_add_rect_obstacle(Vector2(-18, WORLD_SIZE.y * 0.5), Vector2(36, WORLD_SIZE.y + 72))
	_add_rect_obstacle(Vector2(WORLD_SIZE.x + 18, WORLD_SIZE.y * 0.5), Vector2(36, WORLD_SIZE.y + 72))
	_add_rect_obstacle(Vector2(WORLD_SIZE.x * 0.5, -18), Vector2(WORLD_SIZE.x + 72, 36))
	_add_rect_obstacle(Vector2(WORLD_SIZE.x * 0.5, WORLD_SIZE.y + 18), Vector2(WORLD_SIZE.x + 72, 36))
	for x in range(72, 1560, 104):
		for y in range(90, 900, 104):
			var position := Vector2(x + (y % 3) * 13, y)
			if _is_path_position(position) or _is_building_position(position):
				continue
			if x < VILLAGE_EDGE and (x + y) % 3 != 0:
				continue
			tree_positions.append(position)
			_add_tree(position)

	_add_rect_obstacle(Vector2(184, 250), Vector2(150, 100))
	_add_rect_obstacle(Vector2(456, 258), Vector2(130, 80))
	_add_rect_obstacle(Vector2(342, 370), Vector2(68, 42))
	_add_house(Vector2(184, 250), Color("a54f42"), Color("d6bd8b"))
	_add_house(Vector2(456, 258), Color("596b55"), Color("c8b17c"))
	_add_world_marker(SALVE_POSITION, "salve")
	_add_world_marker(CACHE_POSITION, "cache")
	_add_world_marker(WAYSTONE_POSITION, "waystone")
	_add_world_marker(CAMPFIRE_POSITION, "campfire")
	_add_world_marker(CAVE_ENTRANCE_POSITION, "cave")
	_add_cave_walls()

func _add_cave_walls() -> void:
	_add_rect_obstacle(Vector2(960, 688), Vector2(336, 32))
	_add_rect_obstacle(Vector2(792, 808), Vector2(32, 272))
	_add_rect_obstacle(Vector2(960, 936), Vector2(336, 32))
	_add_rect_obstacle(Vector2(1120, 736), Vector2(32, 64))
	_add_rect_obstacle(Vector2(1120, 872), Vector2(32, 112))
	cave_seal = _add_rect_obstacle(Vector2(1120, 800), Vector2(32, 64))

func _is_path_position(position: Vector2) -> bool:
	if position.x < 1140.0 and position.y > 368.0 and position.y < 544.0:
		return true
	if Rect2(808, 704, 304, 224).has_point(position):
		return true
	return position.distance_to(CLEARING_POSITION) < 150.0 \
		or (position.x > 1120.0 and position.y > 544.0 and position.y < 820.0) \
		or position.distance_to(WOLF_CLEARING_POSITION) < 150.0

func _is_building_position(position: Vector2) -> bool:
	return Rect2(72, 120, 224, 220).has_point(position) \
		or Rect2(360, 165, 192, 180).has_point(position) \
		or Rect2(296, 328, 102, 82).has_point(position)

func _add_rect_obstacle(position: Vector2, size: Vector2) -> CollisionShape2D:
	var body := StaticBody2D.new()
	body.position = position
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return collision

func _add_circle_obstacle(position: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = position
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _make_world_tileset() -> TileSet:
	var atlas_image := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	atlas_image.fill(Color.TRANSPARENT)
	for row in range(2):
		for column in range(4):
			_draw_ground_tile(atlas_image, Vector2i(column * TILE_SIZE, row * TILE_SIZE), column, row)
	var atlas_texture := ImageTexture.create_from_image(atlas_image)
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = atlas_texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in range(2):
		for x in range(4):
			atlas_source.create_tile(Vector2i(x, y))
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(atlas_source, 0)
	return tile_set

func _draw_ground_tile(image: Image, origin: Vector2i, column: int, row: int) -> void:
	var base_colors: Array[Color] = [
		Color("81995a"), Color("536f49"), Color("849c5b"), Color("bca071"),
		Color("a98b60"), Color("77745b"), Color("758652"), Color("455f45")
	]
	var tile_index := row * 4 + column
	var base := base_colors[tile_index]
	image.fill_rect(Rect2i(origin, Vector2i(TILE_SIZE, TILE_SIZE)), base)
	var shade := base.darkened(0.13)
	var light := base.lightened(0.12)
	for pixel in range(0, TILE_SIZE, 8):
		image.fill_rect(Rect2i(origin + Vector2i(pixel, 0), Vector2i(1, TILE_SIZE)), shade)
		image.fill_rect(Rect2i(origin + Vector2i(0, pixel), Vector2i(TILE_SIZE, 1)), shade)
	match tile_index:
		0, 1, 6, 7:
			image.fill_rect(Rect2i(origin + Vector2i(6, 7), Vector2i(3, 2)), light)
			image.fill_rect(Rect2i(origin + Vector2i(21, 20), Vector2i(2, 3)), shade)
			image.fill_rect(Rect2i(origin + Vector2i(13, 26), Vector2i(2, 2)), light)
		2:
			_pixel(image, origin.x + 7, origin.y + 10, 3, 3, Color("f1d27a"))
			_pixel(image, origin.x + 6, origin.y + 8, 1, 2, Color("456d43"))
			_pixel(image, origin.x + 21, origin.y + 24, 3, 3, Color("e6a8a0"))
			_pixel(image, origin.x + 22, origin.y + 22, 1, 2, Color("456d43"))
		3, 4:
			image.fill_rect(Rect2i(origin + Vector2i(4, 8), Vector2i(5, 2)), light)
			image.fill_rect(Rect2i(origin + Vector2i(20, 23), Vector2i(4, 2)), shade)
			image.fill_rect(Rect2i(origin + Vector2i(14, 14), Vector2i(2, 2)), Color("d1b987"))
		5:
			image.fill_rect(Rect2i(origin + Vector2i(3, 5), Vector2i(26, 22)), Color("8b795f"))
			for seam in range(8, TILE_SIZE, 8):
				image.fill_rect(Rect2i(origin + Vector2i(seam, 5), Vector2i(1, 22)), Color("685c4b"))
			image.fill_rect(Rect2i(origin + Vector2i(3, 15), Vector2i(26, 1)), Color("685c4b"))

func _pixel(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	image.fill_rect(Rect2i(x, y, width, height), color)

func _paint_world() -> void:
	for y in range(int(WORLD_SIZE.y / TILE_SIZE)):
		for x in range(int(WORLD_SIZE.x / TILE_SIZE)):
			var position := Vector2((x + 0.5) * TILE_SIZE, (y + 0.5) * TILE_SIZE)
			var source := Vector2i(0, 0)
			if x * TILE_SIZE >= VILLAGE_EDGE:
				source = Vector2i(1, 0) if (x + y) % 3 != 0 else Vector2i(3, 1)
			elif (x + y) % 11 == 0:
				source = Vector2i(2, 0)
			if x * TILE_SIZE < 1120 and y in range(12, 16):
				source = Vector2i(3, 0)
			if x in range(33, 37) and y in range(12, 20):
				source = Vector2i(3, 0)
			if x * TILE_SIZE > 1120 and y * TILE_SIZE > 544 and y * TILE_SIZE < 820:
				source = Vector2i(3, 0)
			if position.distance_to(CLEARING_POSITION) < 128.0:
				source = Vector2i(2, 1) if position.distance_to(CLEARING_POSITION) < 82.0 else Vector2i(3, 0)
			if position.distance_to(WOLF_CLEARING_POSITION) < 128.0:
				source = Vector2i(2, 1) if position.distance_to(WOLF_CLEARING_POSITION) < 82.0 else Vector2i(3, 0)
			if Rect2(808, 704, 304, 224).has_point(position):
				source = Vector2i(7, 1)
			if _is_building_position(position):
				source = Vector2i(5, 1)
			world_tiles.set_cell(Vector2i(x, y), 0, source)

func _add_tree(position: Vector2) -> void:
	if tree_texture == null:
		tree_texture = _make_tree_texture()
	var body := StaticBody2D.new()
	body.position = position + Vector2(0, 12)
	body.z_index = 1
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	var sprite := Sprite2D.new()
	sprite.texture = tree_texture
	sprite.position.y = -24.0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(sprite)
	add_child(body)

func _make_tree_texture() -> Texture2D:
	var image := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_pixel(image, 20, 37, 9, 23, Color("63452f"))
	_pixel(image, 18, 55, 13, 4, Color("4a382c"))
	_pixel(image, 9, 22, 28, 23, Color("294c37"))
	_pixel(image, 4, 27, 15, 20, Color("356344"))
	_pixel(image, 28, 24, 16, 22, Color("3c7049"))
	_pixel(image, 13, 11, 23, 24, Color("3d754a"))
	_pixel(image, 18, 5, 14, 15, Color("548250"))
	_pixel(image, 11, 22, 7, 7, Color("679357"))
	_pixel(image, 29, 18, 6, 6, Color("6b9657"))
	_pixel(image, 7, 33, 6, 5, Color("477c4d"))
	return ImageTexture.create_from_image(image)

func _add_world_marker(position: Vector2, marker: String) -> void:
	var sprite := Sprite2D.new()
	sprite.name = marker.capitalize()
	sprite.texture = _make_marker_texture(marker)
	sprite.position = position
	sprite.scale = Vector2(1.5, 1.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 2
	add_child(sprite)
	exploration_markers[marker] = sprite

func _make_marker_texture(marker: String) -> Texture2D:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	match marker:
		"salve":
			_pixel(image, 10, 4, 5, 3, Color("d9c58d"))
			_pixel(image, 8, 7, 9, 12, Color("b84945"))
			_pixel(image, 9, 9, 7, 8, Color("e27563"))
			_pixel(image, 5, 15, 5, 3, Color("5b8b4e"))
			_pixel(image, 14, 14, 5, 4, Color("4b7846"))
			_pixel(image, 7, 18, 10, 2, Color("d9c58d"))
		"cache":
			_pixel(image, 3, 10, 18, 11, Color("704b30"))
			_pixel(image, 4, 7, 16, 5, Color("b98b4f"))
			_pixel(image, 5, 12, 14, 7, Color("986838"))
			_pixel(image, 11, 11, 3, 7, Color("f1d27a"))
			_pixel(image, 4, 19, 3, 3, Color("d0aa69"))
			_pixel(image, 17, 19, 3, 3, Color("d0aa69"))
		"waystone":
			_pixel(image, 6, 3, 12, 19, Color("6b7771"))
			_pixel(image, 8, 5, 8, 15, Color("9ba397"))
			_pixel(image, 10, 8, 4, 9, Color("c6b67a"))
			_pixel(image, 11, 10, 2, 5, Color("e8dba4"))
			_pixel(image, 4, 20, 16, 3, Color("535f56"))
		"campfire":
			_pixel(image, 4, 16, 16, 4, Color("6d4931"))
			_pixel(image, 6, 14, 12, 3, Color("9a6338"))
			_pixel(image, 9, 6, 7, 9, Color("c94f35"))
			_pixel(image, 10, 9, 5, 7, Color("f08c3d"))
			_pixel(image, 11, 11, 3, 4, Color("f8d36b"))
			_pixel(image, 5, 20, 3, 2, Color("d1b987"))
			_pixel(image, 16, 20, 3, 2, Color("d1b987"))
		"cave":
			_pixel(image, 2, 13, 20, 10, Color("443d39"))
			_pixel(image, 4, 8, 16, 12, Color("696258"))
			_pixel(image, 7, 12, 10, 9, Color("171b20"))
			_pixel(image, 9, 14, 6, 8, Color("111519"))
			_pixel(image, 3, 21, 18, 3, Color("a89a76"))
	return ImageTexture.create_from_image(image)

func _add_house(position: Vector2, roof_color: Color, wall_color: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _make_house_texture(roof_color, wall_color)
	sprite.position = position + Vector2(0, -20)
	sprite.z_index = 1
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func _make_house_texture(roof_color: Color, wall_color: Color) -> Texture2D:
	var image := Image.create(96, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_pixel(image, 8, 28, 80, 48, Color("473d34"))
	_pixel(image, 12, 31, 72, 45, wall_color)
	_pixel(image, 4, 25, 88, 8, roof_color.darkened(0.28))
	for row in range(5):
		var inset := row * 7
		_pixel(image, 10 + inset, 8 + row * 5, 76 - inset * 2, 7, roof_color)
		_pixel(image, 10 + inset, 14 + row * 5, 76 - inset * 2, 1, roof_color.lightened(0.15))
	_pixel(image, 22, 52, 18, 24, Color("644333"))
	_pixel(image, 24, 54, 14, 22, Color("825a3c"))
	_pixel(image, 59, 39, 19, 17, Color("527679"))
	_pixel(image, 58, 38, 21, 2, Color("f0dfb0"))
	_pixel(image, 67, 38, 2, 18, Color("f0dfb0"))
	_pixel(image, 12, 74, 72, 3, Color("8e704f"))
	return ImageTexture.create_from_image(image)

func _make_character_texture(coat: Color, hair: Color, trim: Color) -> Texture2D:
	var image := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_pixel(image, 7, 2, 10, 2, hair.darkened(0.2))
	_pixel(image, 5, 4, 14, 6, hair)
	_pixel(image, 7, 10, 10, 7, Color("e7bd91"))
	_pixel(image, 6, 9, 12, 3, hair)
	_pixel(image, 8, 13, 2, 2, Color("453932"))
	_pixel(image, 15, 13, 2, 2, Color("453932"))
	_pixel(image, 5, 17, 14, 9, coat.darkened(0.18))
	_pixel(image, 7, 17, 10, 8, coat)
	_pixel(image, 9, 18, 6, 6, trim)
	_pixel(image, 3, 19, 4, 7, coat)
	_pixel(image, 17, 19, 4, 7, coat)
	_pixel(image, 6, 26, 5, 5, Color("474b5c"))
	_pixel(image, 13, 26, 5, 5, Color("474b5c"))
	_pixel(image, 5, 30, 7, 2, Color("433a34"))
	_pixel(image, 12, 30, 7, 2, Color("433a34"))
	return ImageTexture.create_from_image(image)

func _build_player() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(250, 448)
	player.set_script(PLAYER_SCRIPT)
	player.set("move_speed", 175.0)
	player.set("movement_enabled", true)
	var shape := CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = 30.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	player.add_child(collision)

	var sprite := Sprite2D.new()
	sprite.name = "CharacterSprite"
	sprite.texture = _make_character_texture(Color("b78c45"), Color("594333"), Color("e5cf86"))
	sprite.position.y = -22.0
	sprite.scale = Vector2(1.5, 1.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.add_child(sprite)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y)
	player.add_child(camera)
	add_child(player)
	_update_player_appearance()

func _update_player_appearance() -> void:
	if player == null:
		return
	var coat := Color("b78c45")
	var hair := Color("594333")
	var trim := Color("e5cf86")
	match hero_class:
		"Mage":
			coat = Color("536f91")
			hair = Color("4a3b37")
			trim = Color("9bc8dd")
		"Rogue":
			coat = Color("55734e")
			hair = Color("3b332b")
			trim = Color("c2b16d")
	var sprite := player.get_node_or_null("CharacterSprite") as Sprite2D
	if sprite != null:
		sprite.texture = _make_character_texture(coat, hair, trim)

func _build_npc() -> void:
	npc = StaticBody2D.new()
	npc.name = "Mira"
	npc.position = Vector2(344, 448)
	npc.z_index = 2
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	npc.add_child(collision)
	var sprite := Sprite2D.new()
	sprite.name = "CharacterSprite"
	sprite.texture = _make_character_texture(Color("577f91"), Color("5b4038"), Color("d7b06e"))
	sprite.position.y = -22.0
	sprite.scale = Vector2(1.5, 1.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	npc.add_child(sprite)
	add_child(npc)

func _add_sprite_rect(parent: Node2D, offset: Vector2, size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = offset
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)

func _build_interface() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(screen)

	var hud := _make_panel(screen, Rect2(18, 18, 474, 192))
	var hud_content := VBoxContainer.new()
	hud_content.add_theme_constant_override("separation", 6)
	hud.add_child(hud_content)
	var title := _make_label("CHRONO CHRONICLES  /  GREENVALE", 18, Color("f4e3b8"))
	hud_content.add_child(title)
	hero_identity_label = _make_label("", 13, Color("f3d890"))
	hud_content.add_child(hero_identity_label)
	objective_label = _make_label("", 15, Color("e8eddb"))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_content.add_child(objective_label)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	hud_content.add_child(stats)
	var hp_text := _make_label("HP", 14, Color("f4e3b8"))
	stats.add_child(hp_text)
	hp_bar = _make_bar(Color("70c17b"))
	hp_bar.custom_minimum_size = Vector2(116, 18)
	stats.add_child(hp_bar)
	stats.add_child(_make_label("MP", 14, Color("b8d7e8")))
	mp_bar = _make_bar(Color("6da7d1"))
	mp_bar.custom_minimum_size = Vector2(84, 18)
	stats.add_child(mp_bar)
	gold_label = _make_label("0 G", 14, Color("f0cf75"))
	stats.add_child(gold_label)
	new_game_button = _make_button("New Game")
	new_game_button.custom_minimum_size = Vector2(88, 34)
	new_game_button.add_theme_font_size_override("font_size", 12)
	new_game_button.pressed.connect(_confirm_new_game)

	var progression := HBoxContainer.new()
	progression.add_theme_constant_override("separation", 8)
	hud_content.add_child(progression)
	progression_label = _make_label("", 13, Color("f3d890"))
	progression.add_child(progression_label)
	experience_bar = _make_bar(Color("d4a84e"))
	experience_bar.custom_minimum_size = Vector2(230, 14)
	progression.add_child(experience_bar)

	var controls := _make_panel(screen, Rect2(744, 18, 212, 150))
	var controls_content := VBoxContainer.new()
	controls_content.add_theme_constant_override("separation", 6)
	controls.add_child(controls_content)
	controls_content.add_child(_make_label("WASD / Arrows  Move", 13, Color("e8eddb")))
	controls_content.add_child(_make_label("E  Talk  ·  1-5 Battle", 13, Color("e8eddb")))
	var save_controls := HBoxContainer.new()
	save_controls.add_theme_constant_override("separation", 6)
	controls_content.add_child(save_controls)
	var save_menu_button := _make_button("Save / Load")
	save_menu_button.custom_minimum_size = Vector2(94, 34)
	save_menu_button.pressed.connect(_open_save_load_ui)
	save_controls.add_child(save_menu_button)
	new_game_button.custom_minimum_size = Vector2(94, 34)
	save_controls.add_child(new_game_button)

	prompt_panel = _make_panel(screen, Rect2(310, 540, 340, 48))
	prompt_label = _make_label("", 15, Color("fff0c8"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt_label)

	dialogue_panel = _make_panel(screen, Rect2(22, 408, 936, 172))
	var dialogue_content := VBoxContainer.new()
	dialogue_content.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(dialogue_content)
	dialogue_label = _make_label("", 18, Color("fff0d0"))
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size.y = 92
	dialogue_content.add_child(dialogue_label)
	dialogue_hint = _make_label("E  Continue", 13, Color("b9d1c0"))
	dialogue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogue_content.add_child(dialogue_hint)
	dialogue_panel.hide()

	new_game_dialog = ConfirmationDialog.new()
	new_game_dialog.title = "Start a new game?"
	new_game_dialog.dialog_text = "Start over as a new hero? This replaces the current run in its active save."
	new_game_dialog.ok_button_text = "Start New Game"
	new_game_dialog.confirmed.connect(_start_fresh_game)
	screen.add_child(new_game_dialog)
	_build_hero_creation()
	_build_save_load_ui(screen)
	_update_hud()

func _build_hero_creation() -> void:
	creation_layer = CanvasLayer.new()
	creation_layer.layer = 20
	add_child(creation_layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	creation_layer.add_child(screen)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.03, 0.06, 0.08, 0.9)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(backdrop)
	var panel := _make_panel(screen, Rect2(140, 50, 680, 500))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	panel.add_child(content)
	var title := _make_label("CREATE YOUR HERO", 25, Color("f4e3b8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	content.add_child(_make_label("Choose a name and calling. Roll stats until they feel right.", 15, Color("d5ddcf")))
	hero_name_input = LineEdit.new()
	hero_name_input.placeholder_text = "Hero name"
	hero_name_input.text = DEFAULT_HERO_NAME
	hero_name_input.max_length = 16
	hero_name_input.custom_minimum_size.y = 40
	content.add_child(hero_name_input)
	var class_row := HBoxContainer.new()
	class_row.add_theme_constant_override("separation", 12)
	class_row.add_child(_make_label("Class", 16, Color("f3d890")))
	hero_class_picker = OptionButton.new()
	hero_class_picker.add_item("Warrior")
	hero_class_picker.add_item("Mage")
	hero_class_picker.add_item("Rogue")
	hero_class_picker.item_selected.connect(_on_hero_class_selected)
	class_row.add_child(hero_class_picker)
	content.add_child(class_row)
	hero_stats_label = _make_label("", 16, Color("e8eddb"))
	hero_stats_label.custom_minimum_size.y = 100
	content.add_child(hero_stats_label)
	var explanation := _make_label(
		"Warriors endure and brace better. Mages amplify Ember. Rogues can evade enemy attacks.",
		14, Color("b9d1c0")
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(explanation)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	content.add_child(buttons)
	var reroll_button := _make_button("Roll Stats")
	reroll_button.pressed.connect(_roll_hero_stats)
	buttons.add_child(reroll_button)
	begin_adventure_button = _make_button("Begin Adventure")
	begin_adventure_button.pressed.connect(_confirm_hero_creation)
	buttons.add_child(begin_adventure_button)
	creation_layer.hide()

func _begin_hero_creation() -> void:
	hero_name_input.text = DEFAULT_HERO_NAME
	hero_class_picker.select(0)
	hero_class = DEFAULT_HERO_CLASS
	_update_player_appearance()
	_roll_hero_stats()
	player.set("movement_enabled", false)
	creation_layer.show()

func _on_hero_class_selected(index: int) -> void:
	hero_class = hero_class_picker.get_item_text(index)
	_update_player_appearance()
	_roll_hero_stats()

func _roll_hero_stats() -> void:
	var ranges: Dictionary
	match hero_class:
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
	_update_hero_stats_label()

func _update_hero_stats_label() -> void:
	hero_stats_label.text = "%s  ·  HP %d  ·  MP %d\nVitality %d    Strength %d    Spirit %d    Agility %d\n\nClass traits: %s" % [
		hero_class, max_hp(), max_mp(), hero_vitality, hero_strength, hero_spirit, hero_agility,
		_get_class_trait()
	]

func _get_class_trait() -> String:
	match hero_class:
		"Mage":
			return "Ember deals increased damage."
		"Rogue":
			return "Agility gives a chance to dodge attacks."
		_:
			return "Higher HP and stronger Guard."

func _confirm_hero_creation() -> void:
	var entered_name := hero_name_input.text.strip_edges()
	if entered_name.is_empty():
		hero_name_input.placeholder_text = "Please enter a name"
		return
	hero_name = entered_name
	player_hp = max_hp()
	player_mp = max_mp()
	_update_player_appearance()
	player.set("movement_enabled", true)
	creation_layer.hide()
	var save_error := save_progress(progress_save_path)
	if save_error != OK:
		push_error("Could not save Greenvale progress: %s" % error_string(save_error))
	_update_hud()

func _build_save_load_ui(screen: Control) -> void:
	save_load_layer = CanvasLayer.new()
	save_load_layer.layer = 15
	add_child(save_load_layer)
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	save_load_layer.add_child(overlay)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.03, 0.06, 0.08, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(backdrop)
	var panel := _make_panel(overlay, Rect2(100, 110, 760, 360))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	save_load_title = _make_label("SAVE / LOAD ADVENTURE", 22, Color("f4e3b8"))
	save_load_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(save_load_title)
	content.add_child(_make_label("Saving stores the current hero and world progress in that slot.", 14, Color("d5ddcf")))
	save_slot_rows.clear()
	save_slot_labels.clear()
	save_slot_load_buttons.clear()
	for slot_index in range(SAVE_SLOT_COUNT):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		content.add_child(row)
		var slot_label := _make_label("", 14, Color("e8eddb"))
		slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slot_label)
		var save_button := _make_button("Save")
		save_button.custom_minimum_size = Vector2(100, 36)
		save_button.pressed.connect(_request_save_slot.bind(slot_index))
		row.add_child(save_button)
		var load_button := _make_button("Load")
		load_button.custom_minimum_size = Vector2(100, 36)
		load_button.pressed.connect(_load_slot.bind(slot_index))
		row.add_child(load_button)
		save_slot_rows.append(row)
		save_slot_labels.append(slot_label)
		save_slot_load_buttons.append(load_button)
	var close_button := _make_button("Return to Game")
	close_button.custom_minimum_size = Vector2(220, 38)
	close_button.pressed.connect(_close_save_load_ui)
	content.add_child(close_button)
	save_overwrite_dialog = ConfirmationDialog.new()
	save_overwrite_dialog.title = "Overwrite save?"
	save_overwrite_dialog.dialog_text = "This save slot already contains progress."
	save_overwrite_dialog.ok_button_text = "Overwrite"
	save_overwrite_dialog.confirmed.connect(_confirm_save_slot)
	save_overwrite_dialog.canceled.connect(_cancel_save_overwrite)
	overlay.add_child(save_overwrite_dialog)
	save_load_layer.hide()

func _save_slot_path(slot_index: int) -> String:
	return "%s_slot_%d.json" % [save_slot_prefix, slot_index + 1]

func _open_save_load_ui() -> void:
	if creation_layer.visible or battle_active or dialogue_active:
		return
	player.set("movement_enabled", false)
	_update_save_slot_rows()
	save_load_layer.show()

func _close_save_load_ui() -> void:
	save_load_layer.hide()
	if not creation_layer.visible and not battle_active:
		player.set("movement_enabled", true)

func _update_save_slot_rows() -> void:
	for slot_index in range(SAVE_SLOT_COUNT):
		var summary := _read_save_slot_summary(_save_slot_path(slot_index))
		save_slot_labels[slot_index].text = "Slot %d  ·  %s" % [slot_index + 1, summary["text"]]
		save_slot_load_buttons[slot_index].disabled = not summary["valid"]

func _read_save_slot_summary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"text": "Empty", "valid": false}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not read save slot: %s" % error_string(FileAccess.get_open_error()))
		return {"text": "Unreadable", "valid": false}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or not _is_saved_integer(parsed.get("version")) \
		or int(parsed["version"]) < 1 or int(parsed["version"]) > SAVE_VERSION:
		return {"text": "Invalid save", "valid": false}
	var saved_name := str(parsed.get("hero_name", DEFAULT_HERO_NAME)).strip_edges()
	var saved_class := str(parsed.get("hero_class", DEFAULT_HERO_CLASS))
	var saved_level: Variant = parsed.get("player_level", 1)
	var saved_quest: Variant = parsed.get("quest_step", 0)
	if not _is_saved_integer(saved_level) or not _is_saved_integer(saved_quest):
		return {"text": "Invalid save", "valid": false}
	return {
		"text": "%s the %s  ·  Lv %d  ·  Quest %d" % [
			saved_name, saved_class, int(saved_level), int(saved_quest)
		],
		"valid": true
	}

func _request_save_slot(slot_index: int) -> void:
	pending_save_slot = slot_index
	if FileAccess.file_exists(_save_slot_path(slot_index)):
		save_overwrite_dialog.dialog_text = "Overwrite Slot %d? Its current hero progress will be replaced." % (slot_index + 1)
		save_overwrite_dialog.popup_centered()
	else:
		_confirm_save_slot()

func _confirm_save_slot() -> void:
	if pending_save_slot < 0 or pending_save_slot >= SAVE_SLOT_COUNT:
		return
	var path := _save_slot_path(pending_save_slot)
	var save_error := save_progress(path)
	if save_error != OK:
		push_error("Could not save hero to slot %d: %s" % [pending_save_slot + 1, error_string(save_error)])
		save_load_title.text = "SAVE FAILED"
		return
	progress_save_path = path
	save_load_title.text = "SAVED  ·  %s the %s" % [hero_name, hero_class]
	_update_save_slot_rows()
	pending_save_slot = -1

func _cancel_save_overwrite() -> void:
	pending_save_slot = -1

func _load_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SAVE_SLOT_COUNT:
		return
	var path := _save_slot_path(slot_index)
	if not load_progress(path):
		save_load_title.text = "LOAD FAILED  ·  Save data could not be loaded."
		_update_save_slot_rows()
		return
	progress_save_path = path
	encounter_started = false
	battle_active = false
	dialogue_active = false
	dialogue_panel.hide()
	prompt_panel.hide()
	_update_player_appearance()
	_sync_exploration_markers()
	_update_hud()
	_close_save_load_ui()

func _make_panel(parent: Control, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("24372f")
	style.border_color = Color("b99a69")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("18241f")
	background.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(124, 42)
	button.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("536f59")
	normal.border_color = Color("9fb58a")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("698a68")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("fff0d0"))
	return button

func _process(_delta: float) -> void:
	if player == null:
		return
	_update_prompt()
	if quest_step == 1 and not encounter_started and player.global_position.distance_to(CLEARING_POSITION) < 76.0:
		_start_battle("shade")
	elif quest_step == 3 and not encounter_started and player.global_position.distance_to(WOLF_CLEARING_POSITION) < 76.0:
		_start_battle("wolf")
	elif in_cave and not cave_guardian_defeated and not encounter_started \
		and player.global_position.distance_to(CAVE_GUARDIAN_POSITION) < 64.0:
		_start_battle("guardian")

func _unhandled_input(event: InputEvent) -> void:
	if creation_layer.visible or save_load_layer.visible:
		return
	if event.is_action_pressed("interact") and not event.is_echo() and not battle_active:
		if dialogue_active:
			_advance_dialogue()
		elif player.global_position.distance_to(npc.global_position) < 76.0:
			_talk_to_mira()
		else:
			_interact_with_world()
		get_viewport().set_input_as_handled()

func _update_prompt() -> void:
	if battle_active or dialogue_active:
		prompt_panel.hide()
		return
	if player.global_position.distance_to(npc.global_position) < 76.0:
		prompt_label.text = "E  Talk to Mira"
		prompt_panel.show()
	elif _near_world_object(SALVE_POSITION) and not salve_collected:
		prompt_label.text = "E  Pick up a healing potion"
		prompt_panel.show()
	elif _near_world_object(CACHE_POSITION) and not cache_opened:
		prompt_label.text = "E  Open the old supply cache"
		prompt_panel.show()
	elif _near_world_object(WAYSTONE_POSITION) and not waystone_discovered:
		prompt_label.text = "E  Read the ancient waystone"
		prompt_panel.show()
	elif _near_world_object(CAMPFIRE_POSITION):
		prompt_label.text = "E  Rest at the campfire"
		prompt_panel.show()
	elif in_cave and _near_world_object(CAVE_EXIT_POSITION):
		prompt_label.text = "E  Leave the cave"
		prompt_panel.show()
	elif in_cave and _near_world_object(CAVE_TREASURE_POSITION) and cave_guardian_defeated and not cave_treasure_claimed:
		prompt_label.text = "E  Claim the crystal heart"
		prompt_panel.show()
	elif not in_cave and _near_world_object(CAVE_ENTRANCE_POSITION):
		prompt_label.text = "E  Enter the cave" if quest_step >= 5 else "The cave is sealed until Greenvale is safe."
		prompt_panel.show()
	elif quest_step == 1 and player.global_position.distance_to(CLEARING_POSITION) < 210.0:
		prompt_label.text = "The shade's clearing is just ahead..."
		prompt_panel.show()
	elif quest_step == 3 and player.global_position.distance_to(WOLF_CLEARING_POSITION) < 210.0:
		prompt_label.text = "A growl echoes from the southern trail..."
		prompt_panel.show()
	else:
		prompt_panel.hide()

func _near_world_object(position: Vector2) -> bool:
	return player.global_position.distance_to(position) < 72.0

func _interact_with_world() -> void:
	if in_cave and _near_world_object(CAVE_EXIT_POSITION):
		in_cave = false
		player.global_position = CAVE_ENTRANCE_POSITION + Vector2(56, 0)
		_show_notice("You leave the cave and return to the forest trail.")
	elif in_cave and _near_world_object(CAVE_TREASURE_POSITION) and cave_guardian_defeated and not cave_treasure_claimed:
		cave_treasure_claimed = true
		hero_spirit = mini(hero_spirit + 2, 30)
		player_mp = mini(player_mp + 4, max_mp())
		_show_notice("The crystal heart settles into your pack. Spirit increased by 2.")
	elif not in_cave and _near_world_object(CAVE_ENTRANCE_POSITION) and quest_step >= 5:
		in_cave = true
		player.global_position = CAVE_EXIT_POSITION
		_show_notice("You enter the old cave. Something stirs in the darkness.")
	elif _near_world_object(SALVE_POSITION) and not salve_collected:
		salve_collected = true
		potions += 1
		_sync_exploration_markers()
		_show_notice("You found a healing potion tucked beside the trail.")
	elif _near_world_object(CACHE_POSITION) and not cache_opened:
		cache_opened = true
		gold += 40
		_sync_exploration_markers()
		_show_notice("The old cache holds 40 gold.")
	elif _near_world_object(WAYSTONE_POSITION) and not waystone_discovered:
		waystone_discovered = true
		_award_experience(25)
		_sync_exploration_markers()
		_show_notice("The waystone glows with an old memory. You gained 25 XP.")
	elif _near_world_object(CAMPFIRE_POSITION):
		var was_injured := player_hp < max_hp() or player_mp < max_mp()
		player_hp = max_hp()
		player_mp = max_mp()
		_show_notice("You rest by the fire and recover your strength." if was_injured else "You enjoy a quiet moment by the fire.")
	else:
		return
	var save_error := save_progress(progress_save_path)
	if save_error != OK:
		push_error("Could not save Greenvale progress: %s" % error_string(save_error))
	_update_hud()

func _show_notice(message: String) -> void:
	dialogue_lines = [message]
	dialogue_index = 0
	dialogue_active = true
	dialogue_panel.show()
	_show_dialogue_line()

func _sync_exploration_markers() -> void:
	if exploration_markers.is_empty():
		return
	exploration_markers["salve"].visible = not salve_collected
	exploration_markers["cache"].visible = not cache_opened
	exploration_markers["waystone"].visible = not waystone_discovered

func _talk_to_mira() -> void:
	var save_error: Error
	if quest_step == 0:
		dialogue_lines = [
			"Mira: The forest path has gone quiet. Something has driven the shades out of the old clearing.",
			"Could you check the clearing east of here? Take this potion. I will keep the village safe."
		]
		quest_step = 1
		potions = maxi(potions, 1)
		save_error = save_progress(progress_save_path)
		if save_error != OK:
			push_error("Could not save Greenvale progress: %s" % error_string(save_error))
	elif quest_step == 1:
		dialogue_lines = ["Mira: Follow the dirt path east. The shade is waiting in the northern clearing."]
	elif quest_step == 2:
		dialogue_lines = [
			"Mira: The shade is gone! Take these 75 gold and a fresh potion.",
			"Something else is stalking the southern forest trail. Could you investigate?"
		]
		quest_step = 3
		gold += 75
		potions += 1
		encounter_started = false
		save_error = save_progress(progress_save_path)
		if save_error != OK:
			push_error("Could not save Greenvale progress: %s" % error_string(save_error))
	elif quest_step == 3:
		dialogue_lines = ["Mira: Head south from the shade's clearing. The tracks lead to another open glade."]
	elif quest_step == 4:
		dialogue_lines = ["Mira: You drove the wolf away too! Here is 125 gold. Greenvale is safe again."]
		quest_step = 5
		gold += 125
		save_error = save_progress(progress_save_path)
		if save_error != OK:
			push_error("Could not save Greenvale progress: %s" % error_string(save_error))
	else:
		dialogue_lines = ["Mira: Greenvale is peaceful again. Thank you, friend."]
	dialogue_index = 0
	dialogue_active = true
	dialogue_panel.show()
	_show_dialogue_line()
	_update_hud()

func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		dialogue_active = false
		dialogue_panel.hide()
	else:
		_show_dialogue_line()

func _show_dialogue_line() -> void:
	dialogue_label.text = dialogue_lines[dialogue_index]
	dialogue_hint.text = "E  Continue  (%d/%d)" % [dialogue_index + 1, dialogue_lines.size()]

func _start_battle(encounter: String) -> void:
	encounter_started = true
	battle_active = true
	active_encounter = encounter
	player.set("movement_enabled", false)
	var enemy: Dictionary
	match encounter:
		"wolf":
			enemy = {
				"name": "Bramble Wolf", "hp": 164, "damage": Vector2i(13, 19),
				"xp": 130, "color": Color("a96f58"), "weakness": "physical",
				"intents": PackedStringArray(["Quick bite", "Heavy pounce", "Quick bite"])
			}
		"guardian":
			enemy = {
				"name": "Cave Sentinel", "hp": 148, "damage": Vector2i(12, 17),
				"xp": 115, "color": Color("817f74"), "weakness": "fire",
				"intents": PackedStringArray(["Heavy slam", "Stone ward", "Shard throw"])
			}
		_:
			enemy = {
				"name": "Forest Shade", "hp": 112, "damage": Vector2i(10, 15),
				"xp": 80, "color": Color("647b9a"), "weakness": "fire",
				"intents": PackedStringArray(["Heavy strike", "Shadow swipe", "Shadow swipe"])
			}
	battle_instance = BATTLE_SCENE.instantiate()
	add_child(battle_instance)
	battle_instance.connect("finished", _on_battle_finished)
	battle_instance.call("start_battle",
		enemy["name"], enemy["hp"], enemy["damage"], enemy["xp"], enemy["color"],
		enemy["weakness"], enemy["intents"],
		player_hp, player_mp, player_level, potions,
		hero_name, hero_class, hero_vitality, hero_strength, hero_spirit, hero_agility
	)

func _on_battle_finished(outcome: String, hp: int, mp: int, potion_count: int, experience: int) -> void:
	player_hp = hp
	player_mp = mp
	potions = potion_count
	battle_active = false
	player.set("movement_enabled", true)
	if outcome == "victory":
		encounter_started = false
		match active_encounter:
			"shade":
				quest_step = 2
			"wolf":
				quest_step = 4
			"guardian":
				cave_guardian_defeated = true
		_award_experience(experience)
	elif outcome == "flee":
		encounter_started = false
		if active_encounter == "guardian":
			in_cave = true
			player.position = CAVE_EXIT_POSITION
		else:
			player.position = Vector2(560, 448)
	else:
		player_hp = max_hp()
		player_mp = max_mp()
		encounter_started = false
		in_cave = false
		player.position = Vector2(250, 448)
	active_encounter = ""
	var save_error := save_progress(progress_save_path)
	if save_error != OK:
		push_error("Could not save Greenvale progress: %s" % error_string(save_error))
	_update_hud()
	battle_instance.queue_free()
	battle_instance = null

func _update_hud() -> void:
	if objective_label == null:
		return
	cave_seal.disabled = quest_step >= 5
	hero_identity_label.text = "%s  ·  %s" % [hero_name, hero_class]
	match quest_step:
		0:
			objective_label.text = "Objective: Speak with Mira near the village gate."
		1:
			objective_label.text = "Objective: Follow the northern trail and defeat the forest shade."
		2:
			objective_label.text = "Objective: Return to Mira for your reward."
		3:
			objective_label.text = "Objective: Investigate the southern trail and find the wolf."
		4:
			objective_label.text = "Objective: Return to Mira and report the wolf encounter."
		_:
			objective_label.text = "Adventure complete: The forest is safe. Explore Greenvale!"
	hp_bar.value = float(player_hp) / float(max_hp()) * 100.0
	mp_bar.value = float(player_mp) / float(max_mp()) * 100.0
	progression_label.text = "LV %d  ·  %d / %d XP" % [player_level, player_experience, experience_to_next_level()]
	experience_bar.value = float(player_experience) / float(experience_to_next_level()) * 100.0
	gold_label.text = "%d G" % gold
	new_game_button.show()

func save_progress(path: String = PROGRESS_SAVE_PATH) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({
		"version": SAVE_VERSION,
		"quest_step": quest_step,
		"gold": gold,
		"player_hp": player_hp,
		"player_mp": player_mp,
		"player_level": player_level,
		"player_experience": player_experience,
		"potions": potions,
		"hero_name": hero_name,
		"hero_class": hero_class,
		"hero_vitality": hero_vitality,
		"hero_strength": hero_strength,
		"hero_spirit": hero_spirit,
		"hero_agility": hero_agility,
		"position_x": player.global_position.x,
		"position_y": player.global_position.y,
		"salve_collected": salve_collected,
		"cache_opened": cache_opened,
		"waystone_discovered": waystone_discovered,
		"in_cave": in_cave,
		"cave_guardian_defeated": cave_guardian_defeated,
		"cave_treasure_claimed": cave_treasure_claimed
	}))
	var write_error := file.get_error()
	file.close()
	return write_error

func load_progress(path: String = PROGRESS_SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open Greenvale save: %s" % error_string(FileAccess.get_open_error()))
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("Greenvale save is invalid.")
		return false
	var save_version: Variant = parsed.get("version")
	if not _is_saved_integer(save_version) or int(save_version) < 1 or int(save_version) > SAVE_VERSION:
		push_error("Greenvale save is invalid or uses an unsupported version.")
		return false
	if not _is_saved_integer(parsed.get("quest_step")) \
		or not _is_saved_integer(parsed.get("gold")) \
		or not _is_saved_integer(parsed.get("player_hp")) \
		or not _is_saved_integer(parsed.get("potions")):
		push_error("Greenvale save is missing valid progress values.")
		return false
	if int(save_version) >= 2 and (
		not _is_saved_integer(parsed.get("player_mp")) \
		or not _is_saved_integer(parsed.get("player_level")) \
		or not _is_saved_integer(parsed.get("player_experience"))
	):
		push_error("Greenvale save is missing valid progression values.")
		return false
	if int(save_version) >= 4 and (
		typeof(parsed.get("salve_collected")) != TYPE_BOOL \
		or typeof(parsed.get("cache_opened")) != TYPE_BOOL \
		or typeof(parsed.get("waystone_discovered")) != TYPE_BOOL
	):
		push_error("Greenvale save is missing valid exploration values.")
		return false
	if int(save_version) >= 5 and (
		not parsed.get("hero_name") is String \
		or str(parsed["hero_name"]).strip_edges().is_empty() \
		or str(parsed["hero_name"]).length() > 16 \
		or not ["Warrior", "Mage", "Rogue"].has(parsed.get("hero_class")) \
		or not _is_saved_integer(parsed.get("hero_vitality")) \
		or not _is_saved_integer(parsed.get("hero_strength")) \
		or not _is_saved_integer(parsed.get("hero_spirit")) \
		or not _is_saved_integer(parsed.get("hero_agility")) \
		or int(parsed.get("hero_vitality", 0)) < 1 or int(parsed.get("hero_vitality", 0)) > 30 \
		or int(parsed.get("hero_strength", 0)) < 1 or int(parsed.get("hero_strength", 0)) > 30 \
		or int(parsed.get("hero_spirit", 0)) < 1 or int(parsed.get("hero_spirit", 0)) > 30 \
		or int(parsed.get("hero_agility", 0)) < 1 or int(parsed.get("hero_agility", 0)) > 30
	):
		push_error("Greenvale save is missing valid hero values.")
		return false
	if int(save_version) >= 6 and (
		not _is_saved_number(parsed.get("position_x")) \
		or not _is_saved_number(parsed.get("position_y"))
	):
		push_error("Greenvale save is missing a valid hero position.")
		return false
	if int(save_version) >= 7 and (
		typeof(parsed.get("in_cave")) != TYPE_BOOL \
		or typeof(parsed.get("cave_guardian_defeated")) != TYPE_BOOL \
		or typeof(parsed.get("cave_treasure_claimed")) != TYPE_BOOL
	):
		push_error("Greenvale save is missing valid cave progress.")
		return false

	quest_step = clampi(int(parsed["quest_step"]), 0, 5)
	if int(save_version) < 3 and quest_step == 2:
		quest_step = 3
	gold = maxi(int(parsed["gold"]), 0)
	player_level = clampi(int(parsed.get("player_level", 1)), 1, 99)
	player_experience = maxi(int(parsed.get("player_experience", 0)), 0)
	hero_name = str(parsed.get("hero_name", DEFAULT_HERO_NAME)).strip_edges()
	hero_class = str(parsed.get("hero_class", DEFAULT_HERO_CLASS))
	hero_vitality = clampi(int(parsed.get("hero_vitality", 13)), 1, 30)
	hero_strength = clampi(int(parsed.get("hero_strength", 10)), 1, 30)
	hero_spirit = clampi(int(parsed.get("hero_spirit", 12)), 1, 30)
	hero_agility = clampi(int(parsed.get("hero_agility", 10)), 1, 30)
	player_hp = clampi(int(parsed["player_hp"]), 1, max_hp())
	player_mp = clampi(int(parsed.get("player_mp", STARTING_MP)), 0, max_mp())
	potions = clampi(int(parsed["potions"]), 0, 99)
	salve_collected = bool(parsed.get("salve_collected", false))
	cache_opened = bool(parsed.get("cache_opened", false))
	waystone_discovered = bool(parsed.get("waystone_discovered", false))
	in_cave = bool(parsed.get("in_cave", false))
	cave_guardian_defeated = bool(parsed.get("cave_guardian_defeated", false))
	cave_treasure_claimed = bool(parsed.get("cave_treasure_claimed", false))
	if int(save_version) >= 6:
		player.global_position = Vector2(
			clampf(float(parsed["position_x"]), 24.0, WORLD_SIZE.x - 24.0),
			clampf(float(parsed["position_y"]), 24.0, WORLD_SIZE.y - 24.0)
		)
	_update_hero_stats_label()
	return true

func experience_to_next_level() -> int:
	return 60 + (player_level - 1) * 35

func max_hp() -> int:
	return 48 + hero_vitality * 4 + (player_level - 1) * 20

func max_mp() -> int:
	return 6 + hero_spirit * 2 + (player_level - 1) * 6

func _award_experience(amount: int) -> bool:
	player_experience += amount
	var leveled_up := false
	while player_level < 99 and player_experience >= experience_to_next_level():
		player_experience -= experience_to_next_level()
		player_level += 1
		leveled_up = true
	if player_level == 99:
		player_experience = mini(player_experience, experience_to_next_level() - 1)
	_update_hud()
	return leveled_up

func _is_saved_integer(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return is_finite(float(value)) and floorf(float(value)) == float(value)

func _is_saved_number(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return is_finite(float(value))

func _confirm_new_game() -> void:
	if creation_layer.visible or save_load_layer.visible or battle_active or dialogue_active:
		return
	new_game_dialog.popup_centered()

func _start_fresh_game() -> void:
	quest_step = 0
	player_level = 1
	player_experience = 0
	hero_name = DEFAULT_HERO_NAME
	hero_class = DEFAULT_HERO_CLASS
	hero_vitality = 13
	hero_strength = 10
	hero_spirit = 12
	hero_agility = 10
	potions = 0
	gold = 0
	salve_collected = false
	cache_opened = false
	waystone_discovered = false
	in_cave = false
	cave_guardian_defeated = false
	cave_treasure_claimed = false
	encounter_started = false
	battle_active = false
	dialogue_active = false
	dialogue_panel.hide()
	if battle_instance != null:
		battle_instance.queue_free()
		battle_instance = null
	_sync_exploration_markers()
	player.position = Vector2(250, 448)
	_begin_hero_creation()
	_update_hud()
