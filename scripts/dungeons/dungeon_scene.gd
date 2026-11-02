extends Control
class_name DungeonScene

@export var return_save_path: String = "user://greenvale_progress.json"

@onready var dungeon_generator: DungeonGenerator = null
var player_position: Vector2i = Vector2i(1, 1)
var tilemap_layer: TileMapLayer = null
var dungeon_root: Node2D = null
var player_marker: Sprite2D = null
var tile_size: int = 32
var exit_room_index: int = -1

func _ready() -> void:
	dungeon_generator = DungeonGenerator.new()
	add_child(dungeon_generator)
	var exit_button := Button.new()
	exit_button.text = "Exit Dungeon"
	exit_button.position = Vector2(20, 20)
	exit_button.pressed.connect(_return_to_game)
	add_child(exit_button)
	exit_button.grab_focus()
	tilemap_layer = TileMapLayer.new()
	tilemap_layer.tile_set = _make_world_tileset()
	add_child(tilemap_layer)
	dungeon_root = Node2D.new()
	add_child(dungeon_root)
	for i in range(dungeon_generator.rooms.size()):
		if dungeon_generator.rooms[i]["type"] == DungeonGenerator.RoomType.EXIT:
			exit_room_index = i
			break
	render_dungeon()
	_create_player_marker()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		handle_input(event.keycode)

func handle_input(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE, KEY_E:
			_return_to_game()
		KEY_W, KEY_UP:
			move_player(0, -1)
		KEY_S, KEY_DOWN:
			move_player(0, 1)
		KEY_A, KEY_LEFT:
			move_player(-1, 0)
		KEY_D, KEY_RIGHT:
			move_player(1, 0)

func move_player(dx: int, dy: int) -> void:
	var new_pos = player_position + Vector2i(dx, dy)
	if is_valid_position(new_pos.x, new_pos.y):
		player_position = new_pos
		_update_player_marker()
		check_room_content()

func is_valid_position(x: int, y: int) -> bool:
	if x < 0 or x >= dungeon_generator.dungeon_width or y < 0 or y >= dungeon_generator.dungeon_height:
		return false
	return dungeon_generator.floor_grid[y][x]

func render_dungeon() -> void:
	for child in dungeon_root.get_children():
		if child != player_marker:
			child.queue_free()
	tilemap_layer.clear()
	for y in range(dungeon_generator.dungeon_height):
		for x in range(dungeon_generator.dungeon_width):
			if dungeon_generator.floor_grid[y][x]:
				tilemap_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
	if exit_room_index >= 0:
		var exit_room := dungeon_generator.rooms[exit_room_index]
		for rx in range(exit_room["x"], exit_room["x"] + exit_room["width"]):
			for ry in range(exit_room["y"], exit_room["y"] + exit_room["height"]):
				tilemap_layer.set_cell(Vector2i(rx, ry), 0, Vector2i(3, 0))

func check_room_content() -> void:
	var current_room = get_current_room()
	for content in current_room.get("contents", []):
		match content:
			"enemy":
				print("Encounter enemy!")
				_start_combat(false)
			"item":
				print("Found item!")
			"boss":
				print("Boss encounter!")
				_start_combat(true)
			"exit":
				print("Dungeon exit found!")
				_return_to_game()
	for room in dungeon_generator.rooms:
		if room.get("x", -1) == current_room.get("x", -2) and room.get("y", -1) == current_room.get("y", -2):
			room["contents"] = []

var exiting: bool = false

func _return_to_game() -> void:
	if exiting:
		return
	exiting = true
	call_deferred("_do_return_to_game")

func _do_return_to_game() -> void:
	var packed := load("res://scenes/game.tscn")
	if packed == null:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return
	var game_scene: Node = packed.instantiate()
	if game_scene == null:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return
	game_scene.set("initial_mode", "continue")
	game_scene.set("progress_save_path", return_save_path)
	get_tree().root.add_child(game_scene)
	get_tree().current_scene = game_scene
	queue_free()


func _create_player_marker() -> void:
	player_marker = Sprite2D.new()
	player_marker.texture = _load_art_texture("hero_warrior")
	player_marker.scale = Vector2(1.5, 1.5)
	player_marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dungeon_root.add_child(player_marker)
	_update_player_marker()

func _update_player_marker() -> void:
	if player_marker != null:
		player_marker.position = Vector2(player_position.x * tile_size + tile_size * 0.5, player_position.y * tile_size + tile_size * 0.5)


func _make_world_tileset() -> TileSet:
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = _load_art_texture("overworld_atlas")
	atlas_source.texture_region_size = Vector2i(tile_size, tile_size)
	for y in range(2):
		for x in range(4):
			atlas_source.create_tile(Vector2i(x, y))
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)
	tile_set.add_source(atlas_source, 0)
	return tile_set

func _load_art_texture(asset_name: String) -> Texture2D:
	return load("res://assets/art/%s.svg" % asset_name) as Texture2D


func _start_combat(is_boss: bool) -> void:
	var save_data := {}
	var file := FileAccess.open(return_save_path, FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			save_data = parsed
		file.close()
	var battle_scene := preload("res://scenes/battle.tscn").instantiate()
	add_child(battle_scene)
	var enemy_name := "Cave Sentinel" if is_boss else "Forest Shade"
	var enemy_hp := 148 if is_boss else 112
	var enemy_damage := Vector2i(12, 17) if is_boss else Vector2i(10, 15)
	var enemy_xp := 115 if is_boss else 80
	var enemy_color := Color("817f74") if is_boss else Color("647b9a")
	var enemy_weakness := "fire"
	var enemy_intents := PackedStringArray(["Heavy slam", "Stone ward", "Shard throw"]) if is_boss else PackedStringArray(["Heavy strike", "Shadow swipe", "Shadow swipe"])
	battle_scene.connect("finished", _on_dungeon_battle_finished.bind(battle_scene))
	battle_scene.call("start_battle",
		enemy_name, enemy_hp, enemy_damage, enemy_xp, enemy_color,
		enemy_weakness, enemy_intents,
		int(save_data.get("player_hp", 100)), int(save_data.get("player_mp", 30)), int(save_data.get("player_level", 1)), int(save_data.get("potions", 3)),
		str(save_data.get("hero_name", "Adventurer")), str(save_data.get("hero_class", "Warrior")), int(save_data.get("hero_vitality", 13)), int(save_data.get("hero_strength", 10)), int(save_data.get("hero_spirit", 12)), int(save_data.get("hero_agility", 10)),
		0, 0, 0,
		{},
		30 if is_boss else 12
	)

func _on_dungeon_battle_finished(_outcome: String, _hp: int, _mp: int, _potion_count: int, _experience: int, _gold: int, battle_scene: Node) -> void:
	if is_instance_valid(battle_scene):
		battle_scene.queue_free()


func get_current_room() -> Dictionary:
	for room in dungeon_generator.rooms:
		var rx = room["x"]
		var ry = room["y"]
		var rw = room["width"]
		var rh = room["height"]
		if player_position.x >= rx and player_position.x < rx + rw and \
		   player_position.y >= ry and player_position.y < ry + rh:
			return room
	return {}
