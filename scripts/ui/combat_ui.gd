extends Control

class_name CombatUI

# Autoload references (no type hints to avoid parse errors)
var game_manager = null
var combat_system = null
var encounter_system = null

# UI Elements (buttons are children of ActionMenu)
@onready var turn_label: Label = $TurnLabel if $TurnLabel else null
@onready var action_menu: Control = $ActionMenu if $ActionMenu else null
@onready var attack_button: Button = %ActionMenu/AttackButton if %ActionMenu/AttackButton else null
@onready var magic_button: Button = %ActionMenu/MagicButton if %ActionMenu/MagicButton else null
@onready var item_button: Button = %ActionMenu/ItemButton if %ActionMenu/ItemButton else null
@onready var guard_button: Button = %ActionMenu/GuardButton if %ActionMenu/GuardButton else null
@onready var flee_button: Button = %ActionMenu/FleeButton if %ActionMenu/FleeButton else null

# HP Bars containers
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
		combat_system.combat_ui = self
		combat_system.turn_changed.connect(_on_turn_changed)
		attack_button.pressed.connect(func(): execute_action(0))
		magic_button.pressed.connect(func(): execute_action(1))
		item_button.pressed.connect(func(): execute_action(2))
		guard_button.pressed.connect(func(): execute_action(3))
		flee_button.pressed.connect(func(): execute_action(4))
	
	_setup_ui()

func _setup_ui() -> void:
	if action_menu == null or attack_button == null:
		return
	
	action_menu.visible = true
	
	# Setup buttons with colors (use modulate for Button)
	attack_button.modulate = Color(0.3, 0.6, 0.3)
	magic_button.modulate = Color(0.4, 0.3, 0.8)
	item_button.modulate = Color(1.0, 0.7, 0.2)
	guard_button.modulate = Color(0.5, 0.5, 0.6)
	flee_button.modulate = Color(0.9, 0.4, 0.4)

func execute_action(action_index) -> void:
	if combat_system:
		combat_system.execute_action(action_index, null, 0.0)

func start_combat(enemy_data: Dictionary) -> void:
	if not enemy_data.is_empty():
		update_enemy_hp(enemy_data.get("hp", 0.0), enemy_data.get("max_hp", 1.0))
	update_ui()

func update_enemy_hp(current_hp: float, max_hp: float) -> void:
	var enemy_hp_bar := get_node_or_null("EnemyHPContainer/Bar0") as ProgressBar
	if enemy_hp_bar != null:
		enemy_hp_bar.value = clampf(current_hp / max_hp * 100.0, 0.0, 100.0) if max_hp > 0.0 else 0.0
		enemy_hp_bar.max_value = 100.0
		enemy_hp_bar.modulate = _get_hp_color(current_hp, max_hp)

func use_item() -> void:
	push_warning("Item use is not implemented until an inventory system is available.")

func activate_guard() -> void:
	push_warning("Guard is not implemented until enemy turns are available.")

func _on_turn_changed(_actor_name: String) -> void:
	update_ui()

func update_ui() -> void:
	if turn_label == null or action_menu == null:
		return
	
	# Update turn indicator
	var current_turn = combat_system.get_current_turn_actor() if combat_system else null
	if current_turn:
		turn_label.text = "Turn: " + str(current_turn.name)
		action_menu.visible = combat_system.is_player_turn and not combat_system.battle_ended if combat_system else false

func update_hp_bars() -> void:  # lint:ignore node_ref
	if player_hp_container == null or enemy_hp_container == null:
		return
	
	for i in range(min(player_chars.size(), 4)):
		var char = player_chars[i] if player_chars.size() > i else null
		if char and char.get_is_alive():
			var hp_bar = get_node_or_null("PlayerHPContainer/Bar" + str(i))
			if hp_bar:
				hp_bar.value = clampf(char.hp / char.max_hp * 100, 0.0, 100.0) if char and char.max_hp > 0 else 0.0
				hp_bar.color = _get_hp_color(char.hp, char.max_hp) if char else Color(0.5, 0.5, 0.5)

func update_enemy_hp_bars() -> void:  # lint:ignore node_ref
	if enemy_chars.is_empty():
		return
	
	for i in range(min(enemy_chars.size(), 4)):
		var enemy = enemy_chars[i] if enemy_chars.size() > i else null
		if enemy and enemy.get_is_alive():
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
