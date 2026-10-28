extends Control

class_name BattleScene

@onready var game_manager: GameManager = null
@onready var combat_system: CombatSystem = null

var player_chars: Array[Character] = []
var enemy_chars: Array[Enemy] = []
var is_player_turn: bool = true

func _ready() -> void:
	game_manager = GameManager.get_instance() if GameManager.has_instance() else null
	
	# Connect signals
	combat_system.turn_changed.connect(_on_turn_changed)
	combat_system.battle_won.connect(_on_battle_won)
	combat_system.battle_lost.connect(_on_battle_lost)
	combat_system.action_executed.connect(_on_action_executed)

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
	combat_system.execute_action(action, null, null)

func _on_turn_changed(actor_name: String) -> void:
	print("Turn:", actor_name)
	if not is_player_turn:
		await get_tree().create_timer(1.0).timeout
		combat_system.enemy_turn()

func _on_battle_won() -> void:
	print("Battle won!")
	get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))

func _on_battle_lost() -> void:
	print("Battle lost!")
	get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))

func _on_action_executed(action: CombatSystem.Action, target: Character?, damage: float?) -> void:
	print("Action:", action, "Target:", target.name if target else null, "Damage:", damage)
