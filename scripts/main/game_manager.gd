extends Node

class_name GameManager

@onready var party_manager: PartyManager = null
@onready var combat_system: CombatSystem = null
@onready var save_manager: SaveManager = null

signal game_started()
signal battle_started()
signal battle_ended(winner: String)
signal zone_changed(new_zone: String)

var current_zone: String = "village"
var is_game_running: bool = false

func _ready() -> void:
	party_manager = PartyManager.new()
	combat_system = CombatSystem.new()
	save_manager = SaveManager.new()
	
	add_child(party_manager)
	add_child(combat_system)
	add_child(save_manager)
	
	# Try to load existing save
	var err = save_manager.load_game()
	if err == OK:
		print("Game loaded from save")

func start_new_game() -> void:
	is_game_running = true
	
	# Create default party
	create_default_party()
	
	game_started.emit()

func create_default_party() -> void:
	var warrior = Character.new()
	warrior.name = "Warrior"
	warrior.atk = 15.0
	warrior.def = 8.0
	warrior.hp = 120
	party_manager.add_character(warrior)
	
	var mage = Character.new()
	mage.name = "Mage"
	mage.mag = 12.0
	mage.mp = 60
	mage.hp = 70
	party_manager.add_character(mage)
	
	var thief = Character.new()
	thief.name = "Thief"
	thief.atk = 12.0
	thief.def = 5.0
	thief.mag = 8.0
	thief.hp = 65
	party_manager.add_character(thief)
	
	var monk = Character.new()
	monk.name = "Monk"
	monk.atk = 14.0
	monk.def = 7.0
	monk.mp = 30
	monk.hp = 90
	party_manager.add_character(monk)

func start_battle(player_chars: Array[Character], enemy_chars: Array[Enemy]) -> void:
	combat_system.start_battle(player_chars, enemy_chars)
	battle_started.emit()

func end_battle(winner: String) -> void:
	combat_system.reset_battle()
	battle_ended.emit(winner)

func change_zone(new_zone: String) -> void:
	current_zone = new_zone
	zone_changed.emit(new_zone)

func save_current_progress() -> Error:
	return save_manager.save_game()
