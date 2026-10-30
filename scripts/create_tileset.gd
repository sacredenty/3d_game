extends Node

func _ready():
	create_tileset()

func create_tileset():
	var tileset = TileSet.new()
	tileset.name = "OverworldTileSet"
	
	# Define tile sizes and margins
	tileset.tile_size = Vector2(32, 32)
	tileset.tile_margin_left = 0
	tileset.tile_margin_top = 0
	tileset.tile_margin_right = 0
	tileset.tile_margin_bottom = 0
	
	# Load textures and create tiles
	var grass_texture = load("res://textures/grass.png")
	var dirt_texture = load("res://textures/dirt.png")
	var sand_texture = load("res://textures/sand.png")
	var water_texture = load("res://textures/water.png")
	var cave_wall_texture = load("res://textures/cave_wall.png")
	var bush_texture = load("res://textures/bush.png")
	var fountain_texture = load("res://textures/fountain.png")
	var campfire_texture = load("res://textures/campfire.png")
	var chest_texture = load("res://textures/chest.png")
	var door_texture = load("res://textures/door.png")
	var bridge_texture = load("res://textures/bridge.png")
	
	# Create tiles with their properties
	tileset.add_tile(grass_texture, 0)
	tileset.add_tile(dirt_texture, 1)
	tileset.add_tile(sand_texture, 2)
	tileset.add_tile(water_texture, 3)
	tileset.add_tile(cave_wall_texture, 4)
	tileset.add_tile(bush_texture, 5)
	tileset.add_tile(fountain_texture, 6)
	tileset.add_tile(campfire_texture, 7)
	tileset.add_tile(chest_texture, 8)
	tileset.add_tile(door_texture, 9)
	tileset.add_tile(bridge_texture, 10)
	
	# Save the tileset
	var save_path = "res://textures/tileset.tres"
	tileset.save(save_path)
	print("TileSet saved to: " + save_path)

func _exit_tree():
	pass
