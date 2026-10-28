extends Control

class_name DungeonScene

@onready var dungeon_generator: DungeonGenerator = null

var player_position: Vector2i = Vector2i(1, 1)
var exit_room_index: int = -1

func _ready() -> void:
	dungeon_generator = DungeonGenerator.new()
	add_child(dungeon_generator)
	
	# Find exit room
	for i in range(dungeon_generator.rooms.size()):
		if dungeon_generator.rooms[i]["type"] == DungeonGenerator.RoomType.EXIT:
			exit_room_index = i
			break

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		handle_input(event.keycode)

func handle_input(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE:
			get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))
		
		KEY_w, KEY_UP:
			move_player(0, -1)
		KEY_s, KEY_DOWN:
			move_player(0, 1)
		KEY_a, KEY_LEFT:
			move_player(-1, 0)
		KEY_d, KEY_RIGHT:
			move_player(1, 0)

func move_player(dx: int, dy: int) -> void:
	var new_x = player_position.x + dx
	var new_y = player_position.y + dy
	
	if is_valid_position(new_x, new_y):
		player_position.x = new_x
		player_position.y = new_y
		
		check_room_content()

func is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < dungeon_generator.dungeon_width and \
		   y >= 0 and y < dungeon_generator.dungeon_height

func check_room_content() -> void:
	var current_room = get_current_room()
	
	for content in current_room.get("contents", []):
		match content:
			"enemy":
				print("Encounter enemy!")
				get_tree().change_scene_to_packed(preload("res://scenes/combat/battle_scene.tscn"))
			"item":
				print("Found item!")
			"boss":
				print("Boss encounter!")
				get_tree().change_scene_to_packed(preload("res://scenes/combat/boss_scene.tscn"))
			"exit":
				print("Dungeon exit found!")
				get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))

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
