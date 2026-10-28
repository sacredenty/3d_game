extends Node

class_name Character

# Basic Stats
@export_group("Stats")
var name: String = "Character"
var hp: int = 100
var max_hp: int = 100
var mp: int = 50
var max_mp: int = 50
var atk: float = 10.0
var def: float = 5.0
var mag: float = 8.0

# Elemental Resistances (element -> multiplier)
var resistances: Dictionary = {
	"fire": 1.0,
	"ice": 1.0,
	"lightning": 1.0,
	"wind": 1.0,
	"earth": 1.0,
	"water": 1.0
}

# Equipment slots
var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory": null
}

# Status effects
var status_effects: Array[StatusEffect] = []

# Level and progression
var level: int = 1
var xp: int = 0
var xp_to_next_level: int = 100

signal hp_changed(value: int)
signal mp_changed(value: int)
signal level_up(new_level: int)

func _ready() -> void:
	_update_max_stats()

func take_damage(amount: float, element: String = "neutral") -> float:
	var resistance_mult = resistances.get(element, 1.0)
	var final_damage = amount * resistance_mult
	
	hp -= final_damage
	if hp < 0:
		hp = 0
	hp_changed.emit(hp)
	
	return final_damage

func heal(amount: int) -> void:
	var old_hp = hp
	hp += amount
	if hp > max_hp:
		hp = max_hp
	hp_changed.emit(hp)

func gain_mp(amount: int) -> void:
	mp += amount
	if mp > max_mp:
		mp = max_mp
	mp_changed.emit(mp)

func _update_max_stats() -> void:
	max_hp = calculate_base_stat("hp")
	max_mp = calculate_base_stat("mp")

func calculate_base_stat(stat_name: String) -> int:
	var base_value = 0
	match stat_name:
		"hp":
			base_value = int(atk * 2.5) + level * 10
		"mp":
			base_value = int(mag * 3) + level * 5
	return max(base_value, 1)

func gain_xp(amount: int) -> void:
	xp += amount
	
	while xp >= xp_to_next_level:
		level_up.emit(level + 1)
		level += 1
		xp -= xp_to_next_level
		xp_to_next_level = int(xp_to_next_level * 1.5)

func is_alive() -> bool:
	return hp > 0

func get_turn_order_value() -> float:
	return (atk / def) * 100

# Equipment bonuses
func calculate_equipment_bonus(stat_name: String) -> float:
	var bonus = 0.0
	
	match stat_name:
		"atk":
			if equipment.get("weapon"):
				bonus += equipment["weapon"].bonus_atk
			if equipment.get("accessory"):
				bonus += equipment["accessory"].bonus_atk
		"def":
			if equipment.get("armor"):
				bonus += equipment["armor"].bonus_def
			if equipment.get("accessory"):
				bonus += equipment["accessory"].bonus_def
	
	return bonus

func get_final_stat(stat_name: String) -> float:
	var base = 0.0
	match stat_name:
		"atk":
			base = atk + calculate_equipment_bonus("atk")
		"def":
			base = def + calculate_equipment_bonus("def")
	return max(base, 1.0)

# Serialization for save/load
func to_dict() -> Dictionary:
	return {
		"name": name,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"atk": atk,
		"def": def,
		"mag": mag,
		"resistances": resistances,
		"equipment": equipment,
		"status_effects": [e.to_dict() for e in status_effects],
		"level": level,
		"xp": xp,
		"xp_to_next_level": xp_to_next_level
	}

func from_dict(data: Dictionary) -> void:
	name = data.get("name", "Character")
	hp = data.get("hp", 100)
	max_hp = data.get("max_hp", 100)
	mp = data.get("mp", 50)
	max_mp = data.get("max_mp", 50)
	atk = data.get("atk", 10.0)
	def_ = data.get("def", 5.0)
	mag = data.get("mag", 8.0)
	resistances = data.get("resistances", {})
	equipment = data.get("equipment", {})
	status_effects = [StatusEffect.from_dict(e) for e in data.get("status_effects", [])]
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	xp_to_next_level = data.get("xp_to_next_level", 100)
