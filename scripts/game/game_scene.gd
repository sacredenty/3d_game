extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/systems/overworld/player_controller.gd")
const WORLD_SIZE := Vector2(1600.0, 960.0)
const TILE_SIZE := 32
const VILLAGE_EDGE := 640.0
const FOREST_GATE := 720.0
const CLEARING_POSITION := Vector2(1330.0, 448.0)
const PLAYER_MAX_HP := 100
const ENEMY_MAX_HP := 112
const PROGRESS_SAVE_PATH := "user://greenvale_progress.json"
const SAVE_VERSION := 2
const STARTING_MP := 30

var player: CharacterBody2D
var npc: StaticBody2D
var world_tiles: TileMapLayer
var tree_positions: Array[Vector2] = []
var tree_texture: Texture2D
var quest_step: int = 0
var dialogue_lines: Array[String] = []
var dialogue_index: int = 0
var dialogue_active: bool = false
var battle_active: bool = false
var battle_won: bool = false
var battle_fled: bool = false
var encounter_started: bool = false
var player_hp: int = PLAYER_MAX_HP
var player_mp: int = STARTING_MP
var player_level: int = 1
var player_experience: int = 0
var enemy_hp: int = ENEMY_MAX_HP
var potions: int = 1
var gold: int = 0
var guarding: bool = false
var progress_save_path: String = PROGRESS_SAVE_PATH

var hud_layer: CanvasLayer
var objective_label: Label
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
var battle_overlay: ColorRect
var battle_player_status: Label
var enemy_hp_bar: ProgressBar
var battle_log: Label
var potion_button: Button
var magic_button: Button
var battle_result_button: Button
var new_game_button: Button
var new_game_dialog: ConfirmationDialog

func _ready() -> void:
	_build_world()
	_build_player()
	_build_npc()
	_build_interface()
	load_progress(progress_save_path)
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

func _is_path_position(position: Vector2) -> bool:
	if position.x < 1140.0 and position.y > 368.0 and position.y < 544.0:
		return true
	return position.distance_to(CLEARING_POSITION) < 150.0

func _is_building_position(position: Vector2) -> bool:
	return Rect2(72, 120, 224, 220).has_point(position) \
		or Rect2(360, 165, 192, 180).has_point(position) \
		or Rect2(296, 328, 102, 82).has_point(position)

func _add_rect_obstacle(position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = position
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

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
			if position.distance_to(CLEARING_POSITION) < 128.0:
				source = Vector2i(2, 1) if position.distance_to(CLEARING_POSITION) < 82.0 else Vector2i(3, 0)
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

func _make_shade_texture() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_pixel(image, 9, 6, 14, 3, Color("303b52"))
	_pixel(image, 5, 9, 22, 14, Color("485774"))
	_pixel(image, 8, 6, 16, 3, Color("647b9a"))
	_pixel(image, 3, 13, 5, 10, Color("485774"))
	_pixel(image, 24, 11, 5, 12, Color("485774"))
	_pixel(image, 7, 23, 18, 5, Color("37435d"))
	_pixel(image, 9, 27, 4, 4, Color("a8a4c7"))
	_pixel(image, 19, 27, 4, 4, Color("a8a4c7"))
	_pixel(image, 10, 13, 4, 3, Color("f3d987"))
	_pixel(image, 19, 13, 4, 3, Color("f3d987"))
	_pixel(image, 11, 14, 2, 2, Color("fff3bf"))
	_pixel(image, 20, 14, 2, 2, Color("fff3bf"))
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

	var hud := _make_panel(screen, Rect2(18, 18, 474, 174))
	var hud_content := VBoxContainer.new()
	hud_content.add_theme_constant_override("separation", 6)
	hud.add_child(hud_content)
	var title := _make_label("CHRONO CHRONICLES  /  GREENVALE", 18, Color("f4e3b8"))
	hud_content.add_child(title)
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
	new_game_button.custom_minimum_size = Vector2(74, 28)
	new_game_button.add_theme_font_size_override("font_size", 12)
	new_game_button.pressed.connect(_confirm_new_game)
	new_game_button.hide()
	stats.add_child(new_game_button)

	var progression := HBoxContainer.new()
	progression.add_theme_constant_override("separation", 8)
	hud_content.add_child(progression)
	progression_label = _make_label("", 13, Color("f3d890"))
	progression.add_child(progression_label)
	experience_bar = _make_bar(Color("d4a84e"))
	experience_bar.custom_minimum_size = Vector2(230, 14)
	progression.add_child(experience_bar)

	var controls := _make_panel(screen, Rect2(744, 18, 212, 76))
	var controls_label := _make_label("WASD / Arrows  Move\nE  Talk  ·  1-5 Battle", 14, Color("e8eddb"))
	controls.add_child(controls_label)

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

	_build_battle_interface(screen)
	new_game_dialog = ConfirmationDialog.new()
	new_game_dialog.title = "Start a new game?"
	new_game_dialog.dialog_text = "This will replace your saved Greenvale progress."
	new_game_dialog.ok_button_text = "Start New Game"
	new_game_dialog.confirmed.connect(_start_fresh_game)
	screen.add_child(new_game_dialog)
	_update_hud()

func _build_battle_interface(screen: Control) -> void:
	battle_overlay = ColorRect.new()
	battle_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_overlay.color = Color(0.03, 0.06, 0.08, 0.82)
	battle_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(battle_overlay)
	battle_overlay.hide()

	var panel := _make_panel(battle_overlay, Rect2(160, 76, 640, 448))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	panel.add_child(content)
	content.add_child(_make_label("A WILD SHADE APPEARS", 20, Color("f3d890")))
	battle_player_status = _make_label("", 14, Color("c1d0c0"))
	battle_player_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(battle_player_status)
	var enemy_sprite := TextureRect.new()
	enemy_sprite.texture = _make_shade_texture()
	enemy_sprite.custom_minimum_size = Vector2(72, 72)
	enemy_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	enemy_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(enemy_sprite)
	var enemy_title := _make_label("SHADE  ·  80 XP", 14, Color("d7c8e8"))
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(enemy_title)
	enemy_hp_bar = _make_bar(Color("d16c62"))
	enemy_hp_bar.custom_minimum_size.y = 22
	content.add_child(enemy_hp_bar)
	battle_log = _make_label("The shade blocks the path.", 15, Color("fff0d0"))
	battle_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_log.custom_minimum_size.y = 44
	content.add_child(battle_log)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	var attack_button := _make_button("Attack")
	attack_button.custom_minimum_size.x = 116
	attack_button.pressed.connect(_attack)
	actions.add_child(attack_button)
	magic_button = _make_button("Magic (8 MP)")
	magic_button.custom_minimum_size.x = 116
	magic_button.pressed.connect(_cast_magic)
	actions.add_child(magic_button)
	var guard_button := _make_button("Guard")
	guard_button.custom_minimum_size.x = 116
	guard_button.pressed.connect(_guard)
	actions.add_child(guard_button)
	potion_button = _make_button("Potion (1)")
	potion_button.custom_minimum_size.x = 116
	potion_button.pressed.connect(_use_potion)
	actions.add_child(potion_button)
	var flee_button := _make_button("Flee")
	flee_button.custom_minimum_size.x = 116
	flee_button.pressed.connect(_flee)
	actions.add_child(flee_button)

	battle_result_button = _make_button("Return to the village")
	battle_result_button.pressed.connect(_leave_battle)
	battle_result_button.hide()
	content.add_child(battle_result_button)

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
		_start_battle()

func _unhandled_input(event: InputEvent) -> void:
	if battle_active and event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A, KEY_1:
				_attack()
			KEY_M, KEY_2:
				_cast_magic()
			KEY_G, KEY_3:
				_guard()
			KEY_P, KEY_4:
				_use_potion()
			KEY_F, KEY_5, KEY_ESCAPE:
				_flee()
			_:
				return
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and not event.is_echo() and not battle_active:
		if dialogue_active:
			_advance_dialogue()
		elif player.global_position.distance_to(npc.global_position) < 76.0:
			_talk_to_mira()
		get_viewport().set_input_as_handled()

func _update_prompt() -> void:
	if battle_active or dialogue_active:
		prompt_panel.hide()
		return
	if player.global_position.distance_to(npc.global_position) < 76.0:
		prompt_label.text = "E  Talk to Mira"
		prompt_panel.show()
	elif quest_step == 1 and player.global_position.distance_to(CLEARING_POSITION) < 210.0:
		prompt_label.text = "The forest clearing is just ahead..."
		prompt_panel.show()
	else:
		prompt_panel.hide()

func _talk_to_mira() -> void:
	if quest_step == 0:
		dialogue_lines = [
			"Mira: The forest path has gone quiet. Something has driven the shades out of the old clearing.",
			"Could you check the clearing east of here? Take this potion. I will keep the village safe."
		]
		quest_step = 1
		potions = 1
		var save_error := save_progress(progress_save_path)
		if save_error != OK:
			push_error("Could not save Greenvale progress: %s" % error_string(save_error))
	elif quest_step == 1:
		dialogue_lines = ["Mira: Follow the dirt path east. The clearing is beyond the old gate."]
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

func _start_battle() -> void:
	encounter_started = true
	battle_active = true
	battle_won = false
	battle_fled = false
	enemy_hp = ENEMY_MAX_HP
	player.set("movement_enabled", false)
	battle_log.text = "A shade lunges from the trees! Choose an action."
	battle_result_button.hide()
	_set_battle_actions_visible(true)
	battle_overlay.show()
	_update_battle_hud()

func _attack() -> void:
	if not battle_active:
		return
	var damage := randi_range(18, 25) + (player_level - 1) * 3
	enemy_hp = maxi(enemy_hp - damage, 0)
	_log_player_action("You attack for %d damage." % damage)
	_update_battle_hud()
	if enemy_hp == 0:
		_finish_battle(true)
	else:
		_enemy_turn()

func _cast_magic() -> void:
	if not battle_active or player_mp < 8:
		return
	player_mp -= 8
	var damage := 34 + (player_level - 1) * 4
	enemy_hp = maxi(enemy_hp - damage, 0)
	_log_player_action("You cast Ember for %d damage. (-8 MP)" % damage)
	_update_battle_hud()
	_update_hud()
	if enemy_hp == 0:
		_finish_battle(true)
	else:
		_enemy_turn()

func _guard() -> void:
	if not battle_active:
		return
	guarding = true
	_log_player_action("You guard. The next hit will be reduced.")
	_enemy_turn()

func _use_potion() -> void:
	if not battle_active or potions <= 0 or player_hp >= max_hp():
		return
	var restored := mini(35, max_hp() - player_hp)
	player_hp += restored
	potions -= 1
	_log_player_action("You use a potion and recover %d HP." % restored)
	_update_battle_hud()
	_enemy_turn()

func _log_player_action(message: String) -> void:
	battle_log.text = message
	_update_battle_hud()

func _flee() -> void:
	if not battle_active:
		return
	battle_active = false
	battle_fled = true
	_set_battle_actions_visible(false)
	battle_log.text = "You retreat from the shade. Your quest is still waiting."
	battle_result_button.text = "Retreat to the village"
	battle_result_button.show()

func _enemy_turn() -> void:
	var damage := randi_range(10, 15) + (player_level - 1) * 2
	if guarding:
		damage = ceili(damage * 0.4)
		guarding = false
	player_hp = maxi(player_hp - damage, 0)
	battle_log.text += "\nThe shade attacks for %d damage." % damage
	_update_battle_hud()
	_update_hud()
	if player_hp == 0:
		_finish_battle(false)

func _finish_battle(victory: bool) -> void:
	battle_active = false
	battle_won = victory
	_set_battle_actions_visible(false)
	if victory:
		battle_log.text = "The shade dissolves into the forest light!"
		battle_result_button.text = "Return to the village"
		var leveled_up := _award_experience(80)
		battle_log.text += "\nYou earned 80 XP."
		if leveled_up:
			battle_log.text += " Level up! You are now level %d." % player_level
	else:
		battle_log.text = "You were defeated. Mira will help you recover."
		battle_result_button.text = "Recover at the village"
	battle_result_button.show()

func _leave_battle() -> void:
	battle_overlay.hide()
	if battle_won:
		quest_step = 2
		gold += 75
	elif battle_fled:
		encounter_started = false
		player.position = Vector2(560, 448)
	else:
		player_hp = max_hp()
		player_mp = max_mp()
		encounter_started = false
		player.position = Vector2(250, 448)
	battle_fled = false
	player.set("movement_enabled", true)
	var save_error := save_progress(progress_save_path)
	if save_error != OK:
		push_error("Could not save Greenvale progress: %s" % error_string(save_error))
	_update_hud()
	if battle_won:
		_show_completion_message()

func _show_completion_message() -> void:
	dialogue_lines = ["Mira: You made it back! Here is 75 gold for helping our village."]
	dialogue_index = 0
	dialogue_active = true
	dialogue_panel.show()
	_show_dialogue_line()

func _set_battle_actions_visible(visible: bool) -> void:
	var actions := battle_overlay.get_node_or_null("PanelContainer/VBoxContainer/HBoxContainer")
	if actions != null:
		actions.visible = visible

func _update_hud() -> void:
	if objective_label == null:
		return
	match quest_step:
		0:
			objective_label.text = "Objective: Speak with Mira near the village gate."
		1:
			objective_label.text = "Objective: Follow the eastern path and clear the forest clearing."
		_:
			objective_label.text = "Quest complete: The forest path is safe. Explore Greenvale!"
	hp_bar.value = float(player_hp) / float(max_hp()) * 100.0
	mp_bar.value = float(player_mp) / float(max_mp()) * 100.0
	progression_label.text = "LV %d  ·  %d / %d XP" % [player_level, player_experience, experience_to_next_level()]
	experience_bar.value = float(player_experience) / float(experience_to_next_level()) * 100.0
	gold_label.text = "%d G" % gold
	new_game_button.visible = quest_step >= 2
	if battle_player_status != null:
		battle_player_status.text = "YOU  ·  LV %d  ·  HP %d/%d  ·  MP %d/%d" % [
			player_level, player_hp, max_hp(), player_mp, max_mp()
		]

func _update_battle_hud() -> void:
	enemy_hp_bar.value = float(enemy_hp) / ENEMY_MAX_HP * 100.0
	potion_button.text = "Potion (%d)" % potions
	potion_button.disabled = potions <= 0 or player_hp >= max_hp()
	magic_button.disabled = player_mp < 8
	magic_button.text = "Magic (%d MP)" % 8 if player_mp >= 8 else "Magic (need MP)"

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
		"potions": potions
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

	quest_step = clampi(int(parsed["quest_step"]), 0, 2)
	gold = maxi(int(parsed["gold"]), 0)
	player_level = clampi(int(parsed.get("player_level", 1)), 1, 99)
	player_experience = maxi(int(parsed.get("player_experience", 0)), 0)
	player_hp = clampi(int(parsed["player_hp"]), 1, max_hp())
	player_mp = clampi(int(parsed.get("player_mp", STARTING_MP)), 0, max_mp())
	potions = clampi(int(parsed["potions"]), 0, 99)
	return true

func experience_to_next_level() -> int:
	return 60 + (player_level - 1) * 35

func max_hp() -> int:
	return PLAYER_MAX_HP + (player_level - 1) * 20

func max_mp() -> int:
	return STARTING_MP + (player_level - 1) * 6

func _award_experience(amount: int) -> bool:
	player_experience += amount
	var leveled_up := false
	while player_level < 99 and player_experience >= experience_to_next_level():
		player_experience -= experience_to_next_level()
		player_level += 1
		player_hp = max_hp()
		player_mp = max_mp()
		leveled_up = true
	if player_level == 99:
		player_experience = mini(player_experience, experience_to_next_level() - 1)
	_update_hud()
	return leveled_up

func _is_saved_integer(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return is_finite(float(value)) and floorf(float(value)) == float(value)

func _confirm_new_game() -> void:
	new_game_dialog.popup_centered()

func _start_fresh_game() -> void:
	quest_step = 0
	player_level = 1
	player_experience = 0
	player_hp = max_hp()
	player_mp = max_mp()
	potions = 0
	gold = 0
	encounter_started = false
	battle_active = false
	battle_won = false
	battle_fled = false
	dialogue_active = false
	dialogue_panel.hide()
	battle_overlay.hide()
	player.position = Vector2(250, 448)
	var save_error := save_progress(progress_save_path)
	if save_error != OK:
		push_error("Could not save new-game progress: %s" % error_string(save_error))
	_update_hud()
