extends Node2D

class_name MainScene

@onready var game_manager: GameManager = null
@onready var overworld_scene: OverworldScene = null

func _ready() -> void:
	game_manager = GameManager.new()
	add_child(game_manager)
	
	# Create overworld scene for exploration
	overworld_scene = OverworldScene.new()
	add_child(overworld_scene)
	
	# Connect signals for UI updates
	game_manager.game_started.connect(_on_game_started)
	game_manager.battle_started.connect(_on_battle_started)
	game_manager.battle_ended.connect(_on_battle_ended)
	game_manager.zone_changed.connect(_on_zone_changed)

func _on_game_started() -> void:
	print("Game started!")
	# Initialize UI here

func _on_battle_started() -> void:
	print("Battle started!")
	# Switch to battle scene (handled by encounter system)

func _on_battle_ended(winner: String) -> void:
	print("Battle ended. Winner:", winner)
	# Return to overworld or show results

func _on_zone_changed(new_zone: String) -> void:
	print("Zone changed to:", new_zone)
	# Update zone display in UI
