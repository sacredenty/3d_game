extends CharacterBody2D

@export var move_speed: float = 100.0
@export var movement_enabled: bool = true

var character_sprite: Sprite2D
var walk_time: float = 0.0

func _ready() -> void:
	character_sprite = get_node_or_null("CharacterSprite")

func _physics_process(delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		_update_character_sprite(delta, false)
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
	_update_character_sprite(delta, input_dir.length_squared() > 0.0)

func _update_character_sprite(delta: float, is_moving: bool) -> void:
	if character_sprite == null:
		return
	if is_moving:
		walk_time += delta * 12.0
		character_sprite.position.y = -22.0 + absf(sin(walk_time)) * 2.0
		if absf(velocity.x) > 0.1:
			character_sprite.flip_h = velocity.x < 0.0
	else:
		walk_time = 0.0
		character_sprite.position.y = -22.0
