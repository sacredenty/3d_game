extends Node

signal encounter_started(enemy_data: Dictionary)
signal encounter_ended(result: String)  # "victory", "defeat", "flee"

var current_zone: String = ""
var zone_encounter_rates: Dictionary = {
	"village": 0.1,   # 10% chance per step
	"forest": 0.25,   # 25% chance per step
	"cave": 0.4,     # 40% chance per step
	"castle": 0.5    # 50% chance per step
}

var zone_enemy_pools: Dictionary = {
	"village": ["Slime", "Rat"],
	"forest": ["Wolf", "Goblin", "Bat"],
	"cave": ["Bat", "Orc", "Golem"],
	"castle": ["Skeleton", "Dark Mage", "Dragon"]
}

var current_encounter: Dictionary = {}
var is_in_combat: bool = false

func _ready() -> void:
	pass

func set_current_zone(zone_name: String) -> void:
	current_zone = zone_name

func check_random_encounter() -> bool:
	if not current_zone or not zone_encounter_rates.has(current_zone):
		return false
	
	var rate = zone_encounter_rates[current_zone]
	var roll = randf()
	
	print("EncounterSystem: Zone %s, Roll %.2f, Rate %.2f" % [current_zone, roll, rate])
	
	if roll < rate:
		spawn_random_enemy()
		return true
	
	return false

func spawn_random_enemy() -> void:
	var enemies = zone_enemy_pools.get(current_zone, ["Slime"])
	var enemy_name = enemies[randi() % enemies.size()]
	
	current_encounter = {
		"name": enemy_name,
		"zone": current_zone,
		"spawned_at": Time.get_ticks_msec()
	}
	
	is_in_combat = true
	encounter_started.emit(current_encounter)

func end_encounter(result: String) -> void:
	is_in_combat = false
	current_encounter = {}
	encounter_ended.emit(result)

func get_current_zone() -> String:
	return current_zone

func is_fighting() -> bool:
	return is_in_combat
