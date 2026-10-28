extends Node2D

class_name DungeonGenerator

enum RoomType { COMBAT, TREASURE, BOSS, EXIT }

@export_group("Dungeon Settings")
var dungeon_width: int = 15
var dungeon_height: int = 10
var room_size: Vector2i = Vector2i(4, 3)
var corridor_width: int = 1

# Generated dungeon data
var rooms: Array[Dictionary] = []
var current_room: Dictionary = {}

func _ready() -> void:
	generate_dungeon()

func generate_dungeon() -> void:
	rooms.clear()
	
	# Start with entrance room
	var start_room = create_room(RoomType.TREASURE, 1, 1)
	rooms.append(start_room)
	current_room = start_room
	
	# Generate rooms until we reach exit area
	while not should_place_exit():
		var next_room = get_next_room()
		if next_room:
			rooms.append(next_room)
			current_room = next_room

func create_room(room_type: RoomType, x: int, y: int) -> Dictionary:
	var room = {
		"type": room_type,
		"x": x,
		"y": y,
		"width": room_size.x,
		"height": room_size.y,
		"contents": []
	}
	
	match room_type:
		RoomType.COMBAT:
			room["contents"].append("enemy")
		RoomType.TREASURE:
			room["contents"].append("item")
		RoomType.BOSS:
			room["contents"].append("boss")
		RoomType.EXIT:
			room["contents"].append("exit")
	
	return room

func get_next_room() -> Dictionary:
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	
	for direction in directions:
		var new_x = current_room["x"] + direction.x * room_size.x
		var new_y = current_room["y"] + direction.y * room_size.y
		
		if can_place_room(new_x, new_y):
			var new_room = create_room(get_random_room_type(), new_x, new_y)
			
			# Create corridor to new room
			create_corridor(current_room["x"], current_room["y"], new_x, new_y)
			
			current_room = new_room
			return new_room
	
	return null

func can_place_room(x: int, y: int) -> bool:
	if x < 0 or y < 0:
		return false
	
	var room_width = room_size.x + corridor_width * 2
	var room_height = room_size.y + corridor_width * 2
	
	for i in range(room_width):
		for j in range(room_height):
			var check_x = x + i
			var check_y = y + j
			
			if not is_valid_position(check_x, check_y):
				return false
	
	return true

func is_valid_position(x: int, y: int) -> bool:
	if x < 0 or x >= dungeon_width or y < 0 or y >= dungeon_height:
		return false
	
	for room in rooms:
		var rx = room["x"]
		var ry = room["y"]
		var rw = room["width"]
		var rh = room["height"]
		
		if x >= rx and x < rx + rw and y >= ry and y < ry + rh:
			return false
	
	return true

func get_random_room_type() -> RoomType:
	var rand = randi() % 100
	
	if rand < 30:
		return RoomType.COMBAT
	elif rand < 60:
		return RoomType.TREASURE
	elif rand < 85:
		return RoomType.EXIT
	else:
		return RoomType.BOSS

func should_place_exit() -> bool:
	var exit_rooms = [r for r in rooms if r["type"] == RoomType.EXIT]
	return exit_rooms.size() > 0

func create_corridor(x1: int, y1: int, x2: int, y2: int) -> void:
	# Horizontal corridor first
	for x in range(min(x1, x2), max(x1, x2) + 1):
		set_tile(x, y1, true)
	
	# Vertical corridor second
	for y in range(min(y1, y2), max(y1, y2) + 1):
		set_tile(x2, y, true)

func set_tile(x: int, y: int, is_floor: bool) -> void:
	# In full implementation, would update tilemap or render data
	pass

func get_room_contents(room_index: int) -> Array:
	if room_index < 0 or room_index >= rooms.size():
		return []
	
	var room = rooms[room_index]
	return room.get("contents", [])
