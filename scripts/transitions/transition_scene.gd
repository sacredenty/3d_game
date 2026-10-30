extends Control

class_name TransitionScene

@onready var label: Label = null
@onready var progress_bar: ProgressBar = null

var zone_name: String = ""
var zone_description: String = ""
var is_finished: bool = false

func set_zone_info(zone: String, desc: String) -> void:
	zone_name = zone
	zone_description = desc
	
	if label == null:
		label = Label.new()
		add_child(label)
	
	if progress_bar == null:
		progress_bar = ProgressBar.new()
		add_child(progress_bar)

func _ready() -> void:
	label.text = "Transitioning to " + zone_name + "..."
	label.position = Vector2(0, -50)
	label.size = Vector2(400, 100)
	
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	
	await get_tree().create_timer(1.5).timeout
	transition_complete()

func transition_complete() -> void:
	is_finished = true
	label.text = "Welcome to " + zone_name + "!"
	label.position = Vector2(0, -30)
	
	await get_tree().create_timer(1.0).timeout
	
	if label != null and is_instance_valid(label):
		label.queue_free()
	if progress_bar != null and is_instance_valid(progress_bar):
		progress_bar.queue_free()

signal finished
