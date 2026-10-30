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

func new(data: Dictionary) -> Character:
	var char := Character.new()
	char.name = data.get("name", "Player")
	char.char_class = data.get("char_class", "warrior")
	char.level = data.get("level", 1)
	char.attack_power = data.get("attack_power", 10.0)
	char.magic_power = data.get("magic_power", 8.0)
	char.defense = data.get("defense", 3.0)
	char.speed = data.get("speed", 5.0)
	
	var base_hp = get_class_base_hp(char.char_class, char.level)
	char.max_hp = base_hp * (1.0 + randf() * 0.2)
	char.hp = char.max_hp
	
	return char

func get_class_base_hp(class_type: String, lvl: int) -> float:
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
	hp -= actual_dmg
	_is_alive = hp <= 0
	
	print(name, "HP:", roundf(hp), "/", roundf(max_hp))

func heal(amount: float) -> void:
	if not _is_alive:
		return
	
	var old_max = max_hp
	max_hp += amount * 0.5 if level > 1 else amount
	hp = min(hp + amount, max_hp)
	
	print(name, "Healed to", roundf(hp), "/", roundf(max_hp))

func set_defense(new_defense: float) -> void:
	current_defense = new_defense

func get_is_alive() -> bool:
	return hp > 0
