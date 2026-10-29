extends Control

class_name BattleScene

@onready var game_manager: GameManager = null
@onready var combat_system: CombatSystem = null
@onready var encounter_system: EncounterSystem = null
@onready var action_menu: ActionMenu = null
@onready var turn_label: TurnLabel = null
@onready var player_hp_container: HPBarContainer = null
@onready var enemy_hp_container: HPBarContainer = null

var player_chars: Array[Character] = []
var enemy_chars: Array[Enemy] = []
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
	
	# Initialize combat state
	if combat_system:
		combat_system.initialize()

func _input(event: InputEvent) -> void:
	if not is_player_turn or combat_system.battle_ended:
		return
	
	if event is InputEventKey and event.pressed:
		handle_input(event.keycode)

func handle_input(keycode: int) -> void:
	match keycode:
		KEY_a, KEY_1:
			execute_action(Action.ATTACK)
		KEY_z, KEY_2:
			execute_action(Action.MAGIC)
		KEY_i, KEY_3:
			execute_action(Action.ITEM)
		KEY_g, KEY_4:
			execute_action(Action.GUARD)
		KEY_q, KEY_ESCAPE:
			execute_action(Action.FLEE)

func execute_action(action: CombatSystem.Action) -> void:
	if not is_player_turn or combat_system.battle_ended:
		return
	
	current_action_index = action.index
	combat_system.execute_action(action, null, null)

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

func _on_action_executed(action: CombatSystem.Action, target: Character?, damage: float?) -> void:
	print("Action:", action, "Target:", target.name if target else null, "Damage:", damage)
	update_ui()

func update_ui() -> void:
	if player_hp_container == null or enemy_hp_container == null:
		return
	
	# Update player HP bars (named Bar0, Bar1, Bar2, Bar3)
	for i in range(min(player_chars.size(), 4)):
		var char = player_chars[i] if player_chars else null
		if char and char.is_alive():
			var hp_bar = get_node_or_null("PlayerHPContainer/Bar" + str(i))
			if hp_bar:
				hp_bar.value = clampf(char.hp / char.max_hp * 100, 0.0, 100.0) if char and char.max_hp > 0 else 0.0
				hp_bar.color = _get_hp_color(char.hp, char.max_hp) if char else Color(0.5, 0.5, 0.5)

func update_enemy_ui() -> void:
	if enemy_chars.is_empty():
		return
	
	for i in range(min(enemy_chars.size(), 4)):
		var enemy = enemy_chars[i] if enemy_chars else null
		if enemy and enemy.is_alive():
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
