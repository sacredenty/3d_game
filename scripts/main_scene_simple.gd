extends Node2D

func _ready():
	# Create a simple scene with player and background
	var root = Node2D.new()
	root.name = "Game"
	add_child(root)
	
	# Add background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(800, 600)
	bg.color = Color(0.15, 0.2, 0.1, 1)
	root.add_child(bg)
	
	# Add player controller with movement script
	var player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(400, 300)
	player.collision_layer = 1
	player.collision_mask = 1
	
	var move_script = load("res://scripts/player_movement.gd")
	if move_script:
		player.set_script(move_script)
		print("Player movement script attached")
	else:
		print("ERROR: Could not load player script!")
	
	root.add_child(player)
	
	# Add visible sprite to player (green square)
	var sprite = ColorRect.new()
	sprite.name = "Sprite"
	sprite.size = Vector2(16, 16)
	sprite.color = Color(0.2, 0.8, 0.2, 1)
	player.add_child(sprite)
	print("Player sprite added at", sprite.position)
	
	await get_tree().process_frame
	
	if is_instance_valid(sprite):
		print("SUCCESS: Player visible at", sprite.position, "color:", sprite.color)
	else:
		print("ERROR: Player not found!")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
