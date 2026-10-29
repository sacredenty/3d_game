extends Node

class_name GameManager

signal zone_changed(old_zone: String, new_zone: String)
signal party_member_joined(member_name: String)
signal party_member_left(member_name: String)

var current_zone: String = "forest"
var zones_data: Dictionary = {}
var party_members: Array[Dictionary] = []
var is_in_combat: bool = false

func _ready() -> void:
	# Initialize default zones
	zones_data["forest"] = {
		"name": "Forest",
		"description": "A dense woodland filled with ancient trees and mysterious creatures.",
		"difficulty": 1,
		"encounter_rate": 0.2
	}
	zones_data["dungeon"] = {
		"name": "Dungeon",
		"description": "Dark underground corridors teeming with dangerous monsters.",
		"difficulty": 3,
		"encounter_rate": 0.4
	}
	zones_data["castle"] = {
		"name": "Castle Ruins",
		"description": "Remains of an ancient fortress, now home to powerful enemies.",
		"difficulty": 5,
		"encounter_rate": 0.6
	}

func get_party_members() -> Array[Dictionary]:
	return party_members

func add_member(member_data: Dictionary) -> void:
	if member_data not in party_members:
		party_members.append(member_data)
		party_member_joined.emit(member_data.get("name", "Unknown"))

func remove_member(member_name: String) -> void:
	for i in range(party_members.size()):
		if party_members[i].get("name") == member_name:
			party_members.remove_at(i)
			party_member_left.emit(member_name)
			break

func get_zone_data(zone_name: String) -> Dictionary:
	return zones_data.get(zone_name, {})

func enter_zone(new_zone: String) -> void:
	var old_zone = current_zone
	current_zone = new_zone
	
	if old_zone != new_zone:
		zone_changed.emit(old_zone, new_zone)
		print("Zone changed from", old_zone, "to", new_zone)

func set_in_combat(state: bool) -> void:
	is_in_combat = state
