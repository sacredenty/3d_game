extends Node

signal zone_changed(old_zone: String, new_zone: String)
signal party_member_joined(member_name: String)
signal party_member_left(member_name: String)

var current_zone: String = "village"
var zones_data: Dictionary = {}
var party_members: Array[Dictionary] = []
var is_in_combat: bool = false
var zone_transition_manager: Node = null

func _ready() -> void:
	# Initialize default zones
	zones_data["village"] = {
		"name": "Village of Dawn",
		"description": "A peaceful village at the edge of the forest.",
		"difficulty": 1,
		"encounter_rate": 0.2
	}
	zones_data["forest"] = {
		"name": "Dark Forest",
		"description": "An ancient forest filled with dangerous creatures.",
		"difficulty": 2,
		"encounter_rate": 0.3
	}
	zones_data["cave"] = {
		"name": "Crystal Cave",
		"description": "A dark cave with glowing crystals and hidden treasures.",
		"difficulty": 3,
		"encounter_rate": 0.4
	}
	zones_data["castle"] = {
		"name": "Castle Ruins",
		"description": "The crumbling remains of an ancient fortress.",
		"difficulty": 4,
		"encounter_rate": 0.5
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
	
	if new_zone in zones_data:
		current_zone = new_zone
		
		# Emit zone change signal with both old and new zone names
		zone_changed.emit(old_zone, new_zone)
		
		print("GameManager: Entered zone '%s' (from '%s')" % [new_zone, old_zone])

func set_in_combat(state: bool) -> void:
	is_in_combat = state
	if not is_in_combat:
		current_zone = "village"  # Reset to village when combat ends
