extends CharacterBody2D

@export var move_speed: float = 100.0
@export var movement_enabled: bool = true

func _ready() -> void:
	print("PlayerController ready at:", position.x, position.y)

func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return

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
