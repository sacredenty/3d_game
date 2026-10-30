extends Node

class_name EncounterSystem

const ENCOUNTER_CHANCE = 0.15  # 15% chance per step

# ZoneManager is autoload, use directly

signal encounter_started()
signal encounter_ended(won: bool)

var current_encounter: Array[Node] = []

func trigger_random_encounter() -> bool:
	if randf() < ENCOUNTER_CHANCE and ZoneManager:
		var enemies = get_random_enemies()
		if not enemies.is_empty():
			current_encounter = enemies
			encounter_started.emit()
			return true
	return false

func get_random_enemies(count: int = 1) -> Array[Node]:
	var enemy_names = ["slime", "rat", "wolf", "goblin", "bat", "orc", "golem", "skeleton", "dark mage", "dragon"]
	
	current_encounter.clear()
	for i in range(min(count, enemy_names.size())):
		var enemy_name = enemy_names[randi() % enemy_names.size()]
		var new_enemy = Node.new()
		setup_enemy(enemy_name, new_enemy)
		current_encounter.append(new_enemy)
	
	return current_encounter

func setup_enemy(name: String, enemy: Node) -> void:
	match name.to_lower():
		"slime":
			enemy.name = "Slime"
			enemy.hp = 30.0
			enemy.max_hp = 30.0
			enemy.attack_power = 5.0
			enemy.defense = 2.0
			enemy.magic_power = 1.0
		"rat":
			enemy.name = "Rat"
			enemy.hp = 20.0
			enemy.max_hp = 20.0
			enemy.attack_power = 4.0
			enemy.defense = 1.5
			enemy.magic_power = 1.0
		"wolf":
			enemy.name = "Wolf"
			enemy.hp = 50.0
			enemy.max_hp = 50.0
			enemy.attack_power = 8.0
			enemy.defense = 4.0
			enemy.magic_power = 2.0
		"goblin":
			enemy.name = "Goblin"
			enemy.hp = 35.0
			enemy.max_hp = 35.0
			enemy.attack_power = 6.0
			enemy.defense = 3.0
			enemy.magic_power = 3.0
		"bat":
			enemy.name = "Bat"
			enemy.hp = 25.0
			enemy.max_hp = 25.0
			enemy.attack_power = 7.0
			enemy.defense = 1.0
			enemy.magic_power = 4.0
		"orc":
			enemy.name = "Orc"
			enemy.hp = 80.0
			enemy.max_hp = 80.0
			enemy.attack_power = 12.0
			enemy.defense = 6.0
			enemy.magic_power = 3.0
		"golem":
			enemy.name = "Golem"
			enemy.hp = 150.0
			enemy.max_hp = 150.0
			enemy.attack_power = 8.0
			enemy.defense = 12.0
			enemy.magic_power = 1.0
		"skeleton":
			enemy.name = "Skeleton"
			enemy.hp = 40.0
			enemy.max_hp = 40.0
			enemy.attack_power = 9.0
			enemy.defense = 3.5
			enemy.magic_power = 2.0
		"dark mage":
			enemy.name = "Dark Mage"
			enemy.hp = 60.0
			enemy.max_hp = 60.0
			enemy.attack_power = 4.0
			enemy.defense = 3.0
			enemy.magic_power = 15.0
		"dragon":
			enemy.name = "Dragon"
			enemy.hp = 200.0
			enemy.max_hp = 200.0
			enemy.attack_power = 18.0
			enemy.defense = 10.0
			enemy.magic_power = 20.0

func get_encounter_data() -> Array[Dictionary]:
	var enemy_names = ["slime", "rat", "wolf", "goblin", "bat", "orc"]
	var data: Array[Dictionary] = []
	
	for i in range(3):
		var name = enemy_names[randi() % enemy_names.size()]
		data.append({
			"type": name,
			"name": get_enemy_name(name),
			"level": 1 + randi() % 2,
			"attack_power": get_enemy_attack(name),
			"magic_power": get_enemy_magic(name),
			"defense": get_enemy_defense(name)
		})
	
	return data

func get_enemy_name(type: String) -> String:
	match type.to_lower():
		"slime": return "Slime"
		"rat": return "Rat"
		"wolf": return "Wolf"
		"goblin": return "Goblin"
		"bat": return "Bat"
		"orc": return "Orc"
		_: return "Enemy"
	return "Enemy"

func get_enemy_attack(type: String) -> float:
	match type.to_lower():
		"slime": return 5.0
		"rat": return 4.0
		"wolf": return 8.0
		"goblin": return 6.0
		"bat": return 7.0
		"orc": return 12.0
		_: return 5.0
	return 5.0

func get_enemy_magic(type: String) -> float:
	match type.to_lower():
		"slime": return 1.0
		"rat": return 1.0
		"wolf": return 2.0
		"goblin": return 3.0
		"bat": return 4.0
		"orc": return 3.0
		_: return 1.0
	return 1.0

func get_enemy_defense(type: String) -> float:
	match type.to_lower():
		"slime": return 2.0
		"rat": return 1.5
		"wolf": return 4.0
		"goblin": return 3.0
		"bat": return 1.0
		"orc": return 6.0
		_: return 2.0
	return 2.0

func get_is_boss_encounter() -> bool:
	return false

func end_encounter(won: bool) -> void:
	current_encounter.clear()
	encounter_ended.emit(won)
