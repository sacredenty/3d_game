extends Node

signal zone_entered(zone_name: String)
signal zone_exited(old_zone: String)

var current_zone: String = "village"
var zones_data: Dictionary = {}
var is_loading: bool = false

func _ready() -> void:
	# Initialize with default zone data from ZoneManager
	zones_data = {
		"village": {
			"name": "Village of Dawn",
			"description": "A peaceful village at the edge of the forest.",
			"difficulty": 1,
			"encounter_rate": 0.2,
			"color": Color(0.3, 0.5, 0.3)
		},
		"forest": {
			"name": "Dark Forest",
			"description": "An ancient forest filled with dangerous creatures.",
			"difficulty": 2,
			"encounter_rate": 0.3,
			"color": Color(0.15, 0.25, 0.1)
		},
		"cave": {
			"name": "Crystal Cave",
			"description": "A dark cave with glowing crystals and hidden treasures.",
			"difficulty": 3,
			"encounter_rate": 0.4,
			"color": Color(0.1, 0.12, 0.2)
		},
		"castle": {
			"name": "Castle Ruins",
			"description": "The crumbling remains of an ancient fortress.",
			"difficulty": 4,
			"encounter_rate": 0.5,
			"color": Color(0.12, 0.1, 0.16)
		}
	}

func get_zone_data(zone_name: String) -> Dictionary:
	return zones_data.get(zone_name, {})

func enter_zone(new_zone: String) -> void:
	if new_zone not in zones_data:
		push_error("ZoneManager: Unknown zone '%s'" % new_zone)
		return
	
	is_loading = true
	var transition_scene = preload("res://scenes/ui/zone_transition.tscn")
	
	if transition_scene != null:
		var transition = transition_scene.instantiate()
		add_child(transition)
		
		# Simulate loading progress
		for i in range(100):
			await get_tree().process_frame
			transition.update_progress(float(i + 1) / 100.0)
		
		transition.complete_transition()
		transition.queue_free()
	
	is_loading = false
	
	current_zone = new_zone
	zone_entered.emit(new_zone)

func exit_zone(old_zone: String) -> void:
	if old_zone not in zones_data:
		return
	
	zone_exited.emit(old_zone)

func get_current_zone() -> String:
	return current_zone

func set_current_zone(zone_name: String) -> void:
	current_zone = zone_name
