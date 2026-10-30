extends Node

class_name CombatSystem

signal turn_changed(actor_name: String)
signal battle_won()
signal battle_lost()
signal enemy_turn_started(enemy_name: String)
signal player_turn_started(player_name: String)

var current_enemy: Dictionary = {}
var is_combat_active: bool = false
var is_player_turn: bool = true
var battle_ended: bool = false
var turn_count: int = 0
var combat_ui: Control = null

const DEFAULT_ENEMY_HP = 50.0
const DEFAULT_ENEMY_ATTACK = 8.0
const DEFAULT_ENEMY_MAGIC = 3.0
const DEFAULT_ENEMY_DEFENSE = 2.0

func _ready() -> void:
	combat_ui = get_node_or_null("/root/CombatUI")
	if combat_ui:
		setup_combat_ui()

func setup_combat_ui() -> void:
	if not is_instance_valid(combat_ui):
		return
	
	# Connect UI signals if they exist
	if combat_ui.has_method("on_attack_pressed"):
		combat_ui.attack_button.pressed.connect(_on_attack_pressed)
	if combat_ui.has_method("on_magic_pressed"):
		combat_ui.magic_button.pressed.connect(_on_magic_pressed)
	if combat_ui.has_method("on_item_pressed"):
		combat_ui.item_button.pressed.connect(_on_item_pressed)
	if combat_ui.has_method("on_guard_pressed"):
		combat_ui.guard_button.pressed.connect(_on_guard_pressed)
	if combat_ui.has_method("on_flee_pressed"):
		combat_ui.flee_button.pressed.connect(_on_flee_pressed)

func start_combat(enemy_data: Dictionary = {}) -> void:
	is_combat_active = true
	battle_ended = false
	is_player_turn = true
	turn_count = 0
	
	if enemy_data.is_empty():
		current_enemy = {
			"name": "Slime",
			"hp": DEFAULT_ENEMY_HP,
			"max_hp": DEFAULT_ENEMY_HP,
			"attack_power": DEFAULT_ENEMY_ATTACK,
			"magic_power": DEFAULT_ENEMY_MAGIC,
			"defense": DEFAULT_ENEMY_DEFENSE
		}
	else:
		current_enemy = enemy_data
	
	if combat_ui and is_instance_valid(combat_ui):
		combat_ui.start_combat(current_enemy)
	
	print("Combat started with:", current_enemy.get("name", "Unknown"))

func end_combat(won: bool) -> void:
	is_combat_active = false
	battle_ended = true
	
	if won:
		battle_won.emit()
	else:
		battle_lost.emit()
	
	print("Combat ended, player:", "won" if won else "lost")

func next_turn() -> void:
	turn_count += 1
	is_player_turn = not is_player_turn
	
	if is_player_turn:
		player_turn_started.emit("Player")
	else:
		enemy_turn_started.emit(current_enemy.get("name", "Enemy"))
	
	turn_changed.emit(current_enemy.get("name", "Enemy") if not is_player_turn else "Player")

func _on_attack_pressed() -> void:
	if not is_combat_active or battle_ended:
		return
	
	var damage = calculate_damage("attack", current_enemy.get("defense", DEFAULT_ENEMY_DEFENSE))
	current_enemy["hp"] -= damage
	
	combat_ui.update_enemy_hp(current_enemy["hp"], current_enemy["max_hp"]) if combat_ui else null
	
	if current_enemy["hp"] <= 0:
		end_combat(true)
	else:
		next_turn()

func _on_magic_pressed() -> void:
	if not is_combat_active or battle_ended:
		return
	
	var damage = calculate_damage("magic", current_enemy.get("defense", DEFAULT_ENEMY_DEFENSE))
	current_enemy["hp"] -= damage
	
	combat_ui.update_enemy_hp(current_enemy["hp"], current_enemy["max_hp"]) if combat_ui else null
	
	if current_enemy["hp"] <= 0:
		end_combat(true)
	else:
		next_turn()

func _on_item_pressed() -> void:
	if not is_combat_active or battle_ended:
		return
	
	combat_ui.use_item() if combat_ui and is_instance_valid(combat_ui) else null

func _on_guard_pressed() -> void:
	if not is_combat_active or battle_ended:
		return
	
	combat_ui.activate_guard() if combat_ui and is_instance_valid(combat_ui) else null

func _on_flee_pressed() -> void:
	if not is_combat_active or battle_ended:
		return
	
	end_combat(true)

func calculate_damage(action_type: String, enemy_defense: float) -> float:
	var base_damage = 15.0 if action_type == "attack" else 20.0
	var variance = randf_range(-0.3, 0.3)
	
	return max(1.0, (base_damage * (1 + variance)) - enemy_defense)

func get_enemy_data() -> Dictionary:
	return current_enemy.duplicate()

func execute_action(action_index: int, target: Node = null, power: float = 0.0) -> void:
	if not is_combat_active or battle_ended:
		return
	
	match action_index:
		0: _on_attack_pressed()
		1: _on_magic_pressed()
		2: _on_item_pressed()
		3: _on_guard_pressed()
		4: _on_flee_pressed()

func get_current_turn_actor() -> Dictionary:
	return {
		"name": "Player" if is_player_turn else current_enemy.get("name", "Enemy"),
		"is_player": is_player_turn,
		"hp": 100.0 if is_player_turn else current_enemy.get("hp", 50.0),
		"max_hp": 100.0 if is_player_turn else current_enemy.get("max_hp", 50.0)
	}
