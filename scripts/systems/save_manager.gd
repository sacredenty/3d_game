extends Node

class_name SaveManager

const SAVE_FILE_PATH = "user://savegame.json"

var current_save: Dictionary = {}

func save_game() -> Error:
	var party_data = PartyManager.to_dict() if PartyManager != null else null
	
	current_save = {
		"timestamp": Time.get_ticks_millis(),
		"party": party_data,
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		return ERR_CANT_OPEN
	
	var json_string = JSON.stringify(current_save)
	file.store_string(json_string)
	file.close()
	
	return OK

func load_game() -> Error:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return ERR_FILE_NOT_FOUND
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if data == null or data == "":
		return ERR_CANT_OPEN
	
	current_save = data
	
	if "party" in current_save and PartyManager != null:
		PartyManager.from_dict(current_save["party"])
	
	return OK

func delete_save() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string("{}")
	file.close()

func get_last_save_time() -> int:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return 0
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	if json_string == "":
		return 0
	
	var data = JSON.parse_string(json_string)
	if data == null or not data.has("timestamp"):
		return 0
	
	return data["timestamp"]

func get_save_data() -> Dictionary:
	return current_save
