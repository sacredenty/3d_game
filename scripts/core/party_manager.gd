extends Node

class_name PartyManager

const MAX_PARTY_SIZE = 4

@onready var party: Array[Character] = []
var active_character_index: int = -1

signal character_added(character: Character)
signal character_removed(character: Character)
signal active_character_changed(index: int, character: Character)
signal all_characters_dead()

func add_character(char: Character) -> void:
	if party.size() >= MAX_PARTY_SIZE:
		push_warning("Party is full!")
		return
	
	party.append(char)
	character_added.emit(char)
	
	if active_character_index == -1:
		active_character_index = 0

func remove_character(index: int) -> void:
	if index < 0 or index >= party.size():
		return
	
	var removed = party[index]
	party.remove_at(index)
	character_removed.emit(removed)
	
	if active_character_index >= party.size():
		active_character_index = max(0, party.size() - 1)

func set_active_character(index: int) -> void:
	if index < 0 or index >= party.size():
		return
	
	var old_char = get_active_character()
	active_character_index = index
	var new_char = get_active_character()
	
	if old_char != new_char:
		active_character_changed.emit(index, new_char)

func get_active_character() -> Character:
	if active_character_index < 0 or active_character_index >= party.size():
		return null
	return party[active_character_index]

func is_alive(index: int = -1) -> bool:
	var char_to_check = get_active_character() if index == -1 else party[index]
	return char_to_check and char_to_check.is_alive()

func all_dead() -> bool:
	for char in party:
		if char and char.is_alive():
			return false
	return true

func heal_all(amount: int) -> void:
	for i in range(party.size()):
		var char = party[i]
		if char and char.is_alive():
			char.heal(amount)

# Serialization for save/load
func to_dict() -> Dictionary:
	var result = {
		"active_character_index": active_character_index,
		"characters": []
	}
	for char in party:
		result["characters"].append(char.to_dict())
	return result

func from_dict(data: Dictionary) -> void:
	active_character_index = data.get("active_character_index", -1)
	party.clear()
	
	for char_data in data.get("characters", []):
		var char = Character.new()
		char.from_dict(char_data)
		add_character(char)
