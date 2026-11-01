extends CharacterBody2D

@export var move_speed: float = 100.0

func _ready() -> void:
	print("PlayerController ready at:", position.x, position.y)

func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1.0
	
	if input_dir.length_squared() > 0.0:
		input_dir = input_dir.normalized()
		velocity = input_dir * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP: print("W/UP pressed at:", position.x, position.y)
			KEY_S, KEY_DOWN: print("S/DOWN pressed at:", position.x, position.y)
			KEY_A, KEY_LEFT: print("A/LEFT pressed at:", position.x, position.y)
			KEY_D, KEY_RIGHT: print("D/RIGHT pressed at:", position.x, position.y)
