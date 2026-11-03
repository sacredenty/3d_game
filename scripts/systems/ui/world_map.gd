extends Control

signal zone_selected(zone_name: String)
signal back_to_game_requested()

@onready var village_button = $ZoneContainer/VillageZone
@onready var forest_button = $ZoneContainer/ForestZone
@onready var cave_button = $ZoneContainer/CaveZone
@onready var castle_button = $ZoneContainer/CastleZone
@onready var info_panel = $InfoPanel
@onready var zone_description = $InfoPanel/ZoneDescription
@onready var current_zone_label = $InfoPanel/CurrentZoneLabel
@onready var back_button = $BackButton

var zone_data: Dictionary = {}
var is_open: bool = false

func _ready() -> void:
	# Connect button signals
	village_button.pressed.connect(_on_village_pressed)
	forest_button.pressed.connect(_on_forest_pressed)
	cave_button.pressed.connect(_on_cave_pressed)
	castle_button.pressed.connect(_on_castle_pressed)
	back_button.pressed.connect(_return_to_game)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_M:
				if is_open:
					_close_map()
				get_viewport().set_input_as_handled()
				return

func load_zone_data():
	# Load zone data from ZoneManager autoload
	var zone_manager = get_node_or_null("/root/ZoneManager")
	if zone_manager != null:
		zone_data = {
			"village": {
				"name": "Village of Dawn",
				"description": "A peaceful village at the edge of the forest.",
				"difficulty": 1,
				"enemies": ["Slime", "Rat"],
				"items": ["Potion", "Herb"]
			},
			"forest": {
				"name": "Dark Forest",
				"description": "An ancient forest filled with dangerous creatures.",
				"difficulty": 2,
				"enemies": ["Wolf", "Goblin", "Bat"],
				"items": ["Arrow", "Potion"]
			},
			"cave": {
				"name": "Crystal Cave",
				"description": "A dark cave with glowing crystals and hidden treasures.",
				"difficulty": 3,
				"enemies": ["Bat", "Orc", "Golem"],
				"items": ["Gem", "Gold"]
			},
			"castle": {
				"name": "Castle Ruins",
				"description": "The crumbling remains of an ancient fortress, now home to powerful enemies.",
				"difficulty": 4,
				"enemies": ["Skeleton", "Dark Mage", "Dragon"],
				"items": ["Sword", "Magic Scroll"]
			}
		}

func _open_map():
	is_open = true
	get_viewport().set_input_as_handled()
	info_panel.show()
	current_zone_label.text = "Current Zone: %s" % get_current_zone_name()

func _close_map():
	is_open = false
	info_panel.hide()
	get_viewport().set_input_as_handled()

func get_current_zone_name() -> String:
	var zone_manager = get_node_or_null("/root/ZoneManager")
	if zone_manager != null:
		return zone_manager.current_zone
	return "village"

func _update_info_panel(zone_key: String):
	if zone_data.has(zone_key):
		var data = zone_data[zone_key]
		zone_description.text = data.get("description", "No description")
		current_zone_label.text = "%s (Difficulty: %d)" % [data["name"], data.get("difficulty", 1)]

func _on_village_pressed() -> void:
	if not is_open:
		_open_map()
	else:
		var zone_manager = get_node_or_null("/root/ZoneManager")
		if zone_manager != null:
			zone_manager.change_zone("village")
		zone_selected.emit("village")
		_close_map()

func _on_forest_pressed() -> void:
	if not is_open:
		_open_map()
	else:
		var zone_manager = get_node_or_null("/root/ZoneManager")
		if zone_manager != null:
			zone_manager.change_zone("forest")
		zone_selected.emit("forest")
		_close_map()

func _on_cave_pressed() -> void:
	if not is_open:
		_open_map()
	else:
		var zone_manager = get_node_or_null("/root/ZoneManager")
		if zone_manager != null:
			zone_manager.change_zone("cave")
		zone_selected.emit("cave")
		_close_map()

func _on_castle_pressed() -> void:
	if not is_open:
		_open_map()
	else:
		var zone_manager = get_node_or_null("/root/ZoneManager")
		if zone_manager != null:
			zone_manager.change_zone("castle")
		zone_selected.emit("castle")
		_close_map()

func _return_to_game() -> void:
	back_to_game_requested.emit()
	_close_map()

# Called when returning from world map to main game
func set_current_zone_in_game(zone_name: String) -> void:
	var zone_manager = get_node_or_null("/root/ZoneManager")
	if zone_manager != null:
		zone_manager.set_current_zone(zone_name)
