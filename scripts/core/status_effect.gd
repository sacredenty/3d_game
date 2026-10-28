extends Node

class_name StatusEffect

enum Type { BURN, FREEZE, SHOCK, POISON, SLEEP, HEALING, BUFF }

@export_group("Status Info")
var type: Type = Type.BURN
var duration: int = 0  # Turns remaining
var stack_count: int = 1

@export_group("Effects")
var damage_per_turn: float = 0.0
var heal_per_turn: float = 0.0
var atk_bonus: float = 0.0
var def_bonus: float = 0.0

func to_dict() -> Dictionary:
	return {
		"type": type,
		"duration": duration,
		"stack_count": stack_count,
		"damage_per_turn": damage_per_turn,
		"heal_per_turn": heal_per_turn,
		"atk_bonus": atk_bonus,
		"def_bonus": def_bonus
	}

func from_dict(data: Dictionary) -> void:
	type = Type[data.get("type", 0)]
	duration = data.get("duration", 0)
	stack_count = data.get("stack_count", 1)
	damage_per_turn = data.get("damage_per_turn", 0.0)
	heal_per_turn = data.get("heal_per_turn", 0.0)
	atk_bonus = data.get("atk_bonus", 0.0)
	def_bonus = data.get("def_bonus", 0.0)
