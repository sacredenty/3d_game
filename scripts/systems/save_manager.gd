extends Node

class_name SaveManager

const SAVE_FILE_PATH = "user://savegame.json"

var current_save: Dictionary = {}

func save_game() -> Error:
	var party_data = PartyManager.get_instance().to_dict() if PartyManager.has_instance() else null
	
	current_save = {
		"timestamp": Time.get_ticks_datetime(),
		"party": party_data,
		# Add other game state here (zone, inventory, etc.)
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		return CREATE_ERROR
	
	var json_string = JSON.stringify(current_save)
	file.store_string(json_string)
	file.close()
	
	return OK

func load_game() -> Error:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return FILE_NOT_FOUND_ERROR
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if error != OK or not data:
		return CORRUPT_DATA_ERROR
	
	current_save = data
	
	# Load party
	if "party" in current_save and PartyManager.has_instance():
		PartyManager.get_instance().from_dict(current_save["party"])
	
	return OK

func delete_save() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string("{}")  # Empty JSON to mark as deleted
	file.close()

func get_last_save_time() -> int:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return 0
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if error != OK or "timestamp" not in data:
		return 0
	
	return data["timestamp"]
