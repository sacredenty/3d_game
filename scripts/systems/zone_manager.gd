extends Node

class_name ZoneManager

signal zone_changed(old_zone: String, new_zone: String)

var current_zone: String = "forest"
var zones_data: Dictionary = {}

func _ready() -> void:
	zones_data["forest"] = {
		"name": "Forest",
		"description": "A dense woodland filled with ancient trees and mysterious creatures.",
		"difficulty": 1,
		"encounter_rate": 0.2,
		"color": Color(0.2, 0.6, 0.3)
	}
	zones_data["dungeon"] = {
		"name": "Dungeon",
		"description": "Dark underground corridors teeming with dangerous monsters.",
		"difficulty": 3,
		"encounter_rate": 0.4,
		"color": Color(0.15, 0.15, 0.2)
	}
	zones_data["castle"] = {
		"name": "Castle Ruins",
		"description": "Remains of an ancient fortress, now home to powerful enemies.",
		"difficulty": 5,
		"encounter_rate": 0.6,
		"color": Color(0.3, 0.25, 0.3)
	}

func get_zone_data(zone_name: String) -> Dictionary:
	return zones_data.get(zone_name, {})

func enter_zone(new_zone: String) -> void:
	var old_zone = current_zone
	current_zone = new_zone
	
	if old_zone != new_zone:
		zone_changed.emit(old_zone, new_zone)
		print("Zone changed from", old_zone, "to", new_zone)
