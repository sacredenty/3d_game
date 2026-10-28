extends Node

class_name EncounterSystem

const ENCOUNTER_CHANCE = 0.15  # 15% chance per step

@onready var zone_manager: ZoneManager = null

signal encounter_started()
signal encounter_ended(won: bool)

var current_encounter: Array[Enemy] = []

func _ready() -> void:
	zone_manager = ZoneManager.get_instance() if ZoneManager.has_instance() else null

func trigger_random_encounter() -> bool:
	if randf() < ENCOUNTER_CHANCE and zone_manager:
		var enemies = get_random_enemies()
		if not enemies.is_empty():
			current_encounter = enemies
			encounter_started.emit()
			return true
	return false

func get_random_enemies(count: int = 1) -> Array[Enemy]:
	var enemy_names = zone_manager.get_zone_enemies()
	
	enemies.clear()
	for i in range(min(count, enemy_names.size())):
		var enemy_name = enemy_names[randi() % enemy_names.size()]
		enemies.append(Enemy.new())
		setup_enemy(enemy_name, enemies.back())
	
	return enemies

func setup_enemy(name: String, enemy: Enemy) -> void:
	match name.to_lower():
		"slime":
			enemy.name = "Slime"
			enemy.hp = 30
			enemy.max_hp = 30
			enemy.atk = 5.0
			enemy.def = 2.0
			enemy.mag = 1.0
		"rat":
			enemy.name = "Rat"
			enemy.hp = 20
			enemy.max_hp = 20
			enemy.atk = 4.0
			enemy.def = 1.5
			enemy.mag = 1.0
		"wolf":
			enemy.name = "Wolf"
			enemy.hp = 50
			enemy.max_hp = 50
			enemy.atk = 8.0
			enemy.def = 4.0
			enemy.mag = 2.0
		"goblin":
			enemy.name = "Goblin"
			enemy.hp = 35
			enemy.max_hp = 35
			enemy.atk = 6.0
			enemy.def = 3.0
			enemy.mag = 3.0
		"bat":
			enemy.name = "Bat"
			enemy.hp = 25
			enemy.max_hp = 25
			enemy.atk = 7.0
			enemy.def = 1.0
			enemy.mag = 4.0
		"orc":
			enemy.name = "Orc"
			enemy.hp = 80
			enemy.max_hp = 80
			enemy.atk = 12.0
			enemy.def = 6.0
			enemy.mag = 3.0
		"golem":
			enemy.name = "Golem"
			enemy.hp = 150
			enemy.max_hp = 150
			enemy.atk = 8.0
			enemy.def = 12.0
			enemy.mag = 1.0
		"skeleton":
			enemy.name = "Skeleton"
			enemy.hp = 40
			enemy.max_hp = 40
			enemy.atk = 9.0
			enemy.def = 3.5
			enemy.mag = 2.0
		"dark mage":
			enemy.name = "Dark Mage"
			enemy.hp = 60
			enemy.max_hp = 60
			enemy.atk = 4.0
			enemy.def = 3.0
			enemy.mag = 15.0
		"dragon":
			enemy.name = "Dragon"
			enemy.hp = 200
			enemy.max_hp = 200
			enemy.atk = 18.0
			enemy.def = 10.0
			enemy.mag = 20.0

func end_encounter(won: bool) -> void:
	current_encounter.clear()
	encounter_ended.emit(won)
