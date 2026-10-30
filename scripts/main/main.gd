extends Node

class_name Main

@onready var game_manager: GameManager = null

func _ready() -> void:
	var main_scene = preload("res://scenes/main/main_scene.tscn")
	var instance = main_scene.instantiate()
	add_child(instance)
	instance.tree_root_changed.connect(_on_tree_root_changed)

func _on_tree_root_changed(new_root: Node) -> void:
	print("Tree root changed to:", new_root.name)

# Override to handle game start
func _process(delta):
	if not game_manager:
		return
	
	if game_manager.is_game_running and not game_manager.game_started.is_connected(_on_game_started):
		game_manager.start_new_game()
		game_manager.game_started.connect(_on_game_started)

func _on_game_started():
	print("Game started!")
