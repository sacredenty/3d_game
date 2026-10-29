extends Node

class_name EncounterSystem

signal encounter_started()
signal encounter_ended(won: bool)

var current_encounter_data: Dictionary = {}
var is_boss_encounter: bool = false

func get_encounter_data() -> Array[Dictionary]:
	var enemies := []
	
	if is_boss_encounter:
		enemies.append({
			"name": "Dragon Lord",
			"type": "demon",
			"level": 10,
			"attack_power": 25.0,
			"magic_power": 20.0,
			"defense": 8.0
		})
	else:
		var enemy_type = _get_random_enemy()
		enemies.append({
			"name": enemy_type.name,
			"type": enemy_type.type,
			"level": enemy_type.level,
			"attack_power": enemy_type.attack_power,
			"magic_power": enemy_type.magic_power,
			"defense": enemy_type.defense
		})
	
	return enemies

func _get_random_enemy() -> Dictionary:
	var rand = randf()
	if rand < 0.5:
		return {
			"name": "Slime",
			"type": "slime",
			"level": 1 + randi() % 3,
			"attack_power": 4.0 + randi() * 2,
			"magic_power": 2.0 + randi(),
			"defense": 1.5 + randi()
		}
	elif rand < 0.8:
		return {
			"name": "Goblin",
			"type": "goblin",
			"level": 1 + randi() % 3,
			"attack_power": 6.0 + randi() * 2,
			"magic_power": 4.0 + randi(),
			"defense": 2.5 + randi()
		}
	else:
		return {
			"name": "Skeleton",
			"type": "skeleton",
			"level": 1 + randi() % 3,
			"attack_power": 7.0 + randi() * 2,
			"magic_power": 5.0 + randi(),
			"defense": 3.0 + randi()
		}

func trigger_random_encounter() -> bool:
	if EncounterSystem != null and EncounterSystem.is_boss_encounter():
		return false
	
	var encounter_chance = 0.15 if GameManager != null else 0.2
	if randf() < encounter_chance:
		is_boss_encounter = false
		current_encounter_data = get_encounter_data()[0]
		encounter_started.emit()
		return true
	
	return false

func trigger_boss_encounter() -> bool:
	is_boss_encounter = true
	current_encounter_data = {
		"name": "Dragon Lord",
		"type": "demon",
		"level": 10,
		"attack_power": 25.0,
		"magic_power": 20.0,
		"defense": 8.0
	}
	encounter_started.emit()
	return true

func is_boss_encounter() -> bool:
	return is_boss_encounter
