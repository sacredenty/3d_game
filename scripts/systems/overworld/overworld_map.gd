extends Node2D

class_name OverworldMap

signal player_moved(new_position: Vector2i)
# signal zone_entered(zone_name: String)  # Removed unused signal

var player_position: Vector2i = Vector2i(1, 1)
var current_zone: String = "forest"
var map_size: Vector2i = Vector2i(8, 6)
var tiles_data: Dictionary = {}
var tile_size: int = 32
var player_sprite: Node2D = null  # Changed to regular var for flexibility
var npc_sprite: Node2D = null

func _process(delta):
	if is_instance_valid(player_sprite):
		var x = player_position.x * tile_size + tile_size / 2
		var y = player_position.y * tile_size + tile_size / 2
		player_sprite.position = Vector2(x, y)
	
	if is_instance_valid(npc_sprite):
		var x = target_npc_position.x * tile_size + tile_size / 2
		var y = target_npc_position.y * tile_size + tile_size / 2
		npc_sprite.position = Vector2(x, y)

func _ready() -> void:
	print("=== OverworldMap._ready() START ===")
	create_background()
	find_player_sprite()
	find_npc_sprite()
	
	for x in range(map_size.x):
		for y in range(map_size.y):
			var key = str(x, ",", y)
			if not tiles_data.has(key):
				tiles_data[key] = get_terrain_type(x, y)

func find_player_sprite():
	# Search from root since nodes are created dynamically
	var player = get_node_or_null("/root/MainScene/Overworld/PlayerController")
	if is_instance_valid(player):
		player_sprite = player.get_node_or_null("Sprite2D")
		if is_instance_valid(player_sprite):
			print("OverworldMap: Found player sprite at", player_sprite.position)
		else:
			print("ERROR: OverworldMap: Sprite2D not found in PlayerController!")

func find_npc_sprite():
	var npc = get_node_or_null("/root/MainScene/Overworld/NPCController")
	if is_instance_valid(npc):
		npc_sprite = npc.get_node_or_null("Sprite2D")
		if is_instance_valid(npc_sprite):
			print("OverworldMap: Found NPC sprite at", npc_sprite.position)
		else:
			print("ERROR: OverworldMap: Sprite2D not found in NPCController!")

var target_npc_position: Vector2i = Vector2i(1, 1)

func create_background():
	var bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.size = Vector2(800, 600)
	bg_rect.color = Color(0.15, 0.2, 0.1)
	add_child(bg_rect)

func move_player(dx: int, dy: int) -> void:
	var old_x = player_position.x
	var old_y = player_position.y
	
	player_position.x += dx
	player_position.y += dy
	
	player_position.x = clampi(player_position.x, 0, map_size.x - 1)
	player_position.y = clampi(player_position.y, 0, map_size.y - 1)
	
	var new_key = str(player_position.x, ",", player_position.y)
	var old_key = str(old_x, ",", old_y)
	
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
