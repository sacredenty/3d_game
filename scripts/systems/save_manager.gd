extends Node

const SAVE_FILE_PATH = "user://savegame.json"

var current_save: Dictionary = {}

func save_game() -> Error:
	var party_manager = get_node_or_null("/root/PartyManager")
	var party_data = party_manager.to_dict() if party_manager != null else null
	
	current_save = {
		"timestamp": Time.get_ticks_msec(),
		"party": party_data,
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	
	var json_string = JSON.stringify(current_save)
	file.store_string(json_string)
	file.close()
	
	return OK

func load_game() -> Error:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return ERR_FILE_NOT_FOUND
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return FileAccess.get_open_error()
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if not data is Dictionary:
		return ERR_PARSE_ERROR
	
	current_save = data
	
	var party_manager = get_node_or_null("/root/PartyManager")
	if current_save.get("party") is Dictionary and party_manager != null:
		party_manager.from_dict(current_save["party"])
	
	return OK

func delete_save() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Unable to delete save data: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string("{}")
	file.close()

func get_last_save_time() -> int:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return 0
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return 0
	var json_string = file.get_as_text()
	file.close()
	
	if json_string == "":
		return 0
	
	var data = JSON.parse_string(json_string)
	if not data is Dictionary or not data.has("timestamp"):
		return 0
	
	return data["timestamp"]

func get_save_data() -> Dictionary:
	return current_save
