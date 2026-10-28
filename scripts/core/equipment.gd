extends Node

class_name Equipment

enum SlotType { WEAPON, ARMOR, ACCESSORY }

@export_group("Base Stats")
var slot_type: SlotType = SlotType.WEAPON
var name: String = "Item"
var bonus_atk: float = 0.0
var bonus_def: float = 0.0
var bonus_mag: float = 0.0

@export_group("Elemental Properties")
var element_resistance: Dictionary = {
	"fire": 1.0,
	"ice": 1.0,
	"lightning": 1.0,
	"wind": 1.0,
	"earth": 1.0,
	"water": 1.0
}

@export_group("Special Effects")
var special_effects: Array[String] = []

func to_dict() -> Dictionary:
	return {
		"slot_type": slot_type,
		"name": name,
		"bonus_atk": bonus_atk,
		"bonus_def": bonus_def,
		"bonus_mag": bonus_mag,
		"element_resistance": element_resistance,
		"special_effects": special_effects
	}

func from_dict(data: Dictionary) -> void:
	slot_type = SlotType[data.get("slot_type", 0)]
	name = data.get("name", "Item")
	bonus_atk = data.get("bonus_atk", 0.0)
	bonus_def = data.get("bonus_def", 0.0)
	bonus_mag = data.get("bonus_mag", 0.0)
	element_resistance = data.get("element_resistance", {})
	special_effects = data.get("special_effects", [])
