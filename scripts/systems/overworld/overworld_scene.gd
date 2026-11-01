extends Node2D

class_name OverworldScene

@onready var overworld_map: OverworldMap = null
@onready var encounter_system = null
@onready var zone_manager = null
@onready var transition_scene: TransitionScene = null

func _ready() -> void:
	overworld_map = OverworldMap.new()
	add_child(overworld_map)
	encounter_system = get_node_or_null("/root/EncounterSystem")
	zone_manager = get_node_or_null("/root/ZoneManager")
	
	overworld_map.player_moved.connect(_on_player_moved)
	if encounter_system != null:
		encounter_system.encounter_started.connect(_on_encounter_start)
		encounter_system.encounter_ended.connect(_on_encounter_end)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_right"):
		overworld_map.move_player(1, 0)
	elif Input.is_action_just_pressed("move_left"):
		overworld_map.move_player(-1, 0)
	elif Input.is_action_just_pressed("move_up"):
		overworld_map.move_player(0, -1)
	elif Input.is_action_just_pressed("move_down"):
		overworld_map.move_player(0, 1)

func _on_player_moved(new_position: Vector2i) -> void:
	print("Player moved to:", new_position)
	
	if encounter_system != null and encounter_system.trigger_random_encounter():
		start_combat()

func _on_zone_entered(zone_name: String) -> void:
	print("Entered zone:", zone_name)
	
	if zone_manager != null:
		var zone_data = zone_manager.get_zone_data(zone_name)
		print("Zone description:", zone_data.get("description", ""))
		
		show_zone_transition(zone_name, zone_data)

func show_zone_transition(zone_name: String, zone_data: Dictionary) -> void:
	if not is_instance_valid(transition_scene):
		var trans := TransitionScene.new()
		transition_scene = trans
		trans.set_zone_info(zone_name, zone_data.get("description", ""))
		trans.name = "TransitionScene"
		add_child(trans)
		await trans.finished
	
	if has_node("TransitionScene"):
		get_node("TransitionScene").queue_free()

func start_combat() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/combat/battle_scene.tscn"))

func _on_encounter_start() -> void:
	print("Encounter started!")

func _on_encounter_end(won: bool) -> void:
	print("Encounter ended:", "Won!" if won else "Lost!")
	if not won:
		get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))
