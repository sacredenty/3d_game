extends Control

class_name BattleScene

@export var return_scene_path: String = "res://scenes/main/main_scene.tscn"

@onready var game_manager = get_node_or_null("/root/GameManager")
@onready var combat_system = get_node_or_null("/root/CombatSystem")
@onready var encounter_system = get_node_or_null("/root/EncounterSystem")
@onready var action_menu: Control = get_node_or_null("CombatUI/ActionMenu")
@onready var turn_label: Label = get_node_or_null("CombatUI/TurnLabel")
@onready var player_hp_container: HBoxContainer = get_node_or_null("CombatUI/PlayerHPContainer")
@onready var enemy_hp_container: VBoxContainer = get_node_or_null("CombatUI/EnemyHPContainer")

var player_chars: Array[Node] = []
var enemy_chars: Array[Node] = []
var is_player_turn: bool = true
var current_action_index: int = 0

func _ready() -> void:
	if combat_system == null:
		push_error("CombatSystem autoload is unavailable.")
		return
	
	combat_system.turn_changed.connect(_on_turn_changed)
	combat_system.battle_won.connect(_on_battle_won)
	combat_system.battle_lost.connect(_on_battle_lost)
	combat_system.battle_fled.connect(_on_battle_fled)

	var enemy_data: Dictionary = {}
	if encounter_system != null and not encounter_system.current_encounter.is_empty():
		var enemy: Enemy = encounter_system.current_encounter[0]
		enemy_data = {
			"name": enemy.name,
			"hp": enemy.hp,
			"max_hp": enemy.max_hp,
			"attack_power": enemy.attack_power,
			"magic_power": enemy.magic_power,
			"defense": enemy.defense
		}
	combat_system.start_combat(enemy_data)

func _input(event: InputEvent) -> void:
	if not is_player_turn or combat_system.battle_ended:
		return
	
	if event is InputEventKey and event.pressed:
		handle_input(event.keycode)

func handle_input(keycode: int) -> void:
	match keycode:
		KEY_A, KEY_KP_1:
			execute_action(0)
		KEY_Z, KEY_KP_2:
			execute_action(1)
		KEY_I, KEY_KP_3:
			execute_action(2)
		KEY_G, KEY_KP_4:
			execute_action(3)
		KEY_Q, KEY_ESCAPE:
			execute_action(4)

func execute_action(action_index: int) -> void:
	if not is_player_turn or combat_system.battle_ended:
		return
	
	combat_system.execute_action(action_index, null, 0.0)

func _on_turn_changed(actor_name: String) -> void:
	print("Turn:", actor_name)
	
	if actor_name.begins_with("Player"):
		is_player_turn = true
		if action_menu != null:
			action_menu.visible = true
		update_ui()
	else:
		is_player_turn = false
		if action_menu != null:
			action_menu.visible = false

func _on_battle_won() -> void:
	print("Battle won!")
	get_tree().change_scene_to_file(return_scene_path)

func _on_battle_lost() -> void:
	print("Battle lost!")
	get_tree().change_scene_to_file(return_scene_path)

func _on_battle_fled() -> void:
	get_tree().change_scene_to_file(return_scene_path)

func update_ui() -> void:
	if player_hp_container == null or enemy_hp_container == null:
		return
	
	for i in range(min(player_chars.size(), 4)):
		var char = player_chars[i] if player_chars.size() > i else null
		if char and char.get_is_alive():
			var hp_bar = get_node_or_null("PlayerHPContainer/Bar" + str(i))
			if hp_bar:
				hp_bar.value = clampf(char.hp / char.max_hp * 100, 0.0, 100.0) if char and char.max_hp > 0 else 0.0
				hp_bar.color = _get_hp_color(char.hp, char.max_hp) if char else Color(0.5, 0.5, 0.5)

func update_enemy_ui() -> void:
	if enemy_chars.is_empty():
		return
	
	for i in range(min(enemy_chars.size(), 4)):
		var enemy = enemy_chars[i] if enemy_chars.size() > i else null
		if enemy and enemy.get_is_alive():
			var hp_bar = get_node_or_null("EnemyHPContainer/Bar" + str(i))
			if hp_bar:
				hp_bar.value = clampf(enemy.hp / enemy.max_hp * 100, 0.0, 100.0) if enemy and enemy.max_hp > 0 else 0.0
				hp_bar.color = _get_hp_color(enemy.hp, enemy.max_hp) if enemy else Color(0.5, 0.5, 0.5)

func _get_hp_color(current_hp: float, max_hp: float) -> Color:
	if current_hp >= max_hp * 0.6:
		return Color(0.2, 1.0, 0.2)
	elif current_hp >= max_hp * 0.3:
		return Color(1.0, 1.0, 0.2)
	else:
		return Color(1.0, 0.2, 0.2)
