extends Node2D

var overworld_map = null
var combat_ui = null
var encounter_system = null
var game_manager = null

func _ready() -> void:
	# Create GameWorld container
	var game_world = Node2D.new()
	game_world.name = "GameWorld"
	add_child(game_world)
	
	# Create Camera2D in GameWorld (uses default offset of Vector2(0, 0))
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	game_world.add_child(camera)
	
	# Create OverworldMap in Camera2D
	var overworld = Node2D.new()
	overworld.name = "OverworldMap"
	camera.add_child(overworld)
	
	# Create CombatUI as CanvasLayer
	combat_ui = preload("res://scenes/ui/combat_ui.tscn").instantiate()
	add_child(combat_ui)
	
	# Initialize game systems
	if overworld_map == null or combat_ui == null:
		print("Warning: Game components not found")
		return
	
	overworld.visible = true
	combat_ui.visible = true
	
	_setup_input()
	
	_start_game_systems()

func _setup_input() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _start_game_systems() -> void:
	if encounter_system == null or game_manager == null:
		print("Warning: Game autoloads not ready")
		return
	
	# Connect encounter system signal for movement
	if overworld_map != null:
		overworld_map.player_moved.connect(_on_player_moved)

func _on_player_moved(new_position: Vector2i) -> void:
	print("Player moved to:", new_position)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		handle_key_event(event.keycode)
	elif event is InputEventMouseMotion:
		pass  # Handle mouse motion if needed

func handle_key_event(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		KEY_E:
			print("E key pressed")
