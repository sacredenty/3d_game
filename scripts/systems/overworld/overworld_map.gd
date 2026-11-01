extends Node2D

class_name OverworldMap

signal player_moved(new_position: Vector2i)
# signal zone_entered(zone_name: String)  # Removed unused signal

var player_position: Vector2i = Vector2i(1, 1)
var current_zone: String = "forest"
var map_size: Vector2i = Vector2i(8, 6)
var tiles_data: Dictionary = {}
var tile_size: int = 32
func _ready() -> void:
	print("=== OverworldMap._ready() START ===")
	
	for x in range(map_size.x):
		for y in range(map_size.y):
			var key = str(x, ",", y)
			if not tiles_data.has(key):
				tiles_data[key] = get_terrain_type(x, y)

var target_npc_position: Vector2i = Vector2i(1, 1)

func move_player(dx: int, dy: int) -> void:
	var old_position := player_position
	
	player_position.x += dx
	player_position.y += dy
	
	player_position.x = clampi(player_position.x, 0, map_size.x - 1)
	player_position.y = clampi(player_position.y, 0, map_size.y - 1)
	if player_position == old_position:
		return
	
	var new_key = str(player_position.x, ",", player_position.y)
	var old_key = str(old_position.x, ",", old_position.y)
	
	if tiles_data.has(new_key):
		tiles_data[new_key] = "grass"
	if tiles_data.has(old_key):
		tiles_data[old_key] = "dirt"
	
	player_moved.emit(player_position)
	
	# Update NPC target position when player moves
	target_npc_position.x = clampi(target_npc_position.x + dx, 0, map_size.x - 1)
	target_npc_position.y = clampi(target_npc_position.y + dy, 0, map_size.y - 1)

func get_terrain_type(x: int, _y: int) -> String:
	return "grass" if x > 2 else "dirt"
