extends Control

class_name HPBarContainer

@onready var bar0: ProgressBar = null
@onready var bar1: ProgressBar = null
@onready var bar2: ProgressBar = null
@onready var bar3: ProgressBar = null

func _ready() -> void:
	# Ensure bars exist with proper names for battle_scene.gd to find them
	if not has_node("Bar0"):
		bar0 = ProgressBar.new()
		add_child(bar0)
	
	if not has_node("Bar1"):
		bar1 = ProgressBar.new()
		add_child(bar1)
	
	if not has_node("Bar2"):
		bar2 = ProgressBar.new()
		add_child(bar2)
	
	if not has_node("Bar3"):
		bar3 = ProgressBar.new()
		add_child(bar3)

func update_bar(index: int, value: float, color: Color) -> void:
	match index:
		0: bar0.value = clampf(value, 0.0, 100.0); bar0.color = color if bar0 else Color(0.5, 0.5, 0.5)
		1: bar1.value = clampf(value, 0.0, 100.0); bar1.color = color if bar1 else Color(0.5, 0.5, 0.5)
		2: bar2.value = clampf(value, 0.0, 100.0); bar2.color = color if bar2 else Color(0.5, 0.5, 0.5)
		3: bar3.value = clampf(value, 0.0, 100.0); bar3.color = color if bar3 else Color(0.5, 0.5, 0.5)
