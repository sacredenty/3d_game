extends Node2D

class_name OverworldScene

@onready var overworld_map: OverworldMap = null
@onready var encounter_system: EncounterSystem = null

func _ready() -> void:
	overworld_map = OverworldMap.new()
	add_child(overworld_map)
	
	encounter_system = EncounterSystem.new()
	add_child(encounter_system)
	
	# Connect signals
	overworld_map.player_moved.connect(_on_player_moved)
	overworld_map.zone_entered.connect(_on_zone_entered)
	encounter_system.encounter_started.connect(_on_encounter_start)
	encounter_system.encounter_ended.connect(_on_encounter_end)

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
	if EncounterSystem.has_instance():
		encounter_system.trigger_random_encounter()

func _on_zone_entered(zone_name: String) -> void:
	print("Entered zone:", zone_name)
	if ZoneManager.has_instance():
		var zone_data = ZoneManager.get_instance().get_zone_data(zone_name)
		print("Zone description:", zone_data.get("description", ""))

func _on_encounter_start() -> void:
	# Switch to battle scene
	get_tree().change_scene_to_packed(preload("res://scenes/combat/battle_scene.tscn"))

func _on_encounter_end(won: bool) -> void:
	print("Encounter ended:", "Won!" if won else "Lost!")
	if not won:
		# Player lost battle - return to overworld
		get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))
