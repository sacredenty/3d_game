extends Control

class_name CombatUI

@onready var game_manager: GameManager = null
@onready var combat_system: CombatSystem = null

var player_chars: Array[Character] = []
var enemy_chars: Array[Enemy] = []

func _ready() -> void:
	game_manager = GameManager.get_instance() if GameManager.has_instance() else null
	
	# Connect signals
	combat_system.turn_changed.connect(_on_turn_changed)
	combat_system.battle_won.connect(_on_battle_won)
	combat_system.battle_lost.connect(_on_battle_lost)

func _input(event: InputEvent) -> void:
	if not combat_system.is_player_turn or combat_system.battle_ended:
		return
	
	if event is InputEventKey and event.pressed:
		handle_input(event.keycode)

func handle_input(keycode: int) -> void:
	match keycode:
		KEY_a, KEY_1:
			execute_action(CombatSystem.Action.ATTACK)
		KEY_z, KEY_2:
			execute_action(CombatSystem.Action.MAGIC)
		KEY_i, KEY_3:
			execute_action(CombatSystem.Action.ITEM)
		KEY_g, KEY_4:
			execute_action(CombatSystem.Action.GUARD)
		KEY_q, KEY_ESCAPE:
			execute_action(CombatSystem.Action.FLEE)

func execute_action(action: CombatSystem.Action) -> void:
	combat_system.execute_action(action, null, null)

func _on_turn_changed(actor_name: String) -> void:
	update_ui()

func _on_battle_won() -> void:
	print("Battle won!")
	get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))

func _on_battle_lost() -> void:
	print("Battle lost!")
	get_tree().change_scene_to_packed(preload("res://scenes/main/main_scene.tscn"))

func update_ui() -> void:
	# Update player character stats
	for char in player_chars:
		if char and char.is_alive():
			var hp_bar = get_node_or_null("PlayerHPBar")
			if hp_bar:
				hp_bar.value = char.hp / char.max_hp * 100

func _process(delta):
	update_ui()
