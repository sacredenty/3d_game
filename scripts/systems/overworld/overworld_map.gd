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

@onready var tile_container: Control = $TileContainer if $TileContainer else null
@onready var player_rect: ColorRect = $PlayerRect if $PlayerRect else null
@onready var camera: Camera2D = get_parent().get_node_or_null("Camera2D")

func _ready() -> void:
	generate_default_map()
	_setup_visuals()

func _setup_visuals() -> void:
	if tile_container == null or player_rect == null:
		return
	
	tile_container.visible = true
	player_rect.visible = true
	
	# Create tiles for rendering
	for tile_type in TileType.values():
		var positions = get_tiles_of_type(tile_type)
		clear_tile_layer(tile_type)
		
		for pos in positions:
			create_tile_visual(tile_type, Vector2i(pos.x, pos.y))

func create_tile_visual(tile_type: TileType, position: Vector2i) -> void:
	if tile_container == null or player_rect == null:
		return
	
	var color = get_tile_color(tile_type)
	var rect = ColorRect.new()
	rect.size = Vector2(tile_size, tile_size)
	rect.color = color
	rect.position = Vector2(position.x * tile_size, position.y * tile_size)
	
	tile_container.add_child(rect)

func clear_tile_layer(tile_type: TileType) -> void:
	if tile_container == null or player_rect == null:
		return
	
	for child in tile_container.get_children():
		if child is ColorRect and child.color == get_tile_color(tile_type):
			child.queue_free()

func get_tile_color(tile_type: TileType) -> Color:
	match tile_type:
		TileType.GRASS: return Color(0.35, 0.7, 0.25)
		TileType.WATER: return Color(0.2, 0.4, 0.6)
		TileType.TREE: return Color(0.15, 0.5, 0.1)
		TileType.MOUNTAIN: return Color(0.3, 0.3, 0.4)
		TileType.PATH: return Color(0.6, 0.5, 0.35)
		TileType.HOUSE: return Color(0.7, 0.5, 0.3)
		TileType.NPC: return Color(1.0, 0.8, 0.2)
		TileType.ITEM: return Color(1.0, 0.5, 0.5)
	return Color(0.35, 0.7, 0.25)

func generate_default_map() -> void:
	tiles.clear()
	
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
	
	update_player_visual()
	player_moved.emit(player_position)
	check_zone_transition()
	
	return true

func update_player_visual() -> void:
	if player_rect == null or player_rect.texture == null:
		return
	
	var sprite_pos = Vector2i(player_position.x, player_position.y) * tile_size + Vector2(tile_size / 2, tile_size / 2)
	player_rect.position = sprite_pos

func check_zone_transition() -> void:
	var current_zone = get_current_zone()
	
	if current_zone != "village":
		zone_entered.emit(current_zone)

func get_current_zone() -> String:
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
