extends Node2D

class_name Enemy

@export var name: String = "Slime"
@export var enemy_type: String = "slime"
@export var level: int = 1
@export var attack_power: float = 5.0
@export var magic_power: float = 3.0
@export var defense: float = 2.0

var hp: float = 30.0
var max_hp: float = 30.0
var current_defense: float = 2.0
var is_alive: bool = true

func new(data: Dictionary) -> Enemy:
	var enemy := Enemy.new()
	enemy.name = data.get("name", "Slime")
	enemy.enemy_type = data.get("type", "slime")
	enemy.level = data.get("level", 1)
	enemy.attack_power = data.get("attack_power", 5.0)
	enemy.magic_power = data.get("magic_power", 3.0)
	enemy.defense = data.get("defense", 2.0)
	
	var base_hp = get_type_base_hp(enemy.enemy_type, enemy.level)
	enemy.max_hp = base_hp * (1.0 + randf() * 0.2)
	enemy.hp = enemy.max_hp
	
	return enemy

func get_type_base_hp(type: String, lvl: int) -> float:
	match type.to_lower():
		"slime": return 30.0 + (lvl - 1) * 8.0
		"goblin": return 45.0 + (lvl - 1) * 10.0
		"skeleton": return 40.0 + (lvl - 1) * 9.0
		"orc": return 60.0 + (lvl - 1) * 12.0
		"demon": return 70.0 + (lvl - 1) * 15.0
	return 30.0

func take_damage(amount: float) -> void:
	if not is_alive:
		return
	
	var actual_dmg = amount - current_defense if amount > current_defense else 0.0
	hp -= actual_dmg
	is_alive = hp <= 0
	
	print(name, "HP:", roundf(hp), "/", roundf(max_hp))

func take_damage_from_attack(target: Character?) -> void:
	if target == null or not target.is_alive():
		return
	
	var attack_power = target.attack_power * (1.0 + randf() * 0.2) if target.attack_power else 5.0
	take_damage(attack_power)

func use_magic(target: Character?) -> void:
	if target == null or not target.is_alive():
		return
	
	var spell_power = magic_power * 1.8
	take_damage(spell_power)

func heal(amount: float) -> void:
	max_hp += amount * 0.5 if level > 1 else amount
	hp = min(hp + amount, max_hp)
	print(name, "Healed to", roundf(hp), "/", roundf(max_hp))

func set_defense(new_defense: float) -> void:
	current_defense = new_defense

func is_alive() -> bool:
	return hp > 0
