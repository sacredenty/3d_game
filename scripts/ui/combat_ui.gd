extends Control

class_name CombatUI

# Autoload references (no type hints to avoid parse errors)
var game_manager = null
var combat_system = null
var encounter_system = null

# UI Elements
@onready var turn_label: Label = $TurnLabel if $TurnLabel else null
@onready var action_menu: Control = $ActionMenu if $ActionMenu else null
@onready var attack_button: Button = $AttackButton if $AttackButton else null
@onready var magic_button: Button = $MagicButton if $MagicButton else null
@onready var item_button: Button = $ItemButton if $ItemButton else null
@onready var guard_button: Button = $GuardButton if $GuardButton else null
@onready var flee_button: Button = $FleeButton if $FleeButton else null

# HP Bars container
@onready var player_hp_container: HBoxContainer = $PlayerHPContainer if $PlayerHPContainer else null
@onready var enemy_hp_container: VBoxContainer = $EnemyHPContainer if $EnemyHPContainer else null

var player_chars = []
var enemy_chars = []

func _ready() -> void:
	# Assign autoloads at runtime using get_node_or_null
	self.game_manager = get_node_or_null("/root/GameManager")
	combat_system = get_node_or_null("/root/CombatSystem")
	encounter_system = get_node_or_null("/root/EncounterSystem")
	
	if encounter_system:
		pass  # Will be used later
	
	# Connect signals
	if combat_system:
		combat_system.turn_changed.connect(_on_turn_changed)
		combat_system.battle_won.connect(_on_battle_won)
		combat_system.battle_lost.connect(_on_battle_lost)
	
	_setup_ui()

func _setup_ui() -> void:
	if action_menu == null or attack_button == null:
		return
	
	action_menu.visible = true
	
	# Setup buttons with colors and icons (placeholder)
	attack_button.color = Color(0.3, 0.6, 0.3)
	magic_button.color = Color(0.4, 0.3, 0.8)
	item_button.color = Color(1.0, 0.7, 0.2)
	guard_button.color = Color(0.5, 0.5, 0.6)
	flee_button.color = Color(0.9, 0.4, 0.4)

func _input(event: InputEvent) -> void:
	if not combat_system or not combat_system.is_player_turn or combat_system.battle_ended:
		return
	
	if event is InputEventKey and event.pressed:
		handle_input(event.keycode)

func handle_input(keycode: int) -> void:
	match keycode:
		KEY_A, KEY_1:
			execute_action(0)  # ATTACK
		KEY_Z, KEY_2:
			execute_action(1)  # MAGIC
		KEY_I, KEY_3:
			execute_action(2)  # ITEM
		KEY_G, KEY_4:
			execute_action(3)  # GUARD
		KEY_Q, KEY_ESCAPE:
			execute_action(4)  # FLEE

func execute_action(action_index) -> void:
	if combat_system:
		combat_system.execute_action(action_index, null, null)

func _on_turn_changed(actor_name: String) -> void:
	update_ui()

func _on_battle_won() -> void:
	print("Battle won!")
	get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))

func _on_battle_lost() -> void:
	print("Battle lost!")
	get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))

func update_ui() -> void:
	if turn_label == null or action_menu == null:
		return
	
	# Update turn indicator
	var current_turn = combat_system.get_current_turn_actor() if combat_system else null
	if current_turn:
		turn_label.text = "Turn: " + str(current_turn.name)
		
		# Enable/disable buttons based on whose turn it is
		action_menu.visible = combat_system.is_player_turn and not combat_system.battle_ended if combat_system else false
		
		for button in [attack_button, magic_button, item_button, guard_button, flee_button]:
			button.disabled = true  # Disable by default

func update_hp_bars() -> void:
	if player_hp_container == null or enemy_hp_container == null:
		return
	
	# Update player HP bars
	for i in range(min(player_chars.size(), 4)):
		var char = player_chars[i] if player_chars else null
		if char and char.is_alive():
			var hp_bar = get_node_or_null("PlayerHPContainer/Bar" + str(i))
			if hp_bar:
				hp_bar.value = clampf(char.hp / char.max_hp * 100, 0.0, 100.0) if char and char.max_hp > 0 else 0.0
				hp_bar.color = _get_hp_color(char.hp, char.max_hp) if char else Color(0.5, 0.5, 0.5)

func update_enemy_hp_bars() -> void:
	if enemy_chars.is_empty():
		return
	
	for i in range(min(enemy_chars.size(), 4)):
		var enemy = enemy_chars[i] if enemy_chars else null
		if enemy and enemy.is_alive():
			var hp_bar = get_node_or_null("EnemyHPContainer/Bar" + str(i))
			if hp_bar:
				hp_bar.value = clampf(enemy.hp / enemy.max_hp * 100, 0.0, 100.0) if enemy and enemy.max_hp > 0 else 0.0
				hp_bar.color = _get_hp_color(enemy.hp, enemy.max_hp) if enemy else Color(0.5, 0.5, 0.5)

func _get_hp_color(current_hp, max_hp) -> Color:
	var ratio = current_hp / max_hp if max_hp > 0 else 0.5
	if ratio > 0.6:
		return Color(0.2, 0.8, 0.2)
	elif ratio > 0.3:
		return Color(1.0, 0.8, 0.2)
	else:
		return Color(0.8, 0.2, 0.2)

func _process(delta):
	update_hp_bars()
	update_enemy_hp_bars()
