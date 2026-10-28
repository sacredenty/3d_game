extends Node2D

class_name OverworldMap

enum TileType { GRASS, WATER, TREE, MOUNTAIN, PATH, HOUSE, NPC, ITEM }

@export_group("Map Settings")
var map_width: int = 30
var map_height: int = 20
var tile_size: float = 64.0

# Tile data (type -> list of coordinates)
var tiles: Dictionary = {}
var player_position: Vector2i = Vector2i(15, 10)

signal player_moved(new_position: Vector2i)
signal zone_entered(zone_name: String)

func _ready() -> void:
	generate_default_map()

func generate_default_map() -> void:
	# Clear existing tiles
	tiles.clear()
	
	# Generate grass terrain
	for x in range(map_width):
		for y in range(map_height):
			if is_walkable(x, y):
				add_tile(TileType.GRASS, Vector2i(x, y))
			else:
				add_tile(TileType.MOUNTAIN, Vector2i(x, y))

func add_tile(tile_type: TileType, position: Vector2i) -> void:
	if not tiles.has(tile_type):
		tiles[tile_type] = []
	tiles[tile_type].append(position)

func is_walkable(x: int, y: int) -> bool:
	return x >= 0 and x < map_width and y >= 0 and y < map_height
	
func get_tile_at(x: int, y: int) -> TileType:
	if not tiles.has(TileType.GRASS):
		return TileType.MOUNTAIN
	
	for pos in tiles[TileType.GRASS]:
		if pos.x == x and pos.y == y:
			return TileType.GRASS
	return TileType.WATER

func move_player(dx: int, dy: int) -> bool:
	var new_x = player_position.x + dx
	var new_y = player_position.y + dy
	
	if not is_walkable(new_x, new_y):
		return false
	
	player_position.x = new_x
	player_position.y = new_y
	
	player_moved.emit(player_position)
	
	# Check for zone transitions
	check_zone_transition()
	
	return true

func check_zone_transition() -> void:
	# Simple zone detection based on map regions
	var current_zone = get_current_zone()
	
	if current_zone != "village":
		zone_entered.emit(current_zone)

func get_current_zone() -> String:
	# Define zones by map coordinates
	if player_position.x < 10 and player_position.y > 5:
		return "village"
	elif player_position.x > 20 or player_position.y < 8:
		return "forest"
	elif player_position.y > 15:
		return "cave"
	else:
		return "castle"

func get_player_tile() -> TileType:
	return get_tile_at(player_position.x, player_position.y)

# Get all tiles of a specific type for rendering
func get_tiles_of_type(tile_type: TileType) -> Array[Vector2i]:
	if not tiles.has(tile_type):
		return []
	return tiles[tile_type].duplicate()
