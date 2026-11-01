extends Node2D

class_name Character

@export var char_class: String = "warrior"
@export var level: int = 1
@export var attack_power: float = 10.0
@export var magic_power: float = 8.0
@export var defense: float = 3.0
@export var speed: float = 5.0

var hp: float = 100.0
var max_hp: float = 100.0
var current_defense: float = 3.0
var _is_alive: bool = true

static func create_from_data(data: Dictionary) -> Character:
	var char := Character.new()
	char.name = data.get("name", "Player")
	char.char_class = data.get("char_class", "warrior")
	char.level = data.get("level", 1)
	char.attack_power = data.get("attack_power", 10.0)
	char.magic_power = data.get("magic_power", 8.0)
	char.defense = data.get("defense", 3.0)
	char.current_defense = data.get("current_defense", char.defense)
	char.speed = data.get("speed", 5.0)
	char.max_hp = data.get("max_hp", get_class_base_hp(char.char_class, char.level))
	char.hp = minf(data.get("hp", char.max_hp), char.max_hp)
	char._is_alive = char.hp > 0.0
	return char

static func get_class_base_hp(class_type: String, lvl: int) -> float:
	match class_type.to_lower():
		"warrior": return 80.0 + (lvl - 1) * 15.0
		"mage": return 60.0 + (lvl - 1) * 12.0
		"thief": return 70.0 + (lvl - 1) * 13.0
		"monk": return 75.0 + (lvl - 1) * 14.0
	return 80.0

func take_damage(amount: float) -> void:
	if not _is_alive:
		return
	
	var actual_dmg = amount - current_defense if amount > current_defense else 0.0
	hp = maxf(hp - actual_dmg, 0.0)
	_is_alive = hp <= 0
	
	print(name, "HP:", roundf(hp), "/", roundf(max_hp))

func heal(amount: float) -> void:
	if not _is_alive:
		return
	
	hp = min(hp + amount, max_hp)
	
	print(name, "Healed to", roundf(hp), "/", roundf(max_hp))

func set_defense(new_defense: float) -> void:
	current_defense = new_defense

func get_is_alive() -> bool:
	return hp > 0

func to_dict() -> Dictionary:
	return {
		"name": name,
		"char_class": char_class,
		"level": level,
		"attack_power": attack_power,
		"magic_power": magic_power,
		"defense": defense,
		"current_defense": current_defense,
		"speed": speed,
		"hp": hp,
		"max_hp": max_hp
	}

func from_dict(data: Dictionary) -> void:
	name = data.get("name", name)
	char_class = data.get("char_class", "warrior")
	level = data.get("level", 1)
	attack_power = data.get("attack_power", 10.0)
	magic_power = data.get("magic_power", 8.0)
	defense = data.get("defense", 3.0)
	current_defense = data.get("current_defense", defense)
	speed = data.get("speed", 5.0)
	max_hp = data.get("max_hp", get_class_base_hp(char_class, level))
	hp = clampf(data.get("hp", max_hp), 0.0, max_hp)
	_is_alive = hp > 0.0
