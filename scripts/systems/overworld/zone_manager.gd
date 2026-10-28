extends Node

class_name ZoneManager

@export_group("Zone Data")
var zones: Dictionary = {
	"village": {
		"name": "Village of Dawn",
		"description": "A peaceful village at the edge of the forest.",
		"enemies": ["Slime", "Rat"],
		"items": ["Potion", "Herb"],
		"npcs": [
			{"name": "Old Man", "dialogue": "Welcome to our humble village. Be careful in the forest."},
			{"name": "Blacksmith", "dialogue": "I can repair your weapons for a fee."}
		]
	},
	"forest": {
		"name": "Dark Forest",
		"description": "An ancient forest filled with dangerous creatures.",
		"enemies": ["Wolf", "Goblin", "Bat"],
		"items": ["Arrow", "Potion"],
		"npcs": []
	},
	"cave": {
		"name": "Crystal Cave",
		"description": "A dark cave with glowing crystals and hidden treasures.",
		"enemies": ["Bat", "Orc", "Golem"],
		"items": ["Gem", "Gold"],
		"npcs": []
	},
	"castle": {
		"name": "Castle Ruins",
		"description": "The crumbling remains of an ancient castle.",
		"enemies": ["Skeleton", "Dark Mage", "Dragon"],
		"items": ["Sword", "Magic Scroll"],
		"npcs": []
	}
}

var current_zone: String = "village"

signal zone_changed(zone_name: String)

func get_zone_data(zone_name: String) -> Dictionary:
	return zones.get(zone_name, {})

func change_zone(new_zone: String) -> void:
	if new_zone in zones:
		current_zone = new_zone
		zone_changed.emit(new_zone)

func get_zone_enemies() -> Array[String]:
	var zone_data = get_zone_data(current_zone)
	return zone_data.get("enemies", [])

func get_zone_items() -> Array[String]:
	var zone_data = get_zone_data(current_zone)
	return zone_data.get("items", [])

func get_npc_dialogue(npc_name: String) -> String:
	var zone_data = get_zone_data(current_zone)
	for npc in zone_data.get("npcs", []):
		if npc["name"] == npc_name:
			return npc["dialogue"]
	return ""
