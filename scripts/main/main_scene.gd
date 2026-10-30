extends Node2D

var combat_ui = null
var encounter_system = null
var game_manager = null

const KEY_ESCAPE = 65359
const KEY_E = 69

func _ready() -> void:
	print("=== MainScene._ready() ===")
	
	# Create a simple overworld scene directly (no external scene file)
	var root = Node2D.new()
	root.name = "Overworld"
	add_child(root)
	
	# Add background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(800, 600)
	bg.color = Color(0.15, 0.2, 0.1, 1)
	root.add_child(bg)
	
	# Add player controller
	var player = CharacterBody2D.new()
	player.name = "PlayerController"
	player.position = Vector2(400, 300)
	player.collision_layer = 1
	player.collision_mask = 1
	
	# Attach movement script to player
	var move_script = load("res://scripts/systems/overworld/player_controller.gd")
	if move_script != null:
		player.set_script(move_script)
		print("Attached movement script to player")
	else:
		print("ERROR: Could not load player controller script!")
	
	root.add_child(player)
	
	# Add sprite to player (using a simple ColorRect instead of texture for reliability)
	var sprite = ColorRect.new()
	sprite.name = "Sprite2D"
	sprite.size = Vector2(16, 16)
	sprite.color = Color(0.2, 0.8, 0.2, 1)  # Green player
	player.add_child(sprite)
	print("Added player sprite at", sprite.position, "color:", sprite.color)
	
	# Add OverworldMap node for grid tracking
	var overworld_map = Node2D.new()
	overworld_map.name = "OverworldMap"
	overworld_map.set_script(load("res://scripts/systems/overworld/overworld_map.gd"))
	root.add_child(overworld_map)
	
	await get_tree().process_frame
	
	print("=== After first frame ===")
	if is_instance_valid(sprite):
		print("Player sprite visible at:", sprite.position, "color:", sprite.color)
	else:
		print("ERROR: Player sprite not found!")

	# Create CombatUI as CanvasLayer
	combat_ui = preload("res://scenes/ui/combat_ui.tscn").instantiate()
	combat_ui.name = "CombatUI"
	combat_ui.position = Vector2(10, 50)
	add_child(combat_ui)

	if combat_ui == null:
		print("Warning: Game components not found")
		return

	combat_ui.visible = true
	_setup_input()

func _setup_input() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _start_game_systems() -> void:
	if encounter_system == null or game_manager == null:
		print("Warning: Game autoloads not ready")
		return

func _on_player_moved(new_position: Vector2i) -> void:
	print("Player moved to:", new_position)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		handle_key_event(event.keycode)

func handle_key_event(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		KEY_E:
			print("E key pressed")

func _process(delta):
	if combat_ui != null:
		combat_ui.visible = false
