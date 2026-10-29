extends Node2D

class_name OverworldScene

@onready var overworld_map: OverworldMap = null
@onready var encounter_system: EncounterSystem = null
@onready var zone_manager: ZoneManager = null

func _ready() -> void:
	overworld_map = OverworldMap.new()
	add_child(overworld_map)
	
	# Connect signals
	overworld_map.player_moved.connect(_on_player_moved)
	overworld_map.zone_entered.connect(_on_zone_entered)

func _process(delta: float) -> void:
	# Handle keyboard input for movement
	if Input.is_action_pressed("move_right"):
		overworld_map.move_player(1, 0)
	elif Input.is_action_pressed("move_left"):
		overworld_map.move_player(-1, 0)
	elif Input.is_action_pressed("move_up"):
		overworld_map.move_player(0, -1)
	elif Input.is_action_pressed("move_down"):
		overworld_map.move_player(0, 1)

func _on_player_moved(new_position: Vector2i) -> void:
	print("Player moved to:", new_position)
	
	# Check for random encounter (ZoneManager is autoloaded)
	if EncounterSystem != null and EncounterSystem.trigger_random_encounter():
		start_combat()

func _on_zone_entered(zone_name: String) -> void:
	print("Entered zone:", zone_name)
	if ZoneManager != null:
		var zone_data = ZoneManager.get_zone_data(zone_name)
		print("Zone description:", zone_data.get("description", ""))

func start_combat() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/combat/battle_scene.tscn"))

func _on_encounter_end(won: bool) -> void:
	print("Encounter ended:", "Won!" if won else "Lost!")
	if not won:
		# Player lost battle - return to overworld
		get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))
