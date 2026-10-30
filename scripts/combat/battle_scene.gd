extends Control

class_name BattleScene

# Input key constants (numeric values from Godot 4.x)
const KEY_A = 65
const KEY_NUMPAD1 = 96
const KEY_Z = 90
const KEY_NUMPAD2 = 103
const KEY_I = 73
const KEY_NUMPAD3 = 108
const KEY_G = 71
const KEY_NUMPAD4 = 109
const KEY_Q = 81
const KEY_ESCAPE = 65359

@onready var game_manager: GameManager = null
@onready var combat_system: CombatSystem = null
@onready var encounter_system: EncounterSystem = null
@onready var action_menu: ActionMenu = null
@onready var turn_label: TurnLabel = null
@onready var player_hp_container: HPBarContainer = null
@onready var enemy_hp_container: HPBarContainer = null

var player_chars: Array[Node] = []
var enemy_chars: Array[Node] = []
var is_player_turn: bool = true
var current_action_index: int = 0

func _ready() -> void:
	game_manager = GameManager
	
	if EncounterSystem != null:
		encounter_system = EncounterSystem
	
	combat_system.turn_changed.connect(_on_turn_changed)
	combat_system.battle_won.connect(_on_battle_won)
	combat_system.battle_lost.connect(_on_battle_lost)
	combat_system.action_executed.connect(_on_action_executed)
	
	if combat_system:
		combat_system.initialize()

func _input(event: InputEvent) -> void:
	if not is_player_turn or combat_system.battle_ended:
		return
	
	if event is InputEventKey and event.pressed:
		handle_input(event.keycode)

func handle_input(keycode: int) -> void:
	match keycode:
		KEY_A, KEY_NUMPAD1:
			execute_action(0)
		KEY_Z, KEY_NUMPAD2:
			execute_action(1)
		KEY_I, KEY_NUMPAD3:
			execute_action(2)
		KEY_G, KEY_NUMPAD4:
			execute_action(3)
		KEY_Q, KEY_ESCAPE:
			execute_action(4)

func execute_action(action_index: int) -> void:
	if not is_player_turn or combat_system.battle_ended:
		return
	
	combat_system.execute_action(action_index, null, 0.0)

func _on_turn_changed(actor_name: String) -> void:
	print("Turn:", actor_name)
	
	if actor_name.starts_with("Player"):
		is_player_turn = true
		action_menu.visible = true
		update_ui()
	else:
		is_player_turn = false
		action_menu.visible = false

func _on_battle_won() -> void:
	print("Battle won!")
	get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))

func _on_battle_lost() -> void:
	print("Battle lost!")
	get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))

func _on_action_executed(action_index: int, target: Node?, damage: float) -> void:
	print("Action:", action_index, "Target:", target.name if target else null, "Damage:", damage)
	update_ui()

func update_ui() -> void:
	if player_hp_container == null or enemy_hp_container == null:
		return
	
	for i in range(min(player_chars.size(), 4)):
		var char = player_chars[i] if player_chars.size() > i else null
		if char and char.get_isalive():
			var hp_bar = get_node_or_null("PlayerHPContainer/Bar" + str(i))
			if hp_bar:
				hp_bar.value = clampf(char.hp / char.max_hp * 100, 0.0, 100.0) if char and char.max_hp > 0 else 0.0
				hp_bar.color = _get_hp_color(char.hp, char.max_hp) if char else Color(0.5, 0.5, 0.5)

func update_enemy_ui() -> void:
	if enemy_chars.is_empty():
		return
	
	for i in range(min(enemy_chars.size(), 4)):
		var enemy = enemy_chars[i] if enemy_chars.size() > i else null
		if enemy and enemy.get_isalive():
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

func _process(delta: float) -> void:
	if is_player_turn and action_menu != null:
		action_menu.process_input()
