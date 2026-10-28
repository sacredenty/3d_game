extends Control

signal new_game_started()

func _ready() -> void:
	# Connect button signal
	get_node_or_null("Button").button_up.connect(_on_new_game_button)

func _on_new_game_button() -> void:
	new_game_started.emit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			new_game_started.emit()
