extends Node

class_name AIEnergy

enum AIBehavior { AGGRESSIVE, DEFENSIVE, BALANCED }

@export_group("AI Behavior")
var ai_behavior: AIBehavior = AIBehavior.BALANCED
var attack_patterns: Array[Dictionary] = []

# Loot table (item -> probability)
var loot_table: Dictionary = {}

func _init() -> void:
	# Default patterns for balanced enemy
	attack_patterns = [
		{"action": "attack", "weight": 60},
		{"action": "magic_fire", "weight": 20},
		{"action": "magic_ice", "weight": 15},
		{"action": "guard", "weight": 5}
	]

func get_action() -> Dictionary:
	var total_weight = 0
	for pattern in attack_patterns:
		total_weight += pattern["weight"]
	
	var random_val = randf() * total_weight
	var cumulative = 0.0
	
	for pattern in attack_patterns:
		cumulative += pattern["weight"]
		if random_val <= cumulative:
			return pattern
	
	return {"action": "attack", "weight": 1}

func take_damage(amount: float, element: String) -> float:
	# Placeholder for AI enemy damage handling
	return 0.0

func add_status_effect(effect_type: String, duration: int) -> void:
	pass

func calculate_drop_rate(item_name: String) -> float:
	return loot_table.get(item_name, 0.0)
