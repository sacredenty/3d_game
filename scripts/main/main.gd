extends Node

class_name Main

func _ready() -> void:
	var main_scene = preload("res://scenes/main/main_scene.tscn")
	var instance = main_scene.instantiate()
	add_child(instance)
	instance.tree_root_changed.connect(_on_tree_root_changed)

func _on_tree_root_changed(new_root: Node) -> void:
	get_tree().root = new_root

# Override to handle game start
func _process(delta):
	if not GameManager.has_instance():
		return
	
	var gm = GameManager.get_instance()
	if gm.is_game_running and not gm.game_started.is_connected(_on_game_started):
		gm.start_new_game()
		gm.game_started.connect(_on_game_started)

func _on_game_started():
	print("Game started!")
