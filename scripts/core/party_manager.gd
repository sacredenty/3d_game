extends Node

const MAX_PARTY_SIZE = 4

var party: Array[Character] = []
var active_character_index: int = -1

signal character_added(character: Character)
signal character_removed(character: Character)
signal active_character_changed(index: int, character: Character)
signal all_characters_dead()

func add_character(char: Character) -> void:
	if party.size() >= MAX_PARTY_SIZE:
		push_warning("Party is full!")
		return
	
	if party.has(char):
		return
	if char.get_parent() == null:
		add_child(char)
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
	if removed.get_parent() == self:
		remove_child(removed)
		removed.queue_free()
	
	if party.is_empty():
		active_character_index = -1
	elif active_character_index > index:
		active_character_index -= 1
	elif active_character_index == index:
		active_character_index = mini(index, party.size() - 1)
		active_character_changed.emit(active_character_index, party[active_character_index])

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
	if index == -1:
		index = active_character_index
	if index < 0 or index >= party.size():
		return false
	return party[index].get_is_alive()

func all_dead() -> bool:
	for char in party:
		if char.get_is_alive():
			return false
	return true

func heal_all(amount: int) -> void:
	for i in range(party.size()):
		var char = party[i]
		if char.get_is_alive():
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
	for char in party:
		if char.get_parent() == self:
			remove_child(char)
			char.free()
	party.clear()
	active_character_index = -1
	
	for char_data in data.get("characters", []):
		var char = Character.create_from_data(char_data)
		add_character(char)

	var saved_index: int = data.get("active_character_index", -1)
	active_character_index = saved_index if saved_index >= 0 and saved_index < party.size() else (-1 if party.is_empty() else 0)
